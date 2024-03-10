/*
 * Copyright (C)2008-2017 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

/*
 * YoshiCrafter Engine fixes:
 * - Added Error handler
 * - Added Imports
 * - Added @:bypassAccessor
 */
package hscript;

import haxe.iterators.StringKeyValueIteratorUnicode;
import haxe.EnumTools;
import haxe.display.Protocol.InitializeResult;
import haxe.PosInfos;
import hscript.Expr;
import haxe.Constraints.IMap;

using StringTools;
// This fuckin edit is just to make this public
enum Stop {
	SBreak;
	SContinue;
	SReturn;
}

class Interp {
	public var scriptObject(default, set):Dynamic;
	public function set_scriptObject(v:Dynamic) {
		__instanceFields = (v == null) ? [] : Type.getInstanceFields(Type.getClass(v));
		return scriptObject = v;
	}
	public var errorHandler:Error->Void;
	public var importFailedCallback:Array<String>->Bool;

	public var customClasses:Map<String, Dynamic>;
	public var variables:Map<String, Dynamic>;
	public var publicVariables:Map<String, Dynamic>;
	public var staticVariables:Map<String, Dynamic>;

	public var locals:Map<String, {r:Dynamic, depth:Int}>;
	var binops:Map<String, Expr->Expr->Dynamic>;

	var depth:Int = 0;
	var inTry:Bool;
	var declared:Array<{n:String, old:{r:Dynamic, depth:Int}, depth:Int}>;
	var returnValue:Dynamic;

	var isBypassAccessor:Bool = false;

	public var importEnabled:Bool = true;

	public var allowStaticVariables:Bool = false;
	public var allowPublicVariables:Bool = false;

	public var importBlocklist:Array<String> = [
		// "flixel.FlxG"
	];

	var __instanceFields:Array<String> = [];
	#if hscriptPos
	var curExpr:Expr;
	#end

	public function new() {
		locals = new Map();
		declared = new Array();
		resetVariables();
		initOps();
	}

	private function resetVariables() {
		customClasses = new Map<String, Dynamic>();
		variables = new Map<String, Dynamic>();
		publicVariables = new Map<String, Dynamic>();
		staticVariables = new Map<String, Dynamic>();


		variables.set("null", null);
		variables.set("true", true);
		variables.set("false", false);
		variables.set("trace", Reflect.makeVarArgs(function(el) {
			var inf = posInfos();
			var v = el.shift();
			if (el.length > 0)
				inf.customParams = el;
			haxe.Log.trace(Std.string(v), inf);
		}));
	}

	public function posInfos():PosInfos {
		#if hscriptPos
		if (curExpr != null)
			return cast {fileName: curExpr.origin, lineNumber: curExpr.line};
		#end
		return cast {fileName: "hscript", lineNumber: 0};
	}

	function initOps() {
		var me = this;
		binops = new Map();
		binops.set("+", function(e1, e2) return me.expr(e1) + me.expr(e2));
		binops.set("-", function(e1, e2) return me.expr(e1) - me.expr(e2));
		binops.set("*", function(e1, e2) return me.expr(e1) * me.expr(e2));
		binops.set("/", function(e1, e2) return me.expr(e1) / me.expr(e2));
		binops.set("%", function(e1, e2) return me.expr(e1) % me.expr(e2));
		binops.set("&", function(e1, e2) return me.expr(e1) & me.expr(e2));
		binops.set("|", function(e1, e2) return me.expr(e1) | me.expr(e2));
		binops.set("^", function(e1, e2) return me.expr(e1) ^ me.expr(e2));
		binops.set("<<", function(e1, e2) return me.expr(e1) << me.expr(e2));
		binops.set(">>", function(e1, e2) return me.expr(e1) >> me.expr(e2));
		binops.set(">>>", function(e1, e2) return me.expr(e1) >>> me.expr(e2));
		binops.set("==", function(e1, e2) return me.expr(e1) == me.expr(e2));
		binops.set("!=", function(e1, e2) return me.expr(e1) != me.expr(e2));
		binops.set(">=", function(e1, e2) return me.expr(e1) >= me.expr(e2));
		binops.set("<=", function(e1, e2) return me.expr(e1) <= me.expr(e2));
		binops.set(">", function(e1, e2) return me.expr(e1) > me.expr(e2));
		binops.set("<", function(e1, e2) return me.expr(e1) < me.expr(e2));
		binops.set("||", function(e1, e2) return me.expr(e1) == true || me.expr(e2) == true);
		binops.set("&&", function(e1, e2) return me.expr(e1) == true && me.expr(e2) == true);
		binops.set("=", assign);
		binops.set("??", function(e1, e2) {
			var expr1:Dynamic = me.expr(e1);
			return expr1 == null ? me.expr(e2) : expr1;
		});
		binops.set("...", function(e1, e2) return new IntIterator(me.expr(e1), me.expr(e2)));
		assignOp("+=", function(v1:Dynamic, v2:Dynamic) return v1 + v2);
		assignOp("-=", function(v1:Float, v2:Float) return v1 - v2);
		assignOp("*=", function(v1:Float, v2:Float) return v1 * v2);
		assignOp("/=", function(v1:Float, v2:Float) return v1 / v2);
		assignOp("%=", function(v1:Float, v2:Float) return v1 % v2);
		assignOp("&=", function(v1, v2) return v1 & v2);
		assignOp("|=", function(v1, v2) return v1 | v2);
		assignOp("^=", function(v1, v2) return v1 ^ v2);
		assignOp("<<=", function(v1, v2) return v1 << v2);
		assignOp(">>=", function(v1, v2) return v1 >> v2);
		assignOp(">>>=", function(v1, v2) return v1 >>> v2);
		assignOp("is", function(v1, v2) return Std.isOfType(v1, v2));
		assignOp("??=", function(v1, v2) return v1 == null ? v2 : v1);
		
	}

	public function setVar(name:String, v:Dynamic) {
		if (allowStaticVariables && staticVariables.exists(name)) staticVariables.set(name, v);
		else if (allowPublicVariables && publicVariables.exists(name)) publicVariables.set(name, v);
		else variables.set(name, v);
	}
	// function assign( e1 : Expr, e2 : Expr ) : Dynamic {
	// 	var v = expr(e2);
	// 	switch( Tools.expr(e1) ) {
	// 	case EIdent(id):
			// var l = locals.get(id);
			// if( l == null )
			// 	setVar(id,v)
			// else
			// 	l.r = v;
	// 	case EField(e,f):
	// 		v = set(expr(e),f,v);
	// 	case EArray(e, index):
	// 		var arr:Dynamic = expr(e);
	// 		var index:Dynamic = expr(index);
	// 		if (isMap(arr)) {
	// 			setMapValue(arr, index, v);
	// 		}
	// 		else {
	// 			arr[index] = v;
	// 		}

	// 	default:
	// 		error(EInvalidOp("="));
	// 	}
	// 	return v;
	// }
	function assign(e1:Expr, e2:Expr):Dynamic {
		var v = expr(e2);
		switch (Tools.expr(e1)) {
			case EIdent(id):
				var l = locals.get(id);
				if (l == null) {
					// if (!variables.exists(id) && !staticVariables.exists(id) && !publicVariables.exists(id) && scriptObject != null && __instanceFields != null) {
					// 	if (Type.typeof(scriptObject) == TObject) {
					// 		Reflect.setField(scriptObject, id, v);
					// 	} else {
						// if (isBypassAccessor && __instanceFields.contains(id)) {
						// 	Reflect.setField(scriptObject, id, v);
						// 	return v;
						// }
						// if (__instanceFields.contains(id)) {
						// 	Reflect.setProperty(scriptObject, id, v);
						// 	return v;
						// } else if (__instanceFields.contains('set_$id')) { // setter
						// 	Reflect.getProperty(scriptObject, 'set_$id')(v);
						// 	return v;
						// } 

						// }
					// }
					if(scriptObject != null){
						if (__instanceFields.contains('set_$id')) { // setter
							Reflect.getProperty(scriptObject, 'set_$id')(v);
							return v;
						}else if(__instanceFields.contains(id)){
							Reflect.setProperty(scriptObject, id, v);
							return v;
						}
					}
					setVar(id, v);
					
				} else {
					l.r = v;
					// if (l.depth == 0) {
					// 	setVar(id, v);
					// }
				}
				// TODO
			case EField(e, f, s):
				var obj = expr(e);
				if(s && obj == null) return null;
				v = set(obj, f, v);
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr)) setMapValue(arr, index, v);
				else arr[index] = v;

			default:
				error(EInvalidOp("="));
		}
		return v;
	}

	function assignOp(op, fop:Dynamic->Dynamic->Dynamic) {
		var me = this;
		binops.set(op, function(e1, e2) return me.evalAssignOp(op, fop, e1, e2));
	}

	function evalAssignOp(op, fop, e1, e2):Dynamic {
		var v;
		switch (Tools.expr(e1)) {
			case EIdent(id):
				var l = locals.get(id);
				v = fop(expr(e1), expr(e2));
				if (l != null) {
					l.r = v;
					return v;
				}
				if (__instanceFields.contains(id)) {
					Reflect.setProperty(scriptObject, id, v);
				} else if (__instanceFields.contains('set_$id')) { // setter
					Reflect.getProperty(scriptObject, 'set_$id')(v);
				} else {
					setVar(id, v);
				}
			case EField(e, f, s):
				var obj = expr(e);
				if(s && obj == null) return null;
				v = fop(get(obj, f), expr(e2));
				v = set(obj, f, v);
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr)) {
					v = fop(getMapValue(arr, index), expr(e2));
					setMapValue(arr, index, v);
				} else {
					v = fop(arr[index], expr(e2));
					arr[index] = v;
				}
			default:
				return error(EInvalidOp(op));
		}
		return v;
	}

	function increment(e:Expr, prefix:Bool, delta:Int):Dynamic {
		#if hscriptPos
		curExpr = e;
		var e = e.e;
		#end
		switch (e) {
			case EIdent(id):
				var l = locals.get(id);
				var v:Dynamic = (l == null) ? resolve(id) : l.r;
				if (prefix) {
					v += delta;
					if (l == null) setVar(id, v)
					else l.r = v;
				} else if (l == null) setVar(id, v + delta)
				else l.r = v + delta;
				return v;
			case EField(e, f, s):
				var obj = expr(e);
				if(s && obj == null) return null;
				var v:Dynamic = get(obj, f);
				var vd = v + delta;
				set(obj, f, vd);
				if (prefix) return vd;
				return v;
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr)) {
					var v = getMapValue(arr, index);
					var vd = v + delta;
					setMapValue(arr, index, vd);
					if (prefix) return vd;
					return v;
				} else {
					var v = arr[index];
					var vd = v + delta;
					arr[index] = vd;
					if (prefix) return vd;
					return v;
				}
			default:
				return error(EInvalidOp((delta > 0) ? "++" : "--"));
		}
	}

	public function execute(expr:Expr):Dynamic {
		depth = 0;
		locals = new Map();
		declared = new Array();
		return exprReturn(expr);
	}

	function exprReturn(e):Dynamic {
		try {
			try {
				return expr(e);
			} catch (e:Stop) {
				switch (e) {
					case SBreak: throw "Invalid break";
					case SContinue: throw "Invalid continue";
					case SReturn:
						var v = returnValue;
						returnValue = null;
						return v;
				}
			} catch(e) {
				error(ECustom('${e.toString()}'));
				return null;
			}
		} catch(e:Error) {
			if (errorHandler == null) throw e;
			else errorHandler(e);
			return null;
		} catch(e) {
			trace(e);
		}
		return null;
	}

	public function duplicate<T>(h:Map<String, T>) {
		var h2 = new Map();
		for (k in h.keys())
			h2.set(k, h.get(k));
		return h2;
	}

	function restore(old:Int) {
		while (declared.length > old) {
			var d = declared.pop();
			locals.set(d.n, d.old);
		}
	}

	@:keep inline function error(e:#if hscriptPos ErrorDef #else Error #end, rethrow = false):Dynamic {
		#if hscriptPos var e = new Error(e, curExpr.pmin, curExpr.pmax, curExpr.origin, curExpr.line); #end
		throw e;
		return null;
	}

	@:keep inline function rethrow(e:Dynamic) {
		#if hl
		hl.Api.rethrow(e);
		#else
		throw e;
		#end
	}

	public function resolve(id:String, doException:Bool = true):Dynamic {
		id = StringTools.trim(id);
		try{

			if (locals.exists(id)) return locals.get(id).r;

			for(map in [variables, publicVariables, staticVariables, customClasses])
				if (map.exists(id)) return map[id];

			if (scriptObject != null) {
				// search in object
				if (id == "this") {
					return scriptObject;
				} else if ((Type.typeof(scriptObject) == TObject) && Reflect.hasField(scriptObject, id)) {
					return Reflect.field(scriptObject, id);
				} else {
					if (__instanceFields.contains('get_$id')) { // getter
						return Reflect.getProperty(scriptObject, 'get_$id')();
					}else if (__instanceFields.contains(id)) {
						return Reflect.getProperty(scriptObject, id);
					}
				}
			}
		}catch(e){
			trace(e);
			if (doException)
				error(EUnknownVariable(id));
		}
		// trace('lmao $id is invalid, laugh at this user');
		if (doException){

			// trace('$id THREW AN ERROR, FUCKING L');
			error(EUnknownVariable(id));
		}
		return null;
	}

	public function expr(e:Expr):Dynamic {
		#if hscriptPos
		curExpr = e;
		var e = e.e;
		#end
		switch (e) {
			case EClass(name, fields, extend, interfaces):
				if (customClasses.exists(name))
					error(EAlreadyExistingClass(name));
				customClasses.set(name, new CustomClassHandler(this, name, fields, extend, interfaces));
			case EImport(c, n):
				if (!importEnabled)
					return null;
				var splitClassName = [for (e in c.split(".")) e.trim()];
				var realClassName = splitClassName.join(".");
				var claVarName = splitClassName[splitClassName.length - 1];
				var toSetName = n != null ? n : claVarName;
				var oldClassName = realClassName;
				var oldSplitName = splitClassName.copy();

				if (variables.exists(toSetName)) // class is already imported
					return null;

				if (importBlocklist.contains(realClassName))
					return null;
				var cl = Type.resolveClass(realClassName);
				if (cl == null)
					cl = Type.resolveClass('${realClassName}_HSC');

				var en = Type.resolveEnum(realClassName);

				//trace(realClassName, cl, en, splitClassName);

				// Allow for flixel.ui.FlxBar.FlxBarFillDirection;
				if (cl == null && en == null) {
					if(splitClassName.length > 1) {
						splitClassName.splice(-2, 1); // Remove the last last item
						realClassName = splitClassName.join(".");

						if (importBlocklist.contains(realClassName))
							return null;

						cl = Type.resolveClass(realClassName);
						if (cl == null)
							cl = Type.resolveClass('${realClassName}_HSC');

						en = Type.resolveEnum(realClassName);

						//trace(realClassName, cl, en, splitClassName);
					}
				}

				if (cl == null && en == null) {
					if (importFailedCallback == null || !importFailedCallback(oldSplitName))
						error(EInvalidClass(oldClassName));
				} else {
					if (en != null) {
						// ENUM!!!!
						var enumThingy = {};
						for (c in en.getConstructors()) {
							try {
								Reflect.setField(enumThingy, c, en.createByName(c));
							} catch(e) {
								try {
									Reflect.setField(enumThingy, c, Reflect.field(en, c));
								} catch(ex) {
									throw e;
								}
							}
						}
						variables.set(toSetName, enumThingy);
					} else {
						variables.set(toSetName, cl);
					}
				}

				return null;

			case EConst(c):
				switch (c) {
					case CInt(v): return v;
					case CFloat(f): return f;
					case CString(s): return s;
					#if !haxe3
					case CInt32(v): return v;
					#end
				}
			case EIdent(id):
				return resolve(id);
			case EVar(n, _, e, isPublic, isStatic):
				declared.push({n: n, old: locals.get(n), depth: depth});
				locals.set(n, {r: (e == null) ? null : expr(e), depth: depth});
				if (depth == 0) {
					if(isStatic == true) {
						if(!staticVariables.exists(n)) {
							staticVariables.set(n, locals[n].r);
						}
						return null;
					}
					(isPublic ? publicVariables : variables).set(n, locals[n].r);
				}
				return null;
			case EParent(e):
				return expr(e);
			case EBlock(exprs):
				var old = declared.length;
				var v = null;
				for (e in exprs)
					v = expr(e);
				restore(old);
				return v;
			case EField(e, f, s):
				var field = expr(e);
				if(s && field == null) return null;
				return get(field, f);
			case EBinop(op, e1, e2):
				var fop = binops.get(op);
				if (fop == null)
					error(EInvalidOp(op));
				return fop(e1, e2);
			case EUnop(op, prefix, e):
				switch (op) {
					case "!":
						return !expr(e);
					case "-":
						return -expr(e);
					case "++":
						return increment(e, prefix, 1);
					case "--":
						return increment(e, prefix, -1);
					case "~":
						#if (neko && !haxe3)
						return haxe.Int32.complement(expr(e));
						#else
						return ~expr(e);
						#end
					default:
						error(EInvalidOp(op));
				}
			case ECall(e, params):
				var args = new Array();
				for (p in params)
					args.push(expr(p));
				switch (Tools.expr(e)) {
					case EField(e, f, s):
						var obj = expr(e);
						if (obj == null) {
							if(s) return null;
							error(EInvalidAccess(f));
						}
						return fcall(obj, f, args);
					default:
						var obj = expr(e);
						if (obj == null) throw('Unable to call null');
						return call(null, obj, args);
				}
			case EIf(econd, e1, e2):
				return (expr(econd) == true) ? expr(e1) : ((e2 == null) ? null : expr(e2));
			case EWhile(econd, e):
				whileLoop(econd, e);
				return null;
			case EDoWhile(econd, e):
				doWhileLoop(econd, e);
				return null;
			case EFor(v, it, e):
				forLoop(v, it, e);
				return null;
			case EBreak:
				throw SBreak;
			case EContinue:
				throw SContinue;
			case EReturn(e):
				returnValue = e == null ? null : expr(e);
				throw SReturn;
			case EFunction(params, fexpr, name, _, isPublic, isStatic, isOverride):
				var __capturedLocals = duplicate(locals);
				var capturedLocals:Map<String, {r:Dynamic, depth:Int}> = [];
				for(k=>e in __capturedLocals)
					if (e != null && e.depth > 0)
						capturedLocals.set(k, e);

				var me = this;
				var hasOpt = false, minParams = 0;
				for (p in params)
					if (p.opt) hasOpt = true;
					else minParams++;
				var f = function(args:Array<Dynamic>) {
					if (me.locals == null || me.variables == null) return null;

					if (((args == null) ? 0 : args.length) != params.length) {
						if (args.length < minParams) {
							var str = "Invalid number of parameters. Got " + args.length + ", required " + minParams;
							if (name != null)
								str += " for function '" + name + "'";
							error(ECustom(str));
						}
						// make sure mandatory args are forced
						var args2 = [];
						var extraParams = args.length - minParams;
						var pos = 0;
						for (p in params)
							if (p.opt) {
								if (extraParams > 0) {
									args2.push(args[pos++]);
									extraParams--;
								} else args2.push(null);
							} else args2.push(args[pos++]);
						args = args2;
					}
					var old = me.locals, depth = me.depth;
					me.depth++;
					me.locals = me.duplicate(capturedLocals);
					for (i in 0...params.length)
						me.locals.set(params[i].name, {r: args[i], depth: depth});
					var r = null;
					var oldDecl = declared.length;
					if (inTry)
						try {
							r = me.exprReturn(fexpr);
						} catch (e:Dynamic) {
							me.locals = old;
							me.depth = depth;
							#if neko
							neko.Lib.rethrow(e);
							#else
							throw e;
							#end
						}
					else r = me.exprReturn(fexpr);
					restore(oldDecl);
					me.locals = old;
					me.depth = depth;
					return r;
				};
				var f = Reflect.makeVarArgs(f);
				if (name != null) {
					if (depth == 0) {
						// global function
						((isStatic && allowStaticVariables) ? staticVariables : ((isPublic && allowPublicVariables) ? publicVariables : variables)).set(name, f);
					} else {
						// function-in-function is a local function
						declared.push({n: name, old: locals.get(name), depth: depth});
						var ref = {r: f, depth: depth};
						locals.set(name, ref);
						capturedLocals.set(name, ref); // allow self-recursion
					}
				}
				return f;
			case EArrayDecl(arr, wantedType):
				var isMap = false;
				var isTypeMap = false;
				if(!isMap && wantedType != null) {
					isMap = wantedType.match(CTPath(["Map"], [_, _]));
					isTypeMap = true;
				} else {
					isMap = arr.length > 0 && Tools.expr(arr[0]).match(EBinop("=>", _));
				}
				if (isMap) {
					var isAllString:Bool = true;
					var isAllInt:Bool = true;
					var isAllObject:Bool = true;
					var isAllEnum:Bool = true;
					var keys:Array<Dynamic> = [];
					var values:Array<Dynamic> = [];
					for (e in arr) {
						switch (Tools.expr(e)) {
							case EBinop("=>", eKey, eValue): {
								var key:Dynamic = expr(eKey);
								var value:Dynamic = expr(eValue);
								isAllString = isAllString && (key is String);
								isAllInt = isAllInt && (key is Int);
								isAllObject = isAllObject && Reflect.isObject(key);
								isAllEnum = isAllEnum && Reflect.isEnumValue(key);
								keys.push(key);
								values.push(value);
							}
							default: throw("=> expected");
						}
					}

					if(isTypeMap) {
						if(wantedType != null) {
							isAllString = wantedType.match(CTPath(["Map"], [CTPath(["String"], _), _]));
							isAllInt = wantedType.match(CTPath(["Map"], [CTPath(["Int"], _), _]));
							if(isAllString || isAllInt) {
								isAllObject = false;
								isAllEnum = false;
							} else {
								if(!isAllObject && !isAllEnum) {
									throw("Unknown Type Key");
								}
							}
						}
					}

					var map:Dynamic = {
						if (isAllInt) new haxe.ds.IntMap<Dynamic>();
						else if (isAllString) new haxe.ds.StringMap<Dynamic>();
						else if (isAllEnum) new haxe.ds.EnumValueMap<Dynamic, Dynamic>();
						else if (isAllObject) new haxe.ds.ObjectMap<Dynamic, Dynamic>();
						else throw 'Inconsistent key types';
					}
					for (n in 0...keys.length) setMapValue(map, keys[n], values[n]);
					return map;
				}
				var a = new Array();
				for (e in arr)  a.push(expr(e));
				return a;
				
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr)) {
					return getMapValue(arr, index);
				}
				return arr[index];
			case ENew(cl, params):
				var a = new Array();
				for (e in params) a.push(expr(e));
				return cnew(cl, a);
			case EThrow(e):
				throw expr(e);
			case ETry(e, n, _, ecatch):
				var old = declared.length;
				var oldTry = inTry;
				try {
					inTry = true;
					var v:Dynamic = expr(e);
					restore(old);
					inTry = oldTry;
					return v;
				} catch (err:Stop) {
					inTry = oldTry;
					throw err;
				} catch (err:Dynamic) {
					// restore vars
					restore(old);
					inTry = oldTry;
					// declare 'v'
					declared.push({n: n, old: locals.get(n), depth: depth});
					locals.set(n, {r: err, depth: depth});
					var v:Dynamic = expr(ecatch);
					restore(old);
					return v;
				}
			case EObject(fl):
				var o = {};
				for (f in fl) set(o, f.name, expr(f.e));
				return o;
			case ETernary(econd, e1, e2):
				return (expr(econd) == true) ? expr(e1) : expr(e2);
			case ESwitch(e, cases, def):
				var val:Dynamic = expr(e);
				var match = false;
				for (c in cases) {
					for (v in c.values)
						if (expr(v) == val) {
							match = true;
							break;
						}
					if (match) {
						val = expr(c.expr);
						break;
					}
				}
				if (!match)
					val = def == null ? null : expr(def);
				return val;
			case EMeta(a, b, e):
				var oldAccessor = isBypassAccessor;
				if(a == ":bypassAccessor") {
					isBypassAccessor = true;
				}
				var val = expr(e);

				isBypassAccessor = oldAccessor;
				return val;
			case ECheckType(e, _):
				return expr(e);
		}
		return null;
	}

	function doWhileLoop(econd, e) {
		var old = declared.length;
		do {
			try {
				expr(e);
			} catch (err:Stop) {
				switch (err) {
					case SContinue:
					case SBreak: break;
					case SReturn: throw err;
				}
			}
		} while (expr(econd) == true);
		restore(old);
	}

	function whileLoop(econd, e) {
		var old = declared.length;
		while (expr(econd) == true) {
			try {
				expr(e);
			} catch (err:Stop) {
				switch (err) {
					case SContinue:
					case SBreak:
						break;
					case SReturn:
						throw err;
				}
			}
		}
		restore(old);
	}

	function makeIterator(v:Dynamic):Iterator<Dynamic> {
		#if ((flash && !flash9) || (php && !php7 && haxe_ver < '4.0.0'))
		if (v.iterator != null)
			v = v.iterator();
		#else
		try
			v = v.iterator()
		catch (e:Dynamic) {};
		#end
		if (v.hasNext == null || v.next == null)
			error(EInvalidIterator(v));
		return v;
	}

	function forLoop(n, it, e) {
		var old = declared.length;
		declared.push({n: n, old: locals.get(n), depth: depth});
		var it = makeIterator(expr(it));
		while (it.hasNext()) {
			locals.set(n, {r: it.next(), depth: depth});
			try {
				expr(e);
			} catch (err:Stop) {
				switch (err) {
					case SContinue:
					case SBreak: break;
					case SReturn: throw err;
				}
			}
		}
		restore(old);
	}

	inline function isMap(o:Dynamic):Bool {
		return (o is IMap);
	}

	inline function getMapValue(map:Dynamic, key:Dynamic):Dynamic {
		return cast(map, haxe.Constraints.IMap<Dynamic, Dynamic>).get(key);
	}

	inline function setMapValue(map:Dynamic, key:Dynamic, value:Dynamic):Void {
		cast(map, haxe.Constraints.IMap<Dynamic, Dynamic>).set(key, value);
	}

	public static var getRedirects:Map<String, Dynamic->String->Dynamic> = [];
	public static var setRedirects:Map<String, Dynamic->String->Dynamic->Dynamic> = [];

	function get(o:Dynamic, f:String):Dynamic {
		if (o == null)
			error(EInvalidAccess(f));
		return {
			var redirect:Dynamic->String->Dynamic = null;
			var cls = Type.getClass(o);
			var cl:Null<String> = switch (Type.typeof(o)) {
				case TNull: "Null";
				case TInt: "Int";
				case TFloat: "Float";
				case TBool: "Bool";
				case _: cls != null ? Type.getClassName(cls) : null;
			};
			if (cl != null && getRedirects.exists(cl) && (redirect = getRedirects[cl]) != null) {
				return redirect(o, f);
			} else if (o is IHScriptCustomBehaviour) {
				var obj = cast(o, IHScriptCustomBehaviour);
				return obj.hget(f);
			} else {
				var v = null;
				if(isBypassAccessor) {
					return Reflect.field(o, f) ?? Reflect.field(cls, f);
				}

				if(v == null) {
					return Reflect.getProperty(o, f) ?? Reflect.getProperty(cls, f);
				}
				return v;
			}
		}
	}

	function set(o:Dynamic, f:String, v:Dynamic):Dynamic {
		if (o == null)
			error(EInvalidAccess(f));

		var redirect:Dynamic->String->Dynamic->Dynamic = null;
		var cls = Type.getClass(o);
		var cl:Null<String> = switch (Type.typeof(o)) {
			case TNull: "Null";
			case TInt: "Int";
			case TFloat: "Float";
			case TBool: "Bool";
			case _: cls != null ? Type.getClassName(cls) : null;
		};
		if (cl != null && setRedirects.exists(cl) && (redirect = setRedirects[cl]) != null)
			return redirect(o, f, v);
		else if (o is IHScriptCustomBehaviour) {
			var obj = cast(o, IHScriptCustomBehaviour);
			return obj.hset(f, v);
		}
		if(isBypassAccessor) Reflect.setField(o, f, v);
		else Reflect.setProperty(o, f, v);

		return v;
	}

	function fcall(o:Dynamic, f:String, args:Array<Dynamic>):Dynamic {
		if(o == CustomClassHandler.staticHandler && scriptObject != null) {
			return Reflect.callMethod(scriptObject, Reflect.field(scriptObject, "_HX_SUPER__" + f), args);
		}
		return call(o, get(o, f), args);
	}

	function call(o:Dynamic, f:Dynamic, args:Array<Dynamic>):Dynamic {
		if(f == CustomClassHandler.staticHandler) {
			return null;
		}
		return Reflect.callMethod(o, f, args);
	}

	function cnew(cl:String, args:Array<Dynamic>):Dynamic {
		var cl:String = cast cl;
		var c:Dynamic = resolve(cl);
		if (c == null)
			c = Type.resolveClass(cl);
		return (c is IHScriptCustomConstructor) ? cast(c, IHScriptCustomConstructor).hnew(args) : Type.createInstance(c, args);
	}
}