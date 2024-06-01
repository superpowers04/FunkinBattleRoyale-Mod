package;



// class CharacterJson {
// 	@:publicFields
// 	var asset_files:Array<CharacterAssetFiles> = []; // Might deprecate this, idk
// 	var sideInfo:Array<CharSideInfo> = []; // Info about sides
// 	var embedded:Bool = false;
// 	var path:String = "";
// 	var animations:Array<CharJsonAnimation> = [];
// 	var customProperties:Array<CCProp> = []; // Allows the json file to edit any value about the character
// 	var genBy:String = "Unknown";
// 	var formatVersion:Float = 1; // Version of the format being used

// 	static public function import(json:String){
// 		var charJson = new CharacterJson();
// 		var jsonImport:Dynamic = Json.decode(json);
// 		if(jsonImport.formatVersion == null){
// 			var jsonImport = cast (jsonImport,CharacterJsonOld);

// 		}else{
// 			charJson = charJson.fromJSON(jsonImport);
// 		}
// 		return charJson;
// 	} 
// 	public function fromJSON(json:Dynamic){

// 	}

// 	public function new(){

// 	}

// }



// typedef CharacterJsonRaw = {
// 	var asset_files:Array<CharacterAssetFiles>; // Might deprecate this, idk
// 	var ?flip_notes:Bool; // Tells the game if it should flip left and right notes on the right
// 	var sideInfo:Array<CharSideInfo>; // Info about sides
// 	var animations:Array<CharJsonAnimation>;
// 	var ?customProperties:Array<CCProp>; // Allows the json file to edit any value about the character
// 	var genBy:String;
// 	var formatVersion:Float; // Version of the format being used

// 	// var no_antialiasing:Bool;
// }
// typedef CharSideInfo = {
// 	var flip_x:Bool; // Flip character's X
// 	var flip_y:Bool; // Flip character's Y
// 	var flip_anims:Bool; // Flip animations like singLeft and singRight;
// 	var position:Array<Float>; // Character's Position
// 	var camera_position:Array<Float>; // Camera position
// 	var ?customProperties:Array<CCProp>; // Allows the json file to edit any value about the character
// 	var png:String; // Sprite to use
// 	var xml:String; // Xml to use
// }



typedef CharacterJson =
{
	var ?sprite_type:String; // TODO add more format support using FlxAnimate

	var flip_x:Bool;
	var flip:Dynamic; // Controls if the character should be flipped when on the player's side
	var offset_flip:Dynamic; // Flips the offsets on the left, 0/not specififed = off completely, 1 = use player2, 2 = flip left, 3 = flip right  
	var asset_files:Array<CharacterAssetFiles>;
	var ?clone:String;
	var ?like:String; // Clone but without stealing the offsets
	var voices:String;
	var animations:Array<CharJsonAnimation>;
	var animations_offsets:Array<CharJsonAnimOffsets>;
	var sing_duration:Float;
	var scale:Float;
	var no_antialiasing:Bool;
	// var dance_idle:Bool;
	var ?common_stage_offset:Array<Float>;
	var cam_pos:Array<Float>;
	var char_pos:Array<Float>;
	var cam_pos1:Array<Float>;
	var char_pos1:Array<Float>;
	var cam_pos2:Array<Float>;
	var char_pos2:Array<Float>;
	var cam_pos3:Array<Float>;
	var char_pos3:Array<Float>;
	var custom_misses:Int;
	var ?flip_notes:Bool; // Tells the game if it should flip left and right notes on the right
	var ?editableSprite:Bool; // If false, marks the sprite to not allow it's frames/bitmaps to be editable for performance after done creating
	var color:Dynamic;
	var sprites:Array<String>;

	var embedded:Bool; // For embedded JSON chars, will not effect custom chars. Tells the game whether to use Lime assets or load them like a custom character
	var path:String; // For embedded JSON chars, will not effect custom chars. Tells the game the asset to use or the path to load from
	var genBy:String; // This should not be provided manually
	var ?boneChar:BoneChar;
	var ?customProperties:Array<CCProp>; // Allows the json file to edit any value about the character
	var ?scriptOptions:Map<String,Dynamic>; // Allows characters to tell scripts to use custom settings
	var ?seVersionIdentifier:Null<Int>;

	// Psych Character compatibility
	var camera_position:Array<Float>;
	var healthicon:String;
	var image:String;
	var position:Array<Float>;
}

typedef CharJsonAnimation ={
	var ?ifstate:Null<IfStatement>;
	var anim:String; // The name that'll be used internally to refer to this animation
	var ?name:String; // Prefix
	var fps:Int; // FPS to play animation at
	var loop:Bool; // Loop animation
	var ?noreplaywhencalled:Bool; // Whether the animation should replay when it's told to play, useful for looping animations or hold end animations
	var ?flipx:Null<Bool>; // Whether to flip the animation on the X-Axis or not
	var indices:Array<Int>;  // List of frame numbers to use
	var ?frameNames:Array<String>; // List of frame names to use, removes the need for name

	var ?loopStart:Null<Int>; // Tells the game where to restart the animation if looped
	var ?playAfter:Null<String>; // Tells the game to swap animations, useful for a start animation and then a loop animation
	var ?stage:Null<String>; // Set on specific stage
	var ?song:Null<String>; // Set on specific songname
	var ?char_side:Null<Int>; // Set song specific side, 0 for BF, 1 for Dad, 2 for GF, 3 for disabled
	var ?oneshot:Null<Bool>; // Should animation overlap everything?
	var ?priority:Null<Int>; // Animation priority, 0 is idle, 10 is sing, 5 is hey, and the rest are up to you. The engine will handle the rest
	
	var ?offsets:Array<Dynamic>;
	var ?ifstates:Array<IfStatement>;
}

typedef CCProp = {
	var path:String;
	var value:Dynamic;
}
typedef IfStatement = {
	var ?func:Dynamic->Void;
	var ?isFunc:Bool;
	var	variable:String;
	var	type:String;
	var	value:Dynamic;
	var check:Int; // 0 = beat, 1 = step
} 

typedef CharacterAssetFiles ={
	var xml:String;
	var png:String;
	var stage:String; // Set on specific stage
	var song:String; // Set on specific songname
	var char_side:Dynamic; // Set song specific side, 0 for BF, 1 for Dad, 2 for GF, 3 for disabled
	var tags:Array<String>;
	var animations:Array<CharJsonAnimation>;
	var animations_offsets:Array<CharJsonAnimOffsets>;
}
typedef CharJsonAnimOffsets ={
	var anim:String;
	var player1:Array<Float>;
	var player2:Array<Float>;
	var player3:Array<Float>;
}
typedef BoneChar = {
	var anims:Array<BCAnim>;
}

typedef BCAnim = {
	var keyframes:Array<BCAnimKeyFrame>;
	var name:String;
	var length:Float;
	var looped:Bool;
	var priority:Int;
	var blend:Float;
}
typedef BCAnimKeyFrame = {
	var time:Float; // Time in seconds
	var length:Float; // Time in seconds
	var bone:String;
	var type:Int; // 1 = position, 2 = angle, 3 = frame
	var position:Array<Float>;
	var angle:Float;
	var frame:Int;
	var tweenType:String; // Defaults to linear, allows using a Flx
}