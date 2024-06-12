package se.objects;

import flixel.sound.FlxSound;

// We literally only extend FlxObject so you can add this as a normal object to a FlxState/FlxGroup for updating
@:publicFields class SEJoinedSound extends FlxBasic { 
	var sounds:Array<FlxSound> = [];
	var sound(get,set):FlxSound;
	@:keep inline function get_sound(){
		return sounds[0];
	}
	@:keep inline function set_sound(s:FlxSound){
		return sounds[0]=s;
	}
	var syncVolume:Bool = false;
	var syncTime:Bool = true;
	var maxTimeDifference:Int=5;
	var syncPlaying:Bool = true;
	var syncGroup:Bool = false;

	function new(?initialSound:FlxSound = null){
		super();
		if(initialSound != null){
			sounds[0]=initialSound;
		}
	}
	function update(?e:Float){
		sync();
	}
	function draw(){}

	function sync(){
		var sound = sound;
		if(!sound.playing) return;
		var i = sounds.length;
		while(i > 0){
			var s = sounds[i];
			if(syncVolume) s.volume = sound.volume;
			if(syncPlaying && s.playing != sound.playing){
				if(sound.playing) s.play();
				else s.pause();
			}
			if(s.playing && syncTime && Math.abs(s.time,sound.time) > maxTimeDifference) s.time = sound.time;

		}
	}
	function add(s:FlxSound):FlxSound{
		sounds.push(s);
		if(syncGroup) s.group = sound.group;
		sync();
		return s;
	}
	function remove(sound:FlxSound):FlxSound{
		sounds.remove(sound);
		return sound;
	}



	// Shadowed Variables/Functions. This shit is dumb tbh
	function stop() for(sound in sounds) sound.stop();
	function start() for(sound in sounds) sound.start();
	function pause() for(sound in sounds) sound.pause();
	var volume(get,set):Float;
	function get_volume() return sound.volume;
	function set_volume(v) for(sound in sounds) {sound.volume=v;} return v;
	var loopTime(get,set):Float;
	function get_loopTime() return sound.loopTime;
	function set_loopTime(v) for(sound in sounds) {sound.loopTime=v;} return v;
	var endTime(get,set):Float;
	function get_endTime() return sound.endTime;
	function set_endTime(v) for(sound in sounds) {sound.endTime=v;} return v;
	var time(get,set):Float;
	function get_time() return sound.time;
	function set_time(v) for(sound in sounds) {sound.time=v;} return v;
	#if FLX_PITCH
	var pitch(get, set):Float;
	function get_pitch() return sound.pitch;
	function set_pitch(v) for(sound in sounds) {sound.pitch=v;} return v;
	#end

	var looped(get,set):Bool;
	function get_looped() return sound.looped;
	function set_looped(v) for(sound in sounds) {sound.looped=v;} return v;
	var playing(get,set):Bool;
	function get_playing() return sound.playing;
	function set_playing(v) for(sound in sounds) {(v?sound.play():sound.pause());} return v;
	var autoDestroy(get,set):Bool;
	function get_autoDestroy() return sound.autoDestroy;
	function set_autoDestroy(v) for(sound in sounds) {sound.autoDestroy=v;} return v;

	var onComplete(get,set):Void->Void;
	function get_onComplete() return sound.onComplete;
	function set_onComplete(v) return sound.onComplete=v;
	var group(get, set):FlxSoundGroup;
	function get_group() return sound.group;
	function set_group(v) for(sound in sounds) {sound.group=v;} return v;

	

}