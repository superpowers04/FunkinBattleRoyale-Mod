package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import openfl.media.Sound;
import sys.FileSystem;
import flixel.util.FlxColor;
import flixel.sound.FlxSound;

using StringTools;
typedef MusicTime ={
	var file:String;
	var begin:Int;
	var end:Int;
	var color:String;
	var wrapAround:Bool;
	var bpm:Float;
}

class SickMenuState extends ScriptMusicBeatState
{
	var curSelected:Int = 0;

	var options:Array<String> = ["replace me dammit", "what are you doing, replace me"];
	var descriptions:Array<String> = ["Hello there, Please report this","Bruh"];

	var descriptionText:FlxText;
	var grpControls:FlxTypedGroup<Alphabet>;
	var bgImage:String = "menuDesat";
	var selected:Bool = false;
	var bg:FlxSprite;
	public static var menuMusic:Sound;
	public static var musicTime:Int = 8;
	public static var fading:Bool = false;
	public static var curSongTime:Float = 0;
	public static var musicFileLoc:String = "";
	public static var chgTime:Bool = false;
	public static var musicList:Array<MusicTime> = [
		{
			file: "mods/title-morning.ogg or assets/music/breakfast.ogg",
			begin:6,end:10,wrapAround:false,color:"0xdd9911",bpm:160
		},
		{
			file: "mods/title-day.ogg or assets/music/freakyMenu.ogg",
			// Uses 100 because there is no 100th hour of the day, if there is than what the hell device are you using?
			wrapAround:false,end:100,begin:101,color:"0xECD77F",bpm:204 
		},
		{
			file: "mods/title-evening.ogg or assets/music/GiveaLilBitBack.ogg",
			begin:17,end:19,wrapAround:false,color:"0xdd9911",bpm:125
		},
		{
			file: "mods/title-night.ogg or assets/music/freshChillMix.ogg",
			begin:20,end:5,wrapAround:true,color:"0x113355",bpm:117
		},
	];
	var isMainMenu:Bool = false;


	function goBack(){
		FlxG.switchState(new MainMenuState());
	}
	function generateList(?reload:Bool = false){
		if(reload){
			grpControls = new FlxTypedGroup<Alphabet>();

			add(grpControls);
		}
		grpControls.clear();
		callInterp('generateList',[]);
		if(cancelCurrentFunction) return;
		for (i in 0...options.length) addListing(i);
		callInterp('generateListAfter',[grpControls]);
	}
	function addListing(i:Int){
		callInterp('addToList',[i,options[i]]);
		if(cancelCurrentFunction) return;
		var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, options[i], true, false);
		controlLabel.isMenuItem = true;
		controlLabel.targetY = i;
		if (i != 0) controlLabel.alpha = 0.6;
		grpControls.add(controlLabel);
		callInterp('addToListAfter',[controlLabel,i,options[i]]);

	}

	public static var reloadMusic = true;
	public static function musicHandle(?isMainMenu:Bool = false,?_bg:FlxSprite = null,?recolor:Bool = false){
		try{


			Conductor.bpmChangeMap = null;
			Conductor.bpmChangeMapSteps = null;
			var time:Int = Date.now().getHours();
			var curMusicTime = 1;
			for (i in 0 ... SickMenuState.musicList.length) {
				var v = SickMenuState.musicList[i];
				if (!v.wrapAround && time >= v.begin && time <= v.end || (v.wrapAround && (time >= v.begin || time <= v.end))){
					curMusicTime = i;
					break;
				}
			}

			var musicTime = SickMenuState.musicTime;
			var mt:MusicTime = SickMenuState.musicList[curMusicTime];
				
			if (SickMenuState.menuMusic == null || musicTime != curMusicTime || reloadMusic){
				reloadMusic = false;
				if(FlxG.sound.music.playing && !SickMenuState.fading){
					SickMenuState.fading = true;
					var switchToColor = FlxColor.fromString(mt.color);
					if(isMainMenu && _bg != null){
						MainMenuState.bgcolor = switchToColor;
					}
					// FlxTween.tween(FlxG.sound.music,{volume:0},1);
					if((isMainMenu || recolor) && _bg != null){
						FlxTween.color(_bg,1,_bg.color,switchToColor);
					}
					// new FlxTimer().start(1, function(tmr:FlxTimer) {
					SickMenuState.curSongTime = FlxG.sound.music.time;
					// 	FlxG.sound.music.stop();
						
					// 	musicHandle(isMainMenu,_bg);
					// });
					// return;
				}
				SickMenuState.musicFileLoc = mt.file;
				if(mt.file.contains(" or ")){
					SickMenuState.musicFileLoc = SELoader.anyExists(mt.file.split(" or ")) ?? "assets/music/freakyMenu.ogg"; // Safety net to prevent a null song or something
				}
				SickMenuState.fading = false;
				
				SickMenuState.menuMusic = SELoader.loadSound(SickMenuState.musicFileLoc,true);
				SickMenuState.musicTime = curMusicTime;
				Conductor.changeBPM(mt.bpm);

			// if (_bg != null){ }

				FlxG.sound.playMusic(SickMenuState.menuMusic,SESave.data.instVol);
			// if (!MainMenuState.firstStart) FlxG.sound.music.time = FlxMath.wrap(Math.floor(SickMenuState.curSongTime),0,Math.floor(FlxG.sound.music.length));
			}else if (!FlxG.sound.music.playing) {
				FlxG.sound.playMusic(SickMenuState.menuMusic,SESave.data.instVol);
				Conductor.changeBPM(mt.bpm);
			}
			if(!isMainMenu && !recolor && _bg != null){
				_bg.color = FlxColor.interpolate(_bg.color,FlxColor.fromString(SickMenuState.musicList[musicTime].color),0.2);
			}else if(recolor && _bg != null){
				_bg.color = FlxColor.fromString(mt.color);
			}
			if (FlxG.sound.music.volume < SESave.data.instVol) FlxG.sound.music.volume = SESave.data.instVol;
		}catch(e){
			MusicBeatState.instance.showTempmessage('Unable to handle music ${e.message}');
			trace('${e.stack}');
		}
	} 

	override function create() {
		// if (ChartingState.charting) ChartingState.charting = false;
		SearchMenuState.resetVars();
		// if (SESave.data.songUnload && PlayState.SONG != null) {PlayState.SONG = null;}
		// PlayState.songScript = "";PlayState.hsBrTools = null;
		if(SearchMenuState.background == null){
			try{

			SearchMenuState.background = if(SELoader.exists("mods/bg.png")) SELoader.loadGraphic("mods/bg.png",true); else SELoader.loadGraphic("assets/images/menuDesat.png",true);
			SearchMenuState.backgroundOver = if(SELoader.exists("mods/fg.png")) SELoader.loadGraphic("mods/fg.png",true); else FlxGraphic.fromRectangle(0,0,0x00000000);
			}catch(e){trace('Unable to load background! ${e.message}');}
			if(SearchMenuState.background == null) SearchMenuState.background = FlxGraphic.fromRectangle(0,0,0xff110015);
			SearchMenuState.background.persist = SearchMenuState.backgroundOver.persist = true;
			SearchMenuState.background.destroyOnNoUse = SearchMenuState.backgroundOver.destroyOnNoUse = false;
		}


		if(bg == null){
			
			bg = new FlxSprite().loadGraphic(SearchMenuState.background); 
			bg.color = 0xFFFF6E6E;
		}
		bg.scrollFactor.set(0.01,0.01);

		add(bg);
		if(SearchMenuState.backgroundOver != null){
			var bgOver = new FlxSprite().loadGraphic(SearchMenuState.backgroundOver);
			bgOver.scrollFactor.set(0.01,0.01);
			add(bgOver);
		}
		musicHandle(isMainMenu,bg);


		generateList(true);

		descriptionText = new FlxText(5, FlxG.height - 28, 0, descriptions[0], 12);
		descriptionText.scrollFactor.set();
		descriptionText.setFormat(CoolUtil.font, 22, FlxColor.WHITE, LEFT, NONE, FlxColor.BLACK);
		descriptionText.borderSize = 2;
		var blackBorder:FlxSprite = new FlxSprite(-30,FlxG.height - 30).makeGraphic((FlxG.width),40,FlxColor.fromString("0x220011"));
		blackBorder.scrollFactor.set();
		blackBorder.alpha = 0.8;

		add(blackBorder);

		add(descriptionText);



		FlxG.autoPause = true;


		super.create();
		FlxG.mouse.visible = true;
	}
	var doResize:Bool = true;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
		callInterp('handleInput',[]);
		if(cancelCurrentFunction) return;
		if (controls.BACK) goBack();
		if (selected || grpControls.length == 0) return;
		if (controls.UP_P && FlxG.keys.pressed.SHIFT){changeSelection(-5);} else if (controls.UP_P){changeSelection(-1);}
		if (controls.DOWN_P && FlxG.keys.pressed.SHIFT){changeSelection(5);} else if (controls.DOWN_P){changeSelection(1);}

		if (controls.ACCEPT && grpControls.members[curSelected] != null) {
			if(doResize){
				FlxTween.tween(grpControls.members[curSelected],{x:FlxG.width},2,{ease:FlxEase.quadIn});
				if(curTween != null)curTween.cancel();
				grpControls.members[curSelected].scale.set(1.3,1.3);

			}
			select(curSelected);
		}
		#if !mobile
		if(supportMouse){
		#end
			if(FlxG.mouse.justReleased){
				for (i in -1 ... 2) {
					if(grpControls.members[curSelected + i] != null && FlxG.mouse.overlaps(grpControls.members[curSelected + i])){
						select(curSelected + i);
					}
				}
				#if !mobile
				if(FlxG.mouse.y > 560){
					changeSelection(1);
				}else if(FlxG.mouse.y < 300){
					changeSelection(-1);
				}
				#end
			}
			if(FlxG.mouse.wheel != 0){
				var move = -FlxG.mouse.wheel;
				changeSelection(Std.int(move));
			}
		#if !mobile
		}
		#end
	}

	public var supportMouse(get,default):Bool = true;
	public function get_supportMouse():Bool{
		return supportMouse && !Overlay.Console.showConsole;
	}
	var isEpicTween:Bool = false;
	var curTween:FlxTween;
	var beatTween:FlxTween;
	override function beatHit(){
		super.beatHit();
		if(grpControls.members[curSelected] != null && !isEpicTween){
			
			grpControls.members[curSelected].scale.set(1.1,1.1);
			if(curTween != null){
				curTween.cancel();
			}
			curTween = FlxTween.tween(grpControls.members[curSelected].scale,{x:1,y:1},Conductor.stepCrochet * 0.003,{ease:FlxEase.circOut});
		}
		if(SESave.data.beatBouncing){
			if(beatTween != null){
				beatTween.cancel();
				beatTween.destroy();
			}else{
				beatTween = FlxTween.tween(bg.scale.set(1.01,1.01),{x:1,y:1},Conductor.stepCrochet * 0.003);
			}
		}
	}
	function select(sel:Int){ trace("Why wasn't this replaced?"); }
	function changeSelection(change:Int = 0)
	{
		callInterp('changeSelection',[change]);
		if(cancelCurrentFunction) return;
		SELoader.playSound('assets/sounds/scrollMenu.ogg',true);

		curSelected += change;

		if (curSelected < 0) curSelected = grpControls.length - 1;
		if (curSelected >= grpControls.length) curSelected = 0;

		if(bg.height > 720) bg.y = (curSelected / grpControls.length) * -(bg.height - 720);


		descriptionText.text = descriptions[curSelected];


		var bullShit:Int = 0;

		for (item in grpControls.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (item.targetY == 0) {
				item.alpha = 1;
				item.color = 0xffffff;
			}else{
				item.alpha = 0.6;
				item.color = 0xdddddd;
			}
		}
		callInterp('changeSelectionAfter',[change]);

	}
}
