package;
#if (flixel > "5.6.2")
#error "Super Engine is not compatible with Flixel 5.7 or above";
#end
import openfl.display.BlendMode;
import openfl.text.TextFormat;
import openfl.display.Application;
import lime.app.Application as LimeApp;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.UncaughtErrorEvent;
import sys.thread.*;
import se.objects.ToggleLock;

// import crashdumper.CrashDumper;
// import crashdumper.SessionData;
import Overlay;

import haxe.CallStack;
import sys.FileSystem;
import sys.io.File;

class Main extends Sprite
{
	public static var errorMessage = "";
	public static var instance:Main;
	public static var funniSprite:Sprite;
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 120; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets 

	#if android
		public static var grantedPerms:Array<String> = [];
	#end

	public static var watermarks = true; // Whether to put Kade Engine liteartly anywhere

	public static var game:FlxGameEnhanced;

	public static var fpsCounter:Overlay;
	public static var console:Console;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void {

		// quick checks 
		FuckState.hook();
		SEProfiler.init();
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null){
			init();
		}else{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE)) removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	private function setupGame():Void
	{
		instance = this;
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1){
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}
		// var crashDumper = new CrashDumper(SessionData.generateID("FNFBR-"));
		#if !debug
			initialState = TitleState;
		#end

		// Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		
		addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtErrorHandler);
		try{
			
			funniSprite = new Sprite();
			game = new FlxGameEnhanced(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen);
			FlxG.mouse.enabled = false;
			addChild(funniSprite);
			funniSprite.addChild(game);
			LoadingScreen.show();
			fpsCounter = new Overlay(0, 0);
			funniSprite.addChild(fpsCounter);
			console = Console.instance;
			#if !mobile
			addChild(console);
			addChild(console.commandBox);
			#end

			// fpsCounter.visible = false;
			// fpsOverlay = new Overlay(0, 0);
			// addChild(fpsCounter);

			// fpsCounter = new FPS(10, 3, 0xFFFFFF);
			// addChild(fpsCounter);
			toggleFPS(SESave.data.fps);
		}catch(e){
			FuckState.FUCK(null,'Error occured while trying to load Flixel.\nDid you make sure to extract the game? or did you put it in the wrong folder?\nThe '+
			#if(windows)"exe" #else "executable" #end
			+ 'Should be next to the manifest or assets folder!\nError:\n${e.message}',true,true,true);
		}

	}
	function uncaughtErrorHandler(event:UncaughtErrorEvent):Void { // Yes this is copied from the wiki, fuck you
		var message:String = "";
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);

		for (stackItem in callStack){
			switch (stackItem){
				case FilePos(s, file, line, column):
					message += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}
		FuckState.FUCK(null,message,true,true);
		// uncaughtError(text);
	}
	// var fpsOverlay:Overlay;

	public function toggleFPS(fpsEnabled:Bool):Void fpsCounter.visible = fpsEnabled;

	public function changeFPSColor(color:FlxColor) fpsCounter.textColor = color;

	public function setFPSCap(cap:Float) openfl.Lib.current.stage.frameRate = cap;

	public function getFPSCap():Float return openfl.Lib.current.stage.frameRate;

	public function getFPS():Float return fpsCounter.currentFPS;
	public function onCrash(e:UncaughtErrorEvent){
		FuckState.FUCK(e);
	}
	public static var renderLock:ToggleLock = new ToggleLock();
	public static var renderLockButCooler:ToggleLock = new ToggleLock();
	#if(target.threaded)
	override function __enterFrame(_){
		try{
			SEProfiler.update();
			if(game != null){

				if(FlxG.keys.justPressed.F1) throw('Manual error');
				// if(game.blockDraw || game.blockUpdate){
				// 	renderLockButCooler.wait();
				// 	super.__enterFrame(_);
				// 	renderLockButCooler.lock();
				// 	renderLock.release();
				// }else{
				super.__enterFrame(_);
				// }
			}else{
				super.__enterFrame(_);
				// trace('h');
			}
		}catch(e){
			FuckState.FUCK(e,"Main.onEnterFrame");
		}
	}
	#end
}

// Made specifically for Super Engine. Adds some extensions to FlxGame to allow it to handle errors
// If you use this at all, Please credit me
class FlxGameEnhanced extends FlxGame{
	static var blankState:FlxState = new FlxState();
	public function forceStateSwitch(state:FlxState){ // Might be a bad idea but allows an error to force a state change to Mainmenu instead of softlocking
		_requestedState = state;
		switchState();
	}
	public var blockUpdate:Bool = false;
	public var blockDraw:Bool = false;
	public var blockEnterFrame:Bool = false;

	var requestAdd = false;
	override function create(_){
		try{
			super.create(_);
		}catch(e){
			FuckState.FUCK(e,"FlxGame.Create");
		}
	}
	override function onEnterFrame(_){
		try{
			if(requestAdd){
				requestAdd = false;
				Main.funniSprite.addChildAt(this,0);
				blockUpdate = blockEnterFrame = blockDraw = false;
				FlxG.autoPause = _oldAutoPause;
				_oldAutoPause = false;

				if(_lostFocusWhileLoading != null){
					onFocusLost(_lostFocusWhileLoading);_lostFocusWhileLoading = null;
				}

			}

			if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.F1){
				MainMenuState.handleError("Manually triggered force exit");
			}
			if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.F4){
				throw('Manually triggered crash');
			}
			if(blockEnterFrame) {
				_elapsedMS = (_total = ticks = getTicks()) - _total;
			}else{
				super.onEnterFrame(_);
			}

		}catch(e){
			FuckState.FUCK(e,"FlxGame.onEnterFrame");
		}
	}
	public var funniLoad:Bool = false;
	function _update(){
		if (!_state.active || !_state.exists)
			return;

		#if FLX_DEBUG
		if (FlxG.debugger.visible)
			ticks = getTicks();
		#end

		updateElapsed();

		FlxG.signals.preUpdate.dispatch();

		#if FLX_POST_PROCESS
		if (postProcesses[0] != null)
			postProcesses[0].update(FlxG.elapsed);
		#end

		#if FLX_SOUND_SYSTEM
		FlxG.sound.update(FlxG.elapsed);
		#end
		FlxG.plugins.update(FlxG.elapsed);

		FlxG.signals.postUpdate.dispatch();

		#if FLX_DEBUG
		debugger.stats.flixelUpdate(getTicks() - ticks);
		#end

		filters = filtersEnabled ? _filters : null;
	}
	var _oldAutoPause:Bool = false;
	var hasUpdated = false;
	#if(flixel > "5.5.2")
	public var _requestedState(get,set):flixel.util.typeLimit.NextState;
	public function set__requestedState(e:flixel.util.typeLimit.NextState) return _nextState=e;
	public function get__requestedState() return _nextState;
	#end
	override function switchState():Void
	{
		SEProfiler.qStart('switch_state');
		try{
			// Basic reset stuff
			FlxG.cameras.reset();
			FlxG.inputs.onStateSwitch();
			#if FLX_SOUND_SYSTEM
			FlxG.sound.destroy();
			#end

			FlxG.signals.preStateSwitch.dispatch();

			#if FLX_RECORD
			FlxRandom.updateStateSeed();
			#end

			// Destroy the old state (if there is an old state)
			if (_state != null)
				_state.destroy();

			// we need to clear bitmap cache only after previous state is destroyed, which will reset useCount for FlxGraphic objects
			FlxG.bitmap.clearCache();
			if(_nextState == null) throw('Switch state called with a null state?');

			// Finally assign and create the new state
			_state = _nextState.createInstance();
			_state._constructor = _nextState;
			_nextState = null;

			if (_gameJustStarted)
				FlxG.signals.preGameStart.dispatch();

			FlxG.signals.preStateCreate.dispatch(_state);

			_state.create();

			if (_gameJustStarted)
				gameStart();

			#if FLX_DEBUG
			debugger.console.registerObject("state", _state);
			#end

			FlxG.signals.postStateSwitch.dispatch();
		}catch(e){
			FuckState.FUCK(e,"FlxGame.SwitchState");
		}
		SEProfiler.qStamp('switch_state');
	}
	override function update(){
		
		try{
			SEProfiler.start('update');

			#if(target.threaded && !hl)
				if(_state != _requestedState && _requestedState != null && SESave.data.doCoolLoading){
					blockUpdate = blockEnterFrame = blockDraw = true;
					Main.funniSprite.removeChild(this);
					_oldAutoPause = FlxG.autoPause;
					FlxG.autoPause = false;
					visible = false;
					hasUpdated = false;
					sys.thread.Thread.create(() -> { 
						switchState();
						requestAdd = true;
						visible = true;
					});
					return;
				}
			#end
			if(blockUpdate) _update(); else {
				hasUpdated = true;
				super.update();

				if (FlxG.keys.justPressed.F11) SESave.data.fullscreen = (FlxG.fullscreen = !FlxG.fullscreen);
			}
			SEProfiler.stamp('update');
		}catch(e){
			FuckState.FUCK(e,"FlxGame.Update");
		}
	}
	override function draw(){
			try{
				if (blockDraw || _state == null || !_state.visible || !_state.exists || !hasUpdated) return;
				SEProfiler.start('draw');
				#if FLX_DEBUG
				if (FlxG.debugger.visible) ticks = getTicks();
				#end
				try{
					FlxG.signals.preDraw.dispatch();
				}catch(e){
					FuckState.FUCK(e,"FlxGame.Draw:preDraw"); return;
				}
				if (FlxG.renderTile)
					flixel.graphics.tile.FlxDrawBaseItem.drawCalls = 0;


				#if FLX_POST_PROCESS
				try{
				if (postProcesses[0] != null)
					postProcesses[0].capture();
				}catch(e){
					FuckState.FUCK(e,"FlxGame.Draw:postProcess"); return;
				}
				#end
				try{

					FlxG.cameras.lock();
				}catch(e){
					FuckState.FUCK(e,"FlxGame.Draw:camerasLock"); return;
				}
				try{
					FlxG.plugins.draw();
				}catch(e){
					FuckState.FUCK(e,"FlxGame.Draw:pluginDraw"); return;
				}
				try{
					_state.draw();
				}catch(e){
					FuckState.FUCK(e,"FlxGame.Draw:stateDraw"); return;
				}
				if (FlxG.renderTile)
				{
					try{
						FlxG.cameras.render();
					}catch(e){
						FuckState.FUCK(e,"FlxGame.Draw:cameraRender"); return;
					}
					#if FLX_DEBUG
					debugger.stats.drawCalls(FlxDrawBaseItem.drawCalls);
					#end
				}
				try{
					FlxG.cameras.unlock();
				}catch(e){
					FuckState.FUCK(e,"FlxGame.Draw:cameraUnlock"); return;
				}
				try{
					FlxG.signals.postDraw.dispatch();
				}catch(e){
					FuckState.FUCK(e,"FlxGame.Draw:postDraw"); return;
				}
				#if FLX_DEBUG
				debugger.stats.flixelDraw(getTicks() - ticks);
				#end
				SEProfiler.stamp('draw');
			}catch(e){
				FuckState.FUCK(e,"FlxGame.Draw:function"); return;
			}
	}
	var _lostFocusWhileLoading:flash.events.Event = null;
	override function onFocus(_){
		try{
			if(blockEnterFrame)
				_lostFocusWhileLoading = null;
			else
				super.onFocus(_);
		}catch(e){
			FuckState.FUCK(e,"FlxGame.onFocus");
		}
	}
	override function onFocusLost(_){
		try{
			if(blockEnterFrame && _oldAutoPause) _lostFocusWhileLoading = _; 
			else if(!blockEnterFrame && onlinemod.OnlinePlayMenuState.socket == null) 
				super.onFocusLost(_);
		}catch(e){
			FuckState.FUCK(e,"FlxGame.onFocusLost");
		}
	}
}