
package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
// import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.graphics.FlxGraphic;
import flash.display.BitmapData;
import sys.io.File;
import NoteAssets;
 

class StrumArrow extends FlxSprite{
	public static var defColor:FlxColor = 0xFFFFFFFF;
	public var noteColor:FlxColor = 0xFFFFFFFF; 
	public var id:Int = 0; 
	public var noteJSON:NoteAssetConfig;
	public var updateStrumCenter:Bool = true;
	public var strumCenterX:Float = 0;
	public var strumCenterY:Float = 0;
	public var DEFSkin:String = "skin";

	override public function new(nid:Int = 0,?x:Float = 0,?y:Float = 0,?skin:String = "skin"){
		super(x,y);
		id = ID = nid;
		DEFSkin = skin;
	}

	public function changeSprite(?name:String = "default",?_frames:FlxAtlasFrames,?anim:String = "",?setFrames:Bool = true,path_:String = "mods/noteassets",?noteJSON:NoteAssetConfig){
		try{
			var curAnim = if(anim == "" && animation.curAnim != null) animation.curAnim.name else anim;

			this.noteJSON = noteJSON ?? null;
			
			if(setFrames && (_frames != null || name != "")){
				if(_frames == null){
					if(name == "skin"){
						frames = FlxAtlasFrames.fromSparrow(NoteAssets.image,NoteAssets.xml);
						try{
							noteJSON = NoteAssets.noteJSON.notes[id];
						}catch(e){
							noteJSON = null;
						}
					}else if (name == 'default' || (!SELoader.exists('${path_}/${name}.png') || !SELoader.exists('${path_}/${name}.xml'))){
						frames = SELoader.loadSparrowFrames('assets/shared/images/NOTE_assets');
					}else{
						frames = SELoader.loadSparrowFrames('${path_}/${name}');
						
						if(SELoader.exists('${path}/${name}.json')){
							try{
								this.noteJSON = cast Json.parse(SELoader.loadText('${path}/${name}.json')).notes[id];
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
			antialiasing = true;

			if(noteJSON != null){
				animation.addByPrefix('static', noteJSON.staticanimname);
				animation.addByPrefix('pressed', noteJSON.pressedanimname,false);
				animation.addByPrefix('confirm', noteJSON.confirmanimname,false);
			}else{
				animation.addByPrefix('static', 'arrow' + arrowIDs[id % 4].toUpperCase());
				animation.addByPrefix('pressed', arrowIDs[id % 4].toLowerCase() + ' press', 24, false);
				animation.addByPrefix('confirm', arrowIDs[id % 4].toLowerCase() + ' confirm', 24, false);
			}
			animation.play(curAnim);
			setGraphicSize(Std.int(width * 0.7));
			updateHitbox();
			centerOffsets();
			if(noteJSON != null){
				flipX=noteJSON.flipx;
				flipY=noteJSON.flipy;
				antialiasing=noteJSON.antialiasing;
				scale.x*=noteJSON.scale[0];
				scale.y*=noteJSON.scale[1];
			}
		}catch(e){MainMenuState.handleError(e,'Error while changing sprite for arrow:\n ${e.message}');
		}
	}
	static var arrowIDs:Array<String> = ['left','down','up',"right"];
	public function init(){
		TitleState.loadNoteAssets();
		changeSprite(DEFSkin,"static",(frames == null));
		// if (frames == null) {
		// 	frames = FlxAtlasFrames.fromSparrow(NoteAssets.image,NoteAssets.xml);
		// }
		// animation.addByPrefix('static', 'arrow' + arrowIDs[id].toUpperCase());
		// animation.addByPrefix('pressed', arrowIDs[id].toLowerCase() + ' press', 24, false);
		// animation.addByPrefix('confirm', arrowIDs[id].toLowerCase() + ' confirm', 24, false);
	}
	public override function update(e:Float){
		super.update(e);
		strumCenterX = x + (frameWidth * 0.5);
		strumCenterY = y;

	}
	public function playAnim(name:String,?forced:Bool = true, ?Reversed:Bool = false, ?Frame:Int = 0){
		if(animation.getByName(name) == null) return;
		animation.play(name,forced,Reversed,Frame);
		centerOffsets();
		if(noteJSON == null) return;
		if(noteJSON.offsetStrum != null){
			offset.x+=noteJSON.offsetStrum[0];
			offset.y+=noteJSON.offsetStrum[1];
		}
		if(noteJSON.offset != null){
			offset.x+=noteJSON.offset[0];
			offset.y+=noteJSON.offset[1];
		}
	}
	public function playStatic(?forced:Bool = false){
		// color = defColor;
		animation.play("static",forced);
		centerOffsets();
		if(noteJSON == null) return;
		if(noteJSON.offsetStatic != null){
			offset.x+=noteJSON.offsetStatic[0];
			offset.y+=noteJSON.offsetStatic[1];
		}
		updateOffsets();
	}
	public function press(?forced:Bool = false){
		// if (color != noteColor) color = noteColor;

		animation.play("pressed",forced);
		centerOffsets();
		if(noteJSON == null) return;
		if(noteJSON.offsetPress != null){
			offset.x+=noteJSON.offsetPress[0];
			offset.y+=noteJSON.offsetPress[1];
		}
		updateOffsets();
	}
	public function confirm(?forced:Bool = false){
		// if (color != noteColor) color = noteColor;
		animation.play("confirm",forced);

		centerOffsets();
		if(animation.curAnim.name != "confirm") return;
		offset.x -= 13;
		offset.y -= 13;
		if(noteJSON == null) return;
		if(noteJSON.offsetConfirm != null){
			offset.x+=noteJSON.offsetConfirm[0];
			offset.y+=noteJSON.offsetConfirm[1];
		}
		updateOffsets();

	}
	inline function updateOffsets(){
		if(noteJSON.offsetStrum != null){
			offset.x+=noteJSON.offsetStrum[0];
			offset.y+=noteJSON.offsetStrum[1];
		}
		if(noteJSON.offset != null){
			offset.x+=noteJSON.offset[0];
			offset.y+=noteJSON.offset[1];
		}

	}

}