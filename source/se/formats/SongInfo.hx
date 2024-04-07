package se.formats;

@:keep @:publicFields @:structInit class SongInfo {
	var isCategory:Bool = false;
	var name:String = "";
	var charts:Array<String>;
	// By default, these are literally just path + "FILE.ogg", there's no reason to store path 3 seperate fucking times :skul:
	@:optional var internalVoices:String = "";
	@:optional var internalInst:String = "";
	@:optional var voices(get,set):String;
	@:optional var inst(get,set):String;
	function get_voices(){
		return internalVoices == "" ? path+'Voices.ogg' : internalVoices;
	}
	function set_voices(vari:String){
		return internalVoices = vari;
	}
	function get_inst(){
		return internalInst == "" ? path+'Inst.ogg' : internalInst;
	}
	function set_inst(vari:String){
		return internalInst = vari;
	}
	// var voices(get,set):String;
	// function get_voices() return internal_voices == "" ? path+'Voices.ogg' : internal_voices;
	// function set_voices(val:String) return internal_voices = val;
	// var inst(get,set):String;
	// function get_inst() return internal_inst == "" ? path+'Inst.ogg' : internal_inst;
	// function set_inst(val:String) return internal_inst = val;
	var path:String = "";
	var namespace:String;
	@:optional var categoryID:Int = 0;
	function chartExists(){
		return charts[0] != null && SELoader.exists(path +'/'+charts[0]);
	}
	function instExists(){
		return SELoader.exists(inst);
	}
	function toString() {return 'Song <$name>';}
	function new(){}
}
