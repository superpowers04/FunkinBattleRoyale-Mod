package;

//More Modding Plus stuff
import flixel.input.keyboard.FlxKey;
import openfl.display.DisplayObject;
import openfl.display.Stage;
import flixel.input.gamepad.FlxGamepadManager;
import flixel.system.frontEnds.CameraFrontEnd;
import flixel.system.frontEnds.BitmapFrontEnd;
import flixel.system.frontEnds.SoundFrontEnd;
import flixel.addons.effects.FlxTrail;
import flixel.system.frontEnds.InputFrontEnd;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.sound.FlxSound;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSoundGroup;
import flixel.input.keyboard.FlxKeyboard;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxGame;
import flixel.FlxCamera;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxG;
import openfl.media.Sound;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.system.macros.FlxMacroUtil;

import flixel.math.FlxMath;
import OptionsFileDef;

#if FLX_TOUCH
import flixel.input.touch.FlxTouch;
#end
import sys.FileSystem;
import sys.io.File;



import haxe.iterators.StringIterator;
import haxe.iterators.StringKeyValueIterator;
import hscript.Interp;
import hscript.Parser;
import hscript.Expr;
import hscriptfork.InterpSE;

import flixel.util.FlxAxes;
import flxanimate.FlxAnimate;
import flxanimate.frames.FlxAnimateFrames;

#if cpp
using cpp.NativeString;
#end
class HscriptUtils {


	
	public static var interp = new InterpSE();
	public static var hscriptClasses:Array<String> = [];
	public static var defines:Array<String> = [];
	@:access(hscript.InterpEx)
	public static function init() {
		// var filelist = hscriptClasses = CoolUtil.coolTextFile("assets/scripts/plugin_classes/classes.txt");
		interp = addVarsToInterp(interp);
		HscriptGlobals.init();
	}
	/**
	 * Create a simple interp, that already added all the needed shit
	 * This is what has all the default things for hscript.
	 * @see https://github.com/TheDrawingCoder-Gamer/Funkin/wiki/HScript-Commands
	 * @return Interp
	 */
	public static function createSimpleInterp():Interp {
		var reterp = new InterpSE();
		reterp = addVarsToInterp(reterp);
		return reterp;
	}
	public static function createSimpleParser():Parser {
		var parser = new Parser();
		parser.allowTypes = parser.allowJSON = parser.allowMetadata = true;
		parser.preprocesorValues["version"] = MainMenuState.ver;
		parser.preprocesorValues["debug"] = #if debug true #else false #end;
		return parser;
	}
	public static function eval<T:Interp>(interp:T,?parser:hscript.Parser,str:String):Array<Dynamic>{ // [Errored, Error message if so, stack if present,stage]
		if(str == null || str == ""){
			return [true,'Eval string is empty',null,'str != null'];
		}
		if(interp == null){
			return [true,'No interpeter!',null,'interp != null'];
		}

		var program;
		var parser = (if(parser == null) createSimpleParser() else parser);
		try{

			// parser.parseModule(songScript);
			program = parser.parseString(str);
			if(program == null){throw('Parser is null?');}
		}catch(e){return [true,'Line:${parser.line};\n Error:${e.message}',null,'Parsing'];}

		try{
			interp.execute(program);
		}
		catch(e){
			return [true,e.message,e.stack,'Executing'];
		}
		return [false];
	}
	public static function genErrorMessage(e:hscript.Expr.Error,func:String,id:String,?line:String = ""):String {
		var message = switch( #if hscriptPos e.e #else e #end ) {
			case EInvalidChar(c): "Invalid character: '"+(StringTools.isEof(c) ? "EOF" : String.fromCharCode(c))+"' ("+c+")";
			case EUnexpected(s): "Unexpected token: \""+s+"\"";
			case EUnterminatedString: "Unterminated string";
			case EUnterminatedComment: "Unterminated comment";
			case EInvalidPreprocessor(str): "Invalid preprocessor (" + str + ")";
			case EUnknownVariable(v): "Unknown variable: "+v;
			case EInvalidIterator(v): "Invalid iterator: "+v;
			case EInvalidOp(op): "Invalid operator: "+op;
			case EInvalidAccess(f): "Invalid access to field " + f;
			case EAlreadyExistingClass(f): 'Class $f Already exists';
			case EInvalidClass(f): 'Invalid class $f';
			case ECustom(msg): msg;
		};
		#if hscriptPos
			return	'Function "${func}" caused exception for "$id"\n'+
					'${e.origin}:${e.line}$line\n$message';
		#else
			return message;
		#end

	}
	public static function addVarsToInterp<T:Interp>(interp:T):T {
		// // : )
		// SE Specific

		interp.variables.set("Character", Character);
		interp.variables.set("PlayState", PlayState);
		interp.variables.set("Note", Note);
		interp.variables.set("EmptyCharacter", EmptyCharacter);
		interp.variables.set("HealthIcon", HealthIcon);
		interp.variables.set("Alphabet", Alphabet);
		interp.variables.set("Overlay", Overlay);
		interp.variables.set("Conductor", Conductor);
		interp.variables.set("TitleState", TitleState);
		interp.variables.set("makeRangeArray", CoolUtil.numberArray);
		interp.variables.set("SEVersion",MainMenuState.ver);
		interp.variables.set("SENightlyVersion",MainMenuState.nightly);
		interp.variables.set("FinishSubState",FinishSubState);
		interp.variables.set("Paths",Paths);
		interp.variables.set("HSBrTools",HSBrTools);
		interp.variables.set("SETools",SETools);
		interp.variables.set("SELoader",SELoader);
		interp.variables.set("FlxSprTrail",FlxSprTrail);
		// eval.bind(Interp,_)
		interp.variables.set("eval", function(){trace('This does not work yet!');}); // Eval code 
		// interp.variables.set("SEKeys", SEKeys);


		// SE clones of other libaries
		interp.variables.set("FlxG", HscriptGlobals);
		interp.variables.set("BRcolor", HscriptColor);
		interp.variables.set("SESettings",SESettings);
		interp.variables.set("FlxMath", SEMath);
		interp.variables.set("File", FReplica);
		interp.variables.set("FileSystem", FReplica);
		interp.variables.set("StringTools", SEStringTools); // This uses inlines, I hate my life
		interp.variables.set("Json", SEJson);

		interp.variables.set("Type", Type);
		interp.variables.set("getClass", Type.getClass);
		interp.variables.set("resolveClass", Type.resolveClass);
		// SE modifications of other libraries
		interp.variables.set("FlxTimer", BRTimer);

		// Flixel Libaries


		interp.variables.set("FlixelFlxG", FlxG); // 
		interp.variables.set("FlxSprite", FlxSprite);
		interp.variables.set("FlxGraphic", FlxGraphic);
		interp.variables.set("FlxSound", FlxSound);
		interp.variables.set("FlxGroup", flixel.group.FlxGroup);
		interp.variables.set("FlxAngle", flixel.math.FlxAngle);
		interp.variables.set("FlxAnimation", flixel.animation.FlxAnimation);
		interp.variables.set("FlxBaseAnimation", flixel.animation.FlxBaseAnimation);
		interp.variables.set("FlxBackdrop", flixel.addons.display.FlxBackdrop);
		interp.variables.set("FlxTypedGroup", FlxTypedGroup);
		interp.variables.set("FlxAtlasFrames", FlxAtlasFrames);
		interp.variables.set("FlxTrail", FlxTrail);
		interp.variables.set("FlxTrailArea", FlxTrailArea);
		interp.variables.set("FlxPoint", FlxBasePoint);
		
		interp.variables.set("FlxEase", FlxEase);
		interp.variables.set("FlxCamera",FlxCamera);
		interp.variables.set("FlxTween", FlxTween);
		interp.variables.set("FlxText",FlxText);
		interp.variables.set("FlxSort",FlxSort);
		#if FLXRUNTIMESHADER
		interp.variables.set("FlxRuntimeShader",flixel.addons.display.FlxRuntimeShader);
		#end
		interp.variables.set("FlxShader",flixel.graphics.tile.FlxGraphicsShader);
		interp.variables.set("FlxTextBorderStyle",FlxTextBorderStyle);
		interp.variables.set("FlxAxes",SEAxes);

		interp.variables.set("FlxAnimate", FlxAnimate);
		interp.variables.set("FlxAnimateFrames", FlxAnimateFrames);

		// Normal Haxe
		interp.variables.set("Math", Math);
		interp.variables.set("Global",HSBrTools.shared);
		interp.variables.set("Std", Std);
		interp.variables.set("Reflect", Reflect);

		interp.variables.set("mobile",#if(mobile) true #else false #end );
		if(defines == null){getDefines();}
		interp.variables.set("defines",defines );


		interp.variables.set("this", interp);

		
		interp.variables.set("debug", #if(debug) true #else false #end );
		
		
		return interp;
	}
	public static function getDefines(){
		defines = ['haxe'
		#if(windows)				,"windows" #end
		#if(macos)					,"macos" #end
		#if(linux)					,"linux" #end
		#if(android)				,"android" #end
		#if(web)					,"web" #end
		#if(flash)					,"flash" #end
		#if(sys)					,"sys" #end
		#if(debug)					,"debug" #end
		#if(target.sys)				,"target.sys" #end
		#if(target.static)			,"target.static" #end
		#if(target.threaded)		,"target.threaded" #end
		#if(ghaction)				,"ghaction" #end
		#if(HXCPP_M64)				,"hxcpp_m64" #end
		#if(HXCPP_M32)				,"hxcpp_m32" #end
		#if(HXCPP_CHECK_POINTER)	,"hxcpp_check_pointer" #end
		#if(HXCPP_STACK_LINE)		,"hxcpp_stack_line" #end
		#if(HXCPP_GC_GENERATIONAL)	,"hxcpp_gc_generational" #end
		#if(dce)					,"dce" #end
		#if(FLX_DEBUG)				,"flx_debug" #end
		#if(FLX_NO_DEBUG)			,"flx_no_debug" #end
		#if(FLX_NO_GAMEPAD)			,"flx_no_gamepad" #end
		#if(FLX_NO_TOUCH)			,"flx_no_touch" #end
		#if(FLX_NO_MOUSE)			,"flx_no_mouse" #end
		#if(FLX_NO_KEYBOARD)		,"flx_no_keyboard" #end
		#if(linc_luajit)			,"linc_luajit" #end
		#if(hscript)				,"hscript" #end
		#if(discord_rpc)			,"discord_rpc" #end
		#if(FLXRUNTIMESHADER)			,"flxruntimeshader" #end
		];
	}
}
class SEAxes{
	public static var X    = 0x01;
	public static var Y    = 0x10;
	public static var XY   = 0x11;
	public static var NONE = 0x00;
}
class SETools{
	public static var persistantVars:Map<String,Dynamic> = new Map<String,Dynamic>();
	static public function areSameType(o:Dynamic,c:Dynamic):Bool{
		return Type.typeof(o) == Type.typeof(c);
	}
	static public function keyFromString(key:String):FlxKey{
		return FlxKey.fromStringMap[key];
	}
	static public function keyToString(key:FlxKey):String{
		return FlxKey.toStringMap[key];
	}
	static public function loadSave(scope:String,save:String):SESave{
		return new SESave(scope,save);
	}
	static public function getFromPersistant(obj:String):Dynamic{
		return persistantVars.get(obj);
	}
	static public function addToPersistant(name:String,obj:Dynamic){
		return persistantVars.set(name,obj);
	}
	static public function removeFromPersistant(name:String){
		return persistantVars.set(name,null);
	}


	// Safely tweens an object while making sure the values actually exist
	// static public function tweenObject(o:Dynamic,values:Dynamic,duration:Float,?options:Null<TweenOptions>){ 
	// 	if(o == null){PlayState.instance.handleError('Cannot tween variables of an object that is null.');return;}
	// 	if(values == null){PlayState.instance.handleError('Cannot tween null properties.');return;}
	// 	for (i => v in values) {
	// 		if(Reflect.field(o,v.name) == null) {
	// 			PlayState.instance.handleError('Object does not have value ${v.name}');
	// 			return;
	// 		}
	// 		if(Type.typeof(Reflect.field(o,v.name)) != v.type ) {
	// 			PlayState.instance.handleError('Tweened value ${v.name} has type of ${v.type} but is trying to tween ${Type.typeof(Reflect.field(o,v.name))}');
	// 			return;
	// 		}
	// 	}
	// 	if(options != null){

	// 		if(options.onComplete != null){
	// 			var oldComplete = options.onComplete;
	// 			options.onComplete = function(t:FlxTween){
	// 				try{
	// 					oldComplete(t);
	// 				}catch(e){
	// 					PlayState.instance.handleError('An error occurred in tween complete: ${e.message}');
	// 				}
	// 			}
	// 		}
	// 		if(options.onStart != null){
	// 			var oldComplete = options.onStart;
	// 			options.onStart = function(t:FlxTween){
	// 				try{
	// 					oldComplete(t);
	// 				}catch(e){
	// 					PlayState.instance.handleError('An error occurred in tween start: ${e.message}');
	// 				}
	// 			}
	// 		}
	// 		if(options.onUpdate != null){
	// 			var oldComplete = options.onUpdate;
	// 			options.onUpdate = function(t:FlxTween){
	// 				try{
	// 					oldComplete(t);
	// 				}catch(e){
	// 					PlayState.instance.handleError('An error occurred in tween complete: ${e.message}');
	// 				}
	// 			}
	// 		}
	// 	}
	// 	FlxTween.tween(o,values,duration,options);
	// }
}
class SESave{
	var _map:Map<String,Dynamic> = new Map<String,Dynamic>();
	var _path = "";
	var _fileName = "";
	public var isNew:Bool = true;
	static function saveOptions(path:String,obj:Map<String,Dynamic>){
		var _obj:Array<OptionF> = [];
		for (i => v in obj) {
			_obj.push({name:i,value:v});
		}
		File.saveContent(path,Json.stringify(_obj));
	}
	static function loadOptions(str:String):Null<Map<String,Dynamic>>{ // Holy shit this is terrible but whatever
		
		var ret:Map<String,Dynamic> = new Map<String,Dynamic>();
		var obj:Array<OptionF> = Json.parse(CoolUtil.cleanJSON(str));
		if(obj == null) return null;
		for (i in obj) {
			ret[i.name] = i.value;
		}
		return ret;
	}
	public function flush(){
		sys.FileSystem.createDirectory(_path);
		saveOptions(_path + _fileName,_map);
	}
	public function wipe(){
		_map = new Map<String,Dynamic>();
	}
	public function new(scope:String,save:String){
		_path = 'mods/scriptOptions/saves/$scope/';
		_fileName = '$save.json';
		if(SELoader.exists(_path + _fileName)){
			_map = loadOptions(SELoader.loadText(_path + _fileName));
			isNew = false;
		}else{
			_map = new Map<String,Dynamic>();

		}
	}
	public function get(id:String,?def:Dynamic = null):Dynamic{
		return (if(_map[id] != null) _map[id] else def );
	}
	public function set(id:String,value:Dynamic){
		isNew = false;
		_map[id] = value;
		return;
	}
	public function toString(){
		return '[ Super Engine Save. Contents: ' + _map.toString() + " ]";
	}
}

// class SEType {
// 	static public function allEnums<T>(e:Enum<T>):Array<T>{
// 		return Type.allEnums(e);
// 	}
// 	static public function typeof(o:Dynamic):Dynamic{
// 		return Type.typeof(o);
// 	}
// 	static public function getSuperClass(o:Dynamic):Dynamic{
// 		return Type.getSuperClass(o);
// 	}
// 	static public function getClass(o:Dynamic):Dynamic{
// 		return Type.getClass(o);
// 	}
// 	static public function getClassFields(o:Class<Dynamic>):Array<String>{
// 		return Type.getClassFields(o);
// 	}
// 	static public function getClassName(o:Class<Dynamic>):Dynamic{
// 		return Type.getClassName(o);
// 	}
// 	static public function createInstance<T>(cl:Class<Dynamic>, args:Array<Dynamic>):T{
// 		return Type.createInstance(cl,args);
// 	}
// 	static public function createEmptyInstance<T>(cl:Class<Dynamic>):T{
// 		return Type.createEmptyInstance(cl);
// 	}
// 	static public function resolveClass(name:String):Dynamic{
// 		switch (name) {
// 			case "FileSystem" | "File":
// 				return FReplica;
// 			case "sys":
// 				return Class; // trol
// 			case "Type":
// 				return SEType;
// 		}

// 		return Type.resolveClass(name);
// 	}
// 	static public function resolveEnum(name:String):Enum<Dynamic>{
// 		return Type.resolveEnum(name);
// 	}
// 	static public function createEnum<T>(e:Enum<T>, constr:String, ?params:Array<Dynamic>):T{
// 		return Type.createEnum(e,constr,params);
// 	}
// }


// class SEType extends Type{
// 	static var classes:Map<String,Class<>> = ["FileSystem" => FReplica,];
// 	static public function getClass(o:T):Class<T>{
// 		return super.getClass(o);
// 	}
// }
class SEJson {
	public static function parse(txt:String):Dynamic{
		return Json.parse(CoolUtil.cleanJSON(txt));
	}
	public static function stringify(obj:Dynamic,?style:String = "fancy"):String{
		return Json.stringify(obj,style);
	}
}

class FReplica{
	static public function stat(P:String){
		return FileSystem.stat(SELoader.getPath(P));
	}
	static public function isDirectory(P:String){
		return SELoader.isDirectory(P);
	}
	static public function exists(P:String){
		return SELoader.exists(P);
	}
	static public function absolutePath(P:String){
		return SELoader.absolutePath(P);
	}
	static public function fullPath(P:String){
		return SELoader.fullPath(P);
	}
	static public function readDirectory(P:String){
		return SELoader.readDirectory(P);
	}
	static public function getContent(P:String){
		return SELoader.getContent(P);
	}
	static public function saveContent(P:String,con:String){
		return SELoader.saveContent(P,con);
	}
	static public function getBytes(P:String):haxe.io.Bytes{
		return SELoader.getBytes(P);
	}
}
// class BRTween extends FlxTween{ // Make sure errors are caught whenever a timer is used
// 	public static function tween(Object:Dynamic, Values:Dynamic, Duration:Float = 1, ?Options:TweenOptions):VarTween
// 	{
// 		if(Options != null){
// 			if(Options.onStart != null){
// 				var func = Options.onStart;
// 				Options.onStart = function(tween:flixel.tweens.FlxTween){
// 					try{
// 						func(tween);
// 					}catch(e){PlayState.handleError('An error occurred in a tween\'s onStart: ${e.message}');}
// 				}
// 			}
// 			if(Options.onComplete != null){
// 				var func = Options.onComplete;
// 				Options.onComplete = function(tween:flixel.tweens.FlxTween){
// 					try{
// 						func(tween);
// 					}catch(e){PlayState.handleError('An error occurred in a tween\'s onComplete: ${e.message}');}
// 				}
// 			}
// 		}
// 		return FlxTween.tween(Object, Values, Duration, Options);
// 	}
// }
class BRTimer extends FlxTimer{ // Make sure errors are caught whenever a timer is used
	override public function start(Time:Float = 1, ?OnComplete:FlxTimer->Void, Loops:Int = 1):FlxTimer
	{
		var __onComplete:Null<FlxTimer->Void> = null;
		if(OnComplete != null){
			
			__onComplete = function(timer:FlxTimer):Void{
				try{
					OnComplete(timer);
				}catch(e){PlayState.instance.handleError('An error occurred in a Timer: ${e.message}');}
			}
		}
		return super.start(Time,__onComplete,Loops);
	}
}


class SESettings{
	public static function get(id:String):Dynamic{
		return Reflect.field(SESave.data,id);
	}
}

class HscriptColor{
	// Copy-pasted
	public static var TRANSPARENT:FlxColor = 0x00000000;
	public static var WHITE:FlxColor = 0xFFFFFFFF;
	public static var GRAY:FlxColor = 0xFF808080;
	public static var BLACK:FlxColor = 0xFF000000;

	public static var GREEN:FlxColor = 0xFF008000;
	public static var LIME:FlxColor = 0xFF00FF00;
	public static var YELLOW:FlxColor = 0xFFFFFF00;
	public static var ORANGE:FlxColor = 0xFFFFA500;
	public static var RED:FlxColor = 0xFFFF0000;
	public static var PURPLE:FlxColor = 0xFF800080;
	public static var BLUE:FlxColor = 0xFF0000FF;
	public static var BROWN:FlxColor = 0xFF8B4513;
	public static var PINK:FlxColor = 0xFFFFC0CB;
	public static var MAGENTA:FlxColor = 0xFFFF00FF;
	public static var CYAN:FlxColor = 0xFF00FFFF;
	public static function fromInt(Value:Int):FlxColor
	{
		return new FlxColor(Value);
	}
	static var COLOR_REGEX = ~/^(0x|#)(([A-F0-9]{2}){3,4})$/i;
	static var colorLookup = FlxColor.colorLookup;
	public static function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):FlxColor
	{
		var color = new FlxColor();
		return color.setRGB(Red, Green, Blue, Alpha);
	}
	public static function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):FlxColor
	{
		var color = new FlxColor();
		return color.setRGBFloat(Red, Green, Blue, Alpha);
	}
	public static function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):FlxColor
	{
		var color = new FlxColor();
		return color.setCMYK(Cyan, Magenta, Yellow, Black, Alpha);
	}
	public static function fromHSB(Hue:Float, Saturation:Float, Brightness:Float, Alpha:Float = 1):FlxColor
	{
		var color = new FlxColor();
		return color.setHSB(Hue, Saturation, Brightness, Alpha);
	}
	public static function fromHSL(Hue:Float, Saturation:Float, Lightness:Float, Alpha:Float = 1):FlxColor
	{
		var color = new FlxColor();
		return color.setHSL(Hue, Saturation, Lightness, Alpha);
	}
	public static function fromString(str:String):Null<FlxColor>
	{
		var result:Null<FlxColor> = null;
		str = StringTools.trim(str);

		if (COLOR_REGEX.match(str))
		{
			var hexColor:String = "0x" + COLOR_REGEX.matched(2);
			result = new FlxColor(Std.parseInt(hexColor));
			if (hexColor.length == 8)
			{
				result.alphaFloat = 1;
			}
		}
		else
		{
			str = str.toUpperCase();
			for (key in colorLookup.keys())
			{
				if (key.toUpperCase() == str)
				{
					result = new FlxColor(FlxColor.colorLookup.get(key));
					break;
				}
			}
		}

		return result;
	}
	public static function getHSBColorWheel(Alpha:Int = 255):Array<FlxColor>
	{
		return [for (c in 0...360) fromHSB(c, 1.0, 1.0, Alpha)];
	}
	public static function interpolate(Color1:FlxColor, Color2:FlxColor, Factor:Float = 0.5):FlxColor
	{
		var r:Int = Std.int((Color2.red - Color1.red) * Factor + Color1.red);
		var g:Int = Std.int((Color2.green - Color1.green) * Factor + Color1.green);
		var b:Int = Std.int((Color2.blue - Color1.blue) * Factor + Color1.blue);
		var a:Int = Std.int((Color2.alpha - Color1.alpha) * Factor + Color1.alpha);

		return fromRGB(r, g, b, a);
	}
	public static function gradient(Color1:FlxColor, Color2:FlxColor, Steps:Int, ?Ease:Float->Float):Array<FlxColor>
	{
		var output = new Array<FlxColor>();

		if (Ease == null)
		{
			Ease = function(t:Float):Float
			{
				return t;
			}
		}

		for (step in 0...Steps)
		{
			output[step] = interpolate(Color1, Color2, Ease(step / (Steps - 1)));
		}

		return output;
	}

	public static function multiply(lhs:FlxColor, rhs:FlxColor):FlxColor
	{
		return FlxColor.fromRGBFloat(lhs.redFloat * rhs.redFloat, lhs.greenFloat * rhs.greenFloat, lhs.blueFloat * rhs.blueFloat);
	}
	public static function add(lhs:FlxColor, rhs:FlxColor):FlxColor
	{
		return FlxColor.fromRGB(lhs.red + rhs.red, lhs.green + rhs.green, lhs.blue + rhs.blue);
	}
	public static function subtract(lhs:FlxColor, rhs:FlxColor):FlxColor
	{
		return FlxColor.fromRGB(lhs.red - rhs.red, lhs.green - rhs.green, lhs.blue - rhs.blue);
	}


	// Custom shit
	public static function getRed(color:FlxColor):Int{
		return color.red;
	}
	public static function getBlue(color:FlxColor):Int{
		return color.blue;
	}
	public static function getGreen(color:FlxColor):Int{
		return color.green;
	}
	public static function getAlpha(color:FlxColor):Int{
		return color.alpha;
	}
	public static function getRedFloat(color:FlxColor):Float{
		return color.redFloat;
	}
	public static function getBlueFloat(color:FlxColor):Float{
		return color.blueFloat;
	}
	public static function getGreenFloat(color:FlxColor):Float{
		return color.greenFloat;
	}
	public static function getAlphaFloat(color:FlxColor):Float{
		return color.alphaFloat;
	}
	public static function getSaturation(color:FlxColor):Float{
		return color.saturation;
	}
	public static function getHue(color:FlxColor):Float{
		return color.hue;
	}
	public static function getBrightness(color:FlxColor):Float{
		return color.brightness;
	}
	public static function getLightness(color:FlxColor):Float{
		return color.lightness;
	}
	public static function setRed(color:FlxColor,value:Int):FlxColor{
		color.red = value;
		return color;
	}
	public static function setBlue(color:FlxColor,value:Int):FlxColor{
		color.blue = value;
		return color;
	}
	public static function setGreen(color:FlxColor,value:Int):FlxColor{
		color.green = value;
		return color;
	}
	public static function setAlpha(color:FlxColor,value:Int):FlxColor{
		color.alpha = value;
		return color;
	}
	public static function setRedFloat(color:FlxColor,value:Float):FlxColor{
		color.redFloat = value;
		return color;
	}
	public static function setBlueFloat(color:FlxColor,value:Float):FlxColor{
		color.blueFloat = value;
		return color;
	}
	public static function setGreenFloat(color:FlxColor,value:Float):FlxColor{
		color.greenFloat = value;
		return color;
	}
	public static function setAlphaFloat(color:FlxColor,value:Float):FlxColor{
		color.alphaFloat = value;
		return color;
	}
	public static function setSaturation(color:FlxColor,value:Float):FlxColor{
		color.saturation = value;
		return color;
	}
	public static function setHue(color:FlxColor,value:Float):FlxColor{
		color.hue = value;
		return color;
	}
	public static function setBrightness(color:FlxColor,value:Float):FlxColor{
		color.brightness = value;
		return color;
	}
	public static function setLightness(color:FlxColor,value:Float):FlxColor{
		color.lightness = value;
		return color;
	}

}




class HscriptGlobals {
	public static var VERSION = FlxG.VERSION;
	public static var autoPause(get, set):Bool;
	public static var bitmap(get, never):BitmapFrontEnd;
	// no bitmapLog
	public static var camera(get ,set):FlxCamera;
	public static var cameras(get, never):CameraFrontEnd;
	// no console frontend
	// no debugger frontend
	public static var drawFramerate(get, set):Int;
	public static var elapsed(get, never):Float;
	public static var fixedTimestep(get, set):Bool;
	public static var fullscreen(get, set):Bool;
	public static var game(get, never):FlxGame;
	public static var gamepads(get, never):FlxGamepadManager;
	public static var height(get, never):Int;
	public static var initialHeight(get, never):Int;
	public static var initialWidth(get, never):Int;
	public static var keys(get, never):FlxKeyboard;
	// no log
	public static var maxElapsed(get, set):Float;
	public static var mouse(get,never):flixel.input.mouse.FlxMouse;
	public static var plugins:flixel.system.frontEnds.PluginFrontEnd;
	public static var random(default,never):SERandom = new SERandom();
	public static var renderBlit(get, never):Bool;
	public static var renderMethod(get, never):FlxRenderMethod;
	public static var renderTile(get, never):Bool;
	public static var stage(get, never):Stage;
	public static var state(get, never):FlxState;
	public static var swipes(get,never):Array<flixel.input.FlxSwipe>;
	public static var touches(get,never):flixel.input.touch.FlxTouchManager;

	public static var timeScale(get, set):Float;

	public static var updateFramerate(get,set):Int;
	// no vcr : )
	// no watch : )
	public static var width(get, never):Int;
	public static var worldBounds(get, never):FlxRect;
	public static var worldDivisions(get, set):Int;

	public static var sound(get,never):SoundFrontEnd;
	public static function init() {
	}
	static function get_swipes(){
		return FlxG.swipes;
	}
	static function get_touches(){
		return FlxG.touches;
	}
	static function get_plugins(){
		return FlxG.plugins;
	}
	static function get_sound(){
		return FlxG.sound;
	}
	static function get_bitmap() {
		return FlxG.bitmap;
	}
	static function get_cameras() {
		return FlxG.cameras;
	}
	static function get_autoPause():Bool {
		return FlxG.autoPause;
	}
	static function set_autoPause(b:Bool):Bool {
		return FlxG.autoPause = b;
	}
	static function get_drawFramerate():Int
	{
		return FlxG.drawFramerate;
	}

	static function set_drawFramerate(b:Int):Int
	{
		return FlxG.drawFramerate = b;
	}
	static function get_elapsed():Float {
		return FlxG.elapsed;
	}
	// static function get_random():SERandom
	// {
	// 	return SERandom;
	// }
	static function get_mouse():flixel.input.mouse.FlxMouse
	{
		return FlxG.mouse;
	}
	static function get_fixedTimestep():Bool
	{
		return FlxG.fixedTimestep;
	}

	static function set_fixedTimestep(b:Bool):Bool
	{
		return FlxG.fixedTimestep = b;
	}
	static function get_fullscreen():Bool
	{
		return FlxG.fullscreen;
	}

	static function set_fullscreen(b:Bool):Bool
	{
		return FlxG.fullscreen = b;
	}
	static function get_height():Int {
		return FlxG.height;
	}
	static function get_initialHeight():Int {
		return FlxG.initialHeight;
	}
	static function get_camera():FlxCamera {
		return FlxG.camera;
	}
	static function set_camera(c:FlxCamera):FlxCamera {
		return FlxG.camera = c;
	}
	static function get_game():FlxGame {
		return FlxG.game;
	}
	static function get_gamepads():FlxGamepadManager {

		#if (FLX_NO_GAMEPAD)
			return null;
		#else
			return FlxG.gamepads;
		#end
	}
	static function get_initialWidth():Int {
		return FlxG.initialWidth;
	}

	static function get_inputs() {
		return FlxG.inputs;
	}
	static function get_keys() {
		return FlxG.keys;
	}
	static function set_maxElapsed(s) {
		return FlxG.maxElapsed = s;
	}
	static function get_maxElapsed() {
		return FlxG.maxElapsed;
	}
	static function get_renderBlit() {
		return FlxG.renderBlit;
	}
	static function get_renderMethod() {
		return FlxG.renderMethod;
	}
	static function get_renderTile() {
		return FlxG.renderTile;
	}
	static function get_stage() {
		return FlxG.stage;
	}
	static function get_state() {
		return FlxG.state;
	}
	static function set_timeScale(s) {
		return FlxG.timeScale = s;
	}
	static function get_timeScale() {
		return FlxG.timeScale;
	}
	static function set_updateFramerate(s) {
		return FlxG.updateFramerate = s;
	}
	static function get_updateFramerate() {
		return FlxG.updateFramerate;
	}
	static function get_width() {
		return FlxG.width;
	}
	static function get_worldBounds() {
		return FlxG.worldBounds;
	}
	static function get_worldDivisions() {
		return FlxG.worldDivisions;
	}
	static function set_worldDivisions(s)
	{
		return FlxG.worldDivisions = s;
	}

	public static function addChildBelowMouse<T:DisplayObject>(Child:T, IndexModifier:Int = 0):T {
		return FlxG.addChildBelowMouse(Child, IndexModifier);
	}
	public static function collide(?ObjectOrGroup1, ?ObjectOrGroup2, ?NotifyCallback) {
		return FlxG.collide(ObjectOrGroup1, ObjectOrGroup2, NotifyCallback);
	}
	// no open url because i don't trust you guys

	public static function overlap(?ObjectOrGroup1, ?ObjectOrGroup2, ?NotifyCallback, ?ProcessCallback)
	{
		return FlxG.overlap(ObjectOrGroup1, ObjectOrGroup2, NotifyCallback, ProcessCallback);
	}
	public static function pixelPerfectOverlap(Sprite1, Sprite2, AlphaTolerance = 255, ?Camera) {
		return FlxG.pixelPerfectOverlap(Sprite1, Sprite2, AlphaTolerance, Camera);
	}
	public static function removeChild<T:DisplayObject>(Child:T):T {
		return FlxG.removeChild(Child);
	}
}



// Litterally just FlxMath but without inline
class SEMath
{
	#if (flash || js || ios || blackberry)
	/**
	 * Minimum value of a floating point number.
	 */
	public static var MIN_VALUE_FLOAT:Float = 0.0000000000000001;
	#else

	/**
	 * Minimum value of a floating point number.
	 */
	public static var MIN_VALUE_FLOAT:Float = 5e-324;
	#end

	/**
	 * Maximum value of a floating point number.
	 */
	public static var MAX_VALUE_FLOAT:Float = 1.79e+308;

	/**
	 * Minimum value of an integer.
	 */
	public static var MIN_VALUE_INT:Int = -MAX_VALUE_INT;

	/**
	 * Maximum value of an integer.
	 */
	public static var MAX_VALUE_INT:Int = 0x7FFFFFFF;

	/**
	 * Approximation of `Math.sqrt(2)`.
	 */
	public static var SQUARE_ROOT_OF_TWO:Float = 1.41421356237;

	/**
	 * Used to account for floating-point inaccuracies.
	 */
	public static var EPSILON:Float = 0.0000001;

	/**
	 * Round a decimal number to have reduced precision (less decimal numbers).
	 *
	 * ```haxe
	 * roundDecimal(1.2485, 2) = 1.25
	 * ```
	 *
	 * @param	Value		Any number.
	 * @param	Precision	Number of decimals the result should have.
	 * @return	The rounded value of that number.
	 */
	public static function roundDecimal(Value:Float, Precision:Int):Float
	{
		var mult:Float = 1;
		for (i in 0...Precision)
		{
			mult *= 10;
		}
		return Math.fround(Value * mult) / mult;
	}

	/**
	 * Bound a number by a minimum and maximum. Ensures that this number is
	 * no smaller than the minimum, and no larger than the maximum.
	 * Leaving a bound `null` means that side is unbounded.
	 *
	 * @param	Value	Any number.
	 * @param	Min		Any number.
	 * @param	Max		Any number.
	 * @return	The bounded value of the number.
	 */
	public static function bound(Value:Float, ?Min:Float, ?Max:Float):Float
	{
		var lowerBound:Float = (Min != null && Value < Min) ? Min : Value;
		return (Max != null && lowerBound > Max) ? Max : lowerBound;
	}

	/**
	 * Returns the linear interpolation of two numbers if `ratio`
	 * is between 0 and 1, and the linear extrapolation otherwise.
	 *
	 * Examples:
	 *
	 * ```haxe
	 * lerp(a, b, 0) = a
	 * lerp(a, b, 1) = b
	 * lerp(5, 15, 0.5) = 10
	 * lerp(5, 15, -1) = -5
	 * ```
	 */
	public static function lerp(a:Float, b:Float, ratio:Float):Float
	{
		return a + ratio * (b - a);
	}

	/**
	 * Checks if number is in defined range. A null bound means that side is unbounded.
	 *
	 * @param Value		Number to check.
	 * @param Min		Lower bound of range.
	 * @param Max 		Higher bound of range.
	 * @return Returns true if Value is in range.
	 */
	public static function inBounds(Value:Float, Min:Null<Float>, Max:Null<Float>):Bool
	{
		return (Min == null || Value >= Min) && (Max == null || Value <= Max);
	}

	/**
	 * Returns `true` if the given number is odd.
	 */
	public static function isOdd(n:Float):Bool
	{
		return (Std.int(n) & 1) != 0;
	}

	/**
	 * Returns `true` if the given number is even.
	 */
	public static function isEven(n:Float):Bool
	{
		return (Std.int(n) & 1) == 0;
	}

	/**
	 * Returns `-1` if `a` is smaller, `1` if `b` is bigger and `0` if both numbers are equal.
	 */
	public static function numericComparison(a:Float, b:Float):Int
	{
		if (b > a)
		{
			return -1;
		}
		else if (a > b)
		{
			return 1;
		}
		return 0;
	}

	/**
	 * Returns true if the given x/y coordinate is within the given rectangular block
	 *
	 * @param	pointX		The X value to test
	 * @param	pointY		The Y value to test
	 * @param	rectX		The X value of the region to test within
	 * @param	rectY		The Y value of the region to test within
	 * @param	rectWidth	The width of the region to test within
	 * @param	rectHeight	The height of the region to test within
	 *
	 * @return	true if pointX/pointY is within the region, otherwise false
	 */
	public static function pointInCoordinates(pointX:Float, pointY:Float, rectX:Float, rectY:Float, rectWidth:Float, rectHeight:Float):Bool
	{
		return (pointX >= rectX && pointX <= (rectX + rectWidth)) && (pointY >= rectY && pointY <= (rectY + rectHeight));
	}
	// what the hell flixel
	// 	public static function pointInCoordinates(pointX:Float, pointY:Float, rectX:Float, rectY:Float, rectWidth:Float, rectHeight:Float):Bool
	// {
	// 	if (pointX >= rectX && pointX <= (rectX + rectWidth))
	// 	{
	// 		if (pointY >= rectY && pointY <= (rectY + rectHeight))
	// 		{
	// 			return true;
	// 		}
	// 	}
	// 	return false;
	// }

	/**
	 * Returns true if the given x/y coordinate is within the given rectangular block
	 *
	 * @param	pointX		The X value to test
	 * @param	pointY		The Y value to test
	 * @param	rect		The FlxRect to test within
	 * @return	true if pointX/pointY is within the FlxRect, otherwise false
	 */
	public static function pointInFlxRect(pointX:Float, pointY:Float, rect:FlxRect):Bool
	{
		return pointX >= rect.x && pointX <= rect.right && pointY >= rect.y && pointY <= rect.bottom;
	}

	#if FLX_MOUSE
	/**
	 * Returns true if the mouse world x/y coordinate are within the given rectangular block
	 *
	 * @param	useWorldCoords	If true the world x/y coordinates of the mouse will be used, otherwise screen x/y
	 * @param	rect			The FlxRect to test within. If this is null for any reason this function always returns true.
	 *
	 * @return	true if mouse is within the FlxRect, otherwise false
	 */
	public static function mouseInFlxRect(useWorldCoords:Bool, rect:FlxRect):Bool
	{
		if (rect == null)
		{
			return true;
		}

		if (useWorldCoords)
		{
			return pointInFlxRect(Math.floor(FlxG.mouse.x), Math.floor(FlxG.mouse.y), rect);
		}
		else
		{
			return pointInFlxRect(FlxG.mouse.screenX, FlxG.mouse.screenY, rect);
		}
	}
	#end

	/**
	 * Returns true if the given x/y coordinate is within the Rectangle
	 *
	 * @param	pointX		The X value to test
	 * @param	pointY		The Y value to test
	 * @param	rect		The Rectangle to test within
	 * @return	true if pointX/pointY is within the Rectangle, otherwise false
	 */
	public static function pointInRectangle(pointX:Float, pointY:Float, rect:Rectangle):Bool
	{
		return pointX >= rect.x && pointX <= rect.right && pointY >= rect.y && pointY <= rect.bottom;
	}

	/**
	 * Adds the given amount to the value, but never lets the value
	 * go over the specified maximum or under the specified minimum.
	 *
	 * @param 	value 	The value to add the amount to
	 * @param 	amount 	The amount to add to the value
	 * @param 	max 	The maximum the value is allowed to be
	 * @param 	min 	The minimum the value is allowed to be
	 * @return The new value
	 */
	public static function maxAdd(value:Int, amount:Int, max:Int, min:Int = 0):Int
	{
		value += amount;
		return (value > max ? max : (value <= min ? min : value));
	}

	/**
	 * Makes sure that value always stays between 0 and max,
	 * by wrapping the value around.
	 *
	 * @param 	value 	The value to wrap around
	 * @param 	min		The minimum the value is allowed to be
	 * @param 	max 	The maximum the value is allowed to be
	 * @return The wrapped value
	 */
	public static function wrap(value:Int, min:Int, max:Int):Int
	{
		var range:Int = max - min + 1;

		if (value < min)
			value += range * Std.int((min - value) / range + 1);

		return min + (value - min) % range;
	}

	/**
	 * Remaps a number from one range to another.
	 *
	 * @param 	value	The incoming value to be converted
	 * @param 	start1 	Lower bound of the value's current range
	 * @param 	stop1 	Upper bound of the value's current range
	 * @param 	start2  Lower bound of the value's target range
	 * @param 	stop2 	Upper bound of the value's target range
	 * @return The remapped value
	 */
	public static function remapToRange(value:Float, start1:Float, stop1:Float, start2:Float, stop2:Float):Float
	{
		return start2 + (value - start1) * ((stop2 - start2) / (stop1 - start1));
	}

	/**
	 * Finds the dot product value of two vectors
	 *
	 * @param	ax		Vector X
	 * @param	ay		Vector Y
	 * @param	bx		Vector X
	 * @param	by		Vector Y
	 *
	 * @return	Result of the dot product
	 */
	public static function dotProduct(ax:Float, ay:Float, bx:Float, by:Float):Float
	{
		return ax * bx + ay * by;
	}

	/**
	 * Returns the length of the given vector.
	 */
	public static function vectorLength(dx:Float, dy:Float):Float
	{
		return Math.sqrt(dx * dx + dy * dy);
	}

	/**
	 * Find the distance (in pixels, rounded) between two FlxSprites, taking their origin into account
	 *
	 * @param	SpriteA		The first FlxSprite
	 * @param	SpriteB		The second FlxSprite
	 * @return	Distance between the sprites in pixels
	 */
	public static function distanceBetween(SpriteA:FlxSprite, SpriteB:FlxSprite):Int
	{
		var dx:Float = (SpriteA.x + SpriteA.origin.x) - (SpriteB.x + SpriteB.origin.x);
		var dy:Float = (SpriteA.y + SpriteA.origin.y) - (SpriteB.y + SpriteB.origin.y);
		return Std.int(SEMath.vectorLength(dx, dy));
	}

	/**
	 * Check if the distance between two FlxSprites is within a specified number.
	 * A faster algorithm than distanceBetween because the Math.sqrt() is avoided.
	 *
	 * @param	SpriteA		The first FlxSprite
	 * @param	SpriteB		The second FlxSprite
	 * @param	Distance	The distance to check
	 * @param	IncludeEqual	If set to true, the function will return true if the calculated distance is equal to the given Distance
	 * @return	True if the distance between the sprites is less than the given Distance
	 */
	public static function isDistanceWithin(SpriteA:FlxSprite, SpriteB:FlxSprite, Distance:Float, IncludeEqual:Bool = false):Bool
	{
		var dx:Float = (SpriteA.x + SpriteA.origin.x) - (SpriteB.x + SpriteB.origin.x);
		var dy:Float = (SpriteA.y + SpriteA.origin.y) - (SpriteB.y + SpriteB.origin.y);

		if (IncludeEqual)
			return dx * dx + dy * dy <= Distance * Distance;
		else
			return dx * dx + dy * dy < Distance * Distance;
	}

	/**
	 * Find the distance (in pixels, rounded) from an FlxSprite
	 * to the given FlxPoint, taking the source origin into account.
	 *
	 * @param	Sprite	The FlxSprite
	 * @param	Target	The FlxPoint
	 * @return	Distance in pixels
	 */
	public static function distanceToPoint(Sprite:FlxSprite, Target:FlxPoint):Int
	{
		var dx:Float = (Sprite.x + Sprite.origin.x) - Target.x;
		var dy:Float = (Sprite.y + Sprite.origin.y) - Target.y;
		Target.putWeak();
		return Std.int(SEMath.vectorLength(dx, dy));
	}

	/**
	 * Check if the distance from an FlxSprite to the given
	 * FlxPoint is within a specified number.
	 * A faster algorithm than distanceToPoint because the Math.sqrt() is avoided.
	 *
	 * @param	Sprite	The FlxSprite
	 * @param	Target	The FlxPoint
	 * @param	Distance	The distance to check
	 * @param	IncludeEqual	If set to true, the function will return true if the calculated distance is equal to the given Distance
	 * @return	True if the distance between the sprites is less than the given Distance
	 */
	public static function isDistanceToPointWithin(Sprite:FlxSprite, Target:FlxPoint, Distance:Float, IncludeEqual:Bool = false):Bool
	{
		var dx:Float = (Sprite.x + Sprite.origin.x) - (Target.x);
		var dy:Float = (Sprite.y + Sprite.origin.y) - (Target.y);

		Target.putWeak();

		if (IncludeEqual)
			return dx * dx + dy * dy <= Distance * Distance;
		else
			return dx * dx + dy * dy < Distance * Distance;
	}

	#if FLX_MOUSE
	/**
	 * Find the distance (in pixels, rounded) from the object x/y and the mouse x/y
	 *
	 * @param	Sprite	The FlxSprite to test against
	 * @return	The distance between the given sprite and the mouse coordinates
	 */
	public static function distanceToMouse(Sprite:FlxSprite):Int
	{
		var dx:Float = (Sprite.x + Sprite.origin.x) - FlxG.mouse.screenX;
		var dy:Float = (Sprite.y + Sprite.origin.y) - FlxG.mouse.screenY;
		return Std.int(SEMath.vectorLength(dx, dy));
	}

	/**
	 * Check if the distance from the object x/y and the mouse x/y is within a specified number.
	 * A faster algorithm than distanceToMouse because the Math.sqrt() is avoided.
	 *
	 * @param	Sprite		The FlxSprite to test against
	 * @param	Distance	The distance to check
	 * @param	IncludeEqual	If set to true, the function will return true if the calculated distance is equal to the given Distance
	 * @return	True if the distance between the sprites is less than the given Distance
	 */
	public static function isDistanceToMouseWithin(Sprite:FlxSprite, Distance:Float, IncludeEqual:Bool = false):Bool
	{
		var dx:Float = (Sprite.x + Sprite.origin.x) - FlxG.mouse.screenX;
		var dy:Float = (Sprite.y + Sprite.origin.y) - FlxG.mouse.screenY;

		if (IncludeEqual)
			return dx * dx + dy * dy <= Distance * Distance;
		else
			return dx * dx + dy * dy < Distance * Distance;
	}
	#end

	#if FLX_TOUCH
	/**
	 * Find the distance (in pixels, rounded) from the object x/y and the FlxPoint screen x/y
	 *
	 * @param	Sprite	The FlxSprite to test against
	 * @param	Touch	The FlxTouch to test against
	 * @return	The distance between the given sprite and the mouse coordinates
	 */
	public static function distanceToTouch(Sprite:FlxSprite, Touch:FlxTouch):Int
	{
		var dx:Float = (Sprite.x + Sprite.origin.x) - Touch.screenX;
		var dy:Float = (Sprite.y + Sprite.origin.y) - Touch.screenY;
		return Std.int(SEMath.vectorLength(dx, dy));
	}

	/**
	 * Check if the distance from the object x/y and the FlxPoint screen x/y is within a specified number.
	 * A faster algorithm than distanceToTouch because the Math.sqrt() is avoided.
	 *
	 * @param	Sprite	The FlxSprite to test against
	 * @param	Distance	The distance to check
	 * @param	IncludeEqual	If set to true, the function will return true if the calculated distance is equal to the given Distance
	 * @return	True if the distance between the sprites is less than the given Distance
	 */
	public static function isDistanceToTouchWithin(Sprite:FlxSprite, Touch:FlxTouch, Distance:Float, IncludeEqual:Bool = false):Bool
	{
		var dx:Float = (Sprite.x + Sprite.origin.x) - Touch.screenX;
		var dy:Float = (Sprite.y + Sprite.origin.y) - Touch.screenY;

		if (IncludeEqual)
			return dx * dx + dy * dy <= Distance * Distance;
		else
			return dx * dx + dy * dy < Distance * Distance;
	}
	#end

	/**
	 * Returns the amount of decimals a `Float` has.
	 */
	public static function getDecimals(n:Float):Int
	{
		var helperArray:Array<String> = Std.string(n).split(".");
		var decimals:Int = 0;

		if (helperArray.length > 1)
		{
			decimals = helperArray[1].length;
		}

		return decimals;
	}

	public static function equal(aValueA:Float, aValueB:Float, aDiff:Float = 0.0000001):Bool
	{
		return (Math.abs(aValueA - aValueB) <= aDiff);
	}

	/**
	 * Returns `-1` if the number is smaller than `0` and `1` otherwise
	 */
	public static function signOf(n:Float):Int
	{
		return (n < 0) ? -1 : 1;
	}

	/**
	 * Checks if two numbers have the same sign (using `FlxMath.signOf()`).
	 */
	public static function sameSign(a:Float, b:Float):Bool
	{
		return signOf(a) == signOf(b);
	}

	/**
	 * A faster but slightly less accurate version of `Math.sin()`.
	 * About 2-6 times faster with < 0.05% average error.
	 *
	 * @param	n	The angle in radians.
	 * @return	An approximated sine of `n`.
	 */
	public static function fastSin(n:Float):Float
	{
		n *= 0.3183098862; // divide by pi to normalize

		// bound between -1 and 1
		if (n > 1)
		{
			n -= (Math.ceil(n) >> 1) << 1;
		}
		else if (n < -1)
		{
			n += (Math.ceil(-n) >> 1) << 1;
		}

		// this approx only works for -pi <= rads <= pi, but it's quite accurate in this region
		if (n > 0)
		{
			return n * (3.1 + n * (0.5 + n * (-7.2 + n * 3.6)));
		}
		else
		{
			return n * (3.1 - n * (0.5 + n * (7.2 + n * 3.6)));
		}
	}

	/**
	 * A faster, but less accurate version of `Math.cos()`.
	 * About 2-6 times faster with < 0.05% average error.
	 *
	 * @param	n	The angle in radians.
	 * @return	An approximated cosine of `n`.
	 */
	public static function fastCos(n:Float):Float
	{
		return fastSin(n + 1.570796327); // sin and cos are the same, offset by pi/2
	}

	/**
	 * Hyperbolic sine.
	 */
	public static function sinh(n:Float):Float
	{
		return (Math.exp(n) - Math.exp(-n)) / 2;
	}

	/**
	 * Returns the bigger argument.
	 */
	public static function maxInt(a:Int, b:Int):Int
	{
		return (a > b) ? a : b;
	}

	/**
	 * Returns the smaller argument.
	 */
	public static function minInt(a:Int, b:Int):Int
	{
		return (a > b) ? b : a;
	}

	/**
	 * Returns the absolute integer value.
	 */
	public static function absInt(n:Int):Int
	{
		return (n > 0) ? n : -n;
	}
}



/*
 * Copyright (C)2005-2019 Haxe Foundation
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



/**
	This class provides advanced methods on Strings. It is ideally used with
	`using StringTools` and then acts as an [extension](https://haxe.org/manual/lf-static-extension.html)
	to the `String` class.

	If the first argument to any of the methods is null, the result is
	unspecified.
**/

// I hate improperly used inlines

class SEStringTools {
	/**
		Encode an URL by using the standard format.
	**/
	  public static function urlEncode(s:String):String {
		#if flash
		return untyped __global__["encodeURIComponent"](s);
		#elseif neko
		return untyped new String(_urlEncode(s.__s));
		#elseif js
		return untyped encodeURIComponent(s);
		#elseif cpp
		return untyped s.__URLEncode();
		#elseif java
		return postProcessUrlEncode(java.net.URLEncoder.encode(s, "UTF-8"));
		#elseif cs
		return untyped cs.system.Uri.EscapeDataString(s);
		#elseif python
		return python.lib.urllib.Parse.quote(s, "");
		#elseif hl
		var len = 0;
		var b = @:privateAccess s.bytes.urlEncode(len);
		return @:privateAccess String.__alloc__(b, len);
		#elseif lua
		s = lua.NativeStringTools.gsub(s, "\n", "\r\n");
		s = lua.NativeStringTools.gsub(s, "([^%w %-%_%.%~])", function(c) {
			return lua.NativeStringTools.format("%%%02X", lua.NativeStringTools.byte(c) + '');
		});
		s = lua.NativeStringTools.gsub(s, " ", "+");
		return s;
		#else
		return null;
		#end
	}

	#if java
	private static function postProcessUrlEncode(s:String):String {
		var ret = new StringBuf();
		var i = 0, len = s.length;
		while (i < len) {
			switch (_charAt(s, i++)) {
				case '+'.code:
					ret.add('%20');
				case '%'.code if (i <= len - 2):
					var c1 = _charAt(s, i++), c2 = _charAt(s, i++);
					switch [c1, c2] {
						case ['2'.code, '1'.code]:
							ret.addChar('!'.code);
						case ['2'.code, '7'.code]:
							ret.addChar('\''.code);
						case ['2'.code, '8'.code]:
							ret.addChar('('.code);
						case ['2'.code, '9'.code]:
							ret.addChar(')'.code);
						case ['7'.code, 'E'.code] | ['7'.code, 'e'.code]:
							ret.addChar('~'.code);
						case _:
							ret.addChar('%'.code);
							ret.addChar(cast c1);
							ret.addChar(cast c2);
					}
				case var chr:
					ret.addChar(cast chr);
			}
		}
		return ret.toString();
	}
	#end

	/**
		Decode an URL using the standard format.
	**/
	  public static function urlDecode(s:String):String {
		#if flash
		return untyped __global__["decodeURIComponent"](s.split("+").join(" "));
		#elseif neko
		return untyped new String(_urlDecode(s.__s));
		#elseif js
		return untyped decodeURIComponent(s.split("+").join(" "));
		#elseif cpp
		return untyped s.__URLDecode();
		#elseif java
		try
			return java.net.URLDecoder.decode(s, "UTF-8")
		catch (e:Dynamic)
			throw e;
		#elseif cs
		return untyped cs.system.Uri.UnescapeDataString(s);
		#elseif python
		return python.lib.urllib.Parse.unquote(s);
		#elseif hl
		var len = 0;
		var b = @:privateAccess s.bytes.urlDecode(len);
		return @:privateAccess String.__alloc__(b, len);
		#elseif lua
		s = lua.NativeStringTools.gsub(s, "+", " ");
		s = lua.NativeStringTools.gsub(s, "%%(%x%x)", function(h) {
			return lua.NativeStringTools.char(lua.Lua.tonumber(h, 16));
		});
		s = lua.NativeStringTools.gsub(s, "\r\n", "\n");
		return s;
		#else
		return null;
		#end
	}

	/**
		Escapes HTML special characters of the string `s`.

		The following replacements are made:

		- `&` becomes `&amp`;
		- `<` becomes `&lt`;
		- `>` becomes `&gt`;

		If `quotes` is true, the following characters are also replaced:

		- `"` becomes `&quot`;
		- `'` becomes `&#039`;
	**/
	public static function htmlEscape(s:String, ?quotes:Bool):String {
		var buf = new StringBuf();
		for (code in #if neko iterator(s) #else new haxe.iterators.StringIteratorUnicode(s) #end) {
			switch (code) {
				case '&'.code:
					buf.add("&amp;");
				case '<'.code:
					buf.add("&lt;");
				case '>'.code:
					buf.add("&gt;");
				case '"'.code if (quotes):
					buf.add("&quot;");
				case '\''.code if (quotes):
					buf.add("&#039;");
				case _:
					buf.addChar(code);
			}
		}
		return buf.toString();
	}

	/**
		Unescapes HTML special characters of the string `s`.

		This is the inverse operation to htmlEscape, i.e. the following always
		holds: `htmlUnescape(htmlEscape(s)) == s`

		The replacements follow:

		- `&amp;` becomes `&`
		- `&lt;` becomes `<`
		- `&gt;` becomes `>`
		- `&quot;` becomes `"`
		- `&#039;` becomes `'`
	**/
	public static function htmlUnescape(s:String):String {
		return s.split("&gt;")
			.join(">")
			.split("&lt;")
			.join("<")
			.split("&quot;")
			.join('"')
			.split("&#039;")
			.join("'")
			.split("&amp;")
			.join("&");
	}

	/**
		Returns `true` if `s` contains `value` and  `false` otherwise.

		When `value` is `null`, the result is unspecified.
	**/
	public static function contains(s:String, value:String):Bool {
		#if (js && js_es >= 6)
		return (cast s).includes(value);
		#else 
		return s.indexOf(value) != -1;
		#end
	}

	/**
		Tells if the string `s` starts with the string `start`.

		If `start` is `null`, the result is unspecified.

		If `start` is the empty String `""`, the result is true.
	**/
	public static #if (cs || java || python || (js && js_es >= 6)) #end function startsWith(s:String, start:String):Bool {
		#if java
		return (cast s : java.NativeString).startsWith(start);
		#elseif cs
		return untyped s.StartsWith(start);
		#elseif hl
		return @:privateAccess (s.length >= start.length && s.bytes.compare(0, start.bytes, 0, start.length << 1) == 0);
		#elseif python
		return python.NativeStringTools.startswith(s, start);
		#elseif (js && js_es >= 6)
		return (cast s).startsWith(start);
		#else
		return (s.length >= start.length && s.lastIndexOf(start, 0) == 0);
		#end
	}

	/**
		Tells if the string `s` ends with the string `end`.

		If `end` is `null`, the result is unspecified.

		If `end` is the empty String `""`, the result is true.
	**/
	public static #if (cs || java || python || (js && js_es >= 6)) #end function endsWith(s:String, end:String):Bool {
		#if java
		return (cast s : java.NativeString).endsWith(end);
		#elseif cs
		return untyped s.EndsWith(end);
		#elseif hl
		var elen = end.length;
		var slen = s.length;
		return @:privateAccess (slen >= elen && s.bytes.compare((slen - elen) << 1, end.bytes, 0, elen << 1) == 0);
		#elseif python
		return python.NativeStringTools.endswith(s, end);
		#elseif (js && js_es >= 6)
		return (cast s).endsWith(end);
		#else
		var elen = end.length;
		var slen = s.length;
		return (slen >= elen && s.indexOf(end, (slen - elen)) == (slen - elen));
		#end
	}

	/**
		Tells if the character in the string `s` at position `pos` is a space.

		A character is considered to be a space character if its character code
		is 9,10,11,12,13 or 32.

		If `s` is the empty String `""`, or if pos is not a valid position within
		`s`, the result is false.
	**/
	public static function isSpace(s:String, pos:Int):Bool {
		#if (python || lua)
		if (s.length == 0 || pos < 0 || pos >= s.length)
			return false;
		#end
		var c = s.charCodeAt(pos);
		return (c > 8 && c < 14) || c == 32;
	}

	/**
		Removes leading space characters of `s`.

		This function internally calls `isSpace()` to decide which characters to
		remove.

		If `s` is the empty String `""` or consists only of space characters, the
		result is the empty String `""`.
	**/
	public #if cs #end static function ltrim(s:String):String {
		#if cs
		return untyped s.TrimStart();
		#else
		var l = s.length;
		var r = 0;
		while (r < l && isSpace(s, r)) {
			r++;
		}
		if (r > 0)
			return s.substr(r, l - r);
		else
			return s;
		#end
	}

	/**
		Removes trailing space characters of `s`.

		This function internally calls `isSpace()` to decide which characters to
		remove.

		If `s` is the empty String `""` or consists only of space characters, the
		result is the empty String `""`.
	**/
	public #if cs #end static function rtrim(s:String):String {
		#if cs
		return untyped s.TrimEnd();
		#else
		var l = s.length;
		var r = 0;
		while (r < l && isSpace(s, l - r - 1)) {
			r++;
		}
		if (r > 0) {
			return s.substr(0, l - r);
		} else {
			return s;
		}
		#end
	}

	/**
		Removes leading and trailing space characters of `s`.

		This is a convenience function for `ltrim(rtrim(s))`.
	**/
	public #if (cs || java) #end static function trim(s:String):String {
		#if cs
		return untyped s.Trim();
		#elseif java
		return (cast s : java.NativeString).trim();
		#else
		return ltrim(rtrim(s));
		#end
	}

	/**
		Concatenates `c` to `s` until `s.length` is at least `l`.

		If `c` is the empty String `""` or if `l` does not exceed `s.length`,
		`s` is returned unchanged.

		If `c.length` is 1, the resulting String length is exactly `l`.

		Otherwise the length may exceed `l`.

		If `c` is null, the result is unspecified.
	**/
	public static function lpad(s:String, c:String, l:Int):String {
		if (c.length <= 0)
			return s;

		var buf = new StringBuf();
		l -= s.length;
		while (buf.length < l) {
			buf.add(c);
		}
		buf.add(s);
		return buf.toString();
	}

	/**
		Appends `c` to `s` until `s.length` is at least `l`.

		If `c` is the empty String `""` or if `l` does not exceed `s.length`,
		`s` is returned unchanged.

		If `c.length` is 1, the resulting String length is exactly `l`.

		Otherwise the length may exceed `l`.

		If `c` is null, the result is unspecified.
	**/
	public static function rpad(s:String, c:String, l:Int):String {
		if (c.length <= 0)
			return s;

		var buf = new StringBuf();
		buf.add(s);
		while (buf.length < l) {
			buf.add(c);
		}
		return buf.toString();
	}

	/**
		Replace all occurrences of the String `sub` in the String `s` by the
		String `by`.

		If `sub` is the empty String `""`, `by` is inserted after each character
		of `s` except the last one. If `by` is also the empty String `""`, `s`
		remains unchanged.

		If `sub` or `by` are null, the result is unspecified.
	**/
	public static function replace(s:String, sub:String, by:String):String {
		#if java
		if (sub.length == 0)
			return s.split(sub).join(by);
		else
			return (cast s : java.NativeString).replace(sub, by);
		#elseif cs
		if (sub.length == 0)
			return s.split(sub).join(by);
		else
			return untyped s.Replace(sub, by);
		#else
		return s.split(sub).join(by);
		#end
	}

	/**
		Encodes `n` into a hexadecimal representation.

		If `digits` is specified, the resulting String is padded with "0" until
		its `length` equals `digits`.
	**/
	public static function hex(n:Int, ?digits:Int) {
		#if flash
		var n:UInt = n;
		var s:String = untyped n.toString(16);
		s = s.toUpperCase();
		#else
		var s = "";
		var hexChars = "0123456789ABCDEF";
		do {
			s = hexChars.charAt(n & 15) + s;
			n >>>= 4;
		} while (n > 0);
		#end
		#if python
		if (digits != null && s.length < digits) {
			var diff = digits - s.length;
			for (_ in 0...diff) {
				s = "0" + s;
			}
		}
		#else
		if (digits != null)
			while (s.length < digits)
				s = "0" + s;
		#end
		return s;
	}

	/**
		Returns the character code at position `index` of String `s`, or an
		end-of-file indicator at if `position` equals `s.length`.

		This method is faster than `String.charCodeAt()` on some platforms, but
		the result is unspecified if `index` is negative or greater than
		`s.length`.

		End of file status can be checked by calling `StringTools.isEof()` with
		the returned value as argument.

		This operation is not guaranteed to work if `s` contains the `\0`
		character.
	**/
	public static   function fastCodeAt(s:String, index:Int):Int {
		#if neko
		return untyped __dollar__sget(s.__s, index);
		#elseif cpp
		return untyped s.cca(index);
		#elseif flash
		return untyped s.cca(index);
		#elseif java
		return (index < s.length) ? cast(_charAt(s, index), Int) : -1;
		#elseif cs
		return (cast(index, UInt) < s.length) ? cast(s[index], Int) : -1;
		#elseif js
		return (cast s).charCodeAt(index);
		#elseif python
		return if (index >= s.length) -1 else python.internal.UBuiltins.ord(python.Syntax.arrayAccess(s, index));
		#elseif hl
		return @:privateAccess s.bytes.getUI16(index << 1);
		#elseif lua
		#if lua_vanilla
		return lua.NativeStringTools.byte(s, index + 1);
		#else
		return lua.lib.luautf8.Utf8.byte(s, index + 1);
		#end
		#else
		return untyped s.cca(index);
		#end
	}

	/**
		Returns the character code at position `index` of String `s`, or an
		end-of-file indicator at if `position` equals `s.length`.

		This method is faster than `String.charCodeAt()` on some platforms, but
		the result is unspecified if `index` is negative or greater than
		`s.length`.

		This operation is not guaranteed to work if `s` contains the `\0`
		character.
	**/
	public static function unsafeCodeAt(s:String, index:Int):Int {
		#if neko
		return untyped __dollar__sget(s.__s, index);
		#elseif cpp
		return untyped s.cca(index);
		#elseif flash
		return untyped s.cca(index);
		#elseif java
		return cast(_charAt(s, index), Int);
		#elseif cs
		return cast(s[index], Int);
		#elseif js
		return (cast s).charCodeAt(index);
		#elseif python
		return python.internal.UBuiltins.ord(python.Syntax.arrayAccess(s, index));
		#elseif hl
		return @:privateAccess s.bytes.getUI16(index << 1);
		#elseif lua
		#if lua_vanilla
		return lua.NativeStringTools.byte(s, index + 1);
		#else
		return lua.lib.luautf8.Utf8.byte(s, index + 1);
		#end
		#else
		return untyped s.cca(index);
		#end
	}

	/**
		Returns an iterator of the char codes.

		Note that char codes may differ across platforms because of different
		internal encoding of strings in different runtimes.
		For the consistent cross-platform UTF8 char codes see `haxe.iterators.StringIteratorUnicode`.
	**/
	public static function iterator(s:String):StringIterator {
		return new StringIterator(s);
	}

	/**
		Returns an iterator of the char indexes and codes.

		Note that char codes may differ across platforms because of different
		internal encoding of strings in different of runtimes.
		For the consistent cross-platform UTF8 char codes see `haxe.iterators.StringKeyValueIteratorUnicode`.
	**/
	public static function keyValueIterator(s:String):StringKeyValueIterator {
		return new StringKeyValueIterator(s);
	}

	/**
		Tells if `c` represents the end-of-file (EOF) character.
	**/
	@:noUsing public static function isEof(c:Int):Bool {
		#if (flash || cpp || hl)
		return c == 0;
		#elseif js
		return c != c; // fast NaN
		#elseif (neko || lua || eval)
		return c == null;
		#elseif (cs || java || python)
		return c == -1;
		#else
		return false;
		#end
	}

	/**
		Returns a String that can be used as a single command line argument
		on Unix.
		The input will be quoted, or escaped if necessary.
	**/
	@:noCompletion
	@:deprecated('StringTools.quoteUnixArg() is deprecated. Use haxe.SysTools.quoteUnixArg() instead.')
	public static function quoteUnixArg(argument:String):String {
		return haxe.SysTools.quoteUnixArg(argument);
	}

	/**
		Character codes of the characters that will be escaped by `quoteWinArg(_, true)`.
	**/
	@:noCompletion
	@:deprecated('StringTools.winMetaCharacters is deprecated. Use haxe.SysTools.winMetaCharacters instead.')
	public static var winMetaCharacters:Array<Int> = cast haxe.SysTools.winMetaCharacters;

	/**
		Returns a String that can be used as a single command line argument
		on Windows.
		The input will be quoted, or escaped if necessary, such that the output
		will be parsed as a single argument using the rule specified in
		http://msdn.microsoft.com/en-us/library/ms880421

		Examples:
		```haxe
		quoteWinArg("abc") == "abc";
		quoteWinArg("ab c") == '"ab c"';
		```
	**/
	@:noCompletion
	@:deprecated('StringTools.quoteWinArg() is deprecated. Use haxe.SysTools.quoteWinArg() instead.')
	public static function quoteWinArg(argument:String, escapeMetaCharacters:Bool):String {
		return haxe.SysTools.quoteWinArg(argument, escapeMetaCharacters);
	}

	#if java
	private static function _charAt(str:String, idx:Int):java.StdTypes.Char16
		return (cast str : java.NativeString).charAt(idx);
	#end

	#if neko
	private static var _urlEncode = neko.Lib.load("std", "url_encode", 1);
	private static var _urlDecode = neko.Lib.load("std", "url_decode", 1);
	#end

	#if utf16
	static var MIN_SURROGATE_CODE_POINT = 65536;

	static function utf16CodePointAt(s:String, index:Int):Int {
		var c = StringTools.fastCodeAt(s, index);
		if (c >= 0xD800 && c <= 0xDBFF) {
			c = ((c - 0xD7C0) << 10) | (StringTools.fastCodeAt(s, index + 1) & 0x3FF);
		}
		return c;
	}
	#end
}


/**
 * A class containing a set of functions for random generation.
 */
class SERandom
{
	/**
	 * The global base random number generator seed (for deterministic behavior in recordings and saves).
	 * If you want, you can set the seed with an integer between 1 and 2,147,483,647 inclusive.
	 * Altering this yourself may break recording functionality!
	 */
	public var initialSeed(default, set):Int = 1;

	/**
	 * Current seed used to generate new random numbers. You can retrieve this value if,
	 * for example, you want to store the seed that was used to randomly generate a level.
	 */
	public var currentSeed(get, set):Int;

	/**
	 * Create a new FlxRandom object.
	 *
	 * @param	InitialSeed  The first seed of this FlxRandom object. If ignored, a random seed will be generated.
	 */
	public function new(?InitialSeed:Int)
	{
		if (InitialSeed != null)
		{
			initialSeed = InitialSeed;
		}
		else
		{
			resetInitialSeed();
		}
	}

	/**
	 * Function to easily set the global seed to a new random number.
	 * Please note that this function is not deterministic!
	 * If you call it in your game, recording may not function as expected.
	 *
	 * @return  The new initial seed.
	 */
	public function resetInitialSeed():Int
	{
		return initialSeed = rangeBound(Std.int(Math.random() * FlxMath.MAX_VALUE_INT));
	}

	/**
	 * Returns a pseudorandom integer between Min and Max, inclusive.
	 * Will not return a number in the Excludes array, if provided.
	 * Please note that large Excludes arrays can slow calculations.
	 *
	 * @param   Min        The minimum value that should be returned. 0 by default.
	 * @param   Max        The maximum value that should be returned. 2,147,483,647 by default.
	 * @param   Excludes   Optional array of values that should not be returned.
	 */
	public function int(Min:Int = 0, Max:Int = FlxMath.MAX_VALUE_INT, ?Excludes:Array<Int>):Int
	{
		if (Min == 0 && Max == FlxMath.MAX_VALUE_INT && Excludes == null)
		{
			return Std.int(generate());
		}
		else if (Min == Max)
		{
			return Min;
		}
		else
		{
			// Swap values if reversed
			if (Min > Max)
			{
				Min = Min + Max;
				Max = Min - Max;
				Min = Min - Max;
			}

			if (Excludes == null)
			{
				return Math.floor(Min + generate() / MODULUS * (Max - Min + 1));
			}
			else
			{
				var result:Int = 0;

				do
				{
					result = Math.floor(Min + generate() / MODULUS * (Max - Min + 1));
				}
				while (Excludes.indexOf(result) >= 0);

				return result;
			}
		}
	}

	/**
	 * Returns a pseudorandom float value between Min (inclusive) and Max (exclusive).
	 * Will not return a number in the Excludes array, if provided.
	 * Please note that large Excludes arrays can slow calculations.
	 *
	 * @param   Min        The minimum value that should be returned. 0 by default.
	 * @param   Max        The maximum value that should be returned. 1 by default.
	 * @param   Excludes   Optional array of values that should not be returned.
	 */
	public function float(Min:Float = 0, Max:Float = 1, ?Excludes:Array<Float>):Float
	{
		var result:Float = 0;

		if (Min == 0 && Max == 1 && Excludes == null)
		{
			return generate() / MODULUS;
		}
		else if (Min == Max)
		{
			result = Min;
		}
		else
		{
			// Swap values if reversed.
			if (Min > Max)
			{
				Min = Min + Max;
				Max = Min - Max;
				Min = Min - Max;
			}

			if (Excludes == null)
			{
				result = Min + (generate() / MODULUS) * (Max - Min);
			}
			else
			{
				do
				{
					result = Min + (generate() / MODULUS) * (Max - Min);
				}
				while (Excludes.indexOf(result) >= 0);
			}
		}

		return result;
	}

	// helper variables for floatNormal -- it produces TWO random values with each call so we have to store some state outside the function
	var _hasFloatNormalSpare:Bool = false;
	var _floatNormalRand1:Float = 0;
	var _floatNormalRand2:Float = 0;
	var _twoPI:Float = Math.PI * 2;
	var _floatNormalRho:Float = 0;

	/**
	 * Returns a pseudorandom float value in a statistical normal distribution centered on Mean with a standard deviation size of StdDev.
	 * (This uses the Box-Muller transform algorithm for gaussian pseudorandom numbers)
	 *
	 * Normal distribution: 68% values are within 1 standard deviation, 95% are in 2 StdDevs, 99% in 3 StdDevs.
	 * See this image: https://github.com/HaxeFlixel/flixel-demos/blob/dev/Performance/FlxRandom/normaldistribution.png
	 *
	 * @param	Mean		The Mean around which the normal distribution is centered
	 * @param	StdDev		Size of the standard deviation
	 */
	public function floatNormal(Mean:Float = 0, StdDev:Float = 1):Float
	{
		if (_hasFloatNormalSpare)
		{
			_hasFloatNormalSpare = false;
			var scale:Float = StdDev * _floatNormalRho;
			return Mean + scale * _floatNormalRand2;
		}

		_hasFloatNormalSpare = true;

		var theta:Float = _twoPI * (generate() / MODULUS);
		_floatNormalRho = Math.sqrt(-2 * Math.log(1 - (generate() / MODULUS)));
		var scale:Float = StdDev * _floatNormalRho;

		_floatNormalRand1 = Math.cos(theta);
		_floatNormalRand2 = Math.sin(theta);

		return Mean + scale * _floatNormalRand1;
	}

	/**
	 * Returns true or false based on the chance value (default 50%).
	 * For example if you wanted a player to have a 30.5% chance of getting a bonus,
	 * call bool(30.5) - true means the chance passed, false means it failed.
	 *
	 * @param   Chance   The chance of receiving the value.
	 *                   Should be given as a number between 0 and 100 (effectively 0% to 100%)
	 * @return  Whether the roll passed or not.
	 */
	public function bool(Chance:Float = 50):Bool
	{
		return float(0, 100) < Chance;
	}

	/**
	 * Returns either a 1 or -1.
	 *
	 * @param   Chance   The chance of receiving a positive value.
	 *                   Should be given as a number between 0 and 100 (effectively 0% to 100%)
	 * @return  1 or -1
	 */
	public function sign(Chance:Float = 50):Int
	{
		return bool(Chance) ? 1 : -1;
	}

	/**
	 * Pseudorandomly select from an array of weighted options. For example, if you passed in an array of [50, 30, 20]
	 * there would be a 50% chance of returning a 0, a 30% chance of returning a 1, and a 20% chance of returning a 2.
	 * Note that the values in the array do not have to add to 100 or any other number.
	 * The percent chance will be equal to a given value in the array divided by the total of all values in the array.
	 *
	 * @param   WeightsArray   An array of weights.
	 * @return  A value between 0 and (SelectionArray.length - 1), with a probability equivalent to the values in SelectionArray.
	 */
	public function weightedPick(WeightsArray:Array<Float>):Int
	{
		var totalWeight:Float = 0;
		var pick:Int = 0;

		for (i in WeightsArray)
		{
			totalWeight += i;
		}

		totalWeight = float(0, totalWeight);

		for (i in 0...WeightsArray.length)
		{
			if (totalWeight < WeightsArray[i])
			{
				pick = i;
				break;
			}

			totalWeight -= WeightsArray[i];
		}

		return pick;
	}

	/**
	 * Returns a random object from an array.
	 *
	 * @param   Objects        An array from which to return an object.
	 * @param   WeightsArray   Optional array of weights which will determine the likelihood of returning a given value from Objects.
	 * 						   If none is passed, all objects in the Objects array will have an equal likelihood of being returned.
	 *                         Values in WeightsArray will correspond to objects in Objects exactly.
	 * @param   StartIndex     Optional index from which to restrict selection. Default value is 0, or the beginning of the Objects array.
	 * @param   EndIndex       Optional index at which to restrict selection. Ignored if 0, which is the default value.
	 * @return  A pseudorandomly chosen object from Objects.
	 */
	@:generic
	public function getObject<T>(Objects:Array<T>, ?WeightsArray:Array<Float>, StartIndex:Int = 0, ?EndIndex:Null<Int>):T
	{
		var selected:Null<T> = null;

		if (Objects.length != 0)
		{
			if (WeightsArray == null)
			{
				WeightsArray = [for (i in 0...Objects.length) 1];
			}

			if (EndIndex == null)
			{
				EndIndex = Objects.length - 1;
			}

			StartIndex = Std.int(FlxMath.bound(StartIndex, 0, Objects.length - 1));
			EndIndex = Std.int(FlxMath.bound(EndIndex, 0, Objects.length - 1));

			// Swap values if reversed
			if (EndIndex < StartIndex)
			{
				StartIndex = StartIndex + EndIndex;
				EndIndex = StartIndex - EndIndex;
				StartIndex = StartIndex - EndIndex;
			}

			if (EndIndex > WeightsArray.length - 1)
			{
				EndIndex = WeightsArray.length - 1;
			}

			_arrayFloatHelper = [for (i in StartIndex...EndIndex + 1) WeightsArray[i]];
			selected = Objects[StartIndex + weightedPick(_arrayFloatHelper)];
		}

		return selected;
	}

	/**
	 * Shuffles the entries in an array into a new pseudorandom order.
	 *
	 * @param   Objects        An array to shuffle.
	 * @param   HowManyTimes   How many swaps to perform during the shuffle operation.
	 *                         A good rule of thumb is 2-4 times the number of objects in the list.
	 * @return  The newly shuffled array.
	 */
	@:generic
	@:deprecated("Unless you rely on reproducing the exact output of shuffleArray(), you should use shuffle() instead, which is both faster and higher quality.")
	public function shuffleArray<T>(Objects:Array<T>, HowManyTimes:Int):Array<T>
	{
		HowManyTimes = Std.int(Math.max(HowManyTimes, 0));

		var tempObject:Null<T> = null;

		for (i in 0...HowManyTimes)
		{
			var pick1:Int = int(0, Objects.length - 1);
			var pick2:Int = int(0, Objects.length - 1);

			tempObject = Objects[pick1];
			Objects[pick1] = Objects[pick2];
			Objects[pick2] = tempObject;
		}

		return Objects;
	}

	/**
	 * Shuffles the entries in an array in-place into a new pseudorandom order,
	 * using the standard Fisher-Yates shuffle algorithm.
	 *
	 * @param  array  The array to shuffle.
	 * @since  4.2.0
	 */
	@:generic
	public function shuffle<T>(array:Array<T>):Void
	{
		var maxValidIndex = array.length - 1;
		for (i in 0...maxValidIndex)
		{
			var j = int(i, maxValidIndex);
			var tmp = array[i];
			array[i] = array[j];
			array[j] = tmp;
		}
	}

	/**
	 * Returns a random color.
	 *
	 * @param   Min        An optional FlxColor representing the lower bounds for the generated color.
	 * @param   Max        An optional FlxColor representing the upper bounds for the generated color.
	 * @param 	Alpha      An optional value for the alpha channel of the generated color.
	 * @param   GreyScale  Whether or not to create a color that is strictly a shade of grey. False by default.
	 * @return  A color value as a FlxColor.
	 */
	public function color(?Min:FlxColor, ?Max:FlxColor, ?Alpha:Int, GreyScale:Bool = false):FlxColor
	{
		var red:Int;
		var green:Int;
		var blue:Int;
		var alpha:Int;

		if (Min == null && Max == null){
			red = int(0, 255);
			green = int(0, 255);
			blue = int(0, 255);
			alpha = Alpha ?? int(0, 255);
		}else if (Max == null){
			red = int(Min.red, 255);
			green = GreyScale ? red : int(Min.green, 255);
			blue = GreyScale ? red : int(Min.blue, 255);
			alpha = Alpha ?? int(Min.alpha, 255);
		}else if (Min == null){
			red = int(0, Max.red);
			green = GreyScale ? red : int(0, Max.green);
			blue = GreyScale ? red : int(0, Max.blue);
			alpha = Alpha ?? int(0, Max.alpha);
		}else{
			red = int(Min.red, Max.red);
			green = GreyScale ? red : int(Min.green, Max.green);
			blue = GreyScale ? red : int(Min.blue, Max.blue);
			alpha = Alpha ?? int(Min.alpha, Max.alpha);
		}

		return FlxColor.fromRGB(red, green, blue, alpha);
	}

	/**
	 * Internal method to quickly generate a pseudorandom number. Used only by other functions of this class.
	 * Also updates the internal seed, which will then be used to generate the next pseudorandom number.
	 *
	 * @return  A new pseudorandom number.
	 */
	function generate():Float
	{
		return internalSeed = (internalSeed * MULTIPLIER) % MODULUS;
	}

	/**
	 * The actual internal seed. Stored as a Float value to prevent inaccuracies due to
	 * integer overflow in the generate() equation.
	 */
	var internalSeed:Float = 1;

	/**
	 * Internal function to update the current seed whenever the initial seed is reset,
	 * and keep the initial seed's value in range.
	 */
	function set_initialSeed(NewSeed:Int):Int
	{
		return initialSeed = currentSeed = rangeBound(NewSeed);
	}

	/**
	 * Returns the internal seed as an integer.
	 */
	function get_currentSeed():Int
	{
		return Std.int(internalSeed);
	}

	/**
	 * Sets the internal seed to an integer value.
	 */
	function set_currentSeed(NewSeed:Int):Int
	{
		return Std.int(internalSeed = rangeBound(NewSeed));
	}

	/**
	 * Internal shared function to ensure an arbitrary value is in the valid range of seed values.
	 */
	static function rangeBound(Value:Int):Int
	{
		return Std.int(FlxMath.bound(Value, 1, MODULUS - 1));
	}

	/**
	 * Internal shared helper variable. Used by getObject().
	 */
	static var _arrayFloatHelper:Array<Float> = null;

	/**
	 * Constants used in the pseudorandom number generation equation.
	 * These are the constants suggested by the revised MINSTD pseudorandom number generator,
	 * and they use the full range of possible integer values.
	 *
	 * @see http://en.wikipedia.org/wiki/Linear_congruential_generator
	 * @see Stephen K. Park and Keith W. Miller and Paul K. Stockmeyer (1988).
	 *      "Technical Correspondence". Communications of the ACM 36 (7): 105–110.
	 */
	static var MULTIPLIER:Float = 48271.0;

	static var MODULUS:Int = FlxMath.MAX_VALUE_INT;

	#if FLX_RECORD
	/**
	 * Internal storage for the seed used to generate the most recent state.
	 */
	static var _stateSeed:Int = 1;

	/**
	 * The seed to be used by the recording requested in FlxGame.
	 */
	static var _recordingSeed:Int = 1;

	/**
	 * Update the seed that was used to create the most recent state.
	 * Called by FlxGame, needed for replays.
	 *
	 * @return  The new value of the state seed.
	 */
	@:allow(flixel.FlxGame)
	static function updateStateSeed():Int
	{
		return _stateSeed = FlxG.random.currentSeed;
	}

	/**
	 * Used to store the seed for a requested recording. If StandardMode is false, this will also reset the global seed!
	 * This ensures that the state is created in the same way as just before the recording was requested.
	 *
	 * @param   StandardMode   If true, entire game will be reset, else just the current state will be reset.
	 */
	@:allow(flixel.system.frontEnds.VCRFrontEnd)
	static function updateRecordingSeed(StandardMode:Bool = true):Int
	{
		return _recordingSeed = FlxG.random.initialSeed = StandardMode ? FlxG.random.initialSeed : _stateSeed;
	}

	/**
	 * Returns the seed to use for the requested recording.
	 */
	@:allow(flixel.FlxGame.handleReplayRequests)
	static inline function getRecordingSeed():Int
	{
		return _recordingSeed;
	}
	#end
}
