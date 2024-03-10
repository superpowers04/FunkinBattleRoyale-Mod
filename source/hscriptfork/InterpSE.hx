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
package hscriptfork;
import hscript.Interp;
import haxe.PosInfos;
import hscript.Expr;
import haxe.Constraints.IMap;
// import hscript.Interp.Stop;



class InterpSE extends Interp {
	private override function resetVariables(){
		super.resetVariables();

		variables.set("Bool", Bool);
		variables.set("Int", Int);
		variables.set("Float", Float);
		variables.set("String", String);
		variables.set("Dynamic", Dynamic);
		variables.set("Array", Array);
	}
	public var iterationLimit:Int = 1000000; // Set to 0 to disable
	@:access(hscript.Interp)
	override function whileLoop(econd, e) {
		var old = declared.length;
		var iterations:Int = 0;
		while (expr(econd) == true) {
			if(iterationLimit > 0){
				iterations++;
				if(iterations > iterationLimit){
					throw('Iteration count exceeded!');
					break;
				}
			}
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

	public var iterationLimitFor:Int = 1000000; // Set to 0 to disable. Specific to for loops
	override function makeIterator(v:Dynamic):Iterator<Dynamic> {
		try v = v.iterator() catch (e:Dynamic) {};
		if (v.hasNext == null || v.next == null)
			error(EInvalidIterator(v));
		return v;
	}

	override function forLoop(n, it, e) {
		var old = declared.length;
		declared.push({n: n, old: locals.get(n), depth: depth});
		var it = makeIterator(expr(it));
		var iterations:Int = 0;
		while( it.hasNext() ) {
			if(iterationLimitFor > 0){
				iterations++;
				if(iterations > iterationLimitFor){
					throw('Iteration count exceeded!');
					break;
				}
			}
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

}