package onlinemod;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import flixel.addons.ui.FlxUIButton;
import SEInputText as FlxInputText;
import flixel.addons.ui.FlxUIText;
import flixel.math.FlxRandom;

import sys.io.File;
import sys.FileSystem;

using StringTools;

class OfflineMenuState extends SearchMenuState
{
  var sideButton:FlxUIButton;

  // var songs:Array<String> = [];
  var songFiles:Array<String> = [];
  var songDirs:Array<String> = [];
  var dataDir:String = "assets/onlinedata/data/";
  var optionsButton:FlxUIButton;
  var goBackButton:FlxUIButton;
  var invertedChart:Bool = false;

  function goOptions(){
	  FlxG.mouse.visible = false;
	  OptionsMenu.lastState = 3;
	  FlxG.switchState(new OptionsMenu());
  }
  function chartOptions(){
	callInterp('chartOptions',[]);
	if(cancelCurrentFunction) return;
	grpSongs.visible = false;
	openSubState(new QuickOptionsSubState(function(){
		grpSongs.visible = true;
	}));
  }
  static var attempted:Bool = false;
  override function create()
  {

	goBackButton = new FlxUIButton(1120, 5, "Go back", ret);
	goBackButton.setLabelFormat(24, FlxColor.BLACK, CENTER);
	goBackButton.resize(150, 30);
	optionsButton = new FlxUIButton(1120, 37, "Options", goOptions);
	optionsButton.setLabelFormat(22, FlxColor.BLACK, CENTER);
	optionsButton.resize(150, 26);
	sideButton = new FlxUIButton(1020, 65, "Chart Options", chartOptions); 
	// This is just so I don't have to remove any references to this button, else I'd remove it on android targets 
	#if android
		goBackButton.y = 30;
		optionsButton.y = 65;
		optionsButton.resize(150,30);
	#else
		sideButton.setLabelFormat(24, FlxColor.BLACK, CENTER);
		sideButton.resize(250, 30);
	#end
	scriptSubDirectory = "/offlinemenu/";
	useNormalCallbacks = true;
	loadScripts(true);
	super.create();
	try{
	add(optionsButton);
	add(goBackButton);
	#if !android
		add(sideButton);
	#end
	}catch(e){
		if(attempted){
			MainMenuState.handleError(e,"Error while trying to create state, " + e.message);
			attempted = false;
			return;
		}
		attempted = true;
		Main.game.forceStateSwitch(new OfflineMenuState()); // Try to load the state again
		return;
	}
	attempted = false;
  }
  override function reloadList(?reload=false,?search = ""){
	curSelected = 0;
	if(reload){grpSongs.destroy();}
	grpSongs = new FlxTypedGroup<Alphabet>();
	add(grpSongs);
	songs = [];
	songFiles = [];
	var i:Int = 0;

	var query = new EReg((~/[-_ ]/g).replace(search.toLowerCase(),'[-_ ]'),'i'); // Regex that allows _ and - for songs to still pop up if user puts space, game ignores - and _ when showing
	if (SELoader.exists(dataDir))
	{
	  var dirs = orderList(SELoader.readDirectory(dataDir));
	  for (directory in dirs)
	  {
		for (file in SELoader.readDirectory(dataDir + directory))
		{
		  if ( StringTools.endsWith(file, '.json') && (search == "" || query.match(file.toLowerCase())) ) // Handles searching
		  {
			songs.push(dataDir + directory + "/" + file);
			songFiles.push(file);
			songDirs.push(directory);

			var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, file.substr(0, file.length - 5), true, false);
			controlLabel.isMenuItem = true;
			controlLabel.targetY = i;
			if (i != 0) controlLabel.alpha = 0.6;
			grpSongs.add(controlLabel);

			i++;
		  }
		}
	  }
	}
  }

  override function ret(){
	FlxG.mouse.visible = false;
	goToLastClass();
  }
  override function extraKeys(){
	callInterp('extraKeys',[]);
	if(cancelCurrentFunction) return;
	if (FlxG.keys.justPressed.R){
	  changeSelection(Math.floor(grpSongs.length * Math.random()));
	}
	optionsButton.label.color = (if(FlxG.keys.pressed.SHIFT) 0xFF222222 else 0xFF000000);
	sideButton.label.color = (if(FlxG.keys.pressed.SHIFT) 0xFF222222 else 0xFF000000);

	if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.O){
	  goOptions();
	}
	if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.C){
	  chartOptions();
	}

  }
  override function select(sel:Int = 0){
 	callInterp('select',[sel]);
	OfflinePlayState.chartFile = songs[curSelected];
	PlayState.isStoryMode = false;
	var songName = songFiles[curSelected];
	PlayState.songDir = songDirs[curSelected];
	// Set difficulty
	PlayState.storyDifficulty = 1;
	if (StringTools.endsWith(songs[curSelected], '-hard.json')){
		songName = songName.substr(0,songName.indexOf('-hard.json'));
		PlayState.storyDifficulty = 2;
	}else if (StringTools.endsWith(songs[curSelected], '-easy.json')){
		songName = songName.substr(0,songName.indexOf('-easy.json'));
		PlayState.storyDifficulty = 0;
	}
	PlayState.actualSongName = songName;
	OfflinePlayState.instFile = "";
	OfflinePlayState.voicesFile = "";

	LoadingScreen.loadAndSwitchState(new OfflinePlayState());
  }
}
