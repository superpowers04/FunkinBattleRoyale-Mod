// package;

import flixel.addons.effects.FlxSkewedSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;

import flash.display.BitmapData;
import flixel.math.FlxPoint;
import sys.io.File;


using StringTools; 

// Note without any code for updating it's state and such

class FakeNote extends Note
{
	//Literally just copied flxsprite and flxobject's update
	override public function update(elapsed:Float):Void
	{
		
		updateAnimation(elapsed);
	}
}