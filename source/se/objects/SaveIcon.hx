package se.objects;


import openfl.display.Sprite;
import flixel.FlxG;
import lime.app.Application;

class SaveIcon extends Sprite{
	// public static var icon;
	public static var instance = new SaveIcon();
	static var startTime:Float=0;
	static var lastFrameTime:Float=0;

	static var showing=false;
	function new(){
		super();
		width=150;
		height=150;
		if(instance == null) instance = this;
		var bitmap = SELoader.loadBitmap('assets/images/saveIcon.png',true);
		graphics.beginBitmapFill(bitmap,false,true);
		graphics.moveTo(x,y);
		graphics.drawRect(0,0, bitmap.width, bitmap.height);
		graphics.endFill();

	}
	override function __enterFrame(e:Int){
		try{
			if(startTime == 0){
				lastFrameTime=startTime=Date.now().getTime();
				return super.__enterFrame(e);
			}
			var curTime = Date.now().getTime();
			var time = curTime - startTime;
			if(curTime - lastFrameTime > 1000){
				startTime += curTime - lastFrameTime;
				time = curTime - startTime;
			}
			lastFrameTime=curTime;
			if(time < 200){
				var t= (time / 200);
				x = Application.current.window.width - (width * scaleX);
				rotation=-90*(1-t);
			}else if(time > 220 && time < 500){
				var t = ((time-200)/200);
				y = 10*instance.scaleY*t;
			}else if(time > 1000){
				var t = ((time-1000)/500);
				x = (Application.current.window.width - ((width * scaleX)*(1-t)));
			}
			super.__enterFrame(e);
			if(time > 2000){
				FlxG.stage.removeChild(this);
				showing=false;
			}
		}
		catch(e){
			trace(e);

		}	
	} 
	public static function show(){
		// object.alpha = 1;
		// startTime=Date.now().getTime();
		// lastFrameTime=startTime;
		startTime=0;
		lastFrameTime=0;
		instance.scaleX = Application.current.window.width / 1280;
		instance.scaleY = Application.current.window.height / 720;
		instance.x = Application.current.window.width;
		instance.y = 10*instance.scaleY;
		if(!showing){
			Main.funniSprite.addChildAt(instance,1);
			showing = true;
		}
		// if(!SESave.data.doCoolLoading)object.alpha = 1;

		// object.visible = true;
	}
}