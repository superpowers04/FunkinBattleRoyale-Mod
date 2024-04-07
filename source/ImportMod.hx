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
	var songList:Array<SongInfo> = [];
	function changeText(str){
		loadingText.text = str;
		loadingText.screenCenter(X);
		return;
	}

	public function new (folder:String,name:String,?importExisting:Bool = false)
	{
		super();

		this.name = name;
		this.folder = folder;
		this.importExisting = importExisting;
	}

	override function create()
	{
		try{

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('onlinemod/online_bg2'));
		add(bg);


		loadingText = new FlxText(100, 100, FlxG.width, "empty");
		loadingText.setFormat(CoolUtil.font, 28, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		


		super.create();
		add(loadingText);
		folder = FileSystem.absolutePath(folder);
			// done = selectedLength = true;
			// changedText = '${folder} doesn\'t have a assets folder!';
			// loadingText.color = FlxColor.RED;
			// FlxG.sound.play(Paths.sound('cancelMenu'));
			// return;
		changeText('sex');
		
		if (folder == Sys.getCwd() || folder == SELoader.getPath('')) {//This folder is the same folder that FNFBR is running in!
			done = selectedLength = true;
			changeText('You\'re trying to import songs from me!');
			loadingText.color = FlxColor.RED;
			FlxG.sound.play(Paths.sound('cancelMenu'));
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
			changeText('${songList.length} songs will be placed under:'+
				'\nmods/packs/${name}/charts'+
				'\nPress Enter to continue'+
				"\nPress Escape to go back");
			return;
		}
		done = selectedLength = true;
		loadingText.color = FlxColor.RED;
		FlxG.sound.play(Paths.sound('cancelMenu'));
		trace(folder);
		changeText('${folder.substr(-17)} doesn\'t contain any songs!' + (if(!importExisting) "\nMaybe try allowing vanilla songs to be imported?\n*(Press 1 to toggle importing vanilla songs in the list)" else ""));

		
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
	
	override function update(elapsed:Float)
	{
		loadingText.screenCenter(XY);
		if ((done && FlxG.keys.justPressed.ANY) || FlxG.keys.justPressed.ESCAPE) {
			FlxG.switchState(new MainMenuState());
		}
		if(!selectedLength){
			if(FlxG.keys.justPressed.ENTER){
				selectedLength = true;
				changeText("Scanning for songs..\nThe game may "+ (Sys.systemName() == "Windows" ? "'not respond'" : "freeze") + " during this process");
				// sys.thread.Thread.create(() -> {
					// new FlxTimer().start(0.6, function(tmr:FlxTimer){
					scanSongs();
					changeText('Imported ${songsImported} songs.\n They should appear under "mods/packs/${name}/charts" \nPress any key to go to the main menu');
					loadingText.x -= 70;
					done = true;
					// });
				// }); // Make sure the text is actually printed onto the screen before doing anything
			}
			// if(FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT){
			// 	updateLoadinText(FlxG.keys.pressed.SHIFT,FlxG.keys.justPressed.LEFT);
			// }
		}else{
			super.update(elapsed);
		}
		
	}


}
