package;


import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.Lib;
import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxState;
import flixel.tweens.FlxEase;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.FlxObject;
import flixel.FlxBasic;
import Overlay.Console;
import se.extensions.flixel.FlxSpriteLockScale;
import haxe.Timer;

import flixel.group.FlxGroup.FlxTypedGroup;



class MusicBeatState extends FlxUIState {
	public static var instance:MusicBeatState;

	public var curStep:Int = 0;
	public var curStepProgress:Float = 0;
	public var curBeat:Int = 0;
 
	public var lastUpdateTime:Float = 0;

	private var controls(get, never):Controls;
	var forceQuit = true;
	public static var lastClassList:Array<Class<Dynamic>> = [];
	public static var returningFromClass:Bool = false;

	public function goToLastClass(?avoidType:Class<Any> = null){
		try{
			returningFromClass = true;
			if(avoidType != null){
				while(Std.isOfType(lastClassList[lastClassList.length - 1],avoidType) ){
					lastClassList.pop();
				}
			}
			FlxG.switchState(Type.createInstance(lastClassList.pop(),[]));
		}catch(e){
			FlxG.switchState(new MainMenuState());
		}
	}
	public function new(){
		if(returningFromClass){
			returningFromClass = false;
		}else{
			lastClassList.push(Type.getClass(FlxG.state));
		}
		if(lastClassList.length > 10){
			lastClassList.shift();
		}
		super();
	}
	public function addBelow(OldObject:FlxObject, NewObject:FlxObject):FlxObject{
		var index:Int = members.indexOf(OldObject);

		if (index < 0) return null;

		members.insert(index-1,NewObject);

		if (_memberAdded != null)
			_memberAdded.dispatch(NewObject);

		return NewObject;
	}
	public function addAfter(OldObject:FlxObject, NewObject:FlxObject):FlxObject{
		var index:Int = members.indexOf(OldObject);

		if (index < 0) return null;

		members.insert(index+1,NewObject);

		if (_memberAdded != null)
			_memberAdded.dispatch(NewObject);

		return NewObject;
	}
	public function addObject(object:FlxBasic) { add(object); }
	public function removeObject(object:FlxBasic) { remove(object); }

	public function errorHandle(?error:String = "No error passed!",?forced:Bool = false){
		try{

			trace('Error!\n ${error}');
			FlxTimer.globalManager.clear();
			FlxTween.globalManager.clear();
			// updateTime = false;
			persistentUpdate = false;
			persistentDraw = true;

			Main.game.blockUpdate = Main.game.blockDraw = false;
			openSubState(new ErrorSubState(0,0,error));
		}catch(e){trace('${e.message}\n${e.stack}');MainMenuState.handleError(error);}
	}

	var loading = true;
	public function onFileDrop(file:String):Null<Bool>{
		return true;
	}
	var mouseEnabledTmr:FlxTimer;
	override function onFocus() {
		super.onFocus();
		CoolUtil.setFramerate(true);
		mouseEnabledTmr = new FlxTimer().start(0.25,function(_){FlxG.mouse.enabled = true;});
	}
	override function onFocusLost(){
		super.onFocusLost();
		CoolUtil.setFramerate(24,false,true);
		if(mouseEnabledTmr != null)mouseEnabledTmr.cancel();
		FlxG.mouse.enabled = false;
	}
	@:keep inline function get_controls():Controls return PlayerSettings.player1.controls;
	override function create()
	{
		CoolUtil.setFramerate(true);

		CoolUtil.updateActiveObject(null);
		instance = this;
		super.create();

		tranIn();
	}
	override function destroy(){
		instance = null;
		CoolUtil.updateActiveObject(null);
		super.destroy();
	}
	
	// var tempMessBacking:FlxSprite;
	// var tempMessage:FlxText;
	// var tempMessTimer:FlxTimer;
	var tempMessages:Array<Array<Dynamic>> = [];
	public function showTempmessage(str:String,?color:FlxColor = FlxColor.LIME,?time:Float = 5,?center:Bool = true,?trac:Bool = true){
		var moveDown = false;
		var lastBacking = null;
		if (tempMessages.length > 0){
			moveDown = true;
			lastBacking = tempMessages[tempMessages.length - 1][2];
		}
		
		if(trac) trace(str);
		try{

		var tempMessage = new FlxText(40,60,1000,str,24);
		tempMessage.setFormat(CoolUtil.font, 24, color, LEFT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
		tempMessage.scrollFactor.set();
		tempMessage.autoSize = false;
		tempMessage.width = 1280;
		tempMessage.height = 720;
		tempMessage.textField.width = 1280;
		tempMessage.textField.height = 720;
		if(center){
			tempMessage.alignment = CENTER;
			tempMessage.screenCenter(X);
		}
		// tempMessage.wordWrap = false;
		var tempMessBacking = new FlxSprite(tempMessage.x - 2,tempMessage.y - 2).loadGraphic(FlxGraphic.fromRectangle(Std.int(tempMessage.width + 4),Std.int(tempMessage.height + 4),0xaa000000));
		tempMessBacking.scrollFactor.set();
		if(FlxG.cameras.list[FlxG.cameras.list.length - 1] != null){
			tempMessBacking.cameras = tempMessage.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		}
		// add(tempMessBacking);
		// add(tempMessage);
		if(moveDown){
			tempMessBacking.y = lastBacking.y + lastBacking.height;
			tempMessage.y = tempMessBacking.y + 2;
		};
		tempMessages.push([Sys.time() + time,tempMessage,tempMessBacking]);
		}catch(e){trace(e);}
	}
	public function showTempBanner(str:String,?color:FlxColor = FlxColor.LIME,?time:Float = 5,?center:Bool = true,?trac:Bool = true){
		while(tempMessages.length > 0){
			var e = tempMessages.pop();
			e[2].destroy();
			e[1].destroy();
		}
		showTempmessage(str,color,time,center,trac);
	}



	var skippedFrames = 0;
	var checkInputFocus:Bool = true;
	var hasTextInputFocus = false;
	public var toggleVolKeys:Bool = true; 
	public function onTextInputFocus(object:Dynamic){
		if(toggleVolKeys) CoolUtil.toggleVolKeys(false);
	}
	public function onTextInputUnfocus(object:Dynamic){
		if(toggleVolKeys) CoolUtil.toggleVolKeys(true);
	}

	// public var UIElements:Array<Dynamic> = [];
	public var uiMap:Map<String,Dynamic> = new Map<String,Dynamic>(); 
	inline function clearUIMap(){
		for (i => v in uiMap){
			if (v != null && v.destroy != null) v.destroy();
			uiMap[i] = null;
		}
	}

	public static var currentColor = 0;
	// Have to keep track of steps, else they'll try to hit multiple times
	var oldBeat:Int = 0;
	var oldStep:Int = 0;
	override function update(elapsed:Float) {
		lastUpdateTime = Sys.time();
		if(tempMessages[0] != null && (tempMessages[0][0] < lastUpdateTime)){
			try{
				var msg = tempMessages.shift();
				remove(msg[1]);
				remove(msg[2]);
				msg[1].destroy();
				msg[2].destroy();
				if(tempMessages[0] != null){
					for (_ => msg in tempMessages){
						msg[1].y -= Std.int(msg[2].height);
						msg[2].y -= Std.int(msg[2].height);
					}
				}
			}catch(e){}
		}
		if(FlxG.keys.justPressed.F3){
			var mess = 'Global Mouse pos: ${FlxG.mouse.x},${FlxG.mouse.y}; Screen mouse pos: ${FlxG.mouse.screenX},${FlxG.mouse.screenY}; member count: ${members.length}'; 
			// trace(mess);
			showTempmessage(mess);
		}
		if(FlxG.keys.justPressed.F4 && forceQuit){
			throw("Manually triggered error");
		}
		
		updateSteps();
		if(FlxG.mouse.justPressed && checkInputFocus && FlxG.mouse.visible){
			var hasPressed = false;

			var i:Int = 0;
			var obj:Dynamic = null;
			try{

				forEach(function(basic:Dynamic){
					try{

						if(!Std.isOfType(basic,flixel.addons.ui.FlxUITabMenu) && !Std.isOfType(basic,flixel.addons.ui.FlxUI) && Reflect.field(basic,"HasFocus") != null && Reflect.field(basic,"HasFocus")){
							obj = basic;
							hasPressed = true;
						}
					}catch(e){trace('oh no i errored while checking for a item');}
				},true);
				if(!hasPressed){
					for (i => obj in uiMap){
						if(obj != null && Reflect.field(obj,"HasFocus") != null && Reflect.field(obj,"HasFocus")) hasPressed = true; break;
					}
					
				}
			}catch(e){trace('oh no i errored while checking for a item');}

			// while (i < length)
			// {
			// 	basic = members[i++];

			// 	if (basic != null)
			// 	{
					
			// 	}
			// }
			if(hasTextInputFocus != hasPressed){
				hasTextInputFocus = hasPressed;
				if(hasPressed) onTextInputFocus(obj);
				else onTextInputUnfocus(obj);

			}
		}
		if(SESave.data.animDebug){
			Overlay.debugVar = '\nBPM:${Conductor.bpm}/${HelperFunctions.truncateFloat(Conductor.crochet,2)}MS(S:${HelperFunctions.truncateFloat(Conductor.stepCrochet,2)}MS)\ncurBeat:${curBeat}\ncurStep:${curStep}';
		}

		super.update(elapsed);
		// SELoader.gc();
	}
	@:keep inline public function updateSteps(){
		updateCurStep();
		updateBeat();
		if (oldStep != curStep && curStep > 0){
			if(oldStep > curStep && Conductor.bpmChangeMap != null){ // Gotta resync the 
				// var position = Conductor.songPosition;
				var newStep = curStep;
				for(ev in Conductor.bpmChangeMap){
					if(ev.stepTime < newStep){
						curStep = ev.stepTime;
						updateCurStep();
						updateBPMChange();
					}else break;
				}
				curStep = newStep;
				// Conductor.songPosition = position;
			}
			oldStep = curStep;
			stepHit();
			updateBPMChange();
		}
	}
	private function updateBeat():Void {
		oldBeat = curStep;
		curBeat = Math.floor(curStep / 4);
	}


	public var lastBPMChange:BPMChangeEvent = {
		stepTime: 0,
		songTime: 0,
		bpm: Conductor.bpm
	};
	private function updateCurStep():Void {
		// if(Conductor.bpmChangeMap != null){
			
		// 	for (i in 0...Conductor.bpmChangeMap.length)
		// 	{
		// 		if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime){
		// 			lastChange = Conductor.bpmChangeMap[i];
		// 		}else break;
		// 	}
		// }


		var prog = (Conductor.offset + Conductor.songPosition - lastBPMChange.songTime) / Conductor.stepCrochet;
		curStepProgress = prog % 1;
		curStep = lastBPMChange.stepTime + Math.floor(prog);
		
	}
	@:keep inline function updateBPMChange(){
		if(Conductor.songPosition > 0 && Conductor.bpmChangeMapSteps != null && Conductor.bpmChangeMapSteps[curStep] != null){
			Conductor.changeBPM((lastBPMChange = Conductor.bpmChangeMapSteps[curStep]).bpm);
		}
	}

	public function stepHit():Void {
		if (curStep % 4 == 0 && oldBeat != curBeat){
			oldBeat = curBeat;
			beatHit();
		}
	}

	public function beatHit():Void {
		//do literally nothing dumbass
	}
	
	@:keep inline public function fancyOpenURL(schmancy:String) FlxG.openURL(schmancy);
	override function switchTo(nextState:FlxState):Bool{
		tranOut();
		FlxG.mouse.visible = false;
		FlxG.mouse.enabled = true;
		return super.switchTo(nextState);
	}
	public static function switchState(nextState:FlxState){
		return FlxG.switchState(nextState);
	}

	function tranIn(){ // Replace with empty functions to disable
		
		var oldY = FlxG.camera.x;
		FlxG.camera.x -= 300;
		FlxTween.tween(FlxG.camera, {x:oldY},0.7,{ease: FlxEase.expoOut});
		var oldZoom = FlxG.camera.zoom;
		FlxG.camera.zoom += 1;
		FlxTween.tween(FlxG.camera, {zoom:oldZoom},0.7,{ease: FlxEase.expoOut});
		LoadingScreen.hide();
		
	}
	function tranOut(){
		// active = false;
		
		if(loading) LoadingScreen.show();
		
		
		
		FlxTween.tween(FlxG.camera, {x:FlxG.width},0.9,{ease: FlxEase.expoIn});
		FlxTween.tween(FlxG.camera, {zoom:2},1,{ease: FlxEase.expoIn});

	}


	public var debugMode:Bool = false;
	public var debugOverlay:DebugOverlay;
	override function tryUpdate(elapsed:Float):Void
	{
		if(FlxG.keys.justPressed.F1 && forceQuit){
			Console.showConsole = false;
			MainMenuState.handleError("Manually triggered force exit");
		}
		if(Console.showConsole && onlinemod.OnlinePlayMenuState.socket == null ) return;
		if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.F8 && onlinemod.OnlinePlayMenuState.socket == null){
			debugMode = !debugMode;
			if(debugMode){
				debugOverlay = new DebugOverlay(this);
			}else{
				debugOverlay.destroy();
			}
		}
		if(debugMode)
			debugOverlay.update(elapsed);
		else if ((persistentUpdate || subState == null))
			update(elapsed);

		if (_requestSubStateReset)
		{
			_requestSubStateReset = false;
			resetSubState();
		}
		if (subState != null)
		{
			subState.tryUpdate(elapsed);
		}
	}


	override function draw(){
		super.draw();
		if(debugMode) debugOverlay.draw();
		if(tempMessages.length > 0){
			var i = 0;
			while (i < tempMessages.length){
				tempMessages[i][2].draw();
				tempMessages[i][1].draw();
				i++;
			}
		}
	}
	public function consoleCommand(text:String,args:Array<String>):Dynamic{
		return null;
	}
}




class DebugOverlay extends FlxTypedGroup<FlxSprite>{
	var bg:FlxSprite;
	var oldTarget:FlxObject = null;
	var songPos:Float = 0;
	var songLooped:Bool = false;
	var songFinishCallback:Dynamic = null;
	override public function new(parent:MusicBeatState){
		mouseEnabled = FlxG.mouse.visible;
		this.parent = parent;
		FlxG.mouse.visible = true;
		super();
		MusicBeatState.instance.showTempmessage('Enabled Debug overlay');
		if(objectPosText == null){
			objectPosText = new FlxText(0,-100,'X:2000,Y:2000');
			objectPosText.setFormat(null, 16, 0xffffaaff, CENTER);
			// objectPosText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,2,);
			objectPosText.scrollFactor.set();
		}
		if(objectPosBack == null){
			objectPosBack = new FlxSpriteLockScale(-10,-100);
			objectPosBack.makeGraphic(1,1,FlxColor.BLACK);
			objectPosBack.lockGraphicSize((Std.int(objectPosText.width) + 4),Std.int(objectPosText.height) + 4);
			objectPosBack.alpha = 0.4;
			objectPosBack.scrollFactor.set();
		}
		add(objectPosBack);
		add(objectPosText);
		objectPosBack.visible = objectPosText.visible = false;
		oldTarget = FlxG.camera.target;
		FlxG.camera.target = null;
		if(FlxG.sound.music != null){
			songPos = FlxG.sound.music.time;
			songLooped = FlxG.sound.music.looped;
			FlxG.sound.music.looped = true;
			FlxG.sound.music.onComplete=null;
			songFinishCallback = FlxG.sound.music.onComplete;
		}
	}
	var parent:MusicBeatState;
	var obj:FlxObject;
	var ox:Float = 0;
	var oy:Float = 0;
	var mx:Float = 0;
	var my:Float = 0;
	var mouseEnabled:Bool = false;
	var objectPosText:FlxText;
	var objectPosBack:FlxSpriteLockScale;
	function getTopObject():Dynamic{
		var id = parent.members.length - 1;
		while (id >= 0 && obj == null) {
			try{
				var _ob:Dynamic = parent.members[id];
				if(_ob != null && FlxG.mouse.overlaps(_ob)){
					if(!FlxG.keys.pressed.SHIFT && _ob.members != null){
						var _id:Int = Std.int(_ob.members.length-1);
						var _inob:Dynamic = null;
						while (_id >= 0 && obj == null) {
							try{
								_inob = _ob.members[_id];
								_id--;

								if(_inob == null) continue;
								if(_inob.members != null){
									_id = Std.int(_inob.members.length-1);
									_ob = _inob;
									continue;
								}
								if(FlxG.mouse.overlaps(_inob)){
									obj = cast (_inob,FlxSprite);
									break;
								}
							
							}catch(e){obj = null;}
						}

						if(obj != null && !FlxG.keys.pressed.CONTROL) return obj;
					}else{
						obj = cast (_ob,FlxSprite);
						if(obj != null && !FlxG.keys.pressed.CONTROL) return obj;
					}
					// trace('Funni click on ${obj}');
						// break;
				}

			}catch(e){obj = null;}
			id--;
		}
		return obj;
	}
	var lastRMouseX:Float = 0;
	var lastRMouseY:Float = 0;
	var fakePointer:FlxObject = new FlxObject();

	override function update(el:Float){
		super.update(el);
		if(!FlxG.mouse.pressed && FlxG.mouse.pressedMiddle){
			mx=FlxG.mouse.x;
			my=FlxG.mouse.y;
			obj = fakePointer;
			fakePointer.x = FlxG.mouse.x;
			fakePointer.y = FlxG.mouse.y;
			updateObjPosText();
			obj = null;

		}
		if(FlxG.mouse.justPressed){
			mx=FlxG.mouse.x;
			my=FlxG.mouse.y;
			obj = getTopObject();
			if(obj != null){
				ox=obj.x;
				oy=obj.y;
			}
			
		}else if (FlxG.mouse.pressed && obj != null){
			// if(!FlxG.keys.pressed.SHIFT){
			obj.x = ox - mx + FlxG.mouse.x;
			obj.y = oy - my + FlxG.mouse.y;
			updateObjPosText();
			

			// }
			// MusicBeatState.instance.showTempmessage('Obj pos: ${obj.x},${obj.y}');

			if(FlxG.mouse.wheel != 0) obj.angle += FlxG.mouse.wheel;

		}else if( FlxG.keys.pressed.ALT #if(!windows) || FlxG.keys.pressed.MENU #end){
			obj = getTopObject();
			updateObjPosText();
			
		
		}else if(obj != null){
			obj = null;
		}

		if(FlxG.mouse.justPressedRight){
			lastRMouseX = Std.int(FlxG.mouse.screenX);
			lastRMouseY = Std.int(FlxG.mouse.screenY);
		}

		if(FlxG.mouse.pressedRight){
			if(FlxG.mouse.justMoved){

				var mx = Std.int(FlxG.mouse.screenX);
				var my = Std.int(FlxG.mouse.screenY);

				FlxG.camera.scroll.x+=lastRMouseX - mx;
				FlxG.camera.scroll.y+=lastRMouseY - my;
				lastRMouseX = mx;
				lastRMouseY = my;
			}
			if(FlxG.mouse.wheel != 0) FlxG.camera.zoom += (FlxG.mouse.wheel * 0.05);
			if(obj == null){
				updateObjText('CamScrollPos:${Std.int(FlxG.camera.scroll.x * 100) * 0.01},${Std.int(FlxG.camera.scroll.y * 100) * 0.01} Zoom:${Std.int(FlxG.camera.zoom * 100) * 0.01}');
			}
		}
		if(FlxG.justPressed.THREE){
			trace(objectPosText.text);
		}
	}
	@:keep inline function updateObjPosText(){
		objectPosBack.visible = objectPosText.visible = true;
		objectPosText.text = '${Std.int(obj.x * 100) * 0.001},${Std.int(obj.y * 100) * 0.001}';
		objectPosBack.x = (objectPosText.x = FlxG.mouse.screenX + 20) - 2;
		objectPosBack.y = (objectPosText.y = FlxG.mouse.screenY + 20) - 2;
		objectPosBack.lockGraphicSize((Std.int(objectPosText.width) + 4),Std.int(objectPosText.height) + 4);
	}
	@:keep inline function updateObjText(text){
		objectPosBack.visible = objectPosText.visible = true;
		objectPosText.text = text;
		objectPosBack.x = (objectPosText.x = FlxG.mouse.screenX + 20) - 2;
		objectPosBack.y = (objectPosText.y = FlxG.mouse.screenY + 20) - 2;
		objectPosBack.lockGraphicSize((Std.int(objectPosText.width) + 4),Std.int(objectPosText.height) + 4);
	}
	override function destroy(){
		if(FlxG.sound.music != null){
			Conductor.songPosition = FlxG.sound.music.time = songPos;
			FlxG.sound.music.looped = songLooped;
			FlxG.sound.music.onComplete = songFinishCallback;
		}
		FlxG.mouse.visible = mouseEnabled;
		FlxG.camera.target = oldTarget;
		super.destroy();
		MusicBeatState.instance.showTempmessage('Exited Debug overlay');

	}
}