package onlinemod;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIButton;
import SEInputText as FlxInputText;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import openfl.events.Event;
import openfl.events.ProgressEvent;
import openfl.events.IOErrorEvent;

import openfl.net.Socket;
import openfl.net.ServerSocket;
import openfl.utils.ByteArray;
import openfl.events.ServerSocketConnectEvent;
import openfl.utils.Endian;

@:structInit class ConnectedPlayer {
	public var nick:String;
	public var socket:Socket;
	public var receiver:Receiver;
	public var admin:Bool = false;
	public var afk:Bool = false;
	public var alive:Bool = true;
	public var muted:Bool = false;


}


class OnlineHostMenu extends ScriptMusicBeatState
{
	public static var instance:OnlinePlayMenuState;
	var errorText:FlxText;
	var portField:FlxInputText;
	var pwdField:FlxInputText;
	@:keep inline public static var socket(get,set):ServerSocket;
	@:keep inline function get_socket() return SEServer.socket;
	@:keep inline function set_socket(vari) return SEServer.socket = vari;
	public static var connectedPlayers(get,set):Array<ConnectedPlayer> = [];
	@:keep inline function get_connectedPlayers() return SEServer.connectedPlayers;
	@:keep inline function set_connectedPlayers(vari) return SEServer.connectedPlayers = vari;
	public static var clientsFromNames(get,set):Map<String,Null<Int>> = [];
	@:keep inline function get_clientsFromNames() return SEServer.clientsFromNames;
	@:keep inline function set_clientsFromNames(vari) return SEServer.clientsFromNames = vari;
	public static var serverVariables(get,set):Map<Dynamic,Dynamic>;
	@:keep inline function get_serverVariables() return SEServer.serverVariables;
	@:keep inline function set_serverVariables(vari) return SEServer.serverVariables = vari;

	@:keep inline public static function shutdownServer() {
		SEServer.shutdownServer()
	}
	override function create() {
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image("menuDesat"));
		bg.color = 0xFFea71fd;
		add(bg);


		var topText = new FlxText(0, FlxG.height * 0.15, "Host server");
		topText.setFormat(CoolUtil.font, 64, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		topText.screenCenter(FlxAxes.X);
		add(topText);


		errorText = new FlxText(0, FlxG.height * 0.275, FlxG.width, "");
		errorText.setFormat(CoolUtil.font, 32, FlxColor.WHITE, CENTER);
		add(errorText);


		var portText:FlxText = new FlxText(FlxG.width/2 - 350, FlxG.height * 0.4 - 40, "Port:");
		portText.setFormat(CoolUtil.font, 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(portText);

		portField = new FlxInputText(0, FlxG.height * 0.4, 700, 32);
		portField.setFormat(32, FlxColor.BLACK, CENTER);
		portField.screenCenter(FlxAxes.X);
		portField.customFilterPattern = ~/[^0-9]/;
		portField.text = "8000";
		portField.maxLength = 6;
		portField.hasFocus = true;
		add(portField);


		var pwdText:FlxText = new FlxText(FlxG.width/2 - 350, FlxG.height * 0.6 - 40, "Password:");
		pwdText.setFormat(CoolUtil.font, 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(pwdText);

		pwdField = new FlxInputText(0, FlxG.height * 0.6, 700, 32);
		pwdField.setFormat(32, FlxColor.BLACK, CENTER);
		pwdField.screenCenter(FlxAxes.X);
		pwdField.passwordMode = false;
		add(pwdField);


		var hostButton = new FlxUIButton(0, FlxG.height * 0.75, "Host", () -> {
			try{
				serverVariables = new Map<Dynamic,Dynamic>();
				serverVariables["password"] = pwdField.text;
				var socket = new ServerSocket();
				socket.bind(Std.parseInt(portField.text));
				if(!socket.bound){
					SetErrorText('Unable to bind to port ${portField.text}. Is it already in use or too low?');
					return;
				}
				connectedPlayers = [];
				clientsFromNames = [];
				socket.addEventListener(Event.CONNECT, (e:ServerSocketConnectEvent) -> {
					var ID = connectedPlayers.length;
					connectedPlayers[ID] = {
						socket:e.socket,
						receiver:new Receiver(SEServer.HandleData.bind(ID,_,_)),
						nick:"OUTDATED",
						admin:(ID == 0)
					}
					trace('New connection! ${e.socket}');
					var socket = e.socket;
					socket.endian = LITTLE_ENDIAN;
					socket.addEventListener(IOErrorEvent.IO_ERROR, SEServer.OnErrorSocket.bind(ID,_));
					socket.addEventListener(Event.CLOSE, SEServer.OnCloseSock.bind(ID,_));
					socket.addEventListener(ProgressEvent.SOCKET_DATA, SEServer.OnData.bind(ID,_));
				});
				socket.addEventListener(IOErrorEvent.IO_ERROR, SEServer.OnError);
				socket.addEventListener(Event.CLOSE, SEServer.OnClose);
				// socket.addEventListener(ProgressEvent.SOCKET_DATA, OnData);
				socket.listen(12);
				OnlineHostMenu.socket = socket;
				// Literally just code from OnlinePlayMenu
				var socket = new Socket();
				socket.timeout = 10000;
				// socket.endian = LITTLE_ENDIAN;
				socket.addEventListener(Event.CONNECT, (e:Event) -> {
					Sender.SendPacket(Packets.SEND_CLIENT_TOKEN, [Tokens.clientToken], socket);
				});
				socket.addEventListener(IOErrorEvent.IO_ERROR, OnlinePlayMenuState.OnError);
				socket.addEventListener(Event.CLOSE, OnlinePlayMenuState.OnClose);
				socket.addEventListener(ProgressEvent.SOCKET_DATA, OnlinePlayMenuState.OnData);
				var receiver = new Receiver(OnlinePlayMenuState.HandleData);
				OnlinePlayMenuState.receiver = receiver;
				OnlinePlayMenuState.socket = socket;
				OnlinePlayMenuState.password = pwdField.text;
				socket.connect("localhost", Std.parseInt(portField.text));

			}catch(e){
				shutdownServer();
				SetErrorText("Error occurred while creating socket! " + e.message);
			}
		});
		hostButton.setLabelFormat(32, FlxColor.BLACK, CENTER);
		hostButton.resize(300, FlxG.height * 0.1);
		hostButton.screenCenter(FlxAxes.X);
		add(hostButton);


		FlxG.mouse.visible = true;


		super.create();
	}

	override function update(elapsed:Float) {
		if (controls.BACK) {
			FlxG.switchState(new MainMenuState());
		}
		

		super.update(elapsed);
	}

	function SetErrorText(text:String, color:FlxColor=FlxColor.RED)
	{
		errorText.text = text;
		errorText.setFormat(32, color);
		errorText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	}

	static function OnError(e:IOErrorEvent) {
		shutdownServer();
		FlxG.switchState(new OnlinePlayMenuState('Socket error: ${e.text}'));
	}
}
