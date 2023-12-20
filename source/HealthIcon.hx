package;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flash.display.BitmapData;
import flixel.tweens.FlxTween;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;
	var vanIcon:Bool = false;
	var isPlayer:Bool = false;
	var isMenuIcon:Bool = false;
	var frameCount:Int = 2;
	var hichar:String = "";
	public var trackedSprite:FlxSprite = null;
	public var isTracked:Bool = false;
	public var trackingOffset:Float = 0;
	// public var pathh = "mods/characters";

	public function new(?char:String = 'bf', ?isPlayer:Bool = false,?clone:String = "",?isMenuIcon:Bool = false,?path:String = "mods/characters") {
		super();
		this.isPlayer = isPlayer;
		this.isMenuIcon = isMenuIcon;
		changeSprite(char,"",path);
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
	public function changeSprite(?char:String = 'face',?clone:String = "face",?useClone:Bool = true,?pathh:String = "mods/characters") {
		if(char == hichar) return;
		if(char == "lonely") char = "face";
		var chars:Array<String> = ["INTERNAL|bf","INTERNAL|gf","face",'EVENTNOTE'];
		var relAnims:Bool = true;

		var _path = "";
		var _char = TitleState.findChar(char);
		if(_char != null){
			imgPath = _char.path + "/";
			char = _char.folderName;
		}else{
			char = 'bf';
			imgPath = "mods/characters/";

		}
		
		if (!chars.contains(char) && SELoader.exists(imgPath+char+"/healthicon.png")){
			// trace('Custom character with custom icon! Loading custom icon.');
			var bitmapData = SELoader.loadBitmap('${imgPath}$char/healthicon.png');
			var height:Int = 150;
			var width:Int = 150;
			frameCount = 1; // Has to be 1 instead of 2 due to how compooters handle numbers
			if(bitmapData.width % 150 != 0 || bitmapData.height % 150 != 0){ // Invalid sized health icon! Split in half rather than error
				height = bitmapData.height;
				width = Std.int(bitmapData.width * 0.5);
			}else{
				frameCount = Std.int(bitmapData.width / 150) - 1; // If this isn't an integer, fucking run
				if(frameCount == 0) updateAnim = function(health:Float){return;};
				else if(frameCount == 1) updateAnim = function(health:Float){
					animation.curAnim.curFrame = ((health < 20) ? 1 : 0);
				};
				else updateAnim = function(health:Float){animation.curAnim.curFrame = Math.round(animation.curAnim.numFrames * (health / 150));};
			}
			loadGraphic(FlxGraphic.fromBitmapData(bitmapData), true, bitmapData.height, bitmapData.height);
			// char = "customChar";
			vanIcon = false;
			frameCount = frameCount + 1;
			animation.add(char, if(frameCount > 1)[for (i in 0 ... frameCount) i] else [0,1], 0, false, isPlayer);
		}else if ((chars.contains(char) || chars.contains(clone)) && SELoader.exists(imgPath+char+"/icongrid.png")){
			// trace('Custom character with custom icongrid! Loading custom icon.');
			loadGraphic(SELoader.loadGraphic('${imgPath}$char/icongrid.png'), true, 150, 150);
			if (clone != "") char = clone;
			vanIcon = false;
			animation.add('bf', [0, 1], 0, false, isPlayer);
		}else{
			if (clone != "" && (useClone || !chars.contains(char))) char = clone; else if(!chars.contains(char.toLowerCase())) char = "bf";

			if (!vanIcon) loadGraphic(SELoader.loadGraphic('assets/images/iconGrid.png',true), true, 150, 150); else relAnims = false;
			vanIcon = true;
			animation.add('bf', [0, 1], 0, false, isPlayer);
		}
		
		antialiasing = true;
		
		
		if(chars.contains(char.toLowerCase())){ // For vanilla characters
			if (relAnims){
				animation.add('bf-car', [0, 1], 0, false, isPlayer);
				animation.add('bf-christmas', [0, 1], 0, false, isPlayer);
				if(graphic.width > 451){ // Old icon grid
					trace('You are using a really old iconGrid, this is usually caused by updating from a really really old version of the game\nPlease reinstall the game');
				}else{ // Based icon grid
					animation.add('gf', [2], 0, false, isPlayer);
					animation.add('INTERNAL|gf', [2], 0, false, isPlayer);
					animation.add('face', [3, 4], 0, false, isPlayer);
					animation.add('EVENTNOTE', [5, 5], 0, false, false);
				}
			}
			animation.play(char.toLowerCase());
		}else{
			// animation.play('bf');
			animation.play(char);
		}


		scrollFactor.set();
		if(isMenuIcon) offset.set(75,75);
		updateAnim(50);
		hichar = char;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
