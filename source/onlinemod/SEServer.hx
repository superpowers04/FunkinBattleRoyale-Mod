package onlinemod;
import openfl.events.Event;
import openfl.events.ProgressEvent;
import openfl.events.IOErrorEvent;

import openfl.net.Socket;
import openfl.net.ServerSocket;
import openfl.utils.ByteArray;
import openfl.events.ServerSocketConnectEvent;
import openfl.utils.Endian;
import onlinemod.Player;
import flixel.FlxG;
import onlinemod.Packets;

@:publicFields @:structInit class Command {
	// var name:String;
	var description:String;
	var execute:(ConnectedPlayer,String,Array<String>)->Void;
	@:optional var admin = false;

}

class SEServer{
	public static var instance:SEServer;
	public static var socket:ServerSocket;
	public static var connectedPlayers:Array<ConnectedPlayer> = [];
	public static var clientsFromNames:Map<String,Null<Int>> = [];
	public static var serverVariables:Map<Dynamic,Dynamic>;
	public static var prefix:String = "!";


	public static function createServer(port){
		var socket = new ServerSocket();
		socket.bind(port);
		if(!socket.bound){
			throw('Unable to bind to port ${port}. Is it already in use or too low?');
			return;
		}
		instance = new SEServer();
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
		SEServer.socket = socket;
	}

	/* Packets, this should probably be handled elsewhere but whatever ig*/
	/* TODO: ADD SCRIPT SUPPORT */
	public static function HandleData(socketID:Int,packetId:Int, data:Array<Dynamic>) {	
		var player = connectedPlayers[socketID];
		var socket = player.socket;
		var pktName:String = 'Unknown ID ${packetId}';
		if(Packets.PacketsShit.fields[packetId] != null){
			pktName = Packets.PacketsShit.fields[packetId].name;
		}
		trace('${socketID}: Recieved ${pktName}');
		try{
			switch (packetId) {
				case Packets.SEND_CLIENT_TOKEN:
					// This will always be jumbled, Send the hosted server packet, 
					//  this'll automatically kick the client if unsupported since it's an entirely new packet :3
					Sender.SendPacket(Packets.HOSTEDSERVER, [], socket);
				case Packets.SEND_PASSWORD:
					player.nick = "Unspecified";
					if(data[0] == null) data[0] = "";
					Sender.SendPacket(Packets.PASSWORD_CONFIRM, [(data[0] == serverVariables["password"] ? 0 : 1)], socket);
					if(data[0] != serverVariables["password"]) closeSocket(socketID);
				case Packets.SEND_NICKNAME:
					if(data[0] == "unspecified" || clientsFromNames[data[0]] != null){
						Sender.SendPacket(Packets.NICKNAME_CONFIRM, [1], socket);
						return true;
					}
					clientsFromNames[data[0]] = socketID;
					if(socketID==0){
						player.self=player.admin=true;
					}
					player.nick = data[0];
					trace('${socketID}: registered as ${player.nick}');
					Sender.SendPacket(Packets.NICKNAME_CONFIRM, [0], socket);
					broadcastToAllClients(Packets.BROADCAST_NEW_PLAYER,[socketID,player.nick],player);
				
				case Packets.JOINED_LOBBY:
					Sender.SendPacket(Packets.SERVER_CHAT_MESSAGE,['Hosting is not currently finished, nothing besides chatting is implemented at the moment..'],socket);
					Sender.SendPacket(Packets.SERVER_CHAT_MESSAGE,["'ceabf544' This is a compatibility message, Ignore me!"],socket);
				case Packets.SEND_CHAT_MESSAGE:{
					if(player != null && data[1] is String && data[1].substring(0,prefix.length) == prefix){
						try{
							handleCommand(player,socket,data[1]);
						}catch(e){
							Sender.SendPacket(Packets.SERVER_CHAT_MESSAGE,['An error occured while processing this command!'],socket);
							if(player.admin){
								Sender.SendPacket(Packets.SERVER_CHAT_MESSAGE,['${e.details()}'],socket);
							}
							trace(e);
						}
						return true;
					}
					for (playerObject in connectedPlayers){
						if(playerObject.socket == null || playerObject == player) continue;
						Sender.SendPacket(Packets.BROADCAST_CHAT_MESSAGE,data,playerObject.socket);
					}
				}
				/* TODO IMPLEMENT FILE SENDING*/
				case Packets.REQUEST_INST | Packets.REQUEST_VOICES:
					Sender.SendPacket(Packets.DENY,[],player.socket);

			}
		}catch(e){
			trace('Error handling packet($pktName) from $socketID:${e.message}');
		}
		return true;
	}
	public static function handleCommand(player:ConnectedPlayer,socket:Socket,str:String){
		var split = str.substring(prefix.length).split(' ');
		var cmd = instance.commands[split[0]];
		if(cmd == null){
			Sender.SendPacket(Packets.SERVER_CHAT_MESSAGE,['Invalid command, do !help for a list of commands'],socket);
			return;
		}
		if(cmd.admin && !player.admin){
			Sender.SendPacket(Packets.SERVER_CHAT_MESSAGE,['You do not have permission to run this command!'],socket);
			return;
		}
		cmd.execute(player,str,split);
	}
	public static function OnData(ID:Int,e:ProgressEvent) {
		var data:ByteArray = new ByteArray();
		connectedPlayers[ID].socket.readBytes(data);
		// data.endian = LITTLE_ENDIAN;
		connectedPlayers[ID].receiver.OnData(data);
	}
	public static function closeSocket(ID:Int,?call:Bool = true){
		if(connectedPlayers[ID] != null){
			try{
				connectedPlayers[ID].socket.close();
			}catch(e){}
			try{
				clientsFromNames[connectedPlayers[ID].nick] = null;
			}catch(e){}
			try{
				broadcastToAllClients(Packets.PLAYER_LEFT,[ID]);
			}catch(e){}
		}
	}
	public static function OnCloseSock(ID:Int,e:Event) {
		closeSocket(ID,false);
		trace('Socket for ${ID} closed... ${e}');
	}
	public static function OnClose(e:Event) {
		shutdownServer();
		FlxG.switchState(new OnlinePlayMenuState('Closed server: ${e}'));
	}
	public static function OnError(e:IOErrorEvent) {
		shutdownServer();
		FlxG.switchState(new OnlinePlayMenuState('Socket error: ${e.text}'));
	}

	public static function shutdownServer() {
		try{
			if(OnlineHostMenu.socket != null){
				OnlineHostMenu.socket.close();
				OnlineHostMenu.socket = null;
			}
		}catch(e){OnlineHostMenu.socket = null;return;} // Ignore errors, the socket should close anyways

		try{
			while(connectedPlayers.length > 0){
				var e = connectedPlayers.pop();
				if(e != null && e.socket != null) {
					try{
						e.socket.close();
					}catch(e){}
				}
			}
		}catch(e){}
		serverVariables = null;
		connectedPlayers = [];
		clientsFromNames = [];
	}
	public static function OnErrorSocket(sockID:Int,e:IOErrorEvent) {
		// shutdownServer();
		trace('Error with socket $sockID: ${e.text}');
		// FlxG.switchState(new OnlinePlayMenuState('Socket error: ${e.text}'));
	}
	public static function sendMessageToClient(str:String,player:ConnectedPlayer){
		Sender.SendPacket(Packets.SERVER_CHAT_MESSAGE,[str],player.socket);
	}
	public static function sendMessageToAllClients(str:String,?player:ConnectedPlayer){
		if(player == null){
			for (playerObject in connectedPlayers){
				if(playerObject.socket == null) continue;
				Sender.SendPacket(Packets.SERVER_CHAT_MESSAGE,[str],playerObject.socket);
			}
			return;
		}
		for (playerObject in connectedPlayers){
			if(playerObject.socket == null || playerObject == player) continue;
			Sender.SendPacket(Packets.SERVER_CHAT_MESSAGE,[str],playerObject.socket);
		}
	}
	public static function broadcastToAllClients(packet:Int,content:Array<Dynamic>,?player:ConnectedPlayer){
		if(player == null){
			for (playerObject in connectedPlayers){
				if(playerObject.socket == null) continue;
				Sender.SendPacket(packet,content,playerObject.socket);
			}
			return;
		}
		for (playerObject in connectedPlayers){
			if(playerObject.socket == null || playerObject == player) continue;
			Sender.SendPacket(packet,content,playerObject.socket);
		}
	}
	/*Instance shit
		Currently only using this so commands don't waste memory for no fuckin reason
	*/
	public var scripts:Array<String> = [];
	public var songName:String = "";
	public var chartPath:String = "";
	public var instPath:String = "";
	public var voicePath:String = "";
	public var chart:String="";
	public var midGame:Bool = true;
	public var commands:Map<String,Command> = [
		'help' => {
			description:"Returns all commands available",
			execute:function(player:ConnectedPlayer,cmd:String,split:Array<String>){
				for(name=>cmd in SEServer.instance.commands){
					if(cmd.admin && !player.admin) continue;
					sendMessageToClient('$name - ${cmd.description}',player);
				}
			}
		},
		// TODO ADD PROPER CLIENT SONG SETTING
		'setsong' => {
			description:"Sets the song",
			admin:true,
			execute:function(player:ConnectedPlayer,cmd:String,split:Array<String>){
				if(!player.admin) return sendMessageToClient('You don\'t have permission to run this command!',player);
				if(split[1] == null){
					if(player.self) return FlxG.switchState(new OnlineSongMenuState());
					sendMessageToClient('No song specified!',player);
					return;
				}
				sendMessageToClient('This command is not implemented!',player);
			}
		},
		'start' => {
			description:"Starts the game",
			admin:true,
			execute:function(player:ConnectedPlayer,cmd:String,split:Array<String>){
				if(!player.admin) return sendMessageToClient('You don\'t have permission to run this command!',player);
				return startGame();
				// return sendMessageToClient('This command is not implemented!',player.socket);
				
			}
		}
	];
	public function new(){}

	static public function startGame(){
		var path = instance.chartPath.split('/');
		var l = path.length;
		var json = path[l-1].substring(0,path[l-1].lastIndexOf('/'));
		var folder = path[l-2];
		instance.midGame=true;
		broadcastToAllClients(Packets.GAME_START,[json,folder]);
	}

	public function updateSong(){
		sendMessageToAllClients('Song updated to $songName');
	}
}