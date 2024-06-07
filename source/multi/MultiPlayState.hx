package multi;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSubState;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.media.Sound;
import sys.FileSystem;
import sys.io.File;

import Section.SwagSection;

class MultiPlayState extends onlinemod.OfflinePlayState
{


  // override function loadSongs(){
  //   {try{

  //   if (voicesFile != ""){loadedVoices = new FlxSound().loadEmbedded(Sound.fromFile(voicesFile));}else loadedVoices = new FlxSound();
  //   loadedInst = Sound.fromFile(instFile);
  // }catch(e){MainMenuState.handleError(e,'Caught "loadSongs" crash: ${e.message}');}}
  // }

	override function create(){
		// try{
			if(!PlayState.isStoryMode) stateType=4;
			speed = QuickOptionsSubState.getSetting("Song Speed");
			super.create();

		// }catch(e){MainMenuState.handleError(e,'Caught "create" crash: ${e.message}');}
	}
}
