package;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.Lib;
import Options;
import Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.addons.ui.FlxUIState;
import flixel.util.FlxTimer;

import tjson.Json;
import sys.FileSystem;
import sys.io.File;
import OptionsFileDef;
import Reflect;
using StringTools;

class OptionsMenu extends MusicBeatState
{
	public static var instance:OptionsMenu;
	public static var lastState:Int = 0;

	function goBack(){
		// if (lastState != 0){
		try{

			var ls = lastState;
			lastState = 0;
			SearchMenuState.doReset = true;
			// if(lastStateType is PlayState) 
			LoadingScreen.show();
			goToLastClass();
		}catch(e){
			FlxG.switchState(new MainMenuState());
		}
	}
	var selector:FlxText;
	var curSelected:Int = 0;
	var selCat:Int = 0;
	var transitioning:Bool = false;

	public static var modOptions:Map<String,Map<String,Dynamic>> = new Map<String,Map<String,Dynamic>>();
	public static var ScriptOptions:Map<String,OptionsFileDef> = new Map<String,OptionsFileDef>();

	var options:Array<OptionCategory> = [
		new OptionCategory("Session/Temp Options", [
			for (name => setting in QuickOptionsSubState.normalSettings)
			{
				new QuickOption(name);
			}
		],"Chart options. THESE ARE TEMPORARY AND RESET WHEN GAME IS CLOSED"),
		new OptionCategory("Modifications", [
			new OpponentOption("Change the opponent character"),
			new PlayerOption("Change the player character"),
			new GFOption("Change the GF used"),
			new NoteSelOption("Change the note assets used, pulled from mods/noteassets"),
			new SelStageOption("Select the stage to use, Default will use song default"),
			new SelScriptOption("Enable/Disable scripts that run withsongs"),

			new HCBoolOption("Use Song Stage","Whether to allow the song to choose the stage if you have them installed or force the stage you've selected",'stageAuto'),
			new HCBoolOption("Use Song Opponent Char","Whether to allow the song to choose the opponent if you have them installed or force the opponent you've selected",'charAuto'),
			new HCBoolOption("Use Song Player Char","Whether to allow the song to choose the player if you have them installed or force the player you've selected",'charAutoBF'),
			new HCBoolOption("Pack scripts","Toggle the ability for packs to provide scripts","packScripts"),
			new HCBoolOption("Menu Scripts","Toggle the ability for scripts to run in menus","menuScripts"),
			#if linc_luajit
			new HCBoolOption("Lua Scripts","Toggle lua scripts for fixing broken compatibility with some mods","luaScripts"),
			#end
			// new HCBoolOption("Show player on main menu","Show your player character on the main menu, MAY CAUSE CRASHES!","mainMenuChar"),
			
			new HCBoolOption("Content Creation/Debug Mode","Enables the Character/chart editor, F10 console, displays some extra info in the FPS Counter, and some other debug stuff","animDebug"),
			new ReloadCharlist("Refreshes list of stages, characters and scripts"),
		],"Settings relating to Characters, scripts, etc"),
		new OptionCategory("Online", [
			// new HCBoolOption("Saves charts to disk whenever you recieve one","Save charts from servers","onlineSaveChart"),
			new HCBoolOption('Allow Server Scripts',"Allow servers to run scripts. THIS IS DANGEROUS, ONLY ENABLE IF YOU TRUST THE SERVERS",'allowServerScripts'),
		],"Settings relating to Characters, scripts, etc"),
		new OptionCategory("Gameplay", [
			new DFJKOption(controls),
			new HCBoolOption("Native Touch Buttons","Toggle the built-in taps for hitting notes(Legacy input only!)","useTouch"),
			new HCBoolOption("Strum Buttons","Whether to split the screen into 4 buttons or use strums as buttons(Requires native Touch)","useStrumsAsButtons"),
			
			new HCBoolOption('Scroll Type',"Change the scroll direction between upscroll and downscroll",'downscroll','downscroll',"upscroll"),
			new HCBoolOption('Center strumline',"Move the strumline to the middle of the screen",'middleScroll'),

			new AccuracyDOption("Change how accuracy is calculated. ( Simple = Rating based, SE = Distance from note to time, Complex = Etterna(?) )"),
			// new OffsetMenu("Get a note offset based off of your inputs!"),
			new InputEngineOption("Change the input engine used, only works locally."),
			new ResetKeybindsOption("Backs up your options to SESETTINGS-BACK.json and then resets them"),
		],"Edit things like Keybinds, scroll direction, etc"),
		new OptionCategory("Judgements", [
			new AccuracyDOption("Change how accuracy is calculated. ( Simple = Rating based, SE = Distance from note to time, Complex = Etterna(?) )"),
			new Judgement("Customize your Hit Timings (LEFT or RIGHT)"),
			new SEJudgement("Sick"),
			new SEJudgement("Good"),
			new SEJudgement("Bad"),
			new SEJudgement("Shit")
		],"Edit things like Keybinds, scroll direction, etc"),
		new OptionCategory("Modifiers", [
			new HCBoolOption("Practice Mode","Disables the ability to get a gameover, You can still get a score unless you die","practiceMode"),
			new HCBoolOption("Ghost Tapping","Allow tapping a direction without receiving a miss","ghost"),
			new HCBoolOption("Jump to first note prompt","Show skip beginning prompt","skipToFirst"),
			new HCBoolOption("Debounce detection","Enables some simple debounce detection. Forces presses to be missed from one frame to another.","debounce"),
			new Judgement("Customize your Hit Timings (LEFT or RIGHT)"),
			
			new HCFloatOption('Scroll Speed',"Change your scroll speed (1 = Chart dependent)","scrollSpeed",0.1,10,0.1),
			new HCFloatOption('Scroll Speed(OSU Chart)',"Change your scroll speed OSU charts","scrollOSUSpeed",0.1,10,0.1),
		
			new HCBoolOption("Accurate Note Sustain","Whether note sustains/holds are more accurate. If off then they act like early kade","accurateNoteSustain"),
			new HCBoolOption("Shitty Misses","Whether you'll get a miss from getting a shit","shittyMiss"),
			new HCBoolOption("Bad Misses","Whether you'll get a miss from getting a bad","badMiss"),
			new HCBoolOption("Good Misses","Whether you'll get a miss from getting a good","goodMiss"),
		],"Toggle Practice mode, Ghost Tapping, etc"),

		new OptionCategory("Appearance", [ // if(!FlxG.save.data.noterating && !FlxG.save.data.showTimings && !FlxG.save.data.showCombo)
			new HCBoolOption('Distractions',"Toggle stage distractions that can hinder your gameplay(Handled by the stage, not the game)",'distractions'),
			new HCBoolOption('Camera Movement',"Toggle the camera zooming and moving to current singer",'camMovement'),
			// new NPSDisplayOption("Shows your current Notes Per Second."),
			new HCBoolOption('Show Accuracy',"Display accuracy information.",'accuracyDisplay'),
			new HCBoolOption('Show Song Position',"Show the songs current position, name and length",'songPosition'),
			new HCBoolOption('CPU Strum lighting',"Light up the corrosponding CPU strum when a note is hit",'cpuStrums',"Animated CPU Strums","Static CPU Strums"),
			new SongInfoOption("Change how your performance is displayed"),
			new GUIGapOption("Change the distance between the end of the screen and text(Not used everywhere)"),
		],"Toggle flashing lights, camera movement, song info, etc "),
		new OptionCategory("Misc", [
			#if !mobile
				new HCBoolOption('Check for Updates',"Toggle check for updates when booting the game, useful if you're in the Discord with pings off",'updateCheck'),
			#end
			#if discord_rpc
				new HCBoolOption("Discord Rich Presence","Toggle Discord Rich Presence(Requires restart)","discordDRP"),
			#end
			new FullscreenOption("Toggle fullscreen mode. Press F11 to toggle fullscreen ingame"),
			new HCBoolOption('Reset Key',"Toggle pressing R to gameover","resetButton"),	
			new HCBoolOption('Easter Eggs',"Toggle easter eggs","easterEggs"),	
			new HCBoolOption('Gameplay Logging',"Logs your song performance to a text file to 'DATE.log' and 'UNIXTIMECODE.log' in 'songLogs/CHARTFILE/'","logGameplay"),			
			#if !mobile
			// Desktop only since this is forced on android
			new HCBoolOption("Simpler Main Menu","Removes some options from the main menu for ease of use","simpleMainMenu"),
			#end
			// new HCBoolOption("Allows you to use the legacy chart editor","Lecacy chart editor","legacyCharter"),
			// new LogGameplayOption("Logs your game to a text file"),
			new EraseOption("Backs up your options to SESETTINGS-BACK.json and then resets them"),
			// new ImportOption("Import your options from SEOPTIONS.json"),
			// new ExportOption("Export your options to SEOPTIONS.json to backup or to share with a bug report"),
		],"Misc things"),
		new OptionCategory("Compatibility", [
			new HCBoolOption("Legacy hurt notes","Load legacy Tricky mod format notes","useHurtArrows"),
		],'Toggle compatibility with specific features from mods/engines'),
		new OptionCategory("Performance", [
			new FPSCapOption("Cap your Frames Per Second, This controls how fast the game will update your screen"),
			// new UPSCapOption("Cap your Updates Per Second, This controls how responsive the game is"),
			new HCBoolOption("Hurt note texture","Use custom arrow texture instead of coloring normal notes black","useBadArrowTex"),

			new HCBoolOption('Performance mode',"Disables many effects to make the game run better",'performance'),
			new HCBoolOption("Persistant BF","Doesn't destroy the Player when you exit a song. Makes loading quicker but uses more ram and might cause issues","persistBF"),
			new HCBoolOption("Persistant GF","Doesn't destroy GF when you exit a song. Makes loading quicker but uses more ram and might cause issues","persistGF"),
			// new HCBoolOption("Doesn't destroy the opponent when you exit a song. Makes loading quicker but uses more ram and might cause issues","Persistant Opponent","persistOpp"),
			// new UnloadSongOption("Unload the song when exiting the game"),
			// new MMCharOption("**CAN PUT GAME INTO CRASH LOOP! IF STUCK, HOLD SHIFT AND DISABLE THIS OPTION. Show character on main menu"),
		],"Disable some features for better performance"),
		new OptionCategory("Visibility", [
			new HCBoolOption('Force generic Font', "Force menus to use the built-in font or mods/font.ttf for easier reading(Note, some menus will break)",'useFontEverywhere'),
			new HCBoolOption('FPS Counter', "Show the FPS Counter",'fps'),
            new BackTransOption("Change underlay opacity"),new BackgroundSizeOption("Change underlay size"),
			new HCBoolOption('NPS Display', "Keeps track of and shows your current notes per second",'npsDisplay'),
			new HCBoolOption('Show Note Ratings', "Shows note ratings next to the strumline",'noterating'),
			new HCBoolOption('Show Note Timings', "Shows note timings over the strumline",'showTimings'),
			new HCBoolOption("Show Current Combo","Shows your combo next to the strumline",'showCombo'),
			new HCBoolOption("Beat Bouncing", "Toggle text bouncing, Useful if you can't read some text",'beatBouncing'),
			new HCBoolOption("Flashing Lights", "Toggle flashing lights that can cause seizures and strain",'flashing'),
			new HCBoolOption("Note Splashes", "Shows note splashes when you get a 'Sick' rating on a note",'noteSplash'),
			new HCBoolOption("Show Opponent strumline", "Shows the opponent strumline/notes",'oppStrumline'),
			new HCBoolOption("Show Opponent", "Toggle whether the opponent is loaded or not",'dadShow'),
			new HCBoolOption("Show GF", "Toggle whether gf is loaded or not",'gfShow'),
			new HCBoolOption("Show Player", "Toggle whether the player is loaded or not",'bfShow'),
			new HCBoolOption("Threaded loading screen","Makes the loading screen use threads and show loading progress but is buggy","doCoolLoading"),
			// new MMCharOption("**CAN PUT GAME INTO CRASH LOOP! IF STUCK, HOLD SHIFT AND DISABLE THIS OPTION. Show character on main menu"),
		],"Toggle visibility of certain gameplay aspects"),
		new OptionCategory("Auditory", [
			#if hxCodec
			new HCBoolOption("VLC Audio Handling","Whether to use Flixel or VLC for audio. VLC supports more formats but may cause issues","vlcSound"),
			#end
			new VolumeOption("Adjust the volume of the entire game","master"),
			new VolumeOption("Adjust the volume of the background music","inst"),
			new VolumeOption("Adjust the volume of the vocals","voices"),
			new VolumeOption("Adjust the volume of the hit sounds","hit"),    
			new VolumeOption("Adjust the volume of miss sounds","miss"),       
			new VolumeOption("Adjust the volume of other sounds and the default script sound volume","other"),  
			new HCBoolOption("Miss Sounds","Play a sound when you miss",'playMisses'),
			new HCBoolOption("Hit Sounds","Play a click when you hit a note. Uses osu!'s sounds or your mods/hitsound.ogg",'hitSound'),
			new HCBoolOption("Play Character Voices","Plays the voices a character has when you press a note.","playVoices"),
		],"Toggle some sounds and change the volume of things"),
	];

	public var acceptInput:Bool = true;

	private var currentDescription:String = "";
	private var grpControls:FlxTypedGroup<Alphabet>;
	public static var versionShit:FlxText;
	var timer:FlxTimer;

	var currentSelectedCat:OptionCategory;
	var blackBorder:FlxSprite;
	var titleText:FlxText;
	function addTitleText(str:String = "< Options - Tap here to go back"){
		if (titleText != null) titleText.destroy();
		titleText = new FlxText(FlxG.width * 0.5 - (str.length * 10), 20, 0, str, 12);
		titleText.scrollFactor.set();
		titleText.setFormat(CoolUtil.font, 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(titleText);
	}
	override function create()
	{
		loading = false;
		FlxG.mouse.visible = true;
		instance = this;
		FlxG.save.data.masterVol = FlxG.sound.volume;
		if(onlinemod.OnlinePlayMenuState.socket == null){
			initOptions();
		}else{
			for(catIndex => cat in options){
				var i = cat.options.length;
				while(i > 0){
					i--;
					if(cat.options[i] == null || cat.options[i].isVisible) continue;
					cat.options.remove(cat.options[i]);
				}
			}
		}

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image("menuDesat"));

		menuBG.color = 0x793397;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		grpControls = new FlxTypedGroup<Alphabet>();
		add(grpControls);

		for (i in 0...options.length)
		{
			var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 730, options[i].name, true, false, false);
			controlLabel.isMenuItem = true;
			controlLabel.targetY = i;
			grpControls.add(controlLabel);
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
		}

		currentDescription = "none";

		versionShit = new FlxText(5, FlxG.height + 40, 0, "Offset (Left, Right, Shift for slow): " + HelperFunctions.truncateFloat(FlxG.save.data.offset,2) + " - Description - " + currentDescription, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat(CoolUtil.font, 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		
		blackBorder = new FlxSprite(-30,FlxG.height + 40).makeGraphic((Std.int(versionShit.width + 900)),Std.int(versionShit.height + 600),FlxColor.BLACK);
		blackBorder.alpha = 0.5;

		add(blackBorder);

		add(versionShit);
		addTitleText();
		FlxTween.tween(versionShit,{y: FlxG.height - 18},2,{ease: FlxEase.elasticInOut});
		FlxTween.tween(blackBorder,{y: FlxG.height - 18},2, {ease: FlxEase.elasticInOut});

		super.create();
		changeSelection(0);
	}

	var isCat:Bool = false;
	function isHovering(obj1:Dynamic,obj2:Dynamic):Bool{
		if(obj1 == null || obj2 == null) return false;
		var width:Float = obj2.width;
		var height:Float = obj2.height;
		var x:Float = obj2.x;
		var y:Float = obj2.y;
		return (obj1.x > x && obj1.x < x + width) && (obj1.y > y && obj1.y < y + height);
	}
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!acceptInput) return;
		var _back = controls.BACK;
		var _up = controls.UP_P;
		var _down = controls.DOWN_P;
		var _left = controls.LEFT_P;
		var _right = controls.RIGHT_P;
		var _accept = controls.ACCEPT;

		if(FlxG.mouse.justReleased){
			if(isHovering(FlxG.mouse,titleText)) _back = true;
			if(FlxG.mouse.overlaps(grpControls.members[curSelected])) _accept = true;
			if(FlxG.mouse.y > 450) _down = true;
			else if(FlxG.mouse.y < 300) _up = true;
			// if(grpControls.members[curSelected + 1] != null && FlxG.mouse.overlaps(grpControls.members[curSelected + 1])){
			// 	_down = true;
			// }
			// if(grpControls.members[curSelected - 1] != null && FlxG.mouse.overlaps(grpControls.members[curSelected - 1])){
			// 	_up = true;
			// }

			if(FlxG.swipes[0] != null){
				var swipe = FlxG.swipes[0];
				var distance = (swipe.startPosition.x - swipe.endPosition.x);
				
				if(swipe.duration < 0.5 && (distance > 100 || distance < -100)){
					_left = (distance < -100);
					_right = (distance > 100);
				}
			}
			// TODO Add left and right arrows onscreen for changing options
		}
		if (_back){
			if(isCat){

				isCat = false;

				CoolUtil.clearFlxGroup(grpControls);
				for (i in 0...options.length){
					var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, options[i].name, true, false);
					controlLabel.isMenuItem = true;
					controlLabel.targetY = i;
					controlLabel.x = -2000;
					grpControls.add(controlLabel);
					// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
				}
				curSelected = selCat;
				addTitleText();
				changeSelection();
			}else{
				saveChanges(); // Save when exiting, not every fucking frame
				goBack();
			}
		}
		if (_up) changeSelection(-1);
		if (_down) changeSelection(1);
		if(FlxG.mouse.wheel != 0){
			var move = -FlxG.mouse.wheel;
			changeSelection(Std.int(move));
		}
		
		if (isCat){
			
			if (currentSelectedCat.getOptions()[curSelected].acceptValues){
				if((FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.RIGHT || _right ) && currentSelectedCat.getOptions()[curSelected].right()) 
					updateAlphabet(grpControls.members[curSelected],currentSelectedCat.getOptions()[curSelected].display);
				if((FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.LEFT || _left ) && currentSelectedCat.getOptions()[curSelected].left())
					updateAlphabet(grpControls.members[curSelected],currentSelectedCat.getOptions()[curSelected].display);
			}
			updateOffsetText();
		}else{
			if (FlxG.keys.pressed.SHIFT){
				if (FlxG.keys.pressed.RIGHT) FlxG.save.data.offset += 0.1;
				else if (FlxG.keys.pressed.LEFT) FlxG.save.data.offset -= 0.1;
			}
			else if (FlxG.keys.justPressed.RIGHT) FlxG.save.data.offset += 0.1;
			else if (FlxG.keys.justPressed.LEFT) FlxG.save.data.offset -= 0.1;
			updateOffsetText();
		}
	

		if (controls.RESET) FlxG.save.data.offset = 0;

		if (_accept){
			if (isCat){ 
				if (currentSelectedCat.options[curSelected].press()) 
					updateAlphabet(grpControls.members[curSelected],currentSelectedCat.options[curSelected].display);
			}else{
				selCat = curSelected;
				currentSelectedCat = options[curSelected];
				isCat = true;
				var start = 0;
				var iy = FlxG.height * 0.50;
				CoolUtil.clearFlxGroup(grpControls);
				for (i in start...currentSelectedCat.getOptions().length){
					var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, currentSelectedCat.getOptions()[i].display, true, false);
					controlLabel.isMenuItem = true;
					controlLabel.targetY = i;
					// controlLabel.y = iy;
					updateAlphabet(controlLabel);
					controlLabel.y+=360;
					controlLabel.x=1280;
					grpControls.add(controlLabel);
					// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
				}
				
				curSelected = 0;
				addTitleText('Options > ' + options[selCat].name);
				changeSelection();
				// updateOffsetText();
			}
		}
		
	}
	function updateAlphabet(obj:Alphabet,str:String = ""){

		if(str != "") obj.text = str;
		var txt = obj.text.toLowerCase();
		if(txt.endsWith(" true") || txt.endsWith(" on")){
			obj.color = 0x55FF55;
		}else if(txt.endsWith(" false") || txt.endsWith(" off")){
			obj.color = 0xFF5555;
		}
		obj.bounce();
	}

	var isSettingControl:Bool = false;

	function updateOffsetText(){
		// versionShit.color = FlxColor.WHITE;
		if (isCat)
			versionShit.text = (if(currentSelectedCat.getOptions()[curSelected].acceptValues) currentSelectedCat.getOptions()[curSelected].getValue() + " - " else "") + 
				"Description - " + currentDescription;
		else
			versionShit.text = "Offset (Left, Right, Shift for slow): " + HelperFunctions.truncateFloat(FlxG.save.data.offset,2) + " - Description - " + currentDescription;
	}

	function changeSelection(change:Int = 0)
	{

		if (change != 0 ) FlxG.sound.play(Paths.sound("scrollMenu"), 0.4);

		curSelected += change;

		if (curSelected < 0) curSelected = grpControls.members.length - 1;
		if (curSelected >= grpControls.members.length) curSelected = 0;

		if (isCat)
			currentDescription = currentSelectedCat.options[curSelected].description;
		else if (options[curSelected].description != null)
			currentDescription = options[curSelected].description;
		else
			currentDescription = "Select a category";
		

		updateOffsetText();

		for (bullShit => item in grpControls.members){
			item.targetY = bullShit - curSelected;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0) item.alpha = 1;
		}
	}
	function initOptions(){
		trace('Initializing script options');
		if(FlxG.save.data.scripts.length < 1) return;
		try{SELoader.createDirectory('mods/scriptOptions/');}catch(e){trace('Unable to create dir! ${e}');}
		for (si in 0 ... FlxG.save.data.scripts.length) {
			var script = FlxG.save.data.scripts[si];
			if(!SELoader.exists('mods/scripts/$script/options.json')) {
				continue;
			}
			try{
				var sOptions:OptionsFileDef = Json.parse(CoolUtil.cleanJSON(SELoader.getContent('mods/scripts/$script/options.json')));
				// var curOptions:Map<String,Dynamic> = new Map<String,Dynamic>();
				modOptions[script] = new Map<String,Dynamic>();
				if(SELoader.exists('mods/scriptOptions/$script.json')){
					var scriptJson:Map<String,Dynamic> = loadScriptOptions('mods/scriptOptions/$script.json');
					if(scriptJson != null) {
						// modOptions[script] = scriptJson;
						modOptions[script] = scriptJson;
						// trace('Loaded "mods/scriptOptions/$script.json"');
					}else{
						trace('$script has an empty settings file, skipping!');
					}
				}

				if(sOptions.options == null){'$script has no options defined in it\'s options.json!';continue;}
				var saveOptions:Bool = false;
				var category:Array<Option> = [];
				for (v in sOptions.options) {
					var i = v.name;
					// trace('$script,$i: Registering. Info: ${v.type},${v.description},${v.def}');
					try{

						if(modOptions[script][i] == null) {
							// trace('$script,$i: Reseting to default value');
							if(v.def == null){
								 
								switch(v.type){
									case 0,1: modOptions[script][i] = 0;
									case 2: modOptions[script][i] = false;
								}
							}else{
								modOptions[script][i] = v.def;
							
							}
							saveOptions=true;
						}
						// trace('$script,$i: Adding to list');
						switch (v.type) {
							case 0:category.push(new FloatOption(v.description,i,Std.int(v.min),Std.int(v.max),script));
							case 1:category.push(new IntOption(v.description,i,Std.int(v.min),Std.int(v.max),script));
							case 2:category.push(new BoolOption(v.description,i,script));
							// case 3:category.push(new KeyOption(v.description,i,script));
						}
					}catch(e){
						trace('Error for $script,$i: ${e.message}');
						MainMenuState.errorMessage += '\nError for $script,$i: ${e.message}';
						modOptions[script][i] = null;
					}
				}
				if(category.length < 1){
					throw("No options loaded!");
				}
				// trace('$script: Pushing to options list');
				options.push(new OptionCategory('*${script}',category,'Custom options for ${script}',true));
				// trace('$script: Globalising options');
				// modOptions[script] = curOptions;
				// trace('$script: Globalising option definitions');
				ScriptOptions[script] = sOptions;
				// trace('$script: Saving options');
				if (saveOptions) saveScriptOptions('mods/scriptOptions/$script.json',modOptions[script]);
			}catch(e){
				trace('Error for $script options: ${e.message}');
				MainMenuState.errorMessage += '\nError for $script options: ${e.message}';
				modOptions[script] = null;
				ScriptOptions[script] = null;
			}
		}
	}
	static function saveScriptOptions(path:String,obj:Map<String,Dynamic>){// TJSON gets fucky with maps, this'll save them using a typedef instead
		var _obj:Array<OptionF> = [];
		for (i => v in obj) {
			_obj.push({name:i,value:v});
		}
		File.saveContent(path,Json.stringify(_obj));
	}
	public static function loadScriptOptions(path:String):Null<Map<String,Dynamic>>{ // TJSON gets fucky with maps, this'll load them using a typedef instead
		
		var ret:Map<String,Dynamic> = new Map<String,Dynamic>();
		var obj:Array<OptionF> = Json.parse(CoolUtil.cleanJSON(SELoader.getContent(path)));
		if(obj == null) return null;
		for (i in obj) {
			ret[i.name] = i.value;
		}
		return ret;
	}

	function saveChanges(){
		try{
			// FlxG.save.flush();
			SEFlxSaveWrapper.save();
		}catch(e){MainMenuState.errorMessage += '\nUnable to save options! ${e.message}';}
		// File.saveContent('SEOPTIONS.json',Json.stringify(FlxG.save.data));
		for (i => v in modOptions) {
			try{
				// File.saveContent('mods/scriptOptions/$i.json',Json.stringify({options:v}));
				saveScriptOptions('mods/scriptOptions/$i.json',v);
				// trace('Saved mods/scriptOptions/$i.json');
			}catch(e){
				trace('Error saving $i, ${e.message}');
				MainMenuState.errorMessage += '\nError saving $i, ${e.message}';
			}
		}
		modOptions = new Map<String,Map<String,Dynamic>>();
	}


	// public function parseHScript(?script:String = "",?brTools:HSBrTools = null,?id:String = "song",option:ScriptableOption){
	// 	if ((!QuickOptionsSubState.getSetting("Song hscripts") || onlinemod.OnlinePlayMenuState.socket != null) && !isStoryMode) {resetInterps();return;}
	// 	var songScript = songScript;
	// 	// var hsBrTools = hsBrTools;
	// 	if (script != "") songScript = script;
	// 	if (brTools == null && hsBrTools != null) brTools = hsBrTools;
	// 	if (songScript == "") {return;}
	// 	var interp = HscriptUtils.createSimpleInterp();
	// 	var parser = new hscript.Parser();
	// 	try{
	// 		parser.allowTypes = parser.allowJSON = parser.allowMetadata = true;

	// 		var program;
	// 		// parser.parseModule(songScript);
	// 		program = parser.parseString(songScript);

	// 		if (brTools != null) {
	// 			trace('Using hsBrTools');
	// 			interp.variables.set("BRtools",brTools); 
	// 			brTools.reset();
	// 		}else {
	// 			trace('Using assets folder');
	// 			interp.variables.set("BRtools",new HSBrTools("assets/"));
	// 		}
	// 		interp.variables.set("charGet",charGet); 
	// 		interp.execute(program);
	// 		interps[id] = interp;
	// 		if(brTools != null)brTools.reset();
	// 		callInterp("initScript",[],id);
	// 		interpCount++;
	// 	}catch(e){
	// 		handleError('Error parsing ${id} hscript, Line:${parser.line};\n Error:${e.message}');
	// 		// interp = null;
	// 	}
	// 	trace('Loaded ${id} script!');
	// }


}
