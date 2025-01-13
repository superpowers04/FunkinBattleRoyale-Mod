package;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flash.display.BitmapData;
import flixel.tweens.FlxTween;
import TitleState.CharInfo;
using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	var vanIcon:Bool = false;
	var isPlayer:Bool = false;
	var isMenuIcon:Bool = false;
	var hichar:String = "UNSET";
	public var trackedSprite:FlxSprite = null;
	public var isTracked:Bool = false;
	public var trackMusic:Bool = false;
	public var trackingOffset:Float = 0;
	// public var pathh = "mods/characters";

	public function new(?char:String = 'face', ?isPlayer:Bool = false,?deprecated_clone:String = "",?isMenuIcon:Bool = false,?deprecated_path:Dynamic = null) {
		super();
		if(deprecated_clone != "") trace('HealthIcon.changeSprite: ARGUMENT "clone" IS DEPRECATED AND WILL BE IGNORED');
		if(deprecated_path != null) trace('HealthIcon.changeSprite: ARGUMENT "path" IS DEPRECATED AND WILL BE IGNORED! USE loadCustomIcon INSTEAD');
		this.isPlayer = isPlayer;
		this.isMenuIcon = isMenuIcon;
		if(char == "DONTLOAD") return;
		if(char == "face") return loadBlankIcon();
		changeSprite(char);
	}
	public function updateTracking(Pos:Float = 0){
		if(!isTracked) return;
		x = trackedSprite.x + (trackedSprite.width * Pos) + trackingOffset;
	}

	public dynamic function updateAnim(health:Float){
		animation.curAnim.curFrame = ((health < 20) ? 1 : 0);
	}
	var bounceTween:FlxTween;
	public function bounce(time:Float){
		scale.set(1.2,1.2);
		if(bounceTween != null) bounceTween.cancel();
		bounceTween = FlxTween.tween(this.scale,{x:1,y:1},time);
	}
	var imgPath:String = "mods/characters/";
	public function fromCharInfo(char:Dynamic) {
		var charInfo:CharInfo = ( (char is String) ? TitleState.findChar(char) : ((char is CharInfo) ? cast(char) : null) );
		if(char == hichar) return;
		if(charInfo == null || char == null || charInfo.id == "lonely" || char == "lonely" || char == "face"){
			trace('Empty icon provided, defaulting to face');
			loadBlankIcon();
			return;
		}
		imgPath = charInfo.iconLocation;
		if (!SELoader.exists(imgPath)){
			imgPath = '${char.path}/healthicon.png';
			if(!SELoader.exists(imgPath)){
				loadBlankIcon();
				return;
			}
		}
		loadCustomIcon(imgPath);
		hichar = char;
		antialiasing = !hichar.contains('-pixel');


		scrollFactor.set();
		if(isMenuIcon) offset.set(75,75);
		updateAnim(50);
	}
	public function changeSprite(char:String = 'face',?deprecated_clone:Dynamic = null,?deprecated_useClone:Dynamic = null,?deprecated_path:Dynamic = null) {
		if(char == hichar) return;
		if(char == "lonely" || char == "face") loadBlankIcon();
		if(char == "EVENTNOTE") return loadCustomIcon('assets/images/healthicons/EVENTNOTE.png');
		if(char.endsWith('.png')) {
			loadCustomIcon(char);
			char = char.substring(char.lastIndexOf('/'),char.lastIndexOf('.'));
			scrollFactor.set();
			if(isMenuIcon) offset.set(75,75);
			updateAnim(50);
			hichar = char;
			return;
		}
		if(deprecated_useClone != null) trace('HealthIcon.changeSprite: ARGUMENT "useClone" IS DEPRECATED AND WILL BE IGNORED');
		if(deprecated_clone != null) trace('HealthIcon.changeSprite: ARGUMENT "clone" IS DEPRECATED AND WILL BE IGNORED');
		if(deprecated_path != null) trace('HealthIcon.changeSprite: ARGUMENT "path" IS DEPRECATED AND WILL BE IGNORED! USE loadCustomIcon INSTEAD');
		fromCharInfo(char);

	}
	public function loadBlankIcon(){
		updateAnim = function(health:Float){animation.curAnim.curFrame = ((health < 20) ? 1 : 0);};
		loadGraphic(SELoader.loadGraphic(imgPath = 'assets/images/healthicons/NOICON.png'), true, 150, 150);
		hichar = 'face';
		animation.add("face", [0,1], 0, false, isPlayer);
		animation.play("face");
		antialiasing = true;
		scrollFactor.set();
		if(isMenuIcon) offset.set(75,75);
		updateAnim(50);
	}
	function updateAnimEmpty(health:Float){animation.curAnim.curFrame = ((health < 20) ? 1 : 0);}
	function updateAnimTwo(health:Float){animation.curAnim.curFrame = ((health < 20) ? 1 : 0);}
	function updateAnimDynamic(health:Float){animation.curAnim.curFrame = Math.round(animation.curAnim.numFrames * (health / 150));}
	public function loadCustomIcon(path:String = ""){
		if(path == "") {
			trace('Attempted to load a health icon with no path. If this is intentional then use loadBlankIcon or change visibility');
			return loadBlankIcon();
		}
		var bitmapData = SELoader.loadBitmap(path);
		var height:Int = bitmapData.height;
		var width:Int = bitmapData.width;
		var frameCount = 1; // Has to be 1 instead of 2 due to how compooters handle numbers
		if(width % 150 != 0 || height % 150 != 0){ // Invalid sized health icon! Split in half rather than error
			width = Std.int(bitmapData.width * 0.5);
			updateAnim = updateAnimTwo;
		}else{
			frameCount = Std.int(bitmapData.width / height)-1; // If this isn't an integer, fucking run
			updateAnim = ((frameCount < 1) ? updateAnimEmpty : ((frameCount == 1) ? updateAnimTwo : updateAnimDynamic));
		}
		loadGraphic(FlxGraphic.fromBitmapData(bitmapData), true, height, height);
		animation.add(hichar, (frameCount == 0) ?  [0] : [for (i in 0 ... frameCount) i], 0, false, isPlayer);
		animation.play(hichar);
	}

	override function draw() {
		if (trackMusic) scale.x = scale.y = (1.3 - (((Conductor.songPosition / Conductor.crochet) % 1)*0.2));

		super.draw();
	}
	override function update(elapsed:Float) {
		// if (trackMusic) scale.x = scale.y = (1.3 - ((Conductor.songPosition / Conductor.crochet) % 1));
		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
		super.update(elapsed);
	}
}
