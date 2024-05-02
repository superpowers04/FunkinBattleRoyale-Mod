package se;

import flash.display.Sprite;
import flash.display.BitmapData;
import openfl.text.TextField;
import openfl.text.TextFormat;
import lime.app.Application;

class ErrorSprite extends Sprite{
	
	var textField:TextField;
	var textFieldTop:TextField;
	var textFieldBot:TextField;
	public override function new(?txt = "Unknown Error!",?saved:Bool = false){
		super();

		width = 1280;
		height = 720;
			var textField = new TextField();
			super.addChild(textField);
			textField.width = 1280;
			textField.text = txt;
			textField.y = 720 * 0.3;
			var textFieldTop = new TextField();
			super.addChild(textFieldTop);
			textFieldTop.width = 1280;
			textFieldTop.text = "A fatal error occurred!";
			textFieldTop.textColor = 0xFFFF0000;
			textFieldTop.y = 30;
			var textFieldBot = new TextField();
			super.addChild(textFieldBot);
			textFieldBot.width = 1280;
			textFieldBot.height= 400;
			textFieldBot.text = "Please take a screenshot and report this";
			textFieldBot.y = 720 * 0.8;
			if(saved){
				var dateNow:String = Date.now().toString();

				dateNow = StringTools.replace(dateNow, " ", "_");
				dateNow = StringTools.replace(dateNow, ":", ".");
				textFieldBot.text = 'Crash report saved to "crashReports/SUPERENGINE_CRASH-${dateNow}.log".\n Please send this file when reporting this crash.';
			}

			// textField.x = (1280 * 0.5);
			var tf = new TextFormat(CoolUtil.font, 32, 0xFFFFFF);
			tf.align = "center";
			textFieldBot.embedFonts = textFieldTop.embedFonts = textField.embedFonts = true;
			textFieldBot.defaultTextFormat =textFieldTop.defaultTextFormat =textField.defaultTextFormat = tf;
					
		// var funniBitmap = new BitmapData(1290,730,false,0x100010);
		// graphics.beginBitmapFill(funniBitmap,false,true);
		// graphics.endFill();
		Main.instance.addChild(this);
	}

}