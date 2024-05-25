package onlinemod;

import multi.MultiMenuState;
import flixel.FlxG;
import se.formats.SongInfo;

/*
	TODO:
		IMPLEMENT FOR EXTERNAL SERVERS
		ADD HANDLEDATA
		???
		PROFIT

*/

class OnlineSongMenuState extends MultiMenuState {
	override function create(){
		OnlinePlayMenuState.receiver.HandleData = HandleData;
		super.create();
		remove(optionsButton);
		remove(sideButton);
	}
	override function updateScore(?songInfo:SongInfo,?chart:String){
		if(songInfo == null){
			scoreText.text = "Invalid song";
			SCORETXT = "Invalid song";
			scoreText.screenCenter(X);
			return;
		}
		scoreText.text = "Valid song";
		SCORETXT = "N/A";
		scoreText.screenCenter(X);
	}

	

	override function ret(){
		FlxG.switchState(new OnlineLobbyState(true));
	}
	override function selSong(sel:Int = 0,charting:Bool = false){
		if (grpSongs.members[sel].menuValue == null){ // Actually check if the song is a song, if not then error
			SELoader.playSound('assets/images/cancelMenu.ogg');
			showTempmessage("Invalid song!",0xFFFF0000);
			return;
		}
		var songInfo:SongInfo = cast grpSongs.members[sel].menuValue;
		onlinemod.OfflinePlayState.nameSpace = "";
		if(songInfo.namespace != null){
			onlinemod.OfflinePlayState.nameSpace = songInfo.namespace;
			trace('Using namespace ${onlinemod.OfflinePlayState.nameSpace}');
		}
		var songLoc = songInfo.path;
		if (songInfo.charts[selMode] == "No charts for this song!"){ // Actually check if the song has no charts when loading, if so then error
			SELoader.playSound('assets/images/cancelMenu.ogg');
			showTempmessage("Invalid song!",0xFFFF0000);
			return;
		}
		MultiMenuState.loadScriptsFromSongPath(songLoc);
		var serv = SEServer.instance;
		serv.scripts = PlayState.scripts;
		PlayState.scripts = [];
		if(SEServer.instance != null){

			var path = SELoader.getPath(songInfo.path);
			serv.instPath=songInfo.inst;
			serv.voicePath=songInfo.voices;
			serv.songName=songInfo.name;
			serv.chartPath=path+songInfo.charts[selMode];
			serv.updateSong();
			ret();
			return;
		}
		// gotoSong(SELoader.getPath(songInfo.path),songInfo.charts[selMode],songInfo.name,songInfo.voices,songInfo.inst);
	}
}