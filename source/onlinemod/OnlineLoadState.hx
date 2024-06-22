package onlinemod;

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
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;

class OnlineLoadState extends MusicBeatState
{
	var loadingText:FlxText;
	var fileSizeText:FlxText;
	var loadingBar:FlxBar;
	var progress:Float = 0;
	// var fileSize:Int = 0;

	var customSong:Bool;

	var jsonInput:String;
	var folder:String;

	var voices:FlxSound;
	var inst:Sound;

	var loadedVoices:Bool = false;
	var loadedInst:Bool = false;

	var weeks:Map<String, Int> = ["tutorial" => 1,
		"bopeebo" => 1,
		"fresh" => 1,
		"dadbattle" => 1,
		"spookeez" => 2,
		"south" => 2,
		"monster" => 2,
		"pico" => 3,
		"philly" => 3,
		"blammed" => 3,
		"satin-panties" => 4,
		"high" => 4,
		"milf" => 4,
		"cocoa" => 5,
		"eggnog" => 5,
		"winter-horrorland" => 5,
		"senpai" => 6,
		"roses" => 6,
		"thorns" => 6
	];

	public function new(jsonInput:String, folder:String)
	{
		super();

		this.jsonInput = jsonInput;
		this.folder = folder;
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


		Chat.created = false;



		OnlinePlayMenuState.receiver.HandleData = HandleData;


		// Make sure we are still connected to the server
		new FlxTimer().start(5, (timer:FlxTimer) -> {
			Sender.SendPacket(Packets.KEEP_ALIVE, [], OnlinePlayMenuState.socket);
		}, 0);


		new FlxTimer().start(transIn.duration, (timer:FlxTimer) -> {
			Sender.SendPacket(Packets.READY_DOWNLOAD, [], OnlinePlayMenuState.socket);
		});
	}

	override function update(elapsed:Float)
	{
		if (OnlinePlayMenuState.receiver.packetId == Packets.SEND_CHART || OnlinePlayMenuState.receiver.packetId == Packets.SEND_VOICES
			|| OnlinePlayMenuState.receiver.packetId == Packets.SEND_INST)
		{
			if (OnlinePlayMenuState.receiver.varLength > 4)
			{
				var fileSize:Int = OnlinePlayMenuState.receiver.varLength - 4;
				var bytesReceived:Int = OnlinePlayMenuState.receiver.bufferedBytes - 5;
				progress = Math.min(1, bytesReceived / fileSize);

				if (fileSize > 1000000) { //MB
					fileSizeText.text = Std.int(bytesReceived/10000)/100 + "/" + Std.int(fileSize/10000)/100 + "MB";
				} else {//KB
					fileSizeText.text =  Std.int(bytesReceived/10)/100 + "/" + Std.int(fileSize/10)/100 + "KB";
				}
			}
		}

		switch (OnlinePlayMenuState.receiver.packetId)
		{
			case Packets.SEND_CHART:
				loadingText.text = "Downloading Chart...";
			case Packets.SEND_VOICES:
				loadingText.text = "Downloading Voices...";
			case Packets.SEND_INST:
				loadingText.text = "Downloading Instrumental...";
		}

		super.update(elapsed);
	}

	function HandleData(packetId:Int, data:Array<Dynamic>)
	{
		try{

			switch (packetId)
			{
				case Packets.SEND_CHART:
					var file:Bytes = cast(data[0], Bytes);

					PlayState.SONG = Song.parseJSONshit(file.toString());
					trace("DOWNLOADED CHART!!!");

					PlayState.isStoryMode = false;

					// Set difficulty
					PlayState.storyDifficulty = 1;
					if (StringTools.endsWith(jsonInput.toLowerCase(), '-hard'))
					{
						PlayState.storyDifficulty = 2;
					}
					else if (StringTools.endsWith(jsonInput.toLowerCase(), '-easy'))
					{
						PlayState.storyDifficulty = 0;
					}

					if (FileSystem.exists(Paths.json(folder.toLowerCase() + '/' + jsonInput.toLowerCase()))) // In case of a vanilla song
					{
						customSong = false;

						loadVoices('assets/songs/${folder.toLowerCase()}/Voices.ogg');
						loadInst('assets/songs/${folder.toLowerCase()}/Inst.ogg');

						// Set week
						PlayState.storyWeek = weeks[folder.toLowerCase()];
						Paths.setCurrentLevel("week" + PlayState.storyWeek);
					}
					else // In case of a custom song
					{
						customSong = true;

						if (!SELoader.exists('assets/onlinedata/data/${folder.toLowerCase()}')) SELoader.createDirectory('assets/onlinedata/data/${folder.toLowerCase()}');
						SELoader.saveBytes('assets/onlinedata/data/${folder.toLowerCase()}/${jsonInput.toLowerCase()}.json', file);
						
						if (SELoader.exists('assets/onlinedata/songs/${folder.toLowerCase()}/Voices.ogg')) // If Voices.ogg has already been downladed
							loadVoices('assets/onlinedata/songs/${folder.toLowerCase()}/Voices.ogg');
						else
							requestVoices();

						if (FileSystem.exists('assets/onlinedata/songs/${folder.toLowerCase()}/Inst.ogg')) // If Inst.ogg has already been downloaded
							loadInst('assets/onlinedata/songs/${folder.toLowerCase()}/Inst.ogg');
						else
							requestInst();
					}

				case Packets.SEND_VOICES:
					var file:Bytes = cast(data[0], Bytes);

					if (!SELoader.exists('assets/onlinedata/songs/${folder.toLowerCase()}')) SELoader.createDirectory('assets/onlinedata/songs/${folder.toLowerCase()}');
					SELoader.saveBytes('assets/onlinedata/songs/${folder.toLowerCase()}/Voices.ogg', file);

					voices = new FlxSound().loadEmbedded(Sound.fromAudioBuffer(AudioBuffer.fromBytes(file)));

					loadedVoices = true;
					checkComplete();
					trace("DOWNLOADED VOICES!!!");

				case Packets.SEND_INST:
					var file:Bytes = cast(data[0], Bytes);

					SELoader.createDirectory('assets/onlinedata/songs/${folder.toLowerCase()}');
					SELoader.saveBytes('assets/onlinedata/songs/${folder.toLowerCase()}/Inst.ogg', file);

					inst = Sound.fromAudioBuffer(AudioBuffer.fromBytes(file));

					loadedInst = true;
					checkComplete();
					trace("DOWNLOADED INST!!!");

				case Packets.DENY:
					FlxG.switchState(new OnlinePlayMenuState("Server couldn't send file"));

				// Normal network handlers
				// case Packets.BROADCAST_CHAT_MESSAGE:
				// 	var id:Int = data[0];
				// 	var message:String = data[1];

				// 	Chat.MESSAGE(OnlineLobbyState.clients[id].name, message);
				// case Packets.REJECT_CHAT_MESSAGE:
				// 	Chat.SPEED_LIMIT();
				// case Packets.SERVER_CHAT_MESSAGE:
				// 	Chat.SERVER_MESSAGE(data[0]);

				// case Packets.PLAYER_LEFT:
				// 	var id:Int = data[0];
				// 	var nickname:String = OnlineLobbyState.clients[id].name;

				// 	OnlineLobbyState.removePlayer(id);
				// 	Chat.PLAYER_LEAVE(nickname);

				case Packets.FORCE_GAME_END:
					FlxG.switchState(new OnlineLobbyState(true));

				case Packets.DISCONNECT:
					FlxG.switchState(new OnlinePlayMenuState("Disconnected from server"));
				default:
					return false;
			}
		}catch(e){
			Chat.OutputChatMessage("[Client] You had an error while trying to download a song:");
			Chat.OutputChatMessage(e.message);
			SELoader.playSound('assets/sounds/cancelMenu',true);
			FlxG.switchState(new OnlineLobbyState(true));
		}
		return true;
	}

	function loadVoices(path:String)
	{
		loadingText.text = "Loading Voices...";

		voices = SELoader.loadFlxSound(path);
		// new FlxSound().loadEmbedded(Sound.fromFile(path));

		loadedVoices = true;
		checkComplete();
	}

	function requestVoices()
	{
		Sender.SendPacket(Packets.REQUEST_VOICES, [], OnlinePlayMenuState.socket);
	}

	function loadInst(path:String)
	{
		loadingText.text = "Loading Instrumental...";

		inst = SELoader.loadSound(path);

		loadedInst = true;
		checkComplete();
	}

	function requestInst()
	{
		Sender.SendPacket(Packets.REQUEST_INST, [], OnlinePlayMenuState.socket);
	}


	function checkComplete()
	{
		if (loadedVoices && loadedInst){
			LoadingScreen.loadAndSwitchState(new OnlinePlayState(customSong, voices, inst));
		}
	}
}
