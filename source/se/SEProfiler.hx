package se;

import flixel.math.FlxMath;


class SEProfiler{
	public static var enabled:Bool = false;
	public static var list:Map<String,Profiler> = [];
	@:keep inline public static function init(){
		getProfiler('update',true);
		getProfiler('draw',true);

	}
	@:keep inline public static function update(){
		if(!enabled) return;
		for(index => profiler in list){
			if(profiler == null) continue;
			if(profiler.update()) list[index] = null;
		}
	}

	@:keep inline public static function add(p:Profiler):Profiler{
		return list[p.name]=p;
	}
	@:arrayAccess
	@:keep inline public static function getProfiler(name:String,?keep:Bool = false):Profiler{
		return list[name] ?? (list[name] = new Profiler(name,keep));
	}
	@:arrayAccess
	@:keep inline public static function setProfiler(name:String,p:Profiler){
		return (enabled ? list[name] = p : null);
	}
	
	
	@:keep inline public static function qStamp(name:String){
		if(enabled) getProfiler(name).stamp();
	}
	@:keep inline public static function qStart(name:String){
		if(enabled) getProfiler(name).start();
	}


	@:keep inline public static function stamp(name:String){
		if(enabled) list[name]?.stamp();
	}
	@:keep inline public static function start(name:String){
		if(enabled) list[name]?.start();
	}
	public static function getString():String{
		if(!enabled) return "";
		var ret = "\nProfiler(Time/Max)";
		for(index => profiler in list){
			if(profiler == null) continue;
			ret+='\n $index - ${profiler._end}/${profiler.max}';
		}
		return ret;

	}
}
@:publicFields class Profiler {
	var name:String = "";
	var _start:Float = 0;
	var _end:Float = 0;
	var max:Float = 0;
	var ticks:Int = 0;
	var keep = false;
	// We use ticks instead of time, using time would make a lagspike invalidate every profiler
	var ticksSinceUpdate:Int = 0; 
	function new(_name:String,?_keep:Bool=false){
		name=_name;
		keep=_keep;
	}
	@:keep inline function start(){
		_start = Sys.cpuTime();
		ticksSinceUpdate=0;
	}
	// TODO If this doesn't do anything extra soon, i'll remove the useless if and just make it return the check
	@:keep inline function update():Bool{
		ticksSinceUpdate++;
		if(!keep && ticksSinceUpdate > 120){
			return true;
		}
		// average = Math.lerp(average,end,0.5);
		return false;
	}
	@:keep inline function stamp(){
		ticksSinceUpdate=0;
		_end = Math.floor((Sys.cpuTime()-_start) * 100000)*0.00001;
		if(max < _end) max=_end;
		// average = Math.floor(FlxMath.lerp(average,_end,0.5)*10000)*0.0001;
	}

}