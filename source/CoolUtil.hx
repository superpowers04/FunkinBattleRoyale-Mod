package;

import lime.app.Application;
import openfl.Lib;
import lime.utils.Assets;
import sys.FileSystem;
import flixel.FlxG;
import flixel.group.FlxGroup;

using StringTools;

class CoolUtil {
	public static var fontName:String = "vcr.ttf";
	public static var font:String = (SELoader.exists('mods/font.ttf') ? 'mods/font.ttf' : (SELoader.exists('mods/font.otf') ? 'mods/font.ttf' : Paths.font(fontName)));
	public static var difficultyArray:Array<String> = ['EASY', "NORMAL", "HARD"];
	public static var volKeys:Array<Array<Int>> = [];
	public static var volKeysEnabled = true;
	public static var Framerate:Float = 0;
	public static var updateRate:Float = 120;
	public static var activeObject(default,set):Dynamic = null;
	public static function set_activeObject(vari){
		toggleVolKeys(FlxG.keys.enabled = (vari == null)); // Why the fuck do i need to do this, what
		return activeObject = vari;
	}
	public static function updateActiveObject(vari){
		try{
			activeObject.hasFocus = false;
		}catch(e){}
		return activeObject = vari;
	}
	public static function setFramerate(?fps:Float = 0,?update:Bool = false,?temp:Bool = false){
		if(!temp){
			if(fps != 0 && !update){
				updateRate = (Framerate = SESave.data.fpsCap = fps) * 2;
			}
			if(Framerate == 0 || update){
				Framerate = cast SESave.data.fpsCap;
			}
			if(Framerate < 30){
				var rf = Application.current.window.displayMode.refreshRate;
				var fr = Application.current.window.frameRate;
				Framerate = SESave.data.fpsCap = (rf > 30 ? rf : (fr > 30 ? fr : 30 ));
			}
			if(Framerate > 300){
				Framerate = SESave.data.fpsCap = 300;
			}
		}
		Main.instance.setFPSCap(Framerate);
		FlxG.updateFramerate = (FlxG.drawFramerate = Std.int(Framerate)) * 2;
	}

	@:keep inline public static function clearFlxGroup(obj:FlxTypedGroup<Dynamic>):FlxTypedGroup<Dynamic>{ // Destroys all objects inside of a FlxGroup
		while (obj.members.length > 0){
			var e = obj.members.pop();
			if(e != null && e.destroy != null) e.destroy();
		}
		return obj;
	}
	@:keep inline public static function difficultyString():String {
		return if (PlayState.stateType == 4) PlayState.actualSongName else difficultyArray[PlayState.storyDifficulty];
	}
	public static function toggleVolKeys(?toggle:Bool = true){
		if (toggle){
			FlxG.sound.muteKeys = volKeys[0];
			FlxG.sound.volumeUpKeys = volKeys[1];
			FlxG.sound.volumeDownKeys = volKeys[2];
			return;
		}
		FlxG.sound.muteKeys = null;
		FlxG.sound.volumeUpKeys = null;
		FlxG.sound.volumeDownKeys = null;
	}
	@:keep inline public static function coolTextFile(path:String):Array<String> {
		var daList:Array<String> = Assets.getText(path).trim().split('\n');

		for (i in 0...daList.length) {
			daList[i] = daList[i].trim().replace("\\n","\n");
		}

		return daList;
	}
	@:keep inline public static function splitFilenameFromPath(str:String):Array<String>{
		return [str.substr(0,str.lastIndexOf("/")),str.substr(str.lastIndexOf("/") + 1)];
	}

	public inline static function getFilenameFromPath(str:String):String{
		if(str.lastIndexOf("/") == -1) return str;
		return str.substr(str.lastIndexOf("/") + 1);
	}
	public inline static function removeFileFromPath(str:String):String{
		if(str.lastIndexOf("/") == -1) return str;
		return str.substr(0,str.lastIndexOf("/"));
	}
	public static function coolFormat(text:String){
		var daList:Array<String> = text.trim().split('\n');

		for (i in 0...daList.length) daList[i] = daList[i].trim().replace("\\n","\n");

		return daList;
	}
	public static function formatChartName(str:String):String{
		str = (~/[-_ ]/g).replace(str,' ');
		var e = str.split(' ');
		str = "";
		for (item in e){
			str+=' ' + item.substring(0,1).toUpperCase() + item.substring(1);
		}
		return str.trim();
	}

	@:keep inline public static function orderList(list:Array<String>):Array<String>{
		haxe.ds.ArraySort.sort(list, (a, b) -> (a<b ? -1 : (a>b ? 1 : 0)) );

		return list;
	}
	public static function coolStringFile(path:String):Array<String> {
		var daList:Array<String> = path.trim().split('\n');

		for (i in 0...daList.length) daList[i] = daList[i].trim();

		return daList;
	}

	@:keep inline public static function numberArray(max:Int, ?min = 0):Array<Int> {
		var dumbArray:Array<Int> = [];
		for (i in min...max) dumbArray.push(i);
		return dumbArray;
	}
	@:keep inline public static function multiInt(?int:Int = 0) return (int==1?'':'s');

	public static function cleanJSON(input:String):String{ // Haxe doesn't filter out comments?
		return (~/\/\*[\s\S]*?\*\/|\/\/.*/g).replace(input.trim(),'');
	}
}
