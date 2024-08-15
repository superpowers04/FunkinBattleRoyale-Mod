#if sys
package smTools;
import sys.io.File;
import haxe.Exception;
import lime.app.Application;
import haxe.Json;
import Song;
import Section;

typedef Measure = {
	var notes:Array<SMNote>;
	var measure:Array<String>;
}

class SMFile
{
	public static function loadFile(path):SMFile
	{
		return new SMFile(SELoader.getContent(path).split('\n'));
	}
	
	private var _fileData:Array<String>;

	public var isDouble:Bool = false;

	public var isValid:Bool = true;

	public var _readTime:Float = 0;

	public var header:SMHeader;
	public var measures:Array<Measure>;

	public function new(data:Array<String>)
	{
		// try
		// {
			_fileData = data;

			// Gather header data
			var headerData = "";
			var inc = 0;
			while(!StringTools.contains(data[inc + 1],"//"))
			{
				headerData += data[inc];
				inc++;
				// trace(data[inc]);
			}

			header = new SMHeader(headerData.split(';'));

			// Most likely loading from a state that requires an inst be present 
			// if (!StringTools.contains(header.MUSIC,"ogg"))
			// {
			//     throw("The music MUST be an OGG File.","SM File loading (" + header.TITLE + ")");
			//     isValid = false;
			//     return;
			// }

			// check if this is a valid file, it should be a dance double file.
			inc += 3; // skip three lines down
			if (!StringTools.contains(data[inc],"dance-double:") && !StringTools.contains(data[inc],"dance-single"))
			{
				throw("The file you are loading is neither a Dance Double chart or a Dance Single chart");
				isValid = false;
				return;
			}
			if (StringTools.contains(data[inc],"dance-double:"))
				isDouble = true;
			if (isDouble)
				trace('this is dance double');

			inc += 5; // skip 5 down to where da notes @

			measures = [];

			var measure = "";

			trace(data[inc - 1]);

			for (ii in inc...data.length)
			{
				var i = data[ii];
				if (StringTools.contains(i,",") || StringTools.contains(i,";"))
				{
					measures.push(newMeasure(measure.split('\n')));
					//trace(measures.length);
					measure = "";
					continue;
				}
				measure += i + "\n";
			}
			trace(measures.length + " Measures");
		

		// catch(e:Exception)
		// {
		//     Application.current.window.alert("Failure to load file.\n" + e,"SM File loading");
		// }
	}
	
	public function convertToFNF():SwagSong
	{

		// array's for helds
		var heldNotes:Array<Array<Dynamic>>;

		
		if (isDouble) // held storage lanes
			heldNotes = [[],[],[],[],[],[],[],[]];
		else
			heldNotes = [[],[],[],[]];


		// variables

		var measureIndex = 0;
		var currentBeat:Float = 0;
		var output = "";

		// init a fnf song

		var song:SwagSong = {
				song: header.TITLE,
				notes: [],
				eventObjects: [],
				bpm: header.getBPM(0),
				needsVoices: false,
				player1: 'bf',
				player2: 'bf',
				gfVersion: 'gf',
				noteStyle: 'normal',
				stage: 'stage',
				speed: 2.0,
				validScore: false,
				difficultyString: "Mania",
				chartVersion:"SE-Stepmania"
			}

		// lets check if the sm loading was valid

		if (!isValid)
		{
			return song;
		}

		// aight time to convert da measures

		trace("Converting measures");
		for(measure in measures)
		{
			trace('Looped $measureIndex measures');
			// private access since _measure is private
			@:privateAccess
			var lengthInRows = 192 / (measure.measure.length - 1);

			var rowIndex = 0;

			// section declaration

			var section:SwagSection = {
				sectionNotes: [],
				lengthInSteps: 16,
				typeOfSection: 0,
				// startTime: 0.0,
				// endTime: 0.0,
				mustHitSection: false,
				bpm: header.getBPM(0),
				changeBPM: false,
				altAnim: false
			};

			// if it's not a double always set this to true

			if (!isDouble)
				section.mustHitSection = true;

			for(i in 0...measure.measure.length - 1)
			{
				var noteRow = (measureIndex * 192) + (lengthInRows * rowIndex);

				var notes:Array<String> = [];

				for(note in measure.measure[i].split(''))
				{
					//output += note;
					notes.push(note);
				}

				currentBeat = noteRow / 48;

				var seg = TimingStruct.getTimingAtBeat(currentBeat);

				var timeInSec:Float = (seg.startTime + ((currentBeat - seg.startBeat) / (seg.bpm/60)));

				var rowTime = timeInSec * 1000;

				//output += " - Row " + noteRow + " - Time: " + rowTime + " (" + timeInSec + ") - Beat: " + currentBeat + " - Current BPM: " + header.getBPM(currentBeat) + "\n";

				var index = 0;

				for(i in notes)
				{
					// if its a mine lets skip (maybe add mines in the future??)

					// get the lane and note type
					var lane = index;
					if (i == "M")
					{
					    index++;
					    section.sectionNotes.push([rowTime,lane ,0,1]);
					    continue;
					}
					var numba = Std.parseInt(i);

					// switch through the type and add the note

					switch(numba)
					{
						case 1: // normal
							section.sectionNotes.push([rowTime,lane ,0]);
						case 2: // held head
							heldNotes[lane] = [rowTime,lane,0];
						case 3: // held tail
							var data = heldNotes[lane];
							var timeDiff = rowTime - data[0];
							section.sectionNotes.push([data[0],lane,timeDiff]);
							heldNotes[index] = [];
						case 4: // roll head
							heldNotes[lane] = [rowTime,lane,0];
					}

					index++;
				}


				rowIndex++;
			}

			// push the section

			song.notes.push(section);

			//output += ",\n";

			measureIndex++;
		}



		if (header.changeEvents.length != 0)
		{
			song.eventObjects = header.changeEvents;
		}

		// save da song
		#if linux
		File.saveContent("/tmp/test.json",Json.stringify(song));
		#end
		return song;
	}
	public static function newMeasure(measureData:Array<String>):Measure
	{
		var funni:Measure = {notes:[],measure : measureData};
		// 0 = no note
		// 1 = normal note
		// 2 = head of sustain
		// 3 = tail of sustain

		for(i in measureData)
		{
			for (ii in 0...i.length)
			{
				funni.notes.push(new SMNote(i.split('')[ii],ii));
			}
		}
		return funni;
	}
}
#end