package onlinemod;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import flixel.util.FlxTimer;

import openfl.events.Event;
import openfl.events.ProgressEvent;
import openfl.events.IOErrorEvent;

import openfl.net.Socket;
import openfl.utils.ByteArray;
using StringTools;

class OnlinePlayMenuState extends ScriptMusicBeatState {
	var errorMessage:String;
	var errorColor:FlxColor;

	static var errorText:FlxText;
	static public var password:String;

	public static var socket:Socket;
	public static var receiver:Receiver;
	public static var muteKeys:Array<Int>;
	public static var volumeUpKeys:Array<Int>;
	public static var volumeDownKeys:Array<Int>;
	public static var scripts:Array<String> = [];
	public static var rawScripts:Array<Array<String>> = [];


	var ServerList:Array<Array<Dynamic>> = [];
	var AddServerButton:FlxUIButton;

	public function new(?message:String="", ?color:FlxColor=FlxColor.RED) {
		super();
		PlayState.invertedChart = false;
		PlayState.dadShow = true;
		OnlineLobbyState.clients = [];
		OnlinePlayState.autoDetPlayer2 = true;
		OnlinePlayState.useSongChar = ["","",""];
		errorMessage = message;
		errorColor = color;

		// if(OnlineHostMenu.socket != null){
		// 	OnlineHostMenu.shutdownServer();
		// }
		QuickOptionsSubState.setSetting("Song hscripts",false);
		scripts = [];
		rawScripts = [];
	}

	override function create()
	{
		TitleState.supported = false;
		var bg:FlxSprite = SELoader.loadFlxSprite('assets/images/menuDesat.png',true);
		bg.color = 0xFFFF6E6E;
		add(bg);

		var topText = new FlxText(0, FlxG.height * 0.05, "Connect to server");
		topText.setFormat(CoolUtil.font, 64, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		topText.screenCenter(FlxAxes.X);
		add(topText);

		errorText = new FlxText(0, FlxG.height * 0.175, FlxG.width, errorMessage);
		errorText.setFormat(CoolUtil.font, 32, errorColor, CENTER);
		add(errorText);
		SetErrorText(errorMessage, errorColor);

		AddServerButton = new FlxUIButton(0, 0, 'Add Server', () -> {
			openSubState(new onlinemod.OnlineAddServer());
		});
		AddServerButton.setLabelFormat(24, FlxColor.BLACK, CENTER);
		AddServerButton.resize(200, 75);
		AddServerButton.screenCenter(FlxAxes.X);
		add(AddServerButton);

		reloadServerList();

		AddXieneText(this);

		FlxG.mouse.visible = true;
		FlxG.autoPause = true;


		muteKeys = FlxG.sound.muteKeys;
		volumeUpKeys = FlxG.sound.volumeUpKeys;
		volumeDownKeys = FlxG.sound.volumeDownKeys;
		SetVolumeControls(true);

		disconnect();

		if(SESave.data.savedServers.length == 0) openSubState(new onlinemod.OnlineAddServer());

		scriptSubDirectory = "/onlineserverlist/";
		useNormalCallbacks = true;
		loadScripts(true);
		super.create();
	}
	public override function closeSubState(){
		reloadServerList();
		super.closeSubState();
	}

	public static function HandleData(packetId:Int, data:Array<Dynamic>) {
		switch (packetId) {
			case Packets.SEND_SERVER_TOKEN:
				// var serverToken:Int = data[0];
				// if (serverToken == Tokens.serverToken)
				// {
					Sender.SendPacket(Packets.SEND_PASSWORD, [password], socket);
					password = "";
				// }
				// else
				// {
				// 	SetErrorText("Failed to verify server. Make sure the server and client are up to date");
				// 	if (socket.connected)
				// 		socket.close();
				// }
			case Packets.HOSTEDSERVER:
				socket.endian = LITTLE_ENDIAN;
				Sender.SendPacket(Packets.SEND_PASSWORD, [password], socket);
				password = "";

			case Packets.PASSWORD_CONFIRM:
				switch (data[0])
				{
					case 0:
						if(OnlinePlayMenuState.errorText != null){
							SetErrorText("Correct password", FlxColor.LIME);
						}
						FlxG.switchState(new OnlineNickState());
					case 1:
						SetErrorText("Game already in progress");
					case 2:
						SetErrorText("Wrong password");
					case 3:
						SetErrorText("Game is already full");
				}
			default: return false;
		}
		return true;
	}

	public static function OnData(e:ProgressEvent){
		var data:ByteArray = new ByteArray();
		socket.readBytes(data);
		receiver.OnData(data);
	}

	public static function OnError(e:IOErrorEvent)
	{
		if (Type.getClass(FlxG.state) == OnlinePlayMenuState)
			return OnlinePlayMenuState.SetErrorText('Socket error: ${e.text}');
		FlxG.switchState(new OnlinePlayMenuState('Socket error: ${e.text}'));

	}

	public static function OnClose(e:Event)
	{
		if (Type.getClass(FlxG.state) == OnlinePlayMenuState)
			OnlinePlayMenuState.SetErrorText("Disconnected from server");
		else
			FlxG.switchState(new OnlinePlayMenuState("Disconnected from server"));
	}

	public static function RespondKeepAlive(packetId:Int,?force:Bool = false,?socket:Socket):Bool {
		if (!force && packetId != Packets.KEEP_ALIVE) return false; 
		Sender.SendPacket(Packets.KEEP_ALIVE, [], socket ?? OnlinePlayMenuState.socket);
		return true;
	}

	@:keep inline public static function disconnect(){
		if (socket != null){
			try{
				if(socket.connected) socket.close();
			}catch(e){}
			socket = null;
			QuickOptionsSubState.setSetting("Song hscripts",true);
			OnlineLobbyState.client = null;
		}

	}

	override function update(elapsed:Float) {
		if (controls.BACK) {
			disconnect();

			FlxG.switchState(new MainMenuState());
		}
		super.update(elapsed);
	}

	static function SetErrorText(text:String, ?color:FlxColor)
	{
		OnlinePlayMenuState.errorText.text = text;
		OnlinePlayMenuState.errorText.setFormat(32, color ?? FlxColor.RED);
		OnlinePlayMenuState.errorText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	}

	public static function SetVolumeControls(enabled:Bool)
	{
		if (enabled)
		{
			FlxG.sound.muteKeys = muteKeys;
			FlxG.sound.volumeUpKeys = volumeUpKeys;
			FlxG.sound.volumeDownKeys = volumeDownKeys;
		}
		else
		{
			FlxG.sound.muteKeys = null;
			FlxG.sound.volumeUpKeys = null;
			FlxG.sound.volumeDownKeys = null;
		}
	}

	public static function AddXieneText(state:FlxUIState)
	{
		var xieneText = new FlxText(0, FlxG.height - 30, "XieneDev");
		xieneText.setFormat(CoolUtil.font, 28, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		xieneText.screenCenter(FlxAxes.X);
		state.add(xieneText);
	}

	public static function Connect(IP:String,Port:String,?Password:String){
		try { 
			socket = new Socket();
			socket.timeout = 10000;
			socket.addEventListener(Event.CONNECT, (e:Event) -> {
				Sender.SendPacket(Packets.SEND_CLIENT_TOKEN, [Tokens.clientToken], socket);
			});
			socket.addEventListener(IOErrorEvent.IO_ERROR, OnError);
			socket.addEventListener(Event.CLOSE, OnClose);
			socket.addEventListener(ProgressEvent.SOCKET_DATA, OnData);
			receiver = new Receiver(HandleData);
			SESave.data.lastServer = IP;
			SESave.data.lastServerPort = Port;
			password = Password;
			socket.connect(IP, Std.parseInt(Port));
		}catch (e: Dynamic){
			trace(e);
		}
	}

	function reloadServerList()
	{
		if(ServerList.length > 0) for(Array in ServerList) for(thing in Array){remove(thing);thing.destroy();}
		ServerList = [];
		try{
		if(SESave.data.savedServers.length > 0){
			for(i in 0...SESave.data.savedServers.length){
				var _Server:Array<Dynamic> = [];
				var serverInfo:Array<Dynamic> = cast SESave.data.savedServers[i];

				ServerList.push(_Server);
				var BlackBox = new FlxSprite().makeGraphic(FlxG.width, 75, i % 2 == 0 ? 0x7F000000 : 0x7f3f3f3f);
				BlackBox.screenCenter();
				BlackBox.y += (BlackBox.height * i) - (BlackBox.height + (BlackBox.height * ((SESave.data.savedServers.length * 0.5) - 1.5)));
				_Server.push(add(BlackBox));

				var ServerIP = new FlxText(250, BlackBox.y + 5 , FlxG.width , 'Server: ${serverInfo[0]}:${serverInfo[1]}\nPassword: ${if(serverInfo[2] != null && serverInfo[2] != "")('').rpad('*',serverInfo[2].length) else "No password"}',24);
				_Server.push(add(ServerIP));

				var ConnectButton = new FlxUIButton(FlxG.width - 500, BlackBox.y + 11.25, 'Connect', () -> {
					Connect(serverInfo[0],serverInfo[1],serverInfo[2]);
				});
				ConnectButton.setLabelFormat(24, FlxColor.BLACK, CENTER);
				ConnectButton.resize(200, 50);
				_Server.push(add(ConnectButton));

				var RUSure = 0;
				var DeleteButton = new FlxUIButton(ConnectButton.x + ConnectButton.width + 25, ConnectButton.y, 'Delete Server', () -> {
					RUSure++;
					switch(RUSure){
						case 1:
							showTempmessage('Are you sure you\'d like to delete "${serverInfo[0]}"?',FlxColor.RED,2);
							new FlxTimer().start(2, function(tmr:FlxTimer){RUSure = 0;});
						case 2:
							SESave.data.savedServers.splice(i,1);
							reloadServerList();
					}
				});
				DeleteButton.setLabelFormat(18, FlxColor.BLACK, CENTER);
				DeleteButton.resize(100, 50);
				_Server.push(add(DeleteButton));

				if(serverInfo[2] != null && serverInfo[2] != ""){
					var hide = true;
					var TogglePassword = new FlxUIButton(DeleteButton.x + DeleteButton.width + 25, ConnectButton.y, 'Toggle Password', () -> {
						hide = !hide;
						ServerIP.text = 'Server: ${serverInfo[0]}:${serverInfo[1]}\nPassword: ${(if(hide) ('').rpad('*',serverInfo[2].length) else serverInfo[2])}';
					});
					TogglePassword.setLabelFormat(18, FlxColor.BLACK, CENTER);
					TogglePassword.resize(110, 50);
					_Server.push(add(TogglePassword));
					
				}
			}
		}
		}catch(e){
			showTempmessage("Something went wrong while create a server list",FlxColor.RED);
			trace(e);
		}
		try{AddServerButton.y = ServerList[ServerList.length - 1][0].y + 100;}catch(e){AddServerButton.screenCenter(FlxAxes.Y);}// i have no idea why if isn't working
	}
}
