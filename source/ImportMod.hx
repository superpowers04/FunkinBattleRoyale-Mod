package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import openfl.media.Sound;
import lime.media.AudioBuffer;
import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import flixel.util.FlxTimer;

import haxe.io.Bytes;
import openfl.utils.ByteArray;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;
import se.formats.SongInfo;
import SELoader;

using StringTools;

class ImportMod extends DirectoryListing
{
	var importExisting = false;
	var curReg:EReg = ~/.+\/(.*?)\//g;

	override function create(){
		infoTextBoxSize = 3;
		super.create();
		infotext.text = '${infotext.text}\nPress 1 to toggle importing vanilla songs(Disabled by default to prevent clutter)\nSelect the mods root folder, Example: "games/FNF" not "games/FNF/assets"';
		
	}

	override function handleInput(){
		super.handleInput();
		if (FlxG.keys.justPressed.ONE) {
			importExisting = !importExisting;
			showTempmessage(if(importExisting)"Importing vanilla songs enabled" else "importing vanilla songs disabled");
			SELoader.playSound("assets/sounds/scrollMenu.ogg");
		}
	}
	override function selDir(sel:String){
		curReg.match(sel);
		
		FlxG.switchState(new ImportModFromFolder(sel,curReg.matched(1),importExisting));
	}
}

typedef ZipEntries = haxe.ds.List<haxe.zip.Entry>;
class ImportModFromFolder extends MusicBeatState
{
	var loadingText:FlxText;
	var progress:Float = 0;
	static var existingSongs:Array<String> = ['guns','stress',"ugh","hotdilf","hot-dilf","hot dilf","offsettest", 'tutorial', 'bopeebo', 'fresh', 'dad-battle', 'dad battle', 'dadbattle', 'spookeez', 'south', "monster", 'pico', 'philly-nice', 'philly nice', 'philly', 'phillynice', "blammed", 'satin panties','satin-panties','satinpanties', "high", "milf", 'cocoa', 'eggnog', 'winter-horrorland', 'winter horrorland', 'winterhorrorland', 'senpai', 'roses', 'thorns', 'test'];
	
	var songName:EReg = ~/.+\/(.*?)\//g;
	var songsImported:Int = 0;
	var importExisting:Bool = false;
	var callback:()->Void;

	var name:String;
	var folder:String;
	var done:Bool = false;
	var nameLength = 5;
	var nameoffset = 0;
	var selectedLength = false;
	var chartPrefix:String = "";
	var songList:Array<SongInfo> = [];
	var txt:String = '';
	var acceptInput = false;
	public static function fromZip(path:String = 'requestedFile',?_:Dynamic){
		var input = SELoader.read(path);
		try{

			var entries:ZipEntries = null;
			try{
				entries = haxe.zip.Reader.readZip(input);
				if(entries == null) throw('Zip entries are null. Invalid zip provided?');
			}catch(e){
				throw('Unable to read zip: $e');
			}
			var metadata:haxe.zip.Entry = null;
			var subfolder:String = "";
			var canBreakMeta=false;
			var canBreakSubfolder=false;
			var assumedType:String = "";
			for(entry in entries){
				if(entry.fileName.substring(entry.fileName.length-1)=='/'){
					if(canBreakMeta || !(assumedType == "" || assumedType == "script")) continue; 
					var name = entry.fileName;
					if(name.contains('/manifest') || name.contains('/mods')){
						assumedType="exec";
					}else if(!name.contains('assets/') && (name.contains('characters/') || name.contains('charts/') || name.contains('scripts/'))){
						assumedType="pack";
					}

					continue;
				}
				if(!canBreakMeta && (assumedType == "" || assumedType == "script")){ // scripts can be provided in packs and shit so if we find another type, it's probably that and NOT a script
					if(entry.fileName.endsWith('character.png')){
						assumedType="char";
					}
					if(entry.fileName.endsWith('Inst.ogg')){
						assumedType="chart";
					}
					if(entry.fileName.toLowerCase().endsWith('options.json') || entry.fileName.toLowerCase().endsWith('script.hscript') || entry.fileName.toLowerCase().endsWith('script.hx')){
						assumedType="script";
					}
				}
				if(entry.fileName.toLowerCase().endsWith("semetadata.txt")){
					metadata = entry;
					if(canBreakSubfolder) break;
					canBreakMeta=true;
					assumedType="";
					continue;
				}
				if(!canBreakSubfolder && entry.fileName.contains('/')){
					var sub = entry.fileName.substring(0,entry.fileName.indexOf('/'));
					if(subfolder == ""){
						subfolder = sub;
					}else if(subfolder != sub){
						canBreakSubfolder = true;
						subfolder = "";
						
					}
				}else{
					if(canBreakMeta) break;
					canBreakSubfolder = true;
				}

			}

			var metaContent:Map<String,String> = [];
			if(metadata != null){

				entries.remove(metadata);
				var meta = haxe.zip.Reader.unzip(metadata).toString();
				if(meta.contains('=')){
					var metaList = meta.split('\n');
					for(meta in metaList){
						var index = meta.indexOf('=');
						if(index > -1){
							metaContent[meta.substring(0,index).toLowerCase()] = meta.substring(index+1);
						}
					}
				}else{
					metaContent['type'] = meta;
				}
			}else if(assumedType == ""){
				throw('Unable to auto-detect zip type');
			}else{
				metaContent['type'] = assumedType;
			}
			switch(metaContent['type']){
				case "character" | "char":{
					var char = metaContent['charname'] ?? metaContent['name'] ?? subfolder ?? 'unlabelled-${Date.now().getTime()}';

					var charFolder = metaContent['pack'] != null ? './mods/packs/${metaContent["pack"]}/characters/$char' : './mods/characters/$char';
					extractContent(input,entries,charFolder,subfolder);
				}
				case "chart" | "song":{
					var char = metaContent['songname'] ?? metaContent['name'] ?? subfolder ?? 'unlabelled-${Date.now().getTime()}';

					var charFolder = metaContent['pack'] != null ? './mods/packs/${metaContent["pack"]}/charts/$char' : './mods/charts/$char';
					extractContent(input,entries,charFolder,subfolder);
				}
				case "script":{
					var char = metaContent['name'] ?? subfolder ?? 'unlabelled-${Date.now().getTime()}';

					var charFolder = metaContent['pack'] != null ? './mods/packs/${metaContent["pack"]}/scripts/$char' : './mods/scripts/$char';
					extractContent(input,entries,charFolder,subfolder);
				}
				case "pack":{
					var char = metaContent['name'] ?? subfolder ?? 'unlabelled-${Date.now().getTime()}';

					var charFolder = './mods/packs/$char/';
					extractContent(input,entries,charFolder,subfolder);
				}
				case "exec" | "psych":{
					var char = metaContent['name'] ?? subfolder ?? 'unlabelled-${Date.now().getTime()}';

					var charFolder = './mods/packs/$char/';
					var newEntries:ZipEntries = new ZipEntries();
					for(entry in entries){
						if(!entry.fileName.contains('assets/') && !entry.fileName.contains('mods/')) continue;
						newEntries.push(entry);
					}
					extractContent(input,newEntries,charFolder,subfolder);
				}
				default:
					throw('Unrecognised mod type ${metaContent['type']}');
			}
			Options.ReloadCharlist.RELOAD();
			sys.FileSystem.deleteFile('./requestedFile'); // Hardcoded for now just so I don't have to worry about security
		}catch(e){
			input.close();
			trace('${e}\n${e.stack}');
			// if(path != "" && SELoader.exists(path) && !SELoader.isDirectory(path)){
				try{
					// sys.io.FileSystem.deleteFile(path);
					sys.FileSystem.deleteFile('./requestedFile'); // Hardcoded for now just so I don't have to worry about security

				}catch(e){
					trace('Unable to delete file $path;$e');
				}
			// }
			throw(e);
		}
	}
	public static function extractContent(input:sys.io.FileInput,entries:ZipEntries,startPath:String,subFolder:String){
		startPath = SELoader.cleanPath(SELoader.getPath(startPath));
		if(SELoader.exists(startPath) || SELoader.isDirectory(startPath)){
			startPath+=Date.now().getTime();
		}
		if(SELoader.exists(startPath) || SELoader.isDirectory(startPath)){
			throw('$startPath already exists, unable to extract!');
		}
		for(entry in entries){
			var name = entry.fileName;
			if(name.substring(name.length-1)=='/') continue;
			if(subFolder!="") name=name.substring(subFolder.length+1);
			name = startPath+'/'+name;
			SELoader.createDirectory(name.substring(0,name.lastIndexOf('/')));
			var output = SELoader.write(name);
			var bytes = haxe.zip.Reader.unzip(entry);
			output.writeBytes(bytes,0,bytes.length);
			output.close();
		}

	}

	function changeText(str){
		txt = str;
		// loadingText.screenCenter(X);
		return;
	}

	public function new (folder:String,name:String,?importExisting:Bool = false,?callback:()->Void)
	{
		super();
		this.callback = callback;
		this.name = name;
		this.folder = folder;
		this.importExisting = importExisting;
	}

	override function create()
	{
		try{

		var bg:FlxSprite = SELoader.loadFlxSprite('assets/images/onlinemod/online_bg2.png');
		add(bg);


		loadingText = new FlxText(100, 100, FlxG.width, "Finding songs");
		loadingText.setFormat(CoolUtil.font, 28, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		


		super.create();
		add(loadingText);
		folder = FileSystem.absolutePath(folder);
			// done = selectedLength = true;
			// changedText = '${folder} doesn\'t have a assets folder!';
			// loadingText.color = FlxColor.RED;
			// FlxG.sound.play(Paths.sound('cancelMenu'));
			// return;
		// changeText('Finding songs');
		sys.thread.Thread.create(() -> {
			if (folder == Sys.getCwd() || folder == SELoader.getPath('')) {//This folder is the same folder that FNFBR is running in!
				acceptInput = done = selectedLength = true;
				changeText('You\'re trying to import songs from me!');
				loadingText.color = FlxColor.RED;
				SELoader.playSound('assets/sounds/cancelMenu.ogg');
				return;
			}
			var _songList = SELoader.getSongsFromFolder(folder);
			for(song in _songList){
				if(!importExisting && existingSongs.contains(song.name.toLowerCase())) continue;
				songList.push(song);
			}


			if(songList.length > 0){
				chartPrefix = name;
				loadingText.alignment = CENTER;
				acceptInput = true;
				changeText('${songList.length} songs will be placed under:'+
					'\nmods/packs/${name}/charts'+
					'\nPress Enter to continue'+
					"\nPress Escape to go back");
				return;
			}
			acceptInput = done = selectedLength = true;
			loadingText.color = FlxColor.RED;
			SELoader.playSound('assets/sounds/cancelMenu.ogg');
			// trace(folder);
			changeText('${folder.substr(-17)} doesn\'t contain any songs!' + (if(!importExisting) "\nMaybe try allowing vanilla songs to be imported?\n*(Press 1 to toggle importing vanilla songs in the list)" else ""));

		});
		
		}catch(e){MainMenuState.handleError(e,'Something went wrong when trying to scan for songs! ${e.message}');}
	}
	function doDraw(){draw();}
	function scanSongs(){
		try{
			var importPath = new SEDirectory('mods/packs/${chartPrefix}/charts');
			for(song in songList){
				changeText('Copying ${song.name}...');
				var path = new SEDirectory(song.path);
				var importPath= importPath.newDirectory(song.name);
				for(chart in song.charts){
					SELoader.importFile(path.appendPath(chart),importPath.appendPath(chart));
				}
				if(SELoader.exists(song.inst)){
					SELoader.importFile(song.inst,importPath.appendPath('Inst.ogg'));
				}
				if(SELoader.exists(song.voices)){
					SELoader.importFile(song.voices,importPath.appendPath('Voices.ogg'));
				}
				songsImported++;
			}
		}catch(e){
			MainMenuState.handleError('Something went wrong when trying to import songs ${e.details()}');
		}
	}
	
	override function update(elapsed:Float) {
		if(acceptInput) {

			if ((done && FlxG.keys.justPressed.ANY) || FlxG.keys.justPressed.ESCAPE) {
				if(callback != null){
					callback();
				}else{
					FlxG.switchState(new MainMenuState());
				}

			}
			if(!selectedLength){
				if(FlxG.keys.justPressed.ENTER){
					selectedLength = true;
					changeText("Scanning for songs..\nThe game may "+ (Sys.systemName() == "Windows" ? "'not respond'" : "freeze") + " during this process");
					sys.thread.Thread.create(() -> {
						// new FlxTimer().start(0.6, function(tmr:FlxTimer){
						scanSongs();
						changeText('Imported ${songsImported} songs.\n They should appear under "mods/packs/${name}/charts" \nPress any key to go to the main menu');
						// loadingText.x -= 70;
						done = true;
						// });
					}); // Make sure the text is actually printed onto the screen before doing anything
				}
				// if(FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT){
				// 	updateLoadinText(FlxG.keys.pressed.SHIFT,FlxG.keys.justPressed.LEFT);
				// }
			}
		}
		if(txt != loadingText.text){
			loadingText.text = txt;
		}
		loadingText.screenCenter(XY);
		super.update(elapsed);
		
	}


}
