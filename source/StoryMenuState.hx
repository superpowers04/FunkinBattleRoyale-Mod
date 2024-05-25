package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween; 
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;



import sys.io.File;
import sys.FileSystem;
import multi.MultiPlayState;
import openfl.Assets;



using StringTools;

typedef WeekJSON = {
	var songs:Array<Dynamic>;
	var songList:Array<String>;
	// var difficulties:Array<String>;
	var dontLoadDialog:Bool;
	var name:String;
}
typedef WeekSong = {
	var name:String;
	// var chartFiles:Array<String>;
	var chartName:String;
	var embedded:Bool;
}


class StoryMenuState extends ScriptMusicBeatState
{
	var scoreText:FlxText;

	static var curDifficulty:Int = 1;
	public static var isVanillaWeek:Bool = true;
	public static var weekUnlocked:Array<Bool> = [true, true];
	var weekEmbedded:Array<Bool> = [true, true];

	var weekCharacters:Array<Array<String>> = [];
	// var weekDifficulties:Array<String> = [
	// 	[],
	// 	[],
	// 	[],
	// 	[],
	// 	[],
	// 	[],
	// 	[]
	// ];

	public static var weekNames:Array<String> = [];
	static public var weekDialogue:Array<Bool> = [];
	static public var weekDirectories:Array<String> = [];
	public static var weekData:Array<Array<String>> = [];
	var weekChartNames:Array<Array<String>> = [];

	var txtWeekTitle:FlxText;

	static public var curWeek:Int = 0;
	static public var curSong:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	public static var weekScore:Int = 0;
	public static var weekMisses:Int = 0;
	public static var weekSicks:Int = 0;
	public static var weekGoods:Int = 0;
	public static var weekBads:Int = 0;
	public static var weekShits:Int = 0;
	public static var weekGT:Int = 0;
	public static var weekMaxCombo:Int = 0;
	public static var weekAccuracy:Float = 0.00;
	public static var loadDialog:Bool = true;

	function resetWeeks(){
		weekEmbedded = [];
		weekCharacters = [];
		weekNames = [];
		weekData = [];
		weekDirectories = [];
		curDifficulty = 1;



	}

	function loadWeeks(){
		resetWeeks();
		var curDir:String = "Unspecified";
		try{
			var i = weekData.length;
			if (FileSystem.exists("mods/weeks/")) {
				for (directory in FileSystem.readDirectory("mods/weeks/")) {
					curDir = directory;
					if (FileSystem.exists(Sys.getCwd() + "mods/weeks/"+directory+"/config.json")) {
						var json:WeekJSON = Json.parse(SELoader.loadText("mods/weeks/"+directory+"/config.json"));
						var songList:Array<String> = [];
						var chartList:Array<String> = [];
						var si = 0;
						if(json.songs != null && json.songs[0] != null) {
							for (item in json.songs) {
								if (Std.isOfType(item,String)){
									songList[si] = item;
									chartList[si] = item;
									si++;
								}else if (item.name != null){
									songList[si] = item.name;
									chartList[si] = item.chartName;
									si++;
								}
							}
						}
						if(json.songList != null && json.songList[0] != null) {
							for (item in json.songList) {
								if (item != null && item != ""){
									songList[si] = item;
									chartList[si] = item;
									si++;
								}
							}
						}
						// var char2 = ;
						weekData[i] = songList;
						weekCharacters[i] = (if(si > 0) ['bf','bf','gf'] else ['','','']);
						weekNames[i] = if(json.name == null || json.name == "") directory else json.name;
						weekChartNames[i] = chartList;
						weekDirectories[i] = directory;
						weekDialogue[i] = (if(json.dontLoadDialog) false else true);
						weekEmbedded[i] = false;

						i++;
					}
				}
			} 
		}catch(e){
			movedBack = true;
			MainMenuState.handleError('Error with $curDir: ${e.message}');
		}
	}

	public static function swapSongs(inStoryMenu:Bool = false){
		try{

			// if(isNew){
			// 				}
			var weekName = weekNames[curWeek];
			PlayState.storyWeek = "-custom-" + weekName;
			var songJSON = "";
			var selSong = "mods/weeks/" + weekDirectories[curWeek] + "/" + PlayState.storyPlaylist[0].toLowerCase();
			var diffic = "";

			switch (curDifficulty) {
				case 0:
					diffic = 'easy';
				case 1:
					diffic = 'normal';
				case 2:
					diffic = 'hard';
			}

			if(!SELoader.exists(selSong)){

				if(SELoader.exists('mods/charts/' + PlayState.storyPlaylist[0])){
					selSong = 'mods/charts/' + PlayState.storyPlaylist[0];
				}else if(SELoader.exists('mods/charts/' + PlayState.storyPlaylist[0].toLowerCase() )){
					selSong = 'mods/charts/' + PlayState.storyPlaylist[0].toLowerCase();
				}else{
					songJSON = multi.MultiMenuState.findSongByName(PlayState.storyPlaylist[0] + "-" + diffic,weekName);
					if(songJSON == "") songJSON = multi.MultiMenuState.findSongByName(PlayState.storyPlaylist[0].toLowerCase() + "-" + diffic,weekName);
					if(songJSON == ""){
						MainMenuState.handleError("Unable to find song '" + PlayState.storyPlaylist[0] + "'!");
						return;
					}
				}

			}
			// songJSON = if(weekChartNames[curWeek][i] == null)

			if(songJSON == ""){

				var fucked = [
						PlayState.storyPlaylist[0].toLowerCase() + "-" + diffic,
						PlayState.storyPlaylist[0] + "-" + diffic,
						diffic,
						PlayState.storyPlaylist[0].toLowerCase(),
						PlayState.storyPlaylist[0]
					];
				for (i in fucked)
				{
					if(SELoader.exists('${selSong}/${i}.json')){
						songJSON = i + ".json";
						if(PlayState.storyDifficulty != 1 && i == PlayState.storyPlaylist[0].toLowerCase() || i == PlayState.storyPlaylist[0]){
							PlayState.storyDifficulty = 1;
							PlayState.customDiff = 'Normal($diffic not found)';
						}
						break;
					}
				}
			}
			// for (i in fucked) {
			// 	songJSON=;
			// }
			if(songJSON == ""){
				MainMenuState.handleError("Unable to find a valid chart for '" + PlayState.storyPlaylist[0] + "' on difficulty " + PlayState.storyDifficulty + "!",!inStoryMenu);
				return;

			}
			trace('Loading ${songJSON}');

			onlinemod.OfflinePlayState.chartFile = '${selSong}/${songJSON}';
			PlayState.actualSongName = songJSON;
			// PlayState.actualSongName = songJSON;


			onlinemod.OfflinePlayState.voicesFile = '';
			PlayState.stateType = 6;
			PlayState.isStoryMode = true;
			PlayState.hsBrTools = new HSBrTools('${selSong}');

			if (SELoader.exists('${selSong}/Voices.ogg')) onlinemod.OfflinePlayState.voicesFile = '${selSong}/Voices.ogg';
			// if (FileSystem.exists('${selSong}/script.hscript')) {
			// 	trace("Song has script!");
			// 	MultiPlayState.scriptLoc = '${selSong}/script.hscript';
			// 	// PlayState.songScript = File.getContent('${selSong}/script.hscript');
			// }else {PlayState.hsBrTools = null;MultiPlayState.scriptLoc = "";PlayState.songScript = "";}
			if (SELoader.exists('${selSong}/dialogue.txt')) {
				trace("Song has dialogue!");
				PlayState.dialogue = CoolUtil.coolFormat(SELoader.loadText('${selSong}/dialogue.txt'));
			}else {PlayState.dialogue = [];}

			if (SELoader.exists('${selSong}/enddialogue.txt')) {
				trace("Song has endDialogue!");
				PlayState.endDialogue = CoolUtil.coolFormat(SELoader.loadText('${selSong}/enddialogue.txt'));
			}else if (SELoader.exists('${selSong}/end-dialogue.txt')) {
				trace("Song has endDialogue!");
				PlayState.endDialogue = CoolUtil.coolFormat(SELoader.loadText('${selSong}/end-dialogue.txt'));
			}else {PlayState.endDialogue = [];}
			onlinemod.OfflinePlayState.instFile = '${selSong}/Inst.ogg';
			onlinemod.OfflinePlayState.nameSpace = weekNames[curWeek];
			// LoadingState.loadAndSwitchState(new MultiPlayState());
			new FlxTimer().start(1, function(tmr:FlxTimer){
				LoadingScreen.loadAndSwitchState(new MultiPlayState(), true);
			// 	// PlayState.instance.clearVariables();
			});
		}catch(e){MainMenuState.handleError(e,"Error switching songs for week " + '${weekNames[curWeek]}',!inStoryMenu);
		}
	}

	override function create()
	{
		PlayState.endDialogue = PlayState.dialogue = [];
		loadWeeks();
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		weekSicks = 0;
		weekBads = 0;
		weekShits = 0;
		weekGoods = 0;
		weekMisses = 0;
		weekGT = 0;
		weekMaxCombo = 0;


		persistentUpdate = persistentDraw = true;

		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat(CoolUtil.font, 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat(CoolUtil.font, 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(CoolUtil.font, 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		// yellowBG = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, 0xFFFFFFFF);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);
		SickMenuState.musicHandle(null,true);
		// _bgCol = yellowBG.color;

		// var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		// add(blackBarThingie);

		// grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		// grpLocks = new FlxTypedGroup<FlxSprite>();
		// add(grpLocks);

		if(weekData.length < 1){
			MainMenuState.handleError("You have no weeks installed!");
			return;
		}
		for (i in 0...weekData.length)
		{
			var weekThing:MenuItem = new MenuItem(0, 0,i,weekNames[i]);
			weekThing.screenCenter(XY);
			weekThing.y += ((weekThing.height + 20) * i);
			weekThing.targetY = i;
			grpWeekText.add(weekThing);

			weekThing.screenCenter(X);
			weekThing.antialiasing = true;
			// weekThing.updateHitbox();

			// Needs an offset thingie
			// if (!weekUnlocked[i])
			// {
			// 	var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
			// 	lock.frames = ui_tex;
			// 	lock.animation.addByPrefix('lock', 'lock');
			// 	lock.animation.play('lock');
			// 	lock.ID = i;
			// 	lock.antialiasing = true;
			// 	grpLocks.add(lock);
			// }
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		leftArrow = new FlxSprite(1160, grpWeekText.members[0].y + 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		sprDifficulty = new FlxSprite(leftArrow.x + 130, leftArrow.y);
		sprDifficulty.frames = ui_tex;
		sprDifficulty.animation.addByPrefix('easy', 'EASY');
		sprDifficulty.animation.addByPrefix('normal', 'NORMAL');
		sprDifficulty.animation.addByPrefix('hard', 'HARD');
		sprDifficulty.animation.play('easy');
		

		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(sprDifficulty.x + sprDifficulty.width + 50, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);
		// difficultySelectors.x = grpWeekText.members[curWeek].x + grpWeekText.members[curWeek].width;


		txtTracklist = new FlxText(FlxG.width * 0.05, 100, 0, "Tracks", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = rankText.font;
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		// add(rankText);
		add(scoreText);
		add(txtWeekTitle);

		// updateText();

		changeWeek(0);
		super.create();
		changeDifficulty(0);
	}

	override function update(elapsed:Float)
	{
		// scoreText.setFormat('VCR OSD Mono', 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, elapsed));
		{

			var grp = grpWeekText.members[curWeek];
			var x = Math.floor(FlxMath.lerp(leftArrow.x, grp.x + grp.width + 20, elapsed * 1.5));
			rightArrow.x = (sprDifficulty.x = (leftArrow.x = x) + 130) + sprDifficulty.width + 50;
		}

		scoreText.text = "WEEK SCORE:" + lerpScore;

		// txtWeekTitle.text = weekNames[curWeek].toUpperCase();
		// txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		// FlxG.watch.addQuick('font', scoreText.font);

		// difficultySelectors.visible = weekUnlocked[curWeek];

		// grpLocks.forEach(function(lock:FlxSprite)
		// {
		// 	lock.y = grpWeekText.members[lock.ID].y;
		// });

		if (!movedBack)
		{
			if (!selectedWeek)
			{
				if (controls.UP_P)
				{
					changeWeek(-1);
				}

				if (controls.DOWN_P)
				{
					changeWeek(1);
				}

				if (controls.RIGHT)
					rightArrow.animation.play('press')
				else
					rightArrow.animation.play('idle');

				if (controls.LEFT)
					leftArrow.animation.play('press');
				else
					leftArrow.animation.play('idle');

				if (controls.RIGHT_P)
					changeDifficulty(1);
				if (controls.LEFT_P)
					changeDifficulty(-1);
			}

			if (controls.ACCEPT)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			SELoader.playSound('assets/sounds/cancelMenu.ogg');
			movedBack = true;
			FlxG.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if(weekData[curWeek][0] == null){
			SELoader.playSound('assets/sounds/cancelMenu.ogg');
			return;
		}
		if (stopspamming) return;

		PlayState.resetScore();

		SELoader.playSound('assets/sounds/confirmMenu.ogg');

		// grpWeekText.members[curWeek].startFlashing();
		FlxTween.tween(grpWeekText.members[curWeek],{alpha:0},0.1,{type:FlxTweenType.PINGPONG});
		// grpWeekCharacters.members[1].animation.play('bfConfirm');
		stopspamming = true;

		PlayState.storyPlaylist = weekData[curWeek];
		PlayState.isStoryMode = true;
		selectedWeek = true;
		if (isVanillaWeek)
		{


			var diffic = "";

			switch (curDifficulty)
			{
				case 0:
					diffic = '-easy';
				case 2:
					diffic = '-hard';
			}

			PlayState.storyDifficulty = curDifficulty;

			PlayState.SONG = Song.parseJSONshit(SELoader.loadText('assets/data/${PlayState.storyPlaylist[0]}/${PlayState.storyPlaylist[0]}$diffic.json'));
			PlayState.storyWeek = curWeek;
			PlayState.campaignScore = 0;

			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				LoadingScreen.loadAndSwitchState(new PlayState(), true);
			});
		}else{
			PlayState.storyDifficulty = curDifficulty;
			PlayState.campaignScore = 0;
			swapSongs(true);
			// new FlxTimer().start(1, function(tmr:FlxTimer)
			// {
			// 	LoadingState.loadAndSwitchState(new MultiPlayState(), true);
			// 	// PlayState.instance.clearVariables();
			// });

		}
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		sprDifficulty.offset.x = 0;

		switch (curDifficulty)
		{
			case 0:
				sprDifficulty.animation.play('easy');
				sprDifficulty.offset.x = 20;
			case 1:
				sprDifficulty.animation.play('normal');
				sprDifficulty.offset.x = 70;
			case 2:
				sprDifficulty.animation.play('hard');
				sprDifficulty.offset.x = 20;
		}

		sprDifficulty.alpha = 0;

		// USING THESE WEIRD VALUES SO THAT IT DOESNT FLOAT UP
		sprDifficulty.y = leftArrow.y - 15;
		if(isVanillaWeek)
			intendedScore = Highscore.getWeekScore("-custom-" + weekNames[curWeek], curDifficulty);
		else
			intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);


		FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07);
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= weekData.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = weekData.length - 1;

		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			if (item.targetY == 0 && weekData[curWeek][0] != null)
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}

		SELoader.playSound('assets/sounds/scrollMenu.ogg');
		isVanillaWeek = weekEmbedded[curWeek];
		// try{

		// 	grpWeekCharacters.members[0].setCharacter(weekCharacters[curWeek][0]);
		// 	grpWeekCharacters.members[1].setCharacter(weekCharacters[curWeek][1]);
		// 	grpWeekCharacters.members[2].setCharacter(weekCharacters[curWeek][2]);
		// }catch(e){
		// 	trace(e.message);
		// 	trace(e.stack);
		// 	remove(grpWeekCharacters);
		// 	showTempmessage('Error trying to load chara display?',FlxColor.RED);
		// }
		updateText();
	}
	var _bgCol:FlxColor = 0xFFFFFF;
	function updateText()
	{

		txtTracklist.text = "Tracks\n";
		// var stringThing:Array<String> = ;

		// txtTracklist += stringThing.
		if(weekData[curWeek][0] == null){
			txtTracklist.text += "\nNo songs\nfor this\nweek";

		}else{
			for (i in weekData[curWeek])
				txtTracklist.text += "\n" + i;
		}
		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(XY);
		txtTracklist.x -= FlxG.width * 0.35;
		// txtTracklist.y += FlxG.height * 0.35;

		txtTracklist.text += "\n";
		if(weekEmbedded[curWeek])
			intendedScore = Highscore.getWeekScore("-custom-" + weekNames[curWeek], curDifficulty);
		else
			intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);

	}
}
