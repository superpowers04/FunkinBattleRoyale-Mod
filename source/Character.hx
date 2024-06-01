package;
import se.extensions.flixel.SEFlxFrames;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.animation.FlxAnimation;
import flixel.animation.FlxAnimationController;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;


import haxe.DynamicAccess;
import lime.utils.Assets;
import lime.graphics.Image;
import CharacterJson;
import TitleState;
import flixel.util.FlxColor;

import openfl.media.Sound;

import sys.io.File;
import sys.FileSystem;
import flash.display.BitmapData;
import Xml;
import flixel.sound.FlxSound;

import hscript.Expr;
import hscript.Interp;
import hscriptfork.InterpSE;





using StringTools;
class CharAnimController extends FlxAnimationController{
	#if(flixel > "5.3.0")
	override function findByPrefix(AnimFrames:Array<FlxFrame>, Prefix:String,logError:Bool = true):Void
	#else
	override function findByPrefix(AnimFrames:Array<FlxFrame>, Prefix:String):Void
	#end
	{
		if(Prefix == "FORCEALLLMAOTHISISSHIT"){
			fuckinAddAll(AnimFrames);
		}
		Prefix = EReg.escape(Prefix);
		var regTP:EReg = new EReg('^${Prefix}[- ]*[0-9][0-9]?[0-9]?[0-9]?','ig'); // Fixes the game improperly registering frames from other animations
		for (index => frame in _sprite.frames.framesHash){
			if (regTP.match(index)) AnimFrames.push(frame);
		}
	}
	function fuckinAddAll(AnimFrames:Array<FlxFrame>):Void {
		for (index => frame in _sprite.frames.framesHash){
			AnimFrames.push(frame);
		}
	}
	@:keep inline public function playAnimation(anim:FlxAnimation, force = false, reversed = false, frame = 0):Void {
		var oldFlipX:Bool = false;
		var oldFlipY:Bool = false;
		if (_curAnim != null && _curAnim.name != anim.name) {
			oldFlipX = _curAnim.flipX;
			oldFlipY = _curAnim.flipY;
			_curAnim.stop();
		}
		(_curAnim = anim).play(force, reversed, frame);

		if (oldFlipX != _curAnim.flipX || oldFlipY != _curAnim.flipY) {
			_sprite.dirty = true;
		}
	}
}



@:structInit class Character extends FlxSprite{
	/* Animations */
		public var animationList:Array<CharJsonAnimation> = [];
		public var animOffsets:Map<String, Array<Float>> = ["all" => [0.0,0.0]];
		public var animLoopStart:Map<String,Int> = [];
		public var animLoops:Map<String,Bool> = [];
		public var oneShotAnims:Array<String> = ["hey"];
		public var tintedAnims:Array<String> = [];
		public var replayAnims:Array<String> = [];
		public var loopAnimFrames:Map<String,Int> = [];
		public var loopAnimTo:Map<String,String> = [];
		// Anim priorities, can be used so animations can override others
		// 0 is used for idle animations
		// 5 is used for hey, cheer and scared
		// 7 is used for song start 
		// 10 is used for any sing animations, like dodge, hurt, sing or attack animations
		// 15 is used for missing notes
		// 100  
		public static var animCaseInsensitive:Map<String,String> = [
			"singleft-alt" => "singLEFT-alt",
			"singdown-alt" => "singDOWN-alt",
			"singup-alt" => "singUP-alt",
			"singright-alt" => "singRIGHT-alt",
			"idle-alt" => "idle-alt",
			"singleft" => "singLEFT",
			"singdown" => "singDOWN",
			"singup" => "singUP",
			"singright" => "singRIGHT",
			"singleftmiss" => "singLEFTmiss",
			"singdownmiss" => "singDOWNmiss",
			"singupmiss" => "singUPmiss",
			"singrightmiss" => "singRIGHTmiss",
			"idle" => "idle",
			"danceright" => "danceRight",
			"danceleft" => "danceLeft",
			"hey" => "hey",
			"cheer" => "cheer",
			"scared" => "scared",
			"win" => "win",
			"lose" => "lose",
			"hurt" => "hurt",
			"hit" => "hit",
			"attack" => "attack",
			"shoot" => "shoot",
			"attackleft" => "attackLeft",
			"attackup" => "attackUp",
			"attackdown" => "attackDown",
			"attackright" => "attackRight",
			"shootleft" => "shootLeft",
			"shootright" => "shootRight",
			"shootup" => "shootUp",
			"shootdown" => "shootDown",
			"dodge" => "dodge",
			"dodgeleft" => "dodgeLeft",
			"dodgeright" => "dodgeRight",
			"dodgeup" => "dodgeUp",
			"dodgedown" => "dodgeDown",
			"songstart" => "songStart"
		];
		public var animationPriorities:Map<String,Int> = [
			"singLEFT-alt" => 10,
			"singDOWN-alt" => 10,
			"singUP-alt" => 10,
			"singRIGHT-alt" => 10,
			"singLEFT" => 10,
			"singDOWN" => 10,
			"singUP" => 10,
			"singRIGHT" => 10,
			"singLEFTmiss" => 10,
			"singDOWNmiss" => 10,
			"singUPmiss" => 10,
			"singRIGHTmiss" => 10,

			"idle" => 0,
			"idle-alt" => 0,
			"danceRight" => 0,
			"danceLeft" => 0,
			"danceright" => 0,
			"danceleft" => 0,
			"hey" => 13,
			"cheer" => 13,
			"scared" => 13,
			"sad" => 13,
			"win" => 100,
			"lose" => 100,
			"hurt" => 20,
			"hit" => 20,
			"attack" => 20,
			"shoot" => 20,
			"attackLeft" => 20,
			"shootLeft" => 20,
			"attackRight" => 20,
			"shootRight" => 20,
			"attackUp" => 20,
			"shootUp" => 20,
			"attackDown" => 20,
			"shootDown" => 20,
			"dodge" => 10,
			"dodgeLeft" => 10,
			"dodgeRight" => 10,
			"dodgeUp" => 10,
			"dodgeDown" => 10,
			"dodgeleft" =>10,
			"dodgeright" => 10,
			"dodgeup" => 10,
			"dodgedown" => 10,
			"songStart" => 7
		];
		var altAnims:Array<String> = []; 
		var animHasFinished:Bool = false;
	/* JSON things */
		public var charProperties:CharacterJson;
		public var charInfo:CharInfo;
		public var curCharacter:String = 'bf';
		public var namespace:String = "";
		public function getNamespacedName():String{return (if(namespace != null && namespace != "") '$namespace|' else "") + curCharacter;}
		public var camPos:Array<Int> = [0,0];
		public var charX:Float = 0;
		public var charY:Float = 0;
		public var camX:Float = 0;
		public var camY:Float = 0;
		public var useMisses:Bool = false;
		public var useVoices:Bool = false;
		public var singDuration:Float = 4; // Singduration?
		public var dadVar(get,set):Float; // Singduration?
		@:keep inline public function get_dadVar() return singDuration;
		@:keep inline public function set_dadVar(x) return singDuration = x;
		public var missSounds:Array<Sound> = [];
		public var voiceSounds:Array<FlxSound> = [];
		public var flip:Bool = true;
		public var definingColor:FlxColor;
		var flipNotes:Bool = true;

	/* Internal identifier vars */
		public var isPlayer:Bool = false;
		public var hasAlts:Bool = false;
		public var charType:Int = 0;
		public var dance_idle:Bool = false;
		public var amPreview:Bool = false;
		public var debugMode:Bool = false;

		public var charLoc:String = "mods/characters";
		var needsInverted:Int= 1;
		var customColor = false;

	/*Script shite*/
		public var skipNextAnim:Bool = false;
		public var nextAnimation:String = "";
		public var hscriptGen:Bool = false;
		public var useHscript:Bool = true;

		var interp:Interp;

	/* Misc */
		var danced:Bool = false;
		public var lonely:Bool = false;
		public var tex:FlxAtlasFrames = null;
		public var holdTimer:Float = 0;
		public var stunned:Bool = false;
		public var loadedFrom:String = "";
		public var isCustom:Bool = false;
		public var charXml:String;
		public var isStunned:Bool = false;
		public var isPressingNote:Bool = false; // Only used for the player. True if the player is currently pressing any notes keys
		public var isNew:Bool = false;

	// public var spriteArr:Array<FlxSprite> = [];
	// public var animArr:Array<FlxAnimationController> = [];
	// public var animGraphics:Map<String,Int> = [];
	// public var xmlMap:Map<String,Int> = [];
	// public var curSprite:Int = 0;


	// HScript related shit
	@privateAccess
	public function callInterp(func_name:String, args:Array<Dynamic>,?important:Bool = false):Dynamic { // Modified from Modding Plus, I am too dumb to figure this out myself 
		if ((!useHscript || amPreview) || (interp == null || !interp.variables.exists(func_name) ) && !important) {return null;}

		try{
			args.insert(0,this);
			var method = interp.variables.get(func_name);
			return Reflect.callMethod(interp,method,args);
		}catch(e){handleError('Something went wrong with ${func_name} for ${curCharacter}, ${e.message}'); return null;}
	}

	function parseHScript(scriptContents:String){
		if (amPreview || !useHscript){
			interp = null;
			trace("Skipping HScript for " + curCharacter);
			return; // Don't load in editor
		} 
		var interp = HscriptUtils.createSimpleInterp();
		var parser = new hscript.Parser();
		var program:Expr;
		try{
			parser.allowTypes = parser.allowJSON = true;
			program = parser.parseString(scriptContents);
			
			interp.variables.set("hscriptPath", '${charLoc}/$curCharacter');
			interp.variables.set("charName", curCharacter);
			interp.variables.set("charProperties", charProperties);
			interp.variables.set("PlayState", PlayState);
			interp.variables.set("state", cast FlxG.state);
			interp.variables.set("game", cast FlxG.state);
			interp.variables.set("animation", animation );
			interp.variables.set("BRtools",new HSBrTools('${charLoc}/$curCharacter/'));
			interp.execute(program);
			this.interp = interp;
		}catch(e){
			handleError('Error parsing char ${curCharacter} hscript, Line:${parser.line}; Error:${e.message}');
			
		}
	}

	// function addOffsets(?character:String = "") // Handles offsets for characters with support for clones
	// {
	// 	if(character == null || character == "" ) return;
	// 	if (Reflect.field(TitleState.defCharJson.characters,curCharacter) == null){

	// 		switch(character){
	// 			case 'bf','bf-christmas','bf-car':
	// 				charY+=330;
	// 				needsInverted = 0;
	// 				if (isPlayer){
	// 					addOffset('idle', 0);
	// 					addOffset("singUP", -34, 27);
	// 					addOffset("singRIGHT", -48, -7);
	// 					addOffset("singLEFT", 22, -6);
	// 					addOffset("singDOWN", -10, -50);
	// 					addOffset("singUPmiss", -29, 27);
	// 					addOffset("singRIGHTmiss", -30, 21);
	// 					addOffset("singLEFTmiss", 12, 24);
	// 					addOffset("singDOWNmiss", -11, -19);
	// 					addOffset("hey", 7, 4);
	// 					addOffset('scared', -4);
	// 				}else{
	// 					addOffset("singUP", 5, 30);
	// 					addOffset("singRIGHT", -30, -5);
	// 					addOffset("singLEFT", 38, -5);
	// 					addOffset("singDOWN", -15, -50);
	// 					addOffset("singUPmiss", 1, 30);
	// 					addOffset("singRIGHTmiss", -31, 21);
	// 					addOffset("singLEFTmiss", 2, 23);
	// 					addOffset("singDOWNmiss", -15, -20);
	// 					addOffset("hey", 7, 4);
	// 					addOffset('scared', -4);
	// 				}
	// 		}
	// 	}else{
	// 		var e:Dynamic = Reflect.field(TitleState.defCharJson.characters,curCharacter);
	// 		loadOffsetsFromJSON(e);
	// 		getDefColor(e);

	// 	}
	// }

	function loadOffsetsFromJSON(?charProperties:CharacterJson){
		if (charProperties == null) return;
		if (charProperties.offset_flip != null ) needsInverted = charProperties.offset_flip;
		var offsetCount = 0;
		if (charProperties.animations_offsets != null && charProperties.animations_offsets.length > 0){
			for (offset in charProperties.animations_offsets){ // Custom offsets
				offsetCount++;
				if (needsInverted == 1)
					switch (charType) {
						case 0:
							if (offset.player1 != null && offset.player1.length > 1) addOffset(offset.anim,offset.player1[0],offset.player1[1]);
						case 1:
							if (offset.player2 != null && offset.player2.length > 1) addOffset(offset.anim,offset.player2[0],offset.player2[1]); else if (offset.player1 != null && offset.player1.length > 1) addOffset(offset.anim,offset.player1[0],offset.player1[1]);
						case 2:
							if (offset.player3 != null && offset.player3.length > 1) addOffset(offset.anim,offset.player3[0],offset.player3[1]); else if (offset.player1 != null && offset.player1.length > 1) addOffset(offset.anim,offset.player1[0],offset.player1[1]);
					}
				else
					addOffset(offset.anim,offset.player1[0],offset.player1[1]);
			}	
		}


		switch(charType){
			case 0: 
				if (charProperties.char_pos1 != null){addOffset('all',charProperties.char_pos1[0],charProperties.char_pos1[1]);}
				if (charProperties.cam_pos1 != null){camX += charProperties.cam_pos1[0];camY += charProperties.cam_pos1[1];}
			case 1: 
				if (charProperties.char_pos2 != null){addOffset('all',charProperties.char_pos2[0],charProperties.char_pos2[1]);}
				if (charProperties.cam_pos2 != null){camX += charProperties.cam_pos2[0];camY += charProperties.cam_pos2[1];}
			case 2: 
				if (charProperties.char_pos3 != null){addOffset('all',charProperties.char_pos3[0],charProperties.char_pos3[1]);}
				if (charProperties.cam_pos3 != null){camX += charProperties.cam_pos3[0];camY += charProperties.cam_pos3[1];}
		}


		if(charProperties.common_stage_offset != null){
			if (needsInverted == 1 && !isPlayer){
				addOffset('all',charProperties.common_stage_offset[2],charProperties.common_stage_offset[3]); // Load common stage offset
				camX+=charProperties.common_stage_offset[2];
				camY-=charProperties.common_stage_offset[3]; // Load common stage offset for camera too
			}else{
				addOffset('all',charProperties.common_stage_offset[0],charProperties.common_stage_offset[1]); // Load common stage offset
				camX+=charProperties.common_stage_offset[0];
				camY-=charProperties.common_stage_offset[1]; // Load common stage offset for camera too
			}
		}
		if(!customColor && charProperties.color != null)
			definingColor = FlxColor.fromRGB(isValidInt(charProperties.color[0]),isValidInt(charProperties.color[1]),isValidInt(charProperties.color[2],255));
		
		if (charProperties.char_pos != null){addOffset('all',charProperties.char_pos[0],charProperties.char_pos[1]);}
		if (charProperties.cam_pos != null){camX+=charProperties.cam_pos[0];camY+=charProperties.cam_pos[1];}
	}


	function loadJSONChar(charProperties:CharacterJson){
		


		// healthIcon = charProperties.healthicon;
		singDuration = charProperties.sing_duration; // As the varname implies
		flipX=charProperties.flip_x; // Flip for BF clones
		antialiasing = !charProperties.no_antialiasing; 

		if (charProperties.flip_notes) flipNotes = charProperties.flip_notes;

		getDefColor(charProperties);
		
		var animCount = 0;
		var hasIdle = false;
		if(charProperties.animations.length > 0){
			for (index => anima in charProperties.animations){
				var property = 0;
				try{
					if (anima == null){
						trace('Animation at $index is null! Ignoring!');
						continue;
					}
					if (anima.anim == null) throw('HOW THE FUCK IS THE ANIM NULL');
					if (anima.name == null) throw('HOW THE FUCK IS THE ANIM NAME NULL');
					if (anima.anim.substr(-4) == "-alt") hasAlts=true; // Alt Checking
					if (anima.stage != "" && anima.stage != null){if(PlayState.curStage.toLowerCase() != anima.stage.toLowerCase()){continue;}} // Check if animation specifies stage, skip if it doesn't match PlayState's stage
					if (anima.song != "" && anima.song != null){if(PlayState.SONG.song.toLowerCase() != anima.song.toLowerCase()){continue;}} // Check if animation specifies song, skip if it doesn't match PlayState's song
					if (animCaseInsensitive[anima.anim] != null) anima.anim = animCaseInsensitive[anima.anim];
					if (animation.getByName(anima.anim) != null) continue; // Skip if animation has already been defined
					if (anima.char_side != null && anima.char_side != 3 && anima.char_side != charType){continue;} // This if statement hurts my brain
					

					if (anima.ifstate != null && PlayState.instance != null){
						anima.ifstate.isFunc = false; //Force because funni
						// PlayState.
						// Do on step or beat
						var events = (anima.ifstate.check == 1 ? PlayState.stepAnimEvents : PlayState.beatAnimEvents);
		
						if (events[charType] == null) events[charType] = [anima.anim => anima.ifstate]; 
						else events[charType][anima.anim] = anima.ifstate;
						
						
						// PlayState.regAnimEvent(charType,anima.ifstate,anima.anim);
					}
					if (anima.oneshot == true && !amPreview){ // "On static platforms, null can't be used as basic type Bool" bruh
						oneShotAnims.push(anima.anim);
						anima.loop = false; // Looping when oneshot is a terrible idea
					}
					if (anima.noreplaywhencalled == true && !amPreview){ //
						replayAnims.push(anima.anim);
					}
					if(anima.offsets != null) {
						animOffsets[anima.anim] = cast anima.offsets;
						if(amPreview) anima.offsets=null;
					}
					if(anima.loopStart != null && anima.loopStart != 0 ) loopAnimFrames[anima.anim] = anima.loopStart;
					
					if(anima.playAfter != null && anima.playAfter != '' ) loopAnimTo[anima.anim] = anima.playAfter;
					
					if(anima.anim == "idle" || anima.anim == "danceLeft") hasIdle = true;
					
					if (anima.indices.length > 0) { // Add using indices if specified
						addAnimation(anima.anim, anima.name,anima.indices,"", anima.fps, anima.loop,anima.flipx);
					}else if (anima.frameNames != null && anima.frameNames.length > 0) { // Add using frameNames if specified
						addAnimation(anima.anim, anima.name,anima.frameNames,"", anima.fps, anima.loop,anima.flipx);
					}else{addAnimation(anima.anim, anima.name, anima.fps, anima.loop,anima.flipx);}
					

					if(anima.priority != null && -1 < anima.priority ){
						animationPriorities[anima.name] = anima.priority;
					}
					if(animationPriorities[anima.name] == null){
						animationPriorities[anima.name] = 1;
					}
				}catch(e){handleError('${curCharacter} had an animation error ${e.details()}'); return;}
				animCount++;
			}
		}
		if(charProperties.customProperties != null && charProperties.customProperties[0] != null){
			var i = 0;
			var prop = charProperties.customProperties[i];
			while (i < charProperties.customProperties.length){
				prop = charProperties.customProperties[i];
				if(prop.path != "") {
					var obj:Dynamic = this;
					if(prop.path.contains('.')){
						var path = prop.path.split('.');
						while (path.length > 1){
							try{
								var e = path.shift();
								obj = Reflect.getProperty(obj,e);
								if(obj == null) throw('Unable to access $e');
							}catch(e){
								handleError('Error accessing ${curCharacter}.${prop.path}: ${e.details()}');
								obj = null;
								break;
							}
						}
						if(obj != null && path.length == 1){
							prop.path = path[0];
						}
					}
					if(obj != null){
						try{
							Reflect.setProperty(obj,prop.path,prop.value);
						}catch(e){
							handleError('Error setting ${curCharacter}.${prop.path} to ${prop.value}: ${e.details()}');
							break;

						}
					}
				}
				i++;
			}
		}
		if(!hasIdle){
			if(amPreview){
				// var idleName:String = "";
				// { // Load characters without a idle animation, hopefully
				// 	var regTP:EReg = (~/<SubTexture name="([A-z 0-9]+[iI][dD][lL][eE][A-z 0-9]+)[0-9][0-9][0-9][0-9]"/gm);
				// 	var input:String = charXml;
				// 	while (regTP.match(input)) {
				// 		input=regTP.matchedRight();
				// 		idleName = regTP.matched(1);
				// 		break;
				// 	}
				// }
				charProperties.animations = [{
						anim:"idle",
						name:"FORCEALLLMAOTHISISSHIT",
						loop:false,
						fps:24,
						indices:[],
						oneshot:false
					}];
				addAnimation("idle","FORCEALLLMAOTHISISSHIT");
				if(charType == 2){
					addAnimation("danceLeft","FORCEALLLMAOTHISISSHIT");
					addAnimation("danceRight","FORCEALLLMAOTHISISSHIT");
					charProperties.animations.push({
						anim:"danceLeft",
						name:"FORCEALLLMAOTHISISSHIT",
						loop:false,
						fps:24,
						indices:[],
						oneshot:false
					});
					charProperties.animations.push({
						anim:"danceRight",
						name:"FORCEALLLMAOTHISISSHIT",
						loop:false,
						fps:24,
						indices:[],
						oneshot:false
					});
				}
			}else{
				var hasBFAnims:Bool = false;
				{
					var regTP:EReg = (~/<SubTexture name="BF idle dance/g);
					var input:String = charXml;
					while (regTP.match(input)) {
						hasBFAnims = true;
						break;
					}
				}
				if (hasBFAnims){ // Legacy shit I guess
					addAnimation('idle', 'BF idle dance', 24, false);
					addAnimation('singUP', 'BF NOTE UP0', 24, false);
					// WHY DO THESE NEED TO BE FLIPPED?
					addAnimation('singLEFT', 'BF NOTE RIGHT0', 24, false); 
					addAnimation('singRIGHT', 'BF NOTE LEFT0', 24, false);
					addAnimation('singDOWN', 'BF NOTE DOWN0', 24, false);
					addAnimation('singUPmiss', 'BF NOTE UP MISS', 24, false);

					addAnimation('singRIGHTmiss', 'BF NOTE LEFT MISS', 24, false);
					addAnimation('singLEFTmiss', 'BF NOTE RIGHT MISS', 24, false);

					addAnimation('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);
					addAnimation('hey', 'BF HEY', 24, false);
				}
			}
		}
		dance_idle = (animation.getByName("danceLeft") != null);
		setGraphicSize(Std.int(width * charProperties.scale)); // Setting size
		updateHitbox();


		if(charProperties.flip != null) flip = charProperties.flip;
		loadOffsetsFromJSON(charProperties);
	}
	public function isSelectedChar():Bool{
		switch ( charType ) {
			default: return SESave.data.playerChar == curCharacter;
			case 1: return SESave.data.opponent == curCharacter;
			case 2: return SESave.data.gfChar == curCharacter;
		}
	}
	public function loadCustomChar(){
		if(charInfo == null) charInfo = TitleState.findCharByNamespace(curCharacter,namespace); // Make sure you're grabbing the right character
		curCharacter = charInfo.folderName;
		charLoc = charInfo.path;
		namespace = charInfo.nameSpace;
		SELoader.namespace = charInfo.nameSpace;

		if(SESave.data.doCoolLoading) LoadingScreen.loadingText = 'Loading Character "${getNamespacedName()}"';

		if (!amPreview && SELoader.exists('${charLoc}/$curCharacter/script.hscript')){
			parseHScript(SELoader.loadText('${charLoc}/$curCharacter/script.hscript'));
			var skipConstruct:Dynamic = callInterp("initCharacter",[]);
			if(skipConstruct != null && skipConstruct == true){
				return;
			}
		}
		// }
		// if(charLoc == "mods/characters"){

		// 	if(TitleState.weekChars[curCharacter] != null && TitleState.weekChars[curCharacter].contains(onlinemod.OfflinePlayState.nameSpace) && TitleState.characterPaths[onlinemod.OfflinePlayState.nameSpace + "|" + curCharacter] != null){
		// 		charLoc = TitleState.characterPaths[onlinemod.OfflinePlayState.nameSpace + "|" + curCharacter];
		// 		trace('$curCharacter is loading from $charLoc');
		// 	}else if(TitleState.characterPaths[curCharacter] != null){
		// 		charLoc = TitleState.characterPaths[curCharacter];
		// 		trace('$curCharacter is loading from $charLoc');
		// 	}
		// }
		isCustom = true;
		var charPropJson:String = "";
		if(charInfo.internal){
			try{
				var p = SELoader.getRawPath("assets/shared/images/")+charInfo.internalAtlas; // This is to prevent loading custom bf for internal bf
				charXml = SELoader.loadXML(p+".xml",true);
				// trace('$charXml $p');
				if(frames == null) frames=tex=FlxAtlasFrames.fromSparrow(SELoader.loadGraphic('$p.png',true),charXml);
				// trace('$frames');
				charProperties = Json.parse(charPropJson = charInfo.internalJSON);
			}catch(e){
				thrownError++;
				MainMenuState.handleError(e,'Character ${curCharacter} is a hardcoded character and caused an error, Something went terribly wrong! ${e.message}');
				return;
			}
		}else if(charInfo.psychChar){

			if (charProperties == null) {
				try{
					var file = SELoader.exists(charInfo.jsonLocation+"-SE") ? charInfo.jsonLocation+"-SE" : charInfo.jsonLocation;
					charProperties= Json.parse(CoolUtil.cleanJSON(charPropJson = SELoader.loadText(file)));
					if(amPreview && !file.endsWith('-SE')) 
						loadedFrom=file+"-SE";
					else loadedFrom=file;
				}catch(e){
					throw('Character ${curCharacter} has a missing config.json! ${e.message}');
					return;
				}
			}
			
			if ((charProperties == null || charProperties.animations == null || charProperties.animations[0] == null) && !amPreview){
				throw('$curCharacter\'s JSON is invalid!');
				return;
			} // Boot to main menu if character's JSON can't be loaded
			// if ((charProperties == null || charProperties.animations == null || charProperties.animations[0] == null) && amPreview){

			
			if(charProperties.healthicon != null) charInfo.iconLocation = SELoader.getAssetPath('assets/images/icons/'+charProperties.healthicon+'.png');
			if(frames == null){
				var pngName = SELoader.getAssetPath('assets:images/'+charProperties.image+".png");
				var xmlName = SELoader.getAssetPath('assets:images/'+charProperties.image+".xml");
				if(pngName == "" || !SELoader.exists(pngName)){
					pngName = SELoader.getAssetPath('assets:'+charProperties.image+".png");
					xmlName = SELoader.getAssetPath('assets:'+charProperties.image+".xml");
				}
				if(pngName == ""){
					throw('Unable to find image "${charProperties.image}" for $curCharacter');
					return;
				}
				if(xmlName == ""){
					throw('Unable to find xml "${charProperties.image}" for $curCharacter');
					return;
				}
				var forced:Int = 0;


				if (tex == null){
					var charJsonF:String = (xmlName).substr(0,-3) + "json";
					if (SELoader.exists(charJsonF)){
						charXml = SELoader.loadText(charJsonF);
						if (charXml == null){throw('$curCharacter is missing their sprite JSON?');} // Boot to main menu if character's XML can't be loaded

						tex = FlxAtlasFrames.fromTexturePackerJson(SELoader.loadGraphic('${charLoc}/$curCharacter/${pngName}'), charXml);
					} else {
						charXml = SELoader.loadXML(xmlName); // Loads the XML as a string. 
						if (charXml == null){throw('$curCharacter is missing their XML!');} // Boot to main menu if character's XML can't be loaded
						// if(charXml.substr(2).replace(String.fromCharCode(0),'').contains('UTF-16')){ // Flash CS6 outputs a UTF-16 xml even though no UTF-16 characters are usually used. This reformats the file to be UTF-8 *hopefully*
						// 	charXml = '<?' + charXml.substr(2).replace(String.fromCharCode(0),'').replace('UTF-16','utf-8');
						// }
						tex = SEFlxFrames.fromSparrow(SELoader.loadGraphic(pngName), charXml);
					}
					if (tex == null){throw('$curCharacter is missing their XML!');} // Boot to main menu if character's texture can't be loaded
				}
				// animOffsets['all'] = charProperties.position;
				// animOffsets['all'][1] *=-1;
				// animOffsets['all'][0] *=-1;
				// animOffsets['all'][0] *=-1;
			// dad = new EmptyCharacter(100, 100);
			// boyfriend = new EmptyCharacter(400,100);
			// gf = new EmptyCharacter(400, 100);
				if(charProperties.position != null){

					charProperties.cam_pos= charProperties.camera_position;
					charProperties.cam_pos[0]*=-1;
					charProperties.cam_pos[1]*=-1;
					charProperties.offset_flip=3;
					charProperties.char_pos = charProperties.position;
					charProperties.char_pos[0]*=-1;
					charProperties.char_pos[1]*=-1;
				}
				if(amPreview){
					charProperties.camera_position = charProperties.position = null;
				}
				// charProperties.char_pos[2] = -charProperties.char_pos[2];
				// charProperties.cam_pos1[2] = -charProperties.char_pos[2];
			}
		}else{
			loadedFrom = SELoader.getPath('${charLoc}/$curCharacter/config.json');
			if(charProperties == null && !SELoader.exists(loadedFrom) || (amPreview && FlxG.keys.pressed.SHIFT)){
				if(amPreview){
					var idleName:String = "";
					charProperties = Json.parse('{
						"flip_x":false,
						"sing_duration":6.1,
						"scale":1,
						"dance_idle":false,
						"voices":"",
						"no_antialiasing":false,
						"animations": [],
						"animations_offsets": [{"anim":"all","player1":[0,0],"player2":[0,0],"player3":[0,0]}]
					}');
					animOffsets['all'] = [0.0,0.0];
				}else{
					if(curCharacter == "bf" || curCharacter == "gf"){
						thrownError++;
						MainMenuState.handleError('Character ${curCharacter} has no character json and is a hardcoded character, Something went terribly wrong!');
						return;
					}
					MainMenuState.handleError('Character ${curCharacter} is missing a config.json!("$loadedFrom" is non-existant) You need to set them up in character selection. Using BF');
					curCharacter = "IMPORTED|bf";
					charInfo = null;
					loadChar();
					return;
				}
			}else{
				try{
					if (charProperties == null) {
						charProperties = Json.parse(CoolUtil.cleanJSON(charPropJson = SELoader.loadText(loadedFrom)));
					}
				}catch(e){
					throw('Character ${curCharacter} has a broken config.json! ${e.message}');
					return;
				}
			}
			if ((charProperties == null || charProperties.animations == null || charProperties.animations[0] == null) && !amPreview){
				throw('$curCharacter\'s JSON is invalid!');
				return;
			} // Boot to main menu if character's JSON can't be loaded
			// if ((charProperties == null || charProperties.animations == null || charProperties.animations[0] == null) && amPreview){

			loadedFrom = '${charLoc}/$curCharacter/config.json';
			if(frames == null){
				var pngName:String = "character.png";
				var xmlName:String = "character.xml";
				var forced:Int = 0;
				if (charProperties.asset_files != null){
					var invChIDs:Array<Int> = [1,0,2];
					var selAssets = -10;
					for (i => charFile in charProperties.asset_files) {
						if (charFile.char_side != null && charFile.char_side != 3 && charFile.char_side == charType){continue;} // This if statement hurts my brain
						if (charFile.stage != "" && charFile.stage != null){if(PlayState.curStage.toLowerCase() != charFile.stage.toLowerCase()){continue;}} // Check if charFiletion specifies stage, skip if it doesn't match PlayState's stage
						if (charFile.song != "" && charFile.song != null){if(PlayState.SONG.song.toLowerCase() != charFile.song.toLowerCase()){continue;}} // Check if charFiletion specifies song, skip if it doesn't match PlayState's song
						var tagsMatched = 0;
						if (charFile.tags != null && charFile.tags[0] != null && PlayState.stageTags != null){
							for (i in charFile.tags) {if (PlayState.stageTags.contains(i)) tagsMatched++;}
							if (tagsMatched == 0) continue;
						}
						
						if (forced == 0 || tagsMatched == forced) selAssets = i;
					}
					if (selAssets != -10){
						if (charProperties.asset_files[selAssets].png != null )pngName=charProperties.asset_files[selAssets].png;
						if (charProperties.asset_files[selAssets].xml != null )xmlName=charProperties.asset_files[selAssets].xml;
						if (charProperties.asset_files[selAssets].animations != null )charProperties.animations=charProperties.asset_files[selAssets].animations;
						if (charProperties.asset_files[selAssets].animations_offsets != null )charProperties.animations_offsets=charProperties.asset_files[selAssets].animations_offsets;
					}
				}


				if (tex == null){
					var charJsonF:String = ('${charLoc}/$curCharacter/${xmlName}').substr(0,-3) + "json";
					if (SELoader.exists(charJsonF)){
						charXml = SELoader.loadText(charJsonF); 				
						if (charXml == null){throw('$curCharacter is missing their sprite JSON?');} // Boot to main menu if character's XML can't be loaded

						tex = FlxAtlasFrames.fromTexturePackerJson(SELoader.loadGraphic('${charLoc}/$curCharacter/${pngName}'), charXml);
					} else {
						charXml = SELoader.loadXML('${charLoc}/$curCharacter/${xmlName}'); // Loads the XML as a string. 
						if (charXml == null){throw('$curCharacter is missing their XML!');} // Boot to main menu if character's XML can't be loaded
						// if(charXml.substr(2).replace(String.fromCharCode(0),'').contains('UTF-16')){ // Flash CS6 outputs a UTF-16 xml even though no UTF-16 characters are usually used. This reformats the file to be UTF-8 *hopefully*
						// 	charXml = '<?' + charXml.substr(2).replace(String.fromCharCode(0),'').replace('UTF-16','utf-8');
						// }
						tex = SEFlxFrames.fromSparrow(SELoader.loadGraphic('${charLoc}/$curCharacter/${pngName}'), charXml);
					}
					if (tex == null){throw('$curCharacter is missing their XML!');} // Boot to main menu if character's texture can't be loaded
				}
			}
		}
		frames = tex;



		if (charProperties == null) trace('Still no charProperties for $curCharacter?');


		loadJSONChar(charProperties);
		if(charInfo.internal){
			trace('Finished loading hardcoded character: $curCharacter.');
			return;
		}
		// Custom misses
		if (charType == 0 && !amPreview && !debugMode){
			switch(charProperties.custom_misses){
				case 1: // Custom misses using FNF Multi custom sounds
					if(SELoader.exists('${charLoc}/$curCharacter/miss_left.ogg')){
						useMisses = true;
						missSounds = [SELoader.loadSound('${charLoc}/$curCharacter/custom_left.ogg'), SELoader.loadSound('${charLoc}/$curCharacter/custom_down.ogg'), SELoader.loadSound('${charLoc}/$curCharacter/custom_up.ogg'),SELoader.loadSound('${charLoc}/$curCharacter/custom_right.ogg')];
					}
				case 2: // Custom misses using Predefined sound names
					if(SELoader.exists('${charLoc}/$curCharacter/miss_left.ogg')){
						useMisses = true;
						missSounds = [SELoader.loadSound('${charLoc}/$curCharacter/miss_left.ogg'), SELoader.loadSound('${charLoc}/$curCharacter/miss_down.ogg'), SELoader.loadSound('${charLoc}/$curCharacter/miss_up.ogg'),SELoader.loadSound('${charLoc}/$curCharacter/miss_right.ogg')];
					}
			}
		}
		if (SESave.data.playVoices && charProperties.voices == "custom" && SELoader.exists('${charLoc}/$curCharacter/custom_left.ogg')) {
			useVoices = true;
			voiceSounds = [	SELoader.loadFlxSound('${charLoc}/$curCharacter/custom_left.ogg'),
							SELoader.loadFlxSound('${charLoc}/$curCharacter/custom_down.ogg'),
							SELoader.loadFlxSound('${charLoc}/$curCharacter/custom_up.ogg'),
							SELoader.loadFlxSound('${charLoc}/$curCharacter/custom_right.ogg')
							];

		}
		callInterp("initScript",[]);

		trace('Loaded $curCharacter ${charInfo?.getNamespacedName()}');
	}


	public static function newChar(x:Float, y:Float, ?character:String = "", ?isPlayer:Bool = false,?charType:Int = 0,?exitex:FlxAtlasFrames = null,?charJson:CharacterJson = null,?useHscript:Bool = true):Character{
		var e = new Character(x,y,character,isPlayer,charType,exitex,charJson);
		if(PlayState.instance != null && PlayState.instance.songStarted){
			PlayState.instance.showTempmessage("Please load characters before song start to prevent lag during song!",FlxColor.RED);
		}
		e.hscriptGen = true;
		return e;
	}
	var thrownError:Int = 0;
	var loaded:Bool=false;
	public function handleError(error:String,?pos:haxe.PosInfos){
		thrownError++;
		if(thrownError>1){
			trace('$curCharacter Error $thrownError:$error');
			return;
		}
		trace('$curCharacter:$error');
		interp = null;
		// if(!loaded){
		// 	try{
		// 		loaded=true;
		// 		// loadChar("bf");

		// 	}catch(e){}
		// }
		lonely = true;
		color = 0xaa000000;
		// if (!amPreview && PlayState.instance != null){
		// 	PlayState.instance.errorHandle(error);
		// 	// throw error;
		// }else{
		MainMenuState.handleError(error,pos);
		// }
	}

	inline function loadChar(?char:String = ""){
		if(char != "")curCharacter = char;
		loadCustomChar();
	}


	public function new(?x:Float = 0, ?y:Float = 0, ?character:String = "", ?isPlayer:Bool = false,?charType:Int = 0,?preview:Bool = false,?exitex:FlxAtlasFrames = null,?charJson:CharacterJson = null,?useHscript:Bool = true,?charPath:String = "",?charInfo:Null<CharInfo> = null) { // CharTypes: 0=BF 1=Dad 2=GF 
		var part = "super call";
		var CURRENTNAMESPACE = SELoader.namespace;
		#if !debug 
		try{
		#end
		super(x, y);
		if(lonely || character == "lonely") return;
		if(charInfo != null) character = (this.charInfo = charInfo).folderName;
		trace('Loading ${character}');
		animOffsets = ["all" => [0,0] ];
		// animOffsets['all'] = [0.0, 0.0];
		if (character == "") character = (charType == 2 ? "gf" : "bf");
		
		curCharacter = character;
		this.charType = charType;
		this.useHscript = useHscript;
		namespace = onlinemod.OfflinePlayState.nameSpace;

		this.isPlayer = isPlayer;
		amPreview = preview;
		if(charPath != "") charLoc = charPath;


		if(curCharacter == "automatic" || curCharacter == "" || curCharacter == "bfHC" ) curCharacter = "INTERNAL|bf";

		animation = new CharAnimController(this);

		if(charJson != null) charProperties = charJson;
		if(exitex != null) frames = tex = exitex;
		definingColor = (preview ? definingColor : (charType == 1 ? FlxColor.RED : FlxColor.GREEN));
		
		antialiasing = true;
		part = "Loading Character";
		loadChar();
		if(frames == null){throw('$curCharacter is missing frames?');}
		// var alloffset = animOffsets.get("all");

		part = "Fake miss generation";
		for (i in ['RIGHT','UP','LEFT','DOWN']) { // Add main animations over miss if miss isn't present
			var miss = 'sing${i}miss';
			if (animation.getByName(miss) == null){
				cloneAnimation(miss, animation.getByName('sing$i'));
				tintedAnims.push(miss);
			}
		}
		this.y += charY;
		this.x += charX;
		SELoader.namespace = CURRENTNAMESPACE;
		part = "Flipping sing animations";
		if (isPlayer && flip && flipNotes) {
			flipX = !flipX;
			part = "Flipping sing animations flipx";
			if(!(charInfo?.psychChar)){ // Psych Characters don't use the same animation definitions for both sides, SE characters do
				part = "Flipping sing animations normal";

				var oldRight = animation.getByName('singRIGHT')?.frames;
				var oldLeft = animation.getByName('singLEFT')?.frames;
				if(oldRight != null && oldLeft != null){
					animation.getByName('singRIGHT').frames = oldLeft;
					animation.getByName('singLEFT').frames = oldRight;

					// IF THEY HAVE MISS ANIMATIONS??
					part = "Flipping sing animations miss";
					var oldMissRight = animation.getByName('singRIGHTmiss')?.frames;
					var oldMissLeft = animation.getByName('singLEFTmiss')?.frames;
					if (oldMissRight != null && oldMissLeft != null) {
						animation.getByName('singRIGHTmiss').frames = oldMissLeft;
						animation.getByName('singLEFTmiss').frames = oldMissRight;
					}
				}
			}
		}
		part = "Dance";
		dance();
		part = "Calling interpeter New";

		callInterp("new",[]);
		if (animation.curAnim != null) setOffsets(animName); // Ensures that offsets are properly applied
		part = "Animation callbacks";
		animation.finishCallback = function(name:String){
			animHasFinished = true;
			callInterp("animFinish",[animation.curAnim]);
		};
		animation.callback = function(name:String,frameNumber:Int,frameIndex:Int){
			callInterp("animFrame",[animation.curAnim,frameNumber,frameIndex]);
		};

		if(animation.curAnim == null && !lonely && !amPreview){throw('$curCharacter is missing an idle/dance animation!');}
		part = "Finishing up";
		if(animation.getByName('songStart') != null && !lonely && !amPreview) playAnim('songStart',true);
		if(!charProperties.editableSprite){
			// graphic.canBeDumped = true;
			graphic.dump();
		}
		#if !debug
		}catch(e){ 
			SELoader.namespace = CURRENTNAMESPACE;

			trace(e.details());
			return handleError('Error with $curCharacter at $part: ${e.details()}');
		}
		#end
		loaded=true;

	}

	override function update(elapsed:Float) {
		try{

			if(amPreview || debugMode || animation.curAnim == null) return super.update(elapsed);


			if(animation.curAnim.finished || animation.curAnim.curFrame >= animation.curAnim.numFrames) 
				animHasFinished = true;
			if(animHasFinished){
				if(loopAnimTo[animation.curAnim.name] != null) 
					playAnim(loopAnimTo[animation.curAnim.name]);
				else if(animLoops[animation.curAnim.name] == true) {
					playAnim(animation.curAnim.name);
					currentAnimationPriority = -1;
				}
			}
			if (currentAnimationPriority == 11 && isDonePlayingAnim()) {
				// playAnim('idle', true, false, 10);
				dance();
			}
			if(currentAnimationPriority == 10) holdTimer += elapsed;
			else holdTimer = 0;

			if (!isPlayer && holdTimer >= Conductor.stepCrochet * singDuration * 0.001) {
				holdTimer = 0;
				dance();
			}
			callInterp("update",[elapsed]);

			super.update(elapsed);
		}catch(e:Dynamic){handleError('Caught character "update" crash: ${e}');}
	}

	
	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(Forced:Bool = false,beatDouble:Bool = false,useDanced:Bool = true) {
		if (amPreview){
			playAnim((dance_idle || charType == 2 ? 'danceRight' : 'idle'));
			return;
		}
		if(dance_idle){
			if (animation.curAnim != null && !animation.curAnim.name.startsWith("dance") && !animHasFinished) return;
			if (useDanced){
				playAnim('dance${(danced ? 'Right' : 'Left')}',Forced/*,beatProg*/);
				return;
			}
			playAnim('dance${(beatDouble ? 'Right' : 'Left')}',Forced);
			return;
		}
		playAnim('idle'/*,frame*/);
		
	}
	public function getJSONAnimation(name:String = ""):CharJsonAnimation{
		for(anim in charProperties.animations){
			if(anim.anim == name){
				return anim;
				break;
			}
		}
		return null;
	}
	// Added for Animation debug
	public function idleEnd(?ignoreDebug:Bool = false)
	{
		if (debugMode || !ignoreDebug || !dance_idle) return;
		playAnim('danceRight', true, false, animation.getByName('danceRight').numFrames - 1);

	}
	var baseColor = 0xffffff;
	var tintColor = 0x330066;
	public function setOffsets(?AnimName:String = "",?offsetX:Float = 0,?offsetY:Float = 0){
		if (tintedAnims.contains(animation.curAnim.name) && this.color != tintColor){
			baseColor = color;
			color = tintColor;
		}else if(this.color == tintColor) this.color = baseColor;
		
		var x = offsetX;
		var y = offsetY;
		var daOffset = animOffsets.get(AnimName); // Get offsets
		if (daOffset != null){ // Set offsets if animation has any
			x+=daOffset[0];
			y+=daOffset[1];
		}
		x+=animOffsets["all"][0]; // Add "all" offsets
		y+=animOffsets["all"][1];
		offset.set(x, y); // Set offsets
	}
	// function setSprite(?id:Int = 0){
	// 	if(curSprite != id){
	// 		if(spriteArr[id] == null){
	// 			MainMenuState.handleError('$curCharacter: sprite with id $id doesn\'t exist! This should NOT happen!');
	// 		}
	// 		curSprite = id;
	// 		pixels = spriteArr[curSprite].pixels;
	// 		// animation.stop();
	// 		// animation = animArr[id];
	// 		// frames = graphicsArr[id];
	// 	}
	// }
	override function draw(){
		callInterp("draw",[]);
		super.draw();
	} 
	public var currentAnimationPriority:Int = -100;
	public var forceNextAnim:Bool = false;
	public dynamic function playAnim(AnimName:String = "idle", ?Force:Bool = false, ?Reversed:Bool = false, ?Frame:Float = 0,?offsetX:Float = 0,?offsetY:Float = 0):Bool{
		var lastAnim = "";
		if(AnimName.contains('/')){
			return playAnimAvailable(AnimName.split('/'),Force,Reversed,Frame);
		}
		if (PlayState.instance != null) PlayState.instance.callInterp("playAnim",[AnimName,this]);

		if (PlayState.canUseAlts && !amPreview && !debugMode && animation.getByName(AnimName + '-alt') != null) AnimName = AnimName + '-alt'; // Alt animations
		callInterp("playAnim",[AnimName]);
		if (skipNextAnim){
			skipNextAnim = false;
			return false;
		}
		if(nextAnimation != ""){
			AnimName = nextAnimation;
			nextAnimation = "";
		}
		var curAnim = animation.curAnim;
		if (curAnim != null){
			lastAnim = animName;
			if(!forceNextAnim && !isDonePlayingAnim()){
				if(lastAnim == AnimName && replayAnims.contains(AnimName)){
					if(!animLoops[AnimName]) return false;
				}else if(curAnim.name != AnimName){
					if (animationPriorities[curAnim.name] == null ){
						// Skip if current animation has a higher priority
						if(currentAnimationPriority > animationPriorities[AnimName]) return false;
					}else{
						if(oneShotAnims.contains(curAnim.name) && !oneShotAnims.contains(AnimName)) return false;
					}
				}
			} 
		}
		// if (animation.curAnim != null){
		// 	lastAnim = animName;
		// 	if(forceNextAnim){

		// 	}else if(lastAnim == AnimName){
		// 		if(replayAnims.contains(AnimName) && (!animLoops[AnimName] || !isDonePlayingAnim()))return false;
		// 	}else if(!isDonePlayingAnim()){
		// 		if (currentAnimationPriority > animationPriorities[AnimName] || oneShotAnims.contains(animation.curAnim.name) && !oneShotAnims.contains(AnimName) ){return false;} // Skip if current animation has a higher priority or if it's oneshot
		// 	}
		// }
		// setSprite(animGraphics[AnimName.toLowerCase()]);
		var anim = animation.getByName(AnimName);
		if (anim == null) return false;
		if(AnimName == lastAnim && loopAnimFrames[AnimName] != null){
			if(curAnim != null && curAnim.curFrame < loopAnimFrames[AnimName]){
				return false; // Don't loop to frame position unless we've actually gotten past that frame
			}
			Frame = loopAnimFrames[AnimName];
		}
		animHasFinished = false;
		if(Frame > 0 && Frame < 1 && Frame % 1 == Frame){
			Frame = anim.frames.length * Frame;
		}
		callInterp("playAnimBefore",[AnimName]);
		if (!forceNextAnim && skipNextAnim){
			skipNextAnim = false;
			return false;
		}
		forceNextAnim = false;
		cast(animation,CharAnimController).playAnimation(anim, Force, Reversed, Std.int(Frame));
		AnimName = animName;
		currentAnimationPriority = animationPriorities[AnimName] ?? 1;
		if ((debugMode || amPreview) || animation.curAnim != null && AnimName != lastAnim){
			setOffsets(AnimName,offsetX,offsetY);
		} // Skip if already playing, no need to calculate offsets and such

		if (dance_idle && lastAnim != AnimName ){
			switch(AnimName){
				case 'singLEFT', 'singLEFT-alt', 'danceLeft','danceLeft-alt':
					danced = true;
				case 'singRIGHT', 'singRIGHT-alt', 'danceRight', 'danceRight-alt':
					danced = false;
				case 'singUP', 'singDOWN' ,'singUP-alt', 'singDOWN-alt':
					danced = !danced;
			}
		}
		skipNextAnim = false;
		callInterp("playAnimAfter",[AnimName,animation.curAnim]);
		return true;
	}
	public function playAnimAvailable(animList:Array<String>,forced:Bool = false,reversed:Bool = false,frame:Float = 0):Bool{
		for (i in animList) {
			if(animation.getByName(i) != null){
				if(playAnim(i,forced,reversed,frame)) return true;
			}
		}
		return false;
	}
	public function cloneAnimation(name:String,anim:FlxAnimation){
		try{

			if(!amPreview && anim != null){
				animation.add(name,anim.frames,anim.frameRate,anim.flipX);
				if (animOffsets.exists(anim.name)){
					addOffset(name,animOffsets[anim.name][0],animOffsets[anim.name][1],true);
				}
			}
		}catch(e) handleError('Caught character "cloneAnimation" crash: ${e.message}');
	}
	public function addOffset(name:String, x:Float = 0, y:Float = 0,?custom:Bool = false,?replace:Bool = false)
	{
		
		if (needsInverted == 2 && !isPlayer || needsInverted == 3 && isPlayer){
			x=-x;
		}	
		if (animOffsets[name] == null || replace){ // If animation is null, just add the offsets out right
			animOffsets[name] = [x, y];
		}else{ // If animation is not null, add the offsets to the existing ones
			animOffsets[name] = [animOffsets[name][0] + x, animOffsets[name][1] + y];
		}
	}

	// Handles adding animations
	public function addAnimation(anim:String,?prefix:String = "",?indices:Array<Int>,?frameNames:Array<String>,?postFix:String = "",?fps:Int = 24,?loop:Bool = false,?flipx:Bool = false){
		if(amPreview){
			animationList.push({
				anim : anim,
				name : prefix,
				indices : (if (indices != null && indices.length > 0)indices else []),
				fps : fps,
				loop : loop
			});
		}
		animLoops[anim] = loop;
		if (indices != null && indices.length > 0) { // Add using indices if specified
			animation.addByIndices(anim, prefix,indices,postFix, fps,false,flipx);
		}else if (frameNames != null && frameNames.length > 0) { // Add using indices if specified
			animation.addByNames(anim, frameNames, fps,false,flipx);
		}else{
			animation.addByPrefix(anim, prefix, fps, false,flipx);
		}
	}





	// Shortcut functions
	@:keep inline public static function isValidInt(num:Null<Int>,?def:Int = 0) {return if (num == null) def else num;}
	@:keep inline public function isDonePlayingAnim(){return animation.finished || animation.curAnim.finished || animHasFinished || animation.curAnim.curFrame >= numFrames;}
	public function getScriptOption(path:String = ""):Dynamic{
		if(charProperties.scriptOptions == null || charProperties.scriptOptions[path] == null) return null;
		return charProperties.scriptOptions[path];
	}
	function getDefColor(e:CharacterJson,?apply:Bool = true):FlxColor{
		if(customColor || e.color == null) return 0x000000;
		if(Std.isOfType(e.color,String)){
			if(apply) return FlxColor.fromString(e.color);
			definingColor = FlxColor.fromString(e.color);
			customColor = true;
		}else if (Std.isOfType(e.color,Int)){
			if(apply) return FlxColor.fromInt(e.color);
			definingColor = FlxColor.fromInt(e.color);
			customColor = true;
		}else{
			if(e.color[0] != null){
				if(apply) return FlxColor.fromRGB(isValidInt(e.color[0]),isValidInt(e.color[1]),isValidInt(e.color[2],255));
				definingColor = FlxColor.fromRGB(isValidInt(e.color[0]),isValidInt(e.color[1]),isValidInt(e.color[2],255));
				customColor = true;
			}
			else
				if(apply) return 0x000000;
				customColor = false;
		}
		return 0x000000;
	}
	public static function getDefColorFromJson(e:CharacterJson):FlxColor{
		if(e.color == null) return 0x00000000;

		if(Std.isOfType(e.color,String)) return FlxColor.fromString(e.color);
		if(Std.isOfType(e.color,Int))return FlxColor.fromInt(e.color);
		if(e.color[0] != null) return FlxColor.fromRGB(isValidInt(e.color[0]),isValidInt(e.color[1]),isValidInt(e.color[2],255));
		return 0x00000000;
	}


	public var animName(get,set):String; // Shorthand for either playing an animation or grabbing the name
	public function get_animName():Null<String>{ // Instead of erroring due to curAnim being shit, just return null
		return if(animation.curAnim != null && animation.curAnim.name != null) animation.curAnim.name else null;
	}
	public function set_animName(str:String):String{
		playAnim(str,true);
		return animName;
	}


	@:keep inline public function toJson(){
		return Json.stringify({
			type:"Character",
			charType:charType,
			isPlayer:isPlayer,
			name:curCharacter,
			currentAnimation:animation.curAnim,
			hasInterp:interp != null,
			color:definingColor
		});
	}
	public override function toString(){
		return toJson();
	}
	public static function hasCharacter(char:String):Bool{
		return (TitleState.retChar(char) != "");
	}

	public static var BFJSON(default,null):String = CoolUtil.cleanJSON('{
	"embedded": true,
	"path": "characters/BOYFRIEND",
	"animations_offsets": [
		{
			"player1": [300, 267],
			"player2": [0, 0],
			"player3": [0, 0],
			"anim": "attack"
		},
		{
			"player1": [-18, -51],
			"player2": [-24, -52],
			"player3": [0, 0],
			"anim": "singDOWN"
		},
		{
			"player1": [-37, 22],
			"player2": [-34, 20],
			"player3": [0, 0],
			"anim": "singRIGHTmiss"
		},
		{
			"player1": [-41, 26],
			"player2": [4, 29],
			"player3": [0, 0],
			"anim": "singUP"
		},
		{
			"player1": [10, 17],
			"player2": [36, 23],
			"player3": [0, 0],
			"anim": "singLEFTmiss"
		},
		{
			"player1": [-26, -39],
			"player2": [-3, -39],
			"player3": [0, 0],
			"anim": "preattack"
		},
		{
			"player1": [1, 4],
			"player2": [2, 4],
			"player3": [0, 0],
			"anim": "hey"
		},
		{
			"player1": [0, 0],
			"player2": [-1, -1],
			"player3": [0, 0],
			"anim": "idle"
		},
		{
			"player1": [26, 2],
			"player2": [0, 6],
			"player3": [0, 0],
			"anim": "lose"
		},
		{
			"player1": [-18, -21],
			"player2": [-24, -22],
			"player3": [0, 0],
			"anim": "singDOWNmiss"
		},
		{
			"player1": [-43, -6],
			"player2": [-35, -6],
			"player3": [0, 0],
			"anim": "singRIGHT"
		},
		{
			"player1": [-37, 26],
			"player2": [0, 29],
			"player3": [0, 0],
			"anim": "singUPmiss"
		},
		{
			"player1": [10, -9],
			"player2": [42, -5],
			"player3": [0, 0],
			"anim": "singLEFT"
		},
		{
			"player1": [22, 18],
			"player2": [20, 22],
			"player3": [0, 0],
			"anim": "hurt"
		},
		{
			"player1": [0, -18],
			"player2": [20, 22],
			"player3": [0, 0],
			"anim": "hit"
		},
		{
			"player1": [0, 0],
			"player2": [-27, -13],
			"player3": [0, 0],
			"anim": "dodge"
		},
		{
			"player1": [109, 493],
			"player2": [0, 0],
			"player3": [0, 0],
			"anim": "win"
		}
	],
	"no_antialiasing": false,
	"color": [49, 176, 209],
	"sing_duration": 4,
	"cam_pos": [0, 0],
	"char_pos1": [-6, -305],
	"flip_x": true,
	"like": "",
	"genBy": "FNFSE 1.0.0-U31; Animation Debug",
	"char_pos2": [-4, -308],
	"common_stage_offset": [],
	"offset_flip": 1,
	"scale": 1,
	"char_pos": [],
	"cam_pos1": [0, 300],
	"clone": "",

	"cam_pos2" : [
		 135,
		246
	],
	"animations": [
		{
			"loop": false,
			"fps": 24,
			"anim": "idle",
			"indices": [],
			"name": "BF idle dance"
		},
		{
			"loop": false,
			"fps": 24,
			"anim": "singUP",
			"indices": [],
			"name": "BF NOTE UP0"
		},
		{
			"loop": false,
			"fps": 24,
			"anim": "singDOWN",
			"indices": [],
			"name": "BF NOTE DOWN0"
		},
		{
			"loop": false,
			"fps": 24,
			"anim": "singRIGHT",
			"indices": [],
			"name": "BF NOTE LEFT0"
		},
		{
			"loop": false,
			"fps": 24,
			"anim": "singLEFT",
			"indices": [],
			"name": "BF NOTE RIGHT0"
		},
		{
			"loop": false,
			"fps": 24,
			"anim": "singUPmiss",
			"indices": [],
			"name": "BF NOTE UP MISS0"
		},
		{
			"loop": false,
			"fps": 24,
			"anim": "singDOWNmiss",
			"indices": [],
			"name": "BF NOTE DOWN MISS0"
		},
		{
			"loop": false,
			"fps": 24,
			"anim": "singLEFTmiss",
			"indices": [],
			"name": "BF NOTE RIGHT MISS0"
		},
		{
			"loop": false,
			"fps": 24,
			"anim": "singRIGHTmiss",
			"indices": [],
			"name": "BF NOTE LEFT MISS0"
		},
		{
			"loop": false,
			"priority": -1,
			"anim": "hey",
			"fps": 24,
			"loopStart": 0,
			"name": "BF HEY!!",
			"flipx": false,
			"indices": []
		},
		{
			"loop": true,
			"fps": 24,
			"anim": "scared",
			"indices": [],
			"name": "BF idle shaking"
		},
		{
			"loop": false,
			"oneshot": true,
			"fps": 24,
			"anim": "dodge",
			"indices": [],
			"name": "boyfriend dodge"
		},
		{
			"loop": false,
			"oneshot": true,
			"fps": 24,
			"anim": "attack",
			"indices": [],
			"name": "boyfriend attack"
		},
		{
			"loop": false,
			"oneshot": true,
			"fps": 24,
			"anim": "hit",
			"indices": [],
			"name": "BF hit"
		},
		{
			"loop": false,
			"oneshot": true,
			"fps": 24,
			"anim": "preattack",
			"indices": [],
			"name": "bf pre attack"
		},
		{
			"loop": false,
			"oneshot": true,
			"fps": 24,
			"anim": "lose",
			"indices": [],
			"name": "bf dies"
		},
		{
			"loop": false,
			"priority": -1,
			"anim": "hurt",
			"fps": 24,
			"loopStart": 0,
			"name": "BF hit",
			"flipx": false,
			"indices": []
		},
		{
			"loop": false,
			"priority": -1,
			"anim": "win",
			"fps": 18,
			"loopStart": 0,
			"name": "Boyfriend Good Anim",
			"flipx": false,
			"indices": []
		}
	],
	"editableSprite":true
}');
	public static var GFJSON(default,null) = CoolUtil.cleanJSON('{
	"animations_offsets": [
		{
			"player1": [0, 0],
			"player2": [-2, -8],
			"player3": [-2, -17],
			"anim": "scared"
		},
		{
			"player1": [0, 0],
			"player2": [0, 0],
			"player3": [0, -9],
			"anim": "danceRight"
		},
		{
			"player1": [0, 0],
			"player2": [0, -11],
			"player3": [0, -20],
			"anim": "singDOWN"
		},
		{
			"player1": [0, 0],
			"player2": [0, 0],
			"player3": [0, -9],
			"anim": "danceLeft"
		},
		{
			"player1": [0, 0],
			"player2": [0, 13],
			"player3": [0, 4],
			"anim": "singUP"
		},
		{
			"player1": [0, 0],
			"player2": [45, 0],
			"player3": [45, -8],
			"anim": "hairBlow"
		},
		{
			"player1": [0, 0],
			"player2": [0, -11],
			"player3": [0, -20],
			"anim": "singRIGHT"
		},
		{
			"player1": [0, 0],
			"player2": [0, 9],
			"player3": [0, 0],
			"anim": "cheer"
		},
		{
			"player1": [0, 0],
			"player2": [0, 0],
			"player3": [0, -9],
			"anim": "hairFall"
		},
		{
			"player1": [0, 0],
			"player2": [0, -10],
			"player3": [0, -19],
			"anim": "singLEFT"
		},
		{
			"player1": [0, 0],
			"player2": [-2, -12],
			"player3": [0, -18],
			"anim": "sad"
		}
	],
	"dance_idle": true,
	"no_antialiasing": false,
	"cam_pos": [0, 0],
	"sing_duration": 4,
	"flip_x": false,
	"genBy": "FNFBR; Animation Editor",
	"common_stage_offset": [],
	"char_pos3": [0, 30],
	"offset_flip": 1,
	"scale": 1,
	"char_pos": [],
	"animations": [
		{
			"loop": false,
			"anim": "cheer",
			"fps": 24,
			"name": "GF Cheer",
			"indices": []
		},
		{
			"loop": false,
			"anim": "singLEFT",
			"fps": 24,
			"name": "GF left note",
			"indices": []
		},
		{
			"loop": false,
			"anim": "singRIGHT",
			"fps": 24,
			"name": "GF Right Note",
			"indices": []
		},
		{
			"loop": false,
			"anim": "singUP",
			"fps": 24,
			"name": "GF Up Note",
			"indices": []
		},
		{
			"loop": false,
			"anim": "singDOWN",
			"fps": 24,
			"name": "GF Down Note",
			"indices": []
		},
		{
			"loop": false,
			"anim": "sad",
			"fps": 24,
			"name": "gf sad",
			"indices": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
		},
		{
			"loop": false,
			"anim": "danceLeft",
			"fps": 24,
			"name": "GF Dancing Beat",
			"indices": [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
		},
		{
			"loop": false,
			"anim": "danceRight",
			"fps": 24,
			"name": "GF Dancing Beat",
			"indices": [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]
		},
		{
			"loop": false,
			"anim": "hairBlow",
			"fps": 24,
			"name": "GF Dancing Beat Hair blowing",
			"indices": [0, 1, 2, 3]
		},
		{
			"loop": false,
			"anim": "hairFall",
			"fps": 24,
			"name": "GF Dancing Beat Hair Landing",
			"indices": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
		},
		{
			"loop": false,
			"anim": "scared",
			"fps": 24,
			"name": "GF FEAR",
			"indices": []
		}
	],
	"embedded": true,
	"editableSprite":true,
	"path": "characters/GF_assets",
	"color": "#A5004D",
	"cam_pos3": [0, 0]
}');


}
