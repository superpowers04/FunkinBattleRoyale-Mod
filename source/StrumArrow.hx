package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
// import flixel.math.FlxMath;
import flixel.util.FlxColor;
import sys.FileSystem;
import flixel.graphics.FlxGraphic;
import flash.display.BitmapData;
import sys.io.File;

class StrumArrow extends FlxSprite{
	public static var defColor:FlxColor = 0xFFFFFFFF;
	var noteColor:FlxColor = 0xFFFFFFFF; 
	public var id:Int = 0; 
	static var path_:String = "mods/noteassets";
	override public function new(nid:Int = 0,?x:Float = 0,?y:Float = 0){
		super(x,y);
		id = nid;
		ID = nid;
	}

	public function changeSprite(?name:String = "default",?_frames:FlxAtlasFrames,?anim:String = "",?setFrames:Bool = true){
		try{
			var curAnim = if(anim == "" && animation.curAnim != null) animation.curAnim.name else anim;
			if(setFrames && (_frames != null || name != "")){
				if(_frames == null){
					if(name == "skin"){
						frames = FlxAtlasFrames.fromSparrow(NoteAssets.image,NoteAssets.xml);
					}else if (name == 'default' || (!FileSystem.exists('${path_}/${name}.png') || !FileSystem.exists('${path_}/${name}.xml'))){
						frames = FlxAtlasFrames.fromSparrow(FlxGraphic.fromBitmapData(BitmapData.fromFile('assets/shared/images/NOTE_assets.png')),File.getContent("assets/shared/images/NOTE_assets.xml"));
					}else{
						frames = FlxAtlasFrames.fromSparrow(FlxGraphic.fromBitmapData(BitmapData.fromFile('${path_}/${name}.png')),File.getContent('${path_}/${name}.xml'));
					}
				}else{
					frames = _frames;
				}
			}
			antialiasing = true;
			setGraphicSize(Std.int(width * 0.7));
			updateHitbox();
			animation.addByPrefix('static', 'arrow' + arrowIDs[id].toUpperCase());
			animation.addByPrefix('pressed', arrowIDs[id].toLowerCase() + ' press', 24, false);
			animation.addByPrefix('confirm', arrowIDs[id].toLowerCase() + ' confirm', 24, false);
			animation.play(curAnim);
			centerOffsets();
		}catch(e){MainMenuState.handleError(e,'Error while changing sprite for arrow:\n ${e.message}');
		}
	}
	static var arrowIDs:Array<String> = ['left','down','up',"right"];
	public function init(){
		TitleState.loadNoteAssets();
		changeSprite("skin","static",(frames == null));
		// if (frames == null) {
		// 	frames = FlxAtlasFrames.fromSparrow(NoteAssets.image,NoteAssets.xml);
		// }
		// animation.addByPrefix('static', 'arrow' + arrowIDs[id].toUpperCase());
		// animation.addByPrefix('pressed', arrowIDs[id].toLowerCase() + ' press', 24, false);
		// animation.addByPrefix('confirm', arrowIDs[id].toLowerCase() + ' confirm', 24, false);
	}
	public function playStatic(){
		// color = defColor;
		animation.play("static");
		centerOffsets();
	}
	public function press(){
		// if (color != noteColor) color = noteColor;
		animation.play("pressed");
		centerOffsets();
	}
	public function confirm(){
		// if (color != noteColor) color = noteColor;
		animation.play("confirm");

		centerOffsets();
		offset.x -= 13;
		offset.y -= 13;

	}

}