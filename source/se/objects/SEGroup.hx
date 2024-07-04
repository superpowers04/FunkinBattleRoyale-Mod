package se.objects;


import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxBasic;
import se.formats.Song;
import flixel.FlxObject;

class SEGroup extends FlxGroup {
	public var x(default,set):Float = 0;
	public var y(default,set):Float = 0;
	public function set_x(v){
		for (member in members){
			var member = cast(member,FlxObject);
			member.x+=(-x)+v;
		}
		return x=v;
	}
	public function set_y(v){
		for (member in members){
			var member = cast(member,FlxObject);
			member.y+=(-y)+v;
		}
		return y=v;
	}
	override public function add(b:FlxBasic):FlxBasic{
		if(b == null) return b;
		var e = cast(super.add(b),FlxObject);
		e.x+=x;
		e.y+=y;
		return e;
	}

}