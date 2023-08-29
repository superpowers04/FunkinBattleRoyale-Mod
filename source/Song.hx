package;

import Section.SwagSection;
import tjson.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import flixel.FlxG;

using StringTools;

typedef SwagSong =
{
	// Vanilla Shit
		var song:String;
		var notes:Array<SwagSection>;
		var bpm:Float;
		var needsVoices:Bool;
		var speed:Float;
		var player1:String;
		var player2:String;
		var gfVersion:String;
		var stage:String;
		var validScore:Bool;
		var ?chartVersion:String;

	// Super Engine things
		var ?rawJSON:Dynamic;
		var ?chartType:String;
		var ?forceCharacters:Bool;
		var ?inverthurtnotes:Bool;
		var ?noteMetadata:NoteMetadata;
		var ?offset:Float;

		var ?modName:String;
		var ?artist:String;
		var ?difficultyString:String;

	// Psych
		var ?sectionBeats:Null<Float>;

	// Chart type identification
		var ?noteStyle:String; // Psych
		var ?splashStyle:String; // Psych
		var ?arrowStyle:String; // Psych
		var ?events:Array<Dynamic>; // Psych
		var ?eventObjects:Array<Event>; // Kade
		var ?mania:Null<Int>; // Multikey
}

typedef NoteMetadata={
	var badnoteHealth:Float;
	var badnoteScore:Int;
	// var healthGain:Float;
	var missScore:Int;
	var missHealth:Float;
	// var tooLateScore:Float;
	var tooLateHealth:Float;
}
class Event
{
	public var name:String;
	public var position:Float;
	public var value:Float;
	public var type:String;

	public function new(name:String, pos:Float, value:Float, type:String)
	{
		this.name = name;
		this.position = pos;
		this.value = value;
		this.type = type;
	}
}
class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';
	public var player3:String = 'gf';
	public var noteStyle:String = 'normal';
	public var stage:String = 'stage';
	public static var defNoteMetadata:NoteMetadata = {
				badnoteHealth : -0.24,
				badnoteScore : -7490,
				missScore : -10,
				missHealth : -0.04,
				tooLateHealth : -0.075
			};


	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}
	@:keep inline public static function getEmptySong():SwagSong{
		return cast Json.parse(getEmptySongJSON()).song;
	}
	public static function getEmptySongJSON():String{
		return '{
			"song": {
				"player1": "bf",
				"events": [
				],
				"gfVersion": "gf",
				"notes": [
					{
						"lengthInSteps": 16,
						"sectionNotes": [],
						"typeOfSection": 0,
						"mustHitSection": true,
						"changeBPM": false,
						"bpm": 95
					},
					{
						"lengthInSteps": 16,
						"sectionNotes": [],
						"typeOfSection": 0,
						"mustHitSection": false,
						"changeBPM": false,
						"bpm": 165
					}
				],
				"player2": "bf",
				"player3": null,
				"song": "Unset song name",
				"stage": "stage",
				"validScore": true,
				"sections": 0,
				"needsVoices": false,
				"bpm": 150,
				"speed": 2.0,
				"chartType":"FNF/Super"
			}
		}';
	}


	static function invertChart(swagShit:SwagSong):SwagSong{
		var invertedNotes:Array<Int> = [4,5,6,7,0,1,2,3];
		for (sid => section in swagShit.notes) {
			section.mustHitSection = !section.mustHitSection;
			swagShit.notes[sid] = section;
		}
		return swagShit;
	}


	static function modifyChart(swagShit:SwagSong,charting:Bool = false):SwagSong{
		var hurtArrows = (QuickOptionsSubState.getSetting("Custom Arrows") || onlinemod.OnlinePlayMenuState.socket != null || charting);
		var useHurtArrows = FlxG.save.data.useHurtArrows;
		var opponentArrows = (onlinemod.OnlinePlayMenuState.socket != null || QuickOptionsSubState.getSetting("Opponent arrows") || charting);
		var invertedNotes:Array<Int> = [4,5,6,7];
		var oppNotes:Array<Int> = [0,1,2,3];
		for (sid => section in swagShit.notes) {
			if(section.sectionNotes == null || section.sectionNotes[0] == null) continue;

			var sN:Array<Int> = [];
			try{
				if(section.lengthInSteps == null || section.lengthInSteps <= 0){
					section.lengthInSteps = Std.int(swagShit.sectionBeats * 4);
				}
			}
			if(section.lengthInSteps == null || section.lengthInSteps <= 0) section.lengthInSteps = 16;

			for (nid in 0 ... section.sectionNotes.length){ // Edit section
				var note:Array<Dynamic> = section.sectionNotes[nid];
				var modified = false;
				// Removes opponent arrows 
				if (!opponentArrows && (section.mustHitSection && invertedNotes.contains(note[1]) || !section.mustHitSection && oppNotes.contains(note[1]))){trace("Skipping note");sN.push(nid);continue;}
				
				if (hurtArrows){ // Weird if statement to prevent the game from removing hurt arrows unless they should be removed
					if(useHurtArrows && Std.isOfType(note[3],Int) && note[3] == 0 && (note[4] == 1 || note[1] > 7)) {note[3] = 1;modified = true;} // Support for Andromeda and tricky notes
				}else{
					note[3] = null;modified = true;
				}
				if(modified)section.sectionNotes[nid] = note;

			}
			for (_ => v in sN) {
				section.sectionNotes[v] = null;
			}

		}
		return swagShit;

	}

	public static function parseJSONshit(rawJson:String,charting:Bool = false):SwagSong
	{
		#if !debug
		try{
		#end
			var rawJson:Dynamic = Json.parse(rawJson.substr(0, rawJson.lastIndexOf("}") + 1));
			var swagShit:SwagSong = null;
			if(rawJson == null || rawJson.song == null){
				swagShit = getEmptySong();
			}else if(rawJson.song is String){
				swagShit = cast rawJson;
				swagShit.rawJSON = rawJson;
			}else if(rawJson.song.song != null){
				swagShit = cast rawJson.song;
				swagShit.rawJSON = rawJson;
			}
			swagShit.validScore = true;
			if ((PlayState.invertedChart || (onlinemod.OnlinePlayMenuState.socket == null && QuickOptionsSubState.getSetting("Inverted chart"))) && !charting) swagShit = invertChart(swagShit);
			if(Math.isNaN(swagShit.offset)) swagShit.offset = 0;
			swagShit = modifyChart(swagShit,charting);
			// if (QuickOptionsSubState.getSetting("Hurt notes") || onlinemod.OnlinePlayMenuState.socket != null) swagShit = convHurtArrows(swagShit);
			// if (onlinemod.OnlinePlayMenuState.socket == null){
			// 	if (!QuickOptionsSubState.getSetting("Opponent arrows")) swagShit = removeOpponentArrows(swagShit);
			// 	if (!QuickOptionsSubState.getSetting("Hurt notes")) swagShit = removeHurtArrows(swagShit);
			// }
			if(QuickOptionsSubState.getSetting("Scroll speed") > 0) swagShit.speed = QuickOptionsSubState.getSetting("Scroll speed");
			if (swagShit.noteMetadata == null) swagShit.noteMetadata = Song.defNoteMetadata;
			swagShit.chartType = ChartingState.detectChartType(swagShit);
			return swagShit;
		#if !debug
		}catch(e){MainMenuState.handleError(e,'Error parsing chart: ${e.message}');
			return getEmptySong();
		}
		#end
	}
}
