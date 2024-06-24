package;

import openfl.Lib;

import Controls.Control;
import flixel.FlxG; 
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase; 
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxTween;
import openfl.display.BitmapData;
import flixel.FlxCamera;
// import flixel.tweens.FlxTweenManager;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.ui.FlxBar;
import flixel.util.FlxStringUtil;
import se.utilities.SEUIUtilities;
#if discord_rpc
	import Discord.DiscordClient;
#end

using StringTools;

class PauseSubState extends MusicBeatSubstate {
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = [];
	var songLengthTxt = "N/A";
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;
	var perSongOffset:FlxText;
	var ready = true;
	
	var offsetChanged:Bool = false;
	var levelInfo:FlxText;
	var levelDifficulty:FlxText;
	var restarts:FlxText;
	var startTimer:FlxTimer;
	var quitHeld:Int = 0;
	var quitHeldBar:FlxBar;
	var quitHeldBG:FlxSprite;

	var songPath = '';
	var shouldveLeft = false;
	var finishCallback:()->Void;
	var time:Float = 0;
	var volume:Float = 0;
	var timers:Array<FlxTimer> = [];
	var tweens:Array<FlxTween> = [];
	var jumpToTime:Float = 0;
	var bg:FlxSprite;
	var cam:FlxCamera;
	var fuckYouZoom:Float=0; // This is to force the zoom level of camGame, for some reason, camGame's zoom is being forced to 1
	var currentChart = -1;
	public function new(x:Float, y:Float){
		if(FlxG.sound.music != null ) songLengthTxt = FlxStringUtil.formatTime(Math.floor((FlxG.sound.music.length) / 1000), false);
		time = jumpToTime = Conductor.songPosition;
		menuItems = ['Resume', 'Restart Song',"Options Menu",'Exit to menu'];

		#if !mobile
			if(ChartingState.charting ){
				if(FlxG.sound.music != null) menuItems.insert(2,'Jump to');
				menuItems.insert(3,'Back to chart editor');
				menuItems.insert(4,'Exit Charting Mode');
			}else if (PlayState.songDifficulties.length > 0) menuItems.insert(2,'Swap Charts');
			else if (multi.MultiMenuState.importedSong) menuItems.insert(2,'Import Chart');
		#end
		if(SESave.data.QuickReloading) menuItems.insert(2,'Reload Playstate');
		openfl.system.System.gc();
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer){
			if(tmr.active){tmr.active = false;timers.push(tmr);}
		});
		FlxTween.globalManager.forEach(function(tmr:FlxTween){
			if(tmr.active){tmr.active = false;tweens.push(tmr);}
		});
		super();
		PlayState.instance.callInterp("pauseCreate",[this]);

		#if discord_rpc
			DiscordClient.updateSong(true);
		#end
		cam = new FlxCamera();
		fuckYouZoom=FlxG.cameras.list[0].zoom;
		FlxG.cameras.add(cam,false);
		cam.bgColor=0x00000000;
		// FlxG.cameras.setDefaultDrawTarget(cam,true);
		cameras = [cam];

		finishCallback = FlxG.sound.music.onComplete;

		FlxG.sound.music.onComplete = null;
		FlxG.sound.music.looped = true;
		// FlxG.sound.list.add(pauseMusic);
		if(SESave.data.transparentPause){
			bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			bg.alpha = 0;
		}else{
			var bit=new BitmapData(FlxG.width,FlxG.height,true);
			bit.draw(FlxG.stage);
			bg = new FlxSprite().loadGraphic(FlxGraphic.fromBitmapData(bit));
			bg.alpha = 1;
		}
		bg.scrollFactor.set();
		add(bg);

		// CoolUtil.setFramerate(60,null,true);

		levelInfo = new FlxText(20, 0, 0, "", 32);
		levelInfo.text = CoolUtil.formatChartName(PlayState.SONG.song);
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(CoolUtil.font, 32,OUTLINE,0xff000000);
		levelInfo.borderSize = 2;
		levelInfo.updateHitbox();
		add(levelInfo);

		levelDifficulty = new FlxText(20, 0, 0, (PlayState.SONG.artist ?? PlayState.SONG.author ?? ""), 24);
		if(levelDifficulty.text != "") levelDifficulty.text+='\n';
		levelDifficulty.text+=CoolUtil.difficultyString();

		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(CoolUtil.font, 24,OUTLINE,0xff000000);
		levelDifficulty.borderSize = 2;
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		restarts = new FlxText(20, 0, 0, 'Restart count: ${PlayState.restartTimes}', 20);
		restarts.scrollFactor.set();
		restarts.setFormat(CoolUtil.font, 20,OUTLINE,0xff000000);
		restarts.borderSize = 2;
		restarts.updateHitbox();
		SEUIUtilities.addSpacedUI(this,{y:15,objects:[
			[levelInfo],
			[levelDifficulty],
			[restarts]
		]});
		add(restarts);

		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		restarts.x = FlxG.width - (restarts.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartIn});
		FlxTween.tween(levelInfo, {alpha: 1}, 0.4, {ease: FlxEase.bounceOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1}, 0.4, {ease: FlxEase.bounceOut, startDelay: 0.3});
		FlxTween.tween(restarts, {alpha: 1}, 0.4, {ease: FlxEase.bounceOut, startDelay: 0.4});

		add(grpMenuShit = new FlxTypedGroup<Alphabet>());

		for (i in 0...menuItems.length){
			var _text = menuItems[i];
			if(_text == "Jump to") _text = getJumpTo();
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, _text, true, false,true);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
			songText.screenCenter(X);
		}
		changeSelection();
		if(!SESave.data.transparentPause) FlxG.state.persistentDraw = false;
		quitHeldBG = new FlxSprite(0, 10).loadGraphic(Paths.image('healthBar','shared'));
		quitHeldBG.screenCenter(X);
		quitHeldBG.scrollFactor.set();
		add(quitHeldBG);


		quitHeldBar = new FlxBar(quitHeldBG.x + 4, quitHeldBG.y + 4, LEFT_TO_RIGHT, Std.int(quitHeldBG.width - 8), Std.int(quitHeldBG.height - 8), this,'quitHeld', 0, 1000);
		quitHeldBar.numDivisions = 1000;
		quitHeldBar.scrollFactor.set();
		quitHeldBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
		add(quitHeldBar);
		songPath = 'assets/data/' + PlayState.SONG.song.toLowerCase() + '/';

		PlayState.instance.callInterp("pause",[this]);
		volume = FlxG.sound.music.volume;
		FlxTween.tween(FlxG.sound.music,{volume:0.2},0.5);
		FlxG.sound.music.looped = true;
		new FlxTimer().start(0.9,function(_){updateJumpTo();});
		#if android
			changeSelection(2);
		#end
	}
	@:keep inline function getJumpTo(){

		var time:String = FlxStringUtil.formatTime(Math.floor(Math.abs(jumpToTime / 1000)), false);
		var currentTime:String = FlxStringUtil.formatTime(Math.floor(Math.abs(Conductor.songPosition / 1000)), false); 
		if(jumpToTime < 0){
			time = "-" + time;
		}
		return 'Jump to ${time} / ${currentTime}';
	} 
	@:keep inline function getChartSel(){
		var chart = PlayState.songDifficulties[currentChart];
		var next = PlayState.songDifficulties[currentChart+1];
		var last = PlayState.songDifficulties[currentChart-1];
		if(chart.lastIndexOf(':') != -1) chart = chart.substring(chart.lastIndexOf(':')+1);
		else{
			if(chart.lastIndexOf('.') != -1) chart = chart.substring(0,chart.lastIndexOf('.'));
			if(chart.lastIndexOf('/') != -1) chart = chart.substring(chart.lastIndexOf('/')+1);
			
		}
		return (last==null?"|":"<")+' $chart ' + (next==null?"|":">");
	} 
	@:keep inline function updateJumpTo(){
		var i = menuItems.indexOf('Jump to');
		if(i > 0){
			grpMenuShit.members[i].removeDashes = false;
			grpMenuShit.members[i].text = getJumpTo();
			grpMenuShit.members[i].screenCenter(X);
		}
	}
	@:keep inline function updateChartSel(){
		if(currentChart > PlayState.songDifficulties.length - 1) currentChart = 0;
		if(currentChart < 0) currentChart = PlayState.songDifficulties.length - 1;
		var i = menuItems.indexOf('Swap Charts');
		if(i > 0){
			grpMenuShit.members[i].text = getChartSel();
			grpMenuShit.members[i].screenCenter(X);
		}
	}
	inline function callInterp(name:String,args:Array<Dynamic>){args.unshift(this); if(PlayState.instance != null) PlayState.instance.callInterp(name,args);}
	override function update(elapsed:Float){
		super.update(elapsed);
		FlxG.cameras.list[0].zoom=fuckYouZoom;
		if (quitHeldBar.visible && quitHeld <= 0){
			quitHeldBar.visible = false;
			quitHeldBG.visible = false;
    	}else if (FlxG.keys.pressed.ESCAPE){
			quitHeld += 5;
			quitHeldBar.visible = true;
			quitHeldBG.visible = true;
			if (quitHeld > 1000) {quit();quitHeld = 0;} 
			}else if (quitHeld > 0){
			quitHeld -= 10;
		}

		if (ready){
		
			callInterp("pauseUpdate",[]);

			var upP = controls.UP_P;
			var downP = controls.DOWN_P;
			var accepted = controls.ACCEPT;
			var oldOffset:Float = 0;

			if (upP) changeSelection(-1);
			else if (downP) changeSelection(1);

			var daSelected:String = menuItems[curSelected];
			if(controls.LEFT || controls.RIGHT){

				#if !mobile
				if(daSelected.startsWith('Swap Charts')){
					if(controls.LEFT_P){
						currentChart--;
						updateChartSel();
					}
					if(controls.RIGHT_P){
						currentChart++;
						updateChartSel();
					}

				}else #end if(daSelected.startsWith('Jump to')){
					if(controls.LEFT_P || controls.LEFT && FlxG.keys.pressed.SHIFT){
						if(jumpToTime - 1000 > -5000){
							jumpToTime -= 1000;
							updateJumpTo();
						}
					}
					if(controls.RIGHT_P || controls.RIGHT && FlxG.keys.pressed.SHIFT){
						if(jumpToTime + 1000 < FlxG.sound.music.length){
							jumpToTime += 1000;
							updateJumpTo();

						}
					}
				}
			}
			if (accepted) select(curSelected);
			#if android
				if(FlxG.mouse.justPressed){
					for(i in 0...grpMenuShit.members.length){
						var obj = grpMenuShit.members[i];
						if(	FlxG.mouse.screenX > obj.x - 10 && FlxG.mouse.screenX < obj.x + 600 &&
							FlxG.mouse.screenY > obj.y && FlxG.mouse.screenY < obj.y + obj.members[0].height){
							select(i);
						}
					}
				}
			#end

		}else{
			if (controls.ACCEPT && menuItems[curSelected] == "Exit to menu") quit();
		}
	}
	function disappearMenu(?time:Float = 0.3){
		for (_ => v in grpMenuShit.members)
		{
			ready = false;
			FlxTween.tween(v,{x : -(100 + v.width)},time,{ease:FlxEase.quartIn});
		}
	}
	function quit(){
		// CoolUtil.setFramerate(0,true,false);
		FlxG.sound.music.stop();
		retMenu();


		return;
	}
	function retMenu(){
		if (PlayState.isStoryMode){FlxG.switchState(new StoryMenuState());return;}
		PlayState.actualSongName = ""; // Reset to prevent issues
		if (shouldveLeft || ChartingState.charting) {
			ChartingState.charting = false;
			Main.game.forceStateSwitch(new MainMenuState());
			return;
		}
		switch (PlayState.stateType) {
			case 2:MusicBeatState.returningFromClass=true;FlxG.switchState(new onlinemod.OfflineMenuState());
		case 4:MusicBeatState.returningFromClass=true;FlxG.switchState(new multi.MultiMenuState());
			default:MusicBeatState.instance.goToLastClass(PlayState);
		}
		shouldveLeft = true;
		return;
	}
	function select(sel:Int){
		var sel =menuItems[sel];
		switch (sel){
			case "Resume":
				countdown();
			case "Restart Song":
				disappearMenu();
				new FlxTimer().start(0.3,function(tmr:FlxTimer){
					if(SESave.data.QuickReloading){
						PlayState.instance.restartSong();
						backToPlaystate();
						return;
					}
					Main.game.funniLoad = true;
					MusicBeatState.returningFromClass = true;
					FlxG.resetState();
				},1);
			case "Reload Playstate":
				disappearMenu();
				new FlxTimer().start(0.3,function(tmr:FlxTimer){
					Main.game.funniLoad = true;
					MusicBeatState.returningFromClass = true;
					FlxG.resetState();
				},1);
			case 'Back to chart editor':
				disappearMenu();
				new FlxTimer().start(0.3,function(tmr:FlxTimer){
					MusicBeatState.returningFromClass = true;
					ChartingState.gotoCharter();
				},1);
			case "Exit Charting Mode":
				disappearMenu();
				new FlxTimer().start(0.3,function(tmr:FlxTimer){
					ChartingState.charting = false;
					MusicBeatState.returningFromClass = true;
					FlxG.resetState();
				},1);
			case "Options Menu":
				disappearMenu();
				new FlxTimer().start(0.3,function(tmr:FlxTimer){
					SearchMenuState.doReset = false;
					OptionsMenu.lastState = PlayState.stateType + 10;
					FlxG.switchState(new OptionsMenu());
				},1);

			case "Exit to menu":
				disappearMenu();
				new FlxTimer().start(0.3,function(tmr:FlxTimer){
					FlxTween.globalManager.clear();
					quit();
				},1);
			case "Jump to":
				Conductor.songPosition = FlxG.sound.music.time = time = jumpToTime;

				PlayState.instance.generateNotes();
				countdown();
			case "Swap Charts":
				if(currentChart < 0 || PlayState.songDifficulties[currentChart] == null) {SELoader.playSound('assets/sounds/cancelMenu');return;}
				ChartingState.charting = false;
				MusicBeatState.returningFromClass = true;
				var chart = PlayState.songDifficulties[currentChart];
				multi.MultiMenuState.gotoSong(chart.substring(0,chart.lastIndexOf('/')),chart.substring(chart.lastIndexOf('/') + 1));
				FlxG.resetState();
			case "Import Chart":
				SELoader.createDirectory('mods/packs/imported');
				SELoader.createDirectory('mods/packs/imported/charts');
				var path = 'mods/packs/imported/charts/' + PlayState.SONG.song;
				if(SELoader.exists(path)){
					path = 'mods/packs/imported/charts/' + PlayState.actualSongName.replace('.json','');
				}
				if(SELoader.exists(path)){
					MusicBeatState.instance.showTempmessage('Unable to import: "${path}" exists!',0xFFFF0000);
					return;
				}
				try{
					SELoader.createDirectory(path);
					trace('Importing ${PlayState.actualSongName} to $path');
					SELoader.createDirectory(path);
					SELoader.importFile(onlinemod.OfflinePlayState.chartFile,'${path}/${PlayState.actualSongName}');
					if(SELoader.exists('${path}/Inst.ogg')) SELoader.importFile(onlinemod.OfflinePlayState.instFile,'${path}/${PlayState.actualSongName}-Inst.ogg');
					else SELoader.importFile(onlinemod.OfflinePlayState.instFile,'${path}/Inst.ogg');

					if(onlinemod.OfflinePlayState.voicesFile != "") {
						if(SELoader.exists('${path}/Voices.ogg')) SELoader.importFile(onlinemod.OfflinePlayState.voicesFile,'${path}/${PlayState.actualSongName}-Voices.ogg');
						else SELoader.importFile(onlinemod.OfflinePlayState.voicesFile,'${path}/Voices.ogg');
					}
				}catch(e){
					MusicBeatState.instance.showTempmessage('Error while importing, chart usability is unknown!:\n ${e.message}!',0xFFFF0000);
					return;
				}
				@:privateAccess{
					multi.MultiMenuState.lastSearch = "imported";
					multi.MultiMenuState.lastSel = 0;
				}
				quit();
			default:
				callInterp("pauseSelect",[sel]);
		}
	}
	var _tween:FlxTween;
	public function countdown(){try{
		if(FlxG.keys.pressed.SHIFT){
			backToPlaystate();
			return;
		}
		ready = false;
		var swagCounter:Int = 1;
		try{
			_tween = FlxTween.tween(FlxG.sound.music,{volume:0},0.5);
		}catch(e){}
		if(perSongOffset != null)perSongOffset.destroy();
		for (i in [levelDifficulty,levelInfo,restarts]) {
			if(i == null) continue;
			FlxTween.tween(i,{x:FlxG.width + 10},0.3,{ease:FlxEase.quartIn,
				onComplete:function(_){i.destroy();}
			});
		}
		FlxG.sound.music.pause();
		Conductor.songPosition = FlxG.sound.music.time = time;
		disappearMenu(0.4);
		callInterp("pauseResume",[]);
		if(SESave.data.transparentPause) FlxTween.tween(bg,{alpha:0},2.5,{ease:FlxEase.quartOut});


		var spr = new FlxSprite();
		var tween:FlxTween = null;
		startTimer = new FlxTimer().start(0.5, function(tmr:FlxTimer) {

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', "set", "go"]);

			var introAlts:Array<String> = introAssets.get('default');
			var altSuffix:String = "";
			switch (swagCounter) {
				case 1:
					var ready:FlxSprite = spr.loadGraphic(Paths.image(introAlts[0]));
					ready.scrollFactor.set();
					ready.updateHitbox();
					ready.screenCenter();
					ready.alpha = 1;


					add(ready);
					tween = FlxTween.tween(ready, {y: ready.y + 100, alpha: 0}, 0.4, {
						ease: FlxEase.cubeInOut,
						// onComplete: function(twn:FlxTween) {ready.destroy();}
					});
					FlxG.sound.play(Paths.sound('intro2' + altSuffix), 0.6);
				case 2:
					var set:FlxSprite = spr.loadGraphic(Paths.image(introAlts[1]));
					tween.cancel();
					set.updateHitbox();
					set.alpha = 1;



					set.screenCenter();
					add(set);
					tween = FlxTween.tween(set, {y: set.y + 100, alpha: 0}, 0.4, {
						ease: FlxEase.cubeInOut,
						// onComplete: function(twn:FlxTween) {set.destroy();}
					});
					FlxG.sound.play(Paths.sound('intro1' + altSuffix), 0.6);
				case 3:
					var go:FlxSprite = spr.loadGraphic(Paths.image(introAlts[2]));
					tween.cancel();
					go.scrollFactor.set();
					go.updateHitbox();
					go.alpha = 1;

					go.screenCenter();
					add(go);
					tween = FlxTween.tween(go, {y: go.y + 100, alpha: 0}, 0.4, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween) {go.destroy();}
					});
					FlxG.sound.play(Paths.sound('introGo' + altSuffix), 0.6);
				case 4:

					backToPlaystate();

			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}catch(e){MainMenuState.handleError(e,'Something went wrong on countdown ${e.message}');}}
	
	override function destroy() {
		if (pauseMusic != null){pauseMusic.destroy();}
		FlxG.cameras.remove(cam);
		super.destroy();
	}
	function backToPlaystate(){
		PlayState.instance.callInterp("pauseExit",[]);
		for (i in tweens) i.active = true;
		for (i in timers) i.active = true;
		if(_tween != null) _tween.cancel();
		FlxG.sound.music.time = Conductor.songPosition;
		FlxG.sound.music.volume = volume;
		FlxTween.tween(FlxG.sound.music,{volume:volume},0.01);
		FlxG.sound.music.onComplete = finishCallback;
		FlxG.sound.music.pause();
		#if discord_rpc
			DiscordClient.updateSong();
		#end
		close();
	}
	function changeSelection(change:Int = 0):Void {
		curSelected += change;

		if (curSelected < 0) curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length) curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;
			#if(!mobile)
				item.alpha = (item.targetY == 0 ? 1 : 0.6);
			#else
				item.alpha = 1;
			#end
		}
	}
}