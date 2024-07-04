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

// TODO ADD SCROLLING
class SEList extends SEGroup{
	public var hoveredObject:FlxObject;
	public var selectedObject:FlxObject;
	public var hoveredColor:FlxColor = FlxColor.WHITE;
	public var selectedColor:FlxColor = FlxColor.GREEN;
	public var inactiveColor:FlxColor = 0x999099FF;
	public var selectedCallback:(Int,FlxObject)->Void;
	public var stringList:Array<String> = [];
	override function update(e:Float){
		super.update(e);
		hoveredObject = null;
		var hoveredIndex:Int = -1;
		for(i => m in members){
			var member:FlxObject = cast(m,FlxObject);
			if(member == null) continue;
			if(FlxG.mouse.overlaps(member)){
				hoveredObject = member;
				hoveredIndex=i;
				member.color = hoveredColor;
			}else{

				member.color = inactiveColor;
			}
		}
		if(FlxG.mouse.justPressed){
			selectedObject = hoveredObject;
			if(selectedCallback !=null) selectedCallback(hoveredIndex,selectedObject);
		}
		if(selectedObject != null) selectedObject.color = FlxColor.GREEN;
	}
	public function makeFromStringArray(arr:Array<String>){
		while(members.length > arr.length){
			members.pop().destroy();
		}
		for(member in members){
			if((member is FlxText)) continue;
			remove(member,true);
		}
		stringList = arr;
		for(i->str in arr){
			if(members[i]){
				members[i].text = str;
				continue;
			}
			add(new FlxText(0,0,str));
		}
	}
}