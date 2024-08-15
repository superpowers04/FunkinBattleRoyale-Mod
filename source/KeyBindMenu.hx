package;

/// Code created by Rozebud for FPS Plus (thanks rozebud)
// modified by KadeDev for use in Kade Engine/Tricky

import flixel.input.gamepad.FlxGamepad;
import flixel.util.FlxAxes;
import flixel.FlxSubState;
import Options.Option;
import flixel.input.FlxInput;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import lime.utils.Assets;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.input.FlxKeyManager;


using StringTools;

class KeyBindMenu extends FlxSubState
{

	var keyTextDisplay:FlxTypedGroup<FlxText> = new FlxTypedGroup<FlxText>();
	var keyWarning:FlxText;
	var warningTween:FlxTween;
	var keyText:Array<Array<String>> = [
		["UI LEFT", "UI DOWN", "UI UP", "UI RIGHT", "ALT LEFT", "ALT DOWN", "ALT UP", "ALT RIGHT","RESET","MUTE","VOLUME DOWN","VOLUME UP"],
		["LEFT","DOWN"],
		["LEFT","MIDDLE","DOWN"],
		["LEFT", "DOWN", "UP", "RIGHT", "ALT LEFT", "ALT DOWN", "ALT UP", "ALT RIGHT"],
		["LEFT", "DOWN", "MIDDLE", "UP", "RIGHT"],
		["KEY 1", "KEY 2", "KEY 3", "KEY 4", "KEY 5", "KEY 6"],
		["KEY 1", "KEY 2", "KEY 3", "KEY 4", "KEY 5", "KEY 6", "KEY 7"],
		["KEY 1", "KEY 2", "KEY 3", "KEY 4", "KEY 5", "KEY 6", "KEY 7", "KEY 8"],
		["KEY 1", "KEY 2", "KEY 3", "KEY 4", "KEY 5", "KEY 6", "KEY 7", "KEY 8", "KEY 9"],
		["KEY 1", "KEY 2", "KEY 3", "KEY 4", "KEY 5", "KEY 6", "KEY 7", "KEY 8", "KEY 9", "KEY 10"],
		["KEY 1", "KEY 2", "KEY 3", "KEY 4", "KEY 5", "KEY 6", "KEY 7", "KEY 8", "KEY 9", "KEY 10", "KEY 11"],
		["KEY 1", "KEY 2", "KEY 3", "KEY 4", "KEY 5", "KEY 6", "KEY 7", "KEY 8", "KEY 9", "KEY 10", "KEY 11", "KEY 12"],
		["KEY 1", "KEY 2", "KEY 3", "KEY 4", "KEY 5", "KEY 6", "KEY 7", "KEY 8", "KEY 9", "KEY 10", "KEY 11", "KEY 12","KEY 13"],
		["KEY 1", "KEY 2", "KEY 3", "KEY 4", "KEY 5", "KEY 6", "KEY 7", "KEY 8", "KEY 9", "KEY 10", "KEY 11", "KEY 12","KEY 13","KEY 14"],
		["KEY 1", "KEY 2", "KEY 3", "KEY 4", "KEY 5", "KEY 6", "KEY 7", "KEY 8", "KEY 9", "KEY 10", "KEY 11", "KEY 12","KEY 13","KEY 14","KEY 15"],
		["KEY 1", "KEY 2", "KEY 3", "KEY 4", "KEY 5", "KEY 6", "KEY 7", "KEY 8", "KEY 9", "KEY 10", "KEY 11", "KEY 12","KEY 13","KEY 14","KEY 15","KEY 16"],
		["KEY 1", "KEY 2", "KEY 3", "KEY 4", "KEY 5", "KEY 6", "KEY 7", "KEY 8", "KEY 9", "KEY 10", "KEY 11", "KEY 12","KEY 13","KEY 14","KEY 15","KEY 16","KEY 17"],
		["KEY 1", "KEY 2", "KEY 3", "KEY 4", "KEY 5", "KEY 6", "KEY 7", "KEY 8", "KEY 9", "KEY 10", "KEY 11", "KEY 12","KEY 13","KEY 14","KEY 15","KEY 16","KEY 17","KEY 18"],
	];
	var keyModeText:Array<String> = [
		'User Interface/Legacy Input',null,null,"4K(Seperate from UI/Legacy Input)"
	];
	var keyAlt:Array<String> = ["LEFT ARROW", "DOWN ARROW", "UP ARROW", "RIGHT ARROW"];
	var defaultKeys:Array<String> = ["A", "S", "W", "D", "Z", "X", "N", "M", "R"];
	var defaultGpKeys:Array<String> = ["DPAD_LEFT", "DPAD_DOWN", "DPAD_UP", "DPAD_RIGHT"];
	var curSelected:Int = 0;

	var keys:Array<Array<String>> = SESave.data.keys;
	var tempKey:String = "";
	var blacklist:Array<String> = ["LEFT", "DOWN", "UP", "RIGHT","ESCAPE", "ENTER", "BACKSPACE", "TAB","ONE","TWO","SEVEN","THREE"];

	var blackBox:FlxSprite;
	var infoText:FlxText;
	var selectorText:FlxText;
	var state:String = "select";
	var keyMode:Int = 3;

	public static function getKeyBindsString():String{
		if (KeyBinds.gamepad) {
			return '${SESave.data.gpleftBind}-${SESave.data.gpdownBind}-${SESave.data.gpupBind}-${SESave.data.gprightBind}';
		}
		return '${SESave.data.leftBind}-${SESave.data.downBind}-${SESave.data.upBind}-${SESave.data.rightBind} Alt ${SESave.data.AltleftBind}-${SESave.data.AltdownBind}-${SESave.data.AltupBind}-${SESave.data.AltrightBind}';
	}

	override function create() {

		var _keys:Array<Array<String>> =SESave.data.keys;
		for(count => keyArr in _keys){
			keys[count] = keyArr.copy();
			for(i => v in KeyBinds.defaultKeys[count]){
				if(keys[count][i] == null){
					keys[count][i] = v;
				}
			}
		}
	
		//FlxG.sound.playMusic('assets/music/configurator' + TitleState.soundExt);

		persistentUpdate = true;



		blackBox = new FlxSprite(0,0).makeGraphic(FlxG.width,FlxG.height,FlxColor.BLACK);
		add(blackBox);

		infoText = new FlxText(-10, 580, 1280, '< ${keyMode} >. Press TAB to switch\n(Escape to save, Backspace to leave without saving.)', 72);
		infoText.scrollFactor.set(0, 0);
		infoText.setFormat(CoolUtil.font, 24, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		infoText.borderSize = 2;
		infoText.borderQuality = 3;
		infoText.screenCenter(FlxAxes.X);
		add(infoText);
		selectorText = new FlxText(0,0, 45, ">", 72);
		selectorText.scrollFactor.set(0, 0);
		selectorText.setFormat(CoolUtil.font, 42, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		selectorText.borderSize = 2;
		selectorText.borderQuality = 3;
		selectorText.screenCenter(FlxAxes.X);
		add(selectorText);
		add(keyTextDisplay);

		infoText.alpha = blackBox.alpha = 0;

		// FlxTween.tween(keyTextDisplay, {alpha: 1}, 1, {ease: FlxEase.expoInOut});
		FlxTween.tween(infoText, {alpha: 1}, 1.4, {ease: FlxEase.expoInOut});
		FlxTween.tween(blackBox, {alpha: 0.7}, 1, {ease: FlxEase.expoInOut});
		FlxTween.tween(selectorText, {alpha: 1}, 1, {ease: FlxEase.expoInOut});
		for (i in keyTextDisplay) {i.alpha=0;FlxTween.tween(i, {alpha: 1}, 1, {ease: FlxEase.expoInOut});}
		OptionsMenu.instance.acceptInput = false;

		textUpdate();

		super.create();
	}

	var frames = 0;

	override function update(elapsed:Float)
	{
		#if (!FLX_NO_GAMEPAD)
			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		#end
		if (frames <= 10) frames++;

		#if mobile
			infoText.text = '\n(Tap the screen or press Escape to save, Backspace to leave without saving. )\n${lastKey != "" ? lastKey + " is blacklisted!" : ""}'; //'//Shitty haxe syntax moment
		#else
			infoText.text = (keyText[keyMode - 1] == null ? "|":"<")+' ' + (keyModeText[keyMode] ?? '${keyMode + 1}K') + (keyText[keyMode + 1] == null ? " |":" >") + '\nPress Left/Right to switch\nEscape to save, Backspace to leave without saving.'+(lastKey == "" ? "" : '\n$lastKey is blacklisted!');
		#end

		switch(state){

			case "select":
				if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.UP){
					SELoader.playSound('assets/sounds/scrollMenu.ogg',true);
					changeItem(-1);
				}else if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.DOWN){
					SELoader.playSound('assets/sounds/scrollMenu.ogg',true);
					changeItem(1);
				}
				#if !mobile
				else if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.LEFT){
					lastLength = -1;
					if(keyText[keyMode - 1] == null){
						
						SELoader.playSound('assets/sounds/cancelMenu.ogg',true);
					}else{
						keyMode--;
						SELoader.playSound('assets/sounds/scrollMenu.ogg',true);
					}
					
				}else if (FlxG.keys.justPressed.D || FlxG.keys.justPressed.RIGHT){
					lastLength = -1;
					if(keyText[keyMode + 1] == null){
						SELoader.playSound('assets/sounds/cancelMenu.ogg',true);
					}else{
						keyMode++;
						SELoader.playSound('assets/sounds/scrollMenu.ogg',true);
					}
				}
				#end

				if (FlxG.keys.justPressed.ENTER){
					SELoader.playSound('assets/sounds/scrollMenu.ogg',true);
					state = "input";
				}else if(FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE #if(mobile) || FlxG.mouse.justReleased #end){
					quit();
				}

			case "input":
				tempKey = keys[keyMode][curSelected];
				keys[keyMode][curSelected] = "?";
				textUpdate();
				state = "waiting";

			case "waiting":
				if(FlxG.keys.justPressed.ESCAPE){
					keys[keyMode][curSelected] = tempKey;
					state = "select";
					SELoader.playSound('assets/sounds/confirmMenu');
				}else if(FlxG.keys.justPressed.ENTER){
					addKey(KeyBinds.defaultKeys[keyMode][curSelected]);
					save();
					state = "select";
				}else if(FlxG.keys.justPressed.ANY){
					addKey(FlxG.keys.getIsDown()[0].ID.toString());
					save();
					state = "select";
				}
				CoolUtil.toggleVolKeys(true);


			case "exiting":


			default:
				state = "select";

		}

		if(FlxG.keys.justPressed.ANY) textUpdate();

		super.update(elapsed);
		
	}
	var lastLength = 0;
	function textUpdate(){

		// keyTextDisplay.text = "\n\n";
		var mode = keyText[keyMode];
		var keyList = keys[keyMode];
		var AMOUNT:Int = mode.length;
		// CoolUtil.clearFlxGroup(keyTextDisplay);
		if(AMOUNT != lastLength){
			curSelected = 0;
			lastLength = keyTextDisplay.members.length;
			// 	var e = keyTextDisplay.members[keyTextDisplay.members.length];
			// 	if(e == null) break;
			// 	e.destroy();
			// }
			for (i in keyTextDisplay.members){
				i.destroy();
			}
			while(keyTextDisplay.members.pop() != null){}
		}
		var size:Int = 32;
		for (i in 0...AMOUNT){
			var keyText = keyTextDisplay.members[i];
			var text = '${mode[i]}:${keyList[i]}';
			if(keyMode == 3 && keyAlt[i] != null) text += ' / ${keyAlt[i]}';
			if(keyText == null || text != keyText.text){

				if(keyText == null){
					var _keyText = new FlxText(0,100+(50*(1-(AMOUNT / 18)))+ ((i / AMOUNT) * (AMOUNT * size)), 1220, text, 72);
					_keyText.scrollFactor.set(0, 0);
					_keyText.setFormat(CoolUtil.font, size, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
					_keyText.borderSize = 2;
					_keyText.borderQuality = 3;
					_keyText.screenCenter(FlxAxes.X);
					keyTextDisplay.add(_keyText);
					keyText=_keyText;
				}else{
					keyText.text=text;
					keyText.screenCenter(FlxAxes.X);
				}
			}
			if(i == curSelected){
				selectorText.y = keyText.y;
				selectorText.x = keyText.x - 40;
			}
			// var i=i+AMOUNT;
			// var part = mode[i];
			// if(part != null){
			// 	keyTextDisplay.text += ' | '+((i == curSelected) ? ">" : "*")+'$part:${keys[keyMode][i]}';
			// 	if(keyMode == 3 && keyAlt[i] != null) keyTextDisplay.text += ' / ${keyAlt[i]}';
			// }
			// keyTextDisplay.text+='\n';
			// keyTextDisplay.x=  - offset;
			// textStart + str + ": " + keys[keyMode][i] + " / " + (keyMode == 3 && keyAlt[i] != null ? keyAlt[i] : "") + "\n";
		}

		// for(i => str in keyText[keyMode]){

		// 	var textStart = (i == curSelected) ? "> " : "  ";
		// 	keyTextDisplay.text += textStart + str + ": " + keys[keyMode][i] + " / " + (keyMode == 3 && keyAlt[i] != null ? keyAlt[i] : "") + "\n";

		// }
		

		

	}

	function save(){

		var _keys = SESave.data.keys = [];
		for(count => keyArr in keys){
			_keys[count] = keyArr.copy();
			if(keyText[count] == null) continue;
			for(i in 0...keyText[count].length){
				if(_keys[count][i] != null) continue;
				_keys[count][i] = "F12";
			}
			
		}
		KeyBinds.keyCheck();
		PlayerSettings.player1.controls.loadKeyBinds();

	}

	function quit(){

		state = "exiting";

		save();

		OptionsMenu.instance.acceptInput = true;
		// for (i in keyTextDisplay.members) FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.expoInOut});
		FlxTween.tween(blackBox, {alpha: 0}, 1.1, {ease: FlxEase.expoInOut, onComplete: function(flx:FlxTween){close();}});
		FlxTween.tween(infoText, {alpha: 0}, 1, {ease: FlxEase.expoInOut});
		keyTextDisplay.visible=false;

		// FlxTween.tween(keyTextDisplay, {alpha: 0}, 1, {ease: FlxEase.expoInOut});

	}

	public var lastKey:String = "";

	function addKey(r:String){

		var shouldReturn:Bool = true;
		if (blacklist.contains(r)){
			keys[keyMode][curSelected] = tempKey;
			lastKey = r;
			SELoader.playSound('assets/sounds/cancelMenu');
			return;
		}
		
		for(i => v in keys[keyMode]){
			if(v == r) keys[keyMode][i] = null;
			// if (blacklist.contains(v)){
			// 	keys[keyMode][i] = null;
			// 	lastKey = v;
			// 	return;
			// }
		}

		lastKey = "";

		if(shouldReturn){
			keys[keyMode][curSelected] = r;
			SELoader.playSound('assets/sounds/scrollMenu');
			changeItem(1);
		}

	}

	function changeItem(_amount:Int = 0)
	{
		curSelected += _amount;
				
		if (curSelected >= keys[keyMode].length) curSelected = 0;
		if (curSelected < 0) curSelected = keys[keyMode].length - 1;
	}
}