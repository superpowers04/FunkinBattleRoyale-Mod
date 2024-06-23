package se.utilities;

import flixel.group.FlxGroup;
import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.addons.ui.FlxInputText;

@:publicFields @:structInit class SEUIPosition {
	var x:Int = 10;
	var y:Int = 10;
	var spacingY:Int = 5;
	var spacingX:Int = 5;
	var objects:Array<Array<FlxObject>> = [];

}

class SEUIUtilities{
	public static function addSpacedUI(group:Dynamic, objects:SEUIPosition){
		if (group.add == null) throw('Expected FlxGroup, got ${Type.typeof(group)}');
		var x = objects.x;
		var y = objects.y;
		var spacingX=objects.spacingX;
		var spacingY=objects.spacingY;
		for (i in 0...objects.objects.length){
			var list = objects.objects[i];
			if(list == null || list.length == 0){
				y+=spacingY*2;
				continue;
			}
			var currentHeight = 0;
			var xOffset = 0;
			var x = x;
			for (i in 0...list.length){
				var object = list[i];
				if(object == null){
					x+=spacingX;
					continue;
				}
				object.x=x;
				object.y=y;
				if(currentHeight < object.height) currentHeight = Std.int(object.height);
				var obj:Dynamic = object;
				if(obj is FlxInputText) (cast(obj,FlxInputText)).fieldWidth -= xOffset;
				// trace(x);
				x+=Std.int(object.width+spacingX);
				xOffset+=Std.int(object.width+spacingX);
				group.add(object);
			}

			y+=currentHeight+spacingY;
		}
	}

}
