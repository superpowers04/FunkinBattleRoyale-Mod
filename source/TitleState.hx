package;


import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;
import sys.io.File;
import sys.FileSystem;
import flixel.math.FlxMath;

import flash.display.Graphics;
import flash.display.Sprite;
import flash.Lib;
import SickMenuState;
import openfl.media.Sound;
import flixel.FlxCamera;
import sys.thread.Thread;
import Alphabet;

#if discord_rpc
	import Discord.DiscordClient;
#end

using StringTools;

typedef Scorekillme = {
	var scores:Array<Float>;
	var songs:Array<String>;
	var funniNumber:Float;
}
@:structInit class CharInfo{
	public var id:String = "";
	public var path(get,default):String = null;
	public function get_path(){
		return ((path == "" || path == null) ? "mods/characters/" : path);
	}
	public var folderName:String = "";
	public var description:String = null;
	public var nameSpace:String = null;
	public var nameSpaceType:Int = 0; // 0: mods/characters, 1: mods/weeks, 2: mods/packs 
	public var internal:Bool = false;
	public var internalAtlas:String = "";
	public var internalJSON:String = "";
	public var type:Int = 0x0; // 0: PNG/XML based, 1: Script based
	public var hidden = false;

	public function toString(){
		return 'Character $nameSpace/$id, Raw folder name:$folderName, path:$path';
	}
	public function getNamespacedName(){
		return (nameSpace == null ? id : '$nameSpace|$id');
	}
}
@:structInit class StageInfo{
	public var id:String = "";
	public var path(get,default):String = null;
	public function get_path(){
		if(path == "" || path == null) return "mods/stages/";
		return path;
	}
	public var folderName:String = "";
	public var nameSpace:String = null;
	public var nameSpaceType:Int = 0; // 0: mods/stages, 1: mods/weeks, 2: mods/packs 

	public function toString(){
		return 'Stage $nameSpace/$id, Raw folder name:$folderName, path:$path';
	}
	public function getNamespacedName(){
		return (nameSpace == null ? id : '$nameSpace|$id');
	}
}



class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxTypedGroup<FlxSprite>;
	var ngSpr:FlxSprite;
	public static var p2canplay = true;
	// public static var choosableStages:Array<String> = ["default","stage","nothing"];
	// public static var choosableStagesLower:Map<String,String> = [];

	public static var characters:Array<CharInfo> = [];
	static var defaultChar:CharInfo;
	public static var stages:Array<StageInfo> = [];


	public static var easterEgg(default,set):Int = 0x00;
	public static function set_easterEgg(val:Int){
		if(SESave.data.easterEggs) return easterEgg = val;
		return 0x00;
	}

	public static var invalidCharacters:Array<CharInfo> = []; // This is a seperate array because the character doesn't need metadata beyond it being invalid


	// Var's I have because I'm to stupid to get them to properly transfer between certain functions
	public static var returnStateID:Int = 0;
	public static var supported:Bool = false;
	public static var outdated:Bool = false;
	public static var checkedUpdate:Bool = false;
	public static var updatedVer:String = "";
	public static var osuBeatmapLoc:String = "";
	public static var songScores:Scorekillme;
	public static var pauseMenuMusic:Sound;



	public var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;
	public static function loadNoteAssets(?forced:Bool = false,?forced2:Bool = false){
		if (NoteAssets == null || NoteAssets.name != SESave.data.noteAsset || forced){
			if (!SELoader.exists('mods/noteassets/${SESave.data.noteAsset}.png') || !SELoader.exists('mods/noteassets/${SESave.data.noteAsset}.xml')){
				SESave.data.noteAsset = "default";
			} // Hey, requiring an entire reset of the game's settings when noteasset goes missing is not a good idea
			new NoteAssets(SESave.data.noteAsset,forced2);
		}
	}
	public static function findChar(char:String,?retBF:Bool = true,?ignoreNSCheck:Bool = false,?fuzzySearch:Bool = true):Null<CharInfo>{
		if(char == ""){
			trace('Empty character search, returning BF');
			if(retBF) return defaultChar;
			return null;
		}
		if(char.startsWith('NULL|')) char = char.replace('NULL|','');
		if(char.startsWith('null|')) char = char.replace('null|','');
		if(!ignoreNSCheck && char.contains('|')){

			var _e = char.split('|');
			return findCharNS(_e[1],_e[0],-1,retBF,fuzzySearch);
		}
		if(char == "" || char == "automatic"){
			trace('Tried to get a blank character!');
			if(retBF) return defaultChar;
			return null;
		}
		if(Std.parseInt(char) != null && !Math.isNaN(Std.parseInt(char))){
			var e = Std.parseInt(char);
			if(characters[e] != null){

				trace('Found char with ID of $e');
				return characters[e];
			}else{
				trace('Invalid ID $e, out of range 0-${characters.length}');
				if(retBF) return defaultChar;
				return null;
			}
		}
		char = char.replace(' ',"-").replace('_',"-").toLowerCase();
		
		if(char.contains("-") && fuzzySearch){
			var splitChar = char.split('-');
			var splitCharMap:Map<String,Int> = [];
			var curStr = "";
			for(index => split in splitChar){
				curStr +=(index == 0 ? split : '-$split');
				splitCharMap[curStr] = index;
			}
			var curProbability = -1;
			var probableChar:CharInfo = null;
			for (i in characters){
				if(i.id == char){
					return i;
				}else if(splitCharMap.exists(i.id)){
					curProbability = splitCharMap[i.id];
					probableChar = i;
				}
			}
			if(curProbability >= 0){
				trace('Found character with substring ${probableChar.id}');
				return probableChar;
			}

		}else{
			for (i in characters) if(i.id == char) return i;
		}
		trace('Unable to find $char!');
		if(retBF) return defaultChar;
		return null;
	}
	public static function findInvalidChar(char:String):CharInfo{
		char = char.replace('INVALID|',"");
		if(Std.parseInt(char) != null && !Math.isNaN(Std.parseInt(char))){
			var e = Std.parseInt(char);
			if(invalidCharacters[e] != null){
				return invalidCharacters[e];
			}else{
				return null;
			}
		}
		char = char.replace(' ',"-").replace('_',"-").toLowerCase();
		for (i in invalidCharacters){
			if(i.id == char) return i;
		}
		
		return findChar(char);
	}
	// This prioritises characters from a specific namespace, if it finds one outside of the namespace, then they'll be used instead
	public static function findCharNS(char,?namespace:String = "",?nameSpaceType:Int = -1,?retBF:Bool = true,?fuzzySearch:Bool = true){
		if(namespace == "INVALID"){
			return findInvalidChar(char);
		}
		if(char == "" || char == "automatic"){
			trace('Tried to get a blank character!');
			if(retBF) return defaultChar;
			return null;
		}
		var currentChar:CharInfo = null;
		char = char.replace(' ',"-").replace('_',"-").toLowerCase();
		
		if(char.contains("-") && fuzzySearch){
			var splitChar = char.split('-');
			var splitCharMap:Map<String,Int> = [];
			var curStr = "";
			for(index => split in splitChar){
				splitCharMap[curStr += (index == 0 ? split : '-$split')] = index;
			}
			var curProbability = -1;
			var probableChar:CharInfo = null;
			for (i in characters){
				if(i.id == char){
					if((i.nameSpace == namespace && i.nameSpaceType == nameSpaceType) || nameSpaceType == -1){
						return i;
					}
					currentChar = i;
				}else if(currentChar == null && splitCharMap.exists(i.id)){
					curProbability = splitCharMap[i.id];
					probableChar = i;
				}
			}
			if(currentChar == null && curProbability >= 0){
				trace('Found character with substring ${probableChar.id}');
				return probableChar;
			}

		}else{
			for (i in characters){
				if(i.id == char.toLowerCase()){
					if((i.nameSpace == namespace && i.nameSpaceType == nameSpaceType) || nameSpaceType == -1){
						return i;
					}
					currentChar = i;
				}
			}
		}


		if(currentChar == null){
			trace('Unable to find $char!');
			if(retBF) return defaultChar;
			return null;
		}
		return currentChar;
	}
	public static function findCharByNamespace(char:String = "",?namespace:String = "",?nameSpaceType:Int = -1,?retBF:Bool = true):Null<CharInfo>{ 
		if(char == ""){
			trace('Empty character search, returning $defaultChar');
			if(retBF) return defaultChar;
			return null;
		}
		if(char.contains('|')){
			var _e = char.split('|');
			namespace = _e[0];
			char = _e[1];
		}
		if(namespace == "" || namespace.toLowerCase() == "null") return findChar(char,retBF,true);
		return findCharNS(char,namespace,nameSpaceType,retBF);
	}
	public static function retChar(char:String,fuzzySearch:Bool = true):String{
		var char = findChar(char,false,false,fuzzySearch);
		return ((char == null) ? "" : char.id);
	}
	public static function getCharFromList(list:Array<String>,nameSpace:String = ""):CharInfo{
		trace(list);
		while (list.length > 0){
			var char = list.pop();
			if(char == "" || char == "bf" || char == "null|bf"){continue;}
			var charInfo = findCharByNamespace(char,nameSpace,false);
			if(charInfo != null) return charInfo;
		}
		trace('Unable to find anyone in $list, returning $defaultChar');
		return defaultChar;
	}
	@:keep inline public static function retCharPath(char:String):String{
		var path = findChar(char,false);
		return (if(path == null || path.path == null) "" else path.path);
	}
	@:keep inline public static function checkCharacters(){
		LoadingScreen.loadingText = 'Updating character list';
		characters = [
			{id:"bf",folderName:"bf",path:"assets/",nameSpace:"INTERNAL",internal:true,internalAtlas:"characters/BOYFRIEND",internalJSON:Character.BFJSON,description:"The funny rap guy"},
			{id:"gf",folderName:"gf",path:"assets/",nameSpace:"INTERNAL",internal:true,internalAtlas:"characters/GF_assets",internalJSON:Character.GFJSON,description:"The funny boombox girl"},
			{id:"lonely",folderName:"lonely",path:"assets/",nameSpace:"INTERNAL",internal:true,internalAtlas:"onlinemod/lonely",internalJSON:Character.BFJSON,description:"Not much is known about them besides their ability to mimic any voice, they're invisible and very shy"},
		];
		defaultChar = characters[0];
		invalidCharacters = [];
		#if sys
		// Loading like this is probably not a good idea
		
		var customCharacters:Array<String> = [];


		if (SELoader.exists("assets/characters/")){
			var dir = "assets/characters";
			trace('Checking ${dir} for characters');
			for (char in SELoader.readDirectory(dir)) {
				if (!SELoader.isDirectory(dir+"/"+char)){continue;}
				if (SELoader.exists(dir+"/"+char+"/config.json")) {
					customCharacters.push(char);
					var desc = 'Assets character';
					if (FileSystem.exists('${dir}/${char}/description.txt'))
						desc += ";" + SELoader.getContent('${dir}/${char}/description.txt');
					characters.push({
						id:char.replace(' ','-').replace('_','-').toLowerCase(),
						folderName:char,
						path:"assets/characters/",
						nameSpace:"SEAssetsFolder",
						description:desc
					});

				}else if (SELoader.exists(dir+"/"+char+"/character.png") && (SELoader.exists(dir+"/"+char+"/character.xml") || SELoader.exists(dir+"/"+char+"/character.json"))){
					// invalidCharacters.push([char,dir]);
					invalidCharacters.push({
						id:char.replace(' ','-').replace('_','-').toLowerCase(),
						folderName:char,
						nameSpace:"SEAssetsFolder",
						path:dir
					});
				}
			}
		}

		if (SELoader.exists("mods/characters/")){
			for (directory in SELoader.readDirectory("mods/characters/")) {
				if (!SELoader.isDirectory("mods/characters/"+directory)){continue;}
				if (SELoader.exists("mods/characters/"+directory+"/config.json")) {
					var desc = null;
					if (SELoader.exists("mods/characters/"+directory+"/description.txt"))
						desc = SELoader.getContent('mods/characters/${directory}/description.txt');

					characters.push({
						id:directory.replace(' ','-').replace('_','-').toLowerCase(),
						folderName:directory,
						nameSpace:"SECharactersFolder",
						description:desc
					});
				}else if (SELoader.exists("mods/characters/"+directory+"/script.hscript")) {
					var desc = null;
					if (SELoader.exists("mods/characters/"+directory+"/description.txt"))
						desc = SELoader.getContent('mods/characters/${directory}/description.txt');

					characters.push({
						id:directory.replace(' ','-').replace('_','-').toLowerCase(),
						folderName:directory,
						description:desc,
						nameSpace:"SECharactersFolder",
						type:1
					});
				}else if (SELoader.exists("mods/characters/"+directory+"/character.png") && (SELoader.exists("mods/characters/"+directory+"/character.xml") || SELoader.exists("mods/characters/"+directory+"/character.json"))){
					// invalidCharacters.push([directory,'mods/characters']);
					invalidCharacters.push({
						id:directory.replace(' ','-').replace('_','-').toLowerCase(),
						folderName:directory,
						nameSpace:"SECharactersFolder",
						path:'mods/characters'
					});
				}
			}
		}

		

		for (ID => dataDir in ['mods/weeks/','mods/packs/']) {
			
			if (SELoader.exists(dataDir))
			{
			  for (_dir in SELoader.readDirectory(dataDir))
			  {
				if (!SELoader.isDirectory(dataDir + _dir)){continue;}
				// trace(_dir);
				if (SELoader.exists(dataDir + _dir + "/characters/"))
				{
					var dir = dataDir + _dir + "/characters/";
					// trace('Checking ${dir} for characters');
					for (char in FileSystem.readDirectory(dir))
					{
						if (!SELoader.isDirectory(dir+"/"+char)){continue;}
						if (SELoader.exists(dir+"/"+char+"/config.json"))
						{
							var desc = "";
							if (SELoader.exists('${dir}/${char}/description.txt'))
								desc += ";" +SELoader.getContent('${dir}/${char}/description.txt');
							characters.push({
								id:char.replace(' ',"-").replace('_',"-").toLowerCase(),
								folderName:char,
								description:desc,
								path:dir,
								nameSpaceType:ID,
								nameSpace:_dir
							});

						}else if (SELoader.exists(dir+"/"+char+"/script.hscript"))
						{
							var desc = "";
							if (SELoader.exists('${dir}/${char}/description.txt'))
								desc += ";" +SELoader.getContent('${dir}/${char}/description.txt');
							characters.push({
								id:char.replace(' ',"-").replace('_',"-").toLowerCase(),
								folderName:char,
								description:desc,
								path:dir,
								nameSpaceType:ID,
								type:1,
								nameSpace:_dir
							});

						}else if (SELoader.exists(dir+"/"+char+"/character.png") && (SELoader.exists(dir+"/"+char+"/character.xml") || SELoader.exists(dir+"/"+char+"/character.json"))){
							invalidCharacters.push({
								id:char.replace(' ',"-").replace('_',"-").toLowerCase(),
								folderName:char,
								path:dir,
								nameSpaceType:ID,
								nameSpace:_dir
							});
						}
					}
				}		
			  }
			}
		}
		if(easterEgg == 0x1){
			characters[0] = defaultChar = findChar('bf-girlfriendmode');
			trace('${characters[0]} lesbian mode hopefully?');
		}
		trace('Found ${characters.length} characters');
		// try{

		// 	var rawJson = File.getContent('assets/data/characterMetadata.json');
		// 	// trace('Char Json: \n${rawJson}');
		// 	TitleState.defCharJson = haxe.Json.parse(CoolUtil.cleanJSON(rawJson));
		// 	if (defCharJson == null || TitleState.defCharJson.characters == null || TitleState.defCharJson.aliases == null) {defCharJson = {
		// 		characters:[],
		// 		aliases:[]
		// 	};trace("Character characterMetadata is null!");}
		// }catch(e){
		// 	MainMenuState.errorMessage = 'An error occurred when trying to parse Character Metadata:\n ${e.message}.\n You can reload this using Reload Char/Stage List';
		// 	if (defCharJson == null || TitleState.defCharJson.characters == null || TitleState.defCharJson.aliases == null) {defCharJson = {
		// 		characters:[],
		// 		aliases:[]
		// 	};
		// 	}
		// }
		#end
		checkStages();


		if(SESave.data.scripts != null){
			var scripts:Array<String> = [];
			for (v in SESave.data.scripts) {
				if(!SELoader.exists('mods/scripts/${v}/')){
					trace('Script $v doesn\'t exist! Disabling');
					continue;
				}
				scripts.push(cast v);
			}
			SESave.data.scripts = scripts;
		}
	}

	public static function retStage(char:String):String{
		return findStageByNamespace(char,true).getNamespacedName();
	}
	public static function findStage(char:String,?retStage:Bool = true,?ignoreNSCheck:Bool = false):Null<StageInfo>{
		if(char == ""){
			trace('Empty stage search, returning Stage');
			if(retStage) return stages[1];
			return null;
		}
		if(char.startsWith('NULL|')) char = char.replace('NULL|','');
		if(char.contains('|') && !ignoreNSCheck){
			return inline findStageByNamespace(char,retStage);
		}
		if(char == ""){
			trace('Tried to get a blank stage!');
			if(retStage) return stages[1];
			return null;
		}
		if(Std.parseInt(char) != null && !Math.isNaN(Std.parseInt(char))){
			var e = Std.parseInt(char);
			if(stages[e] != null){

				// trace('Found char with ID of $e');
				return stages[e];
			}else{
				trace('Invalid ID $e, out of range 0-${stages.length}');
				if(retStage) return stages[1];
				return null;
			}
		}
		char = char.replace(' ',"-").replace('_',"-").toLowerCase();
		for (i in stages){
			if(i.id == char.toLowerCase()){
				return i;
			}
		}
		trace('Unable to find $char!');
		if(retStage) return stages[1];
		return null;
	}
	// This prioritises stages from a specific namespace, if it finds one outside of the namespace and the namespace doesn't have one, then they'll be used instead
	public static function findStageByNamespace(stage:String = "",?namespace:String = "",?nameSpaceType:Int = -1,?retStage:Bool = true):Null<StageInfo>{ 
		if(stage == ""){
			trace('Empty stage search, returning stage');
			if(retStage) return stages[1];
			return null;
		}
		if(stage.contains('|')){
			var _e = stage.split('|');
			namespace = _e[0];
			stage = _e[1];
		}
		if(namespace == "") return findStage(stage,retStage,true);
		if(stage == ""){
			trace('Tried to get a blank stageacter!');
			if(retStage) return stages[1];
			return null;
		}
		var currentstage:StageInfo = null;
		stage = stage.replace(' ',"-").replace('_',"-");
		for (i in stages){
			if(i.id == stage.toLowerCase()){
				if(i.nameSpace == namespace && (nameSpaceType == -1 || i.nameSpaceType == nameSpaceType)){
					return i;
				}
				currentstage = i;
			}
		}
		if(currentstage == null){
			trace('Unable to find $stage!');
			if(retStage) return stages[1];
			return null;
		}
		return currentstage;
	}
	public static function checkStages(){

		LoadingScreen.loadingText = 'Updating stage list';
		stages = [
			{id:"nothing",folderName:"nothing",path:"assets/",},
			{id:"stage",folderName:"stage",path:"assets/",},
		];
		#if sys
		// Loading like this is probably not a good idea
		var dataDir:String = "mods/stages/";

		if (SELoader.exists(dataDir))
		{
		  for (directory in SELoader.readDirectory(dataDir))
		  {
			if (!SELoader.isDirectory(dataDir+"/"+directory)){continue;}
			if (SELoader.exists(dataDir+"/"+directory+"/"))
			{
				stages.push({
					id:directory.replace(' ','-').replace('_','-').toLowerCase(),
					folderName:directory,
				});
			}
		  }
		}

		

		for (ID => dataDir in ['mods/weeks/','mods/packs/']) {
			
			if (SELoader.exists(dataDir))
			{
			  for (_dir in SELoader.readDirectory(dataDir))
			  {
				if (!SELoader.isDirectory(dataDir + _dir)){continue;}
				// trace(_dir);
				if (SELoader.exists(dataDir + _dir + "/stages/"))
				{
					var dir = dataDir + _dir + "/stages/";
					// trace('Checking ${dir} for characters');
					for (char in SELoader.readDirectory(dir))
					{
						if (!SELoader.isDirectory(dir+"/"+char)){continue;}
						stages.push({
							id:char.replace(' ',"-").replace('_',"-").toLowerCase(),
							folderName:char,
							path:dir,
							nameSpaceType:ID,
							nameSpace:_dir
						});
					}
				}		
			  }
			}
		}
		trace('Found ${stages.length} stages');
		#end
	}
	#if !android
	public static function findosuBeatmaps(){
		var loc = "";
		#if windows
			if (Sys.getEnv("LOCALAPPDATA") != null && FileSystem.exists('${Sys.getEnv("LOCALAPPDATA")}/osu!/Songs/')) loc = '${Sys.getEnv("LOCALAPPDATA")}/osu!/Songs/';
			if (Sys.getEnv("LOCALAPPDATA") != null && FileSystem.exists('${Sys.getEnv("LOCALAPPDATA")}/osu-stable/Songs/')) loc = '${Sys.getEnv("LOCALAPPDATA")}/osu-stable/Songs/';
		#else
			if (Sys.getEnv("HOME") != null && FileSystem.exists('${Sys.getEnv("HOME")}/.local/share/osu-stable/Songs/')) loc = '${Sys.getEnv("HOME")}/.local/share/osu-stable/Songs/';
			// if (loc == "") trace('${Sys.getEnv("HOME")}/.local/share/osu-stable/songs/ doesnt exist!');
		#end

		osuBeatmapLoc = loc;
	}
	#end

	override public function create():Void
	{

		forceQuit = false; // You can't force quit to something that hasn't been loaded

		var now = Date.now();
		if(now.getMonth() == 5){
			easterEgg = 0x1;
			lime.app.Application.current.window.title = "Friday Night Funkin' Lesbian Engine";
		}

		LoadingScreen.loadingText = 'Loading "shared" library';
		Assets.loadLibrary("shared");
		Assets.loadLibrary("assets");
		Paths.setCurrentLevel("assets");
		@:privateAccess
		{
			trace('Loaded ${openfl.Assets.list().length} assets');
		}
		


		curWacky = getIntroTextShit();
		

		super.create();
		
		if(CoolUtil.font != Paths.font("vcr.ttf")) flixel.system.FlxAssets.FONT_DEFAULT = CoolUtil.font;
		#if !android
			KadeEngineData.initSave();
			Highscore.load();
			checkCharacters();
		#end

		#if discord_rpc
			DiscordClient.initialize();
		
			Application.current.onExit.add (function (exitCode) {
				DiscordClient.shutdown();
			 });
		#end

		new FlxTimer().start(0.25, function(tmr:FlxTimer)
		{
			startIntro();
		});
	}

	var logoBl:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:Alphabet;
	override function tranOut(){return;}
	function startIntro() {
		
		AlphaCharacter.cacheAlphaChars();
		LoadingScreen.loadingText = 'Loading TitleState';
		if (!initialized){
			
			var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
			diamond.persist = true;
			diamond.destroyOnNoUse = false;

			FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(-1, 0), {asset: diamond, width: 32, height: 32},
				new FlxRect(-FlxG.width * 0.5, -FlxG.height * 0.5, FlxG.width * 2, FlxG.height * 2));
			FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.5, new FlxPoint(1, 0),
				{asset: diamond, width: 32, height: 32}, new FlxRect(-FlxG.width * 0.5, -FlxG.height * 0.5, FlxG.width * 2, FlxG.height * 2));

			transIn = FlxTransitionableState.defaultTransIn;
			transOut = FlxTransitionableState.defaultTransOut;
			
			// FlxTween.tween(Main.fpsCounter,{alpha:1},0.2);


			// HAD TO MODIFY SOME BACKEND SHIT
			// IF THIS PR IS HERE IF ITS ACCEPTED UR GOOD TO GO
			// https://github.com/HaxeFlixel/flixel-addons/pull/348

			// var music:FlxSound = new FlxSound();
			// music.loadStream(Paths.music('freakyMenu'));
			// FlxG.sound.list.add(music);
			// music.play();
			FlxG.sound.playMusic(Paths.music('StartItchBuild'), 0.1);
			FlxG.sound.music.pause();
			// LoadingState.loadingText = new FlxText(FlxG.width * 0.8,FlxG.height * 0.8,"Loading...");
			// LoadingState.loadingText.setFormat();

			
			#if android

				FlxG.android.preventDefaultKeys = [BACK];
				// trace(lime.system.System.applicationStorageDirectory);
				// var reason = 0;
				// if(!FileSystem.exists(lime.system.System.applicationStorageDirectory + '/path.txt')){
				// 	reason = 1;
				// }else if(!FileSystem.exists(sys.io.File.getContent(FileSystem.exists(lime.system.System.applicationStorageDirectory + '/path.txt')))){
				// 	reason = 2;
				// }
				// if(reason != 0){

				// }
				var grantedPerms = Main.grantedPerms = android.Permissions.getGrantedPermissions();
				if(!grantedPerms.contains('android.permission.WRITE_EXTERNAL_STORAGE')){
					android.Permissions.requestPermissions(['android.permission.WRITE_EXTERNAL_STORAGE','android.permission.INTERNET'],1);
					throw('Please reload. Permissions are required for the mods folder.\nIf you do not see a dialogue asking for accessing files then please add it manually in your settings');
				}else{

					if(!grantedPerms.contains('android.permission.INTERNET')){
						android.Permissions.requestPermissions(['android.permission.INTERNET'],1);
					}
					if(!FileSystem.exists('${android.os.Environment.getExternalStorageDirectory()}/Superpowers04/SuperEngine/')){
						try{
							android.widget.Toast.makeText('Attempting to create mods folder',20);
							FileSystem.createDirectory('${android.os.Environment.getExternalStorageDirectory()}/Superpowers04/');
							FileSystem.createDirectory('${android.os.Environment.getExternalStorageDirectory()}/Superpowers04/SuperEngine/');
							Sys.setCwd('${android.os.Environment.getExternalStorageDirectory()}/Superpowers04/SuperEngine/');

							android.widget.Toast.makeText('Finished!',20);
						}catch(e){
							FuckState.FATAL = true;
							throw('Unable to create directory "${android.os.Environment.getExternalStorageDirectory()}/Superpowers04/SuperEngine/"! ${e.message}');

						}
					}
				}
				SELoader.PATH = '${android.os.Environment.getExternalStorageDirectory()}/Superpowers04/SuperEngine/';
				Sys.setCwd('${android.os.Environment.getExternalStorageDirectory()}/Superpowers04/SuperEngine/');
				if(!SELoader.exists('mods')){
					try{
						var _dir = lime.system.System.applicationStorageDirectory;
						function recurse(directory:String){
							directory = directory.replace('//','/');
							SELoader.createDirectory(directory);
							for(file in FileSystem.readDirectory(_dir + "/" + directory)){
								android.widget.Toast.makeText('Copying $file',5);
								file = "/" + directory + "/" + file;
								file = file.replace('//','/');
								if(FileSystem.isDirectory(_dir + file)){ recurse(file); continue;}
								SELoader.importFile(_dir + file,file);
							}
						}
						trace('Copying files from $_dir');
						for(file in FileSystem.readDirectory(_dir)){
							trace('Copying $file');
							SELoader.createDirectory(file);
							if(FileSystem.isDirectory(_dir + file)){ recurse(file); continue;}
							android.widget.Toast.makeText('Copying $file',5);
							SELoader.importFile(_dir + file,file);

						}

					}catch(e){
						FuckState.FATAL = true;
						throw('Unable to copy files! ${e.message}');

					}
				}
				android.widget.Toast.makeText('Your mods and stuff will be located at "Superpowers04/SuperEngine"',5);
				// Moved the init to here since settings aren't accessable yet
				KadeEngineData.initSave();
				Highscore.load();
				checkCharacters();
				Alphabet.Frames = null;
				LoadingScreen.forceHide();
				LoadingScreen.initScreen();
				if((CoolUtil.font = if(SELoader.exists('mods/font.ttf')) SELoader.getPath('mods/font.ttf') else Paths.font(CoolUtil.fontName)
					) != Paths.font("vcr.ttf")) flixel.system.FlxAssets.FONT_DEFAULT = CoolUtil.font;
			#end
			#if !android
				findosuBeatmaps();
			#end
			var isUsingPaths = false;
			if(SELoader.exists('path.txt')){
				SELoader.PATH = SELoader.loadText('path.txt');
				trace('Loading files from ${SELoader.PATH}');
				isUsingPaths = true;
			}
			if(!SELoader.exists('assets')){
				FuckState.FATAL = true;
				FuckState.FUCK('It seems "${SELoader.absolutePath('./')}" has no assets folder'
				#if(android) 
				+ "\nDue to android weirdness, you'll have to manually copy your Assets, Manifest and Mods folder to the folder listed above\nYou can get these from a Desktop build of the game" 
				#else
				+(isUsingPaths?"\nDid you uncompress the game's assets to this folder before setting up path.txt?":"Did you make sure to extract the game?")
				#end
				,"TitleState.checkPathisValid");
				return;
			}
			MainMenuState.firstStart = true;
			Conductor.changeBPM(140);
			persistentUpdate = true;
			FlxG.mouse.enabled = true;
			FlxG.fixedTimestep = false; // Makes the game not be based on FPS for things, thank you Forever Engine for doing this
			FlxG.mouse.useSystemCursor = SESave.data.useSystemCursor; // Uses system cursor, did not know this was a thing until Forever Engine
			CoolUtil.volKeys = [FlxG.sound.muteKeys,FlxG.sound.volumeUpKeys,FlxG.sound.volumeDownKeys];
			if(!SELoader.exists("mods/menuTimes.json")){ // Causes crashes if done while game is running, unknown why
				try{
					SELoader.saveContent("mods/menuTimes.json",Json.stringify([
						{
							file: "mods/title-morning.ogg or assets/music/breakfast.ogg",
							begin:6,end:10,wrapAround:false,color:"0xdd9911",bpm:160
						},
						{
							file: "mods/title-day.ogg or assets/music/freakyMenu.ogg",
							// Uses 100 because there is no 100th hour of the day, if there is than what the hell device are you using?
							wrapAround:false,end:100,begin:101,color:"0xECD77F",bpm:204 
						},
						{
							file: "mods/title-evening.ogg or assets/music/GiveaLilBitBack.ogg",
							begin:17,end:19,wrapAround:false,color:"0xdd9911",bpm:125
						},
						{
							file: "mods/title-night.ogg or assets/music/freshChillMix.ogg",
							begin:20,end:5,wrapAround:true,color:"0x113355",bpm:117
						},
					]));
				}catch(e){
					FuckState.FATAL = true;
					throw('Unable to write to "${FileSystem.absolutePath('mods/menuTimes.json')}"!' + " Common causes:\n* You didn't extract the zip\n* You don't have permission to write to the mods folder\nThis isn't an error you can ignore, as something is really wrong with your setup!\n" + e.details());
					return;
				}
			}else{
				try{
					var musicList:Array<MusicTime> = Json.parse(SELoader.getContent("mods/menuTimes.json"));
					SickMenuState.musicList = musicList;
				}catch(e){
					MusicBeatState.instance.showTempmessage("Unable to load Music Timing: " + e.message,FlxColor.RED);
				}
			}
			


		}
		// Android doesn't support importing
		#if !android
		

		if(!SELoader.exists('mods/packs/imported/readme.txt')){
			SELoader.createDirectory('mods/packs/imported');
			SELoader.createDirectory('mods/packs/imported/characters');
			SELoader.saveContent('mods/packs/imported/characters/Individual_characters_will_be_imported_here',"");
			SELoader.createDirectory('mods/packs/imported/charts');
			SELoader.saveContent('mods/packs/imported/charts/Individual_charts_will_be_imported_here',"");
			SELoader.createDirectory('mods/packs/imported/scripts');
			SELoader.saveContent('mods/packs/imported/scripts/Place_Scripts_Here',"");

			SELoader.saveContent('mods/packs/imported/readme.txt','This pack is used for imported songs and characters. The game will check for this file to make sure the imported pack exists.\nYou can empty this file if you wish but deleting it will regenerate the directory structure of this folder.\nThis pack can be used as an example of how to structure your packs if you wish.');
		}
		
		#end

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		// bg.antialiasing = true;
		// bg.setGraphicSize(Std.int(bg.width * 0.6));
		// bg.updateHitbox();
		add(bg);

		logoBl = new FlxSprite(-150, -100);
		logoBl.loadGraphic(Paths.image('logoBumpin'));
		// Paths.image('logoBumpin')
		logoBl.antialiasing = true;

		// logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		// logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		// logoBl.animation.play('bump');
		// logoBl.updateHitbox();
		// logoBl.screenCenter();
		// logoBl.color = FlxColor.BLACK;

		add(logoBl);
		titleText = new Alphabet(0, 0,"PRESS ENTER TO BEGIN",true,false);
		titleText.x = 100;
		titleText.y = FlxG.height * 0.8;
		titleText.screenCenter(X);
		// titleText.frames = Paths.getSparrowAtlas('titleEnter');
		// titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		// titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		// titleText.antialiasing = true;
		// titleText.animation.play('idle');
		// titleText.updateHitbox();
		// titleText.screenCenter(X);
		add(titleText);


		// var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('logo'));
		// logo.screenCenter();
		// logo.antialiasing = true;
		// add(logo);

		// FlxTween.tween(logoBl, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG});
		// FlxTween.tween(logo, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxTypedGroup<FlxSprite>();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "ninjamuffin99\nPhantomArcade\nkawaisprite\nevilsk8er", true);
		credTextShit.screenCenter();

		// credTextShit.alignment = CENTER;

		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = true;

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		FlxG.mouse.visible = false;


		shiftSkip = new FlxText(0,0,0,#if(discord_rpc) (SESave.data.discordDRP ? "Awaiting DRP -" : "DRP disabled -") + #end " Hold shift to go to the options menu after title screen",16);
		
		shiftSkip.y = FlxG.height - shiftSkip.height - 12;
		shiftSkip.x = 6;
		shiftSkip.scrollFactor.set();
		add(shiftSkip);
		CoolUtil.setFramerate(true);
		// CoolUtil.setUpdaterate(true);
		FlxG.sound.volume = SESave.data.masterVol;
		Main.instance.toggleFPS(SESave.data.fps);

		if(initialized)
			skipIntro();
		else{
			Assets.loadLibrary("shared").onComplete(function (_) {
				
				showHaxe();
				LoadingScreen.hide();
			});

		}
			// initialized = true;
		// credGroup.add(credTextShit);
	}
	var shiftSkip:FlxText;
	var isShift = false;
	static var technoAnni = [
			["Technoblade","never dies"],
			['SAY IT WITH ME','Not even close'],
			["thank you hypixel",'very cool'],
			["if you wish to defeat me",'train for another 100 years'],
			["all part of",'my master plan'],
			['subscribe to','technoblade'],
			['This is the second-worst thing','that has happened to these orphans']
		];
	public static var hardcodedDays(default,never):Map<Int,Map<Int,Array<Array<String>>>> = [
		0=>[
			0 => [["New Year","More Pain :)"],["Good bye",'${Date.now().getFullYear() - 1}'],["Hey look","New year"]],
			4 => [["Happy Birthday","PhantomArcade"]],
		],
		4 => [
			11 => [["Hey look","an idiot was born"],['its supers birthday?','whos that?']],
		],
		5 =>[
			-1 => [
				['trans rights','are human rights'],
				['yeah I\'m straight','straight up gay'],
				['be gay','do crime'],
				['Respect my trans homies','or im going to identify','as a fuckin problem'],
				['pride month','less goo'],
				['garlic bread','garlic bread'],
				['omg','blahaj'],
				['I put the l','in lesbian'],
				["you're talkin mad valid",'for someone in','cuddling distance'],
				['women','based'],
				['men','based'],
				['embies','based'],
				['person','based'],
				['skirt go speeen','still cis though'],
				['i want to wear a dress and makeup','still cis though'],
			],
		],
		6 => [
			1 => technoAnni,
			30 => technoAnni
		],
		7 => [
			1 => technoAnni
		],
		8 => [
			12 => [["Happy Birthday","ninjamuffin"]]
		],
		10 => [
			4 => [['funkin on a','friday night']],
			28 => technoAnni,
			30 => [["Spooky time","very spoopy"],["pumpkin pog","wait what"],["Spooky scary skeletons","send shivers down your spine"]]
		],
		11 => [
			30 => [["New Year","More Pain :)"],["Just one more day",'of ${Date.now().getFullYear()}'],["Hey look","New year"]],
		],
	];
	var forcedText:Bool = false;
	function getIntroTextShit():Array<String>
	{
		var now = Date.now();
		// SESave.data.seenText = true;
		if(hardcodedDays[now.getMonth()] != null && hardcodedDays[now.getMonth()][now.getDate()] != null){
			// SESave.data.seenText = false;
			forcedText = true;
			return FlxG.random.getObject(hardcodedDays[now.getMonth()][now.getDate()]);
		}else if(hardcodedDays[now.getMonth()] != null && hardcodedDays[now.getMonth()][-1] != null){
			// SESave.data.seenText = false;
			forcedText = true;
			return FlxG.random.getObject(hardcodedDays[now.getMonth()][-1]);
		}
		if(SESave.data.seenForcedText) SESave.data.seenForcedText = false;
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');

		return FlxG.random.getObject(firstArray).split('--');
	}

	var transitioning:Bool = false;
	var updateCheck:Bool = false;
	var skipMM:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);


		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || skipBoth;

		#if mobile
		for (touch in FlxG.touches.list) {
			if (touch.justPressed) pressedEnter = true;
		}
		#end

		#if (!FLX_NO_GAMEPAD)

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B) pressedEnter = true;
			#end
		}
		#end
		if(shiftSkip != null && isShift != FlxG.keys.pressed.SHIFT){
			isShift = FlxG.keys.pressed.SHIFT;
			shiftSkip.color = (if(FlxG.keys.pressed.SHIFT) 0x00aa00 #if discord_rpc else if(DiscordClient.canSend) 0x5865F2 #end else 0xFFFFFF);
		}
		#if !(debug)
		// This is useless in debug mode since updates aren't checked for
		if(pressedEnter && updateCheck && !skipMM){
			updateCheck = false;
			skipMM = true;
			MainMenu();
		}
		#end
		if (pressedEnter && !transitioning && skippedIntro){



			if (SESave.data.flashing){
				FlxTween.tween(titleText,{alpha:0},0.1,{type:PINGPONG,ease:FlxEase.cubeInOut});
			}

			// FlxG.camera.flash(FlxColor.WHITE, 1);
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			transitioning = true;
			// FlxG.sound.music.stop();
			// if(MainMenuState.nightly != "")MainMenuState.ver += "-" + MainMenuState.nightly;
			lime.app.Application.current.window.onDropFile.add(AnimationDebug.fileDrop);
			if(Sys.args()[0] != null && FileSystem.exists(Sys.args()[0])){
				AnimationDebug.fileDrop(Sys.args()[0]);
			}
			// haxe.Http doesn't work on android for some reason
			#if !(debug || hl)
			if (
			    #if(android) !Main.grantedPerms.contains('android.permission.INTERNET') || #end 
			    FlxG.keys.pressed.SHIFT || FlxG.keys.pressed.CONTROL || FileSystem.exists(Sys.getCwd() + "/noUpdates") || checkedUpdate || !SESave.data.updateCheck){
				#if(android)
				if(!Main.grantedPerms.contains('android.permission.INTERNET')){
					android.widget.Toast.makeText('Update check skipped due to lack of internet permissions',20);
				}
				#end
				FlxG.switchState(if(FlxG.keys.pressed.SHIFT) new OptionsMenu() else new MainMenuState());
			}else{
				new FlxTimer().start(0.5,function(_){try{updateCheck = true;}catch(e){}});

				showTempmessage("Checking for updates..",FlxColor.WHITE);
				#if (target.threaded)
				Thread.create(function(){
				#end
					// Get current version of FNFBR, Uses kade's update checker 
	
					var http = new haxe.Http("https://raw.githubusercontent.com/superpowers04/Super-Engine/" + (if(MainMenuState.nightly == "") "master" else "nightly") + "/version.downloadMe"); // It's recommended to change this if forking
					var returnedData:Array<String> = [];
					
					http.onData = function (data:String)
					{
						updateCheck = false;
						checkedUpdate = true;
						returnedData[0] = data.substring(0, data.indexOf(';'));
						returnedData[1] = data.substring(data.indexOf('-'), data.length);
						updatedVer = returnedData[0];
						OutdatedSubState.needVer = updatedVer;
						OutdatedSubState.currChanges = returnedData[1];
						if (!MainMenuState.ver.contains(updatedVer.trim()) || (MainMenuState.nightly != ""))
						{
							// trace('outdated lmao! ' + returnedData[0] + ' != ' + MainMenuState.ver);
							outdated = true;
							
						}
						if(skipMM) return;
						skipMM = true;
						MainMenu();
					}
					http.onError = function (error) {
						trace('error: $error');
						if(skipMM) return;
						skipMM = true;
						MainMenu();
					}
					
					http.request();
				#if (target.threaded)
				});
				#end
			}
			#else
				MainMenu();
			#end
			// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
		}

		if (pressedEnter && !skippedIntro  && (!forcedText || SESave.data.seenForcedText))
			skipIntro();

		super.update(elapsed);
	}
	inline function MainMenu(){
		ngSpr.graphic.destroy();
		FlxTween.tween(FlxG.camera.scroll,{y:-300},4,{ease:FlxEase.cubeOut});
		FlxG.switchState(if(FlxG.keys.pressed.SHIFT) new OptionsMenu() else new MainMenuState());
	}

	function createCoolText(textArray:Array<String>,yOffset:Int = 200)
	{
		for (i in 0...textArray.length) addMoreText(textArray[i],yOffset);
			// var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
			// money.screenCenter(X);
			// money.y += (i * 70) + 100;
			// money.scale.x = money.scale.y = 1.1;
			// FlxTween.tween(money.scale,{x:1,y:1},0.2,{ease:FlxEase.expoOut});
			// credGroup.add(money);
			// textGroup.add(money);
	
	}

	function addMoreText(text:String,yOffset:Int = 200):Alphabet
	{
		var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
		coolText.screenCenter(X);
		coolText.y += (70 * textGroup.length) + yOffset;
		coolText.bounce();
		credGroup.add(coolText);
		textGroup.add(coolText);
		return coolText;
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}
	var tweeny:FlxTween;
	var ttBounce:FlxTween;
	var cachingText:Alphabet;
	var drpcansend:Bool = false;
	var beatAmounts:Map<Int,Float> = [0=>0.05,1=>0.05,31=>0.07,32=>0.08,64=>0.12,65=>0.05,66=>0.03,67=>0.02,68=>0.005,69=>0];
	var beatIntensity:Float = 0.05;
	override function beatHit() {
		super.beatHit();
		if(beatAmounts.exists(curBeat)) beatIntensity = beatAmounts[curBeat];
		if (logoBl != null){
			
			if(tweeny != null)tweeny.cancel();
			var amount = 0.9 + beatIntensity;
			logoBl.scale.set(amount,amount);
			// FlxTween.tween(logoBl.scale,{x:1,y:1},0.1);
			tweeny = FlxTween.tween(logoBl.scale,{x:0.9,y:0.9},(60 / Conductor.bpm),{ease:FlxEase.expoOut});
			if(ttBounce != null)ttBounce.cancel();
			titleText.scale.set(0.1 + amount,0.1 + amount);
			ttBounce = FlxTween.tween(titleText.scale,{x:1,y:1},(60 / Conductor.bpm),{ease:FlxEase.expoOut});
		} 
		// logoBl.animation.play('bump');
		danceLeft = !danceLeft;

		#if discord_rpc
			if(drpcansend != DiscordClient.canSend){
				drpcansend = DiscordClient.canSend;
				shiftSkip.color = (if(FlxG.keys.pressed.SHIFT) 0x00aa00 else 0x5865F2);
				shiftSkip.x = shiftSkip.x + 10;
				FlxTween.tween(shiftSkip,{x:shiftSkip.x - 10},0.5,{ease:FlxEase.bounceInOut});
				shiftSkip.text = "DRP connected! - Hold shift to go to the options menu after title screen";
			}
		#end

		switch (curBeat)
		{
			case 0:
				deleteCoolText();
				destHaxe();
				
			// 	destHaxe();
			case 1:
				
				createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er'], 0);

				// addMoreText('ninjamuffin99').startTyping(0.015,Conductor.crochetSecs);
				// addMoreText('phantomArcade').startTyping(0.015,Conductor.crochetSecs);
				// addMoreText('kawaisprite').startTyping(0.02,Conductor.crochetSecs);
				// addMoreText('evilsk8er').startTyping(0.022,Conductor.crochetSecs);
				credTextShit.x -= 130;
			case 2:
				addMoreText('do not present');
			case 7:
				deleteCoolText();
			case 10:
				// if (Main.watermarks)  You're not more important than fucking newgrounds
				// 	createCoolText(['Kade Engine', 'by']);
				// else
					// createCoolText(['In Partnership']);
				
				deleteCoolText();
				addMoreText('not partnered with').startTyping(0,Conductor.crochetSecs * 2);
			case 11:
				// if (Main.watermarks)  You're not more important than fucking newgrounds
				// 	createCoolText(['Kade Engine', 'by']);
				// else
			case 12:
				addMoreText('Newgrounds');
				ngSpr.scale.x = ngSpr.scale.y = 1.1;
				FlxTween.tween(ngSpr.scale,{x:1,y:1},0.2);
				ngSpr.visible = true;
			case 16:
				deleteCoolText();
				credTextShit.y += 130;
				ngSpr.visible = false;



			case 18:
			// 	// createCoolText([curWacky[0]]);
				if(curWacky.length % 2 == 1){curWacky.push('');}// Hacky but fuck you
				var max = Std.int(Math.floor(curWacky.length * 0.5));
				createCoolText(curWacky.slice(0,max));
			case 20:
				var max = Std.int(Math.floor(curWacky.length * 0.5));
				createCoolText(curWacky.slice(max));
			case 24:
				deleteCoolText();
				if(forcedText) SESave.data.seenForcedText = true;
			// credTextShit.visible = false;
			// credTextShit.text = "Friday";
			// credTextShit.screenCenter();
			case 26:
				addMoreText('Friday Night Funkin\'');
			// credTextShit.visible = true;
			case 28:
				addMoreText('Super');
			// credTextShit.text += '\nNight';
			case 30:
				addMoreText('Engine'); // credTextShit.text += '\nFunkin';

			case 32:
				skipIntro();
			default:
				// if(curBeat > 17 && curBeat < (20 + (curWacky.length * 2))){
				// 	var _beat:Float = (curBeat - 17) * 0.5;
				// 	if(_beat % 1 == 0){
				// 		addMoreText(curWacky[_beat]);
				// 	}
				// }
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void {
		if (!skippedIntro)
		{
			destHaxe();
			if(!FlxG.sound.music.playing){
				FlxG.sound.music.play();
				FlxG.sound.music.fadeIn(0.1,SESave.data.instVol);
			}
			remove(ngSpr);
			destHaxe();
			FlxG.camera.flash(FlxColor.WHITE, 2);
			remove(credGroup);
			skippedIntro = true;
			FlxG.camera.scroll.x += 100;
			FlxG.camera.scroll.y += 100;
			logoBl.screenCenter();
			logoBl.y -= 100;
			if(Date.now().getHours() == 3){
				logoBl.angle = FlxG.random.int(0,360);
				logoBl.x = FlxG.random.int(-100,1280);
				logoBl.y = FlxG.random.int(-50,720);
			}
			if(Date.now().getHours() == 3){
				titleText.color=0xffff0000;
			}else if(Date.now().getMonth() == 9){
				titleText.color=0xffff8b0f;
			}

			FlxTween.tween(FlxG.camera.scroll,{x: 0,y:0},1,{ease:FlxEase.cubeOut});
		}
	}
	override function stepHit(){
		super.stepHit();
		if(Date.now().getHours() == 3 && FlxG.random.int(0,100) > 80){
			titleText.members[FlxG.random.int(0,titleText.length)].x = FlxG.random.int(-40,1280);
			titleText.members[FlxG.random.int(0,titleText.length)].y = FlxG.random.int(-40,770);
		}
	}

	// HaxeFlixel thing
	// Holy shit I've spent way too much time on this
	var _sprite:Sprite;
	var _gfx:Graphics;

	var _times:Array<Float>;
	var _colors:Array<Int>;
	var _functions:Array<Void->Void>;
	var _curPart:Int = 0;
	var _cachedBgColor:FlxColor;
	var _cachedTimestep:Bool;
	var _cachedAutoPause:Bool;
	var _timers:Array<FlxTimer>;
	var _sound:FlxSound;
	function showHaxe(){
		_times = [0.041, 0.184, 0.334, 0.495, 0.636,1];
		_colors = [0x00b922, 0xffc132, 0xf5274e, 0x3641ff, 0x04cdfb,0xFFFFFF,0xFFFFFF];
		_functions = [drawGreen, drawYellow, drawRed, drawBlue, drawLightBlue,function(){return;}];
		_sprite = new Sprite();
		FlxG.stage.addChild(_sprite);
		_gfx = _sprite.graphics;
		_sprite.filters = [new flash.filters.GlowFilter(0xFFFFFF,1,6,6,1,1)];

		// This is shit, but it caches unloaded sprites for FlxText
		var coolText:Alphabet = new Alphabet(0, 0, "_", true, false);
		coolText.screenCenter(X);
		coolText.forceFlxText = true;
		coolText.text = 'PRECACHING TEXT: ABCDEFGHIJKLMNOPQRSTUVWXYZbcfgijkmpqrstvxz1234567890~#$%&()*+:;<=>@[|]^.,\'!?/unholywader';
		coolText.bounce();
		add(cachingText = coolText);

		_sound = FlxG.sound.load(Assets.getSound("flixel/sounds/flixel." + flixel.system.FlxAssets.defaultSoundExtension,false),SESave.data.instVol - 0.2); // Put the volume down by 0.2 for safety of eardrums
		_sound.play();
		for (time in _times) new FlxTimer().start(time, _timerCallback);
	}
	function destHaxe(){
		flixel.util.FlxTimer.globalManager.clear();
		if(_sprite == null) return;
		if(_sound != null){
			_sound.pause();
			_sound.destroy();
		} 
		FlxG.stage.removeChild(_sprite);
		_sprite = null;
		_gfx = null;
		_times = null;
		_colors = null;
		_functions = null;

	}
	function _timerCallback(Timer:FlxTimer):Void
	{
		_functions[_curPart]();
		_curPart++;
		
		if(textGroup.members[1] == null) textGroup.members[0].color = _colors[_curPart]; else {textGroup.members[1].color = _colors[_curPart];textGroup.members[0].color = 0xFFFFFF;}
		
		if(_sprite.filters[0] != null) cast(_sprite.filters[0],flash.filters.GlowFilter).color = _colors[_curPart];
		if(_sprite != null){
			_sprite.x = (FlxG.width * 0.5);
			_sprite.y = (FlxG.height * 0.60) - 20 * FlxG.game.scaleY;
			_sprite.scaleX = FlxG.game.scaleX;
			_sprite.scaleY = FlxG.game.scaleY;
		}
		if (_curPart == 6){
			// Make the logo a tad bit longer, so our users fully appreciate our hard work :D
			FlxTween.tween(_sprite.filters[0],{blurX:0,blurY:0,strength:1},1.5,{ease:FlxEase.quadOut});
			FlxTween.tween(_sprite, {alpha: 0}, 3.0, {ease: FlxEase.quadOut, onComplete: __onComplete});
			FlxTween.tween(textGroup.members[0], {alpha: 0}, 3.0, {ease: FlxEase.quadOut});
			FlxTween.tween(textGroup.members[1], {alpha: 0}, 3.0, {ease: FlxEase.quadOut});
		}
	}
	function bounceText(?beatLength:Float = 0.3){
		var i = textGroup.members.length - 1;
		while (i > -1){
			textGroup.members[i].scale.x = textGroup.members[i].scale.y = 1.2;
			FlxTween.cancelTweensOf(textGroup.members[i]);
			FlxTween.tween(textGroup.members[i].scale, {x: 1,y: 1}, beatLength, {ease: FlxEase.cubeOut});
			i--;
		}
		

	}
	var skipBoth:Bool = false;
	function  __onComplete(tmr:FlxTween){
		if(_sound != null){
			_sound.pause();
			_sound.destroy();
		} 
		initialized = true;
		destHaxe();
		FlxG.sound.music.play();
		FlxG.sound.music.fadeIn(0.1,SESave.data.instVol);

		if(!isShift){
			FlxG.fullscreen = SESave.data.fullscreen;
		}
		if(isShift || FlxG.keys.pressed.ENTER || (Sys.args()[0] != null && FileSystem.exists(Sys.args()[0]))){
			skipBoth = true;
		}
		new FlxTimer().start(2, function(_){
			if(MusicBeatState.instance.curStep == 0){
				FuckState.FUCK("curStep seems to have not progressed at all.\nThis usually indicates that the game cannot play audio for whatever reason.\nRestarting should fix this.\nif you hear audio perfectly fine, you can safely ignore this and press enter","TitleState.audioCheck",false,true);
			}
		});
	}
	function drawGreen():Void
	{
		cachingText.destroy();
		_gfx.beginFill(0x00b922);
		_gfx.moveTo(0, -37);
		_gfx.lineTo(1, -37);
		_gfx.lineTo(37, 0);
		_gfx.lineTo(37, 1);
		_gfx.lineTo(1, 37);
		_gfx.lineTo(0, 37);
		_gfx.lineTo(-37, 1);
		_gfx.lineTo(-37, 0);
		_gfx.lineTo(0, -37);
		_gfx.endFill();
		createCoolText(['']);

	}

	function drawYellow():Void
	{
		_gfx.beginFill(0xffc132);
		_gfx.moveTo(-50, -50);
		_gfx.lineTo(-25, -50);
		_gfx.lineTo(0, -37);
		_gfx.lineTo(-37, 0);
		_gfx.lineTo(-50, -25);
		_gfx.lineTo(-50, -50);
		_gfx.endFill();
		createCoolText(['Powered by']);
		bounceText();

		// textGroup.members[1].color = 0x00b922;
		
	}

	function drawRed():Void
	{
		_gfx.beginFill(0xf5274e);
		_gfx.moveTo(50, -50);
		_gfx.lineTo(25, -50);
		_gfx.lineTo(1, -37);
		_gfx.lineTo(37, 0);
		_gfx.lineTo(50, -25);
		_gfx.lineTo(50, -50);
		_gfx.endFill();
		
	}

	function drawBlue():Void
	{
		_gfx.beginFill(0x3641ff);
		_gfx.moveTo(-50, 50);
		_gfx.lineTo(-25, 50);
		_gfx.lineTo(0, 37);
		_gfx.lineTo(-37, 1);
		_gfx.lineTo(-50, 25);
		_gfx.lineTo(-50, 50);
		_gfx.endFill();
		deleteCoolText();
		createCoolText(['Powered by',(FlxG.random.bool(0.1) ? 'the bane of my existance' : 'HaxeFlixel')]);
	}

	function drawLightBlue():Void
	{
		_gfx.beginFill(0x04cdfb);
		_gfx.moveTo(50, 50);
		_gfx.lineTo(25, 50);
		_gfx.lineTo(1, 37);
		_gfx.lineTo(37, 1);
		_gfx.lineTo(50, 25);
		_gfx.lineTo(50, 50);
		_gfx.endFill();
		FlxTween.tween(_sprite.filters[0],{blurX:50,blurY:50,strength:2},0.2,{ease:FlxEase.quadOut});
		bounceText();

		// addMoreText('HaxeFlixel');
	}


}



class FuckinNoDestCam extends FlxCamera{
	public override function destroy(){
		return;
	}
}