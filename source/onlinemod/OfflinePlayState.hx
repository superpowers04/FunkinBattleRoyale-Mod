package onlinemod;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSubState;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.media.Sound;
import sys.FileSystem;
import sys.io.File;
import se.ThreadedAction;
import Overlay;


import Section.SwagSection;

using StringTools;

class OfflinePlayState extends PlayState {
	public static var instanc:OfflinePlayState;
	// public var loadedVoices:FlxSound;
	public static var loadedVoices_:FlxSound;
	public var loadedVoices(get,set):FlxSound;
	public function get_loadedVoices(){
		return loadedVoices_;
	}
	public function set_loadedVoices(vari){
		return loadedVoices_ = vari;
	}
	public static var loadedInst_:Sound;
	// public var loadedInst:Sound;
	public var loadedInst(get,set):Sound;
	public function get_loadedInst(){
		return loadedInst_;
	}
	public function set_loadedInst(vari){
		return loadedInst_ = vari;
	}
	var loadingtext:FlxText;
	var shouldLoadJson:Bool = true;
	var stateType = 2;
	var shouldLoadSongs = true;
	public static var voicesFile = "";
	public static var instFile = "";
	public static var lastInstFile = "";
	public static var lastVoicesFile = "";
	public static var chartFile:String = "";
	public static var nameSpace:String = "";
	public static var stateNames:Array<String> = ["","-freep","-Offl","","-Multi","-OSU","-Story","","",""];
	var willChart:Bool = false;
	override public function new(?charting:Bool = false){
		willChart = charting;
		super();
	}

	function loadSongs(){
		LoadingScreen.loadingText = "Loading music";

		SEProfiler.qStart('Loading Music');
		if(lastVoicesFile != voicesFile && loadedVoices != null){
			loadedVoices.destroy();
		}
		#if(target.threaded)
		var voicesThread = new ThreadedAction(() -> { // Offload to another thread for faster loading
		#end
			if(loadedVoices == null || lastVoicesFile != voicesFile){
				if(voicesFile == null || voicesFile == ""){
					voicesFile = SELoader.anyExists([
							'assets/onlinedata/songs/${chartFile.substring(chartFile.lastIndexOf('/')+1,chartFile.lastIndexOf('.'))}/Voices.ogg',
							'assets/onlinedata/songs/${PlayState.songDir}/Voices.ogg',
							'assets/onlinedata/songs/${PlayState.actualSongName.toLowerCase()}/Voices.ogg',
							'assets/onlinedata/songs/${PlayState.SONG.song.toLowerCase()}/Voices.ogg'
						],"");
				}
				if(voicesFile != ""){
					try{
						loadedVoices = SELoader.loadFlxSound(voicesFile);
					}catch(e){
						trace('Unable to load voices ${e.details()}');
						loadedVoices = new FlxSound();
						PlayState.SONG.needsVoices = false;
					}
				}else if(voicesFile == "" && PlayState.SONG != null){
					loadedVoices = new FlxSound();
					PlayState.SONG.needsVoices = false;
				}
				if(loadedVoices.length < 1){
					trace('Voices.ogg didn\'t load properly. Try converting to MP3 and then into OGG Vorbis');
				}

			}
		#if(target.threaded)
		});
		#end

		if(loadedInst == null || lastInstFile != instFile){ // This doesn't need to be threaded
			try{

				if(instFile == null || instFile == ""){
					var list = [
							'assets/onlinedata/songs/${chartFile.substring(chartFile.lastIndexOf('/')+1,chartFile.lastIndexOf('.'))}/Inst.ogg',
							'assets/onlinedata/songs/${PlayState.actualSongName.toLowerCase()}/Inst.ogg',
							'assets/onlinedata/songs/${PlayState.songDir.toLowerCase()}/Inst.ogg',
							'assets/onlinedata/songs/${PlayState.SONG.song.toLowerCase()}/Inst.ogg'
						];
					instFile = SELoader.anyExists(list,"");
				}
				if (instFile == null || instFile == ""){ // why the fuck is instFile null? :sob:
					throw('${PlayState.actualSongName} is missing a inst file!');
				}
				loadedInst = SELoader.loadSound(instFile);
			}catch(e){
				return MainMenuState.handleError('Error occurred while trying to load inst:${e.details()}');
			}
		}
		#if(target.threaded)
		voicesThread.wait();
		#end
		if(loadedVoices != null)loadedVoices.time = 0;

		lastInstFile = instFile;
		lastVoicesFile = voicesFile;
		loadedVoices.persist = true;

		SEProfiler.qStamp('Loading Music');
	trace('Loading $voicesFile, $instFile');
	
  }
	override function destroy(){
		if(loadedVoices != null){loadedVoices.pause();loadedVoices.time = 0;}
		super.destroy();
	}
  function loadJSON(){
	try{

		LoadingScreen.loadingText = "Loading chart JSON";

		SEProfiler.qStart('Parsing Chart');
		if (!ChartingState.charting) {
			if(chartFile.endsWith(".sm")){
				PlayState.SONG = smTools.SMFile.loadFile(chartFile).convertToFNF();
			}else{
				PlayState.SONG = Song.parseJSONshit(SELoader.getContent(chartFile));

			}
				// if(nameSpace != ""){
				// 	if(TitleState.retChar(nameSpace + "|" + PlayState.player2) != null){
				// 		PlayState.player2 = nameSpace + "|" + PlayState.player2;
				// 	}
				// 	if(TitleState.retChar(nameSpace + "|" + PlayState.SONG.player1) != null){
				// 		PlayState.player1 = nameSpace + "|" + PlayState.player1;
				// 	}
				
				// }
		}
		SEProfiler.qStamp('Parsing Chart');
		// var e = chartFile.substr(0,chartFile.lastIndexOf('/') + "/SE-OVERRIDES.json";
		// if(FileSystem.exists(e)){
		// 	var overrides:SwagSong = 
		// }
	}catch(e) throw('Error loading chart \'${chartFile}\': ${e.message}');
  }
	override function create()
	{
	// try{
		instanc = this;
		if (shouldLoadJson) loadJSON();

		PlayState.stateType=stateType;

		if (shouldLoadSongs) loadSongs();

		var oldScripts:Bool = false;
		if(willChart){ // Loading scripts is redundant when we're just going to go into charting state
			oldScripts = QuickOptionsSubState.getSetting("Song hscripts");
			QuickOptionsSubState.setSetting("Song hscripts",false);
		}
		super.create();


		// Add XieneDev watermark
		var xieneDevWatermark:FlxText = new FlxText(-4, FlxG.height * 0.1 - 50, FlxG.width, 'SuperEngine${stateNames[stateType]}\n${MainMenuState.ver}(${MainMenuState.buildType})', 16)
			.setFormat(CoolUtil.font, 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
			xieneDevWatermark.scrollFactor.set();
			add(xieneDevWatermark);
		xieneDevWatermark.cameras = [camHUD];


		FlxG.mouse.visible = false;
		FlxG.autoPause = true;
		if(willChart){
			QuickOptionsSubState.setSetting("Song hscripts",oldScripts);
			FlxG.switchState(new ChartingState());
		}
	  // }catch(e){MainMenuState.handleError(e,'Caught "create" crash: ${e.message}');}
	}
	override function startCountdown(){
		if(shouldLoadJson) FlxG.sound.playMusic(loadedInst, 1, false);
		super.startCountdown();
	}
	  override function generateSong(?dataPath:String = ""){
		vocals = ((PlayState.SONG.needsVoices && Math.abs(loadedVoices.length - loadedInst.length) < 20000) ? loadedVoices : new FlxSound());
		super.generateSong(dataPath);

  }
  // override function generateSong(dataPath:String)
  // {try{
  //   // I have to code the entire code over so that I can remove the offset thing
  //   var songData = PlayState.SONG;
		// Conductor.changeBPM(songData.bpm);

		// curSong = songData.song;

		// if (PlayState.SONG.needsVoices)
		// 	vocals = loadedVoices;
		// else
		// 	vocals = new FlxSound();

		// FlxG.sound.list.add(vocals);

		// notes = new FlxTypedGroup<Note>();
		// add(notes);

		// var noteData:Array<SwagSection>;

		// // NEW SHIT
		// noteData = songData.notes;

		// var playerCounter:Int = 0;

		// // Per song offset check
		// var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		// for (section in noteData)
		// {
		// 	var coolSection:Int = Std.int(section.lengthInSteps / 4);

		// 	for (songNotes in section.sectionNotes)
		// 	{

		// 		if(songNotes[1] == -1) continue;
		// 		var daStrumTime:Float = songNotes[0] + SESave.data.offset;
		// 		if (daStrumTime < 0)
		// 			daStrumTime = 0;
		// 		var daNoteData:Int = songNotes[1];

		// 		var gottaHitNote:Bool = section.mustHitSection;

		// 		if (songNotes[1] > 3)
		// 		{
		// 			gottaHitNote = !section.mustHitSection;
		// 		}

		// 		var oldNote:Note;
		// 		if (unspawnNotes.length > 0)
		// 			oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
		// 		else
		// 			oldNote = null;

		// 		var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote,null,null,songNotes[3] == 1,songNotes,gottaHitNote);
		// 		swagNote.sustainLength = songNotes[2];
		// 		swagNote.scrollFactor.set(0, 0);

		// 		var susLength:Float = swagNote.sustainLength;

		// 		susLength = susLength / Conductor.stepCrochet;
		// 		unspawnNotes.push(swagNote);

		// 		for (susNote in 0...Math.floor(susLength))
		// 		{
		// 			oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

		// 			var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true,null,songNotes[3] == 1,gottaHitNote);
		// 			sustainNote.scrollFactor.set();
		// 			unspawnNotes.push(sustainNote);

		// 			sustainNote.mustPress = gottaHitNote;

		// 			if (sustainNote.mustPress)
		// 			{
		// 				sustainNote.x += FlxG.width / 2; // general offset
		// 			}
		// 		}

		// 		swagNote.mustPress = gottaHitNote;

		// 		if (swagNote.mustPress)
		// 		{
		// 			swagNote.x += FlxG.width / 2; // general offset
		// 		}
		// 	}
		// 	daBeats += 1;
		// }

		// // trace(unspawnNotes.length);
		// // playerCounter += 1;

		// unspawnNotes.sort(sortByShit);

		// generatedMusic = true;
  //  }catch(e){MainMenuState.handleError('Caught "gensong" crash: ${e.message}');}}


	override function endSong() {
		if(PlayState.isStoryMode){
			super.endSong();
		}else{

			canPause = false;
			FlxG.sound.music.onComplete = null;
			if (ChartingState.charting){FlxG.switchState(new ChartingState());return;}
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				super.openSubState(new FinishSubState(PlayState.boyfriend.getScreenPosition().x, PlayState.boyfriend.getScreenPosition().y,true));
		}
	}
	var cmdList:Array<Array<String>> = [
		["help",'Prints the normal help message'],
		["statehelp",'Prints this message'],

		['-- Utilities --'],
		["p1/player1",'Change the player1 of the chart, save it and reload it'],
		["p2/player2",'Change the player2 of the chart, save it and reload it'],
		["gf/p3/player3",'Change the gf of the chart, save it and reload it'],
		["stage",'Change the stage of the chart, save it and reload it'],
		["memberlist",'List all members by class name/id'],
	];
	override public function consoleCommand(text:String,args:Array<String>):Dynamic{
		switch(args[0]){
			case "statehelp":
				var ret = 'State specific Command list:';
				for(_ => v in cmdList){
					ret += (v[1] == null ? '\n${v[0]}' : '\n`${v[0]}` - ${v[1]}');
				}
				Console.print(ret);
			case "memberlist":
				var ret = 'Member list:';
				for(i => v in members){
					// var v:Dynamic = cast v;
					ret += ('\n$i: ${v.ID} - ${Type.typeof(v)}');
				}
				trace(ret);
			case "p1" | "p2" | "p3" | "player1" |  "player2" |  "player3" | "gf" | "stage":{
				var type = args.shift();
				switch(type){
					case "p1":PlayState.SONG.player1=args.join(" ");
					case "p2":PlayState.SONG.player2=args.join(" ");
					case "gf" | "p3":PlayState.SONG.gfVersion=args.join(" ");
					case "stage":PlayState.SONG.stage=args.join(" ");
				}
				var _song = PlayState.SONG;
				var _raw = _song.rawJSON;
				_song.rawJSON = null; // It's a good idea to not include 2 copies of the json
				var data:String = tjson.Json.stringify(_song);
				_song.rawJSON = _raw; // It's a good idea to not include 2 copies of the json
				if ((data != null) && (data.length > 0)){
					try{
						//Bodgey as hell but doesn't work otherwise
						var path = onlinemod.OfflinePlayState.chartFile;
						SELoader.importFile(path,'chartBackup.json');
						trace('Backed chart up to ${SELoader.getPath('chartBackup.json')}');
						File.saveContent(path,'{"song":' + data + "}");
						trace('Saved chart to ${path}');
					
						Console.showConsole = false;
						FlxG.resetState();


					}catch(e){trace(e);}
				}
			}
			default: return null;
		}
		return true;
	}
}


