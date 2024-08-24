package;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.FlxG;
import flixel.util.FlxColor;
import flash.display.BitmapData;
import flixel.FlxCamera;
class QuickNameSubState extends MusicBeatSubstate{
	var funky:Dynamic;
	var args:Array<Dynamic> = [];
	var text:String;
	var textBox:flixel.addons.ui.FlxInputText;
	var shownText:FlxText;
	var funniButton:FlxButton;
	var cancelButton:FlxButton;
	var befUpdate:Bool = false;
	var befDraw:Bool = false;
	var cancelable:Bool = true;
	var defaultText:String;
	var cam:FlxCamera;
	var oldCam:FlxCamera;
	var oldMVis:Bool = false;
	override public function new(funk:Dynamic,args:Array<Dynamic>,?text:String = "Placeholder text goddammit",?defaultText:String = "mooooooooooooo.png",?cancelable:Bool = true,check:String -> String){
		funky = funk;
		this.args = args;
		this.text = text;
		this.cancelable = cancelable;
		befUpdate = FlxG.state.persistentUpdate;
		befDraw = FlxG.state.persistentDraw;
		this.defaultText = defaultText;
		FlxG.state.persistentUpdate = false;
		// FlxG.state.persistentDraw = false;
		// oldCam = FlxG.camera;
		CoolUtil.toggleVolKeys(false);
		oldMVis = FlxG.mouse.visible;
		FlxG.mouse.visible = true;
		
		super();
		buttonPress = function(){
			var str:String = check(textBox.text);
			if(str != ""){
				shownText.text = str;
				shownText.color = FlxColor.RED;
				shownText.screenCenter(X);

				return;
			}
			CoolUtil.toggleVolKeys(true);
			args.insert(0,textBox.text);
			Reflect.callMethod(null,funky,args);
			destroy();
		}
		var box = new FlxSprite(20,20).loadGraphic(FlxGraphic.fromRectangle(1240,680,0xdd000000));
		box.color = 0xdddddd;
		// box.alpha = 0.2;
		add(box);
		textBox = new flixel.addons.ui.FlxInputText(0,0,512,defaultText,32);
		textBox.screenCenter(XY);
		// textBox.width = FlxG.width * 0.45;
		add(textBox);
		shownText = new FlxText(0,0,text,32);
		shownText.setFormat(CoolUtil.font, 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		shownText.screenCenter(XY);
		shownText.y -= shownText.height + textBox.height;

		// shownText.width = FlxG.width * 0.45;
		add(shownText);
		funniButton = new FlxButton(0,0,"Continue",buttonPress);
		funniButton.x = textBox.x + textBox.width - (funniButton.width + 2);
		funniButton.y = textBox.y + textBox.height + 5;
		add(funniButton);
		if(cancelable){
			cancelButton = new FlxButton("Cancel",function(){
			
				FlxG.state.persistentUpdate = befUpdate;
				CoolUtil.toggleVolKeys(true);
				close();

			});

			cancelButton.x = textBox.x + 2;
			cancelButton.y = textBox.y + textBox.height + 5;
			add(cancelButton);
		}
	}
	dynamic function buttonPress(){}
	override function update(e){
		super.update(e);
		if(FlxG.keys.justPressed.ESCAPE){
			FlxG.mouse.visible = oldMVis;
			FlxG.state.persistentUpdate = befUpdate;
			CoolUtil.toggleVolKeys(true);
			// destroy();
			close();
		}
		if(FlxG.keys.justPressed.ENTER){
			buttonPress();
		}
	}
	var _grab:BitmapData;


}