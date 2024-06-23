package;

import flixel.FlxG;
import PlayState;
import Overlay.ConsoleUtils;

using StringTools; 

class EventNote implements flixel.util.FlxDestroyUtil.IFlxDestroyable{
	public var strumTime:Float = 0;
	public var type:Dynamic = 0; // Used for scriptable arrows 
	public var info:Array<Dynamic> = [];
	public var rawNote:Array<Dynamic> = [];
	public var killNote:Bool = false;



	@:keep inline function callInterp(func:String,?args:Array<Dynamic>){
		if(PlayState.instance != null) PlayState.instance.callInterp(func,args);
	}

	dynamic public function hit(?charID:Int = 0,note:EventNote){
		return;
	}

	static var psychChars:Array<Int> = [1,0,2]; // Psych uses different character ID's than SE
	public static function applyEvent(note:Dynamic){
		var rawNote:Array<Dynamic> = note.rawNote;
		for(index => value in rawNote){
			if(value is String){rawNote[index] = (cast(value,String)).trim();}
		}
		if(rawNote[2] == "eventNote") rawNote.remove(2);
		note.type = rawNote[2];
		if(note.inCharter) return;
		note.callInterp("eventNoteCheckType",[note,rawNote]);
		var info:Array<Dynamic> = [];
		var hit:Dynamic = null;
		switch (Std.string(note.type).toLowerCase()) {
			case "charanimref": {
				hit = function(?charID:Int = 0,note){info[0].playAnim(info[1],true);}; 
			}
			case "play animation" | "playanimation"| "playanim" | "animation" | "anim": {
				try{
					// Info can be set to anything, it's being used for storing the Animation and character
					info = [rawNote[3],
						// Psych uses different character ID's than SE, more charts will be coming from Psych than SE
						switch(Std.string(rawNote[4]).toLowerCase()){
							case "dad","opponent","0":1;
							case "bf","player","boyfriend","1":0;
							case "gf","girlfriend","2":2;
							default:{
								MusicBeatState.instance.showTempmessage('A note is attempting to use ${rawNote[4]} as a character, This doesn\'t seem intentional!',0xFFFF0000);
								0;
							}
						}
					]; 
				}catch(e){info = [rawNote[3],0];}
				// Replaces hit func
				hit = function(?charID:Int = 0,note){trace('Playing ${info[0]} for ${info[1]}');PlayState.charAnim(info[1],info[0],true);}; 
			}
			case "hey","hey!": {
				try{
					// Info can be set to anything, it's being used for storing the Animation and character
					info = [
						// Psych uses different character ID's than SE, more charts will be coming from Psych than SE
						switch(Std.string(rawNote[4]).toLowerCase()){
							case "dad","opponent","1":1;
							case "gf","girlfriend","2":2;
							default:0;
						}
					]; 
				}catch(e){info = [rawNote[3]];}
				// Replaces hit func
				hit = function(?charID:Int = 0,note){PlayState.charAnim(info[0],(if(info[0] == 2) "cheer" else "hey"),true);}; 
			}
			case "changebpm" | "bpm" | "bpm change": {
				try{
					info = [(if(rawNote[4] != "" && !Math.isNaN(Std.parseFloat(rawNote[4])))Std.parseFloat(rawNote[4]) else Std.parseFloat(rawNote[3]))]; 
				}catch(e){info = [120,0];}
				hit = function(?charID:Int = 0,note){Conductor.changeBPM(info[0]);}; 
			
			}
			case "changecharacter" | "change character" | "changechar" | "change char": {
				try{
					info = [Std.string(rawNote[3]),rawNote[4]];
					var _char = PlayState.getCharFromID(info[0]);
					if(_char == null || _char.curCharacter == "lonely" || _char.lonely){ // If this character isn't enabled, no reason to allow switching for it
						note.killNote = true;
					}else{
						var id = PlayState.getCharID(info[0]);
						info[0]=id;
						var name = info[1];
						if(PlayState.instance.cachedChars[id][name] == null){ // Absolutely no reason to cache the character again if it's already cached
							trace('Caching ${rawNote[3]}/${id}:${name} for changeChar note');

							var psChar = PlayState.getCharFromID(id);
							var cachingChar:Character = {x:psChar.x, y:psChar.y,character:name,isPlayer:psChar.isPlayer,charType:psChar.charType};
							PlayState.instance.cachedChars[id][name] = cachingChar;
							cachingChar.drawFrame();
							trace('Finished caching $name');
						}
						hit = function(?charID:Int = 0,note){
							var _char:Character = PlayState.instance.cachedChars[info[0]][info[1]];
							if(_char == null){return;}
							// PlayState.charSet(charID,"visible",false);
							PlayState.instance.members[PlayState.instance.members.indexOf(PlayState.getCharFromID(info[0]))] = _char;
							var _oldChar:Character = PlayState.getCharFromID(id);
							var _variName:String = PlayState.getCharVariName(info[0]);
							switch(_variName){
								case "dad":
									PlayState.dad = _char;
								case "gf":
									PlayState.gf = _char;
								case "boyfriend":
									PlayState.boyfriend = _char;
								default:
									Reflect.setProperty(PlayState,_variName,_char);
							}
							try{
								_char.playAnim(_oldChar.animName,_oldChar.animation.curAnim.curFrame / _oldChar.animation.curAnim.frames.length);
							}catch(e){}
							_char.callInterp('changeChar',[_oldChar]); // Allows the character to play an animation or something upon change
							PlayState.instance.callInterp('changeChar',[_char,_oldChar,id]);
							// PlayState.instance.add(_char);
						};

					}
					
				}catch(e){
					trace('Error trying to add char change note for ${rawNote[4]} -> ${rawNote[3]}:${e.message}');
				}
				// Replaces hit func
			}
			case "camflash" | "cameraflash" | "camera flash": {
				try{
					info = [Std.parseFloat(rawNote[3]),(if( Math.isNaN(Std.parseInt(rawNote[4]))) 0xFFFFFF else Std.parseInt(rawNote[4]))]; 
				}catch(e){info = [1];}
				// Replaces hit func
				hit = function(?charID:Int = 0,note){if(SESave.data.distractions && SESave.data.flashingLights) FlxG.camera.flash(info[2],info[1]);}; 

			}
			case "set camzoom" | "setcamzoom" | "camzoom": {
				try{
					info = [Std.parseFloat(rawNote[3])];
					if(Math.isNaN(info[0])) info[0] = 0.7;
				}catch(e){info = [0.7];}
				// Replaces hit func
				hit = function(?charID:Int = 0,note){PlayState.instance.defaultCamZoom = info[0];}; 

			}
			case "addcamerazoom" | "add camera zoom" | "add cam zoom" | "addcamzoom": {
				try{
					info = [Std.parseFloat(rawNote[3])]; 
					if(Math.isNaN(info[0])) info[0] = 0.05;
				}catch(e){info = [0.05];}
				// Replaces hit func
				hit = function(?charID:Int = 0,note){
					PlayState.instance.defaultCamZoom += info[0];
					if(PlayState.instance.defaultCamZoom < 0.1) PlayState.instance.defaultCamZoom = 0.1;
				}; 
			}
			case "multcamzoom" | "multiplycamzoom" | "multiply cam zoom" | "mult cam zoom": {
				try{
					info = [Std.parseFloat(rawNote[3])]; 
					if(Math.isNaN(info[0])) info[0] = 1;
				}catch(e){info = [0.05];}
				// Replaces hit func
				hit = function(?charID:Int = 0,note){PlayState.instance.defaultCamZoom *= info[0];}; 

			}
			case "movecam" | "followchar" | "follow character" | 'focuschar' | 'focus character': {
				try{
					info = [
						switch(Std.string(rawNote[3]).toLowerCase()){
							case "dad","opponent","1":1;
							case "gf","girlfriend","2":2;
							default:0;
						},
						switch(Std.string(rawNote[4]).toLowerCase()){
							case "true","t","1":true;
							default:false;
						},
					]; 
				}catch(e){info = [0.7];}
				hit = function(?charID:Int = 0,note){if(PlayState.instance == null) return;
					PlayState.instance.followChar(info[0],info[1]);
				};
			}
			case "lockcam" | "lock camera" | "controlcamera": {
				try{
					info = [
						switch(Std.string(rawNote[3]).toLowerCase()){
							case "t","true","1":true;
							default:false;
						}
					]; 
				}catch(e){info = [0.7];}
				// Replaces hit func
				hit = function(?charID:Int = 0,note){if(PlayState.instance == null) return;
					PlayState.instance.controlCamera = info[0];
				};
			}
			case "screenshake" | "screen shake" | "shake screen": {
				try{
					info = [Std.parseFloat(rawNote[3]),Std.parseFloat(rawNote[4])];
					if(Math.isNaN(info[0])) info[0] = 0; 
					if(Math.isNaN(info[1])) info[1] = 0; 
				}catch(e){info = [0.7];}
				// Replaces hit func
				hit = function(?charID:Int = 0,note){if(SESave.data.distractions) FlxG.camera.shake(info[0],info[1]);}; 
				
			}
			case "camera follow pos" | "camfollowpos" | "cam follow" | "cam follow position": {
				try{
					info = [Std.parseFloat(rawNote[3]),Std.parseFloat(rawNote[4])];
					if(Math.isNaN(info[0])) info[0] = 0; 
					if(Math.isNaN(info[1])) info[1] = 0; 
				}catch(e){info = [0,0];}
				// Replaces hit func
				hit = function(?charID:Int = 0,note){if(PlayState.instance == null) return;
					PlayState.instance.moveCamera = (info[0] == 0 && info[1] == 0);
					if(info[0] != 0 )PlayState.instance.camFollow.x = info[0];
					if(info[1] != 0 )PlayState.instance.camFollow.y = info[1];
				}; 

			}
			case "setvalue",'set': {
				try{
					info = [Std.string(rawNote[3]).trim(),Std.string(rawNote[4]).trim()]; // path,value
				}catch(e){info = [0,0];}
				// Replaces hit func
				hit = function(?charID:Int = 0,note){
					try{
						if(StringTools.startsWith(info[1],"$")){
							info[1] = PlayState.instance.eventNoteStore[info[1].substring(1)];
						}
						ConsoleUtils.setValueFromPath(info[0],info[1]);
					}catch(e){
						MusicBeatState.instance.errorHandle('Unable to set value ${info[0]} to ${info[1]}: ${e.message}');
					}
				}; 
			}
			case "get": {
				try{
					info = [Std.string(rawNote[3]).trim(),Std.string(rawNote[4]).trim()]; // path,variableName
				}catch(e){info = [0,0];}
				// Replaces hit func
				hit = function(?charID:Int = 0,note){
					PlayState.instance.eventNoteStore[info[1]] = ConsoleUtils.getValueFromPath(null,info[0]);
				}; 
			}

			// }
			// case "tweenfloat",'tweenf': {
			// 	try{
			// 		info = [rawNote[3],Std.parseFloat(rawNote[4]),Std.parseFloat(rawNote[5])]; // path,value,time
			// 		if(Math.isNaN(info[1])) info[0] = 0;
			// 		if(Math.isNaN(info[2])) info[1] = 0.1;
			// 	}catch(e){info = [0,0];}
			// 	// Replaces hit func
			// 	hit = function(?charID:Int = 0,note){
			// 		var path =info[0];

			// 		FlxTween.tween(ConsoleUtils.getValueFromPath(path.substr(0,path.lastIndexOf('.')-1),{'${path.substr(path.lastIndexOf('.')+1)}':info[1]},info[2]);
			// 	}; 

			// }
			case "changescrollspeed": {
				try{
					info = [Std.parseFloat(rawNote[4])]; 
				}catch(e){info = [2,0];}
				// Replaces hit func
				hit = function(?charID:Int = 0,note){PlayState.SONG.speed = info[0];}; 
				
			}
			// case "hscript" | "script" | "runcode" | "haxe": {
			// 	try{
			// 		// Info can be set to anything, it's being used for storing the script
			// 		info = [rawNote[3],rawNote[4]]; 
			// 	}catch(e){info = [""];}
			// 	// Replaces hit func
			// 	hit = function(?charID:Int = 0,note){PlayState.instance.parseRun(rawNote[4],rawNote[3]);}; 
			// }
			case 'script' | 'hscript':{
				info = [rawNote[4]]; 
				hit = function(?charID:Int = 0,note){PlayState.instance.parseRun(rawNote[4]);}; 
			}
			default:{ // Don't trigger hit animation
				hit = function(?charID:Int = 0,note){trace('Hit an empty event note ${note.type}.');return;};
			}
		}
		note.info = info;
		if(hit != null)	note.hit = hit;
	}
	public function destroy(){
		type=null;
		info=null;
		rawNote=null;
		strumTime=0;
	}

	public function new(strumTime:Float,?_type:Dynamic = 0,?rawNote:Array<Dynamic> = null){
		this.strumTime = strumTime;
		type = _type;
		this.rawNote = rawNote;
	}
	// 	// if(rawNote == null){
	// 	// 	this.rawNote = [strumTime,_noteData,0];
	// 	// }else{
	// 	// 	this.rawNote = rawNote;

	// 	// }


	// 	// if(Std.isOfType(_type,String)) _type = _type.toLowerCase();

	// 	if(rawNote != null && PlayState.instance != null) PlayState.instance.callInterp("eventNoteAdd",[this,rawNote]);
	// }catch(e){MainMenuState.handleError(e,e,'Caught "Event note create" crash: ${e.message}');}}

	public static function fromNote(note:Note):EventNote{
		var ev = new EventNote(note.strumTime,note.type,note.rawNote);
		ev.info = note.info;
		ev.hit = cast note.hit;
		return ev;
	}
}