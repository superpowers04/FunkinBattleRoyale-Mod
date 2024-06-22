package;

import flixel.FlxG;
import sys.io.File;


typedef ScoreJson = {
	var songNames:Array<String>;
	var scores:Array<Array<Dynamic>>;
}

class SongScores {

	var songNames:Array<String> = [];
	var scores:Array<Dynamic> = [];
	var path:String = "";
	public function new(?path:String = ""){
		if(path == ""){
			path = Highscore.GETSCOREPATH();
		}
		trace('Loading saves from $path');
		this.path = path;
		var json:ScoreJson = {
			songNames:["Bopeebo"],
			scores:[[1]]
		}
		if(SELoader.exists(path)){
			json = cast try{Json.parse(SELoader.loadText(path));}catch(e){ {songNames:["Bopeebo"],scores:[1]}; };
		}
		songNames = json.songNames;
		#if !hl
		scores = json.scores;
		#end
	}
	public function save(){
		try{
			if(!SELoader.exists(path)){
				SELoader.createDirectory(path.substr(0,path.lastIndexOf("/")));
			}
			SELoader.saveContent(path,Json.stringify({songNames:songNames,scores:scores}));
			se.objects.SaveIcon.show();
		}catch(e){
			MusicBeatState.instance.showTempmessage('Unable to save scores! ${e.message}',0xFF0000);
		}
	}
	public function exists(song:String):Bool{
		return songNames.indexOf(song) != -1;
	}
	public static var NORESULT:Array<Dynamic> = [0,"No score to display!"];
	public function getArr(song:String):Array<Dynamic>{
		var index = songNames.indexOf(song);
		if(index < 0) return [0,"No score to display!"];
		return scores[index].copy();
	}
	public function get(song:String):Int{
		var index = songNames.indexOf(song);
		if(index < 0) return 0;

		return scores[index][0] ?? 0;
	}
	public function set(song:String,?score:Int = 0,?arr:Array<Dynamic>){
		var index = songNames.indexOf(song);
		if(index < 0) index = songNames.length;

		songNames[index] = song;
		scores[index] = arr ?? [score];
		save();
		trace('Funni set $song = $score');
	}
	public function wipe(){
		songNames = [];
		scores = [];
		save();
		trace("");
	}
}
class Highscore
{
	// #if (haxe >= "4.0.0")
	// public static var songScores:Map<String, Int> = new Map();
	// #else
	// public static var songScores:Map<String, Int> = new Map<String, Int>();
	// #end
	public static var songScores:SongScores;

	public static inline function GETSCOREPATH():String{
		#if windows 
			if (Sys.getEnv("LOCALAPPDATA") != null) return '${Sys.getEnv("LOCALAPPDATA")}/superpowers04/FNF Super Engine/scores.json'; // Windows path
		#else
			if (Sys.getEnv("HOME") != null ) return '${Sys.getEnv("HOME")}/.local/share/superpowers04/FNF Super Engine/scores.json'; // Unix path
		#end
		else 
			return "superpowers04/FNF Super Engine/scores.json"; // If this gets returned, fucking run
	}

	public static var scorePath:String = GETSCOREPATH();


	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);



		// if(!SESave.data.botplay)
		// {
			// if (songScores.exists(daSong))
			// {
				// if (songScores.get(daSong) < score)
		setScore(daSong, score);
			// }
			// else
			// 	setScore(daSong, score);
		// }else trace('BotPlay detected. Score saving is disabled.');
	}

	public static function saveWeekScore(week:Dynamic = 1, score:Int = 0, ?diff:Int = 0):Void
	{



		if(!SESave.data.botplay)
		{
			var daWeek:String = formatSong('week$week', diff);

			if (songScores.exists(daWeek))
			{
				if (songScores.get(daWeek) < score)
					setScore(daWeek, score);
			}
			else
				setScore(daWeek, score);
		}else trace('BotPlay detected. Score saving is disabled.');
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	@:keep inline public static function setScore(song:String, score:Int,?Arr:Array<Dynamic>,?forced:Bool = false):Bool
	{
		// // Reminder that I don't need to format this song, it should come formatted!
		if(songScores.get(song) < score || forced){
			songScores.set(song, score,Arr);
			return true;
		}
		return false;
	}

	@:keep inline public static function formatSong(song:String, diff:Int):String
	{
		if (diff == 0) return '$song-easy';
		if (diff == 2) return '$song-hard';
		return song;
	}

	@:keep inline public static function getScoreUnformatted(song:String):Int{
		try{
			return cast songScores.get(song);
		}catch(e){return 0;}
	}
	@:keep inline public static function getScore(song:String, diff:Int):Array<Dynamic>{
		var songy = formatSong(song, diff);
		return songScores.getArr(songy);
	}

	public static function getWeekScore(week:Dynamic, diff:Int):Int
	{
		if (!songScores.exists(formatSong('week-' + week, diff))) setScore(formatSong('week-' + week, diff), 0);

		return songScores.get(formatSong('week-' + week, diff));
	}
	@:keep inline public static function save():Void { // This is usually not needed as scores are automatically saved
		songScores.save();
	}

	@:keep inline public static function load():Void {
		// if (FileSystem.exists())
		// {
		songScores = new SongScores();
		// }
	}
}