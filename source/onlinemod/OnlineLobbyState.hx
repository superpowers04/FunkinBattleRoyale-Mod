package onlinemod;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUIButton;
import SEInputText as FlxInputText;
import flixel.addons.ui.FlxUIList;
import flixel.addons.ui.FlxUIState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import onlinemod.Player;

import sys.FileSystem;
import sys.io.File;

using StringTools;
class OnlineLobbyState extends ScriptMusicBeatState {
	public static var instance:OnlineLobbyState;
	var clientTexts:Map<Int, Int> = []; // Maps a player ID to the corresponding index in clientsGroup
	var clientsGroup:FlxTypedGroup<FlxText>; // Stores all FlxText instances used to display names
	var clientsGroupLeaderboard:FlxTypedGroup<FlxText>; // Stores all FlxText instances used to display names
	var clientCount:Int = 0; // Amount of clients in the lobby
	public static var optionsButton:FlxUIButton;

	static inline var NAMES_PER_ROW:Int = 5;
	static inline var NAMES_SIZE:Int = 32;
	static inline var NAMES_VERTICAL_SPACING:Int = 48;

	public static var client:Player;
	public static var clients:Map<Int, Player> = []; // Maps a player ID to the corresponding player
	public static var clientsOrder:Array<Int> = []; // This array holds ID values in order of join time (including ID -1 for self)
	public static var receivedPrevPlayers:Bool = false;
	var quitHeld:Int = 0;
	var quitHeldBar:FlxBar;
	var quitHeldBG:FlxSprite;


	var keepClients:Bool;
	var showingLeaderBoard:Bool = true;
	var hasLeaderboard:Bool = false;
	var handleNextPacket:Bool = true;
  // public static var loadedScripts:Bool = false;

	public function new(keepClients:Bool=false,?_hasLeaderboard:Bool = false){
		instance = this;
		super();
		scriptSubDirectory = "/onlinelobby/";
		if(_hasLeaderboard){
			showingLeaderBoard = false;
			hasLeaderboard = true;
		}
		if (!keepClients){
			clients = [];
			clientsOrder = [];
			receivedPrevPlayers = false;

			Chat.chatMessages = [];
		}
		FlxG.mouse.visible = true;

		this.keepClients = keepClients;
	}

	function toggleLeaderboard(){
		showingLeaderBoard = !showingLeaderBoard;
		if(showingLeaderBoard){
			backButton.getLabel().name = "Show Player List";
			replace(clientsGroup,clientsGroupLeaderboard);
			return;
		}
		backButton.getLabel().name = "Show Leaderboard";
		replace(clientsGroupLeaderboard,clientsGroup);
	}
	var backButton:FlxUIButton;
	override function create(){
		
		FlxG.sound.music.looped = true;
		FlxG.sound.music.onComplete = null;
	  	if(!FlxG.sound.music.playing) FlxG.sound.music.play();
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('onlinemod/online_bg0'));
		add(bg);


		var topText:FlxText = new FlxText(0, FlxG.height * 0.05, "Lobby");
		topText.setFormat(CoolUtil.font, 64, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		topText.screenCenter(FlxAxes.X);
		add(topText);


		clientsGroup = new FlxTypedGroup<FlxText>();
		clientsGroupLeaderboard = new FlxTypedGroup<FlxText>();
		add(clientsGroup);
		if(hasLeaderboard){

			var orderedKeys:Array<Int> = [for(k in clients.keys()) k];
			orderedKeys.sort((a, b) -> clients[b].score - clients[a].score);

			var x:Int = 0;
			for (i in orderedKeys){
				var player:Player = clients[i];
				var score = player.scoreText ?? "N/A";
				var name = "N/A";
				var text:FlxText = new FlxText(0, FlxG.height*0.2 + 30*x, '${x+1}. $name: $score');

				if (player.self) text.text += " (YOU)";

				var color:FlxColor = (player.disconnected ? FlxColor.RED : FlxColor.WHITE);

				text.setFormat(CoolUtil.font, 24, color, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				text.screenCenter(FlxAxes.X);
				clientsGroupLeaderboard.add(text);
				x++;
			}
			backButton = new FlxUIButton(10, 10, "Show Player List", () -> {
				toggleLeaderboard();
			});
			backButton.setLabelFormat(28, FlxColor.BLACK, CENTER);
			backButton.resize(300, FlxG.height * 0.1);
			add(backButton);
			toggleLeaderboard();
		}
		var dced:Array<Int> = [];
		for (i => v in clients) if(v.disconnected) dced.push(i);
		for (i in dced) clients.remove(i);

		createNamesUI();


		Chat.createChat(this);


		if (!keepClients) Chat.PLAYER_JOIN(OnlineNickState.nickname);


		OnlinePlayMenuState.AddXieneText(this);


		FlxG.mouse.visible = true;
		FlxG.autoPause = false;

		OnlinePlayMenuState.receiver.HandleData = HandleData;
		if (!keepClients) Sender.SendPacket(Packets.JOINED_LOBBY, [], OnlinePlayMenuState.socket);

		optionsButton = new FlxUIButton(1100, 30, "Quick Options", () -> {
			Chat.created = false;
			FlxG.switchState(new OnlineOptionsMenu());
		});
		optionsButton.setLabelFormat(24, FlxColor.BLACK, CENTER);
		optionsButton.resize(160, 70);
		add(optionsButton);

		quitHeldBG = new FlxSprite(0, 10).loadGraphic(Paths.image('healthBar','shared'));
		quitHeldBG.screenCenter(X);
		quitHeldBG.scrollFactor.set();
		add(quitHeldBG);


		quitHeldBar = new FlxBar(quitHeldBG.x + 4, quitHeldBG.y + 4, LEFT_TO_RIGHT, Std.int(quitHeldBG.width - 8), Std.int(quitHeldBG.height - 8), this, 'quitHeld', 0, 1000);
		quitHeldBar.numDivisions = 1000;
		quitHeldBar.scrollFactor.set();
		quitHeldBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
		add(quitHeldBar);



		super.create();
		FlxG.mouse.visible = true;
	}

	function createNamesUI()
	{
		clientsGroup.clear();
		clientTexts = [];
		clientCount = 0;

		for (i in clientsOrder){
			addPlayerUI(i, i == -1 ? OnlineNickState.nickname : clients[i].name, i == -1 ? FlxColor.YELLOW : null);
		}
	}
	override function onFocus(){
		super.onFocus();
		FlxG.mouse.enabled = FlxG.mouse.visible = true;
	}
	public static function handleDataGlobal(packetId:Int, data:Array<Dynamic>):Bool {
		if(OnlinePlayMenuState.RespondKeepAlive(packetId)) return true;
		try{
		switch (packetId) {
			case Packets.BROADCAST_NEW_PLAYER:
				var id:Int = data[0];
				var nickname:String = data[1];

				if(instance != null) instance.addPlayerUI(id, nickname);
				addPlayer(id, nickname);
				if (receivedPrevPlayers) Chat.PLAYER_JOIN(nickname);
			case Packets.END_PREV_PLAYERS:
				receivedPrevPlayers = true;
				if(instance != null) instance.addPlayerUI(-1, OnlineNickState.nickname, FlxColor.YELLOW);
				clientsOrder.push(-1);
			case Packets.PLAYER_LEFT:
				var id:Int = data[0];
				var nickname:String = OnlineLobbyState.clients[id].name;
				Chat.PLAYER_LEAVE(nickname);

				removePlayer(id);
				if(instance != null) instance.createNamesUI();
			case Packets.GAME_START:
				var jsonInput:String = data[0];
				var folder:String = data[1];
				// var count = 0;
				// for (i in clients.keys())
				// {
				//   count++;
				// }

				StartGame(jsonInput, folder);

			case Packets.BROADCAST_CHAT_MESSAGE:
				var id:Int = data[0];
				var message:String = data[1];

				Chat.MESSAGE(OnlineLobbyState.clients[id].name, message);
			case Packets.REJECT_CHAT_MESSAGE:
				Chat.SPEED_LIMIT();
			case Packets.MUTED:
				Chat.MUTED();
			case Packets.SERVER_CHAT_MESSAGE:
				if(data[0] == "'ceabf544' This is a compatibility message, Ignore me!"){
					TitleState.supported = true;
					Sender.SendPacket(Packets.SUPPORTED, [], OnlinePlayMenuState.socket);
					Chat.SERVER_MESSAGE("This server is compatible with extra features!");
				}else if(StringTools.startsWith(data[0],"'32d5d167'")) handleServerCommand(data[0],0); else Chat.SERVER_MESSAGE(data[0]);

			case Packets.DISCONNECT:
				TitleState.p2canplay = false;
				FlxG.switchState(new OnlinePlayMenuState("Disconnected from server"));
			default:
				return false;
		}
		}catch(e){
			Chat.OutputChatMessage("[Client] You had an error when receiving packet '" + '$packetId' + "':");
			Chat.OutputChatMessage(e.message);
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(new OnlineLobbyState(true));
		}
		return true;
	}
	function HandleData(packetId:Int, data:Array<Dynamic>) {
		
		callInterp("packetRecieve",[packetId,data]);
		if(!handleNextPacket){
			handleNextPacket = true;
			return true;
		}
		return false;
		switch (packetId) {
			// case Packets.BROADCAST_NEW_PLAYER:
			// 	var id:Int = data[0];
			// 	var nickname:String = data[1];

			// 	addPlayerUI(id, nickname);
			// 	addPlayer(id, nickname);
			// 	if (receivedPrevPlayers) Chat.PLAYER_JOIN(nickname);
			// case Packets.END_PREV_PLAYERS:
			// 	receivedPrevPlayers = true;
			// 	addPlayerUI(-1, OnlineNickState.nickname, FlxColor.YELLOW);
			// 	clientsOrder.push(-1);
			// case Packets.PLAYER_LEFT:
			// 	var id:Int = data[0];
			// 	var nickname:String = OnlineLobbyState.clients[id].name;
			// 	Chat.PLAYER_LEAVE(nickname);

			// 	removePlayer(id);
			// 	createNamesUI();
			// case Packets.GAME_START:
			// 	var jsonInput:String = data[0];
			// 	var folder:String = data[1];
			// 	// var count = 0;
			// 	// for (i in clients.keys())
			// 	// {
			// 	//   count++;
			// 	// }

			// 	StartGame(jsonInput, folder);

			// case Packets.BROADCAST_CHAT_MESSAGE:
			// 	var id:Int = data[0];
			// 	var message:String = data[1];

			// 	Chat.MESSAGE(OnlineLobbyState.clients[id].name, message);

			// case Packets.SERVER_CHAT_MESSAGE:
			// 	if(data[0] == "'ceabf544' This is a compatibility message, Ignore me!"){
			// 		TitleState.supported = true;
			// 		Sender.SendPacket(Packets.SUPPORTED, [], OnlinePlayMenuState.socket);
			// 		Chat.SERVER_MESSAGE("This server is compatible with extra features!");
			// 	}else if(StringTools.startsWith(data[0],"'32d5d167'")) handleServerCommand(data[0],0); else Chat.SERVER_MESSAGE(data[0]);

			// case Packets.DISCONNECT:
			// 	TitleState.p2canplay = false;
			// 	FlxG.switchState(new OnlinePlayMenuState("Disconnected from server"));
		}
	}

	public static function handleServerCommand(command:String,?version = 0){
		try{ // Not sure if I'll ever actually use the version variable for anything
			// All responses start with '32d5d168'
			var args:Array<String> = command.split(' ');
			var argsLower:Array<String> = command.toLowerCase().split(' ');
			if(args[1] == null) throw('Command is empty!');
			switch (argsLower[1]){
				case "set":{
					if (argsLower[3] == "true" || argsLower[3] == "on" || argsLower[3] == "false" || argsLower[3] == "off"){ 
						var bool = (args[3] == "true" || args[3] == "on");
						switch(args[2]){
							case "invertnotes":
								PlayState.invertedChart = bool;
							case "invertchars":
								QuickOptionsSubState.setSetting("Swap characters",bool);
							case "inputsync":
								OnlinePlayState.autoDetPlayer2 = false;
								PlayState.p2canplay = bool;
							case "p2show":
								OnlinePlayState.autoDetPlayer2 = false;
								PlayState.dadShow = bool;
							case "clientscript": // CAN ALLOW CHEATING, ALLOW WITH CAUTION! Allows players to use custom scripts online!
								QuickOptionsSubState.setSetting("Song hscripts",bool);
								// if(bool == loadedScripts){
								// 	Chat.SERVER_MESSAGE('Server set client scripts to $bool, however you already have ${if(bool) '' else 'no'} scripts loaded. So no actions have been performed');
								// 	return;
								// }
								// if(bool){
								// 	scriptSubDirectory = "onlinelobby";
								// 	loadScripts();
								// 	Chat.SERVER_MESSAGE('Server enabled client scripts. All of your scripts have been enabled');
								// }else{
								// 	resetInterps();
								// 	Chat.SERVER_MESSAGE('Server disabled client scripts. All of your scripts have been disabled');
								// }
								// loadedScripts = bool;
								return;
							default:
								throw("Invalid option for 'set'");
						}
					}else{
						switch(args[2]){
							case "player1",'bf','p1':
								OnlinePlayState.useSongChar[0] = args[3];
							case "player2",'dad','p2':
								OnlinePlayState.useSongChar[1] = args[3];
							case "gf":
								OnlinePlayState.useSongChar[2] = args[3];
							default:
								throw("Invalid option");
						}
					}
					Chat.SERVER_MESSAGE('Server \'${args[1]}\' \'${args[2]}\' to \'${args[3]}\'');
				}
				case "sendhscript":{ // Allows downloading of hscripts
					QuickOptionsSubState.setSetting("Song hscripts",true);
					if(!SESave.data.allowServerScripts){
						Chat.CLIENT_MESSAGE("Server tried to send script but you're blocking server scripts.");
						Chat.CLIENT_MESSAGE("You can change this in your options if you trust the server.");
						sendResponse("Client has scripts disabled",false);
						return;
					}
					if(args[2] == null) throw('No name for script specified!');
					if(args[3] == null) throw('Script contents are empty!');
					if(argsLower[2].startsWith("temp-")){
						var scriptName = ~/[^_a-zA-Z0-9\-]/g.replace(args[2],"");
						args.splice(0,3);
						var script = args.join(" ");
						OnlinePlayMenuState.rawScripts.push([scriptName,script]);
						Chat.CLIENT_MESSAGE('Server has temporarily enabled ${scriptName} with ${script.length} characters, This script will be unloaded when you leave');

						sendResponse('Script "${scriptName}" enabled!',true);
						return;
					}

					var scriptName = ~/[^_a-zA-Z0-9\-]/g.replace(args[2],"");
					scriptName = "serv-" + scriptName;
					Chat.CLIENT_MESSAGE('Server is attempting to install hscript ${scriptName}');
				
					if(FileSystem.exists('mods/scripts/${scriptName}/script.hscript')) {sendResponse("Script Already exists!",true);return;}
					args.splice(0,3);
					var script = args.join(" ");
					Chat.CLIENT_MESSAGE('Installing hscript of ${script.length} characters');
					SELoader.createDirectory('mods/scripts/${scriptName}/');
					SELoader.saveContent('mods/scripts/${scriptName}/script.hscript',script);
					if(!SELoader.exists('mods/scripts/${scriptName}/script.hscript')) {sendResponse("Script couldn't be downloaded!",true);return;}

					OnlinePlayMenuState.scripts.push(scriptName);
					sendResponse('Script "${scriptName}" installed and enabled!',true);
				}
				case "disablescript":{ // Allows disabling of hscripts
					if(!SESave.data.allowServerScripts){
						Chat.CLIENT_MESSAGE("Server tried to disable a script but you're blocking server scripts. You can change this in your options if you trust the server.");
						sendResponse("Client has scripts disabled",false);
						return;
					}
					var scriptName = ~/[^_a-zA-Z0-9\-]/g.replace(args[2],"");
					scriptName = "serv-" + scriptName;
					if(OnlinePlayMenuState.scripts.contains(scriptName)){
						OnlinePlayMenuState.scripts.remove(scriptName);
						sendResponse("Script removed!");return;
					}else{
						for (_ => v in OnlinePlayMenuState.rawScripts) {
							if(v[0] != scriptName){continue;}
							OnlinePlayMenuState.rawScripts.remove(v);
							Chat.CLIENT_MESSAGE('Server unloaded script "${scriptName}"');
							return;
						}

						sendResponse("Script isn't enabled!");
						return;
					}
				
					Chat.CLIENT_MESSAGE('Server Disabled script "${scriptName}"');

					sendResponse("Script enabled!");
				}
				case "enablescript":{ // Allows enabling of hscripts
					QuickOptionsSubState.setSetting("Song hscripts",true);
					if(!SESave.data.allowServerScripts){
						Chat.CLIENT_MESSAGE("Server tried to enable a script but you're blocking server scripts. You can change this in your options if you trust the server.");
						sendResponse("Client has scripts disabled",false);
						return;
					}
					var scriptName = ~/[^_a-zA-Z0-9\-]/g.replace(args[2],"");
					scriptName = "serv-" + scriptName;
					if(OnlinePlayMenuState.scripts.contains(scriptName)){sendResponse("Script already loaded!");return;}
					if(!FileSystem.exists('mods/scripts/${scriptName}/script.hscript')) {sendResponse("Script doesn't exist!");return;}
					OnlinePlayMenuState.scripts.push(scriptName);
					Chat.CLIENT_MESSAGE('Server enabled script "${scriptName}"');

					sendResponse("Script enabled!");
				}
				case "hasscript":{ // Allows enabling of hscripts
					QuickOptionsSubState.setSetting("Song hscripts",true);
					if(!SESave.data.allowServerScripts){
						Chat.CLIENT_MESSAGE("Server checked if you have a script but you're blocking server scripts. You can change this in your options if you trust the server.");
						sendResponse("Client has scripts disabled",false);
						return;
					}
					var scriptName = ~/[^_a-zA-Z0-9\-]/g.replace(args[2],"");
					scriptName = "serv-" + scriptName;
					if(OnlinePlayMenuState.scripts.contains(scriptName)){sendResponse("Script is loaded!");return;}
					if(!FileSystem.exists('mods/scripts/${scriptName}/script.hscript')) {sendResponse("Script doesn't exist!");return;}

					sendResponse("Client has script!");
				}
				case "get":{ // Anything sent from this has to be filtered by the server, All responses start with '32d5d168'
					switch(argsLower[2]){
						case "info":{
							var clientInfo = {
								version: MainMenuState.ver,
								versionSplit: MainMenuState.ver.split("."),
								supported: ["inputsync","invertnotes","p2show","clientscript","setchar","sendscript","enablescript","removescript","tempscript"],
							};

							sendResponse("info:" + Json.stringify(clientInfo));
						}
						case "character" | "char":{
							sendResponse("character:" + SESave.data.playerChar);
						}
					}
				}
			}
		}catch(e){Chat.SERVER_MESSAGE('Server sent an invalid command ${e.message}, ${command}');} // I don't expect servers to always handle this properly, always better to have error catching
	} 
	
	public static function sendResponse(text:String,?sendToPlayer:Bool = false){
		if(sendToPlayer) Chat.CLIENT_MESSAGE(text);
		Sender.SendPacket(Packets.SEND_CHAT_MESSAGE, [Chat.chatId,"'32d5d168' " + text], OnlinePlayMenuState.socket);
	}

	public static function StartGame(jsonInput:String, folder:String){
		PlayState.isStoryMode = false;
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		FlxG.switchState(new OnlineLoadState(jsonInput, folder));

	}

	public static function addPlayer(id:Int, nickname:String){
		OnlineLobbyState.clients[id] = new Player(nickname,id);

		OnlineLobbyState.clientsOrder.push(id);
	}

	public function addPlayerUI(id:Int, nickname:String, ?color:FlxColor=FlxColor.WHITE) {
		var text:FlxText = new FlxText((clientCount % NAMES_PER_ROW) * FlxG.width/NAMES_PER_ROW, FlxG.height*0.2 + Std.int(clientCount / NAMES_PER_ROW) * NAMES_VERTICAL_SPACING, FlxG.width/NAMES_PER_ROW, nickname);
		text.setFormat(CoolUtil.font, NAMES_SIZE, color, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		clientTexts[id] = clientsGroup.length;
		clientsGroup.add(text);
		clientCount++;
	}

	public static function removePlayer(id:Int){
		OnlineLobbyState.clients[id].disconnected = true;
		clientsOrder.remove(id);
	}

	@:keep inline public function removePlayerUI(id:Int){
		var n:Int = clientTexts[id];

		for (i=>k in clientTexts){
			if (k < n) continue;
			clientsGroup.members[k].x = clientsGroup.members[k - 1].x;
			clientsGroup.members[k].y = clientsGroup.members[k - 1].y;
			clientTexts[i] = clientTexts[i] - 1;
		}

		clientsGroup.remove(clientsGroup.members[n], true);
		clientTexts.remove(id);
		clientCount--;
	}
	function disconnect(){
		if (OnlinePlayMenuState.socket.connected) OnlinePlayMenuState.socket.close();
		FlxG.switchState(new OnlinePlayMenuState());
	}

  override function update(elapsed:Float)
  {
	if (quitHeldBar.visible && quitHeld <= 0){
		quitHeldBar.visible = false;
		quitHeldBG.visible = false;
	}
	if (Chat.chatField.hasFocus){
		if (FlxG.keys.justPressed.ENTER) Chat.SendChatMessage();
	}
	if (FlxG.keys.pressed.ESCAPE){
		quitHeld += 5;
		quitHeldBar.visible = true;
		quitHeldBG.visible = true;
		if (quitHeld > 1000) disconnect(); 
	}else if (quitHeld > 0){
		quitHeld -= 10;
	}
	super.update(elapsed);
  }

}
