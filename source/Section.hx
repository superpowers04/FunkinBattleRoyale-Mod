package;
 
typedef SwagSection ={
	var sectionNotes:Array<Array<Dynamic>>;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var ?lengthInMS:Float; // ms better than steps, only used for restructuring a chart
	var ?lengthInSteps:Int;
	var ?centerCamera:Bool;
	var ?scrollSpeed:Float;
	var ?changeBPM:Bool;
	var ?altAnim:Bool;
	var ?bpm:Float;
}
