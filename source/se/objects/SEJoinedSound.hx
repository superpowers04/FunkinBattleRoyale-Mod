package se.objects;

import flixel.sound.FlxSound;
import flixel.sound.FlxSoundGroup;
import flixel.FlxBasic;
import flixel.FlxG;

// We literally only extend FlxObject so you can add this as a normal object to a FlxState/FlxGroup for updating
@:publicFields class SEJoinedSound extends FlxBasic { 
	var sounds:Array<FlxSound> = [];
	var syncedSound:FlxSound;
	var sound(get,set):FlxSound;

	@:keep inline function get_sound(){
		return sounds[0];
	}
	@:keep inline function set_sound(s:FlxSound){
		return sounds[0]=s;
	}
	var length(get,null):Int;
	@:keep inline function get_length(){
		return sounds.length;
	}

	var syncVolume:Bool = false;
	var syncTime:Bool = true;
	var maxTimeDifference:Int=5;
	var syncPlaying:Bool = true;
	var syncGroup:Bool = true;

	function new(?initialSound:FlxSound = null){
		super();
		if(initialSound != null){
			sounds[0]=initialSound;
		}
	}
	override function update(e:Float){
		sync();
		super.update(e);
	}
	override function draw(){}
	function clear(){
		if(length == 0) return;
		for(song in sounds){
			song.destroy();
		}
		sounds = [];
	}
	override function destroy(){
		for(song in sounds){
			song.destroy();
		}
		super.destroy();
	}

	function sync(){
		if(length == 0) return;
		final sound = sound;
		if(!sound.playing) {
			var i = sounds.length-1;
			while(i > 0){
				var s = sounds[i];
				i--;
				if(syncPlaying && s.playing){
					s.pause();
				}
			}
			return;
		}
		var i = sounds.length-1;
		while(i > 0){
			var s = sounds[i];
			i--;
			if(syncVolume) s.volume = sound.volume;
			if(syncPlaying && s.playing != sound.playing){
				if(sound.playing) s.play();
				else s.pause();
			}
			if(s.playing && syncTime && sound.time <= s.length && Math.abs(s.time-sound.time) > maxTimeDifference) s.time = sound.time;

		}
	}
	function syncToSound(sound:FlxSound){
		final s = syncedSound ?? this.sound;
		if(s == null) return;
		if(syncVolume) s.volume = sound.volume;
		if(syncPlaying && s.playing != sound.playing && sound.time <= s.length){
			if(sound.playing) s.play();
			else s.pause();
		}
		if(s.playing && syncTime && sound.time <= s.length  && Math.abs(s.time-sound.time) > maxTimeDifference) s.time = sound.time;
		sync();
	}
	@:keep inline function load(path:String):FlxSound{
		return add(SELoader.loadFlxSound(path));
	}
	function add(s:FlxSound):FlxSound{
		sounds.push(s);
		if(syncGroup) s.group = sound.group;
		if(!FlxG.sound.list.members.contains(s)) FlxG.sound.list.add(s);
		sync();
		return s;
	}
	function remove(sound:FlxSound):FlxSound{
		sounds.remove(sound);
		return sound;
	}
	function setVolume(index:Int,volume:Float):Float{
		if(length == 0) return 0;
		return (sounds[index] is FlxSound ? sounds[index] : sound).volume = volume;
	}

	function getVolume(index:Int):Float{
		if(length == 0) return 0;
		return (sounds[index] is FlxSound ? sounds[index] : sound).volume;
	}



	// Shadowed Variables/Functions. This shit is dumb tbh
	function stop() {
		if(length == 0) return;
		for(sound in sounds) sound.stop();
		sync();
	}
	// function start() for(sound in sounds) sound.start();s
	function play() {
		if(length == 0) return;
		for(sound in sounds) sound.play();
		sync();
	}
	function pause() {
		if(length == 0) return;
		for(sound in sounds) sound.pause();
		sync();
	}
	var volume(get,set):Float;
	function get_volume() return sound?.volume;
	function set_volume(v) {for(sound in sounds) {sound.volume=v;} return v;}
	var loopTime(get,set):Float;
	function get_loopTime() return sound?.loopTime;
	function set_loopTime(v) {for(sound in sounds) {sound.loopTime=v;} return v;}
	var endTime(get,set):Float;
	function get_endTime() return sound?.endTime;
	function set_endTime(v) {for(sound in sounds) {sound.endTime=v;} return v;}
	var time(get,set):Float;
	function get_time() return sound?.time;
	function set_time(v) {for(sound in sounds) {sound.time=v;} return v;}
	#if FLX_PITCH
	var pitch(get, set):Float;
	function get_pitch() return sound?.pitch;
	function set_pitch(v) {for(sound in sounds) {sound.pitch=v;} return v;}
	#end

	var looped(get,set):Bool;
	function get_looped() return sound?.looped;
	function set_looped(v) {for(sound in sounds) {sound.looped=v;} return v;}
	var playing(get,set):Bool;
	function get_playing() return sound?.playing;
	function set_playing(v) {for(sound in sounds) {(v?sound.play():sound.pause());} return v;}
	var autoDestroy(get,set):Bool;
	function get_autoDestroy() return sound?.autoDestroy;
	function set_autoDestroy(v) {for(sound in sounds) {sound.autoDestroy=v;} return v;}

	var onComplete(get,set):Void->Void;
	function get_onComplete() return sound?.onComplete;
	function set_onComplete(v) return sound.onComplete=v;
	var group(get, set):FlxSoundGroup;
	function get_group() return sound?.group;
	function set_group(v) {for(sound in sounds) {sound.group=v;} return v;}

	

}