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



class ErrorSubState extends MusicBeatSubstate {
	public var curSelected:Int = 0;
	public var music:FlxSound;
	public var perSongOffset:FlxText;
	public var offsetChanged:Bool = false;
	public var win:Bool = true;
	public var ready = false;
	public var readyTimer:Float = 0;
	public var errorMsg:String = "";
	public static var instance:ErrorSubState;
	public static var fadeOut:Bool = true;
	public function new(x:Float, y:Float,?error:String = "",force:Bool = false) {
		instance = this;
		endingMusic = null;
		errorMsg = error;
			// PlayState.instance.paused = true;

		FlxG.state.persistentUpdate = false;
		if(PlayState.instance != null){
			PlayState.instance.generatedMusic = PlayState.instance.handleTimes = PlayState.instance.acceptInput = false;
			PlayState.instance.camHUD.alpha = PlayState.instance.camTOP.alpha = 1;
		}
		super();



		FlxG.state.persistentUpdate = false;
		cam = new FlxCamera();
		FlxG.cameras.add(cam);
		// FlxG.cameras.setDefaultDrawTarget(cam,true);
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]]; 
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();

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
			'Tap the left of the screen to return to the main menu or the right of the screen to reload'
		#else
			'Press ENTER to return to the main menu,\n R to reload the state or O to open your options.'
		#end );
		contText.size = 24;
		// contText.x -= contText.width * 0.5;
		contText.screenCenter(X);
		contText.alpha = 0.3;
		contText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
		var reportText = new FlxText(0,FlxG.height - 180,0,'Please report this to the developer of the script listed above');
		reportText.size = 24;
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
		FlxG.camera.zoom = 1;
				
			

	}

	public static var endingMusic:Sound;
	public var cam:FlxCamera;
	var optionsisyes:Bool = false;
	var shownResults:Bool = false;
	public var contText:FlxText;


	var shouldveLeft = false;
	function retMenu(){
		if (PlayState.isStoryMode){FlxG.switchState(new StoryMenuState());return;}
		PlayState.actualSongName = ""; // Reset to prevent issues
		Main.game.forceStateSwitch(new MainMenuState(true));
		shouldveLeft = true;
		return;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(FlxG.keys.pressed.ESCAPE){
			retMenu();
		}

		if (ready){


			if (controls.ACCEPT) retMenu();
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

			if (FlxG.keys.justPressed.R){if(win){FlxG.resetState();}else{restart();}}
			if (FlxG.keys.justPressed.O){
				SearchMenuState.doReset = false;
				OptionsMenu.lastState = PlayState.stateType + 10;
				FlxG.switchState(new OptionsMenu());
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
		super.draw();

	}
	function restart()
	{
		ready = false;
		// FlxG.sound.music.stop();
		// FlxG.sound.play(Paths.music('gameOverEnd'));
		FlxG.resetState();
		if (shouldveLeft){ // Error if the state hasn't changed and the user pressed r already
			MainMenuState.handleError("Caught softlock!");
		}
		shouldveLeft = true;
	}
	override function destroy()
	{
		if (music != null){music.destroy();}

		super.destroy();
	}

}