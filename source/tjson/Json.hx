// Modified from https://raw.githubusercontent.com/JWambaugh/TJSON/
// Uses Std.isOfType instead of Std.is and puts commas before newlines
package tjson;
using StringTools;

class Json {	
	public static var OBJECT_REFERENCE_PREFIX = "@~obRef#";
	/**
	 * Parses a JSON string into a haxe dynamic object or array.
	 * @param String - The JSON string to parse
	 * @param String the file name to whic the JSON code belongs. Used for generating nice error messages.
	 */
	public static function parse(json:String, ?fileName:String="JSON Data", ?stringProcessor:String->Dynamic = null,?_class:Class<Any>,?baseObject:Dynamic):Dynamic{
		var t = new TJSONParser(json, fileName, stringProcessor,_class,baseObject);
		return t.doParse();
	}

	/**
	 * Serializes a dynamic object or an array into a JSON string.
	 * @param Dynamic - The object to be serialized
	 * @param Dynamic - The style to use. Either an object implementing EncodeStyle interface or the strings 'fancy' or 'simple'.
	 */
	public static function encode(obj:Dynamic, ?style:Dynamic=null, useCache:Bool=false):String{
		var t = new TJSONEncoder(useCache);
		return t.doEncode(obj,style);
	}

// Just a copy of the above but with stringify aswell as encode and fancy as the default style
	public static function stringify(obj:Dynamic, ?style:Dynamic="fancy", useCache:Bool=false):String{
		var t = new TJSONEncoder(useCache);
		return t.doEncode(obj,style);

	}


}

class TJSON {	
	public static var OBJECT_REFERENCE_PREFIX = "@~obRef#";
	/**
	 * Parses a JSON string into a haxe dynamic object or array.
	 * @param String - The JSON string to parse
	 * @param String the file name to whic the JSON code belongs. Used for generating nice error messages.
	 */
	public static function parse(json:String, ?fileName:String="JSON Data", ?stringProcessor:String->Dynamic = null,?_class:Class<Any>,?baseObject:Dynamic):Dynamic{
		var t = new TJSONParser(json, fileName, stringProcessor,_class,baseObject);
		return t.doParse();
	}

	/**
	 * Serializes a dynamic object or an array into a JSON string.
	 * @param Dynamic - The object to be serialized
	 * @param Dynamic - The style to use. Either an object implementing EncodeStyle interface or the strings 'fancy' or 'simple'.
	 */
	public static function encode(obj:Dynamic, ?style:Dynamic=null, useCache:Bool=true):String{
		var t = new TJSONEncoder(useCache);
		return t.doEncode(obj,style);
	}

// Just a copy of the above but with stringify aswell as encode 
	public static function stringify(obj:Dynamic, ?style:Dynamic=null, useCache:Bool=true):String{
		var t = new TJSONEncoder(useCache);
		return t.doEncode(obj,style);

	}


}

class JSONANONTYPE {}

class TJSONParser{
	var pos:Int = 0;
	var json:String;
	var lastSymbolQuoted:Bool = false; //true if the last symbol was in quotes.
	var fileName:String;
	var currentLine:Int = 1;
	var cache:Array<Dynamic>;
	var floatRegex:EReg = ~/^-?[0-9]*\.[0-9]+$/;
	var intRegex:EReg = ~/^-?[0-9]+$/;
	var strProcessor:String->Dynamic;
	var baseClass:Class<Any>;
	var baseObject:Dynamic;

	public function new(vjson:String, ?vfileName:String="JSON Data", ?stringProcessor:String->Dynamic = null, _class:Class<Any>, baseObject:Dynamic) {
		json = vjson;
		fileName = vfileName;
		strProcessor = stringProcessor ?? defaultStringProcessor;
		cache = new Array();
		if(_class != null){
			baseClass = _class;
		}
		this.baseObject = baseObject;
	}

	public function doParse():Dynamic{
		try{
			//determine if objector array
			return switch (getNextSymbol()) {
				case '{': doObject();
				case '[': doArray();
				case s: convertSymbolToProperType(s);
			}
		}catch(e:String){
			throw fileName + " on line " + currentLine + ": " + e;
		}
	}

	private function doObject():Dynamic{
		var o:Dynamic =  baseObject ?? (baseClass != null && baseClass != JSONANONTYPE ? Type.createEmptyInstance(baseClass) : {});
		var val:Dynamic ='';
		var key:String;
		var isClassOb:Bool = baseClass != null && baseClass != JSONANONTYPE;
		cache.push(o);
		while(pos < json.length){
			key=getNextSymbol();
			if(!lastSymbolQuoted){

				if(key == ",")continue;
				if(key == "}"){
					//end of the object. Run the TJ_unserialize function if there is one
					if( isClassOb && #if flash9 try o.TJ_unserialize != null catch( e : Dynamic ) false #elseif (cs || java) Reflect.hasField(o, "TJ_unserialize") #else o.TJ_unserialize != null #end  ) {
						o.TJ_unserialize();
					}
					return o;
				}
			}

			var seperator = getNextSymbol();
			if(seperator != ":"){
				throw("Expected ':' but got '"+seperator+"' instead.");
			}

			var v = getNextSymbol();

			if(key == '_hxcls'){
				if(isClassOb){
					if(v.startsWith('Date@')) {
						o = Date.fromTime(Std.parseInt(v.substr(5)));
					} else {
						var cls =Type.resolveClass(v);
						if(cls==null) throw "Invalid class name - "+v;
						o = Type.createEmptyInstance(cls);
					}
				}
				cache.pop();
				cache.push(o);

				isClassOb = true;
				continue;
			}

			if(!lastSymbolQuoted){

				if(v == "{"){
					val = doObject();
				}else if(v == "["){
					val = doArray();
				}else{
					val = convertSymbolToProperType(v);
				}
			}else{
				val = convertSymbolToProperType(v);
			}
			Reflect.setField(o,key,val);
		}
		throw "Unexpected end of file. Expected '}'";
		
	}

	private function doArray():Dynamic{
		var a:Array<Dynamic> = new Array<Dynamic>();
		var val:Dynamic;
		while(pos < json.length){
			val=getNextSymbol();
			if(lastSymbolQuoted){
				a.push(val = convertSymbolToProperType(val));
				continue;
			}
			if(val == ',') {
				continue;
			}else if(val == ']') {
				return a;
			}else if(val == "{") {
				val = doObject();
			}else if(val == "[") {
				val = doArray();
			}else {
				val = convertSymbolToProperType(val);
			}
			a.push(val);
		}
		throw "Unexpected end of file. Expected ']'";
	}

	private function convertSymbolToProperType(symbol):Dynamic{
		if(lastSymbolQuoted) {
			//value was in quotes, so it's a string.
			//look for reference prefix, return cached reference if it is
			if(StringTools.startsWith(symbol,TJSON.OBJECT_REFERENCE_PREFIX)){
				var idx:Int = Std.parseInt(symbol.substr(TJSON.OBJECT_REFERENCE_PREFIX.length));
				return cache[idx];
			}
			return symbol; //just a normal string so return it
		}
		var n = getNumberFromString(symbol);
		if(n != null){
			return n;
		}
		switch(symbol.toLowerCase()){
			case "true": return true;
			case "false": return false;
			case "null": return null;
		}
		
		return symbol;
	}


	private function looksLikeFloat(s:String):Bool{
		if(floatRegex.match(s)) return true;

		if(intRegex.match(s)){
			if({
				var intStr = intRegex.matched(0);
				if (intStr.charCodeAt(0) == "-".code)
					intStr > "-2147483648";
				else
					intStr > "2147483647";
			} ) return true;

			var f:Float = Std.parseFloat(s);
			if(f>2147483647.0) return true;
			else if (f<-2147483648) return true;
			
		}
		return false;	
	}
	private function getNumberFromString(s:String):Dynamic{
		if(floatRegex.match(s)) return Std.parseFloat(s);

		if(intRegex.match(s)){
			if({
				var intStr = intRegex.matched(0);
				if (intStr.charCodeAt(0) == "-".code)
					intStr > "-2147483648";
				else
					intStr > "2147483647";
			} ) return Std.parseFloat(s);

			var f:Float = Std.parseFloat(s);
			if(f>2147483647.0 || f<-2147483648) return f;
			return Std.parseInt(s);
		}
		return null;
	}
	private function looksLikeInt(s:String):Bool{
		return intRegex.match(s);
	}

	private function getNextSymbol(){
		lastSymbolQuoted=false;
		var c:String = '';
		var inQuote:Bool = false;
		var quoteType:String="";
		var symbol:String = '';
		var inEscape:Bool = false;
		var inSymbol:Bool = false;
		var inLineComment = false;
		var inBlockComment = false;

		while(pos < json.length){
			c = json.charAt(pos++);
			if(c == "\n" && !inSymbol)
				currentLine++;
			if(inLineComment){
				if(c == "\n" || c == "\r"){
					inLineComment = false;
					pos++;
				}
				continue;
			}

			if(inBlockComment){
				if(c=="*" && json.charAt(pos) == "/"){
					inBlockComment = false;
					pos++;
				}
				continue;
			}

			if(inQuote){
				if(inEscape){
					inEscape = false;
					if(c=="'" || c=='"'){
						symbol += c;
						continue;
					}
					if(c=="t"){
						symbol += "\t";
						continue;
					}
					if(c=="n"){
						symbol += "\n";
						continue;
					}
					if(c=="\\"){
						symbol += "\\";
						continue;
					}
					if(c=="r"){
						symbol += "\r";
						continue;
					}
					if(c=="/"){
						symbol += "/";
						continue;
					}

					if(c=="u"){
						var hexValue = 0;

						for (i in 0...4){
							if (pos >= json.length)
							  throw "Unfinished UTF8 character";
							var nc = json.charCodeAt(pos++);
							hexValue = hexValue << 4;
							if (nc >= 48 && nc <= 57) // 0..9
							  hexValue += nc - 48;
							else if (nc >= 65 && nc <= 70) // A..F
							  hexValue += 10 + nc - 65;
							else if (nc >= 97 && nc <= 102) // a..f
							  hexValue += 10 + nc - 95;
							else throw "Not a hex digit";
						}

						symbol += String.fromCharCode(hexValue);
						
						continue;
					}


					throw "Invalid escape sequence '\\"+c+"'";
				}else{
					if(c == "\\"){
						inEscape = true;
						continue;
					}
					if(c == quoteType){
						return symbol;
					}
					symbol+=c;
					continue;
				}
			}
			

			//handle comments
			else if(c == "/"){
				var c2 = json.charAt(pos);
				//handle single line comments.
				//These can even interrupt a symbol.
				if(c2 == "/"){
					inLineComment=true;
					pos++;
					continue;
				}
				//handle block comments.
				//These can even interrupt a symbol.
				else if(c2 == "*"){
					inBlockComment=true;
					pos++;
					continue;
				}
			}

			

			if (inSymbol){
				if(c==' ' || c=="\n" || c=="\r" || c=="\t" || c==',' || c==":" || c=="}" || c=="]"){ //end of symbol, return it
					pos--;
					return symbol;
				}else{
					symbol+=c;
					continue;
				}
				
			}
			else {
				if(c==' ' || c=="\t" || c=="\n" || c=="\r"){
					continue;
				}

				if(c=="{" || c=="}" || c=="[" || c=="]" || c=="," || c == ":"){
					return c;
				}



				if(c=="'" || c=='"'){
					inQuote = true;
					quoteType = c;
					lastSymbolQuoted = true;
					continue;
				}else{
					inSymbol=true;
					symbol = c;
					continue;
				}


			}
		} // end of while. We have reached EOF if we are here.
		if(inQuote){
			throw "Unexpected end of data. Expected ( "+quoteType+" )";
		}
		return symbol;
	}


	private function defaultStringProcessor(str:String):Dynamic{
		return str;
	}
}


class TJSONEncoder{

	var cache:Array<Dynamic>;
	var uCache:Bool;

	public function new(useCache:Bool=true){
		uCache = useCache;
		if(uCache)cache = new Array();
	}

	public function doEncode(obj:Dynamic, ?style:Dynamic=null){
		if(!Reflect.isObject(obj)){
			throw("Provided object is not an object.");
		}
		var st:EncodeStyle;
		if(Std.isOfType(style, EncodeStyle)){
			st = style;
		}
		else if(style.toLowerCase() == 'fancy'){
			st = new FancyStyle();
		}
		else st = new SimpleStyle();
		var buffer = new StringBuf();
		if(Std.isOfType(obj,Array) || Std.isOfType(obj,List)) {
			buffer.add(encodeIterable( obj, st, 0));

		} else if(Std.isOfType(obj, haxe.ds.StringMap)){
			buffer.add(encodeMap(obj, st, 0));
		} else {
			cacheEncode(obj);
			buffer.add(encodeObject(obj, st, 0));
		}
		return buffer.toString();
	}

	private function encodeObject( obj:Dynamic,style:EncodeStyle,depth:Int):String {
		var buffer = new StringBuf();
		buffer.add(style.beginObject(depth));
		var fieldCount = 0;
		var fields:Array<String>;
		var dontEncodeFields:Array<String> = null;
		var cls = Type.getClass(obj);
		if (cls != null) {
			fields = Type.getInstanceFields(cls);
		} else {
			fields = Reflect.fields(obj);
		}
		//preserve class name when serializing class objects
		//is there a way to get c outside of a switch?
		switch(Type.typeof(obj)){
			case TClass(c):
				var className = Type.getClassName(c);

				// Special value format (Date@timestamp) for the Date class:
				if(className == "Date") className += '@' + cast(obj, Date).getTime();

				if(fieldCount++ > 0) buffer.add(style.entrySeperator(depth));
				else buffer.add(style.firstEntry(depth));
				buffer.add('"_hxcls"'+style.keyValueSeperator(depth));
				buffer.add(encodeValue( className, style, depth));

				if( #if flash9 try obj.TJ_noEncode != null catch( e : Dynamic ) false #elseif (cs || java) Reflect.hasField(obj, "TJ_noEncode") #else obj.TJ_noEncode != null #end  ) {
					dontEncodeFields = obj.TJ_noEncode();
				}
			default:
		}

		for (field in fields){
			if(dontEncodeFields!=null && dontEncodeFields.indexOf(field)>=0)continue;
			var value:Dynamic = Reflect.field(obj,field);
			var vStr:String = encodeValue(value, style, depth);
			if(vStr!=null){
				if(fieldCount++ > 0) buffer.add(style.entrySeperator(depth));
				else buffer.add(style.firstEntry(depth));
				buffer.add('"'+field+'"'+style.keyValueSeperator(depth)+Std.string(vStr));
			}
			
		}
		

		
		buffer.add(style.endObject(depth));
		return buffer.toString();
	}


	private function encodeMap( obj:Map<Dynamic, Dynamic>,style:EncodeStyle,depth:Int):String {
		var buffer = new StringBuf();
		buffer.add(style.beginObject(depth));
		var fieldCount = 0;
		for (field in obj.keys()){
			if(fieldCount++ > 0) buffer.add(style.entrySeperator(depth));
			else buffer.add(style.firstEntry(depth));
			var value:Dynamic = obj.get(field);
			buffer.add('"'+field+'"'+style.keyValueSeperator(depth));
			buffer.add(encodeValue(value, style, depth));
		}
		buffer.add(style.endObject(depth));
		return buffer.toString();
	}


	private function encodeIterable(obj:Iterable<Dynamic>, style:EncodeStyle, depth:Int):String {
		var buffer = new StringBuf();
		buffer.add(style.beginArray(depth));
		var fieldCount = 0;
		for (value in obj){
			if(fieldCount++ >0) buffer.add(style.entrySeperator(depth));
			else buffer.add(style.firstEntry(depth));
			buffer.add(encodeValue( value, style, depth));
			
		}
		buffer.add(style.endArray(depth));
		return buffer.toString();
	}

	private function cacheEncode(value:Dynamic):String{
		if(!uCache)return null;

		for(c in 0...cache.length){
			if(cache[c] == value){
				return '"'+TJSON.OBJECT_REFERENCE_PREFIX+c+'"';
			}
		}
		cache.push(value);
		return null;
	}

	private function encodeValue( value:Dynamic, style:EncodeStyle, depth:Int):String {
		if(Std.isOfType(value, Int) || Std.isOfType(value,Float)){
				return(value);
		}
		else if(Std.isOfType(value,Array) || Std.isOfType(value,List)){
			var v: Array<Dynamic> = value;
			return encodeIterable(v,style,depth+1);
		}
		else if(Std.isOfType(value,List)){
			var v: List<Dynamic> = value;
			return encodeIterable(v,style,depth+1);

		}
		else if(Std.isOfType(value,haxe.ds.StringMap)){
			return encodeMap(value,style,depth+1);

		}
		else if(Std.isOfType(value,String)){
			return('"'+Std.string(value).replace("\\","\\\\").replace("\n","\\n").replace("\r","\\r").replace('"','\\"')+'"');
		}
		else if(Std.isOfType(value,Bool)){
			return(value);
		}
		else if(Reflect.isObject(value)){
			var ret = cacheEncode(value);
			if(ret != null) return ret;
			return encodeObject(value,style,depth+1);
		}
		else if(value == null){
			return("null");
		}
		else{
			return null;
		}
	}

}


interface EncodeStyle{
	
	public function beginObject(depth:Int):String;
	public function endObject(depth:Int):String;
	public function beginArray(depth:Int):String;
	public function endArray(depth:Int):String;
	public function firstEntry(depth:Int):String;
	public function entrySeperator(depth:Int):String;
	public function keyValueSeperator(depth:Int):String;

}

class SimpleStyle implements EncodeStyle{
	public function new(){

	}
	public function beginObject(depth:Int):String{
		return "{";
	}
	public function endObject(depth:Int):String{
		return "}";
	}
	public function beginArray(depth:Int):String{
		return "[";
	}
	public function endArray(depth:Int):String{
		return "]";
	}
	public function firstEntry(depth:Int):String{
		return "";
	}
	public function entrySeperator(depth:Int):String{
		return ",";
	}
	public function keyValueSeperator(depth:Int):String{
		return ":";
	}
}


class FancyStyle implements EncodeStyle{
	public var tab(default, null):String;
	public function new(tab:String = "\t"){
		this.tab = tab;
		charTimesNCache = [""];
	}
	public function beginObject(depth:Int):String{
		return "{\n";
	}
	public function endObject(depth:Int):String{
		return "\n"+charTimesN(depth)+"}";
	}
	public function beginArray(depth:Int):String{
		return "[\n";
	}
	public function endArray(depth:Int):String{
		return "\n"+charTimesN(depth)+"]";
	}
	public function firstEntry(depth:Int):String{
		return charTimesN(depth+1)+' ';
	}
	public function entrySeperator(depth:Int):String{
		return ",\n"+charTimesN(depth+1);
	}
	public function keyValueSeperator(depth:Int):String{
		return " : ";
	}
	private var charTimesNCache:Array<String>;
	private function charTimesN(n:Int):String{
		return if (n < charTimesNCache.length) {
			charTimesNCache[n];
		} else {
			charTimesNCache[n] = charTimesN(n-1) + tab;
		}
	}
	
}


