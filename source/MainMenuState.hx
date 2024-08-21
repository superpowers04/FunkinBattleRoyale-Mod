package;

import Controls.KeyboardScheme;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import sys.io.File;
import ScriptableState;

// For Title Screen GF
import flixel.graphics.FlxGraphic;
import flixel.animation.FlxAnimation;
import flixel.animation.FlxBaseAnimation;
import sys.FileSystem;
import flixel.graphics.frames.FlxAtlasFrames;
import flash.display.BitmapData;
import flixel.util.FlxAxes;
import haxe.CallStack;
import se.utilities.SEMacros;

using StringTools;

class MainMenuState extends SickMenuState {
	
	public static var firstStart:Bool = true;
	public static var nightly(default,never):String = "X" + SEMacros.buildDate;
	public static var ver(default,never):String = "1.0.0" + (if(nightly != "") "-" + nightly else "");
	// This should be incremented every update, this'll be sequential so you can just compare it to another version identifier
	public static var versionIdentifier:Int = 3;
	public static var lastVersionIdentifier:Int = 0;

	public static var compileType(default,never):String =
	#if ghaction
		"Github action"
	#elseif debug
		"Manual debug build"
	#else
		"Manual build"
	#end;
	public static var buildType:String = #if(android) "android" #else Sys.systemName() #end ;
	public static var errorMessage:String = "";
	public static var bgcolor:Int = 0;
	// public static var char:Character = null;
	// static var hasWarnedInvalid:Bool = false;
	static var hasWarnedNightly:Bool = (nightly == "");
	public static var triedChar:Bool = false;
	public static var lastError = "";
	
	@:keep inline public static function handleError(?exception:haxe.Exception = null,?error:String = "An error occurred",?details:String="",?forced:Bool = true,?pos:haxe.PosInfos):Void{
		trace('Refer to below:\n${pos.fileName}:${pos.lineNumber}: MainMenuState.HandleError called');
		// 
		ScriptableStateManager.lastState = "";
		ScriptableStateManager.goToLastState = false;
		if(MainMenuState.errorMessage == error || lastError == error) return; // Prevents the same error from showing twice

		lastError = error;
		var _error = error;
		if(SESave.data.doCoolLoading && error.indexOf('display.CairoRenderer') >= 0){
			_error = "Flixel tried to render an FlxText while the game was rendering the loading screen, causing an error.\nYou can probably just re-do what you did. If this is annoying, disable threaded loading in the options";
		}
		if(MainMenuState.errorMessage.indexOf('${_error}\n${MainMenuState.errorMessage}') == -1)
			MainMenuState.errorMessage = '${_error}\n${MainMenuState.errorMessage}';
		MainMenuState.errorMessage = MainMenuState.errorMessage.replace('\nCalled from','\n Called from');
		trace('${error}:${details}');
		if(exception != null)
			try{trace('${exception.message}\n${exception.stack}');
		}catch(e){}
		
		if (onlinemod.OnlinePlayMenuState.socket != null){
			try{
				onlinemod.OnlinePlayMenuState.socket.close();
				onlinemod.OnlinePlayMenuState.socket=null;
				QuickOptionsSubState.setSetting("Song hscripts",true);
			}catch(e){trace('You just got an exception in yo exception ${e.message}');}
		}
		try{LoadingScreen.hide();}catch(e){}
		if(LoadingScreen.object != null) LoadingScreen.object.alpha = 0;

		if(forced)
			Main.game.forceStateSwitch(new MainMenuState(true));
		else
			FlxG.switchState(new MainMenuState());
		
	}
	// macro function getTime():String{
	// 	var time = Date.now();
	// 	return '${time.getDay()}/${time.getMonth}/${time.getYear() - 2000} ${time.getHours()}:${time.getMinutes()}';
	// }
	var important:Bool = false;
	override public function new(important:Bool = false){
		FlxG.sound.volume = SESave.data.masterVol;
		this.important = important;
		multi.MultiMenuState.importedSong = false;
		super();
		FlxG.mouse.enabled = FlxG.mouse.visible = true;
		MusicBeatState.lastClassList = [];
		scriptSubDirectory = "/mainmenu/";
	}
	override function create()
	{
		try{
		// forceQuit = true;
			if (Main.errorMessage != ""){
				errorMessage = Main.errorMessage;
				Main.errorMessage = "";
				trace(errorMessage);
			}
			mmSwitch(false);

			persistentUpdate = persistentDraw = true;
			bgImage = 'menuDesat';
			controls.setKeyboardScheme(KeyboardScheme.Solo, true);
			loading = false;
			isMainMenu = true;
			if(!important){
				useNormalCallbacks = true;
				loadScripts(true);
			}
			super.create();

			if(MainMenuState.errorMessage == "" && ScriptableStateManager.goToLastState && ScriptableStateManager.lastState != ""){
				SelectScriptableState.selectState(ScriptableStateManager.lastState);
				return;
			}
			bg.scrollFactor.set(0.1,0.1);
			bg.color = MainMenuState.bgcolor;
			onlinemod.OnlinePlayMenuState.disconnect();
			if(lastVersionIdentifier != versionIdentifier){
				var outdatedLMAO:FlxText = new FlxText(0, FlxG.height * 0.05, 0,'Super Engine has been updated since last start.\n You are now on ${ver}!', 32);
				outdatedLMAO.setFormat(CoolUtil.font, 32, if(nightly == "") FlxColor.RED else FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				outdatedLMAO.scrollFactor.set();
	 			outdatedLMAO.screenCenter(FlxAxes.X);
				add(outdatedLMAO);
			}else if (TitleState.outdated){

				// var outdatedLMAO:FlxText = new FlxText(0, FlxG.height * 0.05, 0,(if(nightly == "") 'SE is outdated, Latest: ${TitleState.updatedVer}, Check Changelog for more info' else 'Latest nightly: ${TitleState.updatedVer}. You are on ${ver}'), 32);
				// outdatedLMAO.setFormat(CoolUtil.font, 32, if(nightly == "") FlxColor.RED else FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				// outdatedLMAO.scrollFactor.set();
				var outdatedLMAO = new SEText(0, FlxG.height * 0.05,0,(nightly == "" ? 'SE is outdated, Latest update:${TitleState.updatedVer}, Check Changelog for more info' : ((TitleState.updatedVer == ver) ? 'You are on $ver; The latest nightly.' : 'Latest nightly: ${TitleState.updatedVer}. You are on ${ver}')),
					32,(nightly==""?FlxColor.RED:FlxColor.WHITE),CENTER);
	 			outdatedLMAO.screenCenter(FlxAxes.X);
				add(outdatedLMAO);
			}else 
			//  Whole bunch of checks to prevent crashing
			if (TitleState.retChar(SESave.data.playerChar) == "" && SESave.data.playerChar != "automatic"){
				errorMessage += '\n${SESave.data.playerChar} is an invalid player! Reset back to BF!';
				SESave.data.playerChar = "bf";
			}
			if (TitleState.retChar(SESave.data.opponent) == null){
				errorMessage += '\n${SESave.data.opponent} is an invalid opponent! Reset back to BF!';
				SESave.data.opponent = "bf";
			}
			if (TitleState.retChar(SESave.data.gfChar) == null){
				errorMessage += '\n${SESave.data.gfChar} is an invalid GF! Reset back to GF!';
				SESave.data.gfChar = "gf";
			}
			// if(MainMenuState.errorMessage == "" && !triedChar && SESave.data.mainMenuChar && !FlxG.keys.pressed.CONTROL && !FlxG.keys.pressed.SHIFT){
			// 	triedChar = true;
			// 	try{
			// 		char = new Character(FlxG.width * 0.55,FlxG.height * 0.10,SESave.data.playerChar,true,0,true);
			// 		if(char != null) add(char);
			// 	}catch(e){MainMenuState.lastStack = e.stack;trace(e);char = null;}
			// }
			if(firstStart){
				// FlxG.sound.volumeHandler = function(volume:Float){
				// 	SESave.data.masterVol = volume;
				// 	SESave.data.flush();
				// };
				FlxG.camera.scroll.y -= 100;
				FlxTween.tween(FlxG.camera.scroll,{y:0},1,{ease:FlxEase.cubeOut});
				callInterp('firstStart',[]);
				firstStart = false;
			}


			// if (MainMenuState.errorMessage == "" && TitleState.invalidCharacters.length > 0 && !hasWarnedInvalid) {
			// 	errorMessage += "You have some characters missing config.json files.";
			// 	hasWarnedInvalid = true;
			// } 
			if (!hasWarnedNightly) {
				errorMessage += "This is a nightly build, expect bugs and things changing without warning!\nPlease report any bugs you encounter!";
				// ver+=nightly;
				hasWarnedNightly = true;
			} 

			var versionShit:FlxText = new FlxText(5, FlxG.height - 50, 0, '${(TitleState.easterEgg == 0x1) ? "Lesbian" : "Super"}-Engine ${ver} ${buildType} ${compileType}', 12);
			versionShit.setFormat(CoolUtil.font, 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			versionShit.borderSize = 2;
			versionShit.scrollFactor.set();
			add(versionShit);
			if (MainMenuState.errorMessage != ""){

				FlxG.sound.play(Paths.sound('cancelMenu'));
				var errorText =  new FlxText(2, 90, 0, MainMenuState.errorMessage, 12);
				errorText.scrollFactor.set();
				errorText.wordWrap = true;
				errorText.fieldWidth = 1200;
				errorText.setFormat(CoolUtil.font, 32, FlxColor.RED, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				add(errorText);
			}
			SELoader.gc();
			eventColors(Date.now());
			

			lastError = "";
			#if !mobile
			if(SESave.data.simpleMainMenu)
			// Scrolls down enough so you can press all of the buttons without needing to scroll
			#end
				changeSelection(1);

			callInterp('createAfter',[]);

		}catch(e){
			FuckState.FUCK(e,'MainMenuState.create');
		}
	}

	public function eventColors(date:Date){
		if(date.getMonth() == 11){

			var _d = date.getDate();
			if(_d > 19 && _d < 26){
				bg.color = 0xaa3333;
				FlxTween.cancelTweensOf(bg);
				FlxTween.color(bg,10,FlxColor.fromString("#aa3333"),FlxColor.fromString("#33aa33"),{type:FlxTweenType.PINGPONG});
			}
			return;
		}
	}

	override function goBack(){
		#if !mobile
		if (otherMenu) {mmSwitch(true);FlxG.sound.play(Paths.sound('cancelMenu'));return;} else
		#end
			escapePress();
		// FlxG.switchState(new TitleState());
		// do nothing
	}

	override function update(elapsed:Float) {
		// if (FlxG.sound.music.volume < 0.8) FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		// if(char != null){
		// 	if(controls.LEFT){
		// 		char.playAnim("singLEFT",true);
		// 	}else if(controls.RIGHT){
		// 		char.playAnim("singRIGHT",true);
		// 	}
		// }
		super.update(elapsed);
	}
	// override function beatHit()
	// {
	// 	super.beatHit();
	// 	// if(char != null && char.animation.curAnim.finished) char.dance(true);
	// }
	var showedImportClipboard:Bool = false;
	static var lastImported:String = "";
	override function onFocus(){

		var clip = lime.system.Clipboard.text;
		if(clip != lastImported && clip.startsWith('https://') && clip.contains('.zip')){
			if(showedImportClipboard) return;
			showedImportClipboard = true;
			if(!otherMenu){
				otherSwitch();
			}
			lastImported=clip;
			descriptions[0]= "Detected a link to a zip file in your clipboard. Press this to import it";

			changeSelection();
		}else if(showedImportClipboard){
			showedImportClipboard=false;
			if(otherMenu){
				options[0]= "import clipboard";
				descriptions[0]= 'Treats the contents of your clipboard like you\'ve dragged and dropped it onto the game';
				if(curSelected == 0) changeSelection();
			}
		}
	}
	override function changeSelection(change:Int = 0){
		// if(char != null && change != 0) char.playAnim(Note.noteAnims[if(change > 0)1 else 2],true);
		MainMenuState.errorMessage = "";
		super.changeSelection(change);
	}
	#if(mobile) 
		inline static var otherMenu:Bool = false;
		function otherSwitch(){}
	#else
	public var otherMenu:Bool = false;
	function escapePress(){
		callInterp('openExitPrompt',[]);
		options = ["Main Menu","Exit Game"];
		descriptions = ['Return to the main menu','Close out of the game'];
		generateList();
		curSelected=0;
		selected = false;
		changeSelection();
	}
	function otherSwitch(){
		options = ["import clipboard","deprecated freeplay","download assets","download characters","import charts from mods","changelog", 'credits'];
		descriptions = ['Treats the contents of your clipboard like you\'ve dragged and dropped it onto the game','Play any song from the main game or your assets folder',"Download content made for or ported to Super Engine","Download characters made for or ported to Super Engine",'Convert charts from other mods to work here. Will put them in Modded Songs',"Read the latest changes for the engine","Check out the awesome people who helped with this engine in some way"];
		
				// if (TitleState.osuBeatmapLoc != '') {options.push("osu beatmaps"); descriptions.push("Play osu beatmaps converted over to FNF");}
		options.push("back"); descriptions.push("Go back to the main menu");
		curSelected = 0;
		#if !mobile
			otherMenu = true;
		#end
		selected = false;
		callInterp('otherSwitch',[]);
		if(cancelCurrentFunction) return;
		generateList();
		changeSelection();
	}
	#end
	function mmSwitch(regen:Bool = false){

		#if !mobile
		if(SESave.data.simpleMainMenu){
		#end
			//Damn, talk about a huge difference from 9 options down to 3
			options = ['modded songs',"scripted states","credits",'options'];
			descriptions = ["Play songs from your mods/charts folder, packs or weeks","Join and play online with other people on a Battle Royale compatible server.","Run a script in a completely scriptable blank state",'Customise your experience to fit you'];
			if(!MainMenuState.ver.contains(TitleState.updatedVer.trim())){
				options.insert(2,"update");
				descriptions.insert(2,"An update has been detected for Super Engine, Press this to view the changelog and download the update!");
			}

		#if !mobile
		}else{
			options = ['modded songs','join FNF\'br server', 'host br server',
				'online songs',"story mode",'other',"scripted states", 'open mods folder','options'];
			descriptions = ["Play songs from your mods/charts folder, packs or weeks","Join and play online with other people on a Battle Royale compatible server.",
			'Host a server so people can join locally, via ngrok or from your IP using portforwarding',
			"Play songs that have been downloaded during online games.","Play a vanilla or custom week",'Freeplay, credits, and download characters or songs',"Run a script in a completely scriptable blank state",'Open your mods folder in your File Manager','Customise your experience to fit you'];

		}
			otherMenu = false;
		#end
		if (ChartingState.charting) {options.unshift("open closed chart"); descriptions.unshift("It looks like a chart is still open. This option will reopen the chart editor");}
		curSelected = 0;
		callInterp('mmSwitch',[]);
		if(cancelCurrentFunction) return;
		if(regen){
			generateList();
			changeSelection();
		}
		selected = false;
	}

  override function select(sel:Int){
		MainMenuState.errorMessage="";
		if (selected){return;}
		selected = true;
		var daChoice:String = options[sel];
		SELoader.playSound('assets/sounds/confirmMenu',true);
		triedChar = false;
		if(daChoice != "other" && daChoice != 'back' && daChoice != 'open mods folder'){
			var _obj = grpControls.members[sel];
			FlxTween.tween(_obj,{x:500},0.4,{ease:FlxEase.quadIn});
			// FlxTween.tween(_obj,{x:500},0.4,{ease:FlxEase.quadIn});
			for (obj in grpControls.members){
				if(obj == _obj) continue;
				FlxTween.tween(obj,{x:-500},0.4,{ease:FlxEase.quadIn});
			}
		}
		
		switch (daChoice.toLowerCase()){

			case 'open closed chart':
				loading = true;

				onlinemod.OfflinePlayState.instFile = ChartingState.lastInst;
				onlinemod.OfflinePlayState.voicesFile = ChartingState.lastVoices;
				onlinemod.OfflinePlayState.chartFile = ChartingState.lastChart;
				FlxG.switchState(new ChartingState());
			case 'modded songs':
				loading = true;
				FlxG.switchState(new multi.MultiMenuState());
			case "scripted states":
				FlxG.switchState(new SelectScriptableState());
			case "credits":
				FlxG.switchState(new se.states.Credits());
			case 'options':
				FlxG.switchState(new OptionsMenu());
			#if !mobile
				case 'join FNF\'br server':
					#if android
					if(!Main.grantedPerms.contains('android.permission.INTERNET')){
						selected = false;
						MainMenuState.handleError('Unable to play online, You need to give internet access to the game!');
						return;
					}
					#else
					FlxG.switchState(new onlinemod.OnlinePlayMenuState());
					#end
				case 'other':
					// FlxG.switchState(new OtherMenuState());
					otherSwitch();
				#if !ghaction
				// Unstable,this'll be removed when I actually make it work
				case 'host br server':
					FlxG.switchState(new onlinemod.OnlineHostMenu());
				#end
				case 'online songs':
					loading = true;
					MainMenuState.handleError('Offline songs have been moved to the modded songs list!');
					// FlxG.switchState(new onlinemod.OfflineMenuState());
				case "import clipboard":
					AnimationDebug.fileDrop(lime.system.Clipboard.text);
				case 'exit game' :
					Sys.exit(0);
				case 'changelog' | 'update':
					FlxG.switchState(new OutdatedSubState());
				// case "Setup characters":
				// 	FlxG.switchState(new SetupCharactersList());
				case 'open mods folder':
					selected = false;
					changeSelection(0);
					#if(linux)
						var _path = SELoader.fullPath('mods/');
						for(i in ['exo-open','xdg-open','nemo','dolphin','nautilus','pcmanfm']){
							if(Sys.command(i,[_path]) != 127){
								return;
							}
						}
						showTempmessage('Unable to find suitable opener!');
					#elseif(windows)
						Sys.command('start',[SELoader.fullPath('mods/')]);
					#elseif(macos)
						Sys.command('open',[SELoader.fullPath('mods/')]);
					#end
				case "download assets":
					FlxG.switchState(new se.states.ModRepoState());
				case "download charts":
					FlxG.switchState(new ChartRepoState());
				case 'story mode':
					handleError('Story mode is disabled while it gets overhauled');
					// loading = true;
					// FlxG.switchState(new StoryMenuState());
				case 'deprecated freeplay':
					loading = true;
					FlxG.switchState(new FreeplayState());
				// case 'osu beatmaps':
				// 	loading = true;
				// 	FlxG.switchState(new osu.OsuMenuState());
				case "import charts from mods":
					FlxG.switchState(new ImportMod());
				case 'download characters':
					FlxG.switchState(new RepoState());
				case "back", "main menu":
					mmSwitch(true);
			#end
			default:
				callInterp('select',[sel,daChoice]);
		}
	}
	override function addListing(i:Int){ // I'm lazy and just want to center the object
		callInterp('addToList',[i,options[i]]);
		if(cancelCurrentFunction) return;
		var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, options[i], true, false);
		controlLabel.isMenuItem = true;
		controlLabel.targetY = i;
		if (i != 0) controlLabel.alpha = 0.6;
		controlLabel.moveX = false;
		controlLabel.screenCenter(X);
		grpControls.add(controlLabel);
		callInterp('addToListAfter',[controlLabel,i,options[i]]);

	}
}
