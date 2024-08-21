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
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
using StringTools;

typedef RepoAsset = {
	var name:String;
	var id:String;
	var author:String;
	var index:Int;
	var description:String;
	var blurb:String;
	var type:String;
	var url:String;
}

// TODO: MAKE USABLE WITHOUT KEYBOARD
@:publicFields class ModRepoState extends SearchMenuState {
	var url:String = se.SESave.data.repoURL == "" ? "https://github.com/superpowers04/Super-Engine-Custom-Content/raw/meow/RepoListing.json" : se.SESave.data.repoURL;
	var repoList:Array<RepoAsset> = [];
	final categories:Array<String> = ['All',"Packs",'Songs','Characters','Scripts','Ports'];
	final categoryIDs:Array<Array<String>> = [[''],['pack','mod'],['song','chart','music'],['character','char'],['script','plugin','state'],['port']];
	var currentCat:Int = 0;
	var loadingProgress:Float = 0;
	var shouldReload = true;
	var diffText:FlxText;
	var assetNameText:FlxText;
	var twee:FlxTween;
	override function new() {
		super();
	}
	override function updateInfoText(str:String = ""){
		if(infotext != null){
			infotext.setHTMLText(str);
			infotext.wordWrap = true;
			infotext.scrollFactor.set();
			infotext.y = infoTextBorder.y + 100;
			infotext.x = infoTextBorder.x + 10;
		}
	}
	inline function updateName(?name = "funninameherelmaomlmaonjosn"){
		if(name != "funninameherelmaomlmaonjosn"){
			assetNameText.text = name;
			assetNameText.x = (infoTextBorder.x + (infoTextBorder.width * 0.5) - (assetNameText.width * 0.5));
		}

	}
	override function create(){
		toggleables['search']=true;
		super.create();
		bg.color = 0x400060;
		diffText = new FlxText(FlxG.width * 0.7, 5, 0, '< ' + categories[0] + ' >', 32);
		diffText.font = CoolUtil.font;
		diffText.borderSize = 2;
		add(diffText);
		infoTextBorder.makeGraphic(500,720,FlxColor.BLACK);
		infoTextBorder.setPosition(1280 - infoTextBorder.width,140);
		infotext.fieldWidth = infoTextBorder.width - 20;

		assetNameText = new FlxText(5, infoTextBorder.y + 50, 0, "yes", 20);
		assetNameText.wordWrap = false;
		assetNameText.scrollFactor.set();
		assetNameText.setFormat(CoolUtil.font, 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		overLay.add(assetNameText);
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
			changeCat(0);
			// reloadList();
		}
		super.update(e);

	}
	override function extraKeys(){
		if(controls.LEFT_P){changeCat(-1);}
		if(controls.RIGHT_P){changeCat(1);}
	}
	public function changeCat(count:Int=1){
		currentCat+=count;
		if(currentCat >= categories.length) currentCat = 0;
		if(currentCat < 0) currentCat = categories.length -1;
		diffText.text = '< ${categories[currentCat]} >';
		diffText.screenCenter(X);
		if(twee != null)twee.cancel();
		diffText.scale.set(1.2,1.2);
		twee = FlxTween.tween(diffText.scale,{x:1,y:1},(30 / Conductor.bpm));
		reloadList(true);
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
			if(!query.match(asset.name ?? "") && !query.match(asset.id ?? "")) continue;
			if(currentCat != 0){
				if(asset.type == null) continue;
				var contains = false;
				for(str in categoryIDs[currentCat]){
					if(asset.type.contains(str)){
						contains = true;
						break;
					}
				}
				if(!contains) continue;
			}
			addToList(asset.name ?? asset.id,i);
			var meow = grpSongs.members[i];
			meow.menuValue = asset;
			if(asset.blurb != null && asset.blurb != ""){

				meow.add(new FlxText(15,60,0,asset.blurb,18));
			}
			i++;
		}
		if(grpSongs.members.length == 0){
			addToList('No mods found',0);
		}
		changeSelection();
	}
	override function ret(){

		SELoader.playSound('assets/sounds/cancelMenu');
		FlxG.switchState(new MainMenuState());
	}
	override function select(i:Int = 0){
		if(grpSongs.members[i] == null || grpSongs.members[i].menuValue == null){
			showTempmessage('No asset associated with that menu item',0xFFFF0000);
			return;
		}
		FlxG.switchState(new se.states.DownloadState(grpSongs.members[i].menuValue.url,'./requestedFile',ImportMod.ImportModFromFolder.fromZip.bind(null,_),FlxG.switchState.bind(new ModRepoState())));
	}
	override function changeSelection(change:Int = 0){
		var _oldSel = curSelected;
		super.changeSelection(change);
		var alpha = grpSongs.members[curSelected];
		if(alpha.menuValue == null) {
			updateInfoText("");
			updateName("");
			infoTextBorder.alpha=0;
			return;
		}
		infoTextBorder.alpha=1;
		var value = alpha.menuValue;

		var text = 'Author: ${value.author ?? "N/A"}\n'
			+(value.description ?? "No description provided")
			+'\n\nID: ${value.id}\nType: ${value.type}\n';
		updateInfoText(text);
		updateName(value.name ?? value.id);

	}
}