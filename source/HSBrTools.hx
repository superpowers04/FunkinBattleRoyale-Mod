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
	public var spriteArray:Map<String,FlxGraphic> = [];
	public var bitmapArray:Map<String,BitmapData> = [];
	public var xmlArray:Map<String,String> = [];
	public var textArray:Map<String,String> = [];
	public var soundArray:Map<String,FlxSound> = [];
	// public var dumpGraphics:Bool = false; // If true, All FlxGraphics will be dumped upon creation, trades off bitmap editability for less memory usage
 
	

	public var optionsMap:Map<String,Dynamic> = new Map<String,Dynamic>();
	public static var shared:Map<String,Dynamic> = new Map<String,Dynamic>();
	public var global(get,never):Map<String,Dynamic>;
	var id = "Unspecified script";
	var hasSettings:Bool = false;
	public function new(_path:String,?id:String = ""){
		path = _path;
		if (!path.endsWith('/')) path = path + "/";
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


	public function getPath(?str:String = ""){
		return SELoader.getPath(path + str);
	}
	public function loadFlxSprite(x:Float,y:Float,pngPath:String):FlxSprite{
		// if(!SELoader.exists('${path}${pngPath}')){
		// 	handleError('${id}: Image "${path}${pngPath}" doesn\'t exist!');
		// 	return new FlxSprite(x, y); // Prevents the script from throwing a null error or something
		// }
		return new FlxSprite(x, y).loadGraphic(loadGraphic(pngPath));
	}
	public function loadGraphic(pngPath:String):FlxGraphic{
		if(!SELoader.exists('${path}${pngPath}')){
			handleError('${id}: "${path}${pngPath}" doesn\'t exist!');
			return FlxGraphic.fromRectangle(0,0,0); // Prevents the script from throwing a null error or something
		}
		if(spriteArray[pngPath] == null) cacheGraphic(pngPath);
		return spriteArray[pngPath];
	}

	public function loadSparrowFrames(pngPath:String):FlxAtlasFrames{
		if(!SELoader.exists('${path}${pngPath}.png')){
			handleError('${id}: SparrowFrame PNG "${path}${pngPath}.png" doesn\'t exist!');
			return new FlxAtlasFrames(FlxGraphic.fromRectangle(0,0,0)); // Prevents the script from throwing a null error or something
		}
		if(!SELoader.exists('${path}${pngPath}.xml')){
			handleError('${id}: SparrowFrame XML "${path}${pngPath}.xml" doesn\'t exist!');
			return new FlxAtlasFrames(FlxGraphic.fromRectangle(0,0,0)); // Prevents the script from throwing a null error or something
		}

		return FlxAtlasFrames.fromSparrow(loadGraphic(pngPath + ".png"),loadXML(pngPath + ".xml"));
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
	public function loadSparrowSprite(x:Int,y:Int,pngPath:String,?anim:String = "",?loop:Bool = false,?fps:Int = 24):FlxSprite{
		var spr = new FlxSprite(x, y);
		spr.frames= loadSparrowFrames(pngPath);
		if (anim != ""){
			spr.animation.addByPrefix(anim,anim,fps,loop);
			spr.animation.play(anim);
		}
		return spr;
	}
	public function reset(){
		for(graphic in spriteArray){
			try{
				graphic.destroy();
			}catch(e){}
		}
		spriteArray.clear();
		bitmapArray.clear();
		soundArray.clear();
		textArray.clear();
		xmlArray.clear();
		// spriteArray = [];
		// bitmapArray = [];
		// xmlArray = [];
		// textArray = [];
		// soundArray = [];
	}

	public function exists(textPath:String):Bool{
		return SELoader.exists('${path}${textPath}');
	}
	public function loadText(textPath:String):String{
		if(textArray[textPath] == null) textArray[textPath] = SELoader.loadText('${path}${textPath}');
		return textArray[textPath];
	}
	// The above but hits the xml cache instead
	public function loadXML(textPath:String):String{
		if(xmlArray[textPath] == null) xmlArray[textPath] = SELoader.loadXML('${path}${textPath}');
		return xmlArray[textPath];
	}
	public function loadShader(textPath:String,?glslVersion:Dynamic = 120)#if(FLXRUNTIMESHADER) :Null<FlxRuntimeShader> #end{
		#if !FLXRUNTIMESHADER

			handleError('Shaders aren\'t supported enabled on this build of the game!');
			return null;
		#else
			if(textArray[textPath + ".vert"] == null && SELoader.exists('${path}${textPath}.vert')) textArray[textPath + ".vert"] = SELoader.loadText('${path}${textPath}.vert');
			if(textArray[textPath + ".frag"] == null && SELoader.exists('${path}${textPath}.frag')) textArray[textPath + ".frag"] = SELoader.loadText('${path}${textPath}.frag');
			try{
				var shader = new FlxRuntimeShader(textArray[textPath + ".vert"],textArray[textPath + ".frag"],Std.string(glslVersion));
				// if(init) shader.initialise(); // If the shader uses custom variables, this can prevent loading a broken shader
				return shader;

			}catch(e){
				handleError('${id}: Unable to load shader "${textPath}": ${e.message}');
				trace(e.message);
			}
			return null;
		#end
	}
	// public function saveText(textPath:String,text:String):Bool{
	// 	File.saveContent('${path}${textPath}',text);
	// 	return true;
	// }




	 public function loadSound(soundPath:String):FlxSound{
		if(soundArray[soundPath] == null) soundArray[soundPath] = SELoader.loadFlxSound('${path}${soundPath}');
		@:privateAccess{
			return new FlxSound().loadEmbedded(soundArray[soundPath]._sound);
		}
	}
	public function loadFlxSound(soundPath:String) return loadSound(soundPath);

	public function playSound(soundPath:String,?volume:Float = 2):FlxSound{
		var sound = loadFlxSound(soundPath);
		sound.volume = (volume == 2 ? SESave.data.otherVol : volume);
		FlxG.sound.list.add(sound);
		return sound.play();
	}

	public function unloadSound(soundPath:String){
		soundArray[soundPath] = null;
	}
	public function unloadText(pngPath:String){
		textArray[pngPath] = null;
	}
	public function unloadShader(pngPath:String){
		textArray[pngPath + ".vert"] = null;
		textArray[pngPath + ".frag"] = null;
	}
	public function unloadXml(pngPath:String){
		xmlArray[pngPath] = null;
	}
	public function unloadSprite(pngPath:String){
		spriteArray[pngPath] = null;
	}

	public function cacheSound(soundPath:String){
		if(soundArray[soundPath] == null) {
			if(!SELoader.exists('${path}${soundPath}')){
				trace('${id} : CacheSound: "${path}${soundPath}" doesn\'t exist!');
				return;
			}
			soundArray[soundPath] = SELoader.loadFlxSound('${path}${soundPath}');
		}
	}
	public function cacheGraphic(pngPath:String,?dumpGraphic:Bool = false){ // DOES NOT CHECK IF FILE IS VALID!
		
		if(bitmapArray[pngPath] == null) bitmapArray[pngPath] = SELoader.loadBitmap('${path}${pngPath}');
		
		if(spriteArray[pngPath] == null) spriteArray[pngPath] = FlxGraphic.fromBitmapData(bitmapArray[pngPath]);
		if(spriteArray[pngPath] == null) return handleError('${id} : cacheGraphic: Unable to load $pngPath into a FlxGraphic!');
		spriteArray[pngPath].destroyOnNoUse = false;
		// if(dumpGraphic || dumpGraphics) spriteArray[pngPath].dump();

	}
	public function cacheSprite(pngPath:String,?dump:Bool = false){

		if(spriteArray[pngPath] == null) {
			if(!SELoader.exists('${path}${pngPath}.png')){
				handleError('${id} : CacheSprite: "${path}${pngPath}.png" doesn\'t exist!');
				return;
			}
			cacheGraphic('${pngPath}.png',dump);
		}
	}
}
