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

class SENotification extends FlxGroup{
	public static var currentNotification:SENotification;
	public static function removal(){
		if(currentNotification == null) return;
		FlxTween.cancelTweensOf(currentNotification);
		currentNotification.destroy();
	}
	public static function show(?destroyOld:Bool=true,title:String="you've been distracted",content:String="",duration:Float=10,direction:Int = 1):SENotification{
		if(destroyOld) removal();
		currentNotification = new SENotification(title,content,duration,direction);
		currentNotification.cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];
		FlxG.state.add(currentNotification);
		return currentNotification;
	}
	public static function showSong(SONG:SwagSong){
		var notificationStr = '${SONG.song}';
		// if(SONG.author != null && SONG.author != "") notificationStr+='By ${SONG.author}';
		var author:String = SONG.author ?? SONG.artist;
		if(author != null && author != "") notificationStr+='\n By ${author}';

		SENotification.show('Now Playing:',notificationStr);
	}
	var x(default,set):Float = 0;
	var y(default,set):Float = 0;
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
			member.y+=(-x)+v;
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
	var bg:FlxSprite;
	public function new(title:String="you've been distracted",content:String="",duration:Float=5,direction:Int = 1){
		super();
		var txt = new SEText(10,10,title,32,direction == 1 ? LEFT : direction == 0 ? CENTER : RIGHT);
		var content = new SEText(15,38,content,24,direction == 1 ? LEFT : direction == 0 ? CENTER : RIGHT);
		bg = new FlxSprite().loadGraphic(FlxGraphic.fromRectangle(
						Std.int(Math.max(txt.width,content.width) + 10),
						Std.int(content.y+content.height+20),0xAA440033));
		add(bg);
		add(txt);
		add(content);
		
		txt.scrollFactor.set();
		bg.scrollFactor.set();
		content.scrollFactor.set();
		if(direction==0){
			x=(FlxG.width*0.5)-(bg.width*0.5);
			y=-bg.height;
			FlxTween.tween(this,{y:10},1);
			FlxTween.tween(this,{y:y},1,{startDelay:duration});
		}else{
			x=(direction==1 ? -bg.width : FlxG.width);
			y=30;
			FlxTween.tween(this,{x:(direction==1?10:FlxG.width-(bg.width+10))},0.5);
			FlxTween.tween(this,{x:x},0.5,{startDelay:duration,onComplete:function(_){
				currentNotification=null;
				destroy();
			}});
		}

	}
}