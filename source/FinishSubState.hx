package;

import openfl.Lib;

import Controls.Control;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.FlxObject;
import flixel.ui.FlxBar;
import flixel.FlxCamera;
import sys.FileSystem;
import sys.io.File;
import PlayState.OutNote;
import openfl.media.Sound;

using StringTools;


typedef ActionsFile = {
	var info:String;
	var notes:Array<OutNote>;
	var bf:String;
	var gf:String;
	var opp:String;
	var ver:String;

}


class FinishSubState extends MusicBeatSubstate
{
	public var curSelected:Int = 0;
	public var music:FlxSound;
	public var perSongOffset:FlxText;
	public var offsetChanged:Bool = false;
	public var win:Bool = true;
	public var ready = false;
	public var readyTimer:Float = 0;
	public var errorMsg:String = "";
	public var isError:Bool = false; 
	public var healthBarBG:FlxSprite;
	public var healthBar:FlxBar;
	public var iconP1:HealthIcon; 
	public var iconP2:HealthIcon;
	public static var pauseGame:Bool = true;
	public static var autoEnd:Bool = true;
	public static var forceBFAnim:Bool = false;
	public static var instance:FinishSubState;
	public static var fadeOut:Bool = true;
	public var updateBF = true;
	public function new(x:Float, y:Float,?won = true,?error:String = "",force:Bool = false)
	{
		instance = this;
		super();
		endingMusic = null;
		if (error != ""){
			isError = true;
			errorMsg = error;
			won = false;
			// PlayState.instance.paused = true;
		}
		if(force){
			FlxG.state.persistentUpdate = false;
			FlxG.sound.pause();
			PlayState.instance.generatedMusic = PlayState.instance.handleTimes = PlayState.instance.acceptInput = false;
			super();
			finishNew("FORCEDMOMENT.MP4efdhseuifghbehu");
			return;
		}
		PlayState.instance.camHUD.alpha = PlayState.instance.camTOP.alpha = 1;
		PlayState.instance.followChar(if(won) 0 else 1);
		var camPos = PlayState.instance.getDefaultCamPos();
		PlayState.instance.camFollow.setPosition(camPos[0],camPos[1]);
		if(!isError){
			var inName = if(won)"winSong" else "loseSong";
			PlayState.instance.callInterp(inName,[]);
			PlayState.dad.callInterp(inName,[]);
			PlayState.playerCharacter.callInterp(inName,[]);
		}

		FlxG.state.persistentUpdate = false;
		win = won;
		FlxG.sound.pause();
		
		PlayState.instance.generatedMusic = PlayState.instance.handleTimes = PlayState.instance.acceptInput = false;
		
		var dad = PlayState.opponentCharacter;
		var boyfriend = PlayState.playerCharacter;
		var curAnim:String = boyfriend.animName;

		// Conductor.changeBPM(70);
		FlxG.cameras.setDefaultDrawTarget(PlayState.instance.camGame,true);


		// For healthbar shit
		healthBar = PlayState.instance.healthBar;
		healthBarBG = PlayState.instance.healthBarBG;
		iconP1 = PlayState.instance.iconP1;
		iconP2 = PlayState.instance.iconP2;



		if(isError){
			finishNew();
		}else{
			var bfAnims = [];

			if(win){
				for (g in [PlayState.instance.cpuStrums,PlayState.instance.playerStrums]) {
					g.forEach(function(i){
						FlxTween.tween(i, {y:if(SESave.data.downscroll)FlxG.height + 200 else -200},1,{ease: FlxEase.expoIn});
					});
				}
				if (SESave.data.songPosition)
				{
					for (i in [PlayState.songPosBar,PlayState.songPosBG,PlayState.instance.songName,PlayState.instance.songTimeTxt]) {
						FlxTween.tween(i, {y:if(SESave.data.downscroll)FlxG.height + 200 else -200},1,{ease: FlxEase.expoIn});
					}
				}

				FlxTween.tween(healthBar, {y:Std.int(FlxG.height * 0.10)},1,{ease: FlxEase.expoIn});
				FlxTween.tween(healthBarBG, {y:Std.int(FlxG.height * 0.10 - 4)},1,{ease: FlxEase.expoIn});
				FlxTween.tween(iconP1, {y:Std.int(FlxG.height * 0.10 - (iconP1.height * 0.5))},1,{ease: FlxEase.expoIn});
				FlxTween.tween(iconP2, {y:Std.int(FlxG.height * 0.10 - (iconP2.height * 0.5))},1,{ease: FlxEase.expoIn});




				FlxTween.tween(PlayState.instance.kadeEngineWatermark, {y:FlxG.height + 200},1,{ease: FlxEase.expoIn});
				FlxTween.tween(PlayState.instance.scoreTxt, {y:if(SESave.data.downscroll) -200 else FlxG.height + 200},1,{ease: FlxEase.expoIn});
				bfAnims = ['win','hey'];
				if (dad.curCharacter == SESave.data.gfChar) dad.playAnim('cheer',true); else {dad.playAnimAvailable(['lose'],true);}
				PlayState.gf.playAnim('cheer',true);
			}else{
				// boyfriend.playAnim('singDOWNmiss');
				// boyfriend.playAnim('lose');

				// dad.playAnim("hey",true);
				// dad.playAnim("win",true);
				bfAnims = ['lose'];
				
				if (dad.curCharacter == SESave.data.gfChar) dad.playAnim('sad',true); 
				else
					dad.playAnimAvailable(['win','hey'],true);
				PlayState.gf.playAnim('sad',true);
			}
		
			if(autoEnd){

				// FlxG.camera.zoom = 1;
				// PlayState.instance.camHUD.zoom = 1;

				if(boyfriend.playAnimAvailable(bfAnims,true)) 
					boyfriend.animation.finishCallback = this.finishNew; 
				else 
					finishNew();
				// if (SESave.data.camMovement){
				PlayState.instance.followChar(0);
				PlayState.instance.controlCamera = false;
				// }
				forceBFAnim = false;
			}
		}

	}

	public static var endingMusic:Sound;
	public var cam:FlxCamera;
	var optionsisyes:Bool = false;
	var shownResults:Bool = false;
	public var contText:FlxText;
	inline function canSaveScore(){
		if(!win || PlayState.instance.hasDied) return "No - Lost";
		if(ChartingState.charting) return 'No - Currently charting?';
		if(PlayState.instance.botPlay) return 'No - Using botplay';
		if(!PlayState.instance.canSaveScore) return 'No - Disabled by a script';
		return "Yes";
	}
	public function saveScore(forced:Bool = false):Bool{

		if(canSaveScore() != "Yes") return false;
		return (Highscore.setScore('${PlayState.nameSpace}-${PlayState.actualSongName}${(if(PlayState.invertedChart) "-inverted" else "")}',PlayState.songScore,[PlayState.songScore,'${HelperFunctions.truncateFloat(PlayState.accuracy,2)}%',Ratings.GenerateLetterRank(PlayState.accuracy)],forced));
		
		// if(forced){
		// 	if(!win || PlayState.instance.hasDied){showTempmessage("",FlxColor.RED);}
		// }
	}
	@:keep inline public static function getScore(forced:Bool = false):Int{

			return (Highscore.getScoreUnformatted('${PlayState.nameSpace}-${PlayState.actualSongName}${(if(PlayState.invertedChart) "-inverted" else "")}'));
	}
	public function finishNew(?name:String = ""){
			// FlxG.mouse.visible = true;
			// var timer = new FlxTimer().start(1,function(e:FlxTimer){FinishSubState.instance.ready=true;FlxTween.tween(FinishSubState.instance.contText,{alpha:1},0.5);});
			Conductor.changeBPM(70);
			if(isError) win = false;
			if(name != "FORCEDMOMENT.MP4efdhseuifghbehu"){

				FlxG.camera.alpha = PlayState.instance.camHUD.alpha = 1;
				FlxG.camera.visible = PlayState.instance.camHUD.visible  = PlayState.instance.camTOP.visible = true;
				FlxG.camera.zoom = PlayState.instance.camTOP.zoom = PlayState.instance.camHUD.zoom = 1;
				// FlxG.camera.zoom = PlayState.instance.defaultCamZoom;
				PlayState.instance.generatedMusic = false;
				var camPos = PlayState.instance.getDefaultCamPos(false);
				// PlayState.instance.camFollow.setPosition(camPos[0],camPos[1]);
				PlayState.instance.moveCamera = PlayState.instance.controlCamera = false;
				PlayState.instance.camFollow.x = PlayState.instance.camGame.scroll.x = camPos[0];
				PlayState.instance.camFollow.y = PlayState.instance.camGame.scroll.y = camPos[1];
				FlxG.state.persistentUpdate = !isError && !pauseGame;
				if (win) PlayState.playerCharacter.animation.finishCallback = null; else PlayState.dad.animation.finishCallback = null;
				updateBF = false;
			}
			cam = new FlxCamera();
			FlxG.cameras.add(cam);
			FlxG.cameras.setDefaultDrawTarget(cam,true);
			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]]; 
				// ready = true;
			pauseGame = true;
			autoEnd = true;
			FlxG.sound.pause();

			// if(!win)FlxG.sound.play(Paths.sound('fnf_loss_sfx'));
			music = new FlxSound().loadEmbedded(endingMusic ?? Paths.music( win ? 'StartItchBuild' : 'gameOver' ), true, true);
			music.play(false);

			if(win && endingMusic == null){
				music.looped = false;
				music.onComplete = function(){
					music = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
					music.play(false);
					FlxG.sound.list.add(music);
				} 

			}
			endingMusic = null;
			shownResults = true;
			// FlxG.camera.zoom = PlayState.instance.camHUD.zoom = 1;

			FlxG.sound.list.add(music);
			// PlayState.songScore
			

			var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			bg.alpha = 0;
			bg.scrollFactor.set();
			if(isError){
				// ready = false;
				var finishedText:FlxText = new FlxText(20,-55,0, "Error caught!" );
				finishedText.size = 32;
				finishedText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
				finishedText.color = FlxColor.RED;
				finishedText.scrollFactor.set();
				finishedText.screenCenter(X);
				var errText:FlxText = new FlxText(20 + SESave.data.guiGap,150,0,'Error Message:\n${errorMsg}');
				errText.size = 20;
				errText.wordWrap = true;
				errText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
				errText.color = FlxColor.WHITE;
				errText.scrollFactor.set();
				errText.fieldWidth = FlxG.width - errText.x;
				errText.screenCenter(X);
				var _errText_X = errText.x;
				errText.x = FlxG.width;
				contText = new FlxText(FlxG.width * 0.5,FlxG.height + 100,0,
				#if android
					'Tap the left of the screen to exit or the right of the screen to restart'
				#else
					'Press ENTER to exit, R to reload or O to open options.'
				#end );
				contText.size = 24;
				// contText.x -= contText.width * 0.5;
				contText.screenCenter(X);
				contText.alpha = 0.3;
				contText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
				var reportText = new FlxText(0,FlxG.height - 180,0,'Please report this to the developer of the script/chart listed above');
				reportText.size = 20;
				// reportText.x -= contText.width * 0.5;
				reportText.screenCenter(X);
				var rep_x = reportText.x;
				reportText.x = FlxG.width;
				reportText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);

				// contText.alignment = CENTER;
				contText.color = FlxColor.WHITE;
				contText.scrollFactor.set();
				FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
				FlxTween.tween(finishedText, {y:20},0.5,{ease: FlxEase.expoInOut});
				FlxTween.tween(errText, {x:_errText_X},0.5,{ease: FlxEase.expoInOut});
				FlxTween.tween(contText, {y:FlxG.height - 90},0.5,{ease: FlxEase.expoInOut});
				FlxTween.tween(reportText, {x:rep_x},0.5,{ease: FlxEase.expoInOut});
				add(bg);
				add(finishedText);
				add(errText);
				add(contText);
				add(reportText);
				optionsisyes = true;
				
			}else{

				var finishedText:FlxText = new FlxText(0,20,0, (if(PlayState.isStoryMode) "Week" else "Song") + " " + (if(win) "Won!" else "Failed...") );
				finishedText.size = 34;
				finishedText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
				finishedText.color = FlxColor.WHITE;
				finishedText.scrollFactor.set();
				var _oldScore = getScore();
				var savedScore = saveScore();

				finishedText.screenCenter(X);

				var songText:FlxText = new FlxText(0,70,0, (PlayState.isStoryMode ? StoryMenuState.weekNames[StoryMenuState.curWeek] : (PlayState.stateType == 4 ? PlayState.actualSongName : '${PlayState.SONG.song} ${PlayState.songDiff}')) + ' ${PlayState.SONG.keyCount}K' );
				songText.size = 36;
				songText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
				songText.color = FlxColor.WHITE;
				songText.scrollFactor.set();
				songText.screenCenter(X);
				var comboText:FlxText = new FlxText(20 + SESave.data.guiGap,80,0,'\n\n'
						+(if(PlayState.instance.botPlay) "Botplay " else "") + (!PlayState.isStoryMode ? 'Song performance' : "Week performance")
						+'\n\nSicks - ${PlayState.sicks}'
						+'\nGoods - ${PlayState.goods}'
						+'\nBads - ${PlayState.bads}'
						+'\nShits - ${PlayState.shits}'
						+'\nGhost Taps - ${PlayState.ghostTaps}'
						+'\n\nLast combo: ${PlayState.combo} (Max: ${PlayState.maxCombo})'
						+'\nMisses${if(SESave.data.ghost) "" else " + Ghost Taps"}${if(SESave.data.shittyMiss) ' + Shits' else ''}${if(SESave.data.badMiss) ' + Bads' else ''}${if(SESave.data.goodMiss) ' + Goods' else ''}: ${PlayState.misses}'
						+(savedScore ? '\n\n!!Score: ${_oldScore} > ${PlayState.songScore}' : '\n\nScore: ${PlayState.songScore} / ${_oldScore}')
						+'\nAccuracy: ${HelperFunctions.truncateFloat(PlayState.accuracy,2)}%');
				comboText.size = 28;
				comboText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
				comboText.color = FlxColor.WHITE;
				comboText.scrollFactor.set();

				var settingsText:FlxText = new FlxText(600,75,0,
				'\n\n\n\nSettings:'
				+'\n\n Able To Save Score: ${canSaveScore()}'
				// +'\n Downscroll: ${SESave.data.downscroll}'
				+'\n Ghost Tapping: ${SESave.data.ghost}'
				+'\n Practice: ${SESave.data.practiceMode}${if(PlayState.instance.hasDied)' - Score not saved' else ''}'
				+'\n HScripts: ${QuickOptionsSubState.getSetting("Song hscripts")}' + (QuickOptionsSubState.getSetting("Song hscripts") ? '\n  Script Count:${PlayState.instance.interpCount}' : "")
				+'\n Safe Frames: ${SESave.data.frames}' 
				+'\n HitWindows: ${Ratings.ratingMS("sick")},${Ratings.ratingMS("good")},${Ratings.ratingMS("bad")},${Ratings.ratingMS("shit")} MS'
				+'\n Input Engine: ${PlayState.inputEngineName}, V${MainMenuState.ver}'
				+'\n Song Offset: ${HelperFunctions.truncateFloat(SESave.data.offset + PlayState.songOffset,2)}ms'
				);
				settingsText.size = 20;
				settingsText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
				settingsText.color = FlxColor.WHITE;
				settingsText.scrollFactor.set();

				var letterText:FlxText = new FlxText(settingsText.x + (settingsText.width * 0.25),500,0, Ratings.GenerateLetterRank(PlayState.accuracy));
				if(letterText.text == "N/A") {
					letterText.text = "No Letter Rank";
				}
				// letterText.color = Ratings.getRating(PlayState.accuracy).color;
				FlxTween.color(letterText,1,0xFFFFFFFF,Ratings.getRank(PlayState.accuracy).color);
				letterText.size = 32;
				letterText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
				
				letterText.scrollFactor.set();

				if(savedScore || FlxG.keys.pressed.SHIFT){
					finishedText.text += " | New Personal Best!";
					FlxG.sound.play(SELoader.loadSound('assets/sounds/confirmMenu.ogg'));
					// letterText.scale.x = letterText.scale.y = 1.3;
					FlxTween.tween(letterText.scale,{x:1.1,y:1.1},0.2,{ease:FlxEase.bounceOut,startDelay:0.6});
					FlxTween.tween(letterText.scale,{x:1,y:1},0.4,{ease:FlxEase.bounceOut,startDelay:0.8});
				}

				contText = new FlxText(FlxG.width - SESave.data.guiGap,FlxG.height - 90,0,
				#if android
					'Tap the left of the screen to exit or the right of the screen to restart'
				#else
				'Press ENTER to continue or R to restart.'
				#end );
				
				contText.size = 28;
				contText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
				contText.color = FlxColor.WHITE;
				// contText.x -= contText.width;
				contText.screenCenter(X);
				contText.scrollFactor.set();
				contText.alpha = 0.3;
				// var chartInfoText:FlxText = new FlxText(20,FlxG.height + 50,0,'Offset: ${SESave.data.offset + PlayState.songOffset}ms | Played on ${songName}');
				// chartInfoText.size = 16;
				// chartInfoText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,2,1);
				// chartInfoText.color = FlxColor.WHITE;
				// chartInfoText.scrollFactor.set();
				

				add(bg);
				add(finishedText);
				add(comboText);
				add(contText);
				add(settingsText);
				add(letterText);
				add(songText);
				// add(chartInfoText);
				healthBar.cameras = healthBarBG.cameras = iconP1.cameras = iconP2.cameras = [cam];

				FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
				FlxTween.tween(finishedText, {y:(finishedText.y-=55) + 55},0.5,{ease: FlxEase.bounceOut});
				FlxTween.tween(songText, {y:(songText.y-=55) + 55},0.5,{ease: FlxEase.bounceOut});
				FlxTween.tween(comboText, {x:(comboText.x-=200) + 200},0.5,{ease: FlxEase.bounceOut});
				FlxTween.tween(letterText, {x:(letterText.x+=300) - 300},0.5,{ease: FlxEase.bounceOut});
				FlxTween.tween(settingsText, {x:(settingsText.x+=400)-400},0.5,{ease: FlxEase.bounceOut});
				// for (obj in [finishedText,songText,comboText,settingsText,comboText]){
				// 	obj.scale.x = obj.scale.y = 0;
				// 	FlxTween.tween(obj.scale, {x:1,y:1},1,{ease: FlxEase.bounceOut,startDelay:0.2});
				// }
				// FlxTween.tween(contText, {y:(contText.y-=90) + 90},0.5,{ease: FlxEase.expoInOut});
				// FlxTween.tween(chartInfoText, {y:FlxG.height - 35},0.5,{ease: FlxEase.expoInOut});
				
				FlxTween.tween(contText, {alpha:(contText.alpha=0) + 1},0.5,{ease: FlxEase.bounceOut});

				if(PlayState.logGameplay){

					try{
						var info = '--- Game Info:\n${comboText.text}\n\n${settingsText.text}\n\nCharacters(Dad,GF,BF): ${PlayState.dad.curCharacter},${PlayState.gf.curCharacter},${PlayState.playerCharacter.curCharacter}\n\nScripts:';
						for (i => v in PlayState.instance.interps) {
							info += '\n- $i';
						}
						var eventLog:ActionsFile = {
							info:info,
							notes:PlayState.instance.eventLog,
							bf:PlayState.playerCharacter.curCharacter,
							opp:PlayState.dad.curCharacter,
							gf:PlayState.gf.curCharacter,
							ver:MainMenuState.ver
						};
						var events:String = info + '\n\n--- Hits and Misses:\n\n/ Example Note\n|- TIME\n|- DIRECTION\n|- RATING\n|- IS SUSTAIN\n|- NOTE STRUM TIME\n\\\n\n\n';
						var noteCount = 0;
						for (_ => v in PlayState.instance.eventLog ) {
							events += '\n/\n|- ${v.time}\n|- ${Note.noteDirections[v.direction]}\n|- ${v.rating}\n|- ${v.isSustain}\n|- ${v.strumTime}\n\\';
							if(!v.isSustain && v.rating != "Missed without note")noteCount++;
						}
						var eventsjson:String = haxe.Json.stringify(eventLog);
						events += '\n---\nLog generated at ${Date.now()}, Assumed Note Count: ${noteCount}. USE THE JSON FOR AUTOMATION';
						if(!SELoader.exists("songLogs/"))
							SELoader.createDirectory("songLogs/");
						var curDate = Date.now();
						var songName = if(PlayState.isStoryMode) StoryMenuState.weekNames[StoryMenuState.curWeek] else if (PlayState.stateType == 4) PlayState.actualSongName else '${PlayState.SONG.song} ${PlayState.songDiff}';
						songName.replace(".json","");
						if(PlayState.invertedChart || QuickOptionsSubState.getSetting('Inverted Chart')) songName = songName + "-inverted";
						if(!SELoader.exists('songLogs/${songName}/'))
							SELoader.createDirectory('songLogs/${songName}/');
						SELoader.saveContent('songLogs/${songName}/${curDate.getDate()}-${curDate.getMonth()}-${curDate.getFullYear()}_AT_${curDate.getHours()}-${curDate.getMinutes()}-${curDate.getSeconds()}.log',events);
						SELoader.saveContent('songLogs/${songName}/${curDate.getTime()}.json',eventsjson);
					}catch(e){trace("Something went wrong when trying to output event log! " + e.message);}
				}
				// try{TitleState.saveScore(PlayState.accuracy);}catch(e){trace("e");}
			}



	}
	var shouldveLeft = false;
	function retMenu(){
		FlxTween.globalManager.clear();
		if (PlayState.isStoryMode){FlxG.switchState(new StoryMenuState());return;}
		PlayState.actualSongName = ""; // Reset to prevent issues
		if (shouldveLeft) {Main.game.forceStateSwitch(new MainMenuState());return;}
		
		switch (PlayState.stateType)
		{
			case 2:MusicBeatState.returningFromClass=true;FlxG.switchState(new onlinemod.OfflineMenuState());
			case 4:MusicBeatState.returningFromClass=true;FlxG.switchState(new multi.MultiMenuState());
			case 5:MusicBeatState.returningFromClass=true;FlxG.switchState(new osu.OsuMenuState());
				

			default:MusicBeatState.instance.goToLastClass(PlayState);
		}
		shouldveLeft = true;
		// if (PlayState.isStoryMode){FlxG.switchState(new StoryMenuState());return;}
		// PlayState.actualSongName = ""; // Reset to prevent issues
		// PlayState.instance.persistentUpdate = true;
		// if (shouldveLeft){
		// 	Main.game.forceStateSwitch(new MainMenuState());

		// }else{
		// 	FlxTween.tween(FlxG.camera.scroll,{y:-100},0.2);
		// 	MusicBeatState.instance.goToLastClass();
		// 	// switch (PlayState.stateType)
		// 	// {
		// 	// 	case 2:FlxG.switchState(new onlinemod.OfflineMenuState());
		// 	// 	case 4:FlxG.switchState(new multi.MultiMenuState());
		// 	// 	case 5:FlxG.switchState(new osu.OsuMenuState());
					

		// 	// 	default:FlxG.switchState(new FreeplayState());
		// 	// }
		// }
		// shouldveLeft = true;
		return;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(FlxG.keys.pressed.ESCAPE){
			retMenu();
		}
		if(updateBF && PlayState.playerCharacter != null){
			PlayState.playerCharacter.update(elapsed);
		}

		if (ready){
			if (controls.ACCEPT){
				retMenu();
			}
			#if android
				if(FlxG.mouse.justPressed){
					trace(FlxG.mouse.screenX / FlxG.width);
					if((FlxG.mouse.screenX / FlxG.width) <= .5){
						retMenu();
					}else{
						if(win){FlxG.resetState();}else{restart();}
					}
				}
			#end

			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S){saveScore(true);}
			if (FlxG.keys.justPressed.R){if(win){FlxG.resetState();}else{restart();}}
			if (FlxG.keys.justPressed.O && optionsisyes){
				SearchMenuState.doReset = false;
				OptionsMenu.lastState = PlayState.stateType + 10;
				FlxG.switchState(new OptionsMenu());
			}
			if(PlayState.instance != null)PlayState.instance.testanimdebug();
		}else if (!shownResults){
			if(FlxG.keys.justPressed.ANY){
				PlayState.playerCharacter.animation.finishCallback = null;
				finishNew();
			}
		}else{
			if(readyTimer > 2){
				ready=true;
				// FlxTween.tween(,{alpha:1},0.5);
			}
			readyTimer += elapsed;
			contText.alpha = readyTimer - 1;
		}

	}
	override function draw(){

		if(updateBF && PlayState.playerCharacter != null){
			PlayState.playerCharacter.draw();
		}
		super.draw();

	}
	function restart() {
		ready = false;
		// FlxG.sound.music.stop();
		// FlxG.sound.play(Paths.music('gameOverEnd'));
		if(isError){
			FlxG.resetState();
			if (shouldveLeft){ // Error if the state hasn't changed and the user pressed r already
				MainMenuState.handleError("Caught softlock!");
			}
			shouldveLeft = true;
			return;
		}
		// Holyshit this is probably a bad idea but whatever
		// PlayState.instance.resetInterps();
		// Conductor.songPosition = 0;
		// Conductor.songPosition -= Conductor.crochet * 5;
		
		// PlayState.instance.persistentUpdate = true;
		// PlayState.instance.resetScore();
		// PlayState.songStarted = false;

		// PlayState.strumLineNotes = null;
		// PlayState.instance.generateSong();
		// PlayState.instance.startCountdown();
		// close();
		FlxG.resetState();
	}
	override function destroy()
	{
		if (music != null){music.destroy();}

		super.destroy();
	}

}