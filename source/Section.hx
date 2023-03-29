package;
 
typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var ?lengthInMS:Float; // ms better than steps, only used for restructuring a chart
	var ?lengthInSteps:Int;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var ?scrollSpeed:Float;
	var bpm:Float;
	var changeBPM:Bool;
	var ?altAnim:Bool;
}

class Section
{
	public var sectionNotes:Array<Dynamic> = [];

	public var lengthInSteps:Float = 16;
	public var typeOfSection:Int = 0;
	public var mustHitSection:Bool = true;

	/**
	 *	Copies the first section into the second section!
	 */
	public static var COPYCAT:Int = 0;

	public function new(lengthInSteps:Int = 16)
	{
		this.lengthInSteps = lengthInSteps;
	}
}
