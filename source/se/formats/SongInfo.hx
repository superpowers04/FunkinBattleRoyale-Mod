package se.formats;

@:publicFields @:structInit class SongInfo {
	var isCategory:Bool = false;
	var name:String = "";
	var charts:Array<String>;
	// By default, these are literally just path + "FILE.ogg", there's no reason to store path 3 seperate fucking times :skul:
	@:optional var internal_voices:String = "";
	@:optional var internal_inst:String = "";
	var voices(get,default):String = "";
	function get_voices() return voices == "" ? path+'Voices.ogg' : voices;
	var inst(get,default):String = "";
	function get_inst() return inst == "" ? path+'Inst.ogg' : inst;

	var path:String = "";
	var namespace:String = null;
	@:optional var categoryID:Int = 0;
	function chartExists(){
		return charts[0] != null && SELoader.exists(path +'/'+charts[0]);
	}
	function instExists(){
		return SELoader.exists(inst);
	}
	function toString() {return 'Song <$name>';}
	function new(name:String="",charts:Array<String>,path:String="",?namespace:String=null,?isCategory:Bool=false,?categoryID:Int=0){
		this.name = name;
		this.charts = charts;
		this.path = path;
		this.namespace = namespace;
		this.isCategory = isCategory;
		this.categoryID=categoryID;
	}
}
