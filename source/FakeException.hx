package;
import haxe.Exception;
class FakeException extends Exception{
	public function new(?msg:String = "FAKE EXCEPTION WITH NO MESSAGE",?previous:Null<haxe.Exception> = null,?native:Null<Any> = null){
		super(msg,previous,native);
	}
}