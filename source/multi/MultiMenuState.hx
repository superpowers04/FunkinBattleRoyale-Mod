package multi;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import flixel.addons.ui.FlxUIButton;
import openfl.media.Sound;
import flixel.math.FlxMath;

import Song;
import sys.io.File;
import sys.FileSystem;

import flixel.sound.FlxSound;
import Discord.DiscordClient;
import flixel.ui.FlxBar;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import se.formats.SongInfo;

using StringTools;


class MultiMenuState extends onlinemod.OfflineMenuState {
	// static var modes:Map<Int,Array<String>> = [];
	// static var nameSpaces:Array<String> = [];
	// static var songNames:Array<String> = [];
	static var songInfoArray:Array<SongInfo> = [];
	static var categories:Array<String> = [];
	static inline var CATEGORYNAME:String = "-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-CATEGORY";
	var selMode:Int = -1;
	public static var blockedFiles:Array<String> = ['events.json','picospeaker.json','dialogue-end.json','dialogue.json','_meta.json','meta.json','se-overrides.json','config.json'];
	static var lastSel:Int = 1;
	static var lastSearch:String = "";
	public static var lastSong:String = ""; 
	var beetHit:Bool = false;

	var shouldDraw:Bool = true;
	var inTween:FlxTween;
	var beatTween:FlxTween;
	var score:Int = 0;
	var interpScore:Int = 0;
	var shouldVoicesPlay:Bool = false;

	var diffText:FlxText;
	var scoreText:FlxText;
	var songProgress:FlxBar = new FlxBar();
	var songProgressParent:Alphabet;
	var songProgressText:FlxText = new FlxText(0,0,"00:00/00:00. Playing voices",12);
	var favButton:FlxUIButton;
	public static var importedSong = false;
	override function draw(){
		if(shouldDraw){
			super.draw();
		}else{
			grpSongs.members[curSelected].draw();
		}
	}
	override function beatHit(){
		if (voices != null && shouldVoicesPlay && (!voices.playing || (voices.time > FlxG.sound.music.time + 20 || voices.time < FlxG.sound.music.time - 20))){
			voices.time = FlxG.sound.music.time;
			voices.play();
		}
		if(shouldDraw && SESave.data.beatBouncing && curPlaying != ""){
			if(beatTween != null){
				beatTween.cancel();
				beatTween.destroy();
			}
			beatTween = FlxTween.tween(bg.scale.set(1.01,1.01),{x:1,y:1},Conductor.stepCrochet * 0.003);
		}
		super.beatHit();
	}
	override function findButton(){
		super.findButton();
		changeDiff();
	}
	override function switchTo(nextState:FlxState):Bool {
		FlxG.autoPause = true;
		if(voices != null){
			voices.destroy();
			voices = null;
		}
		return super.switchTo(nextState);
	}
	override function create(){try{

		retAfter = false;
		importedSong = false;
		SearchMenuState.doReset = true;
		if(scriptSubDirectory == "") scriptSubDirectory = "/multilist/";
		dataDir = "mods/charts/";
		PlayState.scripts = [];
		bgColor = 0x00661E;
		super.create();
		diffText = new FlxText(FlxG.width * 0.7, 5, 0, "", 24);
		diffText.font = CoolUtil.font;
		diffText.borderSize = 2;
		add(diffText);
		scoreText = new FlxText(FlxG.width * 0.7, 35, 0, "N/A", 24);
		scoreText.font = CoolUtil.font;
		scoreText.borderSize = 2;
		scoreText.screenCenter(X);
		add(scoreText);
		songProgress.height = 18;
		songProgress.width = 180;
		songProgress.createFilledBar(0xff000000,0xffffaaff,true,0xff000000);

		favButton = new FlxUIButton(750, 65, "Un/Fav Chart", favChart); 
		add(favButton);
		favButton.setLabelFormat(24, FlxColor.BLACK, CENTER);
		favButton.resize(250, 30);
		searchField.text = lastSearch;
		if(lastSearch != "") reloadList(true,lastSearch);

		lastSearch = "";
		curSelected = 0;
		changeSelection(lastSel);
		lastSel = 1;
		changeDiff();
		updateInfoText('Use shift to scroll faster; Shift+F10 to erase the score of the current chart. Press CTRL/Control to listen to inst/voices of song. Press again to toggle the voices. *Disables autopause while in this menu. Found ${songInfoArray.length} songs.');
	}catch(e){MainMenuState.handleError(e,'Something went wrong in create; ${e.message}\n${e.stack}');}}
	override function onFocus() {
		shouldDraw = true;
		super.onFocus();
		bg.alpha = 0;
		inTween = FlxTween.tween(bg,{alpha:1},0.7);
	}
	override function onFocusLost(){
		shouldDraw = false;
		super.onFocusLost();
		if(inTween != null){
			inTween.cancel();
			inTween.destroy();
		}
	}
	function addListing(name:String,i:Int,child:Dynamic):Alphabet{
		callInterp('addListing',[name,i]);
		if(cancelCurrentFunction) return null;
		var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, name, true, false);
		controlLabel.yOffset = 20;
		controlLabel.cutOff = 25;
		controlLabel.isMenuItem = true;
		controlLabel.targetY = i;
		controlLabel.menuValue = child;
		if (i != 0) controlLabel.alpha = 0.6;
		grpSongs.add(controlLabel);
		callInterp('addListingAfter',[controlLabel,name,i]);
		return controlLabel;
	}
	function favChart(){
		var songInfo = grpSongs.members[curSelected].menuValue;
		if(songInfo == null) return showTempmessage('This is not a song!',FlxColor.RED);
		if(!SESave.data.favourites.remove(songInfo)){
			SESave.data.favourites.push(songInfo);
		}
		SEFlxSaveWrapper.save();
		reloadList(false,'');
		reloadList(true,searchField.text);
	}
	function addCategory(name:String,i:Int,addToCats:Bool = true):Alphabet{
		callInterp('addCategory',[name,i]);
		if(cancelCurrentFunction) return null;
		var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, name, true, false,true);
		controlLabel.adjustAlpha = false;
		controlLabel.x = 20;
		if(controlLabel.border != null) {
			controlLabel.border.alpha = 0.35;
			controlLabel.border.lockGraphicSize((Std.int(FlxG.width) + 20),Std.int(controlLabel.border.height));
			controlLabel.border.x -= 20;
		}
		controlLabel.yOffset = 20;
		controlLabel.isMenuItem = true;
		controlLabel.targetY = i;
		controlLabel.alpha = 1;
		grpSongs.add(controlLabel);
		if(addToCats) categories.push(name);
		callInterp('addCategoryAfter',[controlLabel,name,i]);
		return controlLabel;
	}
	@:keep inline static public function isValidFile(file) {return ((StringTools.endsWith(file, '.json') || StringTools.endsWith(file, '.sm')) && !blockedFiles.contains(file.toLowerCase()));}
	@:keep inline function addSong(path:String,name:String,catID:Int = 0):SongInfo{
		if(!SELoader.exists(path) || !SELoader.isDirectory(path)){
			trace('$path doesnt exist!');
			return null;
		}
		var songInfo:SongInfo = {
			name:name,
			charts:[],
			namespace:null,
			path:path + '/',
			categoryID:catID
		};
		for (file in orderList(SELoader.readDirectory(path))) {
			if (!isValidFile(file)) continue;
			songInfo.charts.push(file);
		}

		return songInfo;
	}
	inline function reloadListFromMemory(search:String = "",query){
		var _goToSong = 0;
		var i:Int = 0;
		var emptyCats:Array<String> = [];
		var currentCat = "";
		var currentCatID:Int = -1;
		var hadSong = false;
		var matchedCat = false;
		for(song in songInfoArray){
			if(currentCatID != song.categoryID){
				if(!hadSong) emptyCats.push(currentCat);
				hadSong = false;
				currentCatID = song.categoryID;
				currentCat = categories[currentCatID] ?? "Unknown";
				matchedCat = search == "" || (currentCat != "Unknown" && query.match(currentCat.toLowerCase()));
			}
			if(!matchedCat && !query.match(song.name.toLowerCase())) continue;
			if(!hadSong) {
				hadSong = true;
				addCategory(currentCat,i,false);
				i++;
			}
			if(_goToSong == 0) _goToSong = i;
			addListing(song.name,i,song);
			i++;


		}
		if(!hadSong) emptyCats.push(currentCat);
		while(emptyCats.length > 0){
			var e = emptyCats.shift();
			addCategory(e,i).color = FlxColor.RED;
			i++;
		}
		changeSelection(_goToSong);
	}
	override function reloadList(?reload=false,?search = ""){
		if(!allowInput) return;
		curSelected = 0;

		if(grpSongs != null) {
			CoolUtil.clearFlxGroup(grpSongs);
		}

		var query = new EReg((~/[-_ ]/g).replace(search.toLowerCase().replace('\\','\\\\'),'[-_ ]'),'i'); // Regex that allows _ and - for songs to still pop up if user puts space, game ignores - and _ when showing
		callInterp('reloadList',[reload,search,query]);

		if(!cancelCurrentFunction && songInfoArray[0] != null && ((reload && search != "") || SESave.data.cacheMultiList)){
			if(selMode == -1) {
				reloadListFromMemory(search,query);
				return;
			}
			#if (false && target.threaded)
			var loadingText = new FlxText(0,0,'Loading...',32);
			replace(grpSongs,loadingText);
			loadingText.screenCenter(XY);
			sys.thread.Thread.create(() -> {
				allowInput = false;
			#end
				reloadListFromMemory(search,query);
			#if (false && target.threaded)
				allowInput = true;
				replace(loadingText,grpSongs);
				loadingText.destroy();
			});
			#end
			return;
		}
		var i:Int = 0;
		categories = [];
		songInfoArray=[];
		callInterp('generateList',[reload,search,query]);
		if(!cancelCurrentFunction){
			var emptyCats:Array<String> = [];
			var _packCount:Int = 0;

			if(SESave.data.favourites != null && SESave.data.favourites.length > 0){
				var containsSong = false;
				var missingSongs:Array<SongInfo> = [];
				_packCount++;
				for (song in SESave.data.favourites){
					if(!SELoader.exists(song.path)){
						missingSongs.push(song);
						continue;
					}
					if(search != "" && !query.match(song.name.toLowerCase())) continue;
					if(!containsSong){
						containsSong = true;
						addCategory('Favourites',i,false);
						i++;
					}
					addListing(song.name,i,song);
					// songInfoArray.push(song);
					i++;
				}
				for (song in missingSongs){SESave.data.favourites.remove(song);}
			}
			if (SELoader.exists(dataDir)){
				var dirs = orderList(SELoader.readDirectory(dataDir));
				var catID = 0;
				var containsSong = false;
				LoadingScreen.loadingText = 'Scanning mods/charts';
				_packCount++;
				for (directory in dirs){
					if (!SELoader.isDirectory('${dataDir}${directory}') || (search != "" && !query.match(directory.toLowerCase()))) continue; // Handles searching
					var song = addSong('${dataDir}${directory}',directory,catID);
					if(song == null) continue;
					if(!containsSong){
						containsSong = true;
						addCategory('Charts Folder',i);
						
						i++;
					}
					addListing(directory,i,song);
					songInfoArray.push(song);
					i++;
				}
				if(!containsSong){
					emptyCats.push('Charts Folder');
				}
			}
			if (SELoader.exists("mods/weeks")){
				for (name in orderList(SELoader.readDirectory("mods/weeks"))){
					var catID = categories.length;

					var dataDir = "mods/weeks/" + name + "/charts/";
					if(!SELoader.exists(dataDir)){continue;}
					var catMatch = query.match(name.toLowerCase());
					var dirs = orderList(SELoader.readDirectory(dataDir));
					// addCategory(name + "(Week)",i);
					_packCount++;
					var containsSong = false;
					LoadingScreen.loadingText = 'Scanning mods/weeks/$name';
					for (directory in dirs){
						if (!SELoader.isDirectory('${dataDir}${directory}') && (!catMatch && search != "" && !query.match(directory.toLowerCase()))) continue; // Handles searching
						if (SELoader.exists('${dataDir}${directory}/Inst.ogg')){
							var song = addSong('${dataDir}${directory}',directory,catID);
							if(song == null) continue;
							song.namespace = name;
							if(!containsSong){
								containsSong = true;
								addCategory(name,i);
								i++;
							}
							addListing(directory,i,song);
							songInfoArray.push(song);
							
							i++;
						}
					}
					if(!containsSong){
						emptyCats.push(name + "(Week)");
					}
				}
			}
			if (SELoader.exists("mods/packs")){
				for (name in orderList(SELoader.readDirectory("mods/packs"))){
					// dataDir = "mods/packs/" + dataDir + "/charts/";
					var catMatch = query.match(name.toLowerCase());
					// var dataDir = SELoader.anyExists(['${baseDir}charts/','${baseDir}data/']);
					// !SELoader.exists(dataDir) && !SELoader.exists(dataDir = "mods/packs/" + name + "/data/")
					// if(dataDir == null) continue;
					_packCount++;
					if(!catMatch){
						emptyCats.push(name);
						continue;
					}
					var catID = categories.length;
					// var containsSong = false;
					// var dirs = orderList(SELoader.readDirectory(dataDir));
					
					var baseDir = 'mods/packs/$name/';
					var folderSongs:Array<SongInfo> = SELoader.getSongsFromFolder(baseDir);
					if(folderSongs.length == 0){
						emptyCats.push(name);
						continue;
					}
					addCategory(name,i);
					i++;
					for (song in folderSongs){

						song.categoryID=catID;
						song.namespace=name;
						addListing(song.name,i,song);
						songInfoArray.push(song);
						i++;
					}
					
				}
			}
			while(emptyCats.length > 0){
				var e = emptyCats.shift();
				if(e != null && e != "") addCategory(e,i).color = FlxColor.RED;
				i++;
			}
		}
		if(reload && lastSel == 1){
			for(index => value in grpSongs.members){
				if(value.menuValue is SongInfo){
					changeSelection(i);
					break;
				}
			}
		}
		// if(_packCount == 0){
		// 	addCategory("No packs or weeks to show",i);
		// 	grpSongs.members[i - 1].color = FlxColor.RED;
		// }
		// if(reload && lastSel == 1) changeSelection(_goToSong);
		SELoader.gc();
		updateInfoText('Use shift to scroll faster; Shift+F7 to erase the score of the current chart. Press CTRL/Control to listen to instrumental/voices of song. Press again to toggle the voices. *Disables autopause while listening to a song in this menu. Found ${songInfoArray.length} songs');

	}

	public static function loadScriptsFromSongPath(selSong:String){
		LoadingScreen.loadingText = "Finding scripts";
		if(selSong.contains("mods/packs") || selSong.contains("mods/weeks")){
			var packDirL = selSong.split("/"); // Holy shit this is shit but using substr won't work for some reason :<

			if(packDirL[packDirL.length] == "")packDirL.pop(); // There might be an extra slash at the end, remove it
			packDirL.pop();
			if(packDirL.contains('packs')) 
				while(packDirL[packDirL.length - 2] != null && packDirL[packDirL.length - 2] != 'packs' )packDirL.pop(); 

			// Packs have a sub charts folder, weeks do not
			
			var packDir = packDirL.join("/");
			if(SELoader.isDirectory('${packDir}/scripts')){
				for (file in SELoader.readDirectory('${packDir}/scripts')) {
					if((file.endsWith(".hscript") || file.endsWith(".hx") #if(linc_luajit) || file.endsWith(".lua") #end ) && !SELoader.isDirectory('${packDir}/scripts/$file')){
						PlayState.scripts.push('${packDir}/scripts/$file');
					}
				}
			}
		}
	}
	/*TODO: REMOVE ALL INSTANCES OF SONGNAME*/
	public static function gotoSong(?selSong:String = "",?songJSON:String = "",?songName:String = "",?charting:Bool = false,?blankFile:Bool = false,?voicesFile:String="",?instFile:String=""){
		try{
			if(selSong == "" || songJSON == ""){
				throw("No song name provided!");
			}
			#if windows
			selSong = selSong.replace("\\","/"); // Who decided this was a good idea?
			#end
			LoadingScreen.loadingText = "Setting up variables";
			var chartFile = onlinemod.OfflinePlayState.chartFile = '${selSong}/${songJSON}';
			PlayState.isStoryMode = false;
			// Set difficulty
			PlayState.songDiff = songJSON;
			PlayState.storyDifficulty = (songJSON.endsWith('-easy.json') ? 0 : (songJSON.endsWith('easy.json') ? 2 : 1));
			PlayState.actualSongName = songJSON;
			onlinemod.OfflinePlayState.voicesFile = '';
			PlayState.hsBrToolsPath = selSong;
			PlayState.scripts = [];

			onlinemod.OfflinePlayState.instFile = (instFile != "" ? instFile 
				: (FileSystem.exists('${chartFile}-Inst.ogg') ? '${chartFile}-Inst.ogg' 
				: '${selSong}/Inst.ogg'));
			onlinemod.OfflinePlayState.voicesFile = (voicesFile != "" ? voicesFile 
				: (FileSystem.exists('${chartFile}-Voices.ogg') ? '${chartFile}-Voices.ogg' 
				: (FileSystem.exists('${selSong}/Voices.ogg') ? '${selSong}/Voices.ogg'
				: '')));
			loadScriptsFromSongPath(selSong);
			// if (FileSystem.exists('${selSong}/script.hscript')) {
			// 	trace("Song has script!");
			// 	MultiPlayState.scriptLoc = '${selSong}/script.hscript';
				
			// }else {MultiPlayState.scriptLoc = "";PlayState.songScript = "";}
			LoadingScreen.loadingText = "Creating PlayState";

			PlayState.nameSpace = selSong;
			PlayState.stateType = 4;
			FlxG.sound.music.fadeOut(0.4);
			LoadingScreen.loadAndSwitchState(new MultiPlayState(charting));
		}catch(e){MainMenuState.handleError(e,'Error while loading chart ${e.message}');}
	}

	function selSong(sel:Int = 0,charting:Bool = false){
		if (grpSongs.members[sel].menuValue == null){ // Actually check if the song is a song, if not then error
			SELoader.playSound("assets/sounds/cancelMenu.ogg");
			showTempmessage("Invalid song!",FlxColor.RED);
			return;
		}
		var songInfo:SongInfo = cast grpSongs.members[sel].menuValue;
		onlinemod.OfflinePlayState.nameSpace = "";
		if(songInfo.namespace != null){
			onlinemod.OfflinePlayState.nameSpace = songInfo.namespace;
			trace('Using namespace ${onlinemod.OfflinePlayState.nameSpace}');
		}
		var songLoc = songInfo.path;
		if(charting){

			
			var chart = songInfo.charts[selMode];
			var songName = songInfo.name;
			if(chart == null){
				onlinemod.OfflinePlayState.chartFile = '${songLoc}/${chart = '$songName.json'}';
				trace('New chart! ${onlinemod.OfflinePlayState.chartFile}  $chart');
				var song = (PlayState.SONG = Song.parseJSONshit("",true));
				song.song = songName;
				try{
					SELoader.saveContent(onlinemod.OfflinePlayState.chartFile,Json.stringify({song:song}));
				}catch(e){trace('Unable to save chart:$e');} // The player will be manually saving this later, this doesn't need to succeed
			}else{
				onlinemod.OfflinePlayState.chartFile = '${songLoc}/${chart}';
				PlayState.SONG = Song.parseJSONshit(SELoader.loadText(onlinemod.OfflinePlayState.chartFile),true);
			}
			trace('Loading $songName  $chart');
			loadScriptsFromSongPath(songLoc);
			onlinemod.OfflinePlayState.voicesFile = (songInfo.voices ?? (SELoader.exists('${songLoc}/Voices.ogg') ? '${songLoc}/Voices.ogg' : ""));
			PlayState.hsBrTools = new HSBrTools('${songLoc}');
			onlinemod.OfflinePlayState.instFile = (songInfo.inst ?? '${songLoc}/Inst.ogg');
			if(SELoader.exists(onlinemod.OfflinePlayState.chartFile + "-Inst.ogg")){
				onlinemod.OfflinePlayState.instFile = onlinemod.OfflinePlayState.chartFile + "-Inst.ogg";
			}
			if(SELoader.exists(onlinemod.OfflinePlayState.chartFile + "-Voices.ogg")){
				onlinemod.OfflinePlayState.voicesFile = onlinemod.OfflinePlayState.chartFile + "-Voices.ogg";
			}
			PlayState.stateType = 4;
			PlayState.SONG.needsVoices = onlinemod.OfflinePlayState.voicesFile != "";
			ChartingState.gotoCharter();
			// LoadingState.loadAndSwitchState(new charting.ForeverChartEditor());
			return;
		}
		if (songInfo.charts[selMode] == "No charts for this song!"){ // Actually check if the song has no charts when loading, if so then error
			SELoader.playSound("assets/sounds/cancelMenu.ogg");
			showTempmessage("Invalid song!",FlxColor.RED);
			return;
		}
		loadScriptsFromSongPath(songLoc);

		lastSel = sel;
		lastSearch = searchField.text;
		lastSong = songInfo.path + songInfo.charts[selMode] + songInfo.name;
		{
			var diffList:Array<String> = PlayState.songDifficulties = [];
			for(i => v in songInfo.charts){
				diffList.push(songInfo.path + "/" + v);
			}
		}
		gotoSong(SELoader.getPath(songInfo.path),songInfo.charts[selMode],songInfo.name,songInfo.voices,songInfo.inst);
	}

	override function select(sel:Int = 0){
		try{
			selSong(sel,false);

		}catch(e){
			trace(e);
			MainMenuState.handleError('Unable to load song ${e.message}');
		}
	}

	var curPlaying = "";
	var voices:FlxSound;
	var playCount:Int = 0;
	var curVol:Float = 2;
	var SCORETXT:String = "";

	override function update(e){

		super.update(e);
		// if(interpScore != score){
		// 	if(score == 0){
		// 		scoreText.text = 'N/A';
		// 		scoreText.screenCenter(X);

		// 	}else{

		// 		if((score - interpScore) < 10){
		// 			interpScore = score;
		// 		}else{
		// 			interpScore = Std.int(FlxMath.lerp(interpScore,score,0.4));
		// 		}
		// 		scoreText.text = '${interpScore}${SCORETXT}';
		// 		scoreText.screenCenter(X);
		// 	}
		// }
		// // Fucking flixel
		if(curVol != FlxG.sound.volume){ // Don't change volume unless volume changes
			try{
				curVol = FlxG.sound.volume;
				FlxG.sound.music.volume = SESave.data.instVol;

				if(voices != null) voices.volume = SESave.data.voicesVol;
			}catch(ignored){}
		}
	}

	override function handleInput(){
		if (controls.BACK || FlxG.keys.justPressed.ESCAPE) {ret();return;}

		if(songInfoArray.length == 0 || !allowInput) return;
		if (controls.UP_P && FlxG.keys.pressed.SHIFT){changeSelection(-5);} 
		else if (controls.UP_P || (controls.UP && grpSongs.members[curSelected].y > FlxG.height * 0.46 && grpSongs.members[curSelected].y < FlxG.height * 0.50) ){changeSelection(-1);}
		if (controls.DOWN_P && FlxG.keys.pressed.SHIFT){changeSelection(5);} 
		else if (controls.DOWN_P || (controls.DOWN  && grpSongs.members[curSelected].y > FlxG.height * 0.50 && grpSongs.members[curSelected].y < FlxG.height * 0.56) ){changeSelection(1);}
		handleScroll();
		extraKeys();
		if (controls.ACCEPT) select(curSelected);
	}
	var listeningTime:Float = 0;
	override function extraKeys(){
		if(controls.LEFT_P){changeDiff(-1);}
		if(controls.RIGHT_P){changeDiff(1);}
		if (FlxG.keys.justPressed.SEVEN && SESave.data.animDebug){
			selSong(curSelected,true);
		}
		if((FlxG.mouse.justPressed || FlxG.mouse.justPressedRight)){
			if(FlxG.mouse.screenY < 35 && FlxG.mouse.screenX < 1115){
				changeDiff(if(FlxG.mouse.screenX > 640) 1 else -1);
			}
			else if(!FlxG.mouse.overlaps(blackBorder)){
				var curSel= grpSongs.members[curSelected];
				if(FlxG.mouse.y < curSel.y-20){
					changeSelection(-1);
				}else if(FlxG.mouse.y > curSel.y+60){
					changeSelection(1);
				}else if((FlxG.mouse.y > curSel.y-10 && FlxG.mouse.y < curSel.y+50)  || FlxG.mouse.overlaps(curSel)){
					selSong(curSelected,FlxG.mouse.justPressedRight);
					if(retAfter) ret();
				}
			}
		}
		if(FlxG.mouse.justPressedMiddle) changeDiff(1);
		if(FlxG.mouse.wheel != 0) changeSelection(Std.int(-FlxG.mouse.wheel));
		if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.F7){
			Highscore.setScore(curScoreName,0,['N/A']);
			changeDiff();
		}
		if(FlxG.keys.justPressed.CONTROL){
			FlxG.autoPause = false;
			playCount++;
			allowInput = false;
			curVol = 2; // Resync audio volume
			var songInfo:SongInfo = grpSongs.members[curSelected]?.menuValue;
			if(songInfo == null) {
				curPlaying = "";
				SickMenuState.musicHandle();
				curPlaying = "SEMENUMUSIC";
				if(voices != null){
					voices.stop();
					voices.destroy();
				}
				allowInput = true;
				SELoader.gc();
			}else{
				#if (target.threaded)
				sys.thread.Thread.create(() -> {
				#end
					if(curPlaying != songInfo.name){
						if(songProgressParent != null){
							try{
								songProgressParent.remove(songProgress);
								songProgressParent.remove(songProgressText);
							}catch(e){}
						}
						FlxG.sound.music.fadeOut(0.4);

						curPlaying = songInfo.name;
						if(voices != null){
							voices.stop();
							voices.destroy();
						}
						voices = null;

						try{
							FlxG.sound.playMusic(SELoader.loadSound(songInfo.inst),SESave.data.instVol,true);
						}catch(e){
							showTempmessage('Unable to play instrumental! ${e.message}',FlxColor.RED);
						}
						if (FlxG.sound.music.playing){

							if(songInfo.charts[selMode] != null && SELoader.exists(songInfo.path + "/" + songInfo.charts[selMode])){
								try{

									var song:SwagSong = cast Json.parse(SELoader.getContent(songInfo.path + "/" + songInfo.charts[selMode])).song;
									// if(e.bpm > 0) Conductor.changeBPM(e.bpm);
									if(song.bpm > 0) Conductor.changeBPM(song.bpm);
									try{
										Conductor.mapBPMChanges(song);
									}catch(e){}
								}catch(e){
									showTempmessage("Unable to get BPM from chart automatically. BPM will be out of sync",0xee0011);
								}
								FlxG.sound.music.pause();
							}
							try{
								songProgressParent = grpSongs.members[curSelected];
								songProgressParent.add(songProgress);
								songProgressParent.add(songProgressText);
								songProgress.revive();
								songProgressText.revive();
								songProgress.setParent(FlxG.sound.music,'time');
								songProgress.setRange(0,FlxG.sound.music.length);
								try{FlxTween.cancelTweensOf(songProgress);}catch(e){}
								try{FlxTween.cancelTweensOf(songProgressText);}catch(e){}
								songProgressText.alpha = songProgress.alpha = 0;
								songProgressText.y = songProgress.y = 0;
								songProgressText.x = (songProgress.x = songProgressParent.x + 20) ;
								songProgressText.y = (songProgress.y = songProgressParent.y + 60) - 5;
								FlxTween.tween(songProgress,{alpha:1,y:songProgress.y + 20},0.4,{ease:FlxEase.expoOut});
								FlxTween.tween(songProgressText,{alpha:1,y:songProgress.y + 20},0.4,{ease:FlxEase.expoOut});
								FlxTween.tween(songProgressText,{x:songProgress.x + songProgress.width + 10},0.7,{ease:FlxEase.expoOut});
								songProgressText.text = "Playing Inst";
							}catch(e){}

							#if discord_rpc
								if(listeningTime == 0)listeningTime = Date.now().getTime();
								DiscordClient.changePresence('Listening to a song in menus',CoolUtil.formatChartName(songInfo.name),listeningTime);
							#end
						}else{
							curPlaying = "";
							SickMenuState.musicHandle();
						}
						SELoader.gc();
					}
					if(curPlaying == songInfo.name){
						try{
							if(voices == null){
								if(SELoader.exists(songInfo.voices)){
									voices = new FlxSound();
									voices.loadEmbedded(SELoader.loadSound(songInfo.voices),true);
									voices.volume = SESave.data.voicesVol;
									voices.looped = true;
									voices.play(FlxG.sound.music.time);
									FlxG.sound.list.add(voices);
									songProgressText.text = "Playing Inst and Voices";
								}else{
									songProgressText.text = "Playing Inst. No Voices available";
								}
							}else{
								if(!voices.playing){
									songProgressText.text = "Playing Inst and Voices";
									voices.play(FlxG.sound.music.time);
									voices.volume = SESave.data.voicesVol * FlxG.sound.volume;
									voices.looped = true;
								}else{
									songProgressText.text = "Playing Inst";
									voices.stop();
								}
							}
							shouldVoicesPlay = (voices != null && voices.playing);
						}catch(e){
							showTempmessage('Unable to play voices! ${e.message}',FlxColor.RED);
						}
						if(FlxG.sound.music.fadeTween != null) FlxG.sound.music.fadeTween.destroy(); // Prevents the song from muting itself
						// FlxG.sound.music.volume = SESave.data.instVol;
						FlxG.sound.music.volume = SESave.data.instVol * FlxG.sound.volume;
				
						FlxG.sound.music.play();
					}
					
		
					curVol = 0;
					allowInput = true;
				#if (target.threaded)
				});
				#end
			}
		}
		super.extraKeys();
	}
	var twee:FlxTween;
	var curScoreName:String = "";
	function updateScore(?songInfo:SongInfo,?chart:String){
		if(songInfo == null || chart == null){
			scoreText.text = "N/A";
			SCORETXT = "N/A";
			scoreText.screenCenter(X);
			return;
		}
		var name = '${songInfo.path}-${chart}${(QuickOptionsSubState.getSetting("Inverted chart") ? "-inverted" : "")}';
		curScoreName = "";
		if(!Highscore.songScores.exists(name)){
			scoreText.text = "N/A";
			SCORETXT = "N/A";
			scoreText.screenCenter(X);
			return;
		}
		curScoreName = name;
		scoreText.text = (Highscore.songScores.getArr(curScoreName)).join(", ");
		scoreText.screenCenter(X);
			// var _Arr:Array<Dynamic> = Highscore.songScores.getArr(name);
			// if(Std.isOfType(_Arr[0],Int)){
			// 	score = _Arr.shift();
			// }else{
			// 	score = -1;
			// }
			// SCORETXT = ', ${_Arr.join(", ")}';
			// score = Highscore.getScoreUnformatted();
		
	}
	function changeDiff(change:Int = 0,?forcedInt:Int= -100){ // -100 just because it's unlikely to be used
		var songInfo = grpSongs.members[curSelected]?.menuValue;
		if (songInfo == null) {
			diffText.text = 'No song selected';
			diffText.screenCenter(X);
			updateScore();
			return;
		}
		if(twee != null)twee.cancel();
		diffText.scale.set(1.2,1.2);
		twee = FlxTween.tween(diffText.scale,{x:1,y:1},(30 / Conductor.bpm));
		var charts = songInfo.charts;
		lastSong = charts[selMode] + songInfo.name;

		if (forcedInt == -100) selMode += change; else selMode = forcedInt;
		if (selMode >= charts.length) selMode = 0;
		if (selMode < 0) selMode = charts.length - 1;
		// var e:Dynamic = TitleState.getScore(4);
		// if(e != null && e != 0) diffText.text = '< ' + e + '%(' + Ratings.getLetterRankFromAcc(e) + ') - ' + modes[curSelected][selMode] + ' >';
		// else 
		// "No charts for this song!"
		// diffText.text = (if(modes[curSelected][selMode - 1 ] != null ) '< ' else '|  ') + (if(modes[curSelected][selMode] == CATEGORYNAME) songs[curSelected] else modes[curSelected][selMode]) + (if(modes[curSelected][selMode + 1 ] != null) ' >' else '  |');
		diffText.text = (charts[selMode - 1] == null ? "|  " : "< ") + (charts[selMode] ?? "No charts for this song!") + (charts[selMode + 1] == null ? "  |" : " >");
		// diffText.centerOffsets();
		diffText.screenCenter(X);
		updateScore(songInfo,charts[selMode]);

		// diffText.x = (FlxG.width) - 20 - diffText.width;

	}

	override function changeSelection(change:Int = 0){
		var looped = 0;
		super.changeSelection(change);
		var songInfo:SongInfo = grpSongs.members[curSelected]?.menuValue;
		if(songInfo == null || !songInfo.charts.contains('${songInfo.name}.json')){
			changeDiff(0,0);
			return;
		}
		var pos = 0;
		var json = '${songInfo.name}.json';
		for(i => chart in songInfo.charts){
			var s = '${songInfo.path}-${chart}${(QuickOptionsSubState.getSetting("Inverted chart") ? "-inverted" : "")}';
			if(Highscore.songScores.exists(s)) {pos = i;break;}
			if(chart == json ) pos = i;
		}
		changeDiff(0,pos);
		// if (modes[curSelected].indexOf('${songNames[curSelected]}.json') != -1) changeDiff(0,modes[curSelected].indexOf('${songNames[curSelected]}.json')); else changeDiff(0,0);
	}
	@:keep inline public static function findFileFromAssets(path:String,name:String,file:String):String{
		if(FileSystem.exists('${path}/songs/${name}/$file')){
			return '${path}/songs/${name}/$file';
		}
		if(FileSystem.exists('${path}/music/${name}-${file}')){
			return '${path}/music/${name}-${file}';
		}
		if(FileSystem.exists('${path}/${name}/${file}')){
			return '${path}/${name}/${file}';
		}
		if(FileSystem.exists('${path}/${name}-${file}')){
			return '${path}/${name}-${file}';
		}
		if(FileSystem.exists('${path}/${file}')){
			return '${path}/${file}';
		}
		return '';
	}
	@:keep inline static function upToString(str:String,ending:String){
		return str.substr(0,str.lastIndexOf(ending) + ending.length);
	}
	@:keep inline public static function getAssetsPathFromChart(path:String,attempt:Int = 0):String{
		if(path.contains('/data/') && attempt < 1){
			return path.substr(0,path.lastIndexOf('/data/'));
		}
		if(path.contains('/assets/')  && attempt < 2){
			return upToString(path,'/assets/');
		}
		if(path.contains('/mods/')  && attempt < 3){
			return upToString(path,'/mods/');
		}
		var i = attempt - 3;
		var str = path;
		while (str.indexOf('/') > -1){
			i--;
			if(i <= 0) break;
			str = str.substr(0,str.lastIndexOf('/'));
		}
		return str;
	}
	public static function fileDrop(file:String){
		try{
			trace('Attempting to load "$file"');
			try{
				var json:FuckingSong = cast Json.parse(File.getContent(file));
				var name = json.song.song;
				if(name == null) throw("");
			}catch(e){
				trace(e);
				MainMenuState.handleError('This chart isn\'t a FNF format chart or the chart is inaccessable!(Unable to parse and grab the song name from JSON.song.song)');
				return; // why did it take me several months TO FUCKING RETURN :sob:
			}

			var voices = "";
			var inst = "";
			var dir = file.substr(0,file.lastIndexOf("/"));
			var json = file.substr(file.lastIndexOf("/") + 1);
			var name = json.substr(0,json.lastIndexOf("."));
			var chartName = "";
			var content = File.getContent(file);
			if(content != null && content != ""){
				var name:Dynamic = cast Json.parse(File.getContent(file));
				var songName:String = "";
				if(name.song != null && Std.isOfType(name.song,String)){
					songName = cast name.song;
				}else if(name.song != null && name.song.song != null && Std.isOfType(name.song.song,String)){
					songName = cast name.song.song;
				}
				chartName = songName;
			}
			var attempts = 0;
			if(FileSystem.exists('${dir}/Inst.ogg')){ 
				inst = '${dir}/Inst.ogg';
				if(FileSystem.exists('${dir}/Voices.ogg')){
					voices = '${dir}/Voices.ogg';
				}
			}
			while(inst == "" && attempts < 99){ // If this reaches 99 attempts, fucking run
				// why did it take me several months to remember to break if the inst is found :sob:
				attempts++;
				var assets = getAssetsPathFromChart(file,attempts);
				if(assets == "") break; // Nothing else to search!
				trace(assets);

				inst = findFileFromAssets(assets,name,'Inst.ogg');
				voices = findFileFromAssets(assets,name,'Voices.ogg');
				if(inst != "") break; 
				if(name.lastIndexOf("-") != -1){ // Try without the extra - part, some songs only have a hard variant
					var name = name.substr(0,name.lastIndexOf("-"));
					inst = findFileFromAssets(assets,name,'Inst.ogg');
					voices = findFileFromAssets(assets,name,'Voices.ogg');
				}
				if(inst != "") break;
				if(inst == "" && chartName != ""){ // Try using the chart name maybe?
					inst = findFileFromAssets(assets,chartName,'Inst.ogg');
					voices = findFileFromAssets(assets,chartName,'Voices.ogg');
				}
				if(inst != "") break; 
			}
			if(inst == ""){
				MainMenuState.handleError('Unable to find Inst.ogg for "$json"');
				// MusicBeatState.instance.showTempmessage('Unable to find Inst.ogg for "$json"',FlxColor.RED);
				return;
			}
			importedSong = true;
			gotoSong(dir,
					json,
					name,
					voices,
					inst
			);

		}catch(e){
			MainMenuState.handleError(e,'Unable to load dragdrop/argument song: ${e.message}');
		}
	}
	override function goOptions(){
		lastSel = curSelected;
		lastSearch = searchField.text;
		FlxG.mouse.visible = false;
		OptionsMenu.lastState = 4;
		FlxG.switchState(new OptionsMenu());
	}
	public static function findSongByName(songName:String = "",?namespace:String = ""):String{
		if(songName == "") return null;
		if(namespace == "" && songName.contains('|')){
			namespace = songName.substring(0,songName.indexOf('|'));
			songName = songName.substring(songName.indexOf('|') + 1);

		}
		var probablyHasDifficulty = songName.contains("-");
		var songNameWithoutDifficulty = (probablyHasDifficulty ? songName.substring(0,songName.lastIndexOf("-")) : "");
		var difficulty = (probablyHasDifficulty ? songName.substring(songName.lastIndexOf("-") + 1) : "");
		if(namespace != ""){
			if(SELoader.exists('mods/packs/$namespace')){
				var packDir = 'mods/packs/$namespace/charts';
				var dir = SELoader.anyExists(['$packDir/$songName/$songName.json','$packDir/$songNameWithoutDifficulty/$songName.json']);
				if(dir != null) return dir;
			}
			if(SELoader.exists('mods/weeks/$namespace')){
				var packDir = 'mods/weeks/$namespace/charts';
				var dir = SELoader.anyExists(['$packDir/$songName/$songName.json','$packDir/$songNameWithoutDifficulty/$songName.json']);
				if(dir != null) return dir;
			}
		}
		var dir = SELoader.anyExists(['mods/charts/$songName/$songName.json',
									'mods/packs/$songNameWithoutDifficulty/charts/$songName/$songName.json',
									'mods/packs/$songNameWithoutDifficulty/charts/$songNameWithoutDifficulty/$songName.json',
									'mods/packs/$songName/charts/$songName/$songName.json',
									'mods/charts/$songNameWithoutDifficulty/$songName.json']);
		if(dir != null) return dir;
		for(i in SELoader.readDirectory('mods/packs')){
			var dir = SELoader.anyExists(['mods/packs/$i/charts/$songName/$songName.json','mods/packs/$i/charts/$songNameWithoutDifficulty/$songName.json']);
			if(dir != null) return dir;
		}
		return null;
	}
	public static function playSongByName(songName:String = "",?namespace:String = ""):Bool{
		var song = findSongByName(songName,namespace);
		if(song == null)return false;
		if(!SELoader.exists(song)){
			trace('"$song" does not exist!');
			return false;
		}
		gotoSong(song.substr(0,song.lastIndexOf('/')),song.substr(song.lastIndexOf('/') + 1));
		return true;

	}
}
typedef FuckingSong = {
	var song:FSong;
}
typedef FSong = {
	var song:String;
}
