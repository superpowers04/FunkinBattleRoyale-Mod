package;

import Section.SwagSection;
import tjson.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import flixel.FlxG;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var ?defplayer1:String;
	var ?defplayer2:String;
	var ?defgf:String;
	var gfVersion:String;
	var ?noteStyle:String;
	var stage:String;
	var validScore:Bool;
	var ?noteMetadata:NoteMetadata;
	var ?difficultyString:String;
	var ?inverthurtnotes:Bool;
	var ?rawJSON:Dynamic;
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

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = CoolUtil.cleanJSON(Assets.getText(Paths.json(folder.toLowerCase() + '/' + jsonInput.toLowerCase())));

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		return parseJSONshit(rawJson);
	}

	static function invertChart(swagShit:SwagSong):SwagSong{
		var invertedNotes:Array<Int> = [4,5,6,7,0,1,2,3];
		for (sid => section in swagShit.notes) {
			section.mustHitSection = !section.mustHitSection;
			swagShit.notes[sid] = section;
		}
		return swagShit;
	}


	static function modifyChart(swagShit:SwagSong):SwagSong{
		var hurtArrows = (QuickOptionsSubState.getSetting("Custom Arrows") || onlinemod.OnlinePlayMenuState.socket != null);
		var opponentArrows = (onlinemod.OnlinePlayMenuState.socket != null || QuickOptionsSubState.getSetting("Custom Arrows"));
		var invertedNotes:Array<Int> = [4,5,6,7];
		var oppNotes:Array<Int> = [0,1,2,3];
		// if(FlxG.save.data.regenSong){
		// 	var notes:Array<Array<Dynamic>> = [];
		// 	var curBPM:Float = swagShit.bpm;
		// 	var totalSteps:Int = 0;
		// 	var lastPos:Float = 0;
		// 	var totalPos:Float = 0;
		// 	// var 
		// 	// var sections = Array<SwagSection>;
		// 	// var noteTimeEnding:Float = 0;
		// 	for (sid => section in swagShit.notes) {
		// 		if(section.sectionNotes == null || section.sectionNotes[0] == null) continue;

		// 		// var sN:Array<Array<Dynamic>> = [];

		// 		for (nid in 0 ... section.sectionNotes.length){ // Regenerate section, is a bit fucky but only happens when loading
		// 			var note:Array<Dynamic> = section.sectionNotes[nid];
		// 			// Removes opponent arrows 
		// 			if (!opponentArrows && (section.mustHitSection && invertedNotes.contains(note[1]) || !section.mustHitSection && oppNotes.contains(note[1]))){trace("Skipping note");continue;}


		// 			if (hurtArrows){ // Weird if statement to prevent the game from removing hurt arrows unless they should be removed
		// 				if(note[4] == 1 || note[1] > 7) {note[3] = 1;} // Support for Andromeda and tricky notes
		// 			}else{
		// 				note[3] = 0;
		// 			}
		// 			note[note.length + 1] =section.mustHitSection; 
		// 			// sN.push(note);
		// 			notes.push(note);
		// 		}
		// 		section.sectionNotes = [];
		// 		// swagShit.notes[sid].sectionNotes = sN;

		// 	}
		// 	haxe.ds.ArraySort.sort(notes, function(a, b) {
		// 	   if(a[0] < b[0]) return -1;
		// 	   else if(b[0] > a[0]) return 1;
		// 	   else return 0;
		// 	});
		// 	notes.reverse();
		// 	for (sid => section in swagShit.notes) {
		// 		if(section.changeBPM){
		// 			curBPM = section.bpm;
		// 		}
		// 		if(section.changeBPM && section.bpm != curBPM)
		// 		{
		// 			curBPM = section.bpm;
		// 		}

		// 		var deltaSteps:Int = section.lengthInSteps;
		// 		totalSteps += deltaSteps;
		// 		totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		// 		var notesLeft = true;
		// 		while (notesLeft){
		// 			var note = notes[notes.length];
		// 			if(notes[0][0] > lastPos && notes[0][0] < totalPos){
		// 				if(section.mustHitSection != note[note.length] && note[1] > -1) {note[1] = note[1] + 4 % 8 - 1;}
		// 				note[note.length] = null;
		// 				section.sectionNotes.push(notes.pop());
		// 			}else{notesLeft = false;}
		// 		}
		// 		lastPos = totalPos;
		// 	}
		// 	if(notes[0] != null){
		// 		while(notes[0] != null){
		// 			var section:SwagSection = {
		// 				sectionNotes : [],
		// 				typeOfSection:0,
		// 				lengthInSteps:16,
		// 				bpm:curBPM,
		// 				changeBPM:false,
		// 				altAnim:false,
		// 				mustHitSection:false
		// 			};
		// 			totalSteps += 16;
		// 			totalPos += ((60 / curBPM) * 1000 / 4) * 16;
		// 			var notesLeft = true;
		// 			while (notesLeft){
		// 				var note = notes[notes.length];

		// 				if(note[0] > lastPos && note[0] < totalPos){
		// 					if(section.mustHitSection != note[note.length] && note[1] > -1){
		// 						note[1] = note[1] + 4 % 8 - 1;
		// 					}; 
		// 					note[note.length] = null;
		// 					section.sectionNotes.push(notes.pop());
		// 				}else{
		// 					notesLeft = false;
		// 				}
		// 			}
		// 			lastPos = totalPos;
		// 			swagShit.notes.push(section);
		// 		}
		// 	}

		// }else{

			for (sid => section in swagShit.notes) {
				if(section.sectionNotes == null || section.sectionNotes[0] == null) continue;

				var sN:Array<Array<Dynamic>> = [];

				for (nid in 0 ... section.sectionNotes.length){ // Regenerate section, is a bit fucky but only happens when loading
					var note:Array<Dynamic> = section.sectionNotes[nid];
					// Removes opponent arrows 
					if (!opponentArrows && (section.mustHitSection && invertedNotes.contains(note[1]) || !section.mustHitSection && oppNotes.contains(note[1]))){trace("Skipping note");continue;}
					
					if (hurtArrows){ // Weird if statement to prevent the game from removing hurt arrows unless they should be removed
						if(note[3] == 0 && (note[4] == 1 || note[1] > 7)) {note[3] = 1;} // Support for Andromeda and tricky notes
					}else{
						note[3] = null;
					}
					sN.push(note);

				}
				swagShit.notes[sid].sectionNotes = sN;
				
				haxe.ds.ArraySort.sort(swagShit.notes[sid].sectionNotes, function(a, b) {
				   if(a[0] < b[0]) return -1;
				   else if(b[0] > a[0]) return 1;
				   else return 0;
				});
			}

		// }
		// if(swagShit.events[0] != null){
		// 	var sect:SwagSection = {
		// 		changeBPM : false,
		// 		sectionNotes : [],
		// 		bpm:0,
		// 		altAnim:false,
		// 		mustHitSection:false,
		// 		typeOfSection:0,
		// 		lengthInSteps:16
		// 	};
		// 	for (i => v in swagShit.events) {
		// 			// [
		// 			// 	131368.421052631,
		// 			// 	[
		// 			// 		[
		// 			// 			"Hey!",
		// 			// 			"BF",
		// 			// 			"1"
		// 			// 		]
		// 			// 	]
		// 			// ]
		// 		for (id in 0 ... v[1].length) {
		// 			var note = [v[0],-1];
		// 			note.concat(v[1][id]);
		// 			sect.sectionNotes.push(note);
		// 		}
		// 	}
		// 		trace(sect);
		// 	swagShit.notes.push(sect);

		// }
		return swagShit;

	}
	// static function convHurtArrows(swagShit:SwagSong):SwagSong{ // Support for Andromeda and tricky notes
	// 	for (sid => section in swagShit.notes) {
	// 		for (nid => note in section.sectionNotes){
	// 			if(note[4] == 1 || note[1] > 7) {swagShit.notes[sid].sectionNotes[nid][3] = 1;}
	// 		}
	// 	}
	// 	return swagShit;
	// }

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		#if !debug
		try{
		#end
			var rawJson:Dynamic = Json.parse(rawJson);
			var swagShit:SwagSong = cast rawJson.song;
			swagShit.rawJSON = rawJson;
			swagShit.validScore = true;
			swagShit.defplayer1 = swagShit.player1;
			swagShit.defplayer2 = swagShit.player2;
			if (PlayState.invertedChart || (onlinemod.OnlinePlayMenuState.socket == null && QuickOptionsSubState.getSetting("Inverted chart"))) swagShit = invertChart(swagShit);
			swagShit = modifyChart(swagShit);
			// if (QuickOptionsSubState.getSetting("Hurt notes") || onlinemod.OnlinePlayMenuState.socket != null) swagShit = convHurtArrows(swagShit);
			// if (onlinemod.OnlinePlayMenuState.socket == null){
			// 	if (!QuickOptionsSubState.getSetting("Opponent arrows")) swagShit = removeOpponentArrows(swagShit);
			// 	if (!QuickOptionsSubState.getSetting("Hurt notes")) swagShit = removeHurtArrows(swagShit);
			// }
			if(QuickOptionsSubState.getSetting("Scroll speed") > 0) swagShit.speed = QuickOptionsSubState.getSetting("Scroll speed");
			if (swagShit.noteMetadata == null) swagShit.noteMetadata = Song.defNoteMetadata;
			swagShit.defgf = swagShit.gfVersion;
			return swagShit;
		#if !debug
		}catch(e){
			MainMenuState.handleError('Error parsing chart: ${e.message}');
			return {
				song: "Unable to load chart",
				notes: [],
				bpm: 120,
				needsVoices: false,
				player1: 'bf',
				player2: 'bf',
				gfVersion: 'gf',
				noteStyle: 'normal',
				stage: 'stage',
				speed: 2.0,
				validScore: false,
				difficultyString: "e"
			};
		}
		#end
	}
}
