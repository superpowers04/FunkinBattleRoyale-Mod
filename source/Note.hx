package;

import flixel.addons.effects.FlxSkewedSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import tjson.Json;
import flixel.math.FlxPoint;
import sys.io.File;
import sys.FileSystem;
import flash.display.BitmapData;
import NoteAssets;
import PlayState;

using StringTools; 



class Note extends FlxSprite
{
	public var strumTime:Float = 0;
	public var noteID:Int = 0;
	public static var lastNoteID:Int = 0;
	// public var skipXAdjust:Bool = false;
	public var skipXAdjust(get,set):Bool;
	public var updateX:Bool = true;
	public function get_skipXAdjust(){return !updateX;}
	public function set_skipXAdjust(vari){return updateX = !vari;}
	public var updateY:Bool = true;
	public var updateAlpha:Bool = true;
	public var updateAngle:Bool = true;
	public var updateScrollFactor:Bool = true;
	public var updateCam:Bool = true;
	public var clipSustain:Bool = true;
	public var lockToStrum:Bool = true;

	public var hitDistance:Float = 0;
	public var char:Dynamic = null; // plays note anim on this character if specified
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var shouldntBeHit:Bool = false;
	public var isPressed:Bool = false;
	// public var playerNote:Bool = false;
	public var type:Dynamic = 0; // Used for scriptable arrows 

	public var isSustainNoteEnd:Bool = false;
	public var parentNoteWidth:Float = 0;

	public var noteScore:Float = 1;
	public var inCharter:Bool = false;

	public static var swagWidth:Float = 112;
	public static var noteNames:Array<String> = ["purple","blue","green",'red'];
	public var skipNote:Bool = false;
	public var childNotes:Array<Note> = [];
	public var parentNote:Note = null;
	public var parentSprite:FlxSprite = null;
	public var distanceToSprite:Float = 0; // This is inverted because i am dumb and stupid and dumb
	public var showNote = true;
	public var info:Array<Dynamic> = [];
	public var rawNote:Array<Dynamic> = [];
	
	// public var kill:Bool = false; 
	public var rating:String = "shit";
	public var eventNote:Bool = false;
	public var aiShouldPress:Bool = true;
	public var ntText:FlxText;
	public var vanillaFrames:Bool = false;
	public var noteAnimation:Null<String> = "";
	public var noteAnimationMiss:Null<String> = "";
	// public var frames(set,get):FlxFramesCollection;
	// public var _Frames:FlxFramesCollection;


	public function toJson(){
		return Json.stringify({
			type:"Note",
			strumTime:strumTime,
			noteData:noteData,
			noteType:type,
			mustPress:mustPress
		});
	}
	public override function toString(){
		return Std.string({
			type:"Note",
			strumTime:strumTime,
			noteData:noteData,
			noteType:type,
			mustPress:mustPress
		});
	}
	public var noteJSON:NoteAssetConfig;
	// public var multikeyNoteNames:Array<Array<String>> = [
	// 	['white'],
	// 	['purple','red'],
	// 	['purple','white','red'],
	// 	['purple','aqua','green','red'],
	// 	['purple','aqua','white','green','red'],
	// 	['purple','aqua','red','yellow','green','orange'],
	// 	['purple','aqua','red','white','yellow','green','orange'],
	// 	['purple','aqua','green','red','yellow','pink','blue','orange'],
	// 	['purple','aqua','green','red','white','yellow','pink','blue','orange'],
	// 	['purple','aqua','green','red','cyan','magenta','yellow','pink','blue','orange'],
	// 	['purple','aqua','green','red','cyan','white','magenta','yellow','pink','blue','orange'],
	// 	['purple','aqua','green','red','lime','cyan','magenta','tango','yellow','pink','blue','orange'],
	// 	['purple','aqua','green','red','lime','cyan','white','magenta','tango','yellow','pink','blue','orange'],
	// 	['purple','aqua','green','red','lime','cyan','tango','canary','magenta','tango','yellow','pink','blue','orange'],
	// 	['purple','aqua','green','red','lime','cyan','tango','wintergreen','canary','magenta','tango','yellow','pink','blue','orange'],
	// 	['purple','aqua','green','red','lime','cyan','magenta','tango','canary','scarlet','violet','erin','yellow','pink','blue','orange'],
	// 	['purple','aqua','green','red','lime','cyan','magenta','tango','wintergreen','canary','scarlet','violet','erin','yellow','pink','blue','orange'],
	// 	['purple','aqua','green','red','lime','cyan','magenta','tango','white','wintergreen','canary','scarlet','violet','erin','yellow','pink','blue','orange'],
	// 	['purple','aqua','green','red','lime','cyan','magenta','tango','lime','cyan','wintergreen','violet','erin','canary','scarlet','violet','erin','yellow','pink','blue','orange'],
	// ];
	public function addAnimations(){
		if(noteJSON != null){
			animation.addByPrefix('scroll', noteJSON.animname);
			animation.addByPrefix('hold', noteJSON.holdanimname);
			animation.addByPrefix('holdend', noteJSON.endanimname);
			if(noteData == 0){
				animation.addByPrefix('holdend', 'pruple end hold'); // WHY
			}
		}else{
			animation.addByPrefix('greenScroll', 'green0');
			animation.addByPrefix('redScroll', 'red0');
			animation.addByPrefix('blueScroll', 'blue0');
			animation.addByPrefix('purpleScroll', 'purple0');


			animation.addByPrefix('purpleholdend', 'pruple end hold'); // Fucking default names
			animation.addByPrefix('purpleholdend', 'purple end hold');
			animation.addByPrefix('greenholdend', 'green hold end');
			animation.addByPrefix('redholdend', 'red hold end');
			animation.addByPrefix('blueholdend', 'blue hold end');

			animation.addByPrefix('purplehold', 'purple hold piece');
			animation.addByPrefix('greenhold', 'green hold piece');
			animation.addByPrefix('redhold', 'red hold piece');
			animation.addByPrefix('bluehold', 'blue hold piece');
		}
	}
	public function changeSprite(?name:String = "default",?_frames:FlxAtlasFrames,?_anim:String = "",?setFrames:Bool = true,path_:String = "mods/noteassets",?noteJSON:NoteAssetConfig){
		try{
			var curAnim = (_anim == "" && animation.curAnim != null) ? animation.curAnim.name : ((_anim != "") ? _anim : "");
			var _sx:Float = scale.x;
			var _sy:Float = scale.y;
			var _ox:Float = offset.x;
			this.noteJSON = noteJSON;
			if(setFrames && (_frames != null || name != "")){
				if(_frames == null){
					if(name == "skin"){
						frames = FlxAtlasFrames.fromSparrow(NoteAssets.image,NoteAssets.xml);
						try{
							noteJSON = NoteAssets.noteJSON.notes[noteData];
						}catch(e){
							noteJSON = null;
						}
					}else if (name == 'default' || (!SELoader.exists('${path_}/${name}.png') || !SELoader.exists('${path_}/${name}.xml'))){
						frames = SELoader.loadSparrowFrames('assets/shared/images/NOTE_assets');
						// FlxAtlasFrames.fromSparrow(FlxGraphic.fromBitmapData(BitmapData.fromFile('assets/shared/images/NOTE_assets.png')),File.getContent("assets/shared/images/NOTE_assets.xml"));
					}else{
						frames = SELoader.loadSparrowFrames('${path_}/${name}');
						
						if(SELoader.exists('${path}/${name}.json')){
							try{
								this.noteJSON = cast Json.parse(SELoader.loadText('${path}/${name}.json')).notes[noteData];
							}catch(e){
								this.noteJSON = null;
							}
						}
					}
				}else{
					frames = _frames;
				}
			}
			frames = frames.addBorder(new FlxPoint(1,1));
			setGraphicSize(Std.int(width * 0.7));
			antialiasing = true;
			updateHitbox();
			addAnimations();
			animation.play(curAnim);
			centerOffsets();
			scale.x = _sx;scale.y = _sy;
			offset.x = frameWidth * 0.5;
		}catch(e){MainMenuState.handleError(e,'Error while changing sprite for arrow:\n ${e.message}');
		}
	}
	public function loadFrames(){
		if(eventNote && !inCharter) return;
		if (frames == null){
			try{
				if (shouldntBeHit && SESave.data.useBadArrowTex) {frames = FlxAtlasFrames.fromSparrow(NoteAssets.badImage,NoteAssets.badXml);}
			}catch(e){}
			try{
				if(frames == null && shouldntBeHit) {color = 0x220011;}
				if (frames == null) frames = NoteAssets.frames;
				vanillaFrames = true;
				try{
					noteJSON = NoteAssets.noteJSON.notes[noteData];
				}catch(e){
					noteJSON = null;
				}
				
			}catch(e) {
				try{
					TitleState.loadNoteAssets(true);
					if(shouldntBeHit) {color = 0x220011;}
					frames = NoteAssets.frames;
					vanillaFrames = true;
					try{
						noteJSON = NoteAssets.noteJSON.notes[noteData];
					}catch(e){
						noteJSON = null;
					}
				}catch(e){MainMenuState.handleError(e,"Unable to load note assets, please restart your game!");}
			}
		}
		if((eventNote || rawNote[1] == -1 || rawNote[2] == "eventNote") && inCharter){
			color = 0xFFFFFFFF;
			frames = Paths.getSparrowAtlas("EVENTNOTE");
		}
		addAnimations();

	}
	dynamic public function hit(?charID:Int = 0,note:Note){
		switch (charID) {
			case 0:PlayState.instance.BFStrumPlayAnim(noteData);
			case 1:if (SESave.data.cpuStrums) {PlayState.instance.DadStrumPlayAnim(noteData);}
		}; // Strums
		if(noteAnimation != null){
			var anim = (if(noteAnimation == "") getNoteAnim(noteData) else noteAnimation);
			var char = (if(char == null)PlayState.getCharFromID(charID,true) else char);
			if(!isSustainNote && char.animName == anim){
				char.animation.play('idle',true);
			}
			char.playAnim(anim,true); // Play animation
		}
	}
	dynamic public function susHit(?charID:Int = 0,note:Note){ // Played every update instead of every time the strumnote is hit
		switch (charID) {
			case 0:PlayState.instance.BFStrumPlayAnim(noteData);
			case 1:if (SESave.data.cpuStrums) {PlayState.instance.DadStrumPlayAnim(noteData);}
		}; // Strums
		if(noteAnimation != null){
			(if(char == null) PlayState.getCharFromID(charID,true) else char).playAnim((if(noteAnimation == "") getNoteAnim(noteData) else noteAnimation),true); // Play animation
		}
	}
	@:keep inline function getNoteAnim(noteData){return (if (noteAnims[noteData] == null) _noteAnimsBackup[noteData % 4] else noteAnims[noteData]);}

	dynamic public function miss(?charID:Int = 0,?note:Null<Note> = null){
		if(noteAnimationMiss != null){
			(if(char == null) PlayState.getCharFromID(charID,true) else char).playAnim((if(noteAnimationMiss == "") getNoteAnim(noteData) + "miss" else noteAnimationMiss),true); // Play animation
		}
	}
	// Array of animations, to be used above

	static var _noteAnimsBackup(default,null):Array<String> = ['singLEFT','singDOWN','singUP','singRIGHT']; 
	public static var noteAnims:Array<String> = ['singLEFT','singDOWN','singUP','singRIGHT']; 
	public static var noteDirections:Array<String> = ['LEFT','DOWN','UP','RIGHT','NONE']; 

	public var killNote = false;


	@:keep inline function callInterp(func:String,?args:Array<Dynamic>){
		if(PlayState.instance != null) return PlayState.instance.callInterp(func,args);
		if(ScriptMusicBeatState.instance != null) ScriptMusicBeatState.instance.callInterp(func,args);
	}
	@:keep inline function getKeyCount():Int{
		if(PlayState.instance != null && PlayState.SONG != null) return PlayState.SONG.keyCount;
		return noteAnims.length;
	}

	public function new(?strumTime:Float = 0, ?_noteData:Int = 0, ?prevNote:Note, ?sustainNote:Bool = false, ?_inCharter:Bool = false,?_type:Dynamic = 0,?_rawNote:Array<Dynamic> = null,?playerNote:Bool = false)
	{try{
		super();
		
		if (prevNote == null) prevNote = this;
		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		mustPress = playerNote; 
		type = _type;
		x = y = 300;
		this.inCharter = _inCharter;
		this.rawNote = (if(_rawNote == null) [strumTime,_noteData,0] else _rawNote);




		if(Std.isOfType(_type,String)) _type = _type.toLowerCase();
		callInterp("noteCheckType",[this,rawNote]);


		this.noteData = _noteData % getKeyCount(); 

		shouldntBeHit = (isSustainNote && prevNote.shouldntBeHit);
		if(_type == 1 || _type == "hurtnote" || _type == "hurt note" || _type == "hurt" || _type == true){
			shouldntBeHit=true;
			if(!mustPress) noteAnimation=null;
		}
		if(inCharter){
			this.strumTime = strumTime;
			showNote = true;
			if((rawNote[1] < 0 || rawNote[2] == "eventNote")){
				type =rawNote[2];
				// eventNote = true; // Just an identifier
				EventNote.applyEvent(this);
				
			}
		}else{
			this.strumTime = Math.round(strumTime);

			showNote = !(!playerNote && !SESave.data.oppStrumLine);
			if((rawNote[1] < 0 || rawNote[2] == "eventNote")){ // Psych event notes, These should not be shown, and should not appear on the player's side
				
				shouldntBeHit = false; // Make sure it doesn't become a hurt note
				showNote = false; // Don't show the note
				this.noteData = 1; // Set it to 0, to prevent issues
				mustPress = false; // The player CANNOT recieve this note
				eventNote = true; // Just an identifier
				aiShouldPress = true;
				type =rawNote[2];
				// _update = function(elapsed:Float){if (strumTime <= Conductor.songPosition) wasGoodHit = true;};
				frames = null;
				EventNote.applyEvent(this);
			}
		}
		if(rawNote[3] != null && Std.isOfType(rawNote[3],String)){
			switch (Std.string(rawNote[3]).toLowerCase()) {
				case "play animation" | "playanimation" | "animation" | "anim": {
					noteAnimation = rawNote[4];
				}
				case "alt" | "altanim" | "alt animation" | "altanimation": {
					noteAnimation = getNoteAnim(noteData) + "-alt";
				}
				case "noanimation" | "no animation" | "noanim": {
					noteAnimation = null;
				}
			}
		}
			
			
		y = 1300; // Prevents the note from being seen when it first gets added to PlayState.notes 

		if (this.strumTime < 0 && !eventNote) this.strumTime = 0;
		if(shouldntBeHit && PlayState.SONG != null && PlayState.SONG.inverthurtnotes) mustPress=!mustPress;

		callInterp("noteCreate",[this,rawNote]); 
		if(killNote){return;}

		if(!eventNote){
			lastNoteID++;
			noteID = lastNoteID;
			//defaults if no noteStyle was found in chart
			loadFrames();

			setGraphicSize(Std.int(width * 0.7));
			updateHitbox();
			antialiasing = true;
			var noteName = noteNames[noteData % noteNames.length]; // TODO Add support for multikey note assets
			if(eventNote || noteName == null || noteName == "") noteName = noteNames[0];
			

			if (isSustainNote && prevNote != null){
				noteScore * 0.2;
				alpha = 0.6;

				animation.play(noteJSON == null ? noteName + "holdend" : "holdend");
				isSustainNoteEnd = true;
				updateHitbox();
				


				parentNoteWidth = prevNote.width;

				if (prevNote.isSustainNote){
					parentNoteWidth = prevNote.parentNoteWidth;
					var _offset:Float = prevNote.offset.x;
					prevNote.animation.play(prevNote.noteJSON == null ? noteName + "hold" : "hold");
					if (prevNote.parentNote != null){
						prevNote.parentNote.childNotes.push(this);
						this.parentNote = prevNote.parentNote;
					}else{
						prevNote.childNotes.push(this);
						this.parentNote = prevNote;
					}
					prevNote.isSustainNoteEnd = false;
					prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * (SESave.data.scrollSpeed != 1 ? SESave.data.scrollSpeed : PlayState.SONG.speed);
					prevNote.updateHitbox();
					prevNote.offset.x = _offset;

					// prevNote.offset.x = prevNote.frameWidth * 0.5;
					// prevNote.setGraphicSize();
				}
			}else{
				animation.play(if(noteJSON == null) noteName + "Scroll" else "scroll");
			}
		}else{
			noteID = -40;
		}
		visible = false;
		callInterp("noteAdd",[this,rawNote]);
		if(!eventNote){
	
			updateHitbox();
			// centerOrigin();
			
			// offset.y = 0;
			// origin.y=0;
			offset.x = frameWidth * 0.5;
			if(noteJSON != null){
				flipX=noteJSON.flipx;
				flipY=noteJSON.flipy;
				antialiasing=noteJSON.antialiasing;
				scale.x*=noteJSON.scale[0];
				scale.y*=noteJSON.scale[1];
				if(noteJSON.offset != null){offset.x+=noteJSON.offset[0];offset.y+=noteJSON.offset[1];}
				if(noteJSON.offsetNote != null){offset.x+=noteJSON.offsetNote[0];offset.y+=noteJSON.offsetNote[1];}
				if(isSustainNoteEnd) if(noteJSON.offsetHoldEnd != null){offset.x+=noteJSON.offsetHoldEnd[0];offset.y+=noteJSON.offsetHoldEnd[1];}
				else if(isSustainNote) if(noteJSON.offsetHold != null){offset.x+=noteJSON.offsetHold[0];offset.y+=noteJSON.offsetHold[1];}
				else if(noteJSON.offsetScroll != null){offset.x+=noteJSON.offsetStatic[0];offset.y+=noteJSON.offsetStatic[1];}
			}
			if (SESave.data.downscroll && isSustainNote && isSustainNoteEnd) flipY = !flipY;
			if(shouldntBeHit && noteAnimation == ""){
				noteAnimationMiss = noteAnimation = 'hurt${noteDirections[noteData]}/hurt/sing${noteDirections[noteData]}miss';
			}
		}

	}catch(e){MainMenuState.handleError(e,'Caught "Note create" crash: ${e.message}\n${e.stack}');}}

	override function draw(){
		// if(!(eventNote && !inCharter) && showNote && visible){
		if(!inCharter && (!showNote || !visible || eventNote)) return;
		super.draw();
		if(ntText != null){ntText.x = this.x;ntText.y = this.y;ntText.draw();}
		// }
	}
	override function destroy(){
		if(PlayState.instance != null){
			callInterp('noteDestroy',[this]);
			if(PlayState.instance.cancelCurrentFunction) return;
			
		}
		super.destroy();
	}
	public function updateCanHit(?comparisonTime:Float = -1):Bool{
		if(comparisonTime == -1) comparisonTime = Conductor.songPosition;
		if(shouldntBeHit){
			return canBeHit = (strumTime - comparisonTime <= (45 * Conductor.timeScale) && strumTime - comparisonTime >= (-45 * Conductor.timeScale));
		}
		return canBeHit = ((isSustainNote && (strumTime > comparisonTime - Conductor.safeZoneOffset && strumTime < comparisonTime + ((Conductor.safeZoneOffset * 0.5) * Conductor.timeScale)) ) ||
				strumTime > comparisonTime - (Conductor.safeZoneOffset * Conductor.timeScale) && strumTime < comparisonTime + Conductor.safeZoneOffset  );
	}
	public var doUpdate:Bool = false;
	override function update(elapsed:Float) {
		if(doUpdate) super.update(elapsed);
		animation.update(elapsed);
		if(inCharter){
			wasGoodHit = (strumTime <= Conductor.songPosition && strumTime + 100 >= Conductor.songPosition);
			alpha = (wasGoodHit ? 0.7 : 1);
			if(wasGoodHit && !tooLate && ChartingState.playClaps){
				ChartingState.playSnap();
			}
			tooLate = wasGoodHit;
			visible = true;
			skipNote = false;
			return;
		}
		callInterp("noteUpdate",[this]);
		if(PlayState.instance.cancelCurrentFunction) return;
		if(skipNote) return;
		visible = showNote;
		var dad = PlayState.opponentCharacter;
		if (mustPress) {
			if (shouldntBeHit) { 
				updateCanHit();
			}else{

				updateCanHit();

				if (!wasGoodHit && strumTime < Conductor.songPosition - (Conductor.safeZoneOffset * Conductor.timeScale)){
					canBeHit = false;
					tooLate = true;
					skipNote = true;
					if (!shouldntBeHit) {
						PlayState.instance.health += PlayState.SONG.noteMetadata.tooLateHealth;
						PlayState.instance.vocals.volume = 0;
						PlayState.instance.noteMiss(noteData, this);
					}
					// FlxTween.tween(this,{alpha:0},0.2,{onComplete:(_)->{
					PlayState.instance.notes.remove(this, true);

					destroy();
					// }});
				}
			}
		}else if (aiShouldPress && (dad == null || !dad.isStunned) && PlayState.dadShow && !PlayState.p2canplay && strumTime <= Conductor.songPosition) {
			hit(1,this);
			
			callInterp("noteHitDad",[dad,this]);
			

			dad.holdTimer = 0;

			if (dad.useVoices){
				dad.voiceSounds[noteData].play(1);
				dad.voiceSounds[noteData].time = 0;
				PlayState.instance.vocals.volume = 0;
			}else if (PlayState.instance.vocals != null){
				PlayState.instance.vocals.volume = SESave.data.voicesVol;
			}

			PlayState.instance.notes.remove(this, true);
			destroy();
		}
		callInterp("noteUpdateAfter",[this]);
	}
}