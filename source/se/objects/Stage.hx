package se.objects;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.FlxState;
import flixel.FlxSprite;

class Stage extends FlxGroup{
	public var objects:Array<Dynamic<FlxObject>> = [];
	public var bfPos:Array<Float> =  [0,0];
	public var dadPos:Array<Float> = [0,0];
	public var gfPos:Array<Float> =  [0,0];
	public var tags:Array<String> = [];
	public var jsonFile:String;
	public var showGF:Bool = true;
	public var defaultCamZoom:Float = 1.05;
	public var name:String = "";
	public function apply(state:FlxState){
		// state.add(this);

	}
}
class BaseStage extends Stage{

	public function new(?simple:Bool = false){
		super();
		defaultCamZoom = 0.9;
		name = 'stage';
		tags = ["inside","stage"];
		if(simple) {
			tags.push('performance');
			tags.push('simple');
		}else {
			var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('stageback'));
			bg.antialiasing = true;
			bg.scrollFactor.set(0.9, 0.9);
			bg.active = false;
			add(bg);
		}
		var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront'));
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		stageFront.antialiasing = true;
		stageFront.scrollFactor.set(0.9, 0.9);
		stageFront.active = false;
		add(stageFront);
		if(!simple){
			var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image('stagecurtains'));
			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
			stageCurtains.updateHitbox();
			stageCurtains.antialiasing = true;
			stageCurtains.scrollFactor.set(1.3, 1.3);
			stageCurtains.active = false;

			add(stageCurtains);
		}
	}
}