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

class MainMenuState extends SickMenuState
{
	
	public static var firstStart:Bool = true;
	public static var nightly(default,never):String = "X" + SEMacros.buildDate;
	public static var ver(default,never):String = "1.0.0" + (if(nightly != "") "-" + nightly else "");
	// This should be incremented every update, this'll be sequential so you can just compare it to another version identifier
	public static var versionIdentifier:Int = 2;
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
	public static var char:Character = null;
	static var hasWarnedInvalid:Bool = false;
	static var hasWarnedNightly:Bool = (nightly == "");
	public static var triedChar:Bool = false;
	public static var lastError = "";
	
	@:keep inline public static function handleError(?exception:haxe.Exception = null,?error:String = "An error occurred",?details:String="",?forced:Bool = true):Void{

		ScriptableStateManager.lastState = "";
		ScriptableStateManager.goToLastState = false;
		if(MainMenuState.errorMessage == error || lastError == error) return; // Prevents the same error from showing twice

		lastError = error;
		var _error = error;
		if(FlxG.save.data.doCoolLoading && error.indexOf('display.CairoRenderer') == -1){
			_error = "Flixel tried to render an FlxText while the game was rendering the loading screen, causing an error.\nYou can probably just re-do what you did. If this is annoying, disable threaded loading in the options";
		}
		if(MainMenuState.errorMessage != '${_error}\n${MainMenuState.errorMessage}')
			MainMenuState.errorMessage = '${_error}\n${MainMenuState.errorMessage}';
		trace('${error}:${details}');
		if(exception != null)
			try{trace('${exception.message}\n${exception.stack}');}catch(e){}
		
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
		this.important = important;
		multi.MultiMenuState.importedSong = false;
		super();
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
			}else 
			bg.scrollFactor.set(0.1,0.1);
			bg.color = MainMenuState.bgcolor;
			if (onlinemod.OnlinePlayMenuState.socket != null){
				try{
					QuickOptionsSubState.setSetting("Song hscripts",true);
					onlinemod.OnlinePlayMenuState.socket.close();
					onlinemod.OnlinePlayMenuState.socket=null;
				}catch(e){trace('Error closing socket? ${e.message}');}
			}
			if(lastVersionIdentifier != versionIdentifier){
				var outdatedLMAO:FlxText = new FlxText(0, FlxG.height * 0.05, 0,'Super Engine has been updated since last start.\n You are now on ${ver}!', 32);
				outdatedLMAO.setFormat(CoolUtil.font, 32, if(nightly == "") FlxColor.RED else FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				outdatedLMAO.scrollFactor.set();
	 			outdatedLMAO.screenCenter(FlxAxes.X);
				add(outdatedLMAO);

			}else if (TitleState.outdated){

				var outdatedLMAO:FlxText = new FlxText(0, FlxG.height * 0.05, 0,(if(nightly == "") 'SE is outdated, Latest: ${TitleState.updatedVer}, Check Changelog for more info' else 'Latest nightly: ${TitleState.updatedVer}. You are on ${ver}'), 32);
				outdatedLMAO.setFormat(CoolUtil.font, 32, if(nightly == "") FlxColor.RED else FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				outdatedLMAO.scrollFactor.set();
	 			outdatedLMAO.screenCenter(FlxAxes.X);
				add(outdatedLMAO);
			}else 
			//  Whole bunch of checks to prevent crashing
			if (TitleState.retChar(FlxG.save.data.playerChar) == "" && FlxG.save.data.playerChar != "automatic"){
				errorMessage += '\n${FlxG.save.data.playerChar} is an invalid player! Reset back to BF!';
				FlxG.save.data.playerChar = "bf";
			}
			if (TitleState.retChar(FlxG.save.data.opponent) == null){
				errorMessage += '\n${FlxG.save.data.opponent} is an invalid opponent! Reset back to BF!';
				FlxG.save.data.opponent = "bf";
			}
			if (TitleState.retChar(FlxG.save.data.gfChar) == null){
				errorMessage += '\n${FlxG.save.data.gfChar} is an invalid GF! Reset back to GF!';
				FlxG.save.data.gfChar = "gf";
			}
			// if(MainMenuState.errorMessage == "" && !triedChar && FlxG.save.data.mainMenuChar && !FlxG.keys.pressed.CONTROL && !FlxG.keys.pressed.SHIFT){
			// 	triedChar = true;
			// 	try{
			// 		char = new Character(FlxG.width * 0.55,FlxG.height * 0.10,FlxG.save.data.playerChar,true,0,true);
			// 		if(char != null) add(char);
			// 	}catch(e){MainMenuState.lastStack = e.stack;trace(e);char = null;}
			// }
			if(firstStart){
				// FlxG.sound.volumeHandler = function(volume:Float){
				// 	FlxG.save.data.masterVol = volume;
				// 	FlxG.save.data.flush();
				// };
				FlxG.camera.scroll.y -= 100;
				FlxTween.tween(FlxG.camera.scroll,{y:0},1,{ease:FlxEase.cubeOut});
				callInterp('firstStart',[]);
				firstStart = false;
			}


			if (MainMenuState.errorMessage == "" && TitleState.invalidCharacters.length > 0 && !hasWarnedInvalid) {
				errorMessage += "You have some characters missing config.json files.";
				hasWarnedInvalid = true;
			} 
			if (!hasWarnedNightly) {
				errorMessage += "This is a nightly build for " + ver.substring(0,ver.length - (1 + nightly.length) ) +", expect bugs and things changing without warning!\nBasing a fork off of this is not advised!";
				// ver+=nightly;
				hasWarnedNightly = true;
			} 

			var versionShit:FlxText = new FlxText(5, FlxG.height - 50, 0, 'FNF 0.2.7.1/Kade 1.5.2/${if(TitleState.easterEgg == 0x1) "Lesbian" else "Super"}-Engine ${ver} ${buildType} ${compileType}', 12);
			versionShit.setFormat(CoolUtil.font, 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			versionShit.borderSize = 2;
			versionShit.scrollFactor.set();
			add(versionShit);
			if (MainMenuState.errorMessage != ""){

				FlxG.sound.play(Paths.sound('cancelMenu'));

				var errorText =  new FlxText(2, 64, 0, MainMenuState.errorMessage, 12);
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
			if(FlxG.save.data.simpleMainMenu)
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
		#if mobile
			selected = false;
		#else
		if (otherMenu) {mmSwitch(true);FlxG.sound.play(Paths.sound('cancelMenu'));return;} else{
			selected = false;
		}
		#end
		// FlxG.switchState(new TitleState());
		// do nothing
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		// if(char != null){
		// 	if(controls.LEFT){
		// 		char.playAnim("singLEFT",true);
		// 	}else if(controls.RIGHT){
		// 		char.playAnim("singRIGHT",true);
		// 	}
		// }
		super.update(elapsed);
	}
	override function beatHit()
	{
		super.beatHit();
		// if(char != null && char.animation.curAnim.finished) char.dance(true);
	}
	override function changeSelection(change:Int = 0){
		// if(char != null && change != 0) char.playAnim(Note.noteAnims[if(change > 0)1 else 2],true);
		if(MainMenuState.errorMessage != "")MainMenuState.errorMessage = "";
		super.changeSelection(change);
	}
	#if(android) inline static #end var otherMenu:Bool = false;
	#if !mobile
	function otherSwitch(){
		options = ["deprecated freeplay","download charts","download characters","import charts from mods","changelog", 'credits'];
		descriptions = ['Play any song from the main game or your assets folder',"Download charts made for or ported to Super Engine","Download characters made for or ported to Super Engine",'Convert charts from other mods to work here. Will put them in Modded Songs',"Read the latest changes for the engine","Check out the awesome people who helped with this engine in some way"];
		
		if (ChartingState.charting) {options.unshift("open closed chart"); descriptions.unshift("It looks like a chart is still open. This option will reopen the chart editor");}
		if (TitleState.osuBeatmapLoc != '') {options.push("osu beatmaps"); descriptions.push("Play osu beatmaps converted over to FNF");}
		options.push("back"); descriptions.push("Go back to the main menu");
		curSelected = 0;

		#if(!mobile)
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
		if(FlxG.save.data.simpleMainMenu){
		#end
			//Damn, talk about a huge difference from 9 options down to 3
			options = ['modded songs',"scripted states","credits",'options'];
			descriptions = ["Play songs from your mods/charts folder, packs or weeks","Join and play online with other people on a Battle Royale compatible server.","Run a script in a completely scriptable blank state",'Customise your experience to fit you'];
			if(ChartingState.charting){
				options.unshift('open unfinished chart');
				descriptions.unshift('Looks like the chart editor closed incorrectly. You can reopen it here');
			}
		#if !mobile
		}else{
			options = ['modded songs','join FNF\'br server',
			#if !ghaction
				'host br server',
			#end
				'online songs',"story mode",'other',"scripted states", 'open mods folder','options'];
			descriptions = ["Play songs from your mods/charts folder, packs or weeks","Join and play online with other people on a Battle Royale compatible server.",
			#if !ghaction
			'Host a server so people can join locally, via ngrok or from your IP using portforwarding',
			#end
			"Play songs that have been downloaded during online games.","Play a vanilla or custom week",'Freeplay, Osu beatmaps, and download characters or songs',"Run a script in a completely scriptable blank state",'Open your mods folder in your File Manager','Customise your experience to fit you'];
		}
		#end
		curSelected = 0;
		#if(!mobile)
			otherMenu = false;
		#end
		if(regen)generateList();
		callInterp('mmSwitch',[]);
		if(cancelCurrentFunction) return;
		if(regen)changeSelection();
		selected = false;
	}

  override function select(sel:Int){
		MainMenuState.errorMessage="";
		if (selected){return;}
		selected = true;
		var daChoice:String = options[sel];
		FlxG.sound.play(Paths.sound('confirmMenu'));
		triedChar = false;
		if(daChoice != "other" && daChoice != 'back' && daChoice != 'open mods folder'){
			var _obj = grpControls.members[sel];
			FlxTween.tween(_obj,{x:500},0.4,{ease:FlxEase.quadIn});
			FlxTween.tween(_obj,{x:500},0.4,{ease:FlxEase.quadIn});
			for (obj in grpControls.members){
				if(obj == _obj) continue;
				FlxTween.tween(obj,{x:-500},0.4,{ease:FlxEase.quadIn});
			}
		}
		
		switch (daChoice)
		{

			case 'open closed chart':
				loading = true;
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
					#end
					FlxG.switchState(new onlinemod.OnlinePlayMenuState());
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
					FlxG.switchState(new onlinemod.OfflineMenuState());
				case 'changelog':
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
				case "download charts":
					FlxG.switchState(new ChartRepoState());
				case 'story mode':
					loading = true;
					FlxG.switchState(new StoryMenuState());
				case 'deprecated freeplay':
					loading = true;
					FlxG.switchState(new FreeplayState());
				case 'osu beatmaps':
					loading = true;
					FlxG.switchState(new osu.OsuMenuState());
				case "import charts from mods":
					FlxG.switchState(new ImportMod());
				case 'download characters':
					FlxG.switchState(new RepoState());
				case "back":
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
