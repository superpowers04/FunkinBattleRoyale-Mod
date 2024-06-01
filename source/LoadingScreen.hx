package;

import flash.display.Sprite;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flash.display.BitmapData;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import lime.app.Application;

@:NullSafety(StrictThreaded) class LoadingScreen extends Sprite{
	public static var object:LoadingScreen;
	public static var isVisible = false;
	public static var canShow:Bool = true;

	public static var loadingText(default,set):String = "";
	public static function set_loadingText(text:String){
		loadingText = text;
		// if(LoadingScreen.object != null && LoadingScreen.object.visible && SESave.data.doCoolLoading) {

		// 	LoadingScreen.object.updateText();
		// 	// Main.instance.game.blockDraw=Main.instance.game.blockUpdate = true;
		// 	Main.funniSprite.removeChildAt(0);
		// 	@:privateAccess var back = lime.app.Application.current.__backend;
		// 	// @:privateAccess back.handleRenderEvent();
		// 	if(back.handle != null)
		// 		@:privateAccess lime._internal.backend.native.NativeCFFI.lime_application_update(back.handle);
		// 	// Main.instance.game.blockDraw=Main.instance.game.blockUpdate = false;
		// 	// Main.funniSprite.addChildAt(Main.game,1);
		// }
		return text;
	}
	// var _loadingText:String = "";
	var funni = false;
	var textField:TextField;
	var tipTextField:TextField;
	// var loadingText:Alphabet;
	var loadingIcon:Sprite;
	var vel:Float = 0;
	static var tips:Array<String> = [
		"You can drag a PNG or XML of a character into the game to import them.",
		"Unfortunately, your mother",
		"You can drag any FNF json chart into the game and play it.\n Some weird engines might not work though..",
		"With threaded loading, this loading screen has a chance of crashing\nbecause of Flixel trying to make an FlxText at the wrong time...",
		"By default, the only characters available are GF and BF.",
		"Enable Content Creation Mode for some stuff that might help with making packs.",
		"You've just wasted your time looking at this....",
		"This engine is buggy as hell.\nFeel free to report any bugs you find on the Discord server.",
		"Hey, look Mom! I'm on a loading screen!!!",
		"I'm here to pad out the loading screen messages. How am I doing? :3",
		"goober",
		"l + bozo + ratio + skill issue + bruh",
		"Never do drugs, you'll probably die",
		"Lua >>> python, fight me",
		'You opened the game at ${Date.now()}',
		#if windows
		"Totally real error! Delete system32 to fix!!!! hah got you so good...\ndon't actually delete that please",
		#elseif !mobile
		"Totally real error! Run 'sudo rm -rf /' to fix!!!! hah got you so good...\nNote that will delete your entire drive. Do not run it",
		#end
		'You\'re currently on ${MainMenuState.ver}. You probably knew that though...',
		'Also try Terraria. I mean it\'s a different genre but the game\'s still cool',
		"This game can still crash on stupid shit even though it has so much error checking...",
		// 'This game\'s native resolution is 1280x720. You started the game with ${Application.current.window.width}x${Application.current.window.height}.',
		"Did you know that Content Creation Mode enables a debug console?\nYou can use F10 for it..",
		"Did you know that Content Creation Mode enables an object mover?\nYou can use Shift+F8 for it..",
		"Did you know that missing a note will make you lose health?",
		"If you have practice mode disabled, you will die at 0 health.\n Otherwise your score will just not save",
		"For the first year or so, offsets were fucked. Then I removed Pico",
		"your mother",
		"your mother is a lesbian and thats a threat",
		"qhar?!?!?!",
		"did you know that- uhh i forgor",
		"Powered by\nThe bane of my existance :3",
		"I'm going to kill you and all the cake is gone",
		"You will be baked, and then there will be cake",
		"The cake is a lie",
		"Part 5: Booby trap the stalemate button",
		"This is the part where he kills you",
		"This text is so long that it will probably fall off the screen\n and you will be unable to read it because I'm such a massive troll\n that likes to make text fall off the screen to troll people lmao lmao this is just padding to make the text even longer I got you so goooooooooddddddd ",
		"sex",
		"Some people call the 'Arrow keys' as 'Cursor keys'",
		"have you touched grass recently? because i havent",
		"2+2=fish",
		"",
		"You've been distracted",
		"If you're under the age of 13...\nwhat the hell are you doing playing fnf? Go do your homework, play roblox or something"
	];
	static var currentTip:Int = 0;

	public override function new(?txt = "loading"){
		super();
		if(object == null) object = this;
		width = 1280;
		height = 720;

			// scaleX = lime.app.Application.current.window.width / 1280;
			// scaleY = lime.app.Application.current.window.height / 720;
		// graphics.beginFill(0x110011);
		// graphics.drawRect(0,0, 1280, 720);
		// graphics.endFill();
		var loadingText = new Alphabet(0,0,txt,true);
		loadingText.isMenuItem = false;
		loadingText.visible = true;
		if(SESave.data.doCoolLoading){
			// loadingIcon = new Sprite();
			// loadingIcon.x = 640;
			// loadingIcon.y = 300;
			// addChild(loadingIcon);
			// // var note = new Note(0, 0, null,false,false);
			// // note.useFramePixels = true;
			// // note.draw();
			// var note = SELoader.loadBitmap('assets/shared/images/loadingIcon.png',true);
			// loadingIcon.graphics.beginBitmapFill(note,false,true);
			// // loadingIcon.graphics.moveTo();
			// // 
			// loadingIcon.graphics.drawRect(0,0, note.width, note.height);
			// loadingIcon.graphics.endFill();
			// loadingIcon.scaleX = loadingIcon.scaleY= 0.5;
			
		}

		var funniBitmap = new BitmapData(1290,730,false,0x100010);
		var x = 1200;
		var y = 600;
		var i = loadingText.members.length - 1;
		while (i >= 0) { // Writing backwards instead of forwards
			var v = loadingText.members[i];
			v.useFramePixels = true;
			v.drawFrame();
			x -= Std.int(v.width - 2);
			funniBitmap.copyPixels(v.framePixels,new flash.geom.Rectangle(0,0,v.width,v.height),new flash.geom.Point(x,y));
			v.destroy();
			// graphics.beginBitmapFill(v.framePixels,false,true);
			// graphics.moveTo(x,y);
			// graphics.drawRect(0,0, v.width, v.height);
			// graphics.endFill();
			i--;
		}

		graphics.beginBitmapFill(funniBitmap,false,true);
		graphics.moveTo(x,y);
		graphics.drawRect(-5,-5, funniBitmap.width, funniBitmap.height);
		graphics.endFill();
		loadingText.destroy();


		var errText:FlxText = new FlxText(0,0,0,'');
		errText.size = 20;
		errText.setFormat(CoolUtil.font, 32, 0xFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		errText.setBorderStyle(FlxTextBorderStyle.OUTLINE,0xFF000000,4,1);
		errText.scrollFactor.set();
		var oldTF = errText.textField;
		errText.destroy();
		addChild(textField = new TextField());
		textField.width = 1280;
		textField.text = "";
		textField.y = 720 * 0.7;
		addChild(tipTextField = new TextField());
		tipTextField.width = 1280;
		tipTextField.text = "";
		tipTextField.y = 720 * 0.75;


		// textField.x = (1280 * 0.5);
		var tf = new TextFormat(oldTF.defaultTextFormat.font, 32, 0xFFFFFF);
		tipTextField.embedFonts = textField.embedFonts = oldTF.embedFonts;
		tf.align = "center";

		textField.defaultTextFormat = tf;


		var tf = new TextFormat(oldTF.defaultTextFormat.font, 24, 0xffaaff);
		
		tf.align = "center";
		tipTextField.defaultTextFormat = tf;


		// new FlxTimer().start(0.1,function(_){
		// 	FlxG.cameras.remove(cam);
		// 	graphics.beginBitmapFill(cam.buffer);
		// 	graphics.drawRect(0,0, 1280, 720);
		// 	graphics.endFill();
		// 	loadingText.destroy();
		// 	cam.destroy();
		// 	cam = null;
		// 	loadingText = null;
		// },1);
		// loadingText.update(0);
		// loadingText.draw();
		
		
		// super.addChild(loadingText);
	}

	public static function initScreen(?text:String = "Loading"){
		new LoadingScreen(text);

	}
	var elapsed = 0;
	override function __enterFrame(e:Int){
		try{
			// if(textField.htmlText != loadingText){
			// 	updateText();
			// }
			if(SESave.data.doCoolLoading){
				if(loadingIcon != null){
					loadingIcon.rotation += e * vel;
					loadingIcon.rotation = loadingIcon.rotation % 360;
					vel = FlxMath.lerp(0.02,vel,e * 0.001); // This is shit but I don't care, it's funny
				}
				if(object.funni && alpha < 1){
					alpha += e * 0.003;
				}else if(!object.funni) {
					if(alpha > 0.003){
						alpha -= e * 0.003;
					}else{
						FlxG.stage.removeChild(this);
					}
				}
			}
			if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.F1){
				MainMenuState.handleError("Manually triggered force exit");
			}
			if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.F4){
				throw('Manually triggered crash');
			}
			super.__enterFrame(e);
		}
		catch(e){
			trace(e);

		}	
	} 
	function updateText(){
		textField.htmlText =  '$loadingText';
		tipTextField.text = tips[currentTip] ?? "your mother";
		if(loadingIcon != null) vel += 0.15;
		if(SESave.data.doCoolLoading){
			Main.renderLockButCooler.release();
			Main.renderLock.wait();
		
		// textField.x = (1280 * 0.5) - textField.width;
		}
	}
	public static var tween:FlxTween;
	public static function show(){
		if(object == null){
			initScreen();
		}
		if(!canShow){
			forceHide();
			return;
		}
		// object.alpha = 1;
		if(tween != null){tween.cancel();}
		isVisible = object.funni = true;
		currentTip = Math.floor(Math.random() * tips.length);
		object.elapsed = 0;
		object.scaleX = Application.current.window.width / 1280;
		object.scaleY = Application.current.window.height / 720;
		Main.funniSprite.addChildAt(object,1);
		loadingText = "";
		object.updateText();
		if(!SESave.data.doCoolLoading)object.alpha = 1;

		// object.visible = true;
	}
	public static function forceHide(){
		if(object == null) return;
		if(tween != null){tween.cancel();}
		isVisible = object.funni = false;
		object.alpha = 0;
		try{
			Main.funniSprite.removeChild(object);
		}catch(e){}
	}
	public static function hide(){
		if(Main.game != null) Main.game.blockUpdate = Main.game.blockDraw = false;
		if(object == null) return;
		if(!object.funni){
			object.alpha = 0;
			return;
		}
		if(tween != null){tween.cancel();}
		object.funni = false;
		object.alpha = 1;
		if(!SESave.data.doCoolLoading){
			try{
				tween = FlxTween.tween(object,{alpha:0},0.4,{onComplete:function(_){Main.funniSprite.removeChild(object);}});
			}catch(e){
				object.alpha = 0;
			}
		}
		
	}

	@:keep inline static public function loadAndSwitchState(target:flixel.FlxState, stopMusic = false) {
		LoadingScreen.show();
		if (stopMusic && FlxG.sound.music != null){
			if(SickMenuState.chgTime){
				SickMenuState.curSongTime = FlxG.sound.music.time;
				SickMenuState.chgTime = false;
			}
			FlxG.sound.music.stop();

		}
		FlxG.switchState(target);
	}



}
