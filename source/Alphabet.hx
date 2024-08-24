package;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import sys.io.File;
import sys.FileSystem;
import flixel.graphics.FlxGraphic;
import flash.display.BitmapData;
import se.extensions.flixel.FlxSpriteLockScale;
import flixel.animation.FlxAnimation;

using StringTools; 


/**
 * Loosley based on FlxTypeText lolol
 */
class Alphabet extends FlxSpriteGroup
{
	public var delay:Float = 0.05;
	public var paused:Bool = false;

	// for menu shit
	public var targetY:Float = 0;
	public var isMenuItem:Bool = false;
	 // You can just add the value to this alphabet instead of needing a completely seperate array
	public var menuValue:Dynamic = null;

	public var text(default,set):String = "";

	public function set_text(repl:String = ""):String{
		if(members.length > 0){
			var e:FlxSprite;
			while (members.length > 0){
				e = remove(members[0],true);
				if(e != null) e.destroy();
			}
		}
		
		if(listOAlphabets != null && listOAlphabets.length > 0){
			var e:FlxSprite;
			while (listOAlphabets.length > 0){
				e = listOAlphabets.pop();
				if(e != null && e.destroy != null) e.destroy();
			}
		}
		xPos = 0;
		lastSprite = null;
		lastWasSpace = false;
		
		_finalText = text = se.translation.Lang.get(repl);
		setup();
		return text;
	}
	var _finalText:String = "";
	var _curText:String = "";
	public static var sprite:FlxSprite;
	public static var Frames(get,set):FlxFramesCollection;
	public static function get_Frames():FlxFramesCollection{
		return sprite.frames;
	}
	public static function set_Frames(vari:FlxFramesCollection):FlxFramesCollection{
		return sprite.frames = vari;
	}

	public var widthOfWords:Float = FlxG.width;

	var yMulti:Float = 1;


	// custom shit
	// amp, backslash, question mark, apostrophy, comma, angry faic, period
	var lastSprite:AlphaCharacter;
	var xPosResetted:Bool = false;
	var lastWasSpace:Bool = false;
	public var textObj:FlxText;

	var listOAlphabets:List<AlphaCharacter>;

	var splitWords:Array<String> = [];

	var isBold:Bool = false;
	public var xOffset:Float = 70;
	public var yOffset:Float = 0;
	public var useAlphabet:Bool = true;
	public var selected:Bool = false;
	public var moveX:Bool = true;
	public var moveY:Bool = true;
	public var adjustAlpha:Bool = true;
	public var persist:Bool = false;
	public var removeDashes = true;
	public var forceFlxText:Bool = false;
	public var cutOff(default,set):Int = 0;
	public var border:FlxSpriteLockScale = null;
	public function set_cutOff(value:Int){
		cutOff = value;
		var spr:FlxSprite;
		if(members.length > 0){
			while (members.length > 0){
				spr = remove(members[0],true);
				if(spr != null && spr.destroy != null) spr.destroy();
			}
		}
		if(listOAlphabets != null && listOAlphabets.length > 0){
			while (listOAlphabets.length > 0){
				spr = listOAlphabets.pop();
				if(spr != null && spr.destroy != null) spr.destroy();
			}
		}
		xPos = 0;
		lastSprite = null;
		lastWasSpace = false;
		
		addText(false,(if(value == 0 || text.length <= value + 3) text else text.substring(0,value) + '...'));
		return cutOff;
	}

	public function changeScale(mult:Float = 1){
		scale.x = mult;
		scale.y = mult;
		text = text;
	}
	// public var bounce=true;
	public var bounceTween:FlxTween;
	public function bounce(){
		scale.x = scale.y = 1.1;
		if(bounceTween != null){
			bounceTween.cancel();
			bounceTween.destroy();
		}
		bounceTween = FlxTween.tween(scale,{x:1,y:1},0.2,{ease:FlxEase.expoOut});
	}
	public override function destroy(){
		if(!persist){
			if(timer != null)timer.destroy();
			super.destroy();
		}else{visible = false;}
	}

	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = false, typed:Bool = false, dontMoveX:Bool = false,?xOffset:Float = 70,?useAlphabet:Bool = true)
	{
		super(x, y);

		_finalText = text;
		isBold = bold;
		this.xOffset = xOffset;
		if(SESave.data.useFontEverywhere) this.useAlphabet = useAlphabet = false;
		this.moveX = !dontMoveX;
		this.useAlphabet = useAlphabet;
		if(sprite == null || Frames == null){
			if(sprite == null) sprite = new FlxSprite();
			trace('Loading alphabet sprites');
			if(SESave.data.useFontEverywhere){
				Frames = new flixel.graphics.frames.FlxFramesCollection(FlxGraphic.fromRectangle(1,1,0x01000000,false,"blank.mp4"));
			}else{
				try{
					if(!SELoader.exists("mods/alphabet.png") || !SELoader.exists("mods/alphabet.xml")) throw('');
					Frames = SELoader.loadSparrowFrames('mods/alphabet');
				}catch(e){
					Frames = SELoader.loadSparrowFrames('assets/images/alphabet');
					// Paths.getSparrowAtlas('alphabet');
				}
			}
		}
		this.text = text;
	}
	inline function setup(){
		if(text == "") return;
		if(!useAlphabet) forceFlxText = true;
		listOAlphabets = new List<AlphaCharacter>();
		addText();
	}

	var xPos:Float = 0;
	var yPos:Float = 0;
	public function addText(bounce:Bool = false,?finalText:String = "")
	{
		if(border != null){
			remove(border);
			border.destroy();
		}
		if(finalText == "") finalText = _finalText;
		splitWords = finalText.split("");
		var _X = -xOffset;
		var _Y = y;
		x = y = 0;

		for (character in splitWords) {addLetter(character,bounce);}

		x=_X;
		y=_Y;
		try{
			border = new FlxSpriteLockScale(-10,-10);
			border.makeGraphic(1,1,FlxColor.BLACK);
			border.lockGraphicSize((Std.int(width) + 20),Std.int(height) + 20);
			border.alpha = SESave.data.useTouch ? 0.1 : 0.001;
			insert(0,border);
		}catch(e){trace(e);}
		
	}
	var currentLetter = 0;
	var timer:FlxTimer;
	public function startTyping(secsBetweenLetters:Float = 0.3,max:Float = 0,?callback:AlphaCharacter -> Void){
		// showLetter(0,secsBetweenLetters);
		for (i in members){if(i != null) i.visible = false;}
		if(max > 0){
			secsBetweenLetters = max / members.length;
			// trace(secsBetweenLetters);
		}
		timer = new FlxTimer().start(secsBetweenLetters,function(_){
			var spr:FlxSprite = cast members[currentLetter];
			if(spr != null){
				spr.visible = true;
				if(callback != null && spr is AlphaCharacter){
					callback(cast (spr,AlphaCharacter));
				}
			}
			currentLetter++;
		},length);
	}
	public function addLetter(character:String,bounce:Bool = false){
		if (character == " " || removeDashes && ( character == "-" || character == "_")){ 
			lastWasSpace = true;
			return;
		}
		if(character=="\n"){
			lastWasSpace=false;
			yPos+=70 * scale.x;
			lastSprite = null;
			return;
		}

		// if (AlphaCharacter.acceptedChars.contains(character.toLowerCase()))
			// if (AlphaCharacter.alphabet.contains(character.toLowerCase()))
		// {
		if (lastSprite != null) xPos = lastSprite.x + lastSprite.width;

		if (lastWasSpace){
			xPos += 40 * scale.x;
			lastWasSpace = false;
		}

		// var letter:AlphaCharacter = new AlphaCharacter(30 * loopNum, 0);
		var letter:AlphaCharacter = new AlphaCharacter(xPos, yPos,removeDashes);
		listOAlphabets.add(lastSprite = letter);
		add(letter);
		if (!useAlphabet) letter.useFLXTEXT(isBold ? character.toUpperCase() : character,isBold)
		else if (isBold) letter.createBold(character.toUpperCase());
		else letter.createLetter(character);
		if(bounce) {
			letter.scale.x = letter.scale.y = 1.1;
			FlxTween.tween(letter.scale,{x:1,y:1},0.5,{ease:FlxEase.quadInOut});
		}
		// }
	}


	public var personTalking:String = 'gf';
	public var screenCentX:Bool = false;
	public var screenCentY:Bool = false;

	override function update(elapsed:Float)
	{
		if (isMenuItem){
			if(moveY) y = FlxMath.lerp(y, (targetY * (120 * scale.x)) + (FlxG.height * 0.48) + yOffset,10 * elapsed);
			if(moveX) x = FlxMath.lerp(x, xOffset, 10 * elapsed);
		}
		if(visible) super.update(elapsed);
		if(screenCentX) screenCenter(X);
		if(screenCentY) screenCenter(Y);

	}
	override function revive(){
		super.revive();
		if (isMenuItem){
			if(moveY) y = (targetY * (120 * scale.x)) + (FlxG.height * 0.48) + yOffset;
			if(moveX) x = xOffset;
		}
		if(screenCentX) screenCenter(X);
		if(screenCentY) screenCenter(Y);

	}
}

@:structInit class CachedSprite{
	public var frames:flixel.graphics.frames.FlxFramesCollection;
	public var graphic:FlxGraphic;
}


class AlphaCharacter extends FlxSprite {
	public static var alphabet:String = "abcdefghijklmnopqrstuvwxyz";
	public static var acceptedChars:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890~#$%()*+:;<=>@[|]^.,'!?/";
	public static var alphabetMap:Map<String,String> = [
		","=>"-comma-",
		'.'=>"-period-",
		'?'=>"-question-",
		'\''=>"-apostraphie-",
		">"=>"-left arrow-",
		"<"=>"-right arrow-",
		"*"=>"-multiply x-",
		"\""=>"-end quote-",
		"/"=>"-forward slash-",
		"\\"=>"-back slash-",
		" "=>"space",
		"!" => 'exclamation point',
	];

	public static var numbers:String = "1234567890";
	public static var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!? /";
	public static var textCache:Map<String,FlxSprite> = [];
	public static var alphabetAnims:Map<String, Array<Int>> = [];


	public static function cacheAlphaChars(){
		// LoadingScreen.loadingText = "Caching text characters";
		// var txt = new FlxText(-10000,0,"",48);
		// for (char in acceptedChars) {
		// 	cacheText(acceptedChars.charAt(char),true,txt);
		// 	cacheText(acceptedChars.charAt(char),false,txt);
		// }
		// txt.destroy();
		// trace('Cached Alpha Characters');
	}
	public static function cacheText(char:String = "",?bold:Bool = false,?txt:FlxText = null):FlxSprite{
		if(char == "") return null;
		var kill = false;
		if(txt == null) {
			txt = new FlxText(-10000,0,"",48);
			kill = true;
		}
		var charID = char + (bold ? "-bold" : "");
		txt.text = char;
		if(bold){
			txt.color = 0xFFFFFF;
			txt.setBorderStyle(OUTLINE,0xff000000,5);
		}else{
			txt.color = 0xff000000;
		}
		txt.drawFrame();
		// var _char:CachedSprite = {
		// 	frames:txt.frames,
		// 	graphic:FlxGraphic.fromGraphic(txt.graphic,true,charID)
		// };
		// _char.graphic.dump();
		// _char.graphic.persist = true;
		var spr = textCache[charID] = new FlxSprite();
		spr.frames = txt.frames;
		spr.graphic = txt.graphic;
		spr.graphic.persist = true;

		if(kill) txt.destroy();
		return spr;
	}

	public var row:Int = 0;
	public var showDashes = false;
	public var forceFlxText:Bool = false;

	public function new(x:Float, y:Float,?allowDashes:Bool = false,?forcedFlxText:Bool = false) {
		super(x, y);
		frames = Alphabet.Frames;
		
		showDashes = allowDashes;
		forceFlxText = forcedFlxText;

		antialiasing = true;
	}
	public function addAnim(anim:String,?letter:String):Bool{
		@:privateAccess{
			if(frames == Alphabet.Frames && alphabetAnims.exists(anim)){
				// animation._animations = alphabetAnims;
				animation._animations[anim] = new FlxAnimation(animation,anim,alphabetAnims[anim],24);
				return true;
			}
			animation.addByPrefix(anim, anim ?? letter, 24);
			if(!animation.exists(anim)) return false;
			if(frames == Alphabet.Frames){
				alphabetAnims[anim] = animation._animations[anim].frames;
			}
			return true;
		}
	}
	
	@:keep inline public function createBold(letter:String) {
		var _letter = letter.toUpperCase() + " bold";

		if(addAnim(_letter)){
			animation.play(_letter);
			updateHitbox();
		}else{
			useFLXTEXT(letter,true);
		}
	}

	@:keep inline public function createLetter(letter:String):Void
	{
		var letterCase:String = (letter.toLowerCase() == letter ? "lowercase" : 'capital');
		if(forceFlxText){
			useFLXTEXT(letter);
		}else{
			if (symbols.contains(letter)){
				createSymbol(letter);
			}else{
				addAnim(letter,letter);
				if(addAnim(letter,'$letter $letterCase')){
					animation.play(letter);
					updateHitbox();
				}else{
					useFLXTEXT(letter);
				}
			}
		}

		if (alphabet.contains(letter)) y = (110 - height);
	}

	@:keep inline public function createNumber(letter:String,bold:Bool = false):Void {
		animation.addByPrefix(letter, letter, 24);
		updateHitbox();
	}
	@:keep inline public function useFLXTEXT(letter:String,bold:Bool = false) {

		var cacheID = letter + (bold ? '-bold' : '');
		var txt = textCache[cacheID] ?? cacheText(letter,bold);
		if(txt != null){
			graphic = txt.graphic;
			frames = txt.frames;
		}
	}

	public function createSymbol(letter:String) {
		if(alphabetMap[letter] != null && addAnim(letter, alphabetMap[letter])){
			animation.play(letter);
			updateHitbox();
			return;
			
		}
		
		if(addAnim(letter)){
			animation.play(letter);
			updateHitbox();
			return;
		}
		useFLXTEXT(letter);
	}
}
