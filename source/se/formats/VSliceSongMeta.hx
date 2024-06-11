package se.formats;

typedef VSlicePlayData = {
	var songVariations:Array<String>; // This'll probably never be used since SE uses dynamic generation for chat listings
	var characters:VSliceChartCharacters;
	var difficulties:Array<String>
	var stage:String;
}

typedef VSliceSongMeta = {
	var version:String;
	var artist:String;
	var playData:VSlicePlayData;
	var songName:String;
	var timeFormat:String;
	var timeChanges:Array<TimeChange>
}
typedef VSliceChart = {
	var scrollSpeed:Map<String,Float>;
	var events:Array<VEvent>;
	var notes:Map<String,Array<VNote>>;
}
typedef VSliceChartCharacters = {
	var bf:String;
	var girlfriend:String;
	var opponent:String;
}
typedef TimeChange = {
	var t:Float;
	var bpm:Float;
}
typedef VNote = {
	var t:Float; // Time 
	var l:Float; // Length
	var d:Float; // Data
	var k:String; // Type
}
typedef VEvent = {
	var e:String; // Event
	var t:Float; // Time 
	var v:Dynamic; // Value
}