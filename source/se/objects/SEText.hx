package se.objects;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets;

import openfl.display.BitmapData;
import openfl.geom.ColorTransform;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import flixel.util.FlxColor;
/*
	A basic class that auto-initialises a FlxText with the right font and shit
*/
class SEText extends FlxText{
	public function new(x:Float = 0, y:Float = 0, fieldwidth:Float = 0, ?text:String, 
						size:Int = 8,lockScrollFactor:Bool = true,?color:FlxColor = FlxColor.WHITE,alignment:FlxTextAlign = LEFT,borderStyle:FlxTextBorderStyle = OUTLINE, outlineColor:FlxColor =FlxColor.BLACK){
		super(x,y,fieldwidth,text,size,true);
		setFormat(CoolUtil.font, size, color, alignment, borderStyle, outlineColor);
		if(lockScrollFactor) scrollFactor.set();
	}
}
// class SEText extends FlxSprite{
// 	public var textField(default, null):TextField;
// 	public var textFormat:TextFormat;
// 	public function new(x:Float=0,y:Float=0,?Size:Int = 8){
// 		super(x,y);
// 		textField = new TextField();
// 		textField.selectable = false;
// 		textField.multiline = true;
// 		textField.wordWrap = true;
// 		// letterSpacing = 0;
// 		// font = FlxAssets.FONT_DEFAULT;
// 		textField.defaultTextFormat = textFormat = new TextFormat(null, Size, 0xffffff);
		
// 		textField.cacheAsBitmap=true;
// 		useFramePixels=true;
// 	}

// 	/**
// 	 * The text being displayed.
// 	 */
// 	public var text(default, set):String = "";
// 	public function set_text(str:String){
// 		textField.text = str;
// 		updateInternalBitmap();
// 		return str;
// 	}
// 	inline function getNewBitmapData() return new BitmapData(Std.int(textField.width),Std.int(textField.height),0x00000000);
// 	public function updateInternalBitmap(){
// 		if(graphic == null) @:privateAccess loadGraphic(FlxGraphic.fromBitmapData(getNewBitmapData()));
// 		else if(graphic.bitmap.width != textField.width || graphic.bitmap.height != textField.height) graphic.bitmap = getNewBitmapData();
// 		@:privateAccess graphic.bitmap.draw(textField.__cacheBitmapData);
// 	}
// }
