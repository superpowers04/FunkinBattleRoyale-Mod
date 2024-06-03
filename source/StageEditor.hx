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
import flixel.addons.ui.FlxUISubState;
import flixel.addons.ui.FlxUIInputText;
import Controls.Control;
import flixel.addons.transition.FlxTransitionableState;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.addons.ui.FlxUIDropDownMenu;
import TitleState.StageInfo;

import StageJson;

using StringTools;

typedef StageOutput = {
	var objects:Array<Dynamic<FlxObject>>;
	var bfPos:Array<Float>;
	var dadPos:Array<Float>;
	var gfPos:Array<Float>;
	var tags:Array<String>;
	var ?jsonFile:String;
	var showGF:Bool;
}
typedef Stage = se.objects.Stage;
class StageEditor extends MusicBeatState{
	public static function loadStage(?state:FlxState,json:String):Stage{
		var objects:Dynamic = [];
		var stage = new Stage();
		if(json == ""){
			return stage;
		}
		try{
			var stagePropJson:String = SELoader.getContent(json);
			var stageProperties:StageJSON = cast Json.parse(CoolUtil.cleanJSON(stagePropJson));
			if (stageProperties == null){throw('Attempted to load an empty Stage');} // Boot to main menu if character's JSON can't be loaded
			var stagePath = SELoader.getAsDirectory(json.substr(0,json.lastIndexOf("/") + 1)); 
			// defaultCamZoom = stageProperties.camzoom;
			for (layer in stageProperties.layers) {
				// if(layer.song != null && layer.song != "" && layer.song.toLowerCase() != SONG.song.toLowerCase()){continue;}
				var curLayer:FlxSprite = new FlxSprite(0,0);
				if(layer.animated){
					if (!stagePath.exists('${layer.name}.xml'))throw('$stagePath/${layer.name}.xml is invalid!');
					curLayer.frames = SELoader.loadSparrowFrames('$stagePath/${layer.name}');
					curLayer.animation.addByPrefix(layer.animation_name,layer.animation_name,layer.fps,false);
					curLayer.animation.play(layer.animation_name);
				}else{
					var png:FlxGraphic = SELoader.loadGraphic('$stagePath/${layer.name}.png');
					// if (png == null) MainMenuState.handleError('$stagePath/${layer.name}.png is invalid!');
					curLayer.loadGraphic(png);
				}

				if (layer.centered) curLayer.screenCenter();
				if (layer.flip_x) curLayer.flipX = true;
				curLayer.setGraphicSize(Std.int(curLayer.width * layer.scale));
				curLayer.updateHitbox();
				curLayer.x = layer.pos[0];
				curLayer.y = layer.pos[1];
				curLayer.antialiasing = layer.antialiasing;
				curLayer.alpha = layer.alpha;
				curLayer.active = false;
				curLayer.scrollFactor.set(layer.scroll_factor[0],layer.scroll_factor[1]);
				stage.add(curLayer);
			}
			stage.bfPos = stageProperties.bf_pos;
			stage.dadPos = stageProperties.dad_pos;
			stage.gfPos = stageProperties.gf_pos;
			stage.showGF = !stageProperties.no_gf;
			stage.tags = stageProperties.tags;
			stage.defaultCamZoom = stageProperties.camzoom;
			if(state != null){
				state.add(stage);
			}
		}catch(e){
			// MusicBeatState.instance.showTempmessage('Invalid, broken or empty stage! ${e.message}',FlxColor.RED);
			MainMenuState.handleError('Invalid, broken or empty stage! ${e.message} ${e.details()}');
			return new Stage();
		}
		// stage.objects = objects,
		// stage.bfPos = bfPos,
		// stage.dadPos = dadPos,
		// stage.gfPos = gfPos,
		// stage.tags = stageTags,
		// stage.showGF = showGF,
		return stage;
		// {
		// 	objects:objects,
		// 	bfPos:bfPos,
		// 	dadPos:dadPos,
		// 	gfPos:gfPos,
		// 	tags:stageTags,
		// 	showGF:showGF,
		// }
	}
	// Don't enable this, I'm just too lazy to comment out code
	#if STAGEEDITOR
	var curStage:StageInfo;
	public override function new(stage:String = "stage"){
		curStage = TitleState.findStage(stage);
		super();
	}
	public var objects:Array<Dynamic> = [];
	// public var objectList:Map<String,Int> = [];
	public var objectListArr:Array<String> = [];
	public var bf:Character;
	public function updateObjectList(){
		objectList = [];
		for (i => v in objects){
			objectListArr.push(v.name);
		}
		objectListArr.push("boyfriend");
		objectListArr.push("girlfriend");
		objectListArr.push("opponent");
	}

	public override function create(){

		super.create();

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.mouse.enabled = true;
		FlxG.mouse.visible = true;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);

		FlxCamera.defaultCameras = [camGame];

		// Music should still be playing, no reason to do anything to it
		FlxG.sound.music.looped = true;
		FlxG.sound.music.onComplete = null;
		FlxG.sound.music.play(); // Music go brrr



		var out:StageOutput = loadStage(this,curStage);





	}
	override public function onFileDrop(file):Null<Bool>{

	}

	#end
}