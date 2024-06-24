package;

import Song.SwagSong;
import flixel.FlxG;

/**
 * ...
 * @author
 */

typedef BPMChangeEvent = { 
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class Conductor {
	public static var bpm:Float = 100;
	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	public static var crochetSecs(get,set):Float;
	public static function get_crochetSecs():Float{
		return crochet * 0.001;
	}
	public static function set_crochetSecs(val:Float):Float{
		return crochet = val * 1000;
	}
	public static var songPosition:Float;
	public static var lastSongPos:Float;
	public static var offset:Float = 0;

	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = Math.floor((safeFrames / 60) * 1000); // is calculated in create(), is safeFrames in milliseconds
	public static var timeScale:Float = Conductor.safeZoneOffset / 166;

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];
	public static var bpmChangeMapSteps:Map<Int,BPMChangeEvent> = [];

	public function new(){}

	@:keep inline public static function recalculateTimings() {
		Conductor.safeFrames = SESave.data.frames;
		Conductor.safeZoneOffset = Math.floor((Conductor.safeFrames / 60) * 1000);
		Conductor.timeScale = Conductor.safeZoneOffset / 166;
	}

	public static function mapBPMChanges(?song:SwagSong) {
		bpmChangeMap = [];
		bpmChangeMapSteps = [];
		offset = 0;
		if(song == null) return;
		offset = song.offset;

		var curBPM:Float = 120;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length) {
			var v = song.notes[i];
			if(v.changeBPM && v.bpm != curBPM) {
				curBPM = Math.abs(v.bpm);
				bpmChangeMap.push(bpmChangeMapSteps[totalSteps] = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				});
			}


			var deltaSteps:Int = Math.isNaN(v.lengthInSteps) ? v.lengthInSteps : 16;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
	}

	@:keep inline public static function changeBPM(newBpm:Float) {
		stepCrochet = (crochet = ((60 / (bpm = Math.abs(Math.isNaN(newBpm) || newBpm == 0 ? 120 : newBpm))) * 1000)) / 4;
		// FlxG.animationTimeScale=bpm/120;
	}
}