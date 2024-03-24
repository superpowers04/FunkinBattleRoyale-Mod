package;
// About 90% of code used from OfflineMenuState
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxInputText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;


#if discord_rpc
	import Discord.DiscordClient;
#end

import sys.io.File;
import sys.FileSystem;
import flixel.math.FlxMath;

using StringTools;

class SearchMenuState extends ScriptMusicBeatState {
	var curSelected:Int = 0;

	var songs:Array<String> = []; // Is the character list, just too lazy to rename
	var grpSongs:FlxTypedGroup<Alphabet>;
	var posX:Int = Std.int(FlxG.width * 0.7);
	var posY:Int = 0;
	var searchField:FlxInputText;
	var searchButton:FlxUIButton;
	var muteKeys = FlxG.sound.muteKeys;
	var volumeUpKeys = FlxG.sound.volumeUpKeys;
	var volumeDownKeys = FlxG.sound.volumeDownKeys;
	public var searchList:Array<String> = ["this should be replaced"];
	var retAfter:Bool = true;
	var bg:FlxSprite;
	var titleText:FlxText;
	var infotext:FlxText;
	var overLay:FlxGroup = new FlxTypedGroup();
	var infoTextBoxSize:Int = 2;
	public var supportMouse(get,default):Bool = true;
	public function get_supportMouse():Bool{
		return supportMouse && !Overlay.Console.showConsole;
	}
	public var allowInput:Bool = true;

	public static var background:FlxGraphic;
	public static var backgroundOver:FlxGraphic;
	var toggleables:Map<String,Bool> = [
		"search" => true
	];
	var buttonText:Map<String,String> = [
		"Find" => "Find"
	];
	var useAlphabet:Bool = true;

	

	function addTitleText(str:String = ""){
		if (titleText != null) titleText.destroy();
		if (str == "") return;
		#if android
			str = str + " - Tap here to go back";
		#end
		titleText = new FlxText(FlxG.width * 0.5, 20, 0, str, 12);
		titleText.scrollFactor.set();
		titleText.setFormat(CoolUtil.font, 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(titleText);
	}

	function findButton(){
		reloadList(true,searchField.text);
		searchField.hasFocus = false;
		changeSelection(0);
	}
	function orderList(list:Array<String>):Array<String>{
		haxe.ds.ArraySort.sort(list, function(a, b) {
			a=a.toLowerCase();
			b=b.toLowerCase();
			return (a<b) ? -1 : ((a>b) ? 1 : 0);
		});
		return list;
	}
	function updateInfoText(str:String = ""){
		if(infotext == null) return;
		infotext.text = str;
		infotext.scrollFactor.set();
		
	}
	// var bgColor:FlxColor = 0xFFFF6E6E;
	@:keep inline static public function resetVars(){
		LoadingScreen.loadingText = "Resetting Variables";
		if (/*SESave.data.songUnload && */PlayState.SONG != null) {PlayState.SONG = null;} // I'm not even sure if this is needed but whatever
		ChartingState.charting = false;
		PlayState.songDifficulties = [];
		PlayState.nameSpace = "";
		PlayState.scripts = [];
		PlayState.hsBrTools = null;
		PlayState.isStoryMode = false;
		PlayState.songDiff = "";
		PlayState.storyDifficulty = 1;
		PlayState.actualSongName = "";
		PlayState.hsBrToolsPath = "";
		onlinemod.OfflinePlayState.nameSpace = 
			onlinemod.OfflinePlayState.chartFile = 
			onlinemod.OfflinePlayState.instFile = 
			onlinemod.OfflinePlayState.voicesFile = "";
		onlinemod.OfflinePlayState.instFile = onlinemod.OfflinePlayState.voicesFile = null;
		HSBrTools.shared = [];
		SickMenuState.chgTime = true;
		if(Note.noteNames[0] == null){Note.noteNames = ["purple","blue","green",'red'];}
		if(Note.noteAnims[0] == null){Note.noteAnims = ["singLEFT","singDOWN","singUP",'singRIGHT'];}
		if(Note.noteDirections[0] == null){Note.noteDirections = ["LEFT","DOWN","UP",'RIGHT','NONE'];}
		Conductor.offset = 0;
		if(!SESave.data.persistBF && PlayState.boyfriend != null){
			try{PlayState.boyfriend.destroy();}catch(e){}
			PlayState.boyfriend = null;
		} 
		if(!SESave.data.persistGF && PlayState.gf != null){
			try{PlayState.gf.destroy();}catch(e){}
			PlayState.gf = null;
		} 
		if(/*SESave.data.persistOpp == null &&*/ PlayState.dad != null){
			try{PlayState.dad.destroy();}catch(e){}
			PlayState.dad = null;
		}
		#if discord_rpc
			DiscordClient.changePresence('Admiring the menus',"Probably configurin something or choosing a song");
		#end
		// #if linc_luajit
			// llua.Convert.cleanFunctionRefs();
		// #end
		PlayState.restartTimes = 0;
	}
	public static var doReset:Bool = true;
	public var blackBorder:FlxSprite;
	public var scrollBar:FlxSprite;
	public var scrollBarBG:FlxSprite;
	public var infoTextBorder:FlxSprite;
	override function create()
	{try{
		if(doReset)resetVars();
		if(bg == null){
			// if(FileSystem.exists("mods/bg.png")){
			// 	bg = new FlxSprite().loadGraphic(Paths.getImageDirect("mods/bg.png"));
			// }else{
			// 	bg = new FlxSprite().loadGraphic(Paths.image("menuDesat"));

			// }
			bg = new FlxSprite().loadGraphic(SearchMenuState.background); 
			// bg = new FlxSprite().loadGraphic(Paths.image(bgImage));
			bg.color = bgColor;
		}
		bg.scrollFactor.set(0.2,0.2);
		if(doReset) SickMenuState.musicHandle(bg);

		add(bg);
		var bgOver = new FlxSprite().loadGraphic(SearchMenuState.backgroundOver);
		bgOver.scrollFactor.set(0.2,0.2);
		add(bgOver);
		grpSongs = new FlxTypedGroup<Alphabet>();
		LoadingScreen.loadingText = "Loading list";
		reloadList();
		add(grpSongs);
		FlxG.mouse.visible = true;
		if (toggleables['search']){
			blackBorder = new FlxSprite(-30,0).makeGraphic((Std.int(FlxG.width + 40)),140,FlxColor.BLACK);
			blackBorder.alpha = 0.5;
			add(blackBorder);
			//Searching
			searchField = new FlxInputText(10, 100, 1152, 20);
			searchField.maxLength = 81;
			add(searchField);
	
			searchButton = new FlxUIButton(10 + 1152 + 9, 100, buttonText["Find"], findButton);
			searchButton.setLabelFormat(24, FlxColor.BLACK, CENTER);
			searchButton.resize(100, searchField.height);
			add(searchButton);
			searchField.callback = function(_:String,cb:String){
				if(cb == "enter") findButton();
			}
		}

		infotext = new FlxText(5, FlxG.height - (20 * infoTextBoxSize ), FlxG.width - 5, "Hold shift to scroll faster", 16);
		infotext.wordWrap = true;
		infotext.scrollFactor.set();
		infotext.setFormat(CoolUtil.font, 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		infoTextBorder = new FlxSprite(-30,FlxG.height - (20 * infoTextBoxSize )).makeGraphic((Std.int(FlxG.width + 40)),(20 * infoTextBoxSize),FlxColor.BLACK);
		infoTextBorder.alpha = 0.5;
		overLay.add(infoTextBorder);
		overLay.add(infotext);
		var _sbbgy:Int = Std.int(blackBorder == null ? 0 : blackBorder.y + blackBorder.height);
		scrollBarBG = new FlxSprite(FlxG.width - 20,_sbbgy).makeGraphic(18,Std.int(FlxG.height) - _sbbgy,0xFF220022);
		scrollBarBG.alpha = 0.9;
		scrollBarBG.scrollFactor.set();
		overLay.add(scrollBarBG);
		scrollBar = new FlxSprite(scrollBarBG.x - 1,scrollBarBG.y + 12).makeGraphic(22,Std.int(scrollBarBG.width) + 2,FlxColor.WHITE);
		scrollBar.alpha = 0.8;
		scrollBar.scrollFactor.set();
		overLay.add(scrollBar);
		// add(overLay);
		FlxG.autoPause = true;
		try{if(onlinemod.OnlinePlayMenuState.socket != null) onlinemod.OnlinePlayMenuState.receiver.HandleData = HandleData;}catch(e){}

		super.create();
		openfl.system.System.gc();
		try{
			FlxG.sound.music.onComplete = null;

		}catch(e){}
		
	}catch(e) MainMenuState.handleError(e,'Error with searchmenu "create" ${e.message}');}

	function addToList(char:String,i:Int = 0){
		callInterp('addToList',[char,i]);
		if(cancelCurrentFunction) return;
		songs.push(char);
		var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, char, true, false,false,useAlphabet);

		controlLabel.cutOff = 24;
		controlLabel.isMenuItem = true;
		controlLabel.targetY = i;
		if (i != 0) controlLabel.alpha = 0.6;

		grpSongs.add(controlLabel);
		callInterp('addToListAfter',[controlLabel,char,i]);
	}
	override function draw(){
		super.draw();
		overLay.draw();
	}

	function reloadList(?reload = false,?search=""){try{
		curSelected = 0;
		if(reload){CoolUtil.clearFlxGroup(grpSongs);}
		songs = [];

		var i:Int = 0;
		var query = new EReg((~/[-_ ]/g).replace(search.toLowerCase(),'[-_ ]'),'i'); // Regex that allows _ and - for songs to still pop up if user puts space, game ignores - and _ when showing
		for (char in searchList){
			if(search == "" || query.match(char.toLowerCase()) ){
				addToList(char,i);
				i++;
			}
		}
	}catch(e) MainMenuState.handleError('Error with loading stage list ${e.message}');}
	override function update(elapsed:Float)
	{
		// try{
		super.update(elapsed);
		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
		// if (FlxG.sound.music.volume < 0.8) FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		if (toggleables['search'] && searchField.hasFocus){SetVolumeControls(false);if (FlxG.keys.pressed.ENTER) findButton();}else{
			SetVolumeControls(true);
			handleInput();
		}
		if(bg.height > 720) bg.y = FlxMath.lerp(bg.y,(curSelected / grpSongs.length) * -(bg.height - 720),elapsed);

	// }catch(e) MainMenuState.handleError('Error with searchmenu "update" ${e.message}');
	}
	function select(sel:Int = 0){
		trace("You forgot to replace the select function!");
	}
	var hoverColor = 0xffffffff;
	var idleColor = 0xff997799;
	var scrollHover:Bool = false;
	var scrollPressed:Bool = false;
	var scrollOffsetY:Float = 0;
	function handleScroll(){
		var sbBGYOffset = scrollBarBG.y;
		var sbBGHeight = sbBGYOffset + scrollBarBG.height - 20;
		var LENGTH = grpSongs.length - 1;
		if(scrollPressed || FlxG.mouse.x > scrollBar.x && FlxG.mouse.x < scrollBar.x + scrollBar.width){
			scrollBar.alpha = 1;
			scrollHover = true;
			if(FlxG.mouse.pressed){
				scrollPressed = true;
				scrollBar.y = FlxG.mouse.y - (scrollBar.height * 0.5);
				if(scrollBar.y < sbBGYOffset) scrollBar.y = sbBGYOffset;
				if(scrollBar.y > sbBGHeight) scrollBar.y = sbBGHeight;
				var sel = Math.round((LENGTH * ((scrollBar.y - sbBGYOffset) / (sbBGHeight - sbBGYOffset)) ));

				if(curSelected != sel && sel > 0 && sel < LENGTH){
					curSelected = 0;
					changeSelection(sel);
				}
			}else{
				scrollPressed = false;
			}
		}else{
			scrollBar.alpha = 0.8;
			scrollHover = false;
		}
		scrollBar.y = Std.int(sbBGYOffset - (scrollBar.height * 0.5) + ((scrollBarBG.height - 20) * (curSelected / LENGTH))) ;
		if(scrollBar.y < sbBGYOffset) scrollBar.y = sbBGYOffset;
		if(scrollBar.y > sbBGHeight) scrollBar.y = sbBGHeight;
	}
	function handleInput(){
		callInterp('handleInput',[]);
		if (controls.BACK || FlxG.keys.justPressed.ESCAPE){
			ret();
		}
		if(!grpSongs.visible || songs.length <= 0 || !allowInput || cancelCurrentFunction) return;
		if(songs.length > 1){
			if (controls.UP_P && FlxG.keys.pressed.SHIFT){changeSelection(-5);} 
			else if (controls.UP_P || (controls.UP && grpSongs.members[curSelected].y > FlxG.height * 0.46 && grpSongs.members[curSelected].y < FlxG.height * 0.50) ){changeSelection(-1);}
			if (controls.DOWN_P && FlxG.keys.pressed.SHIFT){changeSelection(5);} 
			else if (controls.DOWN_P || (controls.DOWN  && grpSongs.members[curSelected].y > FlxG.height * 0.46 && grpSongs.members[curSelected].y < FlxG.height * 0.50) ){changeSelection(1);}
			handleScroll();

		}

		extraKeys();

		if (controls.ACCEPT){
			select(curSelected);
			if(retAfter) ret();
		}
		// if(supportMouse){
			if(!scrollHover && FlxG.mouse.justReleased){
				if(titleText != null && FlxG.mouse.overlaps(titleText)){
					ret();
				}
				if(blackBorder == null || !FlxG.mouse.overlaps(blackBorder) ){
					var curSel= grpSongs.members[curSelected];
					for (i in -2 ... 2) {
						var member = grpSongs.members[curSelected + i];
						if(member != null && FlxG.mouse.overlaps(member)){
							if(member == curSel){
								select(curSelected);
								if(retAfter) ret();
							}else{
								changeSelection(i);
							}
						}
					}
				}
			}
			#if android
				if(FlxG.swipes[0] != null){
					var swipe = FlxG.swipes[0];
					var distance = (swipe.startPosition.y - swipe.endPosition.y) / 100;
					// var speed = Math.max(swipe.duration - 1,0.1);
					trace(distance);
					changeSelection(Std.int(distance));
				}
			#end
			if(FlxG.mouse.wheel != 0){
				var move = -FlxG.mouse.wheel;
				changeSelection(Std.int(move));
			}
			// }
	}
	function extraKeys(){
		return;
	}
	var curTween:FlxTween;
	override function beatHit(){
		super.beatHit();
		if(SESave.data.beatBouncing && grpSongs != null && grpSongs.members[curSelected] != null){
			
			grpSongs.members[curSelected].scale.set(1.1,1.1);
			if(curTween != null)curTween.cancel();
			curTween = FlxTween.tween(grpSongs.members[curSelected],{"scale.x":1,"scale.y":1},Conductor.stepCrochet * 0.003,{ease:FlxEase.circOut});
		}
	}
	function ret(){
		FlxG.mouse.visible = false;
		FlxG.sound.play(Paths.sound('cancelMenu'));
		// if (onlinemod.OnlinePlayMenuState.socket != null){
		// 	FlxG.switchState(new onlinemod.OnlineOptionsMenu());}else{
		goToLastClass();
			// }
	}
	function changeSelection(change:Int = 0)
	{try{
		if (change != 0) FlxG.sound.play(Paths.sound("scrollMenu"), 0.4);
		callInterp('changeSelection',[change]);
		if(cancelCurrentFunction) return;
		curSelected += change;

		if (curSelected < 0) curSelected = grpSongs.members.length - 1;
		if (curSelected >= grpSongs.members.length) curSelected = 0;

		var bullShit:Int = 0;
		


		for (item in grpSongs.members){
			var onScreen = ((item.y > 0 && item.y < FlxG.height) || (bullShit - curSelected < 10 &&  bullShit - curSelected > -10));
			if (onScreen){ // If item is onscreen, then actually move and such
				if (!item.alive){
					item.revive();
					if (change < 0 ) item.y = -500; else item.y = FlxG.height + 300;
				}
				item.targetY = bullShit - curSelected;
				if(item.adjustAlpha){
					item.alpha = 0.6;
					if(!useAlphabet) item.color = idleColor;
					if (item.targetY == 0){
						item.alpha = 1;
						if(!useAlphabet) item.color = hoverColor;
					}
				} 
			}else if(item.alive) item.kill(); // Else, try to kill it to lower the amount of sprites loaded
			bullShit++;
		}
		callInterp('changeSelectionAfter',[change]);
	}catch(e) MainMenuState.handleError('Error with searchmenu "chgsel" ${e.message}');}
	function SetVolumeControls(enabled:Bool){
		FlxG.sound.muteKeys = (enabled ? muteKeys : null);
		FlxG.sound.volumeUpKeys = (enabled ? volumeUpKeys : null);
		FlxG.sound.volumeDownKeys = (enabled ? volumeDownKeys : null);
	}
	function HandleData(packetId:Int, data:Array<Dynamic>){
		var Chat = onlinemod.Chat;
		var Packets = onlinemod.Packets;
		var OnlineLobbyState = onlinemod.OnlineLobbyState;
		switch (packetId) {
			case Packets.GAME_START:
				var jsonInput:String = data[0];
				var folder:String = data[1];
				var count = 0;
				for (i in OnlineLobbyState.clients.keys()) count++;
				TitleState.p2canplay = (count == 2 && TitleState.supported);
				onlinemod.OnlineLobbyState.StartGame(jsonInput, folder);
			default:
				return false;
		}
		return true;
	}
}
