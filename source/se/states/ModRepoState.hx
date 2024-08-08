package se.states;
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

import tjson.Json;
import haxe.io.Bytes;
import openfl.utils.ByteArray;
import openfl.net.Socket;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;
// import openfl.filesystem.File;
// import openfl.filesystem.FileStream;
import lime.net.HTTPRequest;
import openfl.events.Event;
import openfl.events.ProgressEvent;
import openfl.events.IOErrorEvent;
using StringTools;

typedef RepoAsset = {
	var name:String;
	var id:String;
	var index:Int;
	var description:String;
	var url:String;
}
@:publicFields class ModRepoState extends SearchMenuState {
	var url:String = "https://github.com/superpowers04/Super-Engine-Custom-Content/raw/meow/RepoListing.json";
	var repoList:Array<RepoAsset> = [];
	var loadingProgress:Float = 0;
	var shouldReload = true;
	override function new() {
		if(se.SESave.data.repoURL != ""){
			url = se.SESave.data.repoURL;
		}
		super();
	}
	override function create(){
		toggleables['search']=true;
		super.create();
		loadScripts();
		new HTTPRequest<Bytes>(url).load(url).onComplete(onData).onProgress(updateProgress).onError(onError);
		showBeatBouncing=false;

	}
	public var inError:Bool =false;
	public function onData(bytes:Bytes){
		try{
			var byte = bytes.toString();
			repoList = Json.parse(byte);
			shouldReload=true;
			// reloadList(true);
		}catch(e){

		}

	}
	function updateProgress(min:Float=0,max:Float=0){
		loadingProgress = min/max;
	}
	function onError(e:Dynamic){

		inError=true;
		throw(e);
	}
	override function update(e:Float){
		if(shouldReload){
			shouldReload = false;
			reloadList();
		}
		super.update(e);

	}
	override function reloadList(?reload = false,?search=""){
		curSelected = 0;
		CoolUtil.clearFlxGroup(grpSongs);
		songs = [];
		if(repoList[0] == null){
			addToList('Downloading repo',0);
			var meow = grpSongs.members[grpSongs.members.length-1];
			var loadingBar = new FlxBar(0, 50, LEFT_TO_RIGHT, 120, 10, this, 'loadingProgress', 0, 1);
			loadingBar.createFilledBar(FlxColor.RED, FlxColor.LIME, true, FlxColor.BLACK);
			loadingBar.screenCenter(FlxAxes.XY);
			meow.add(loadingBar);
			return;
		}
		var i:Int = 0;
		var query = new EReg((~/[-_ ]/g).replace(search.toLowerCase().replace('\\','\\\\'),'[-_ ]'),'i'); // Regex that allows _ and - for songs to still pop up if user puts space, game ignores - and _ when showing
		for (asset in repoList){
			addToList(asset.name ?? asset.id,i);
			var meow = grpSongs.members[i];
			meow.menuValue = asset;
			meow.add(new FlxText(10,meow.members[0].height,0,asset.description ?? "No Description Provided",18));
			i++;
		}
	}
	override function select(i:Int = 0){
		if(grpSongs.members[i] == null || grpSongs.members[i].menuValue == null){
			showTempmessage('No asset associated with that menu item');
			return;
		}
		FlxG.switchState(new se.states.DownloadState(grpSongs.members[i].menuValue.url,'./requestedFile',
							ImportMod.ImportModFromFolder.fromZip.bind(null,_),FlxG.switchState.bind(new ModRepoState())));
	}
}