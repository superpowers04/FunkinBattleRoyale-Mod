package;

// class FreeplayState extends MusicBeatState{
// 	override function create(){
// 		flixel.FlxG.switchState(new multi.MultiMenuState());
// 	}
// }

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import sys.FileSystem;
import sys.io.File;

import multi.MultiPlayState;







class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;


	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	// private var iconArray:Array<HealthIcon> = [];

	override function create()
	{
		try{


		// var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));
		super.create();
		
		if (SELoader.exists("assets/data")){
			for (dir in SELoader.readDirectory("assets/data")){
				if(SELoader.exists('assets/data/${dir}/${dir}.json') && SELoader.exists('assets/songs/${dir}/Inst.ogg')){
					try{

						var song = Json.parse(SELoader.loadText('assets/data/${dir}/${dir}.json')).song;
						var head = "head";
						if (song.player2 != null){
							head = song.player2;
						}
						songs.push(new SongMetadata(dir, 0, song.player2));
						song = null;
					}catch(e){trace('Failed to load ${dir}: ${e.message}');}
				}
			}
		}
		if(songs.length < 1){
			MainMenuState.handleError("No songs found! Please use modded songs list instead!");
		}
		haxe.ds.ArraySort.sort(songs, function(a, b) {
		   if(a.songName < b.songName) return -1;
		   else if(b.songName > a.songName) return 1;
		   else return 0;
		});
		trace('Found ${songs.length} songs!');
		// for (i in 0...initSonglist.length)
		// {
		// 	var data:Array<String> = initSonglist[i].split(':');
		// 	songs.push(new SongMetadata(data[0], Std.parseInt(data[2]), data[1]));
		// }



		/* 
			if (FlxG.sound.music != null)
			{
				if (!FlxG.sound.music.playing)
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		 */

		 

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		// LOAD MUSIC

		// LOAD CHARACTERS

		var bg:FlxSprite = new FlxSprite().loadGraphic(SearchMenuState.background); 
		bg.color = 0xff4444dd;
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false, true);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			// var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			// icon.sprTracker = songText;

			// // using a FlxGroup is too much fuss!
			// iconArray.push(icon);
			// add(icon);
			var healthIcon = new HealthIcon(songs[i].songCharacter,false,"head",true);
			healthIcon.x = songText.members[songText.length - 1].x + songText.members[songText.length - 1].width + 30;
			healthIcon.y += 75;
			songText.add(healthIcon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		trace("e");
		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(CoolUtil.font, 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);


		add(scoreText);
		trace("hi");
		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		// selector = new FlxText();

		// selector.size = 40;
		// selector.text = ">";
		// add(selector);

		// var swag:Alphabet = new Alphabet(1, 0, "swag");

	}catch(e){MainMenuState.handleError(e,'Something went wrong when creating freeplaystate: ${e.message}');}
	}

	public function addSong(songName:String, weekNum:Int,?songCharacter:String = "")
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['dad'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + lerpScore;

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (controls.LEFT_P)
			changeDiff(-1);
		if (controls.RIGHT_P)
			changeDiff(1);

		if (controls.BACK)
		{
			FlxG.switchState(new MainMenuState());
		}

		if (accepted)
		{
			try{
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);

				trace(poop);

				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
				// PlayState.storyWeek = songs[curSelected].week;
				// PlayState.stateType = 0;
				trace('CUR WEEK' + PlayState.storyWeek);
			// LoadingState.loadAndSwitchState(new MultiPlayState());
				// onlinemod.OfflinePlayState.chartFile = '';
				onlinemod.OfflinePlayState.chartFile = 'assets/data/${songs[curSelected].songName}/${poop}.json';
				PlayState.isStoryMode = false;
				// Set difficulty
				PlayState.actualSongName = '${songs[curSelected].songName}';
				onlinemod.OfflinePlayState.voicesFile = '';

				if (FileSystem.exists('assets/songs/${songs[curSelected].songName}/Voices.ogg')) onlinemod.OfflinePlayState.voicesFile = 'assets/songs/${songs[curSelected].songName}/Voices.ogg';
				PlayState.hsBrTools = new HSBrTools('assets/data/${songs[curSelected].songName}/');
				onlinemod.OfflinePlayState.instFile = 'assets/songs/${songs[curSelected].songName}/Inst.ogg';
				PlayState.stateType = 0;
				FlxG.sound.music.fadeOut(0.4);
				LoadingScreen.loadAndSwitchState(new MultiPlayState());
			}catch(e){MainMenuState.handleError(e,'Error while loading chart ${e.message}');
			}
		}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		#if !switch
		// intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		#end

		switch (curDifficulty)
		{
			case 0:
				diffText.text = "EASY";
			case 1:
				diffText.text = 'NORMAL';
			case 2:
				diffText.text = "HARD";
		}
	}

	function changeSelection(change:Int = 0)
	{
		#if !switch
		// NGio.logEvent('Fresh');
		#end

		// NGio.logEvent('Fresh');
		SELoader.playSound('assets/sounds/scrollMenu');

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		// intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		// lerpScore = 0;
		#end

		// #if PRELOAD_ALL
		// FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
		// #end

		var bullShit:Int = 0;


		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}
}
// import flixel.FlxG;
// import flixel.FlxSprite;
// import flixel.FlxState;
// import flixel.group.FlxGroup.FlxTypedGroup;
// import flixel.text.FlxText;
// import flixel.util.FlxColor;
// import flixel.util.FlxStringUtil;
// import flixel.addons.ui.FlxUIButton;
// import openfl.media.Sound;
// import Song;
// import sys.io.File;
// import sys.FileSystem;
// 
// import flixel.sound.FlxSound;


// import flixel.tweens.FlxTween;

// using StringTools;

// class FreeplayState extends onlinemod.OfflineMenuState
// {
// 	var modes:Map<Int,Array<String>> = [];
// 	static var CATEGORYNAME:String = "-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-CATEGORY";
// 	var diffText:FlxText;
// 	var selMode:Int = 0;
// 	var blockedFiles:Array<String> = ['picospeaker.json','dialogue-end.json','dialogue.json','_meta.json','meta.json','config.json'];
// 	static var lastSel:Int = 1;
// 	static var lastSearch:String = "";
// 	public static var lastSong:String = ""; 
// 	var beetHit:Bool = false;

// 	var songNames:Array<String> = [];
// 	var nameSpaces:Array<String> = [];
// 	var assetSongs:Array<String> = [];
// 	var shouldDraw:Bool = true;
// 	var inTween:FlxTween;
// 	override function draw(){
// 		if(shouldDraw){
// 			super.draw();
// 		}else{
// 			grpSongs.members[curSelected].draw();
// 		}
// 	}
// 	override function beatHit(){
// 		if (voices != null && voices.playing && (voices.time > FlxG.sound.music.time + 20 || voices.time < FlxG.sound.music.time - 20))
// 		{
// 			voices.time = FlxG.sound.music.time;
// 			voices.play();
// 		}
// 		super.beatHit();
// 	}
// 	override function findButton(){
// 		super.findButton();
// 		changeDiff();
// 	}
// 	override function switchTo(nextState:FlxState):Bool{
// 		FlxG.autoPause = true;
// 		if(voices != null){
// 			voices.destroy();
// 			voices = null;

// 		}
// 		return super.switchTo(nextState);
// 	}
// 	override function create()
// 	{
// 		try{

// 		retAfter = false;
// 		SearchMenuState.doReset = true;
// 		dataDir = "assets/data";
// 		bgColor = 0x2222dE;
// 		super.create();
// 		diffText = new FlxText(FlxG.width * 0.7, 5, 0, "", 24);
// 		diffText.font = CoolUtil.font;
// 		diffText.borderSize = 2;
// 		diffText.x = (FlxG.width) - 20;
// 		// diffText.autoSize = false;
// 		// diffText.width = 200;
// 		diffText.alignment = RIGHT;
// 		add(diffText);

// 		searchField.text = lastSearch;
// 		if(lastSearch != "") reloadList(true,lastSearch);

// 		lastSearch = "";
// 		changeSelection(lastSel);
// 		lastSel = 1;
// 		changeDiff();
// 		updateInfoText('Use shift to scroll faster; Press CTRL/Control to listen to instrumental/voices of song. Press again to toggle the voices. *Disables autopause while in this menu. Found ${songs.length} songs');
// 		}catch(e){MainMenuState.lastStack = e.stack;
// 			MainMenuState.handleError('Something went wrong in create; ${e.message}');
// 		}

// 	}
// 	override function onFocus() {
// 		shouldDraw = true;
// 		super.onFocus();
// 		bg.alpha = 0;
// 		inTween = FlxTween.tween(bg,{alpha:1},0.7);
// 	}
// 	override function onFocusLost(){
// 		shouldDraw = false;
// 		super.onFocusLost();
// 		if(inTween != null){
// 			inTween.cancel();
// 			inTween.destroy();
// 		}
// 	}
// 	function addListing(name:String,i:Int,?json:String = ""){
// 		var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, name, true, false);
// 		controlLabel.yOffset = 20;
// 		controlLabel.isMenuItem = true;
// 		controlLabel.targetY = i;
// 		if (i != 0)
// 			controlLabel.alpha = 0.6;
// 		grpSongs.add(controlLabel);
// 		if(json != ""){
// 			var icon = "head";
// 			var _json = Json.parse(File.getContent('assets/data/${dir}/${dir}.json'));
// 			if(_json != null && _json.song != null && _json.song.player2 != null){
// 				icon = _json.song.player2;
// 			}
// 			var healthIcon = new HealthIcon(icon,false,"head",true);
// 			healthIcon.x = controlLabel.members[controlLabel.length].x + controlLabel.members[controlLabel.length].width + 20;
// 			healthIcon.y = controlLabel.members[controlLabel.length].y + (controlLabel.members[controlLabel.length].height * 0.5);
// 			controlLabel.add(healthIcon);
// 		}
// 	}
// 	function addCategory(name:String,i:Int){
// 		songs[i] = name;
// 		modes[i] = [CATEGORYNAME];
// 		var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, name, true, false,true);
// 		controlLabel.adjustAlpha = false;
// 		controlLabel.screenCenter(X);
// 		var blackBorder = new FlxSprite(-500,-10).makeGraphic((Std.int(FlxG.width * 2)),Std.int(controlLabel.height) + 20,FlxColor.BLACK);
// 		blackBorder.alpha = 0.35;
// 		// blackBorder.screenCenter(X);
// 		controlLabel.insert(0,blackBorder);
// 		controlLabel.yOffset = 20;
// 		controlLabel.isMenuItem = true;
// 		controlLabel.targetY = i;
// 		controlLabel.alpha = 1;
// 		grpSongs.add(controlLabel);
// 	}
// 	inline function isValidFile(file) {return (!blockedFiles.contains(file.toLowerCase()) && (StringTools.endsWith(file, '.json') || StringTools.endsWith(file, '.sm')));}
// 	override function reloadList(?reload=false,?search = ""){
// 		curSelected = 0;
// 		var _goToSong = 0;
// 		if(reload){grpSongs.clear();}

// 		songs = ["No Songs!"];
// 		songNames = ["Nothing"];
// 		modes = [0 => ["None"]];
// 		assetSongs = [];
// 		var i:Int = 0;

// 		var query = new EReg((~/[-_ ]/g).replace(search.toLowerCase(),'[-_ ]'),'i'); // Regex that allows _ and - for songs to still pop up if user puts space, game ignores - and _ when showing
// 		if (FileSystem.exists("assets/data"))
// 		{
// 			addCategory("Asset songs",i);
// 			i++;
// 			for (directory in FileSystem.readDirectory("assets/data"))
// 			{
// 				if(FileSystem.exists('assets/data/${directory}/${directory}.json') && FileSystem.exists('assets/songs/${directory}/Inst.ogg')){
// 					try{
// 						modes[i] = [];
// 						for (file in FileSystem.readDirectory(dataDir + directory))
// 						{
// 								if (isValidFile(file)){
// 									modes[i].push(file);
// 								}
// 						}
// 						if (modes[i][0] == null){ // No charts to load!
// 							modes[i][0] = "No charts for this song!";
// 						}
// 						songs[i] = dataDir + directory;
// 						songNames[i] = directory;

						
// 						addListing(directory,i,modes[i]);
// 						nameSpaces[i] = dataDir;
// 						if(_goToSong == 0)_goToSong = i;
// 						containsSong = true;
// 						i++;
// 						// var song:JustThePlayer = cast Json.parse(File.getContent('assets/data/${dir}/${dir}.json')).song;
// 						// songs.push(new SongMetadata(dir, 0, song.player2));
// 						// song = null;
// 					}catch(e){MainMenuState.lastStack = e.stack;trace('Failed to load ${dir}: ${e.message}');}
// 				}
// 			}
// 		}
// 		if (FileSystem.exists("mods/weeks"))
// 		{
// 			for (name in FileSystem.readDirectory("mods/weeks"))
// 			{

// 				var dataDir = "mods/weeks/" + name + "/charts/";
// 				if(!FileSystem.exists(dataDir)){continue;}
// 				var catMatch = query.match(name.toLowerCase());
// 				var dirs = orderList(FileSystem.readDirectory(dataDir));
// 				addCategory(name + "(Week)",i);
// 				i++;
// 				var containsSong = false;
// 				for (directory in dirs)
// 				{
// 					if ((search == "" || catMatch || query.match(directory.toLowerCase())) && FileSystem.isDirectory('${dataDir}${directory}')) // Handles searching
// 					{
// 						if (FileSystem.exists('${dataDir}${directory}/Inst.ogg') ){
// 							modes[i] = [];
// 							for (file in FileSystem.readDirectory(dataDir + directory))
// 							{
// 									if (isValidFile(file)){
// 										modes[i].push(file);
// 									}
// 							}
// 							if (modes[i][0] == null){ // No charts to load!
// 								modes[i][0] = "No charts for this song!";
// 							}
// 							songs[i] = dataDir + directory;
// 							songNames[i] = directory;

							
// 							addListing(directory,i);
// 							nameSpaces[i] = dataDir;
// 							if(_goToSong == 0)_goToSong = i;
// 							containsSong = true;
// 							i++;
// 						}
// 					}
// 				}
// 				if(!containsSong){
// 					grpSongs.members[i - 1].color = FlxColor.RED;
// 				}
// 			}
// 		}
		
// 		if(reload && lastSel == 1)changeSelection(_goToSong);
// 		updateInfoText('Use shift to scroll faster; Press CTRL/Control to listen to instrumental/voices of song. Press again to toggle the voices. *Disables autopause while listening to a song in this menu. Found ${songs.length} songs');
// 	}
// 	// function checkSong(dataDir:String,directory:String){

// 	// }

// 	// public static function grabSongInfo(songName:String):Array<String>{ // Returns empty array if song is not found or invalid
// 	// 	var ret:Array<Dynamic> = [];
// 	// 	var query = new EReg((~/[-_ ]/g).replace(songName.toLowerCase(),'[-_ ]'),'i');
// 	// 	var modes = [];
// 	// 	var dataDir = "mods/charts/";
// 	// 	// This is pretty messy, but I don't believe regex's are possible without a for loop
// 	// 	if (FileSystem.exists(dataDir))
// 	// 	{
// 	// 		var dirs = orderList(FileSystem.readDirectory(dataDir));
// 	// 		for (directory in dirs)
// 	// 			{
// 	// 				if (query.match(directory.toLowerCase())) // Handles searching
// 	// 				{
// 	// 					if (FileSystem.exists('${dataDir}${directory}/Inst.ogg') ){
// 	// 						modes = [];
// 	// 						for (file in FileSystem.readDirectory(dataDir + directory))
// 	// 						{
// 	// 								if (!blockedFiles.contains(file.toLowerCase()) && StringTools.endsWith(file, '.json')){
// 	// 									modes.push(file);
// 	// 								}
// 	// 						}
// 	// 						if (modes[0] == null){return [];}
// 	// 						ret[0] = dataDir + directory;
// 	// 						ret[1] = directory;
// 	// 						ret[2] = modes;
// 	// 						break; // Who the hell in their right mind would continue to loop
// 	// 					}
// 	// 				}
// 	// 			}
// 	// 	}
// 	// 	return ret;
// 	// }

// 	public static function gotoSong(?selSong:String = "",?songJSON:String = "",?songName:String = "",?charting:Bool = false,?blankFile:Bool = false,?voicesFile:String="",?instFile:String=""){
// 			try{
// 				if(selSong == "" || songJSON == "" || songName == ""){
// 					throw("No song name provided!");
// 				}
// 				onlinemod.OfflinePlayState.chartFile = '${selSong}/${songJSON}';
// 				PlayState.isStoryMode = false;
// 				// Set difficulty
// 				PlayState.songDiff = songJSON;
// 				PlayState.storyDifficulty = switch(songJSON){case '${songName}-easy.json': 0; case '${songName}-hard.json': 2; default: 1;};
// 				PlayState.actualSongName = songJSON;
// 				onlinemod.OfflinePlayState.voicesFile = '';
// 				PlayState.hsBrTools = new HSBrTools('${selSong}');


// 				if(instFile == "" ){
// 					if(FileSystem.exists(onlinemod.OfflinePlayState.chartFile + "-Inst.ogg")){
// 						onlinemod.OfflinePlayState.instFile = onlinemod.OfflinePlayState.chartFile + "-Inst.ogg";
// 					}else{
// 						onlinemod.OfflinePlayState.instFile = '${selSong}/Inst.ogg';
// 					}
// 				} else onlinemod.OfflinePlayState.instFile = instFile;
// 				if(voicesFile == ""){
// 					if(FileSystem.exists(onlinemod.OfflinePlayState.chartFile + "-Voices.ogg")){
// 						onlinemod.OfflinePlayState.voicesFile = onlinemod.OfflinePlayState.chartFile + "-Voices.ogg";
// 					}else if(FileSystem.exists('${selSong}/Voices.ogg')) {onlinemod.OfflinePlayState.voicesFile = '${selSong}/Voices.ogg';}
// 				}else{
// 					onlinemod.OfflinePlayState.voicesFile = voicesFile;
// 				}
// 				if (FileSystem.exists('${selSong}/script.hscript')) {
// 					trace("Song has script!");
// 					MultiPlayState.scriptLoc = '${selSong}/script.hscript';
					
// 				}else {MultiPlayState.scriptLoc = "";PlayState.songScript = "";}
// 				PlayState.stateType = 4;
// 				FlxG.sound.music.fadeOut(0.4);
// 				LoadingState.loadAndSwitchState(new MultiPlayState(charting));
// 			}catch(e){MainMenuState.lastStack = e.stack;
// 				MainMenuState.handleError('Error while loading chart ${e.message}');
// 			}
// 	}

// 	function selSong(sel:Int = 0,charting:Bool = false){
// 		if(charting && (songs[sel] != "No Songs!" && modes[curSelected][selMode] != CATEGORYNAME)){
// 			var songLoc = songs[sel];
// 			var chart = modes[sel][selMode];
// 			var songName = songNames[sel];
// 			if(modes[curSelected][selMode] == "No charts for this song!"){
// 				onlinemod.OfflinePlayState.chartFile = '${songLoc}/${songName}.json';
// 				var song = cast Song.getEmptySong();
// 				song.song = songName;
// 				File.saveContent(onlinemod.OfflinePlayState.chartFile,Json.stringify({song:song}));
				
// 				reloadList(true,searchField.text);
// 				curSelected = sel;
// 				changeSelection();
// 				selSong(sel,true);
// 				// showTempmessage('Generated blank chart for $songName');
// 				return;


// 			}else{
// 				onlinemod.OfflinePlayState.chartFile = '${songLoc}/${chart}';
// 				PlayState.SONG = Song.parseJSONshit(File.getContent(onlinemod.OfflinePlayState.chartFile),true);
// 			}
// 			if (FileSystem.exists('${songLoc}/Voices.ogg')) {onlinemod.OfflinePlayState.voicesFile = '${songLoc}/Voices.ogg';}
// 			PlayState.hsBrTools = new HSBrTools('${songLoc}');
// 			if (FileSystem.exists('${songLoc}/script.hscript')) {
// 				trace("Song has script!");
// 				MultiPlayState.scriptLoc = '${songLoc}/script.hscript';
				
// 			}else {MultiPlayState.scriptLoc = "";PlayState.songScript = "";}
// 			onlinemod.OfflinePlayState.instFile = '${songLoc}/Inst.ogg';
// 			if(FileSystem.exists(onlinemod.OfflinePlayState.chartFile + "-Inst.ogg")){
// 				onlinemod.OfflinePlayState.instFile = onlinemod.OfflinePlayState.chartFile + "-Inst.ogg";
// 			}
// 			if(FileSystem.exists(onlinemod.OfflinePlayState.chartFile + "-Voices.ogg")){
// 				onlinemod.OfflinePlayState.voicesFile = onlinemod.OfflinePlayState.chartFile + "-Voices.ogg";
// 			}
// 			PlayState.stateType = 4;
// 			PlayState.SONG.needsVoices =  onlinemod.OfflinePlayState.voicesFile != "";

// 			LoadingState.loadAndSwitchState(new ChartingState());
// 			return;
// 		}
// 		if (songs[sel] == "No Songs!" || modes[sel][selMode] == CATEGORYNAME || modes[sel][selMode] == "No charts for this song!"){ // Actually check if the song has no charts when loading, if so then error
// 			FlxG.sound.play(Paths.sound("cancelMenu"));
// 			showTempmessage("Invalid song!",FlxColor.RED);
// 			return;
// 		}
			
// 		lastSel = curSelected;
// 		lastSearch = searchField.text;
// 		lastSong = songs[sel] + modes[sel][selMode] + songNames[sel];
// 		gotoSong(songs[sel],modes[sel][selMode],songNames[sel]);
// 	}

// 	override function select(sel:Int = 0){
// 			selSong(sel,false);

// 	}	

// 	var curPlaying = "";
// 	var voices:FlxSound;
// 	var playCount:Int = 0;
// 	var curVol:Float = 1;
// 	override function update(e){
// 		super.update(e);
// 		// Fucking flixel
// 		if(voices != null && curVol != FlxG.sound.volume){ // Don't change volume unless volume changes
// 			curVol = FlxG.sound.volume;
// 			voices.volume = SESave.data.voicesVol * FlxG.sound.volume;
// 		}
// 	}
// 	override function handleInput(){
// 			if (controls.BACK || FlxG.keys.justPressed.ESCAPE)
// 			{
// 				ret();
// 			}
// 			if(songs.length == 0) return;
// 			if (controls.UP_P && FlxG.keys.pressed.SHIFT){changeSelection(-5);} 
// 			else if (controls.UP_P || (controls.UP && grpSongs.members[curSelected].y > FlxG.height * 0.46 && grpSongs.members[curSelected].y < FlxG.height * 0.50) ){changeSelection(-1);}
// 			if (controls.DOWN_P && FlxG.keys.pressed.SHIFT){changeSelection(5);} 
// 			else if (controls.DOWN_P || (controls.DOWN  && grpSongs.members[curSelected].y > FlxG.height * 0.50 && grpSongs.members[curSelected].y < FlxG.height * 0.56) ){changeSelection(1);}
// 			extraKeys();
// 			if (controls.ACCEPT && songs.length > 0)
// 			{
// 				select(curSelected);
// 			}
// 	}

// 	override function extraKeys(){
// 		if(controls.LEFT_P){changeDiff(-1);}
// 		if(controls.RIGHT_P){changeDiff(1);}
// 		if (FlxG.keys.justPressed.SEVEN && songs.length > 0 && SESave.data.animDebug)
// 		{
// 			selSong(curSelected,true);
// 		}
// 		if(!FlxG.mouse.overlaps(blackBorder) && (FlxG.mouse.justPressed || FlxG.mouse.justPressedRight)){
// 			for (i in -2 ... 2) {
// 				if(grpSongs.members[curSelected + i] != null && FlxG.mouse.overlaps(grpSongs.members[curSelected + i])){
// 					selSong(curSelected + i,FlxG.mouse.justPressedRight);
// 				}
// 			}
// 		}
// 		if(FlxG.mouse.justPressedMiddle){
// 			changeDiff(1);
// 		}
// 		if(FlxG.mouse.wheel != 0){
// 			var move = -FlxG.mouse.wheel;
// 			changeSelection(Std.int(move));
// 		}
// 		if(FlxG.keys.justPressed.CONTROL){
// 				FlxG.autoPause = false;
// 				playCount++;
// 				if(curPlaying != songs[curSelected]){
// 					curPlaying = songs[curSelected];
// 					if(voices != null){
// 						voices.stop();
// 					}
// 					voices = null;
// 					FlxG.sound.music.stop();
// 					FlxG.sound.playMusic(Sound.fromFile('${songs[curSelected]}/Inst.ogg'),SESave.data.instVol,true);
// 					if (FlxG.sound.music.playing){
// 						if(modes[curSelected][selMode] != "No charts for this song!" && FileSystem.exists(songs[curSelected] + "/" + modes[curSelected][selMode])){
// 							try{

// 								var e:SwagSong = cast Json.parse(File.getContent(songs[curSelected] + "/" + modes[curSelected][selMode])).song;
// 								if(e.bpm > 0){
// 									Conductor.changeBPM(e.bpm);
// 								}
// 							}catch(e){MainMenuState.lastStack = e.stack;
// 								showTempmessage("Unable to get BPM from chart automatically. BPM will be out of sync",0xee0011);
// 							}
// 						}

// 					}else{
// 						curPlaying = "";
// 						SickMenuState.musicHandle();
// 					}
// 				}
// 				if(curPlaying == songs[curSelected]){
// 					try{

// 						if(voices == null){
// 							voices = new FlxSound();
// 							voices.loadEmbedded(Sound.fromFile('${songs[curSelected]}/Voices.ogg'),true);
// 							voices.volume = SESave.data.voicesVol;
// 							voices.play(FlxG.sound.music.time);

// 						}else{
// 							if(!voices.playing){
// 								voices.play(FlxG.sound.music.time);
// 							}else
// 								voices.stop();
// 						}
// 					}catch(e){MainMenuState.lastStack = e.stack;
// 						showTempmessage('Unable to play voices! ${e.message}',FlxColor.RED);
// 					}
// 				}
// 				if(playCount > 2){
// 					playCount = 0;
// 					openfl.system.System.gc();
// 				}
// 			}
// 		super.extraKeys();
// 	}
// 	var twee:FlxTween;
// 	function changeDiff(change:Int = 0,?forcedInt:Int= -100){ // -100 just because it's unlikely to be used
// 		if (songs.length == 0 || songs[curSelected] == null || songs[curSelected] == "") {
// 			diffText.text = 'No song selected';
// 			return;
// 		}
// 		if(twee != null)twee.cancel();
// 		diffText.scale.set(1.2,1.2);
// 		twee = FlxTween.tween(diffText.scale,{x:1,y:1},(30 / Conductor.bpm));
// 		lastSong = modes[curSelected][selMode] + songNames[curSelected];

// 		if (forcedInt == -100) selMode += change; else selMode = forcedInt;
// 		if (selMode >= modes[curSelected].length) selMode = 0;
// 		if (selMode < 0) selMode = modes[curSelected].length - 1;
// 		// var e:Dynamic = TitleState.getScore(4);
// 		// if(e != null && e != 0) diffText.text = '< ' + e + '%(' + Ratings.getLetterRankFromAcc(e) + ') - ' + modes[curSelected][selMode] + ' >';
// 		// else 
// 		diffText.text = (if(modes[curSelected][selMode - 1 ] != null ) '< ' else '|  ') + (if(modes[curSelected][selMode] == CATEGORYNAME) songs[curSelected] else modes[curSelected][selMode]) + (if(modes[curSelected][selMode + 1 ] != null) ' >' else '  |');
// 		// diffText.centerOffsets();
// 		diffText.screenCenter(X);
// 		// diffText.x = (FlxG.width) - 20 - diffText.width;

// 	}

// 	override function changeSelection(change:Int = 0)
// 	{
// 		var looped = 0;


// 		super.changeSelection(change);
// 		if (modes[curSelected].indexOf('${songNames[curSelected]}.json') != -1) changeDiff(0,modes[curSelected].indexOf('${songNames[curSelected]}.json')); else changeDiff(0,0);

// 	}
// }


class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";

	public function new(song:String, week:Int, songCharacter:String)
	{
		this.songName = song;
		this.songCharacter = songCharacter;
	}
}