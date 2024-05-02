package;

import Song;




using StringTools;

import flixel.FlxG;

// A rewrite of how FNF songs are read, intended to prevent changing bpm and such to break the current song's time
// While you can convert into this format, converting out will be a bit finnicky

class SESONG{
	/* Note related shite */
		public var songNotes:Array<Array<Dynamic>> = []; // [TIME:Float, DIRECTION:Int, SustainLengthInMS:Float, TYPE:Dynamic, ...]
		public var noteToRaw:Map<Note,Array<Dynamic>> = []; // Allows access to a note's raw metadata. 
		// This is to allow the notes array to change without needing to keep track of every id or looping through the entire fucking array to get a note's raw data
		
		public var eventNotes:Array<Array<Dynamic>> = []; // [TIME:Float, TYPE:Dynamic, ...]
		public var mustHitSwitches:Array<Array<Dynamic>> = []; // [TIME:Float, ISMUSTHIT:Bool]
		public var BPMChanges:Array<Array<Dynamic>> = []; // [TIME:Float, BPM:Float]
		public var arrayCurrents:Map<Dynamic,Int> = []; // Array:Array<Dynamic> => CurrentIndex:Int

		// public var notes(get,never):Array<SwagSection>; // fucking piece of shit FNF syntax; Basic compatibility layer, it'll always return the current "section"
		// var _section:SwagSection; // The above uses this, this is changed every time FNF would normally go into a new section 
		// public function get_notes(){
			
		// 	return sect;
		// }

	/*Player Shite*/
		public var player1:String; // Player
		public var player2:String; // Opponent
		public var gf:String; // GF
		public var stage:String; // The stage
		public var forceCharacters(get,default):Bool = false; // Whether characters from the chart should be forced. Always enabled when charting
			public function get_forceCharacters() return ChartingState.charting || PlayState.isStoryMode || forceCharacters;
		/* Helper variables */
			public var player3(get,set):String; // Redirect to GF
				public function get_player3() return gf;
				public function set_player3(val) return gf = val;
			public var gfVersion(get,set):String; // Redirect to GF
				public function get_gfVersion() return gf;
				public function set_gfVersion(val) return gf = val;

	/* Metadata */
		public var BPM:Float = 120; // BPM
		public var song_BPM:Float = 120; // BPM
		public var scrollSpeed:Float = 1;
		public var chartVersion:String; // The version of the game the chart was created with
		public var rawJSON:Dynamic; // The raw JSON of the chart
		public var focusPlayer:Bool = false; // MusthitSection but without changing the note ids
		public var name:String = "Unspecified"; // Song name
		public var song(get,set):String;
		public var needsVoices:Bool = false;
		public function get_song() return name;
		public function set_song(v) return name = v;

	/**/
	public function new(){

	}
	public function importLegacy(song:SwagSong):SESONG{ // Returns itself because funni
		var curBPM:Float = Math.abs(song.bpm);
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		var mustHit:Bool = false;
		for (i in 0...song.notes.length)
		{
			var section = song.notes[i];
			if(section.changeBPM && section.bpm != curBPM)
			{
				curBPM = Math.abs(section.bpm);
				BPMChanges.push([totalPos,curBPM]);
			}
			if(i == 0){
				focusPlayer = mustHit = section.mustHitSection;
			}else if (section.mustHitSection != mustHit){
				mustHit = section.mustHitSection;
				mustHitSwitches.push([totalPos,mustHit]);
			}
			var nid:Int = 0; // Note ID
			while (nid < section.sectionNotes.length){
				var note = section.sectionNotes[nid];

				nid++;
				if(note[1] < 0){
					eventNotes.push(note);
				}else{
					if(!section.mustHitSection) note[1] = (note[1] + 4) % 8;
					songNotes.push(note);
				}
			}

			var deltaSteps:Int = section.lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
		BPM = song.bpm;
		player1 = song.player1;
		player2 = song.player2;
		gf = song.gfVersion;
		scrollSpeed = song.speed;
		stage = song.stage;
		name = song.song;
		needsVoices = song.needsVoices;
		forceCharacters = song.forceCharacters;
		return this;
	}

	public static function importFromLegacy(song:SwagSong):SESONG{ return new SESONG().importLegacy(song); }
	public function resetCurrent(Obj:Dynamic){
		if(arrayCurrents.get(Obj) != null){
			arrayCurrents.set(Obj,0);
		}
	}

	public function update(el:Float){
		var bpm:Float = cast getCurrentPast(BPMChanges,Conductor.songPosition);
		focusPlayer = cast getCurrentPast(mustHitSwitches,Conductor.songPosition);
		if(Conductor.bpm != bpm) Conductor.changeBPM(bpm);
	}
	// public function stepHit(step:Int){
	// 	if(step / 16 == 0 ){
	// 		updateSection();
	// 	}
	// }
	// var curNoteID:Int = 0;
	// public function updateSection(){
	// 	var noteList:Array<Array<Dynamic>> = [];
	// 	while (songNotes[curNoteID] != null && songNotes[curNoteID][0] < Conductor.songPosition + )
	// }
	public function generateNotes(song:SESONG,?jumpTo:Float = 0):Array<Note>{
		var unspawnNotes:Array<Note> = [];
		for (songNotes in eventNotes){
			var daStrumTime = songNotes[0] + SESave.data.offset;

			var daNoteData:Int = songNotes[1];


			if(jumpTo != 0 && daStrumTime < jumpTo){continue;} // Don't load notes if they aren't from this timezone
			var swagNote:Note = new Note(daStrumTime, -1, null,false,false,songNotes[3],songNotes,false);
			if(swagNote.killNote){swagNote.destroy();continue;}

			var susLength:Float = swagNote.sustainLength;
			unspawnNotes.push(swagNote);
		}
		for (songNotes in songNotes){
				var daStrumTime = songNotes[0] + SESave.data.offset;
				if (daStrumTime < 0)
					daStrumTime = 0;


				var daNoteData:Int = songNotes[1];


				var gottaHitNote:Bool = (daNoteData % 8 > 3);

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;
				if(jumpTo != 0 && daStrumTime < jumpTo){continue;} // Don't load notes if they aren't from this timezone
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote,false,false,songNotes[3],songNotes,gottaHitNote);
				if(swagNote.killNote){swagNote.destroy();continue;}
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);
				var lastSusNote = false; // If the last note is a sus note
				var _susNote = -1;
				if(susLength > 0.1){

					for (susNote in 0...Math.floor(susLength))
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true,false,songNotes[3],songNotes,gottaHitNote);
						if(sustainNote.killNote){sustainNote.destroy();continue;}
						sustainNote.scrollFactor.set();
						sustainNote.sustainLength = susLength;
						unspawnNotes.push(sustainNote);
						lastSusNote = true;
						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						_susNote = susNote;
					}
					if(susLength % 1 > 0.1){ // Allow for float note lengths, hopefully
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * _susNote) + (Conductor.stepCrochet * (susLength % 1)), daNoteData, oldNote, true,false,songNotes[3],songNotes,gottaHitNote);
						sustainNote.scrollFactor.set();
						sustainNote.sustainLength = susLength;
						unspawnNotes.push(sustainNote);
						lastSusNote = true;


						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}

					}

					if (onlinemod.OnlinePlayMenuState.socket == null && lastSusNote){ // Moves last sustain note so it looks right, hopefully
						var note = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						note.strumTime = unspawnNotes[Std.int(unspawnNotes.length - 2)].strumTime + (Conductor.stepCrochet * 0.5);
					}
				}

				// swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
			}
		return unspawnNotes;
	}

	public function reset(){
		BPM = song_BPM;
		arrayCurrents = [];
	}
	public function getCurrent(Obj:Dynamic,inc:Bool = false):Dynamic{ // Allows you to access a value without it needing to be wiped
		if(arrayCurrents.get(Obj) == null){
			arrayCurrents.set(Obj,0);
		}
		var count = arrayCurrents.get(Obj);
		if(inc){
			arrayCurrents.set(Obj,count + 1);
		}
		return Obj.get(count);
	}
	public function getCurrentPast(Obj:Dynamic,time:Float):Dynamic{ // Allows you to access a value
		if(arrayCurrents.get(Obj) == null){
			arrayCurrents.set(Obj,0);
		}
		var count = arrayCurrents.get(Obj);
		while(Obj.get(count)[0] < time){
			arrayCurrents.set(Obj,count++);
		}
		return Obj.get(count - 1);
	}
}
