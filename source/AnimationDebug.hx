package;



 
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxTimer;
import sys.FileSystem;
import sys.io.File;
import openfl.net.FileReference;
import flixel.graphics.frames.FlxAtlasFrames;
import flash.display.BitmapData;



import flixel.graphics.FlxGraphic;
import SEInputText as FlxInputText;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.FlxUIText;
import flixel.addons.ui.FlxUISubState;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import SENumericStepper as FlxUINumericStepper;
import Controls.Control;
import flixel.addons.transition.FlxTransitionableState;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.plugin.screengrab.FlxScreenGrab;
import ImportMod;

import se.utilities.SEUIUtilities;

import CharacterJson;

using StringTools;



// Todo, add buttons to go through animations without needing to use shitty text box

class AnimationDebug extends MusicBeatState
{
	static var INTERNALANIMATIONLIST:Array<String> = ["idle","danceLeft","danceRight","singLEFT","singDOWN","singUP","singRIGHT","singLEFTmiss","singDOWNmiss","singUPmiss","singRIGHTmiss","idle-alt","singLEFT-alt","singDOWN-alt","singUP-alt","singRIGHT-alt","songStart","hey",
	"scared","win","cheer","lose","dodge","hurt","hurtLEFT","hurtRIGHT","hurtUP","hurtDOWN","dodgeLeft","dodgeRight","dodgeUp","dodgeDown"]; // Why is this yelling you ask? Because yes
	public static var instance:AnimationDebug;
	var gf:Character;
	public var chara:Character;
	public var charaBG:Character;
	//var char:Character;
	var textAnim:FlxText;
	var dumbTexts:FlxTypedGroup<FlxText>;
	var animList:Array<String> = [];
	var curAnim:Int = 0;
	var isPlayer:Bool = false;
	var daAnim:String = 'bf';
	var charType:Int = 0;

	var camFollow:FlxObject;
	var pressArray:Array<Bool> = [];
	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;
	var offset:Map<String, Array<Float>> = [];
	var offsetText:Map<String, FlxText> = [];
	var offsetList:Array<String> = [];
	var offsetTextSize:Int = 20;
	var offsetCount:Int = 1;
	var charSel:Bool = false;
	var charX:Float = 0;
	var charY:Float = 0;
	var characterX:Float = 0;
	var characterY:Float = 0;
	var UI:FlxGroup = new FlxGroup();
	// var tempMessage:FlxText;
	// var tempMessTimer:FlxTimer;
	var offsetTopText:FlxText;
	var isAbsoluteOffsets:Bool = false;
	var absPos:Bool = false;
	public static var charJson:CharacterJson;
	public static var inHelp:Bool = false;
	public static var canEditJson:Bool = false;
	public static var reloadChar:Bool = false;
	var animationList:Array<String> = [];
	var xmlAnimList:Array<String> = [];
	var healthBar:FlxBar;
	var iconP1:HealthIcon;

	public var editMode:Int = 0;
	static var showOffsets:Bool = false;
	static var offsetTopTextList:Array<String> = [
	'Current offsets(Relative, These should be added to your existing ones):',
	'Current offsets(Absolute, these replace your existing ones):',
	'Offset Editing Mode(Relative)',
	'Offset Editing Mode(Absolute)',
	'Camera Positioning Mode',
	'Animation Editing Mode'
	];

	var lastMouseY = 0;
	var lastMouseX = 0;
	var lastRMouseY = 0;
	var lastRMouseX = 0;

	var quitHeld:Int = 0;
	var quitHeldBar:FlxBar;
	var quitHeldBG:FlxSprite;
	var animDropDown:PsychDropDown;
	var bf:Character;
	#if mobile
	public static function fileDrop(file:String){
		if(MusicBeatState.instance.onFileDrop(file) == null || !FileSystem.exists(file)){
			return;
		}
		throw("Importing isn't supported on mobile targets yet!");
	}
	#else
	public static function fileDrop(file:String){
		// Normal filesystem/file is used here because we aren't working within the game's folder. We need absolute paths

		#if windows
		file = file.replace("\\","/"); // Windows uses \ at times but we use / around here
		#end
		if(MusicBeatState.instance.onFileDrop(file) == null || !FileSystem.exists(file)){
			return;
		}
		file = FileSystem.absolutePath(file);
		if(FileSystem.isDirectory(file)){
			if(file.substring(-1) != "/") file +="/";
			var name = file.substring(0,file.lastIndexOf("/"));
			FlxG.switchState(new ImportModFromFolder(file + '/',name.substring(name.lastIndexOf('/'))));
			return;
			
		}
		if(file.endsWith(".json")){
			return multi.MultiMenuState.fileDrop(file);
		}
		if(file.endsWith(".osu") || file.endsWith(".osz") ){
			MainMenuState.handleError('osu! beatmap support has been removed\nosu! lazer changed the file structure and-\n it\'s not worth it to maintain support when osu! stable and lazer are far better');
			return;
		}
		if(FlxG.state is PlayState) return;
		var validFile:String = "";
		var ending1 = "";
		var ending2 = "";
		if(file.endsWith(".png") && FileSystem.exists(file.replace(".png",".xml"))){
			validFile = file.replace(".png",".xml");
			ending1 = "png";
			ending2 = "xml";
		}else if(file.endsWith(".xml") && FileSystem.exists(file.replace(".xml",".png"))){
			validFile = file.replace(".xml",".png");
			ending1 = "xml";
			ending2 = "png";
		}
		if(validFile == "")return;
		if(!SESave.data.animDebug) {throw "You need to enable Content Creation Mode to work on characters!";return;}
		var name = file.substring(file.lastIndexOf("/") + 1,file.lastIndexOf("."));
		FlxG.state.openSubState(new QuickNameSubState(function(name:String,file:String,validFile:String,ending1:String,ending2:String){
			var _file = file.substr(file.lastIndexOf("/") + 1);
			var _validFile = validFile.substr(file.lastIndexOf("/") + 1);
			if(SELoader.exists('mods/packs/imported/characters/$name/')){name = '${name}DRAGDROP-${FlxG.random.int(0,999999)}';}
			SELoader.createDirectory('mods/packs/imported/characters/$name');
			SELoader.importFile(file,'mods/packs/imported/characters/$name/character.$ending1');
			SELoader.importFile(validFile,'mods/packs/imported/characters/$name/character.$ending2');
			LoadingScreen.loadAndSwitchState(new AnimationDebug("INVALID|" + name,false,1,false,true));

		},[file,validFile,ending1,ending2],"Type a name for the character\n",name,function(name:String){return (if(TitleState.retChar(name,false) != "") "This character already exists! Please use a different name" else "");}));
	} 

	override public function onFileDrop(file){
		file = FileSystem.absolutePath(file);
		if(file.endsWith(".png")){
			try{
				SELoader.importFile(file,'${chara.loadedFrom.substring(0,chara.loadedFrom.lastIndexOf('/'))}/healthicon.png');
				showTempmessage('Imported health icon!');
			}catch(e){
				trace('Unable to import health icon! ${e.message}');
				showTempmessage('Unable to import health icon! ${e.message}',FlxColor.RED);
				return null;
			}
		}
		return null;
	}
	#end
	public function new(?daAnim:String = 'bf',?isPlayer=false,?charType_:Int=1,?charSel:Bool = false,?dragDrop:Bool = false)
	{
		super();
		dragdrop = dragDrop;
		this.daAnim = daAnim;
		this.isPlayer = isPlayer;
		charType = charType_;
		this.charSel = charSel;
		canEditJson = false;
		instance = this;
		if(SELoader.exists('assets/music/chartEditorLoop.ogg') && SESave.data.animDebugMusic){
			
			if(OptionsMenu.bgMusic != FlxG.sound.music){
				FlxG.sound.playMusic(SELoader.loadSound('assets/music/chartEditorLoop.ogg',true),true);
				FlxG.sound.music.volume = SESave.data.instVol;
			}
			Conductor.changeBPM(137);
		}
		trace('Animation debug with ${daAnim},${if(isPlayer) "true" else "false"},${charType}');

	}
	var dragdrop = false;
	override function beatHit(){
		super.beatHit();
		if(FlxG.keys.pressed.V && editMode != 2){chara.dance(curBeat==2);}
		if(gf != null) gf.dance();
	}
	var health:Int = 2;
	override function create()
	{
		var phase:Int = 0;
		var phases:Array<String> = ["Adding cams","Adding Stage","Adding First UI","super.create","Adding char","Moving character","Adding more UI","Adding healthbar","finished"];

		inline function updateTxt():Int{
			phase++;
			LoadingScreen.loadingText = phases[phase];
			return phase;
		}
		try{
			updateTxt();

			super.create();
			camGame = new FlxCamera();
			camHUD = new FlxCamera();
			camHUD.bgColor.alpha = 0;

			FlxG.mouse.enabled = true;
			FlxG.mouse.visible = true;

			FlxG.cameras.reset(camGame);
			FlxG.cameras.add(camHUD);

			FlxG.cameras.setDefaultDrawTarget(camGame,true);

			// if (!charSel){ // Music should still be playing, no reason to do anything to it
			FlxG.sound.music.looped = true;
			FlxG.sound.music.onComplete = null;
			FlxG.sound.music.play(); // Music go brrr
			// }

			updateTxt();
			var gridBG:FlxSprite = FlxGridOverlay.create(50, 20);
			gridBG.scrollFactor.set();
			gridBG.cameras = [camGame];
			add(gridBG);
			// Emulate playstate's setup
			try{

				var stageFront:FlxSprite = SELoader.loadFlxSprite(-650, 600,'assets/shared/images/stagefront.png');
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				stageFront.antialiasing = false;
				stageFront.scrollFactor.set(0.9, 0.9);
				stageFront.active = false;
				stageFront.cameras = [camGame];
				add(stageFront);

				gf = new Character(400, 100, "INTERNAL|gf",false,2,true);
				gf.scrollFactor.set(0.90, 0.90);
				gf.animation.finishCallback = function(name:String) gf.idleEnd(true);
				gf.dance();
				gf.cameras = [camGame];
				add(gf);

				if (charType == 2){
					gf.alpha = 0.5;
					gf.color = 0xA5004D;
				}else{
					bf = new Character((charType == 1 ? 100 : 790), 100, "INTERNAL|bf",(charType == 0),charType,true);
					bf.scrollFactor.set(0.95, 0.95);
					bf.dance();
					bf.cameras = [camGame];
					bf.alpha = 0.5;
					bf.color = if(charType == 1) 0xaf66ce else 0x31b0d1;
					add(bf);

				}
			}catch(e){
				trace("Hey look, an error:" + e.stack + ";\n\\Message:" + e.message);
			}
			updateTxt();
			offsetTopText = new FlxText(30,20,0,'');
			offsetTopText.setFormat(CoolUtil.font, 24, FlxColor.BLACK, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.WHITE);
			offsetTopText.scrollFactor.set();
			offsetTopText.cameras = [camHUD];
			animDropDown = new PsychDropDown(FlxG.width - 300, 50, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(id:String)
			{
				var anim = animList[Std.parseInt(id)];
				playAnim(anim);
				// animToPlay = anim;
			});

			animDropDown.selectedLabel = '';
			animDropDown.cameras = [camHUD];
			add(animDropDown);
			var animTxt = new FlxText(animDropDown.x, animDropDown.y - 20,0,"Cur Animation");
			offsetTopText.setFormat(CoolUtil.font, 24, FlxColor.BLACK, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.WHITE);
			animTxt.cameras = [camHUD];
			add(animTxt);
			var switchModesButton = new FlxUIButton(20,680,"Switch modes",function(){
				openSubState(new AnimSwitchMode());
			});
			switchModesButton.resize(120,20);
			switchModesButton.cameras = [camHUD];
			add(switchModesButton);
			camFollow = new FlxObject(0, 0, 2, 2);
			camFollow.screenCenter();
			camFollow.setPosition(720, 500); 
			camFollow.cameras = [camGame];
			add(camFollow);


			camGame.follow(camFollow);
			updateTxt();
			spawnChar();
			updateTxt();
			if(chara == null)throw("Player object is null!");
			if(charJson.clone != "" && charJson.clone != null){
				showTempmessage('Older character loaded. Config has been reset!',FlxColor.RED);
				spawnChar(true,true,Json.parse('{
						"flip_x":false,
						"sing_duration":6.1,
						"scale":1,
						"dance_idle":false,
						"voices":"",
						"no_antialiasing":false,
						"animations": [],
						"animations_offsets": [{"anim":"all","player1":[0,0],"player2":[0,0],"player3":[0,0]}]
					}'));

			}

			updateCharPos(0,0,false,false);
			updateTxt();
			



			updateTxt();
			var contText:FlxText = new FlxText(FlxG.width * 0.81,FlxG.height * 0.94,0,'Press H for help');
			contText.setFormat(CoolUtil.font, 24, FlxColor.BLACK, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.WHITE);
			contText.color = FlxColor.BLACK;
			contText.scrollFactor.set();
			contText.cameras = [camHUD];
			// add(contText);

			add(offsetTopText);
			add(contText);

			quitHeldBG = new FlxSprite(0, 10).loadGraphic(SELoader.loadGraphic('assets/shared/images/healthBar.png',true));
			quitHeldBG.screenCenter(X);
			quitHeldBG.scrollFactor.set();
			add(quitHeldBG);


			quitHeldBar = new FlxBar(quitHeldBG.x + 4, quitHeldBG.y + 4, LEFT_TO_RIGHT, Std.int(quitHeldBG.width - 8), Std.int(quitHeldBG.height - 8), this,'quitHeld', 0, 1000);
			quitHeldBar.numDivisions = 1000;
			quitHeldBar.scrollFactor.set();
			quitHeldBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
			quitHeldBar.cameras = quitHeldBG.cameras = [camHUD];
			add(quitHeldBar);
			updateTxt();

			if(dragdrop)showTempmessage('Imported character $daAnim');
		}catch(e) {MainMenuState.handleError('Error occurred, while loading Animation Debug. Current phase:${phases[phase]}; ${e.message}');}
	}
	function spawnChar(?reload:Bool = false,?resetOffsets = true,?charProp:CharacterJson = null){
		try{
			TitleState.checkCharacters();
			reloadChar = false;
			if (reload) {
				// Destroy, otherwise there will be 4 characters
				chara.destroy();
				charaBG.destroy();

				for (i => v in offsetText) {
					v.destroy();
				}
				// Reset offsets
				if (resetOffsets){
					offsetText = [];
					offset = [];
					offsetCount = 1;
					offsetList = [];
					charX = 0;charY = 0;
				}
				animationList = [];
			}
			characterY=100;
			var flipX = isPlayer;
			switch(charType){
				case 0:characterX=790;flipX = true;
				case 1:characterX=100;
				case 2:characterX=400;
				default:characterX=100;
			};
			try{

				chara = new Character(characterX, characterY, daAnim,flipX,charType,true,null,charProp);
			}catch(e){
				throw('Error while loading character $e');
			}
			if(chara == null)throw("Player object is null!");
			// chara.screenCenter();
			chara.debugMode = true;
			chara.cameras = [camGame];

			try{
				charaBG = new Character(characterX, characterY, daAnim,flipX,charType,true,chara.tex,charProp);
			// charaBG.screenCenter();
			}catch(e){
				throw('Error while loading bg character $e');
			}
			charaBG.debugMode = true;
			charaBG.alpha = 0.75;
			charaBG.color = 0xFF000000;
			charaBG.cameras = [camGame];
			charaBG.scrollFactor.set(chara.scrollFactor.x,chara.scrollFactor.y);
			// offsetTopText.text = offsetTopTextList[0];
			toggleOffsetText(showOffsets);
			isAbsoluteOffsets = false;
			absPos = false;

			add(charaBG);
			add(chara);
			if (charType == 2){remove(gf);add(gf);};
			charJson = chara.charProperties;
			animList = [];
			charAnims = ["**Unbind"];
			if (chara.charXml != null){
				if(chara.charXml.trim().substring(0,1) == "{"){ // Probably a sprite atlas
					var obj:flixel.graphics.atlas.TexturePackerAtlas = Json.parse(chara.charXml);
					inline function addAnim(name:String){
						if(name.lastIndexOf('-') != -1 ) name = name.substring(0,name.lastIndexOf('-') - 1);
						else if(name.lastIndexOf('0') != -1)name = name.substring(0,name.lastIndexOf('0') - 1);
						if(!charAnims.contains(name))charAnims.push(name);
					}
					// yes I stole this from flxatlasframes, fight me
					if ((obj.frames is Array)){
						for (frame in Lambda.array(obj.frames)){
							addAnim(frame.filename);
						}
					}else{
						for (frameName in Reflect.fields(obj.frames)){
							addAnim(frameName);
						}
					}
				}else{
					var charAnimsContains:Map<String,Bool> = []; 
					var regTP:EReg = (~/<SubTexture name="([A-z0-9\-_ !?:;\(\)\[\]'\/\{\}+@#$%^&*~`.,\\\|]+)[0-9][0-9][0-9][0-9]"/gm);
					var input:String = chara.charXml;
					while (regTP.match(input)) {
						input=regTP.matchedRight();
						var matched = regTP.matched(1);
						if (charAnimsContains.exists(matched)) continue;
						
						charAnimsContains[matched] = true;
						charAnims.push(matched);
					}
				}
			}
			try{
				canEditJson = (charJson == null || chara.loadedFrom == "");
				if(charJson.animations != null && charJson.animations[0] != null){
					for (i => v in charJson.animations) {animList.push(v.anim);}
					if(charJson.animations_offsets != null) {for (i => v in charJson.animations) {animationList.push(v.name);}}
				}
				animDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(animList, true));
			}catch(e){showTempmessage("Unable to load animation list",FlxColor.RED);}
			
		}catch(e) {MainMenuState.handleError('Error occurred in spawnChar, animdebug ${e.message}');trace(e.message);}
	}



	function moveOffset(?amountX:Float = 0,?amountY:Float = 0,?shiftPress:Bool = false,?ctrlPress:Bool = false,?animName:String = ""){
		try{

			if (shiftPress){amountX=amountX*5;amountY=amountY*5;}
			if (ctrlPress){amountX=amountX*0.1;amountY=amountY*0.1;}
			if (animName == "") animName = chara.animation.curAnim.name;
			if(animName == null){MainMenuState.handleError('Animation name is missing!');}
			if(offset[animName] == null){
				offsetCount += 1;
				offset[animName] = [amountX,amountY];
			}else{
				offset[animName][0] += amountX;
				offset[animName][1] += amountY;
			}
			if (offsetText[animName] == null){
				var text:FlxText = new FlxText(30,30 + (offsetTextSize * offsetCount),0,"");
				text.setFormat(CoolUtil.font, 24, FlxColor.BLACK, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.WHITE);
				text.scrollFactor.set();
				text.visible = showOffsets;
				text.cameras = [camHUD];
				add(text);
				offsetText[animName] = text;
				offsetList.push(animName);
			}
			chara.playAnim(animName, true,false,0,offset[animName][0],offset[animName][1]);
			offsetText[animName].text = '${animName}: [${offset[animName][0]}, ${offset[animName][1]}]';
		}catch(e) MainMenuState.handleError('Error while handling offsets: ${e.message}');
		
	}
	function swapSides(){
		var side = switch (charType) {
			case 0: 1;
			case 2: 1;
			default: 0;
		};
		var e= new AnimationDebug(daAnim,side == 0,side,charSel);
		MusicBeatState.lastClassList.pop();
		FlxG.switchState(e);
	}
	function exit(){
		FlxG.mouse.enabled = false;
		goToLastClass();
		// if (charSel){
		// 	FlxG.switchState(new CharSelection()); 
		// }else if(dragdrop){
		// 	FlxG.switchState(new MainMenuState()); 

		// }
		// else switch(PlayState.stateType){
		// 	case 2: LoadingState.loadAndSwitchState(new onlinemod.OfflinePlayState()); 
		// 	case 4: LoadingState.loadAndSwitchState(new multi.MultiPlayState());
		// 	default: LoadingState.loadAndSwitchState(new PlayState());
		// }
	}

	function outputCharOffsets(){
		var text = (if(isAbsoluteOffsets) "These are absolute, these should replace the offsets in the config.json." else 'These are not absolute, these should be added to the existing offsets in your config.json.')  +
			'\nExported offsets for ${chara.curCharacter}/Player ${charType + 1}:\n' +
			if(charX != 0 || charY != 0) '\ncharPos: [${charX}, ${charY}]' else ""; 
		for (i => v in offset) {
			var name = i;
			text+='\n"${name}" : { "player${charType + 1}": [${v[0]}, ${v[1]}] }';
		}
		SELoader.saveContent("offsets.txt",text);
		showTempmessage("Saved to output.txt successfully");
		FlxG.sound.play(Paths.sound("scrollMenu"), 0.4);

	}
	function outputChar(){
		var errorStage = 0;
		try{
			if(chara.loadedFrom == "") {
				@:privateAccess
				var e = '{
						"animations" : ${Json.stringify(chara.animationList)},
						"flip_x" : false,
						"scale" : ${chara.scale.x},
						"no_antialiasing" : ${!chara.antialiasing},
						"dance_idle" : ${chara.dance_idle},
						"animations_offsets" : [],
						"sing_duration" : ${chara.singDuration}
		
						}';
				trace(e);
				charJson = Json.parse(e);
				chara.loadedFrom = "output.json";
			}
			if(charJson == null) {FlxG.sound.play(Paths.sound('cancelMenu'));showTempmessage("Can't save, Character has no JSON?",FlxColor.RED);return;}
			errorStage = 1; // Offsets
			var animOffsetsJSON:String = "[";
			var animOffsets:Map<String, Map<String,Array<Float>>> = [];
			for (name => v in chara.animOffsets) {
				var x:Float = v[0];
				var y:Float = v[1];
				if (offset.get(name) != null){
					x+=offset[name][0];
					y+=offset[name][1];
				}
				animOffsets[name] = ['player${charType + 1}' =>[x,y]];

			}
			for (i => v in offset){
				if (animOffsets.get(i) == null){
					animOffsets[i] = [ 'player${charType + 1}' => [v[0],v[1]]];
				}
			}
			errorStage = 2; // Offsets
			if (charJson.animations_offsets != null && charJson.animations_offsets[0] != null){
				for (i => v in charJson.animations_offsets){
					var name:String = v.anim;
					if (animOffsets[name] == null){
						animOffsets[name] = new Map();
					}
					if(v.player1 != null && animOffsets[name]["player1"] == null) animOffsets[name]["player1"] = v.player1;
					if(v.player2 != null && animOffsets[name]["player2"] == null) animOffsets[name]["player2"] = v.player2;
					if(v.player3 != null && animOffsets[name]["player3"] == null) animOffsets[name]["player3"] = v.player3;

				}
			}
			errorStage = 3; // Offsets
			charJson.animations_offsets = [];
			for (name => v in animOffsets){
				if(name == "all") {
					chara.x += v['player${charType + 1}'][0];
					chara.y -= v['player${charType + 1}'][1];
					continue;
				}
				if(animOffsets[name]["player1"] == null) animOffsets[name]["player1"] = [0.0,0.0];
				if(animOffsets[name]["player2"] == null) animOffsets[name]["player2"] = [0.0,0.0];
				if(animOffsets[name]["player3"] == null) animOffsets[name]["player3"] = [0.0,0.0];
				charJson.animations_offsets.push({
					"anim" : name,
					"player1" : animOffsets[name]["player1"],
					"player2" : animOffsets[name]["player2"],
					"player3" : animOffsets[name]["player3"]
				});
			}

			errorStage = 4; // metadata

			charJson.char_pos = charJson.common_stage_offset = [];
			charJson.offset_flip = 1;
			charJson.seVersionIdentifier = MainMenuState.versionIdentifier;
			// Compensate for the game moving the character's position

			charJson.cam_pos = [0,0];

			chara.x -= characterX;
			// if(charType == 2){
			// 	chara.y -= 300;
			// }else{
			chara.y -= characterY;
			// }
			chara.y = -chara.y;

			errorStage = 5; // Position
			switch (charType) {
				case 0: {
					charJson.char_pos1 = [chara.x,chara.y];
					charJson.cam_pos1 = [chara.camX,chara.camY];
				};
				case 1: {
					charJson.char_pos2 = [chara.x,chara.y];
					charJson.cam_pos2 = [chara.camX,chara.camY];
				};
				case 2: {
					charJson.char_pos3 = [chara.x,chara.y];
					charJson.cam_pos3 = [chara.camX,chara.camY];
				};
			}
			charJson.genBy = 'FNFSE ${MainMenuState.ver}; Animation Debug';
			errorStage = 6; // Saving
			var backed = false;
			if (SELoader.exists(chara.loadedFrom)) {backed=true;SELoader.copy(chara.loadedFrom,chara.loadedFrom + "-bak.json");}
			SELoader.triggerSave(chara.loadedFrom,Json.stringify(charJson, "fancy"));
			showTempmessage('Saved to ${if (chara.loadedFrom.length > 20) '...' + chara.loadedFrom.substring(-20) else chara.loadedFrom} successfully.' + (if(backed) "Old json was backed up to -bak.json." else ""));
			// FlxG.sound.play(Paths.sound("scrollMenu"), 0.4);
			SELoader.playSound('assets/sounds/scrollMenu.ogg',0.4);
			spawnChar(true);


		}catch(e){FlxG.sound.play(
			Paths.sound('cancelMenu'));
			showTempmessage('Error: ${e.message} Debug Info: ${errorStage}',FlxColor.RED);
			trace('ERROR: ${e.message}');
			return;
		}
	}



	function updateCharPos(?x:Float = 0,?y:Float = 0,?shiftPress:Bool = false,?ctrlPress:Bool = false){
		if (shiftPress){x=x*5;y=y*5;}
		if (ctrlPress){x=x*0.1;y=y*0.1;}
		charX+=x;charY-=y;
		// chara.x += x;
		// chara.y -= y;
		// charaBG.x += x;
		// charaBG.y -= y;
		if(chara.animOffsets['all'] == null) chara.animOffsets['all'] = [0.0,0.0];
		chara.animOffsets['all'][0] -= x;
		chara.animOffsets['all'][1] += y;

		chara.setOffsets(chara.animation.curAnim.name);
		if(charaBG.animOffsets['all'] == null) charaBG.animOffsets['all'] = [0.0,0.0];
		charaBG.animOffsets['all'][0] -= x;
		charaBG.animOffsets['all'][1] += y;
		charaBG.setOffsets(chara.animation.curAnim.name);

		if (offsetText["charPos_internal"] == null){
			offsetCount += 1;
			var text:FlxText = new FlxText(30,30 + (offsetTextSize * offsetCount),0,"");
			text.setFormat(CoolUtil.font, 24, FlxColor.BLACK, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.WHITE);
			// text.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
			text.width = FlxG.width;
			text.scrollFactor.set();
			text.visible = showOffsets;
			text.cameras = [camHUD];
			add(text);
			offsetText["charPos_internal"] = text;
			offsetList.push("charPos_internal");
		}
		offsetText["charPos_internal"].text = 'Character Position: [${charX}, ${charY}]';

	}

	function resetOffsets(){
		chara.animOffsets = ["all" => [0,0]];
		charX = 0;charY = 0;
		chara.offset.set(0,0);
		charaBG.offset.set(0,0);
		absPos = true;
		isAbsoluteOffsets = true;
		offsetTopText.text = offsetTopTextList[1];
	}
	function updateOffsetText(?value:Bool = false){
		showOffsets = value;
		// for (i => v in offsetList) {
		// 	offsetText[v].visible = showOffsets;
		// };
		offsetTopText.visible = true;
		if(chara.animation.curAnim == null){
			offsetTopText.text = 'Per frame offsetting, No animation selected??';
			return;

		}
		var frame = chara.frames.frames[chara.animation.frameIndex];
		if (frame == null){
			offsetTopText.text = 'Per frame offsetting, No frame selected??';
			return;
		}
		offsetTopText.text = 'Per frame offsetting, ${frame.name}, frameX:${frame.offset.x}, frameY:${frame.offset.y}';
	}
	public function toggleOffsetText(?value:Bool = false){
		showOffsets = value;
		for (i => v in offsetList) {
			offsetText[v].visible = showOffsets;
		};
		if(editMode == 0){
			offsetTopText.text = offsetTopTextList[0 + (if(isAbsoluteOffsets) 1 else 0) + (if(showOffsets) 0 else 2 )];
		}else if (offsetTopTextList[3 + editMode] != null){
			offsetTopText.text = offsetTopTextList[3 + editMode];
		}
		if(editMode == 2){
			updateCameraPos(false,chara.getMidpoint().x, chara.getMidpoint().y);
		}else if(editMode == 1){
			updateCameraPos(false,get_chara_X(), get_chara_Y());
		}else{
			updateCameraPos(false,720, 500);
		}
	}
	inline function get_chara_X(){return chara.getMidpoint().x + (if (charType == 0) -100 else if (charType == 2) 0 else 150) + chara.camX;}
	inline function get_chara_Y(){return chara.getMidpoint().y - 100 + chara.camY;}

	function playAnim(?animName:String = ""){
		if (animName == "") animName = animToPlay;
		var localOffsets:Array<Float>=[0,0];
		if(offset[animName] != null) localOffsets = offset[animName];
		chara.playAnim(animName, true, false, 0, localOffsets[0], localOffsets[1]);
		animToPlay = "";
		if(animDropDown != null) animDropDown.selectedLabel = animName;
	}

	function updateCameraPos(?modify:Bool = true,?x:Float=0,?y:Float=0,?shiftPress:Bool = false,?ctrlPress:Bool = false){
		if (modify){
			if (shiftPress){x=x*5;y=y*5;}
			if (ctrlPress){x=x*0.1;y=y*0.1;}
			chara.camX += x;
			chara.camY += y;
			camFollow.setPosition(get_chara_X(), get_chara_Y());
			return;
		}
		camFollow.setPosition(x,y);
	}


	// var editorAnim:Map;

	@:keep inline function findAnimation(Anim:String):Array<Dynamic>{
		var meow:Array<Dynamic> = [];
		for (i => v in charJson.animations) {
			if (v.anim == Anim) {
				meow[0] = i;
				meow[1] = v;
				break;
			}
		}
		return meow;
	}
	function editAnimation(Anim:String,charAnim:CharJsonAnimation,?overide:Bool = true){
		var existingAnim:Array<Dynamic> = findAnimation(Anim);
		// var anim = existingAnim[1];
		var id = existingAnim[0];
		// if (unbind || overide){
		// 	if (anim != null) {
		// 		charJson.animations[id]=charAnim;
		// 		return;
		// 	}
		// 	if (!overide)return;
		// 	// anim = null;
		// }
		// if (anim != null){
		// 	charJson.animations[id]=charAnim;
		// 	// showTempmessage('Replaced existing animation!');
		// 	return;
		// }
		if(id != null){
			if(overide) charJson.animations[id] = charAnim;
			return;



		}
		charJson.animations.push(charAnim);
	}

	
	var _colText:FlxUIText;
	var uiBox:FlxUITabMenu;
	var charAnims:Array<String> = [];
	var animUICurAnim:String = "idle";
	var animUICurName:String = "";
	function playTempAnim(name:String){
		if(uiMap['animFPS'] == null){
			chara.addAnimation("ANIMATIONDEBUG_tempAnim",name,24);
		}else{
			var indices = [];
			if((uiMap['animFinish'].value == 0))
				indices == null;
			else
				for(i in uiMap['animStart'].value...uiMap['animFinish'].value) indices.push(i);
			chara.addAnimation("ANIMATIONDEBUG_tempAnim",name,indices,Std.int(uiMap['animFPS'].value),uiMap['loop'].checked,uiMap['flipanim'].checked);

		}
		chara.playAnim("ANIMATIONDEBUG_tempAnim");
	}
	function updateTempAnim(){
		if(animUICurName != "**Unbind"){
			inline playTempAnim(animUICurName);
		}
	}

	inline function updateColorBox(){
		if(charJson.color != null && charJson.color[0] != null){
			trace(colorFromRGB(charJson.color));
			sampleBox.color = colorFromRGB(charJson.color);
		}else{
			sampleBox.color = chara.definingColor;
		}
	}
	function updateColor(?r:Int = -1,?g:Int=-1,?b:Int=-1){

		if(charJson.color == null || charJson.color[0] == null){
			charJson.color = [255,255,255];
		}
		if(r != -1) charJson.color[0] = r;
		if(g != -1) charJson.color[1] = g;
		if(b != -1) charJson.color[2] = b;
		
		// var colText = uiMap["colorTxt"];
		var col:FlxColor = FlxColor.fromRGB(charJson.color[0],charJson.color[1],charJson.color[2]);
		_colText.color = col;
		_colText.borderColor = (_colText.color.lightness >= 0.4 ? FlxColor.BLACK : FlxColor.WHITE);
		_colText.text = col.toWebString();
	}
	public function setupUI(dest:Bool = false){
		try{

		if (dest){
			// if (animDropDown3 != null) animDropDown3.destroy();
			// if (animDropDown2 != null) animDropDown2.destroy();
			try{

				clearUIMap();
				uiBox.destroy();
				if(sampleBox != null)sampleBox.destroy();
				uiBox = null;
				animDropDown.visible = true;
				// for(i in uiMap){
				// 	try{i.destroy();}catch(){}
				// }
			}catch(e){return;}
			return;
		}

		animDropDown.visible = false;
		uiBox = new FlxUITabMenu(null, [{name:"Animation binder",label:"Animation binder"}], true);
		var UIBOX = uiBox;
		uiBox.cameras = [camHUD];

		uiBox.resize(250, 330);
		uiBox.x = FlxG.width - 275;
		uiBox.y = 80;
		uiBox.scrollFactor.set();
		add(uiBox);
		// var uiBox = new FlxUI(null, UIBOX);
		uiBox.name = "Animation binder";
		uiMap["animSel"] = new FlxInputTextUpdatable(5, 232, 100, 'idle');
		var animDropDown2 = new PsychDropDown(5, 230, FlxUIDropDownMenu.makeStrIdLabelArray(INTERNALANIMATIONLIST, true), function(anim:String)
		{
			uiMap["animSel"].updateText(INTERNALANIMATIONLIST[Std.parseInt(anim)]);
		});
		animDropDown2.header.background.visible = animDropDown2.header.text.visible = false;
		animDropDown2.cameras = [camHUD];
		uiBox.add(animDropDown2);
		uiBox.add(uiMap["animSel"]);
		
		animUICurName = charAnims[0];
		uiMap["animSel"].text = "idle";
		animDropDown2.selectedLabel = animUICurName;
		animDropDown3 = new PsychDropDown(130, 230, FlxUIDropDownMenu.makeStrIdLabelArray(charAnims, true), function(anim:String)
		{
			// trace('Drop3: ${Std.parseInt(anim)}');
			animUICurName = charAnims[Std.parseInt(anim)];
			if(animUICurName.toLowerCase() == "**unbind"){
				if(charAnims[1] != null) animUICurName = charAnims[1];
				chara.alpha = 0.5;
			}else{
				chara.alpha = 1;
			}
			if(animUICurName != "**Unbind") playTempAnim(animUICurName);
			uiMap["animStart"].value = 0;
			uiMap["animFinish"].value = 0;
			// uiMap["animSel"].text = charAnims[Std.parseInt(anim)];
		});
		animDropDown3.selectedLabel = '';animDropDown3.cameras = [camHUD];
		uiBox.add(animDropDown3);

		uiBox.add(new FlxText(5, 210,0,"Internal Name"));

		uiBox.add(new FlxText(140, 210,0,"XML Name"));

		// Togglables 

		var looped = new FlxUICheckBox(10, 30, null, null, "Loop animation");
		looped.checked = false;
		looped.callback = function(){ updateTempAnim();};
		uiMap["loop"] = looped;
		// uiBox.add(looped);
		var restplay = new FlxUICheckBox(10, 50, null, null, "Restart Anim when played");
		restplay.checked = true;
		uiMap["restplay"] = restplay;
		// uiBox.add(uiMap["restplay"] = restplay);
		var flipanim = new FlxUICheckBox(10, 70, null, null, "FlipX");
		flipanim.checked = false;
		uiMap["flipanim"] = flipanim;
		uiMap["flipanim"].callback = function(){ updateTempAnim();};
		// uiBox.add(flipanim);
		// var oneshot = new FlxUICheckBox(30, 40, null, null, "Oneshot/High priority");
		// oneshot.checked = false;
		// uiMap["oneshot"] = oneshot;
		// uiBox.add(oneshot);
		// var prTxt = new FlxText(30, 40,0,"Priority(-1 for def)");
		// uiMap["prtxt"] = prTxt;
		// uiBox.add(prTxt);
		// var priorityText = new FlxUIInputText(150, 40, 20, '-1');
		uiMap["prioritytxt"] = new FlxText(10, 90,0,"Priority(-1 for def)");
		uiMap["priorityText"] = new FlxUINumericStepper(140, 90, 1, -1,-999,999,2);


		uiMap["animtxt"] = new FlxText(10, 110,0,"Animation FPS");
		uiMap["animFPS"] = new FlxUINumericStepper(140, 110, 1, 24);
		uiMap["looptxt"] = new FlxText(10, 130,0,"Loop start frame");
		uiMap["loopStart"] = new FlxUINumericStepper(140, 130, 1, 0,0);
		uiMap["AnimationLengthText"] = new FlxText(10, 130,0,"Animation Start > Finish");
		uiMap["animStart"] = new FlxUINumericStepper(140, 130, 1, 0,0);
		uiMap["animFinish"] = new FlxUINumericStepper(140, 130, 1, 0,0);
		uiMap["animStart"].callback = uiMap["animFinish"].callback = function(_,_) {updateTempAnim();};

		uiMap["animFPS"].callback = function(value,_){ updateTempAnim();};

		uiMap["commitButton"] = new FlxUIButton(20,160,"Add animation",function(){
			try{

				var Anim = uiMap["animSel"].text;
				var indices = [];
				if(uiMap['animFinish'].value != 0) for(i in uiMap['animStart'].value...uiMap['animFinish'].value) indices.push(i);
				trace(indices);
				editAnimation(Anim, (animUICurName.toLowerCase() == "**unbind") ? null : {
					anim: Anim,
					name: animUICurName,
					loop: uiMap["loop"].checked,
					flipx:uiMap["flipanim"].checked,
					noreplaywhencalled:!uiMap["restplay"].checked,
					fps: Std.int(uiMap["animFPS"].value),
					loopStart:Std.int(uiMap["loopStart"].value),
					indices: indices,
					priority:Std.int(uiMap["priorityText"].value)
				});
				
				spawnChar(true,false,charJson);
			}catch(e){
				showTempmessage('Error while adding animation: ${e.message}',FlxColor.RED);
			}
		});
		// uiBox.add(uiMap["commitButton"]);
		var autoDetAnims = new FlxUIButton(160,160,"Autodetect Anims",function(){
			try{
				var count = 0;
				var flipped = uiMap['flip_x_global'].checked || charJson.flip_x;
				var overide = chara.isNew /*|| FlxG.keys.pressed.CONTROL*/;
				for(index => animation in charAnims){
					if(animation == "**Unbind") continue;
					var _animName = "";
					var _type = "";
					var checkAnim = animation.toLowerCase();
					for(anim in ['idle','cheer','songstart','win','hey','dodge','shoot','sing','attack','hit','dance','sad']){
						if(checkAnim.contains(anim)){
							_animName = anim;
							break;
						}
					}
					// if(charJson.flip_x){ // 90% of the time, this is a bf clone. Worst case scenario, the animations can be re-bound
					// 	if(checkAnim.contains('left')) checkAnim.replace('left','right');
					// 	else if(checkAnim.contains('right')) checkAnim.replace('right','left');
					// }
					// for(n in ['left','down','up','right']){
					// 	if(!checkAnim.contains(n)) continue;
					// 	if(_animName == "") _animName = "sing";
					// 	if(flipped){
					// 		_animName += (n=="left" ? "right" :(n=="right" ? "left" : n));
					// 	}else{
					// 		_animName += '${n}';
					// 	}
					// 	break;
						
					// }
					// I promise, this is faster
					if(checkAnim.contains('left')){
						if(_animName == "") _animName = "sing";
						_animName += flipped ? "right" : 'left';
					}else if(checkAnim.contains('right')){
						if(_animName == "") _animName = "sing";
						_animName += flipped ? 'left' : "right";
					}else if(checkAnim.contains('up')){
						if(_animName == "") _animName = "sing";
						_animName += 'up';
					}else if(checkAnim.contains('down')){
						if(_animName == "") _animName = "sing";
						_animName += 'down';
					}

					if(checkAnim.contains('miss'))_animName += 'miss';
					if(checkAnim.contains('alt'))_animName += '-alt';



					if(_animName == "") continue;
					trace('$_animName $checkAnim $animation');
					if(Character.animCaseInsensitive[_animName] != null) _animName = Character.animCaseInsensitive[_animName];
					
					editAnimation(_animName,{
						anim: _animName,
						name: animation,
						loop: uiMap["loop"].checked,
						flipx:uiMap["flipanim"].checked,
						noreplaywhencalled:!uiMap["restplay"].checked,
						fps: Std.int(uiMap["animFPS"].value),
						loopStart:Std.int(uiMap["loopStart"].value),
						indices: [],
						priority:-1
					},overide);
					count++;
					
				}
				// if(FlxG.keys.pressed.CONTROL) showTempmessage('Auto detected and forced $count anims!');
				// else 
					showTempmessage('Auto detected $count anims!');
			}catch(e){
				showTempmessage('Error while adding animation: ${e.message}',FlxColor.RED);
			}
			spawnChar(true,false,charJson);
		});
		uiMap["autoDetAnims"]=autoDetAnims;
		// uiBox.add(uiMap["autoDetAnims"]);
		SEUIUtilities.addSpacedUI(uiBox,{y:30,objects:[
			[uiMap["loop"],uiMap["restplay"]],
			[uiMap["flipanim"]],
			[uiMap["priorityText"],uiMap["prioritytxt"]],
			[uiMap["animFPS"],uiMap["animtxt"]],
			[uiMap["loopStart"],uiMap["looptxt"]],
			[uiMap["animStart"],uiMap["animFinish"],uiMap["AnimationLengthText"]],
			null,
			[uiMap["commitButton"],null,null,null,null,null,autoDetAnims],

		]});

		// ----------------
		// Config editor
		// ----------------


		var uiBox2 = new FlxUITabMenu(null, [{name:"Config Editor",label:"Config Editor"}], true);
		uiBox2.cameras = [camHUD];

		uiBox2.resize(250, 330);
		uiBox2.x = 15;
		uiBox2.y = 80;
		uiBox2.scrollFactor.set();
		add(uiBox2);
		uiMap["uiBox2"] = uiBox2;
		var UIBOX2 = uiBox2;
		// var uiBox2 = new FlxUI(null, UIBOX2);
		uiBox2.name = "Animation binder";

		uiMap['no_antialiasing']=checkBox(10, 30,"No antialiasing","no_antialiasing");
		uiMap['flip_x_global']=checkBox(10, 50,"Flip X","flip_x");
		// var looped = checkBox(30, 80,"Spirit Trail","spirit_trail");
		// uiBox2.add(looped);
		// var looped = checkBox(10, 75,"Invert left/right singing for BF Clone","flip_notes");
		// uiBox2.add(looped);
		// var animTxt = new FlxText(30, 100,0,"Color, R/G/B");

		uiMap["scaletxt"] = new FlxText(10, 100,0,"Scale");
		uiMap["scale"] = new FlxUINumericStepper(140, 100, 0.1, charJson.scale,0,10,2);
		uiMap["scale"].callback = function(value,_){ charJson.scale = value;};

		uiMap["singDurTxt"] = new FlxText(10, 120,0,"Sing Duration");
		uiMap["Sing Duration"] = new FlxUINumericStepper(140, 120, 0.1, charJson.sing_duration,0,10,2);
		uiMap["Sing Duration"].callback = function(value,_){ charJson.sing_duration = value;}


		if(charJson.color != null && !Std.isOfType(charJson.color,Array)){
			var _Col = new FlxColor(0xFFFFFF);
			try{
				var __col = Character.getDefColorFromJson(charJson);
				if(__col != 0x00000000) _Col = __col;
			}catch(e){}
			charJson.color = [_Col.red,_Col.green,_Col.blue];
		}
		if(charJson.color == null || charJson.color[0] == null){
			charJson.color = [255,255,255];
		}
		
		uiMap["hiredtxt"] = new FlxText(10, 160,0,"Health Red");
		uiMap["hired"] = new FlxUINumericStepper(100, 160, 1, charJson.color[0],0,255);
		uiMap["hired"].callback = function(value,_){
			updateColor(value);
		}


		uiMap["higreentxt"] = new FlxText(10, 180,0,"Health Green");
		uiMap["higreen"] = new FlxUINumericStepper(100, 180, 1, charJson.color[1],0,255);
		uiMap["higreen"].callback = function(value,_){
			updateColor(-1,value);
		}


		uiMap["colorTxt"] = _colText = new FlxUIText(160, 180,0,"#FFFFFF",12);
		_colText.borderSize = 2;
		_colText.borderStyle = OUTLINE;
		_colText.borderColor = FlxColor.BLACK;


		uiMap["hibluetxt"] = new FlxText(10, 200,0,"Health blue");
		uiMap["hiblue"] = new FlxUINumericStepper(100, 200, 1, charJson.color[2],0,255);
		uiMap["hiblue"].callback = function(value,_){
			updateColor(-1,-1,value);
		}

		// uiBox2.add(new FlxText(30, 120,0,"Scale:"));
		// uiMap["scale"] = new FlxUINumericStepper(80, 120, 0.1, charJson.scale,0,10,2);
		// uiMap["scale"].callback = function(text,_){
		// 	charJson.scale = value;
		// }
		// uiBox2.add(uiMap["scale"]);

		// uiBox2.add(new FlxText(30, 140,0,"Sing Duration:"));
		// uiMap["Sing Duration"] = new FlxUINumericStepper(90, 140, 0.1, charJson.sing_duration.0,30,2);

		// uiMap["Sing Duration"].callback = function(text,_){
		// 	uiMap["Sing Duration"].text = text;
		// }
		// uiBox2.add(uiMap["Sing Duration"]);

		// TODO, USE STEPPERS INSTEAD
		// uiBox2.add(new FlxText(20, 160,0,"Color"));
		// uiMap["charColor"] = new FlxUIInputText(90, 160, 100, (if(charJson.color != null) '${chara.definingColor.red},${chara.definingColor.green},${chara.definingColor.blue}' else '0,0,0'));
		// uiMap["charColor"].customFilterPattern = ~/(?![0-9,])/gi;
		// uiMap["charColor"].callback = function(text,a){
		// 	// text = text.toUpperCase();
		// 	var rgb = text.split(',');
		// 	if(rgb == null || rgb.length < 3){ // Weird way of doing it but still returns null even if valid for some reason
		// 		if(a == "enter" || a == "focuslost") showTempmessage("Invalid color, valid syntax: \"RRR,GGG,BBB\". 0-255.\n R = Red, G = Green, B = Blue, A = alpha. 0123456789abcdef allowed ",FlxColor.RED,10);
		// 		return;
		// 	}
		// 	rgb[0] = Std.int(rgb[0]);
		// 	rgb[1] = Std.int(rgb[1]);
		// 	rgb[2] = Std.int(rgb[2]);

		// 	var col = colorFromRGB(rgb);
		// 	if('$col' == "null"){ // Weird way of doing it but still returns null even if valid for some reason
		// 		if(a == "enter" || a == "focuslost") showTempmessage("Invalid color, valid syntax: \"RRR,GGG,BBB\". 0-255.\n R = Red, G = Green, B = Blue, A = alpha. 0123456789abcdef allowed ",FlxColor.RED,10);
		// 		return;
		// 	}
		// 	// charJson.color = col;
		// 	if(a == "enter" || a == "focuslost"){
		// 		uiMap["charColor"].text = '${col.red},${col.green},${col.blue}';
		// 	}
		// 	updateColorBox();
		// 	// uiMap["colorSample"].color = col;
		// }
		// uiMap["charColor"].focusLost = function(){
		// 	uiMap["charColor"].callback(uiMap["charColor"].text,"focuslost");
		// }
		// uiBox2.add(uiMap["charColor"]);

		uiMap["colorIcon"] = new FlxUIButton(20,220,"Pull color from screen pixel",function(){
			try{
				if(uiMap["hi1"] == null){
					showTempmessage('No health icon to scan!',FlxColor.RED,10);
					return;
				}
				showTempmessage('Click somewhere on the screen to grab the color from there',null,5);
				colorPickerMode = true;
			}catch(e){
				showTempmessage('Unable to find color! ${e.message}',FlxColor.RED,10);
				trace(e.stack);
			}
		});




		var commitButton = new FlxUIButton(20,240,"Update character to show changes",function(){
			spawnChar(true,false,charJson);
		});
		commitButton.resize(120,30);
		uiBox2.add(commitButton);

		var modeButton = new FlxUIButton(20,280,"Switch Modes",function(){
			openSubState(new AnimSwitchMode());
		});
		modeButton.resize(120,20);
		uiMap["switchModes"] = modeButton;
		SEUIUtilities.addSpacedUI(uiBox2,{y:30,spacingY:2,objects:[
			[uiMap['no_antialiasing'],uiMap['flip_x_global']],
			null,
			[uiMap["scale"],uiMap["scaletxt"]],
			[uiMap["Sing Duration"],uiMap["singDurTxt"]],
			null,
			[uiMap["hired"],uiMap["hiredtxt"]],
			[uiMap["higreen"],uiMap["higreentxt"],null,uiMap["colorTxt"]],
			[uiMap["hiblue"],uiMap["hibluetxt"],uiMap["colorIcon"]],
			[],
			null,
			[commitButton],[modeButton]

		]});

		if(chara.charType == 0){

			var warning = new FlxText(2, 180,0,"Anims might not add correctly when editing as BF.\nIt is recommended to add anims as opponent, save, then swap back to editing BF");
			warning.setFormat(CoolUtil.font, 28, FlxColor.RED, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			warning.scrollFactor.set();
			warning.screenCenter(X);
			warning.y = 50;
			add(uiMap["warning"] = warning);
		}
		try{

			// var healthBarBG = new FlxSprite(0, FlxG.height * 0.9 - SESave.data.guiGap).loadGraphic(Paths.image('healthBar'));
			// if (SESave.data.downscroll)
			// 	healthBarBG.y = 50 + SESave.data.guiGap;
			// healthBarBG.screenCenter(X);
			// healthBarBG.scrollFactor.set();
			// add(healthBarBG);
			// var healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,'health', 0, 2);
			
			// healthBar.scrollFactor.set();
			// healthBar.createColoredFilledBar(chara.definingColor, chara.definingColor);
			// healthBar.updateBar();
			// healthBar.percent = 100;
			var iconP1 = new HealthIcon(chara.charInfo.getNamespacedName(), (charType == 0));
			iconP1.y = (FlxG.height * 0.9) - (iconP1.height / 2);
			
			iconP1.screenCenter(X);
			iconP1.centerOffsets();
			iconP1.updateHitbox();
			iconP1.cameras = [camHUD];
			// healthBarBG.cameras = 
			// healthBar.cameras = 
			// uiMap["healthBar"] = healthBar;
			// uiMap["healthBarBG"] = healthBarBG;
			uiMap["hi1"] = iconP1;
			add(iconP1);
		}catch(e){trace('oh no, the healthbar had an error, what ever will we do ${e.message}');}
		
		updateColor();
		
		}catch(e){MainMenuState.handleError(e,'Error while loading GUI: ${e.message}');}
	}
	static public function colorFromRGB(arr:Array<Dynamic>):FlxColor{
		return FlxColor.fromRGB(arr[0],arr[1],arr[2]);
	}
	var sampleBox:FlxSprite;
	var colorPickerMode = false;
	// static function textBox(x:Float,y:Float,defText:String,name:String,internalName:String):FlxInputTextUpdatable{
	// 	var ret = new FlxUIInputText(30, 100, null, "24");
	// 	ret.checked = Reflect.field(charJson,internalName);
	// 	ret.callback = function(){
	// 		Reflect.setField(charJson,internalName,uiMap[name].checked);
	// 	}
	// 	uiMap[name] = ret;
	// 	var animTxt = new FlxText(140, 130,0,"XML Name");
	// 	return ret;
	// }
	function checkBox(x:Float,y:Float,name:String,internalName:String):FlxUICheckBox{
		var ret = new FlxUICheckBox(x, y, null, null, name);
		ret.checked = Reflect.field(charJson,internalName);
		ret.callback = function(){
			Reflect.setField(charJson,internalName,uiMap[name].checked);
		}
		uiMap[name] = ret;
		return ret;
	}
	// function textBox(x:Float,y:Float,name:String,internalName:String):FlxUICheckBox{
	// 	var ret = new FlxUIInputText(x, y, null, null, name);
	// 	ret.checked = Reflect.field(charJson,internalName);
	// 	ret.callback = function(){
	// 		Reflect.setField(charJson,internalName,uiMap[name].checked);
	// 	}
	// 	uiMap[name] = ret;
	// 	return ret;
	// }
	var animToPlay:String = "";
	var animDropDown3:PsychDropDown;
	var animDropDown2:PsychDropDown;
	// inline function canSwitch():Bool {return uiMap["FPS"] == null || (!uiMap["FPS"].focused && !uiMap["animSel"].focused );} // This is disgusting but whatever




	override function update(elapsed:Float)
	{
		// textAnim.text = chara.animation.curAnim.name;
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		if (quitHeldBar.visible && quitHeld <= 0){
			quitHeldBar.visible = false;
			quitHeldBG.visible = false;
    		}
		if (FlxG.keys.pressed.ESCAPE)
		{
			quitHeld += 5;
			quitHeldBar.visible = true;
			quitHeldBG.visible = true;
			if (quitHeld > 1000) exit(); 
		}else if (quitHeld > 0){
			quitHeld -= 10;
		}
		var shiftPress = FlxG.keys.pressed.SHIFT;
		var ctrlPress = FlxG.keys.pressed.CONTROL;
		var rPress = FlxG.keys.justPressed.R;
		var hPress = FlxG.keys.justPressed.H;
		charaBG.y = chara.y;

		if (hPress && editMode != 2) openSubState(new AnimHelpScreen(canEditJson,editMode));
		if (FlxG.keys.justPressed.M && editMode != 2) openSubState(new AnimSwitchMode());
		switch(editMode){
			case 0:{
				if (rPress && !pressArray.contains(true)) spawnChar(true);
				if (FlxG.keys.justPressed.B) {toggleOffsetText(!showOffsets);}
				if(!FlxG.mouse.overlaps(animDropDown)){
					if(FlxG.mouse.justPressed){
						lastMouseX = Std.int(FlxG.mouse.x);
						lastMouseY = Std.int(FlxG.mouse.y);
					}
					if(FlxG.mouse.justPressedRight){
						lastRMouseX = Std.int(FlxG.mouse.screenX);
						lastRMouseY = Std.int(FlxG.mouse.screenY);
					}

					if(FlxG.mouse.pressedRight && FlxG.mouse.justMoved){

						var mx = Std.int(FlxG.mouse.screenX);
						var my = Std.int(FlxG.mouse.screenY);

						camFollow.x+=lastRMouseX - mx;
						camFollow.y+=lastRMouseY - my;
						lastRMouseX = mx;
						lastRMouseY = my;
					}
					if(FlxG.mouse.pressed && FlxG.mouse.justMoved){
						var mx = Std.int(FlxG.mouse.x);
						var my = Std.int(FlxG.mouse.y);
						if(shiftPress){
							updateCharPos(-(lastMouseX - mx),(lastMouseY - my),false,false);
						}else{
							moveOffset(lastMouseX - mx,lastMouseY - my,false,false);
						}
						lastMouseX = mx;
						lastMouseY = my;

					}
				}

				var modifier = "";
				if (shiftPress) {modifier += "miss";}
				if (ctrlPress) modifier += "-alt";
				if(FlxG.keys.pressed.SEVEN) swapSides();
				// Note animations
				if(FlxG.keys.pressed.W)	animToPlay = 'singUP' + modifier;
				else if(FlxG.keys.pressed.A) animToPlay = 'singLEFT' + modifier;
				else if((!ctrlPress || !shiftPress) && FlxG.keys.pressed.S) animToPlay = 'singDOWN' + modifier;
				else if(FlxG.keys.pressed.D) animToPlay = 'singRIGHT' + modifier;
				// A bit ugly but a lot better for performance
				// Offsets and Character position, shift: pressed else: justPressed
				if(shiftPress){
					// Offset adjustment
					if ((FlxG.keys.pressed.UP) || (FlxG.keys.pressed.LEFT) || (FlxG.keys.pressed.DOWN) || (FlxG.keys.pressed.RIGHT)){
						moveOffset((if((FlxG.keys.pressed.LEFT)) 1 else if(FlxG.keys.pressed.RIGHT) -1 else 0)
						           ,(if((FlxG.keys.pressed.UP)) 1 else if(FlxG.keys.pressed.DOWN) -1 else 0)
						           ,false,ctrlPress);
					}
					// Char position
					if ((FlxG.keys.pressed.I) || (FlxG.keys.pressed.J) || (FlxG.keys.pressed.K) || (FlxG.keys.pressed.L)){
						updateCharPos((if((FlxG.keys.pressed.J)) 1 else if(FlxG.keys.pressed.L) -1 else 0)
						           ,(if((FlxG.keys.pressed.I)) 1 else if(FlxG.keys.pressed.K) -1 else 0)
						           ,false,ctrlPress);
					}
				}else{
					if ((FlxG.keys.justPressed.UP) || (FlxG.keys.justPressed.LEFT) || (FlxG.keys.justPressed.DOWN) || (FlxG.keys.justPressed.RIGHT)){
						moveOffset((if((FlxG.keys.justPressed.LEFT)) 1 else if(FlxG.keys.justPressed.RIGHT) -1 else 0)
						           ,(if((FlxG.keys.justPressed.UP)) 1 else if(FlxG.keys.justPressed.DOWN) -1 else 0)
						           ,false,ctrlPress);
					}
					// Char position
					if ((FlxG.keys.justPressed.I) || (FlxG.keys.justPressed.J) || (FlxG.keys.justPressed.K) || (FlxG.keys.justPressed.L)){
						updateCharPos((if((FlxG.keys.justPressed.J)) 1 else if(FlxG.keys.justPressed.L) -1 else 0)
						           ,(if((FlxG.keys.justPressed.I)) 1 else if(FlxG.keys.justPressed.K) -1 else 0)
						           ,false,ctrlPress);
					}
				}
				if(FlxG.keys.justPressed.ONE){resetOffsets(); updateCameraPos(false,720, 500);}// Unload character offsets
				if(FlxG.keys.justPressed.THREE || ctrlPress && shiftPress && FlxG.keys.justPressed.S){outputChar();} // Saving
				if(FlxG.keys.pressed.V){animToPlay = 'Idle';}
				if(FlxG.keys.pressed.LBRACKET){
					var id:Int = animationList.indexOf(chara.animName);
					if(id == -1){
						animToPlay = animationList[0];
					}else{
						animToPlay = animationList[Std.int(Math.abs((id - 1) % animationList.length))];
					}
				}
				if(FlxG.keys.pressed.RBRACKET){
					var id:Int = animationList.indexOf(chara.animName);
					if(id == -1){
						animToPlay = animationList[0];
					}else{
						animToPlay = animationList[Std.int(Math.abs((id + 1) % animationList.length))];
					}
				}
				// if(FlxG.keys.justPressed.M){editMode = 1; toggleOffsetText(false);} // Switch modes
				// if(FlxG.keys.justPressed.TWO){outputCharOffsets();}
				// if(FlxG.keys.justPressed.FOUR){
				// 				chara.animOffsets['all'] = [0.0,0.0];
				// 				charX = 0;charY = 0;
				// 				updateCharPos(0,0,false,false);
				// 				chara.dance();
				// 				absPos = true;}
				if (animToPlay != "") {
					playAnim();
				}
			}
			case 1:{

				if(FlxG.mouse.justPressed){
					lastRMouseX = Std.int(FlxG.mouse.screenX);
					lastRMouseY = Std.int(FlxG.mouse.screenY);
				}
				if(FlxG.mouse.pressed && FlxG.mouse.justMoved){
					var mx = Std.int(FlxG.mouse.screenX);
					var my = Std.int(FlxG.mouse.screenY);

					updateCameraPos(true,lastRMouseX - mx,lastRMouseY - my,false,false);
					lastRMouseX = mx;
					lastRMouseY = my;
					// offsetTopText.text = "X: " + lastMouseX + ",Y: " + lastMouseY;
				}
				// Camera position
				if(shiftPress){
					if ((FlxG.keys.pressed.UP) || (FlxG.keys.pressed.LEFT) || (FlxG.keys.pressed.DOWN) || (FlxG.keys.pressed.RIGHT)){
						updateCameraPos(true,(if((FlxG.keys.pressed.LEFT)) 1 else if(FlxG.keys.pressed.RIGHT) -1 else 0)
						           ,(if((FlxG.keys.pressed.UP)) 1 else if(FlxG.keys.pressed.DOWN) -1 else 0)
						           ,false,ctrlPress);
					}
				}else{
					if ((FlxG.keys.justPressed.UP) || (FlxG.keys.justPressed.LEFT) || (FlxG.keys.justPressed.DOWN) || (FlxG.keys.justPressed.RIGHT)){
						updateCameraPos(true,(if((FlxG.keys.justPressed.LEFT)) 1 else if(FlxG.keys.justPressed.RIGHT) -1 else 0)
						           ,(if((FlxG.keys.justPressed.UP)) 1 else if(FlxG.keys.justPressed.DOWN) -1 else 0)
						           ,false,ctrlPress);
					}
					
				}
				// if(FlxG.keys.justPressed.M){editMode = 2; setupUI(false); toggleOffsetText(false);} // Switch modes
			}
			case 2:{
				if(FlxG.mouse.justPressedRight){
					lastRMouseX = Std.int(FlxG.mouse.screenX);
					lastRMouseY = Std.int(FlxG.mouse.screenY);
				}

				if(FlxG.mouse.pressedRight && FlxG.mouse.justMoved){

					var mx = Std.int(FlxG.mouse.screenX);
					var my = Std.int(FlxG.mouse.screenY);

					camFollow.x+=lastRMouseX - mx;
					camFollow.y+=lastRMouseY - my;
					lastRMouseX = mx;
					lastRMouseY = my;
				}
				if(colorPickerMode && FlxG.mouse.pressed){
					colorPickerMode = false;
					try{
						var grabbed = FlxScreenGrab.grab(false,true);
						var _Col = FlxColor.fromInt(grabbed.bitmapData.getPixel(FlxG.mouse.screenX,FlxG.mouse.screenY));
						updateColor(_Col.red,_Col.green,_Col.blue);
						uiMap["hired"].value = _Col.red;
						uiMap["higreen"].value = _Col.green;
						uiMap["hiblue"].value = _Col.blue;
					}catch(e){
						showTempmessage('Unable to grab color of that pixel!',FlxColor.RED);
					}
				}
				// if (FlxG.keys.justPressed.M && canSwitch()){
				// 	editMode = 0;
				// 	setupUI(true);
				// 	toggleOffsetText(false);

				// }
			}

			case 3:{
				if (rPress && !pressArray.contains(true)) spawnChar(true);
				if (FlxG.keys.justPressed.B) {toggleOffsetText(!showOffsets);}
				if(FlxG.mouse.justPressed){
					lastMouseX = Std.int(FlxG.mouse.x);
					lastMouseY = Std.int(FlxG.mouse.y);
				}
				if(FlxG.mouse.justPressedRight){
					lastRMouseX = Std.int(FlxG.mouse.screenX);
					lastRMouseY = Std.int(FlxG.mouse.screenY);
				}
				var ox = 0;
				var oy = 0;
				if(FlxG.mouse.pressedRight && FlxG.mouse.justMoved){

					var mx = Std.int(FlxG.mouse.screenX);
					var my = Std.int(FlxG.mouse.screenY);

					camFollow.x+=lastRMouseX - mx;
					camFollow.y+=lastRMouseY - my;
					lastRMouseX = mx;
					lastRMouseY = my;
				}
				if(FlxG.mouse.pressed && FlxG.mouse.justMoved){
					var mx = Std.int(FlxG.mouse.x);
					var my = Std.int(FlxG.mouse.y);
					ox = lastMouseX - mx;
					oy = lastMouseY - my;
					lastMouseX = mx;
					lastMouseY = my;

				}

				var modifier = "";
				if (shiftPress) {modifier += "miss";}
				if (ctrlPress) modifier += "-alt";
				if(FlxG.keys.pressed.SEVEN) swapSides();
				// Note animations
				if(FlxG.keys.pressed.W)	animToPlay = 'singUP' + modifier;
				else if(FlxG.keys.pressed.A) animToPlay = 'singLEFT' + modifier;
				else if((!ctrlPress || !shiftPress) && FlxG.keys.pressed.S) animToPlay = 'singDOWN' + modifier;
				else if(FlxG.keys.pressed.D) animToPlay = 'singRIGHT' + modifier;
				else if(FlxG.keys.pressed.V) animToPlay = 'Idle';
				// A bit ugly but a lot better for performance
				// Offsets and Character position, shift: pressed else: justPressed
				if(shiftPress){
					// Offset adjustment
					if ((FlxG.keys.pressed.UP) || (FlxG.keys.pressed.LEFT) || (FlxG.keys.pressed.DOWN) || (FlxG.keys.pressed.RIGHT)){
						ox += (if((FlxG.keys.pressed.LEFT)) 1 else if(FlxG.keys.pressed.RIGHT) -1 else 0);
						oy += (if((FlxG.keys.pressed.UP)) 1 else if(FlxG.keys.pressed.DOWN) -1 else 0);
					}
				}else{
					if ((FlxG.keys.justPressed.UP) || (FlxG.keys.justPressed.LEFT) || (FlxG.keys.justPressed.DOWN) || (FlxG.keys.justPressed.RIGHT)){
						ox += (if((FlxG.keys.justPressed.LEFT)) 1 else if(FlxG.keys.justPressed.RIGHT) -1 else 0);
						oy += (if((FlxG.keys.justPressed.UP)) 1 else if(FlxG.keys.justPressed.DOWN) -1 else 0);
					}
				}
				var anim = chara.frames.frames[chara.animation.frameIndex];
				if(ox != 0){
					chara.frames.frames[chara.animation.frameIndex].offset.x += ox;
					updateOffsetText(true);
					chara.animation.curAnim.curFrame = chara.animation.curAnim.curFrame;
				}if(oy != 0){
					chara.frames.frames[chara.animation.frameIndex].offset.y += oy;
					updateOffsetText(true);
					chara.animation.curAnim.curFrame = chara.animation.curAnim.curFrame;
				}
				if(FlxG.keys.justPressed.Q){
					var e = (chara.animation.curAnim.curFrame - 1);
					if(e < 0){
						e = chara.animation.curAnim.frames.length - 1;
					}
					chara.animation.curAnim.curFrame = e;
					updateOffsetText(true);

				}
				if(FlxG.keys.justPressed.E){
					chara.animation.curAnim.curFrame = (chara.animation.curAnim.curFrame + 1) % chara.animation.curAnim.frames.length;
					updateOffsetText(true);
				}
				// if(FlxG.keys.justPressed.THREE || ctrlPress && shiftPress && FlxG.keys.justPressed.S){outputChar();} // Saving
				// if(FlxG.keys.justPressed.M){editMode = 1; toggleOffsetText(false);} // Switch modes
				// if(FlxG.keys.justPressed.TWO){outputCharOffsets();}
				// if(FlxG.keys.justPressed.FOUR){
				// 				chara.animOffsets['all'] = [0.0,0.0];
				// 				charX = 0;charY = 0;
				// 				updateCharPos(0,0,false,false);
				// 				chara.dance();
				// 				absPos = true;}
				if (animToPlay != "") {
					playAnim();
					chara.animation.curAnim.pause();
					updateOffsetText(true);
				}
			}
		}
		if (reloadChar) spawnChar(true,false,charJson);

		super.update(elapsed);
	}
	override function draw(){ // Dunno how inefficient this is but it works
		super.draw();

		// if (!inHelp) UI.draw();
	} 
}
class AnimHelpScreen extends FlxUISubState{

	var helpObjs:Array<FlxObject> = [];

	var animDebug:Dynamic;
	var canEditJson:Bool = false;
	var editMode:Int = 0;


	function createHelpUI(){
		AnimationDebug.inHelp = true;
		helpObjs = [];
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.8;
		bg.scrollFactor.set();
		helpObjs.push(bg);
		var exitText:FlxText = new FlxText(FlxG.width * 0.7, FlxG.height * 0.9,0,'Press ESC to close.');
		exitText.setFormat(CoolUtil.font, 28, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		exitText.scrollFactor.set();
		helpObjs.push(exitText);
		var controlsText:FlxText = new FlxText(10,70,0,'Controls:'
		+(switch(editMode) {
			case 0:
				'\n\nWASD - Note anims'
				+'\nV - Idle'
				+'\n *Shift - Miss variant'
				+'\n *Ctrl - Alt Variant'
				+'\nRightClick - Move Camera(Doesn\'t save)'
				+'\nClick - Move Offset'
				+'\n *Shift - Moves character position'
				+'\nIJKL - Move char, Moves per press for accuracy'
				+'\nArrows - Move Offset, Moves per press for accuracy'
				+'\n *Shift - Hold to move'
				+'\n *Ctrl - Move by *0.1'
				+"\n\nUtilities:\n"
				+'\n1 - Unloads all offsets from the game or json file, including character position.\n'
				// +'\n2 - Write offsets to offsets.txt in FNFBR\'s folder for easier copying'
				+(if(canEditJson)'\n3/Ctrl+Shift+S - Save Character' else '\n3/Ctrl+Shift+S - Write character to output.json in Super Engine folder')
				// +'\n4 - Unloads character position from json file.(Useful if the game refuses to save the character\'s pos)\n'	
				+'\n7 - Reloads Animation debug with the character\'s side swapped\n'
				+"\nB - Hide/Show offset text";
			case 1:
				'\n\nArrows - Move camera, Moves per press for accuracy'
				+'\n *Shift - Hold to move'
				+'\n *Ctrl - Move by *0.1'
				+'\n Left Click - Move Camera'
				+'\n\nUtilities:\n';
			case 2:
				'';
			default:
				'This should not happen, please report this!.\nEdit mode:${editMode}';
		})
		+'\nR - Reload character'
		+"\nM - Switch mode"
		+'\n\nC - Open property editor in help screen\nEscape - Close animation debug');
		controlsText.setFormat(CoolUtil.font, 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		controlsText.scrollFactor.set();
		helpObjs.push(controlsText);
		animDebug = AnimationDebug.instance;
		// if(animDebug.canEditJson)createUI();
		if(!canEditJson){

			var importantText:FlxText = new FlxText(10, 48,0,'You cannot save offsets for this character, You have to manually copy them');
			importantText.setFormat(CoolUtil.font, 28, FlxColor.RED, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.WHITE);

			// importantText.color = FlxColor.BLACK;
			importantText.scrollFactor.set();
			helpObjs.push(importantText);
		}

		for (i => v in helpObjs) {
			add(helpObjs[i]);
		}

		// if(AnimationDebug.charJson != null){
		// 	FlxG.mouse.enabled = true;
		// 	var reloadCharacter:FlxUIButton = new FlxUIButton(FlxG.width - 200, 70, "Reload Char", function() {animDebug.spawnChar(true,true);});
		// 	var charSettings:FlxUIButton = new FlxUIButton(FlxG.width - 200, 30, "Char Settings", function() {openSubState(new AnimDebugOptions());}); // Todo, make UI for character settings
		// 	reloadCharacter.resize(100, 30);
		// 	charSettings.resize(100, 30);

		// 	helpObjs.push(reloadCharacter);
		// 	helpObjs.push(charSettings);
		// 	add(reloadCharacter);
		// 	add(charSettings);

		// }

	}

	override public function new(?canEditJson:Bool = false,?mode:Int = 0) {
		this.canEditJson = canEditJson;
		this.editMode = mode;
		super();
	}
	override function create(){
		// helpShown = true;

		createHelpUI();
	}
	override function update(elapsed:Float){
		if (canEditJson && FlxG.keys.justPressed.C)
			openSubState(new AnimDebugOptions());
		if (FlxG.keys.justPressed.ESCAPE)
			closeHelp();
	}
	function clearObjs(){
		for (i => v in helpObjs) {
			helpObjs[i].destroy();
		}
		helpObjs = [];
	}
	function closeHelp(){
		// FlxG.mouse.enabled = false;

		AnimationDebug.inHelp = false;
		close();
	} 
}

typedef AnimSetting={
	var ?max:Float;
	var ?min:Float;
	var ?type:Int; // 0 = bool, 1 = int, 2 = float
	var value:Dynamic;
	var description:String;
	var ?name:String;
}

class AnimSwitchMode extends se.substates.QuickList {
	var animDebug:AnimationDebug;


	override public function new() {
		// AnimationDebug.reloadChar = true;
		super();
		AnimationDebug.instance.setupUI(true);
		AnimationDebug.instance.editMode = 0;
		AnimationDebug.instance.toggleOffsetText(false);
		settings = [
			{name:"Offsetting",value:function(){
				AnimationDebug.instance.editMode = 0;
				AnimationDebug.instance.toggleOffsetText(false);
			},description:"Edit offsets for animations"},
			{name:"Reposition Camera",value:function(){
				AnimationDebug.instance.editMode = 1;
				AnimationDebug.instance.toggleOffsetText(false);
			},description:"Edit the position of the camera"},
			{name:"Animation Binder/Config editor",value:function(){
				AnimationDebug.instance.editMode = 2;
				AnimationDebug.instance.setupUI(false);
				AnimationDebug.instance.toggleOffsetText(false);
			},description:"Setup animations"},
			{name:"Per frame offsetting",value:function(){
				AnimationDebug.instance.editMode = 3;
				AnimationDebug.instance.toggleOffsetText(false);
			},description:"Move character per animation frame to help with fixing broken XML frame positions"},
		];
	}
	override function quit(){
		AnimationDebug.instance.editMode = 0;
		AnimationDebug.instance.toggleOffsetText(false);
		close();
	}
}
class AnimDebugOptions extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var animDebug:AnimationDebug;
	var settings:Map<String,AnimSetting> = [];
	var menuItems:Array<String> = [];
	var curSelected:Int = 0;
	var infotext:FlxText;
	function getSetting(setting:Dynamic,defValue:Dynamic){ // Function to make sure all data passed through is not null
		if (setting == null) return defValue;
		return setting;
	}
	inline function getValue(str:String,defValue:Dynamic){
		return getSetting(Reflect.field(AnimationDebug.charJson,str),defValue);
	}
	function setValue(str:String,value:Dynamic){
		Reflect.setField(AnimationDebug.charJson,str,value);
		settings[str].value = Reflect.field(AnimationDebug.charJson,str);
	}

	function reloadList():Void{
		grpMenuShit.clear();
		

		menuItems = [];
		var i = 0;
		for (name => value in settings)
		{
			menuItems.push(name);
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, '${name}: ${value.value}', true, false,70,false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
			i++;
		}
		changeSelection();
	}


	public function new() {
		AnimationDebug.reloadChar = true;
		settings = [
			"flip_x" => {type:0,value:getValue("flip_x",false),
				description:"Whether to flip the character, useful for BF clones"},
			"scale" => {type:2,value:getValue("scale",1),description:"Scale for the character",min:0.1,max:10},
			"no_antialiasing" => {type:0,value:getValue("no_antialiasing",false),
				description:"Disables smoothing out pixels, Enabled for pixel characters"},
			"flip_notes" => {type:0,value:getValue("flip_notes",true),
				description:"Whether to flip left/right when on the right, true by default"},
			"sing_duration" => {type:2,value:getValue("sing_duration",4),
				description:"How long to play the Character's sing animations for"}
		];
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.0;
		bg.scrollFactor.set();
		add(bg);
		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		var infotexttxt:String = "";
		infotext = new FlxText(5, FlxG.height - 40, FlxG.width - 100, infotexttxt, 16);
		infotext.wordWrap = true;
		infotext.scrollFactor.set();
		infotext.setFormat(CoolUtil.font, 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		var blackBorder = new FlxSprite(-30,FlxG.height - 40).makeGraphic((Std.int(FlxG.width)),Std.int(50),FlxColor.BLACK);
		blackBorder.alpha = 0.5;
		add(blackBorder);
		add(infotext);
		FlxTween.tween(bg, {alpha: 0.7}, 0.4, {ease: FlxEase.quartInOut});
		reloadList();
		changeSelection(0);


		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{

		super.update(elapsed);

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;
		var accepted = controls.ACCEPT;
		var oldOffset:Float = 0;

		if (upP) {
			changeSelection(-1);
		}else if (downP) {
			changeSelection(1);
		}
		
		if (FlxG.keys.pressed.ESCAPE) close(); 

		if (accepted && settings[menuItems[curSelected]].type != 1) changeSetting(curSelected);
		if (leftP || rightP) changeSetting(curSelected,rightP);
	}

	function changeSetting(sel:Int,?dir:Bool = true){
		if (settings[menuItems[sel]].type == 0) setValue(menuItems[sel],settings[menuItems[sel]].value = !settings[menuItems[sel]].value );
		if (settings[menuItems[sel]].type == 1 || settings[menuItems[sel]].type == 2) {
			var val = settings[menuItems[sel]].value;
			var inc:Float = 1;
			if(settings[menuItems[sel]].type == 2 && FlxG.keys.pressed.SHIFT) inc=0.1;
			val += if(dir) inc else -inc;
			if (val > settings[menuItems[sel]].max) val = settings[menuItems[sel]].min; 
			if (val < settings[menuItems[sel]].min) val = settings[menuItems[sel]].max - 1; 
			setValue(menuItems[sel],val);
		}

		grpMenuShit.members[sel].destroy();
		var songText:Alphabet = new Alphabet(0, (70) + 30, '${menuItems[sel]}: ${settings[menuItems[sel]].value}', true, false,70,false);
		songText.isMenuItem = true;
		songText.targetY = 0;
		grpMenuShit.members[sel] = songText;
		// reloadList();
	}

	function changeSelection(?change:Int = 0) {
		curSelected += change;

		if (curSelected < 0) curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length) curSelected = 0;

		for (index => item in grpMenuShit.members) {
			item.targetY = index - curSelected; 

			item.alpha = (item.targetY == 0 ? 1 : 0.6);
		}
		infotext.text = settings[menuItems[curSelected]].description ?? "No description";
	}
}