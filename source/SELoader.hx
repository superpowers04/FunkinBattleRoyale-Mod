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
import se.formats.SongInfo;
import se.formats.Song.SwagSong;
// import vlc.VLCSound;
using StringTools;

// This uses rawmode all of the time because this uses absolute pathing. 
// I plan to support more storage locations so we HAVE to use SELoader
@:publicFields class SEDirectory { 
	var path:String;
	function new(_path:String = ""){
		path=SELoader.getPath(_path);
		if(path.substring(-1) != "/") path+="/";
	}
	@:keep inline function appendPath(?part:String){
		return part == null ? path : path + part;
	}
	function exists(?path:String):Bool{
		SELoader.rawMode=true;
		return SELoader.exists(appendPath(path));
	}
	function newDirectory(?path:String):SEDirectory{
		SELoader.rawMode=true;
		return new SEDirectory(appendPath(path));
	}
	function isDirectory(?path:String):Bool{
		SELoader.rawMode=true;
		return SELoader.isDirectory(appendPath(path));
	}
	function readDirectory(?path:String){
		SELoader.rawMode=true;
		return SELoader.readDirectory(appendPath(path));
	}
	function getContent(?path:String):String{
		SELoader.rawMode=true;
		return SELoader.getContent(appendPath(path));
	}
	@:keep inline function toString(){
		return path;
	}
}

class SELoader {

	static public var cache:InternalCache = new InternalCache();
	public static var AssetPathCache:Map<String,String>=[];
	public static var aliases:Map<String,String>=[];
	
	public static var PATH(default,set):String = '';
	public static function set_PATH(?_path:String = "./"):String{
		_path = _path.replace('\\',"/"); // Unix styled paths, Windows \\ paths are weird and fucky and i hate it
		if(!_path.endsWith('/')) _path = _path + "/"; // SELoader expects the main path to have a / at the end
		
		return PATH = _path.replace('//','/'); // Fixes paths having //'s in them 
	}
	public static var rawMode = false;
	public static var defaultRawMode = false;
	public static var ignoreMods = false;
	public static var id = "SELoader";
	public static var namespace = "";

	inline public static function handleError(e:String){
		trace(e);
		throw(e);
		// if((cast (FlxG.state)).handleError != null) (cast (FlxG.state)).handleError(e); else MainMenuState.handleError(e);
		
	}
	// Basically clenses paths and returns the base path with the requested one. Used heavily for the Android port
	@:keep inline public static function getPath(path:String="",allowModded:Bool = true):String{
		if(path == "") return PATH;
		// Absolute paths should just return themselves without anything changed
		if( rawMode ||
			#if windows
				path.substring(1,2) == ':' || 
			#end
				path.substring(0,1) == "/" || path.substring(0,2) == "./"){
			rawMode = defaultRawMode;
			return path.replace('//','/');
		}
		if(aliases[path] != null) return getRawPath(aliases[path]);
		// Allow custom assets
		if(path.substring(0,7) == "assets:" || (!ignoreMods && allowModded && path.substring(0,7) == "assets/")){
			return getAssetPath(path);
		}
		// Remove library from path
		if(path.indexOf(":") > 3) path = path.substring(path.indexOf(":") + 1);
		// if( && FileSystem.exists('${PATH}mods${path}')) path = 'mods/' + path; // Return modded assets before vanilla assets

		return (PATH + path).replace('//','/'); // Fixes paths having //'s in them
	}
	// The above but skips the getAssetPath check
	@:keep inline public static function getRawPath(path:String,allowModded:Bool = true):String{
		
		// Absolute paths should just return themselves without anything changed
		if(rawMode || 
			#if windows
				path.substring(1,2) == ':' || 
			#end
				path.substring(0,1) == "/" || path.substring(0,2) == "./"){
			rawMode = defaultRawMode;
			return path.replace('//','/');
		}
		// Remove library from path
		if(path.indexOf(":") > 3) path = path.substring(path.indexOf(":") + 1);

		return (PATH + path).replace('//','/'); // Fixes paths having //'s in them
	}

	public static function getAssetPath(path:String,?namespace:String = ""):String{
		if(#if windows path.substring(1,2) == ':' || #end path.substring(0,1) == "/" || rawMode){
			rawMode=false;
			return path.replace('//','/');
		}
		// Remove library
		if(path.indexOf(':') > 2) path = path.substring(path.indexOf(":") + 1);
		if(path.startsWith('assets/')) path = path.substring(7);
		var modsFolder = new SEDirectory(getRawPath('mods/'));
		var packsFolder = modsFolder.newDirectory('packs/');
		if(namespace=="") namespace=SELoader.namespace;
		if(namespace!=""){ // We always want to check the namespace first, It has top priority
			var e = (namespace == "INTERNAL" || namespace == "assets") ? getPath() : packsFolder+namespace;
			SELoader.ignoreMods = true;
			var the = SELoader.anyExists([
				e+'/'+path,
				e+'/shared/'+path,
				e+'/assets/'+path,
				e+'/assets/shared/'+path,
				e+'/assets/preload/'+path
			]);
			SELoader.ignoreMods = false;
			if(the!=null) return the;
		}
		{ // If the path has already been found before, just use that. No need to re-scan
			var PATH = AssetPathCache[path];
			if(PATH!=null) return PATH == "" ? SELoader.getRawPath("assets/"+path,false) :PATH; 
		}
		{ // Mods folder
			var the = SELoader.anyExists([
				'mods/'+path,
				'mods/shared/'+path,
				'mods/assets/'+path,
				'mods/assets/shared/'+path,
				'mods/assets/preload/'+path
			]);
			if(the!=null) return AssetPathCache[path]=the;
		}
		var p = SELoader.getRawPath("assets/"+path);
		// Cache as an empty string, literally no fucking reason to store the same string twice in memory
		AssetPathCache[path]="";

		if(!exists(p)){ // I am honestly too lazy at the moment to add a proper mods menu
			AssetPathCache[path]=null;
			{
				var e = getRawPath('assets/');
				rawMode=defaultRawMode=true;
				var the = SELoader.anyExists([
					e+'/'+path,
					e+'/shared/'+path,
				]);
				rawMode=defaultRawMode=false;
				if(the!=null) return AssetPathCache[path]=the;
			}
			if(!SESave.data.HDDMode){
				if(SELoader.exists(modsFolder + path)) return AssetPathCache[path]=modsFolder+path;
				for (directory in orderList(SELoader.readDirectory(packsFolder.toString()))){
					var e = packsFolder+directory;
					var the = SELoader.anyExists([
						e+'/'+path,
						e+'/shared/'+path,
						e+'/assets/'+path,
						e+'/assets/shared/'+path,
						e+'/assets/preload/'+path
					]);
					if(the!=null) return AssetPathCache[path]=the;
				}
			}
			trace('Unable to find "${path}"!');
		}
		return p;
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
		if(textPath.lastIndexOf('.') == -1) textPath+='.xml';
		var text = loadText(textPath,useCache);
		return cleanXML(text);
	}
	public static function cleanXML(text:String):String{ // Automatically fixes UTF-16 encoded files
		
		var text = text.replace("UTF-16","utf-8");
		// final nul = String.fromCharCode(0);
		if(text.substr(2).contains("U\x00T\x00F\x00-\x001\x006")){ // Flash CS6 outputs a UTF-16 xml even though no UTF-16 characters are usually used. This reformats the file to be UTF-8 *hopefully*
			text = '<?' + text.substr(2).replace(String.fromCharCode(0),'').replace('UTF-16','utf-8');
		}
		return text;
	}

	public static function loadFlxSprite(x:Float = 0,y:Float = 0,pngPath:String,?useCache:Bool = false):FlxSprite{
		if(!SELoader.exists('${pngPath}')){
			handleError('${id}: Image "${pngPath}" doesn\'t exist!');
			return new FlxSprite(x, y); // Prevents the script from throwing a null error or something
		}
		return new FlxSprite(x, y).loadGraphic(loadGraphic(pngPath,useCache));
	}
	public static function loadGraphic(pngPath:String,?useCache:Bool = false):FlxGraphic{
		if(useCache){
			return cache.loadGraphic(pngPath);
		}
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

	public static function loadSparrowFrames(pngPath:String,?cache:Bool=false):FlxAtlasFrames{
		pngPath = getPath(pngPath);
		if(!exists('${pngPath}.png')){
			handleError('${id}: SparrowFrame PNG "${pngPath}.png" doesn\'t exist!');
			return new FlxAtlasFrames(FlxGraphic.fromRectangle(0,0,0)); // Prevents the script from throwing a null error or something
		}
		if(!exists('${pngPath}.xml')){
			handleError('${id}: SparrowFrame XML "${pngPath}.xml" doesn\'t exist!');
			return new FlxAtlasFrames(FlxGraphic.fromRectangle(0,0,0)); // Prevents the script from throwing a null error or something
		}
		return FlxAtlasFrames.fromSparrow(loadGraphic('$pngPath.png',cache),loadText('${pngPath}.xml',cache));
	}
	public static function loadSparrowSprite(x:Float,y:Float,pngPath:String,?anim:String = "",?loop:Bool = false,?fps:Int = 24,?useCache:Bool = false):FlxSprite{
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
		gc();
	}
	@:keep inline public static function getContent(textPath:String):String{return loadText(textPath,false);}
	public static function getChart(textPath:String,?difficulty:String=""):SwagSong{
		return Song.parseJSONshit(loadText(textPath,false));
/*		if(difficulty != "") return Song.fromVSlice(textPath,difficulty);

		var colonIndex = textPath.lastIndexOf(':');
		if(colonIndex == -1) return Song.parseJSONshit(loadText(textPath,false));
		textPath = textPath.substring(0,colonIndex);
		difficulty = textPath.substring(colonIndex+1);
		return Song.fromVSlice(textPath,difficulty);*/
	}
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
		if(soundPath.lastIndexOf('.') == -1){
			soundPath+='.ogg';
		}
		final rawPath = getPath(soundPath);
		if(cache.soundArray[rawPath] != null || useCache){
			return cache.loadSound(rawPath);
		}
		if(!exists(soundPath)){
			handleError('${id}: Sound "$soundPath" > "$rawPath" doesn\'t exist!');
			// return null;
		}
		return Sound.fromFile(getPath(rawPath));
	}
	@:keep inline public static function loadFlxSound(soundPath:String,?useCache:Bool=false):FlxSound{
		return new FlxSound().loadEmbedded(loadSound(soundPath,useCache));
	}


	static public function playSound(soundPath:String,?volume:Dynamic = null,?cache:Bool = false):FlxSound{
		if(soundPath == null || soundPath == ""){
			try{
				throw('Tried to play a "" sound');
			}catch(e){
				trace('UNABLE TO PLAY SOUND: ${e.details()}');
			}
			return null;
		}
		var _vol = SESave.data.otherVol;
		if(volume != null){

			if(volume is String){
				switch(volume.toLowerCase()){
					case "inst": _vol = SESave.data.instVol;
					case "voices": _vol = SESave.data.voicesVol;
					case "master": _vol = SESave.data.masterVol;
					case "hit": _vol = SESave.data.hitVol;
					case "misses": _vol = SESave.data.missVol;
					default: _vol = SESave.data.otherVol;
				}
			}else if(volume is Int || volume is Float){
				_vol = volume;
			}
		}
		// if(volume == 0.662121) volume = SESave.data.otherVol;
		return FlxG.sound.play(loadSound(soundPath,cache),_vol);
	}


	// Clones of FileSystem and File functions. Eventually, zip support might be added. This'll also allow custom formats to be used

	public static function absolutePath(path:String):String{
		return FileSystem.absolutePath(getPath(path));
	}
	public static function fullPath(path:String):String{
		return FileSystem.fullPath(getPath(path));
	}
	public static function anyExists(paths:Array<String>,?returnOriginal:Bool = false,?defaultValue:String = null):String{
		for(i in paths) {
			var path = getPath(i);
			if(exists(path)) return returnOriginal ? i : path;
		}
		return defaultValue;
	}
	#if windows 
		@:keep inline public static function anyExistsInsensitive(paths:Array<String>,?returnOriginal:Bool = false,?defaultValue:String = null):String{ return anyExists(paths,returnOriginal,defaultValue); }
	#else

	public static function anyExistsInsensitive(paths:Array<String>,?returnOriginal:Bool = false,?defaultValue:String = null):String{
		for(i in paths) {
			var path = getPath(i);
			if(exists(path)) return returnOriginal ? i : path;
		}
		for(i in paths) {
			var path = getPath(i);
			var folder = path.substring(0,path.lastIndexOf('/'));
			var file = path.substring(path.lastIndexOf('/')+1);
			for(FILE in readDirectory(folder)){
				if(FILE.toLowerCase() != file.toLowerCase()) continue;
				return folder+"/"+FILE;
				
			}
			
		}
		return defaultValue;
	}
	#end
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
	@:keep inline public static function getAsDirectory(path:String):SEDirectory{
		return new SEDirectory(path);
	}
	public static function readDirectoriesAsPaths(paths:Array<String>):Array<SEDirectory>{
		var ret = [];
		for(path in paths){
			var _path = new SEDirectory(path);
			if(_path.exists() && _path.isDirectory()){
				for(item in _path.readDirectory()){
					ret.push(_path.newDirectory(item));
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
		var path = getPath(to);
		FileSystem.createDirectory(path.substring(0,path.lastIndexOf('/')));
		return File.copy(from,path);
	}
	public static function exportFile(from:String,to:String){
		return File.copy(getPath(from),to);
	}

	static function orderList(list:Array<String>):Array<String>{
		haxe.ds.ArraySort.sort(list, function(a, b) {
			a=a.toLowerCase();
			b=b.toLowerCase();
			return (a<b) ? -1 : ((a>b) ? 1 : 0);
		});
		return list;
	}
	public static function getSongsFromFolder(path:String):Array<SongInfo>{
		var path=new SEDirectory(path);
		var returnArray:Array<SongInfo> = [];
		if(!path.isDirectory()) return returnArray;
		var blockedFiles = multi.MultiMenuState.blockedFiles;
		if(path.isDirectory('assets/')){ // subfolder
			var stuff:Array<SongInfo> = getSongsFromFolder(path.appendPath('assets/'));
			if(stuff.length > 0){
				for(i in stuff) returnArray.push(i);
			}
		}
		if(path.isDirectory('mods/')){ // subfolder
			var stuff:Array<SongInfo> = getSongsFromFolder(path.appendPath('mods/'));
			if(stuff.length > 0){
				for(i in stuff) returnArray.push(i);
			}
		}
		if(path.isDirectory('charts/')){ // SE
			for (folder in path.readDirectory('charts/')){
				var path = path.newDirectory('charts/$folder');
				if(!path.exists('Inst.ogg') && !path.exists('ignoreMissingInst')) continue;
				var song:SongInfo = {
					name:folder,
					charts:[],
					namespace:null,
					path:path.toString()
				};
				for (file in orderList(path.readDirectory())){
					if(file.substring(file.length-5) != ".json" || blockedFiles.contains(file.toLowerCase())) 
						continue;
					song.charts.push(file);
				}
				returnArray.push(song);
			}
		}
		if(path.isDirectory('data/')){ // Normal FNF
			var songsFolder = path.newDirectory('songs/');
			var data = path.newDirectory('data/');
			if(data.exists('songData')){ // Legacy psych
				data = data.newDirectory('songData');
			}
			var list = data.readDirectory();
			// for (chart in list){
			// 	if(chart.contains(''))
			// }
			for (folder in list){
				var path = data.newDirectory('$folder');
				if(!path.isDirectory() || !songsFolder.exists('$folder/Inst.ogg')) continue;
				var song:SongInfo = {
					name:folder,
					charts:[],
					namespace:null,

					path:path.toString()
				};
				song.inst = songsFolder.appendPath('$folder/Inst.ogg');
				song.voices = songsFolder.appendPath('$folder/Voices.ogg');
				for (file in orderList(path.readDirectory())){
					if(file.substring(file.length-5) != ".json" || blockedFiles.contains(file.toLowerCase())) 
						continue;
					song.charts.push(file);
				}
				returnArray.push(song);
			}
		}
		if(path.isDirectory('songs/')){ // Codename :sob:
			var path = path.newDirectory('songs/');
			for (folder in path.readDirectory()){
				if(!path.isDirectory('$folder/charts')) continue;
				var path = path.newDirectory('$folder');
				var song:SongInfo = {
					name:folder,
					charts:[],
					namespace:null,

					path:path.toString()
				};
				song.inst = path.appendPath('song/Inst.ogg');
				song.voices = path.appendPath('song/Voices.ogg');
				for (file in orderList(path.readDirectory('charts'))){
					if(file.substring(file.length-5) != ".json" || blockedFiles.contains(file.toLowerCase())) 
						continue;
					song.charts.push('charts/$file');
				}
				returnArray.push(song);
			}
		}
		if(returnArray.length < 0){
			for (file in orderList(path.readDirectory())){
				if(!path.isDirectory(file)) continue;
				var songs = getSongsFromFolder(path.appendPath());
				if(songs.length > 0){
					for (song in songs) returnArray.push(song);
				}
			}
		}
		return returnArray;

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
	public function new(?id:String = "Internal Cache"){
		this.id = id;
		trace('New cache $id');
	}
	public function clear(){
		for (v in spriteArray) if(v != null && v.destroy != null) v.destroy();
		for (v in bitmapArray) if(v != null && v.dispose != null) v.dispose();
		for (v in soundArray) if(v != null && v.close != null) v.close();
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
	public function loadFlxSprite(x:Float,y:Float,pngPath:String):FlxSprite{
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
	public function loadSparrowSprite(x:Float,y:Float,pngPath:String,?anim:String = "",?loop:Bool = false,?fps:Int = 24):FlxSprite{
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

	public function playSound(soundPath:String,?volume:Dynamic = null):FlxSound{
		var _vol = SESave.data.otherVol;
		if(volume != null){

			if(volume is String){
				switch(volume.toLowerCase()){
					case "inst": _vol = SESave.data.instVol;
					case "voices": _vol = SESave.data.voicesVol;
					case "master": _vol = SESave.data.masterVol;
					case "hit": _vol = SESave.data.hitVol;
					case "misses": _vol = SESave.data.missVol;
					default: _vol = SESave.data.otherVol;
				}
			}else if(volume is Int || volume is Float){
				_vol = volume;
			}
		}
		// if(volume == 0.662121) volume = SESave.data.otherVol;
		return FlxG.sound.play(loadSound(soundPath),_vol);
	}

	public function unloadSound(soundPath:String){
		if(soundArray[soundPath] == null) return;
		trace('Unloading $soundPath');
		soundArray[soundPath].close();
		soundArray[soundPath] = null;
	}
	public function unloadText(pngPath:String){
		textArray[pngPath] = null;
		trace('Unloading $pngPath');
	}
	public function unloadShader(pngPath:String){
		textArray[pngPath + ".vert"] = null;
		textArray[pngPath + ".frag"] = null;
	}
	public function unloadSprite(pngPath:String){
		if(spriteArray[pngPath] == null) return;
		trace('Unloading $pngPath');
		spriteArray[pngPath].destroy();
		spriteArray[pngPath] = null;
	}

	public function cacheText(textPath:String){
		if(textArray[textPath] == null){
			if(!exists('${textPath}')){
				trace('${id} : CacheText: "${textPath}" doesn\'t exist!');
				return;
			}
			textArray[textPath] = SELoader.getContent(textPath);
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
		if(bitmapArray[pngPath] == null) bitmapArray[pngPath] = BitmapData.fromFile(getPath(pngPath));
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
	public function toString(){
		var sprites = 0;
			for(e in spriteArray) sprites++;
		var sounds = 0;
			for(e in soundArray) sounds++;
		var bitmaps = 0;
			for(e in bitmapArray) bitmaps++;
		var xmls = 0;
			for(e in xmlArray) xmls++;
		var texts = 0;
			for(e in textArray) texts++;
		return '$id Cache. Currently loaded:'
		+' Sprites: ${sprites}'
		+' Audio: ${sounds}'
		+' Bitmaps: ${bitmaps}'
		+' XMLS: ${xmls}'
		+' TEXT: ${texts}';
	}
	public function list(){
		return '$id Cache. Currently loaded:'
		+'\n Sprites: ${spriteArray}'
		+'\n Audio: ${soundArray}'
		+'\n Bitmaps: ${bitmapArray}'
		+'\n XMLS: ${xmlArray}'
		+'\n TEXT: ${textArray}';
	}
	@:keep inline public static function absolutePath(path:String):String{ return SELoader.absolutePath(getPath(path)); }
	@:keep inline public static function fullPath(path:String):String{ return SELoader.fullPath(getPath(path)); }
	@:keep inline public static function exists(path:String):Bool{ return SELoader.exists(getPath(path)); }
	@:keep inline public static function readDirectory(path:String):Array<String>{ return SELoader.readDirectory(getPath(path)); }
	@:keep inline public static function isDirectory(path:String):Bool{ return SELoader.isDirectory(getPath(path)); }
	@:keep inline public static function createDirectory(path:String){ return SELoader.createDirectory(getPath(path)); }
}