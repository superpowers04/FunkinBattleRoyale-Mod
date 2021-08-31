package;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import sys.FileSystem;
import flash.display.BitmapData;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public function new(?char:String = 'bf', ?isPlayer:Bool = false,?clone:String = "")
	{
		super();
		if (clone != "") char = clone;
		var chars:Array<String> = ["bf","spooky","pico","mom","mom-car",'parents-christmas',"senpai","senpai-angry","spirit","spooky","bf-pixel","gf","dad","monster","monster-christmas","parents-christmas","bf-old","gf-pixel","gf-christmas","face","tankman"];
		if (FileSystem.exists(Sys.getCwd() + "mods/characters/"+char+"/healthicon.png")){
			trace('Custom character with custom icon! Loading custom icon.');
			loadGraphic(FlxGraphic.fromBitmapData(BitmapData.fromFile('mods/characters/$char/healthicon.png')), true, 150, 150);
			char = "bf";
		}else if (chars.contains(char) && FileSystem.exists(Sys.getCwd() + "mods/characters/"+char+"/icongrid.png")){
			trace('Custom character with custom icon! Loading custom icon.');
			loadGraphic(FlxGraphic.fromBitmapData(BitmapData.fromFile('mods/characters/$char/icongrid.png')), true, 150, 150);
		}else{loadGraphic(Paths.image('iconGrid'), true, 150, 150);}
		
		antialiasing = true;
		animation.add('bf', [0, 1], 0, false, isPlayer);
		if(chars.contains(char.toLowerCase())){ // For vanilla characters
			animation.add('bf-car', [0, 1], 0, false, isPlayer);
			animation.add('bf-christmas', [0, 1], 0, false, isPlayer);
			animation.add('bf-pixel', [21, 21], 0, false, isPlayer);
			animation.add('spooky', [2, 3], 0, false, isPlayer);
			animation.add('pico', [4, 5], 0, false, isPlayer);
			animation.add('mom', [6, 7], 0, false, isPlayer);
			animation.add('mom-car', [6, 7], 0, false, isPlayer);
			animation.add('tankman', [8, 9], 0, false, isPlayer);
			animation.add('face', [10, 11], 0, false, isPlayer);
			animation.add('dad', [12, 13], 0, false, isPlayer);
			animation.add('senpai', [22, 22], 0, false, isPlayer);
			animation.add('senpai-angry', [22, 22], 0, false, isPlayer);
			animation.add('spirit', [23, 23], 0, false, isPlayer);
			animation.add('bf-old', [14, 15], 0, false, isPlayer);
			animation.add('gf', [16], 0, false, isPlayer);
			animation.add('gf-christmas', [16], 0, false, isPlayer);
			animation.add('gf-pixel', [16], 0, false, isPlayer);
			animation.add('parents-christmas', [17, 18], 0, false, isPlayer);
			animation.add('monster', [19, 20], 0, false, isPlayer);
			animation.add('monster-christmas', [19, 20], 0, false, isPlayer);
			animation.play(char.toLowerCase());
		}else{trace('Invalid character icon $char, Using BF!');animation.play("bf");}
		switch(char)
		{
			case 'bf-pixel' | 'senpai' | 'senpai-angry' | 'spirit' | 'gf-pixel':
				antialiasing = false;
		}

		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
