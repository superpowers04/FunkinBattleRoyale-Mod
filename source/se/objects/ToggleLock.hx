package se.objects;

#if(target.threaded) 
import sys.thread.*;

class ToggleLock extends Lock{
	public function lock(){
		locked = true;
	}
	public var locked:Bool = false;
	public var locks:Int = 0;
	override public function wait(?timeout:Float){
		if(!locked) return true;
		trace('waiting for unlock :3333 ');
		locks++;
		return super.wait(timeout);
	}

	override public function release(){
		locked = false;
		while (locks > 0){
			super.release();
			locks--;
		}
	}
}
class RenderToggleLock extends ToggleLock{
	override public function wait(?timeout:Float){
		if(!SESave.data.doCoolLoading) return true;
		return super.wait(timeout);
	}
}
#else
class ToggleLock{
	public function lock() return;
	public var locked:Bool = false;
	@:keep inline public override function wait(?timeout:Float) return true;

	@:keep inline public override function release() return;
}
#end