package se.states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import openfl.media.Sound;
import lime.media.AudioBuffer;
import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import flixel.util.FlxTimer;

import haxe.io.Bytes;
import openfl.utils.ByteArray;
import openfl.net.Socket;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;
// import openfl.filesystem.File;
// import openfl.filesystem.FileStream;
import lime.net.HTTPRequest;
import openfl.events.Event;
import openfl.events.ProgressEvent;
import openfl.events.IOErrorEvent;

class DownloadState extends MusicBeatState
{
	public var loadingText:FlxText;
	public var fileSizeText:FlxText;
	public var loadingBar:FlxBar;
	public var progress:Float = 0;
	public var url:String= "";
	public var path:String = "";
	public var callback:Dynamic->Void;
	public var exitCallback:Void->Void = function(){
		FlxG.switchState(new MainMenuState());
	};
	public var socket:HTTPRequest<Bytes>;
	public var file:File;
	public var output:FileOutput;
	public var canClose:Bool = true;

	public function new(url:String, path:String, callback:Dynamic->Void,?exitCallback:Void->Void)
	{
		super();

		this.url = url;

		this.callback = callback;
		this.exitCallback = exitCallback;
		this.path = path;
	}

	override function create()
	{
		var bg:FlxSprite = SELoader.loadFlxSprite('assets/images/onlinemod/online_bg2.png',true);
		add(bg);


		loadingText = new FlxText(FlxG.width/4, FlxG.height/2 - 36, FlxG.width, "Waiting...");
		loadingText.setFormat(CoolUtil.font, 28, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(loadingText);


		fileSizeText = new FlxText(FlxG.width/4, FlxG.height/2 - 32, FlxG.width/2, "?/?");
		fileSizeText.setFormat(CoolUtil.font, 24, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fileSizeText);


		loadingBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 640, 10, this, 'progress', 0, 1);
		loadingBar.createFilledBar(FlxColor.RED, FlxColor.LIME, true, FlxColor.BLACK);
		loadingBar.screenCenter(FlxAxes.XY);
		add(loadingBar);


		super.create();
		canClose = false;
		output = SELoader.write(path);
		socket = new HTTPRequest<Bytes>(url);
		socket.load(url).onComplete(onData).onProgress(updateProgress).onError(onError);
		// socket = new Socket();
		// socket.addEventListener(ProgressEvent.SOCKET_DATA,onData);
		// socket.addEventListener(IOErrorEvent.IO_ERROR,onIOError);
		// socket.addEventListener(Event.CLOSE,onClose);
		// socket.connect(url);

	}
	// public dynamic function onClose(e:Event){
	// 	if(canClose) return;
	// 	try{

	// 		output.close();
	// 	}catch(e){}
	// 	callback(e);
	// 	try{
	// 		socket.close();
	// 	}catch(e){}
	// }
	public dynamic function onError(e:Dynamic){
		try{
			output.close();
		}catch(e){}
		inError=true;
		progress = 0;
		fileSizeText.text = "";
		loadingText.text = 'Error! Press any key to exit\n\n${e ?? "Unknown error??"}';
		trace('Error! ${e} ${Type.typeof(e)}');
		canClose = true;
	}
	// public dynamic function onIOError(e:IOErrorEvent){
	// 	try{
	// 		output.close();
	// 		socket.close();
	// 	}catch(e){}
	// 	fileSizeText.text = 'Error! ${e.text}\n\n Press any key to exit';
	// 	trace('Error! ${e.text}');
	// 	canClose = true;
	// }
	public var inError:Bool =false;
	public dynamic function onData(bytes:Bytes){

		fileSizeText.text =  "Writing to file";
		output.writeBytes(bytes,0,bytes.length);
		output.close();
		fileSizeText.text =  "Finished.";
		try{
			loadingText.text = 'Finished, Press any key to exit..';
			canClose = true;
			callback(null);
		}catch(e){
			fileSizeText.text = "";
			loadingText.text = 'Error! Press any key to exit\n\n${e.details()}\n${e.stack}';
			inError=true;
			progress = 0;
			trace('Error! ${e.details()}\n ${e.stack}');
		}

	}
	// public dynamic function onData(e:ProgressEvent){
	// 	var data:ByteArray = new ByteArray();
	// 	socket.readBytes(data);

	// 	output.writeBytes(data,output.position,data.bytesAvailable);
	// 	updateProgress(e.bytesLoaded,e.bytesTotal);
	// }
	function updateProgress(bytesReceived:Float,fileSize:Float){
		progress = Math.min(1, bytesReceived / fileSize);

		if (fileSize > 1000000) { //MB
			fileSizeText.text = Std.int(bytesReceived/10000)/100 + "/" + Std.int(fileSize/10000)/100 + "MB";
		} else {//KB
			fileSizeText.text =  Std.int(bytesReceived/10)/100 + "/" + Std.int(fileSize/10)/100 + "KB";
		}
	}
	var errEl:Float = 0;
	override function update(elapsed:Float) {

		if(canClose || inError){
			if(FlxG.keys.justPressed.ANY){
				exitCallback();
			}
		}
		if(inError && SESave.data.flashing){
			errEl+=elapsed;
			progress = (errEl % 1 > 0.5 ? 1 : 0);
		}

		super.update(elapsed);
	}

}
