package onlinemod;


class SEServer{
	public static var socket:ServerSocket;
	public static var connectedPlayers:Array<ConnectedPlayer> = [];
	public static var clientsFromNames:Map<String,Null<Int>> = [];
	public static var serverVariables:Map<Dynamic,Dynamic>;
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
					player.nick = data[0];
					trace('${socketID}: registered as ${player.nick}');
					Sender.SendPacket(Packets.NICKNAME_CONFIRM, [0], socket);
				case Packets.JOINED_LOBBY:
					Sender.SendPacket(Packets.SERVER_CHAT_MESSAGE,['Hosting is not currently finished, nothing besides chatting is implemented at the moment..'],socket);
				case Packets.SEND_CHAT_MESSAGE:{
					for (playerObject in connectedPlayers){
						if(playerObject.socket != null && playerObject != player) 
							Sender.SendPacket(Packets.BROADCAST_CHAT_MESSAGE,data,playerObject.socket);
					}
				}
			}
		}catch(e){
			trace('Error handling packet($pktName) from $socketID:${e.message}');
		}
		return true;
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
	static function OnError(e:IOErrorEvent) {
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
}