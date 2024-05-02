package onlinemod;

import openfl.net.Socket;

@:publicFields @:structInit class Player{
	var id:Int = 0;
	var name:String = "N/A";
	var score:Int = 0;
	var scoreText:String = "N/A";
	var self:Bool = false;
	var admin:Bool = false;
	var currentStateInfo:Array<Dynamic>;
	var disconnected:Bool = false;
	function toString() return name;
	function new(name:String,id:Int){
		this.name = name;
		this.id = id;
	}
}
@:publicFields@:structInit class ConnectedPlayer {
	var nick:String;
	var socket:Socket;
	var receiver:Receiver;
	var admin:Bool = false;
	var self:Bool = false;
	var afk:Bool = false;
	var alive:Bool = true;
	var muted:Bool = false;
}