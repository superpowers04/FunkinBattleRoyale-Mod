package;
import flixel.system.FlxAssets.FlxSoundAsset;
#if (flixel > "5.3")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.animation.FlxAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxG;
import openfl.media.Sound;
import sys.io.File;
import flash.display.BitmapData;
import Xml;
import sys.FileSystem;
import SELoader;
#if FLXRUNTIMESHADER
import flixel.addons.display.FlxRuntimeShader;
#end
import flixel.system.FlxAssets;

import flxanimate.FlxAnimate;

// Made specifically for Super Engine


using StringTools;


// A class that handles IO for scripts. Allowing easy loading of sprites, sounds and text without having to keep track of where the script actually is 

class HSBrTools {
	public var path:String;
	public var cache:InternalCache;
	// public var dumpGraphics:Bool = false; // If true, All FlxGraphics will be dumped upon creation, trades off bitmap editability for less memory usage
 
	public var cachedSounds:Array<String> = [];
	

	public var optionsMap:Map<String,Dynamic> = new Map<String,Dynamic>();
	public static var shared:Map<String,Dynamic> = new Map<String,Dynamic>();
	public var global(get,never):Map<String,Dynamic>;
	var id = "Unspecified script";
	var hasSettings:Bool = false;
	public function new(_path:String,?id:String = ""){
		path = SELoader.getPath(_path);
		if (!path.endsWith('/')) path = path + "/";
		cache = new InternalCache('SCRIPT-'+_path);
		if(id != "" && SELoader.exists('mods/scriptOptions/$id.json')){
			hasSettings = true;
			var scriptJson:Map<String,Dynamic> = OptionsMenu.loadScriptOptions('mods/scriptOptions/$id.json');
			if(scriptJson != null) optionsMap = scriptJson;
			this.id = id;
		}
	}

	public function getSetting(setting:String,?defValue:Dynamic = false):Dynamic{
		return optionsMap[setting] ?? defValue;
	}
	function get_global(){
		return shared;
	}

	inline function handleError(e:String){
		// PlayState.instance.handleError(e + '\nExtra info:\n\nPath:${path}\nHasOptions:${hasSettings}');
		throw(e + '\nExtra info:\n\nPath:${path}\nHasOptions:${hasSettings}');
	}


	@:keep inline public function getPath(?str:String = ""){
		return SELoader.getPath(path + str);
	}
	public function loadFlxSprite(x:Float,y:Float,pngPath:String):FlxSprite{
		// if(!SELoader.exists('${path}${pngPath}')){
		// 	handleError('${id}: Image "${path}${pngPath}" doesn\'t exist!');
		// 	return new FlxSprite(x, y); // Prevents the script from throwing a null error or something
		// }
		if(!pngPath.endsWith('.png')) pngPath+=".png";
		return cache.loadFlxSprite(x,y,'${path}${pngPath}');
	}
	@:keep inline public function loadGraphic(pngPath:String):FlxGraphic{
		// if(!SELoader.exists('${path}${pngPath}')){
		// 	handleError('${id}: "${path}${pngPath}" doesn\'t exist!');
		// 	return FlxGraphic.fromRectangle(0,0,0); // Prevents the script from throwing a null error or something
		// }
		if(!pngPath.endsWith('.png')) pngPath+=".png";
		return cache.loadGraphic('${path}${pngPath}');
	}

	public function loadSparrowFrames(pngPath:String):FlxAtlasFrames{
		if(!exists('${pngPath}.png')){
			handleError('${id}: SparrowFrame PNG "${path}${pngPath}.png" doesn\'t exist!');
			return new FlxAtlasFrames(FlxGraphic.fromRectangle(0,0,0)); // Prevents the script from throwing a null error or something
		}
		if(!exists('${pngPath}.xml')){
			handleError('${id}: SparrowFrame XML "${path}${pngPath}.xml" doesn\'t exist!');
			return new FlxAtlasFrames(FlxGraphic.fromRectangle(0,0,0)); // Prevents the script from throwing a null error or something
		}

		return FlxAtlasFrames.fromSparrow(loadGraphic(pngPath + ".png"),loadXML(pngPath + ".xml"));
	}
	public function loadStitchedSparrowFrames(pngPath:String,?cache:Bool=false):FlxAtlasFrames{
		if(!exists('${pngPath}.png')){
			handleError(' SparrowFrame PNG "${pngPath}.png" doesn\'t exist!');
			return new FlxAtlasFrames(FlxGraphic.fromRectangle(0,0,0)); // Prevents the script from throwing a null error or something
		}
		if(!exists('${pngPath}.xml')){
			handleError(' SparrowFrame XML "${pngPath}.xml" doesn\'t exist!');
			return new FlxAtlasFrames(FlxGraphic.fromRectangle(0,0,0)); // Prevents the script from throwing a null error or something
		}
		var atlas = FlxAtlasFrames.fromSparrow(loadGraphic('$pngPath.png'),loadXML('${pngPath}'));
		var i = 1;
		while(exists('${pngPath}-$i.png') && exists('${pngPath}-$i.xml')){
			var pngPath ='${pngPath}-$i';
			i++;
			var nextAtlas = FlxAtlasFrames.fromSparrow(loadGraphic('$pngPath.png'),loadXML('${pngPath}'));
			@:privateAccess{
				if(!atlas.usedGraphics.contains(atlas.parent)){
					atlas.usedGraphics.push(atlas.parent);
				}
			}
			atlas.addAtlas(nextAtlas);
		}
		return atlas;
	}
	public function loadAtlasSprite(x:Int,y:Int,pngPath:String,?anim:String = "",?loop:Bool = false,?fps:Int = 24):FlxSprite{
		var spr = new FlxSprite(x, y);
		spr.frames= loadSparrowFrames(pngPath);
		if (anim != ""){
			spr.animation.addByPrefix(anim,anim,fps,loop);
			spr.animation.play(anim);
		}
		return spr;
	}
	@:keep inline public function loadSparrowSprite(x:Int,y:Int,pngPath:String,?anim:String = "",?loop:Bool = false,?fps:Int = 24):FlxSprite{
		return loadAtlasSprite(x,y,pngPath,anim,loop,fps);
	}
	@:keep inline public function reset(){
		cache.clear();
		// spriteArray = [];
		// bitmapArray = [];
		// xmlArray = [];
		// textArray = [];
		// soundArray = [];
	}

	@:keep inline public function exists(textPath:String):Bool{
		return SELoader.exists('${path}${textPath}');
	}
	@:keep inline public function loadText(textPath:String):String{
		if(!exists(textPath)) handleError(' Text "${textPath}" doesn\'t exist!');
		return cache.loadText('${path}${textPath}');
	}
	@:keep inline public function loadXML(textPath:String):String{
		if(!exists(textPath)) handleError(' xml "${textPath}" doesn\'t exist!');
		return cache.loadXML('${path}${textPath}');
	}
	public function loadShader(textPath:String,?glslVersion:Dynamic = 120)#if(FLXRUNTIMESHADER) :Null<FlxRuntimeShader> #end{
		// #if !FLXRUNTIMESHADER

			handleError('Shaders aren\'t supported enabled on this build of the game!');
			return null;
		// #else
		// 	if(textArray[textPath + ".vert"] == null && SELoader.exists('${path}${textPath}.vert')) textArray[textPath + ".vert"] = SELoader.loadText('${path}${textPath}.vert');
		// 	if(textArray[textPath + ".frag"] == null && SELoader.exists('${path}${textPath}.frag')) textArray[textPath + ".frag"] = SELoader.loadText('${path}${textPath}.frag');
		// 	try{
		// 		var shader = new FlxRuntimeShader(textArray[textPath + ".vert"],textArray[textPath + ".frag"],Std.string(glslVersion));
		// 		// if(init) shader.initialise(); // If the shader uses custom variables, this can prevent loading a broken shader
		// 		return shader;

		// 	}catch(e){
		// 		handleError('${id}: Unable to load shader "${textPath}": ${e.message}');
		// 		trace(e.message);
		// 	}
		// 	return null;
		// #end
	}
	// public function saveText(textPath:String,text:String):Bool{
	// 	File.saveContent('${path}${textPath}',text);
	// 	return true;
	// }




	public function loadSound(soundPath:String):FlxSound{
		// if(!exists(soundPath)) handleError(' Sound "${soundPath}" doesn\'t exist!');

		return cache.loadFlxSound(getPath(soundPath));
	}
	public function loadFlxSound(soundPath:String):FlxSound return loadSound(soundPath);
	public function playSound(soundPath:String,?volume:Dynamic = 2):FlxSound {
		if(!exists(soundPath)) handleError(' Sound "${soundPath}" doesn\'t exist!');
		return cache.playSound(getPath(soundPath),volume);
	}

	public function unloadSound(soundPath:String){
		cache.unloadSound('${path}$soundPath');
	}
	public function unloadShader(pngPath:String){
		// textArray[pngPath + ".vert"] = null;
		// textArray[pngPath + ".frag"] = null;
	}
	public function unloadText(pngPath:String){
		cache.unloadText('${path}$pngPath');
	}
	public function unloadXml(pngPath:String){
		cache.unloadText('${path}$pngPath');
	}
	public function unloadSprite(pngPath:String){
		cache.unloadText('${path}$pngPath');
	}

	public function cacheSound(soundPath:String){
		cache.cacheSound('${path}${soundPath}');
	}
	public function cacheGraphic(pngPath:String,?dumpGraphic:Bool = false){ // DOES NOT CHECK IF FILE IS VALID!
		
		// if(bitmapArray[pngPath] == null) bitmapArray[pngPath] = SELoader.loadBitmap('${path}${pngPath}');
		
		// if(spriteArray[pngPath] == null) spriteArray[pngPath] = FlxGraphic.fromBitmapData(bitmapArray[pngPath]);
		// if(cache.cacheGraphic(pngPath) == null) return handleError('${id} : cacheGraphic: Unable to load $pngPath into a FlxGraphic!');
		// spriteArray[pngPath].destroyOnNoUse = false;
		cache.cacheGraphic('${path}$pngPath');
		// if(dumpGraphic || dumpGraphics) spriteArray[pngPath].dump();

	}
	public function cacheSprite(pngPath:String,?dump:Bool = false){
		cache.cacheSprite('${path}$pngPath');
		// if(spriteArray[pngPath] == null) {
		// 	if(!SELoader.exists('${path}${pngPath}.png')){
		// 		handleError('${id} : CacheSprite: "${path}${pngPath}.png" doesn\'t exist!');
		// 		return;
		// 	}
		// 	cacheGraphic('${pngPath}.png',dump);
		// }
	}
}
