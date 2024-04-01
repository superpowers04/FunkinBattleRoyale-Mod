package hscript;

using StringTools;

class CustomClassHandler implements IHScriptCustomConstructor {
	public static var staticHandler = new StaticHandler();

	public var ogInterp:Interp;
	public var name:String;
	public var fields:Array<Expr>;
	public var extend:String;
	public var interfaces:Array<String>;

	public function new(ogInterp:Interp, name:String, fields:Array<Expr>, ?extend:String, ?interfaces:Array<String>) {
		this.ogInterp = ogInterp;
		this.name = name;
		this.fields = fields;
		this.extend = extend;
		this.interfaces = interfaces;
	}

	public function hnew(args:Array<Dynamic>):Dynamic {
		var interp = new Interp();

		interp.errorHandler = ogInterp.errorHandler;

		var cl = extend == null ? TemplateClass : Type.resolveClass('${extend}_HSX');
		var _class = Type.createInstance(cl, args);

		var __capturedLocals = ogInterp.duplicate(ogInterp.locals);
		var capturedLocals:Map<String, {r:Dynamic, depth:Int}> = [];
		for(k=>e in __capturedLocals)
			if (e != null && e.depth <= 0)
				capturedLocals.set(k, e);

		var disallowCopy = Type.getInstanceFields(cl);

		//trace("Locals");
		for (key => value in capturedLocals) {
			if(!disallowCopy.contains(key)) {
				interp.locals.set(key, {r: value, depth: -1});
				//trace(key, value);
			}
		}
		//trace("Variables");
		for (key => value in ogInterp.variables) {
			if(!disallowCopy.contains(key)) {
				interp.variables.set(key, value);
				//trace(key, value);
			}
		}

		for(expr in fields) {
			@:privateAccess
			interp.exprReturn(expr);
		}

		interp.variables.set("super", staticHandler);

		_class.__interp = interp;
		interp.scriptObject = _class;

		var newFunc = interp.variables.get("new");
		if(newFunc != null) {
			Reflect.callMethod(null, newFunc, args);
		}

		for(variable => value in interp.variables) {
			if(variable == "this") continue;
		}

		return _class;
	}

	public function toString():String {
		return name;
	}
}

class TemplateClass implements IHScriptCustomBehaviour {
	public var __interp:Interp;

	public function hset(name:String, val:Dynamic):Dynamic {
		if(this.__interp.variables.exists("set_" + name)) {
			return this.__interp.variables.get("set_" + name)(val); // TODO: Prevent recursion from setting it in the function
		}
		if (this.__interp.variables.exists(name)) {
			this.__interp.variables.set(name, val);
			return val;
		}
		Reflect.setProperty(this, name, val);
		return Reflect.field(this, name);
	}
	public function hget(name:String):Dynamic {
		if(this.__interp.variables.exists("get_" + name))
			return this.__interp.variables.get("get_" + name)();
		if (this.__interp.variables.exists(name))
			return this.__interp.variables.get(name);
		return Reflect.getProperty(this, name);
	}
}

class StaticHandler {
	public function new() {}
}