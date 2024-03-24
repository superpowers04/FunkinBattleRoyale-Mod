package;

// Class used for loading sprites and caching them, hopefully will be more efficient than Flixels built-in caching
// This will work reguardless of if they're in assets/ or not


import sys.io.File;
import sys.FileSystem;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import sys.io.File;
import sys.FileSystem;
import flash.display.BitmapData;
import Xml;
import openfl.media.Sound;
import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.util.typeLimit.OneOfTwo;
import lime.media.AudioBuffer;
import haxe.io.Bytes;
// import vlc.VLCSound;
using StringTools;

class SELoader {

	static public var cache:InternalCache = new InternalCache();
	
	public static var PATH(default,set):String = '';
	public static function set_PATH(_path:String):String{
		if(!_path.endsWith('/')) _path = _path + "/"; // SELoader expects the main path to have a / at the end
		_path = _path.replace('\\',"/"); // Unix styled paths, Windows \\ paths are weird and fucky and i hate it
		
		return PATH = _path.replace('//','/'); // Fixes paths having //'s in them 
	}
	public static var rawMode = false;
	public static var id = "SELoader";

	inline public static function handleError(e:String){
		throw(e);
		// if((cast (FlxG.state)).handleError != null) (cast (FlxG.state)).handleError(e); else MainMenuState.handleError(e);
		
	}
	// Basically clenses paths and returns the base path with the requested one. Used heavily for the Android port
	@:keep inline public static function getPath(path:String,allowModded:Bool = true):String{
		// Remove library from path
		if(path.indexOf(":") > 3) path = path.substring(path.indexOf(":") + 1);
		// Absolute paths should just return themselves without anything changed
		if(
			#if windows
				path.substring(1,2) == ':' || 
			#end
				path.substring(0,1) == "/" || rawMode){
			rawMode = false;
			return path.replace('//','/');
		}
		if(allowModded && path.startsWith("assets/") && FileSystem.exists('${PATH}mods${path}')) path = 'mods/' + path; // Return modded assets before vanilla assets

		return (PATH + path).replace('//','/'); // Fixes paths having //'s in them
	}
	

	public static function loadText(textPath:String,?useCache:Bool = false):String{
		textPath = getPath(textPath);
		if(cache.textArray[textPath] != null || useCache){
			return cache.loadText(textPath);
		}
		if(!exists(textPath)){
			handleError('${id}: Text "${textPath}" doesn\'t exist!');
			return "";
		}
		return File.getContent(textPath);
	}
	public static function loadXML(textPath:String,?useCache:Bool = false):String{ // Automatically fixes UTF-16 encoded files
		var text = loadText(textPath,useCache).replace("UTF-16","utf-8");
		if(text.substr(2).replace(String.fromCharCode(0),'').contains('UTF-16')){ // Flash CS6 outputs a UTF-16 xml even though no UTF-16 characters are usually used. This reformats the file to be UTF-8 *hopefully*
			text = '<?' + text.substr(2).replace(String.fromCharCode(0),'').replace('UTF-16','utf-8');
		}
		return text;
	}


	public static function loadFlxSprite(x:Int = 0,y:Int = 0,pngPath:String,?useCache:Bool = false):FlxSprite{
		if(!SELoader.exists('${pngPath}')){
			handleError('${id}: Image "${pngPath}" doesn\'t exist!');
			return new FlxSprite(x, y); // Prevents the script from throwing a null error or something
		}
		return new FlxSprite(x, y).loadGraphic(loadGraphic(pngPath,useCache));
	}
	public static function loadGraphic(pngPath:String,?useCache:Bool = false):FlxGraphic{
		// if(cache.spriteArray[pngPath] != null || useCache){
		// 	return cache.loadGraphic(pngPath);
		// }
		return FlxGraphic.fromBitmapData(loadBitmap(pngPath));
	}
	public static function loadBitmap(pngPath:String,?useCache:Bool = false):BitmapData{
		pngPath = getPath(pngPath);
		if(pngPath.substr(-4) != ".png") pngPath += '.png';
		if(cache.bitmapArray[pngPath] != null || useCache){
			return cache.loadBitmap(pngPath);
		}
		if(!exists('${pngPath}')){
			handleError('${id}: "${pngPath}" doesn\'t exist!');
			return new BitmapData(0,0,false,0xFF000000); // Prevents the script from throwing a null error or something
		}
		return BitmapData.fromFile(pngPath);
	}

	public static function loadSparrowFrames(pngPath:String):FlxAtlasFrames{
		pngPath = getPath(pngPath);
		if(!exists('${pngPath}.png')){
			handleError('${id}: SparrowFrame PNG "${pngPath}.png" doesn\'t exist!');
			return new FlxAtlasFrames(FlxGraphic.fromRectangle(0,0,0)); // Prevents the script from throwing a null error or something
		}
		if(!exists('${pngPath}.xml')){
			handleError('${id}: SparrowFrame XML "${pngPath}.xml" doesn\'t exist!');
			return new FlxAtlasFrames(FlxGraphic.fromRectangle(0,0,0)); // Prevents the script from throwing a null error or something
		}
		return FlxAtlasFrames.fromSparrow(loadGraphic(pngPath),loadXML('${pngPath}.xml'));
	}
	public static function loadSparrowSprite(x:Int,y:Int,pngPath:String,?anim:String = "",?loop:Bool = false,?fps:Int = 24,?useCache:Bool = false):FlxSprite{
		pngPath = getPath(pngPath);
		var spr = new FlxSprite(x, y);
		var _f = spr.frames;
		try{
			spr.frames=loadSparrowFrames(pngPath);
		}catch(e){
			spr.frames = _f;
			return spr;
		}
		if (anim != ""){
			spr.animation.addByPrefix(anim,anim,fps,loop);
			spr.animation.play(anim);
		}
		return spr;
	}
	public static function reset(){
		cache.clear();
		cache = new InternalCache();
	}
	@:keep inline public static function getContent(textPath:String):String{return loadText(textPath,false);}
	@:keep inline public static function saveContent(textPath:String,content:String):String{return saveText(textPath,content,false);}
	@:keep inline public static function getBytes(textPath:String):Bytes{return loadBytes(textPath,false);}
	@:keep inline public static function gc(){
		FlxG.bitmap.clearUnused();
		openfl.system.System.gc();
	}

	public static function loadBytes(textPath:String,?useCache:Bool = false):Bytes{
		// No cache support atm

		// if(cache.textArray[textPath] != null || useCache){
		// 	return cache.loadText(textPath);
		// }
		textPath = getPath(textPath);
		if(!exists(textPath)){
			handleError('${id}: Text "${textPath}" doesn\'t exist!');
			return null;
		}
		return File.getBytes(getPath(textPath));
	}
	public static function saveBytes(textPath:String,contents:Bytes){ // If there's an error, it'll return the error, else it'll return null
		try{
			File.saveBytes(getPath(textPath),contents);
		}catch(e){ return e; }
		return null;
	}
	public static function saveText(textPath:String,contents:String = "",?useCache:Bool = false):Dynamic{ // If there's an error, it'll return the error, else it'll return null
		textPath = getPath(textPath);
		try{
			File.saveContent(textPath,contents);
		}catch(e){ return e; }
		if(cache.textArray[textPath] != null || useCache){
			cache.textArray[textPath] = contents;
		}
		return null;
	}
	public static function loadSound(soundPath:String,?useCache:Bool = false):Null<Sound>{
		soundPath = getPath(soundPath);
		if(cache.soundArray[soundPath] != null || useCache){
			return cache.loadSound(soundPath);
		}
		if(!exists(soundPath)){
			handleError('${id}: Sound "${getPath(soundPath)}" doesn\'t exist!');
			// return null;
		}
		return Sound.fromFile(getPath(soundPath));
	}
	@:keep inline public static function loadFlxSound(soundPath:String):FlxSound{
		return new FlxSound().loadEmbedded(loadSound(soundPath));
	}

	public static function playSound(soundPath:String,?volume:Float = -1):FlxSound{
		if(volume == -1) volume = SESave.data.otherVol;
		return FlxG.sound.play(loadSound(soundPath),volume);
	}


	// Clones of FileSystem and File functions. Eventually, zip support might be added. This'll also allow custom formats to be used

	public static function absolutePath(path:String):String{
		return FileSystem.absolutePath(getPath(path));
	}
	public static function fullPath(path:String):String{
		return FileSystem.fullPath(getPath(path));
	}
	public static function anyExists(paths:Array<String>):String{
		for(i in paths) if(exists(i)) return i;
		return null;
	}
	public static function exists(path:String):Bool{
		return FileSystem.exists(getPath(path));
	}
	public static function readDirectory(path:String):Array<String>{
		return FileSystem.readDirectory(getPath(path));
	}
	public static function readDirectories(paths:Array<String>):Array<String>{
		var ret = [];
		for(path in paths){
			var _path = getPath(path,false);
			if(exists(_path) && isDirectory(_path)){
				for(item in readDirectory(_path)){
					ret.push('$path/$item');
				}
			}
		}
		return ret;
	}
	public static function isDirectory(path:String):Bool{
		return FileSystem.isDirectory(getPath(path));
	}
	public static function createDirectory(path:String){
		return FileSystem.createDirectory(getPath(path));
	}
	public static function copy(from:String,to:String){
		return File.copy(getPath(from),getPath(to));
	}
	public static function importFile(from:String,to:String){
		return File.copy(from,getPath(to));
	}
	public static function exportFile(from:String,to:String){
		return File.copy(getPath(from),to);
	}

}

class InternalCache{
	public var spriteArray:Map<String,FlxGraphic> = [];
	public var bitmapArray:Map<String,BitmapData> = [];
	public var xmlArray:Map<String,String> = [];
	public var textArray:Map<String,String> = [];
	public var soundArray:Map<String,Sound> = [];
	public var audioBufferArray:Map<String,AudioBuffer> = [];
	// public var dumpGraphics:Bool = false; // If true, All FlxGraphics will be dumped upon creation, trades off bitmap editability for less memory usage
 
	@:keep inline static function getPath(path):String{return SELoader.getPath(path);}
	

	var id = "Internal Cache";
	public function new(){
		trace('Internal cache initialised');
	}
	public function clear(){
		for (v in spriteArray){
			if(v != null && v.destroy != null){
				v.destroy();
			}
		}
		bitmapArray = [];
		xmlArray = [];
		textArray = [];
		soundArray = [];
		openfl.system.System.gc();
	}
	inline function handleError(e:String){
		SELoader.handleError(e);
	}


	// public function getPath(?str:String = ""){
	// 	return Sys.getCwd() + str;
	// }
	public function loadFlxSprite(x:Int,y:Int,pngPath:String):FlxSprite{
		return new FlxSprite(x, y).loadGraphic(loadGraphic(pngPath));
	}
	public function loadGraphic(pngPath:String):FlxGraphic{
		if(!exists('${pngPath}')){
			handleError('${id}: "${pngPath}" doesn\'t exist!');
			return FlxGraphic.fromRectangle(0,0,0); // Prevents the script from throwing a null error or something
		}
		if(spriteArray[pngPath] == null) cacheGraphic(pngPath);
		return spriteArray[pngPath];
	}
	public function loadBitmap(pngPath:String):BitmapData{
		if(!exists('${pngPath}')){
			handleError('${id}: "${pngPath}" doesn\'t exist!');
			return new BitmapData(0,0,false,0xFF000000); // Prevents the script from throwing a null error or something
		}
		if(bitmapArray[pngPath] == null) cacheBitmap(pngPath);
		return bitmapArray[pngPath];
	}

	public function loadSparrowFrames(pngPath:String):FlxAtlasFrames{
		// if(!exists('${pngPath}.png')){
		// 	handleError('${id}: SparrowFrame PNG "${pngPath}.png" doesn\'t exist!');
		// 	return FlxAtlasFrames.fromSparrow(FlxGraphic.fromRectangle(1,1,0),""); // Prevents the script from throwing a null error or something
		// }
		var _txt = "";
		if(exists('${pngPath}.xml')){
			_txt = loadText(pngPath + ".xml");
		}else{
			handleError('${id}: SparrowFrame XML "${pngPath}.xml" doesn\'t exist!');
			// return FlxAtlasFrames.fromSparrow(FlxGraphic.fromRectangle(1,1,0),""); // Prevents the script from throwing a null error or something
		}

		return FlxAtlasFrames.fromSparrow(loadGraphic(pngPath + ".png"),_txt);
	}
	public function loadSparrowSprite(x:Int,y:Int,pngPath:String,?anim:String = "",?loop:Bool = false,?fps:Int = 24):FlxSprite{
		var spr = new FlxSprite(x, y);
		spr.frames= loadSparrowFrames(pngPath);
		if (anim != ""){
			spr.animation.addByPrefix(anim,anim,fps,loop);
			spr.animation.play(anim);
		}
		return spr;
	}

	public function loadText(textPath:String):String{
		cacheText(textPath);
		return textArray[textPath];
	}
	// public function saveText(textPath:String,text:String):Bool{
	// 	File.saveContent('${textPath}',text);
	// 	return true;
	// }



	public function loadSound(soundPath:String):Sound{
		cacheSound(soundPath);
		return soundArray[soundPath];
	}

	public function playSound(soundPath:String,?volume:Float = 0.662121):FlxSound{
		if(volume == 0.662121) volume = SESave.data.otherVol;
		return FlxG.sound.play(loadSound(soundPath),volume);
	}

	public function unloadSound(soundPath:String){
		if(soundArray[soundPath] == null) return;
		soundArray[soundPath].close();
		soundArray[soundPath] = null;
	}
	public function unloadText(pngPath:String){
		textArray[pngPath] = null;
	}
	public function unloadShader(pngPath:String){
		textArray[pngPath + ".vert"] = null;
		textArray[pngPath + ".frag"] = null;
	}
	public function unloadSprite(pngPath:String){
		if(spriteArray[pngPath] == null) return;
		spriteArray[pngPath].destroy();
		spriteArray[pngPath] = null;
	}

	public function cacheText(textPath:String){
		if(textArray[textPath] != null){
			if(!exists('${textPath}')){
				trace('${id} : CacheText: "${textPath}" doesn\'t exist!');
				return;
			}
			textArray[textPath] = File.getContent('${textPath}');
		}
	}
	public function cacheSound(soundPath:String){
		if(soundArray[soundPath] == null) {
			if(!exists('${soundPath}')){
				trace('${id} : CacheSound: "${soundPath}" doesn\'t exist!');
				return;
			}
			soundArray[soundPath] = Sound.fromFile(getPath(soundPath));
		}
	}
	public function cacheBitmap(pngPath:String){ // DOES NOT CHECK IF FILE IS VALID!
		if(bitmapArray[pngPath] == null) bitmapArray[pngPath] = BitmapData.fromFile(getPath('${pngPath}'));
	}
	public function cacheGraphic(pngPath:String){ // DOES NOT CHECK IF FILE IS VALID!
		
		cacheBitmap('${pngPath}');
		if(spriteArray[pngPath] == null) spriteArray[pngPath] = FlxGraphic.fromBitmapData(bitmapArray[pngPath]);
		if(spriteArray[pngPath] == null) handleError('${id} : cacheGraphic: Unable to load $pngPath into a FlxGraphic!');
		spriteArray[pngPath].persist = true;
		spriteArray[pngPath].destroyOnNoUse = false;
		// if(dumpGraphic || dumpGraphics) spriteArray[pngPath].dump();

	}
	public function cacheSprite(pngPath:String){

		if(spriteArray[pngPath] == null) {
			if(!SELoader.exists('${pngPath}.png')){
				handleError('${id} : CacheSprite: "${pngPath}.png" doesn\'t exist!');
				return;
			}
			cacheGraphic('${pngPath}.png');
		}
	}
	@:keep inline public static function absolutePath(path:String):String{ return SELoader.absolutePath(getPath(path)); }
	@:keep inline public static function fullPath(path:String):String{ return SELoader.fullPath(getPath(path)); }
	@:keep inline public static function exists(path:String):Bool{ return SELoader.exists(getPath(path)); }
	@:keep inline public static function readDirectory(path:String):Array<String>{ return SELoader.readDirectory(getPath(path)); }
	@:keep inline public static function isDirectory(path:String):Bool{ return SELoader.isDirectory(getPath(path)); }
	@:keep inline public static function createDirectory(path:String){ return SELoader.createDirectory(getPath(path)); }
}