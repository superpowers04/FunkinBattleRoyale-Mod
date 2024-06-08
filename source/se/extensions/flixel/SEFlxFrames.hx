package se.extensions.flixel;
import flixel.graphics.frames.FlxAtlasFrames;

#if (flixel < "5.3.0")
typedef SEFlxFrames = FlxAtlasFrames;
#else

import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.util.FlxDestroyUtil;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxFramesCollection.FlxFrameCollectionType;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.FlxAssets.FlxTexturePackerSource;
import openfl.Assets;
import haxe.Json;
import haxe.xml.Access;

// Attempts to optmise some loading to minimise memory usage

class SEFlxFrames extends FlxAtlasFrames{

	#if (flixel < "5.3.0")
		public var framesByName(get,set):Map<String,FlxFrame>;
		@:keep inline public function get_framesByName() return framesHash;
		@:keep inline public function set_framesByName(v) return framesHash = v;
	#end
	/**
	 * Parsing method for Sparrow texture atlases
	 * (they can be generated with Shoebox http://renderhjs.net/shoebox/ for example).
	 * This will return a FlxFramesCollection that will avoid duplicating frames.
	 *
	 * @param   Source        The image source (can be `FlxGraphic`, `String` or `BitmapData`).
	 * @param   Description   Contents of the XML file with atlas description.
	 *                        You can get it with `Assets.getText(path/to/description.xml)`.
	 *                        Or you can just pass a path to the XML file in the assets directory.
	 * @return  Newly created `FlxAtlasFrames` collection.
	 */
	public static function fromSparrow(Source:FlxGraphicAsset, Description:String):FlxAtlasFrames {
		var graphic:FlxGraphic = FlxG.bitmap.add(Source);
		if (graphic == null)
			return null;

		// No need to parse data again
		var frames:FlxAtlasFrames = FlxAtlasFrames.findFrame(graphic);
		if (frames != null)
			return frames;

		if (graphic == null || Description == null)
			return null;

		frames = new SEFlxFrames(graphic);

		if (Assets.exists(Description))
			Description = Assets.getText(Description);

		var data:Access = new Access(Xml.parse(Description).firstElement());

		for (texture in data.nodes.SubTexture) {
			var name = texture.att.name;
			var trimmed = texture.has.frameX;
			var rotated = (texture.has.rotated && texture.att.rotated == "true");
			var flipX = (texture.has.flipX && texture.att.flipX == "true");
			var flipY = (texture.has.flipY && texture.att.flipY == "true");

			var rect = FlxRect.get(Std.parseFloat(texture.att.x), Std.parseFloat(texture.att.y), Std.parseFloat(texture.att.width),
				Std.parseFloat(texture.att.height));

			var size = if (trimmed) {
				new Rectangle(Std.parseInt(texture.att.frameX), Std.parseInt(texture.att.frameY), Std.parseInt(texture.att.frameWidth),
					Std.parseInt(texture.att.frameHeight));
			} else {
				new Rectangle(0, 0, rect.width, rect.height);
			}

			var angle = rotated ? FlxFrameAngle.ANGLE_NEG_90 : FlxFrameAngle.ANGLE_0;

			var offset = FlxPoint.get(-size.left, -size.top);
			var sourceSize = FlxPoint.get(size.width, size.height);

			if (rotated && !trimmed)
				sourceSize.set(size.height, size.width);

			frames.addAtlasFrame(rect, sourceSize, offset, name, angle, flipX, flipY);
		}

		return frames;
	}

	/**
	 * Helper method for a adding frame to the collection.
	 *
	 * @param   frameObj   Frame to add.
	 * @return  Added frame.
	 */
	public function pushFrameWithName(frameObj:FlxFrame,name:String = ""):FlxFrame
	{
		if(name == "") 
			name = frameObj.name;
		else if(frameObj.name != name) {
			framesByName.set(name,frameObj);
			return frameObj;
		}
		if(name != null && framesByName.exists(name))
			return framesByName.get(name);

		frames.push(frameObj);
		frameObj.cacheFrameMatrix();

		if (name != null)
			framesByName.set(name, frameObj);

		return frameObj;
	}

	public override function addAtlasFrame(frame:FlxRect, sourceSize:FlxPoint, offset:FlxPoint, ?name:String, angle:FlxFrameAngle = 0, flipX:Bool = false, flipY:Bool = false,
			duration = 0.0):FlxFrame{
		frame = checkFrame(frame, name);
		if (name != null && framesByName.exists(name))
			return framesByName.get(name);
		for(index => frameValue in frames){
			if(
				frame.x == frameValue.frame.x &&
				frame.y == frameValue.frame.y &&
				sourceSize.x == frameValue.sourceSize.x &&
				sourceSize.y == frameValue.sourceSize.y &&
				offset.x == frameValue.offset.x &&
				offset.y == frameValue.offset.y &&
				angle == frameValue.angle &&
				flipY == frameValue.flipY &&
				flipX == frameValue.flipX
			){
				framesByName.set(name,frameValue);
				return frameValue;
			}
		}


		var texFrame:FlxFrame = new FlxFrame(parent, angle, flipX, flipY, duration);
		texFrame.name = name;
		texFrame.sourceSize.set(sourceSize.x, sourceSize.y);
		texFrame.offset.set(offset.x, offset.y);
		texFrame.frame = frame;

		sourceSize = FlxDestroyUtil.put(sourceSize);
		offset = FlxDestroyUtil.put(offset);

		return pushFrame(texFrame);
	}

	public override function getIndexByName(name:String):Int
	{
		var frame = framesByName.get(name);
		if(frame == null) return -1;
		return frames.indexOf(framesByName.get(name));
	}
}
#end