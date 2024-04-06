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
			FlxG.sound.play(Paths.sound("scrollMenu"), 0.4);
		}
	}
	override function selDir(sel:String){
		curReg.match(sel);
		
		FlxG.switchState(new ImportModFromFolder(sel,curReg.matched(1),importExisting));
	}
}


class ImportModFromFolder extends MusicBeatState
{
	var loadingText:FlxText;
	var progress:Float = 0;
	static var existingSongs:Array<String> = ['guns','stress',"ugh","hotdilf","hot-dilf","hot dilf","offsettest", 'tutorial', 'bopeebo', 'fresh', 'dad-battle', 'dad battle', 'dadbattle', 'spookeez', 'south', "monster", 'pico', 'philly-nice', 'philly nice', 'philly', 'phillynice', "blammed", 'satin panties','satin-panties','satinpanties', "high", "milf", 'cocoa', 'eggnog', 'winter-horrorland', 'winter horrorland', 'winterhorrorland', 'senpai', 'roses', 'thorns', 'test'];
	
	var songName:EReg = ~/.+\/(.*?)\//g;
	var songsImported:Int = 0;
	var importExisting:Bool = false;

	var name:String;
	var folder:String;
	var done:Bool = false;
	var nameLength = 5;
	var nameoffset = 0;
	var selectedLength = false;
	var chartPrefix:String = "";
	var folderList:Array<String> = []; 
	var isSuperEngine:Bool = false;
	var changedText(null,set):String= "";
	inline function set_changedText(str){
		loadingText.text = changedText;
		loadingText.screenCenter(X);
		return "";
	}

	public function new (folder:String,name:String,?importExisting:Bool = false)
	{
		super();

		this.name = name;
		this.folder = folder;
		this.importExisting = importExisting;
	}

	var valid = false;
	override function create()
	{
		try{

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('onlinemod/online_bg2'));
		add(bg);


		loadingText = new FlxText(FlxG.width/4, FlxG.height/2 - 36, FlxG.width, "empty");
		loadingText.setFormat(CoolUtil.font, 28, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(loadingText);


		super.create();
		folder = FileSystem.absolutePath(folder);
			// done = selectedLength = true;
			// changedText = '${folder} doesn\'t have a assets folder!';
			// loadingText.color = FlxColor.RED;
			// FlxG.sound.play(Paths.sound('cancelMenu'));
			// return;
		
		if (folder == Sys.getCwd() || folder == SELoader.getPath('')) {//This folder is the same folder that FNFBR is running in!
			done = selectedLength = true;
			changedText = 'You\'re trying to import songs from me!';
			loadingText.color = FlxColor.RED;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		} 
		
		var assets = ('${folder}assets/').replace('//','/'); // For easy access
		// This is a mess

		if(FileSystem.exists(assets)) { 
			if(FileSystem.exists('${assets}songs/')){ // Assets/songs
				for (directory in FileSystem.readDirectory('${assets}songs/')) {
					if(!FileSystem.isDirectory('${assets}songs/${directory}') || (!importExisting && existingSongs.contains(directory.toLowerCase()))) continue; // Skip if it's a file or if it's on the existing songs list
					var dir:String = '${folder}assets/songs/${directory}/';
					if(!(FileSystem.exists('${dir}Inst.ogg') || FileSystem.exists('${dir}${directory}-Inst.ogg')) || (!FileSystem.isDirectory('${assets}data/${directory}/') && !FileSystem.isDirectory('${assets}data/songs/${directory}/')) ) {trace('"${assets}data/${directory}/" or "${dir}Inst.ogg" doesnt exist');continue;}
					valid = true;
					break;
				}
			}
			if(FileSystem.exists('${assets}music/')){ // Assets/music
				for (directory in FileSystem.readDirectory('${assets}music/')) {
					if(!importExisting && existingSongs.contains(directory.toLowerCase())) {continue;} // Skip if it's on the existing songs list
					var dir:String = '${folder}assets/music/${directory.substr(0,-4)}-';
					if(!FileSystem.isDirectory('${assets}data/${directory}/') ) {trace('"${assets}data/${directory}/" doesnt exist');continue;}
					valid = true;
					break;
				}
			}
		}
		if(FileSystem.exists('${folder}songs/')){ // Check if the selected directory just has a songs folder
			for (directory in FileSystem.readDirectory('${folder}songs/')) {
				directory = directory.replace('//','/');
				if(!FileSystem.isDirectory('${folder}songs/${directory}') || (!importExisting && existingSongs.contains(directory.toLowerCase()))) continue; // Skip if it's a file or if it's on the existing songs list
				var dir:String = ('${folder}/songs/${directory}/').replace('//','/');

				if(!FileSystem.exists('${dir}Inst.ogg') || (!FileSystem.isDirectory('${assets}data/${directory}/') && 
						!FileSystem.isDirectory('${assets}data/songs/${directory}/') && 
						!FileSystem.isDirectory('${assets}data/song data/${directory}/') // Leather Engine????
					)) {trace('"${assets}data/${directory}/" or "${dir}Inst.ogg" doesnt exist');continue;}
				folderList.push('${folder}');
				break;
			}
		}
		if(FileSystem.exists('${folder}mods/')){ // Psych Engine mods folder
			if(FileSystem.exists('${folder}mods/songs') && FileSystem.isDirectory('${folder}mods/songs')){
				// folderList.push('${folder}mods/');
				var dir:String = '${folder}mods/';
				trace(dir);
				for (directory in FileSystem.readDirectory('${dir}songs/')) {
					if(!FileSystem.isDirectory('${dir}songs/${directory}') || (!importExisting && existingSongs.contains(directory.toLowerCase()))) continue; // Skip if it's a file or if it's on the existing songs list
					var _dir:String = ('${dir}songs/${directory}/').replace('//','/');
					trace(_dir);
					if(!FileSystem.exists('${_dir}Inst.ogg') || (!FileSystem.isDirectory('${dir}data/${directory}/') )) {trace('"${dir}data/${directory}/" or "${dir}Inst.ogg" doesnt exist');continue;}
					folderList.push('${folder}mods/');
					break;
				}
			}

			for (directory in FileSystem.readDirectory('${folder}mods/')) {
				if(!FileSystem.isDirectory('${folder}mods/$directory')){continue;}
				// if(!importExisting && existingSongs.contains(directory.toLowerCase())) {continue;} // Skip if it's on the existing songs list
				var dir:String = '${folder}mods/${directory}/';
				if(!FileSystem.exists('${dir}songs/')){continue;}
				for (directory in FileSystem.readDirectory('${dir}songs/')) {
					if(!FileSystem.isDirectory('${dir}songs/${directory}') || (!importExisting && existingSongs.contains(directory.toLowerCase()))) continue; // Skip if it's a file or if it's on the existing songs list
					var _dir:String = ('${dir}songs/${directory}/').replace('//','/');
					if(!FileSystem.exists('${_dir}Inst.ogg') || (!FileSystem.isDirectory('${dir}data/${directory}/') )) {trace('"${dir}data/${directory}/" or "${dir}Inst.ogg" doesnt exist');continue;}
					folderList.push('${folder}mods/${directory}/');
					break;
				}
			}
			
		}
		if(valid || folderList.length > 0){
			chartPrefix = name;
			loadingText.alignment = CENTER;
			changedText = 'Songs will be placed under:'+
				'\nmods/packs/${name}/charts'+
				'\nPress Enter to continue'+
				"\nPress Escape to go back";
		}else{
			done = selectedLength = true;
			loadingText.color = FlxColor.RED;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			trace(folder);
			changedText = '${folder.substr(-17)} doesn\'t contain any songs!' + (if(!importExisting) "\nMaybe try allowing vanilla songs to be imported?\n*(Press 1 to toggle importing vanilla songs in the list)" else "");

		}
		}catch(e){MainMenuState.handleError(e,'Something went wrong when trying to scan for songs! ${e.message}');}
	}
	function doDraw(){draw();}
	function scanSongs(?folder:String = "",assets:String=""){
		try{
			if(FileSystem.exists('${assets}songs/')){ // Chad github style
				var inCharts = 
					(FileSystem.isDirectory('${assets}data/songs/') ? '${assets}data/songs/' : 
					(FileSystem.isDirectory('${assets}data/song data/') ? '${assets}data/song data/'
					:'${assets}data/')); // Fuckin later versions of kade engine
				for (directory in FileSystem.readDirectory('${assets}songs/')) {
					changedText = 'Checking ${directory}...'; // Just display this text
					
					if(!FileSystem.isDirectory('${assets}songs/${directory}') || (!importExisting && existingSongs.contains(directory.toLowerCase()))) 
						continue; // Skip if it's a file or if it's on the existing songs list
					var dir:String = '${assets}songs/${directory}/';
					if(!FileSystem.exists('${dir}Inst.ogg') || !FileSystem.isDirectory('${inCharts}${directory}/') ) {
						trace('"${inCharts}${directory}/" or "${dir}Inst.ogg" doesnt exist');
						continue;
					}

					var outDir:String = 'mods/packs/${chartPrefix}/charts/${directory}/';
					try{FileSystem.createDirectory(outDir);}catch(e) MainMenuState.handleError('Error while creating folder, ${e.message}');
					try{
						changedText = 'Copying Inst...';
						SELoader.importFile('${dir}Inst.ogg','${outDir}Inst.ogg');
					}catch(e) trace('Importing inst caused ${e.message}');
					try{
						changedText = 'Copying Voices...';
						SELoader.importFile('${dir}Voices.ogg','${outDir}Voices.ogg');
					}catch(e) trace('Importing voices caused ${e.message}');
					for (file in FileSystem.readDirectory('${inCharts}${directory}/')) {
						try{
							changedText = 'Copying ${file}...';// Just display this text
					
							SELoader.importFile('${inCharts}${directory}/${file}','${outDir}${file}');
						}catch(e) trace('$file caused ${e.message}');
					}
					songsImported++;
				}
			}
		if(FileSystem.exists('${assets}music/')){ // Older itch.io style
			for (directory in FileSystem.readDirectory('${assets}music/')) {
				if (!directory.endsWith("inst.ogg")) continue;
				directory = directory.substr(0,-8);
				changedText = 'Checking ${directory}...'; // Just display this text
				
				if(!importExisting && existingSongs.contains(directory.toLowerCase())) {continue;} // Skip if it's on the existing songs list
				var dir:String = '${folder}assets/music/${directory}-';
				if(!FileSystem.isDirectory('${assets}data/${directory}/') ) {trace('"${assets}data/${directory}/" doesnt exist');continue;}

				var outDir:String = 'mods/packs/${chartPrefix}/charts/${directory}/';
				try{SELoader.createDirectory(outDir);}catch(e) MainMenuState.handleError('Error while creating folder, ${e.message}');
				
				for (i => v in ['${dir}Inst.ogg' => '${outDir}Inst.ogg',
									'${dir}Voices.ogg' => '${outDir}Voices.ogg']) {
					try{
						changedText = 'Copying ${i}...';// Just display this text
				
						SELoader.importFile(i,v);
					}catch(e) trace('$i caused ${e.message}');
				}
				for (file in FileSystem.readDirectory('${assets}data/${directory}/')) {
					try{
						changedText = 'Copying ${file}...';// Just display this text
				
						SELoader.importFile('${assets}data/${directory}/${file}','${outDir}${file}');
					}catch(e) trace('$file caused ${e.message}');

			}
			songsImported++;
		}}
		}catch(e) MainMenuState.handleError('Error while trying to scan for songs, ${e.message}');
	}
	
	function scanSongFolders(){
		if(valid)scanSongs(folder,'${folder}assets/');
		for (i => v in folderList) {
			scanSongs(v,v);
		}
	}
	override function update(elapsed:Float)
	{
		loadingText.screenCenter(XY);
		if ((done && FlxG.keys.justPressed.ANY) || FlxG.keys.justPressed.ESCAPE) {
			FlxG.switchState(new MainMenuState());
		}
		if(!selectedLength){
			if(FlxG.keys.justPressed.ENTER){
				selectedLength = true;
				changedText = "Scanning for songs..\nThe game may "+ (if(Sys.systemName() == "Windows")"'not respond'" else "freeze") + " during this process";
				sys.thread.Thread.create(() ->
				{
					// new FlxTimer().start(0.6, function(tmr:FlxTimer){
					scanSongFolders();
					changedText = 'Imported ${songsImported} songs.\n They should appear under "mods/packs/${name}/charts" \nPress any key to go to the main menu';
					loadingText.x -= 70;
					done = true;
					// });
				}); // Make sure the text is actually printed onto the screen before doing anything
			}
			// if(FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT){
			// 	updateLoadinText(FlxG.keys.pressed.SHIFT,FlxG.keys.justPressed.LEFT);
			// }
		}
		super.update(elapsed);
	}


}
