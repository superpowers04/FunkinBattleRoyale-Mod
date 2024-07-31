import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.FlxObject;
import flixel.graphics.FlxGraphic;


import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.ui.Keyboard;
import flixel.FlxSprite;
import flixel.FlxG;
import KadeEngineData;
import flixel.sound.FlxSound;

class GameplayCustomizeState extends PlayState
{


	var background:FlxSprite;
	var curt:FlxSprite;
	var front:FlxSprite;
	// var rating:FlxSprite;
	var posText:FlxText;

	// var rating:FlxSprite;
	public static var objs:Map<String,Map<String,ObjectInfo>> = [
		"songPosBG_" => [
			"songPosBar_" => {
				x:4,y:4
			},
			"songTimeTxt" =>{
				x:90,y:4
			},
			"songName" =>{
				x:6,y:4
			}
		],
		"healthBarBG" => [
			"healthBar" => {
				x:4,y:4
			},
			"iconP1" =>{
				x:0,y:-75
			},
			"iconP2" =>{
				x:0,y:-75
			}
		],
		"kadeEngineWatermark" => [],
		"rating" => []

	];
	var objClicks:Map<FlxSprite,String> = [];
	var rating:FlxSprite;
	public override function create() {
		// SAVDATA = cast SESave.data.playStateObjectLocations;
		PlayState.SONG = {
				song: SickMenuState.musicFileLoc,
				notes: [{
					sectionNotes:[],
					typeOfSection:0,
					changeBPM:false,
					bpm:120,
					lengthInSteps:1000,
					mustHitSection:true,
				},{
					sectionNotes:[],
					typeOfSection:0,
					changeBPM:false,
					bpm:120,
					lengthInSteps:1000,
					mustHitSection:true,
				}],
				bpm: 120,
				needsVoices: false,
				player1: 'bf',
				player2: 'bf',
				gfVersion: 'gf',
				noteStyle: 'normal',
				stage: 'stage',
				speed: 2.0,
				validScore: false,
				difficultyString: "e"
			};
		
		if(SESave.data.noterating){
			rating = new FlxSprite(-1000,-1000);
			rating.loadGraphic(Paths.image("sick"));
			rating.screenCenter();
			
			rating.y -= 50;
			rating.x -= 125;
		
			// rating.acceleration.y = 550;
			// rating.velocity.y -= FlxG.random.int(140, 175);
			// rating.velocity.x -= FlxG.random.int(0, 10);
		}
		super.create();
		FlxG.mouse.enabled = FlxG.mouse.visible = true;
		var text = new FlxText(5, FlxG.height * 90, 0, "Drag around gameplay elements, R to reset, Escape to go back.", 12);
		text.scrollFactor.set();
		text.setFormat(CoolUtil.font, 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.screenCenter(X);
		add(text);

		healthBar.visible = healthBarBG.visible = true;
		practiceMode = false;
		
		rating.cameras = [camHUD];
		add(rating);
		
		posText = new FlxText(0,0,"Mouse pos\n X:N/A,Y:N/A \nObject:\n X:N/A,Y:N/A \n");
		posText.cameras=[camHUD];
		posText.height = 200;
		posText.width = 150;
		posText.setFormat(CoolUtil.font, 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		posText.alignment = CENTER;
		add(posText);

	}
	inline function resetValues(){
		// SESave.data.playStateObjectLocations = new Map<String,ObjectInfo>();
		FlxG.resetState();
	}
	// override function generateSong(?dataPath:String = ""){
	// 	PlayState.SONG.needsVoices = false;
	// 	vocals = new FlxSound();
	// 	FlxG.sound.list.add(vocals);
	// 	SickMenuState.musicHandle();
	// 	if (notes == null) 
	// 		notes = new FlxTypedSpriteGroup<Note>();
	// 	notes.clear();
	// 	// add(notes);
	// 	add(notes);
	// 	Note.lastNoteID = -1;
	// }

	override function startSong(?alrLoaded:Bool = false){
		super.startSong(true);
		FlxG.sound.music.onComplete = null;
		for (i => v in objs) {
			var obj = Reflect.getProperty(this,i);
			if(obj == null){
				trace('${i} is null');
				continue;
			}
			var funni:FlxSprite = new FlxSprite(obj.x - 2,obj.y - 2);
			funni.loadGraphic(FlxGraphic.fromRectangle(obj.width + 4,obj.height + 4,0xffffff));
			// funni.color = 0x99AAFFAA;
			if(obj.cameras != null)funni.cameras = obj.cameras.slice(0);
			objClicks[funni] = i;
			add(funni);
			trace('$i = $funni');
		}
	}
	var isPressed:Bool = false;
	var lastMouseX:Int = 0;
	var lastMouseY:Int = 0;
	var currentObjectName:String = "";
	var currentObject:Dynamic;
	var currentObjectClicker:FlxSprite;
	var SAVDATA:Map<String,ObjectInfo>;
	inline function mouseOverlaps(obj:FlxObject):Bool{
		var pos = obj.getScreenPosition();
		return (
			FlxG.mouse.screenX > pos.x &&
			FlxG.mouse.screenY > pos.y &&
			FlxG.mouse.screenX < pos.x + obj.width &&
			FlxG.mouse.screenY < pos.y + obj.height
		);}

	override function update(elapsed:Float) {
		canPause = false;
		super.update(elapsed);
		// if (FlxG.mouse.overlaps(sick) && FlxG.mouse.pressed)
		// {
		//     sick.x = FlxG.mouse.x - sick.width / 2;
		//     sick.y = FlxG.mouse.y - sick.height;
		// }

		// for (i in playerStrums)
		//     i.y = strumLine.y;
		// for (i in strumLineNotes)
		//     i.y = strumLine.y;

		if(FlxG.mouse.justPressed){
			lastMouseX = Std.int(FlxG.mouse.x);
			lastMouseY = Std.int(FlxG.mouse.y);
			for (hitbox => i in objClicks) {
				if(hitbox != null && mouseOverlaps(hitbox)){
					var object = Reflect.getProperty(this,i);
					
					trace('Funni click on ${i}');
					isPressed = true;
					currentObject = object;
					currentObjectClicker = hitbox;
					currentObjectName = i;
				}
			}
			
		}
		if(isPressed && FlxG.mouse.pressed && FlxG.mouse.justMoved && currentObject != null){
			var mx = Std.int(FlxG.mouse.x);
			var my = Std.int(FlxG.mouse.y);
			currentObject.x -= (lastMouseX - mx);
			currentObject.y -= (lastMouseY - my);
			currentObjectClicker.x = currentObject.x - 2;
			currentObjectClicker.y = currentObject.y - 2;
			if(SAVDATA[currentObjectName] == null){
				SAVDATA[currentObjectName] = {
					x:currentObject.x,
					y:currentObject.y
				};
			}else{
				SAVDATA[currentObjectName].x = currentObject.x;
				SAVDATA[currentObjectName].y = currentObject.y;

			}
			var objCount = 0;
			for (i => v in objs[currentObjectName]) {
				var object = Reflect.getProperty(this,i);
				if(object != null){
					object.x = currentObject.x + v.x;
					object.y = currentObject.y + v.y;
				}
				objCount++;
			}
			lastMouseX = mx;
			lastMouseY = my;
			posText.text = 'Mouse\n X:${mx},Y:${my}\n${currentObjectName}\n X:${currentObject.x},Y:${currentObject.y}\n Has ${objCount} subobjects \n';
		}
		if(!FlxG.mouse.pressed){
			isPressed = false;
			if(FlxG.mouse.justMoved) posText.text = 'Mouse\n X:${FlxG.mouse.x},Y:${FlxG.mouse.y}\n';
		}

		posText.screenCenter();
		// if (FlxG.mouse.overlaps(sick) && FlxG.mouse.justReleased)
		// {
		//     SESave.data.changedHitX = sick.x;
		//     SESave.data.changedHitY = sick.y;
		//     SESave.data.changedHit = true;
		// }

		if (FlxG.keys.justPressed.R)
		{
			resetValues();
		}

		if (controls.BACK)
		{
			FlxG.mouse.enabled = false;
			// SESave.data.playStateObjectLocations = cast SAVDATA;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(new OptionsMenu());
		}

	}
	override function testanimdebug(){};


	// ripped from play state cuz im lazy
}