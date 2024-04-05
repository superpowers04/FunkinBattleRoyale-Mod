package onlinemod;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxAxes;
import flixel.FlxSubState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.sound.FlxSound;
import flash.media.Sound;
import onlinemod.Packets;
import onlinemod.Player;

import Section.SwagSection;



class OnlinePlayState extends PlayState
{
	var clients(get,set):Map<Int,Player>;
	@:keep inline public function get_clients() return OnlineLobbyState.clients;
	@:keep inline public function set_clients(vari) return OnlineLobbyState.clients = vari;
	// public static var clientScores:Map<Int, Int> = [];
	// public static var clientText:Map<Int, String> = [];
	public static var lastPressed:Array<Bool> = [false,false,false,false];
	public static var useSongChar:Array<String> = ["","",""];
	public static var autoDetPlayer2:Bool = true;
	var clientTexts:Map<Int, Int> = [];
	var clientsGroup:FlxTypedGroup<FlxText>;

	var CoolLeaderBoard:Array<Array<Dynamic>>;
	var scoreY:Float;

	var clientCount:Int = 1;

	var waitingBg:FlxSprite;
	var waitingText:FlxText;

	var customSong:Bool;
	var loadedVoices:FlxSound;
	var loadedInst:Sound;

	var ready:Bool = false;
	var waitMusic:FlxSound;

	var inPause:Bool = false;

	var originalSafeFrames:Int = SESave.data.frames;

	public function new(customSong:Bool, voices:FlxSound, inst:Sound) {
		PlayState.stateType =3;
		updateOverlay = false;
		super();


		this.customSong = customSong;
		this.loadedVoices = voices;
		this.loadedInst = inst;
		practiceMode = true;
		FlxG.sound.playMusic(loadedInst, SESave.data.instVol, false);
		FlxG.sound.music.pause();
	}

	override function create()
	{try{
		handleNextPacket = true;
		OnlinePlayMenuState.SetVolumeControls(true); // Make sure volume is enabled
		if (customSong){
			if (useSongChar[0] != "") PlayState.SONG.player1 = SESave.data.playerChar;
			
			if ((SESave.data.charAuto || useSongChar[1] != "") && TitleState.retChar(PlayState.player2) != ""){ // Check is second player is a valid character
				PlayState.player2 = TitleState.retChar(PlayState.player2);
			}else{
				PlayState.player2 = SESave.data.opponent;
			}
			for (i => v in useSongChar) {
				if (v != ""){
					switch(i){
						case 0: PlayState.player1 = v;
						case 1: PlayState.player2 = v;
						case 2: PlayState.player3 = v;
					}
				}
			}
		}
		// if (autoDetPlayer2){
		// 	var count = 0;
		// 	for (i in clients.keys()) {
		// 		count++;
		// 		if(count > 1){break;}
		// 	}
		// 		// PlayState.dadShow = (count == 1);
		// }

		super.create();
		clientsGroup = new FlxTypedGroup<FlxText>();
		CoolLeaderBoard = [];

		CoolLeaderBoard.push([]);
		var Box1 = new FlxSprite().makeGraphic(275, 50, 0x7FFF7F00); // #FF7F00
		Box1.screenCenter(Y);
		scoreY = Box1.y;
		CoolLeaderBoard[0].push(Box1);
		Box1.cameras = [camHUD];
		add(Box1);
		var Box2 = new FlxSprite().makeGraphic(150, 50, 0x7FFFFF00); // #FFFF00
		CoolLeaderBoard[0].push(Box2);
		Box2.cameras = [camHUD];
		add(Box2);
		var nametext = new FlxText(Box2.x + 10, Box2.y + 12.5, OnlineNickState.nickname,16);
		nametext.setFormat(CoolUtil.font, 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		CoolLeaderBoard[0].push(nametext);
		nametext.cameras = [camHUD];
		add(nametext);
		var scoretext = new FlxText(Box2.x + Box2.width + 10, Box2.y + 5, '0\nn/a%  0x',16);
		scoretext.setFormat(CoolUtil.font, 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		CoolLeaderBoard[0].push(scoretext);
		scoretext.cameras = [camHUD];
		add(scoretext);
		clientsGroup.add(scoretext);

		// Add the score UI for other players
		for (i in clients.keys()) {
			clients[i].score = 0;
			clientCount++;

			CoolLeaderBoard.push([]);
			var Box1 = new FlxSprite().makeGraphic(275, 50, 0x7F0000FF); // #0000FF
			Box1.screenCenter(Y);
			CoolLeaderBoard[CoolLeaderBoard.length - 1].push(Box1);
			Box1.cameras = [camHUD];
			add(Box1);
			var Box2 = new FlxSprite().makeGraphic(150, 50, 0x7F007FFF); // #007FFF
			CoolLeaderBoard[CoolLeaderBoard.length - 1].push(Box2);
			Box2.cameras = [camHUD];
			add(Box2);
			var nametext = new FlxText(Box2.x + 10, Box2.y + 12.5, OnlineLobbyState.clients[i].name,16);
			nametext.setFormat(CoolUtil.font, 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			CoolLeaderBoard[CoolLeaderBoard.length - 1].push(nametext);
			nametext.cameras = [camHUD];
			add(nametext);
			var scoretext = new FlxText(Box2.x + Box2.width + 10, Box2.y + 5, '0\nN/A%  0x',16);
			scoretext.setFormat(CoolUtil.font, 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			CoolLeaderBoard[CoolLeaderBoard.length - 1].push(scoretext);
			scoretext.cameras = [camHUD];
			add(scoretext);
			clientTexts[i] = clientsGroup.length;
			clientsGroup.add(scoretext);
		}
		scoreY -= scoreY/2;
		for(i in 0...CoolLeaderBoard.length){
			// Long Box
			CoolLeaderBoard[i][0].y = scoreY + (CoolLeaderBoard[i][0].height * i) - (CoolLeaderBoard[i][0].height + (CoolLeaderBoard[i][0].height * ((CoolLeaderBoard.length * 0.5) - 1.5)));
			CoolLeaderBoard[i][0].x = (!PlayState.invertedChart ? 125 - (Math.abs(0 - i) * 10) : FlxG.width - 625 + (Math.abs(0 - i) * 10));
			// Name Box
			CoolLeaderBoard[i][1].y = CoolLeaderBoard[i][0].y;
			CoolLeaderBoard[i][1].x = CoolLeaderBoard[i][0].x + 10;
			// Name Text
			CoolLeaderBoard[i][2].y = CoolLeaderBoard[i][1].y + 5;
			CoolLeaderBoard[i][2].x = CoolLeaderBoard[i][1].x + 10;
			// Score Text
			CoolLeaderBoard[i][3].y = CoolLeaderBoard[i][1].y + 5;
			CoolLeaderBoard[i][3].x = CoolLeaderBoard[i][1].x + CoolLeaderBoard[i][1].width + 10;
		}


		// Add XieneDev watermark
		var xieneDevWatermark:FlxText = new FlxText(-4, FlxG.height * 0.9 + 50, FlxG.width, 'SuperEngine-BattleRoyale ${MainMenuState.ver}', 16);
		xieneDevWatermark.setFormat(CoolUtil.font, 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
		xieneDevWatermark.scrollFactor.set();
		xieneDevWatermark.cameras = [camHUD];
		add(xieneDevWatermark);


		// The screen with 'Waiting for players (1/4)' stuff
		waitingBg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		waitingBg.alpha = 0.5;
		waitingBg.cameras = [camHUD];
		add(waitingBg);

		waitingText = new FlxText(0, 0, FlxG.width, 'Waiting for players (?/${clientCount})');
		waitingText.setFormat(CoolUtil.font, 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		waitingText.screenCenter(FlxAxes.XY);
		waitingText.cameras = [camHUD];
		add(waitingText);


		// Remove healthbar
		scoreTxt.visible = false;
		// remove(healthBarBG);
		// remove(healthBar);
		// remove(iconP1);
		remove(iconP2);
		camGame.alpha = 1;
		camGame.visible = true;

		OnlinePlayMenuState.receiver.HandleData = HandleData;
		new FlxTimer().start(transIn.duration, (timer:FlxTimer) -> Sender.SendPacket(Packets.GAME_READY, [], OnlinePlayMenuState.socket));

		waitMusic = SELoader.loadFlxSound('assets/shared/music/breakfast.ogg');
		waitMusic.volume = 0;
		waitMusic.play(false, FlxG.random.int(0, Std.int(waitMusic.length / 2)));
		waitMusic.looped = true;
		FlxG.sound.list.add(waitMusic);

		FlxG.mouse.visible = false;
		FlxG.autoPause = false;
		canPause = true;
	}catch(e){MainMenuState.handleError('Crash in "create" caught: ${e.message}');}}

	override function startCountdown() if (ready) super.startCountdown();

	override function generateSong(?dataPath:String = ""){
	//   // I have to code the entire code over so that I can remove the offset thing
	//   var songData = PlayState.SONG;
		// Conductor.changeBPM(songData.bpm);

		// curSong = songData.song;

		vocals = (PlayState.SONG.needsVoices ? loadedVoices : new FlxSound());
		super.generateSong(dataPath);

		// Instantly get note id's, if this isn't done now, a note might not get added to the list
		if(PlayState.p2canplay){

			var _note:Note;
			for (i in 0 ... unspawnNotes.length) {
				_note = unspawnNotes[i];
				if(_note == null || _note.noteData == -1) continue;
				noteData[_note.noteID] = [_note,_note.noteData % 4];
			}
		}
	}

	override function popUpScore(daNote:Note):Void {
		super.popUpScore(daNote);
		clientsGroup.members[0].text = PlayState.songScore + "\n" + HelperFunctions.truncateFloat(PlayState.accuracy,2) + "%  " + PlayState.misses;

		SendScore();
	}

	override function noteMiss(direction:Int = 1, daNote:Note,?forced:Bool = false,?calcStats:Bool = true):Void{
		super.noteMiss(direction, daNote,forced,calcStats);
		clientsGroup.members[0].text = PlayState.songScore + "\n" + HelperFunctions.truncateFloat(PlayState.accuracy,2) + "%  " + PlayState.misses;

		SendScore();
	}

	override function resyncVocals() {
		if (inPause) return;

		super.resyncVocals();
	}
	public override function handleError(?error:String = "",?forced:Bool = false){
		// generatedMusic = persistentUpdate = false;
		canPause=true;
		try{

			if(error == "") error = 'No error passed!';
			// else if(error == "Null Object Reference") error = 'Null Object Reference;\nInterp info: ${currentInterp}';
			if(currentInterp.isActive) error += '\nInterp info: ${currentInterp}';
			trace('Error!\n ${error}');
			resetInterps();
			parseMoreInterps = false;
			errorMsg = "";
			Chat.OutputChatMessage(error);
			FlxG.switchState(new OnlineLobbyState());
		}catch(e){
			trace('${e.message}\n${e.stack}');MainMenuState.handleError(error);
		}
	}
	override function beatHit(){
		super.beatHit();
		CoolLeaderBoard.sort((a,b) -> Std.int(b[3].text.split(' ')[0]) - Std.int(a[3].text.split(' ')[0]));
		var WhereME = 0;
		for(Index => Array in CoolLeaderBoard){
			if(Array[2].text == OnlineNickState.nickname){
				WhereME = 1 + Index;
				break;
			}
		}
		if(CoolLeaderBoard.length > 1){
			for(i in 0...CoolLeaderBoard.length){
				var YMove = scoreY + ((CoolLeaderBoard[i][0].height * (i - (WhereME - (CoolLeaderBoard.length * 0.5)))) - (CoolLeaderBoard[i][0].height + (CoolLeaderBoard[i][0].height * ((CoolLeaderBoard.length * 0.5) - 1.5))));
				var XMove = (!PlayState.invertedChart ? 125 - (Math.abs((WhereME - 1) - i) * 10) : FlxG.width - 625 + (Math.abs((WhereME - 1) - i) * 10));
				if(YMove - CoolLeaderBoard[i][0].y >= 20 || YMove - CoolLeaderBoard[i][0].y <= -20 
					|| YMove - CoolLeaderBoard[i][1].y >= 20 || YMove - CoolLeaderBoard[i][1].y <= -20) {
					FlxTween.tween(CoolLeaderBoard[i][0],{y: YMove,x: XMove},0.1,{ease: FlxEase.quadInOut});
					FlxTween.tween(CoolLeaderBoard[i][1],{y: YMove,x: XMove + 10},0.1,{ease: FlxEase.quadInOut});
					FlxTween.tween(CoolLeaderBoard[i][2],{y: YMove + 12.5,x: XMove + 10},0.1,{ease: FlxEase.quadInOut});
					FlxTween.tween(CoolLeaderBoard[i][3],{y: YMove + 5,x: XMove + CoolLeaderBoard[i][1].width + 20},0.1,{ease: FlxEase.quadInOut});
				}
			}
		}
		
	}

	override function finishSong(?win=true){endSong();}
	override function endSong():Void{
		OnlineLobbyState.client.score = PlayState.songScore;
		OnlineLobbyState.client.scoreText = "S:" + PlayState.songScore + " M:" + PlayState.misses + " A:" + HelperFunctions.truncateFloat(PlayState.accuracy,2);

		canPause = false;
		FlxG.sound.playMusic(loadedInst, SESave.data.instVol, true);
		FlxG.sound.music.onComplete = null;
		FlxG.sound.music.pause();
		vocals.volume = 0;
		vocals.pause();

		Sender.SendPacket(Packets.GAME_END, [], OnlinePlayMenuState.socket);

		FlxG.switchState(new OnlineLobbyState(true,true));
	}


	override function keyShit() {
		if (!inPause) super.keyShit();
	}

	public override function pause(){
		var realPaused:Bool = paused;
		paused = false;

		super.openSubState(new OnlinePauseSubState());
		inPause = true;

		paused = realPaused;
		persistentUpdate = true;
		
		canPause = false;
	}
	override function closeSubState() {
		if (paused) {
			canPause = true;
			inPause = false;
		}

		super.closeSubState();
	}

	public static var handleNextPacket = true;
	static var noteData:Array<Array<Dynamic>> = []; // Stores notes so they can be hit by other players
	var lastPacket:Array<Dynamic> = [];
	var lastPacketID:Int = 0;
	function HandleData(packetId:Int, data:Array<Dynamic>)
	{try{
		lastPacketID = packetId;
		lastPacket = data;

		OnlinePlayMenuState.RespondKeepAlive(packetId);
		callInterp("packetRecieve",[packetId,data]);
		if(!handleNextPacket){
			handleNextPacket = true;
			return true;
		}
		switch (packetId)
		{
			case Packets.PLAYERS_READY:
				var count:Int = data[0];
				waitingText.text = 'Waiting for players ($count/${clientCount})';
			case Packets.EVERYONE_READY:
				var safeFrames:Int = data[0];
				waitingText.text = 'Ready!';
				ready = true;
				startCountdown();
				FlxTween.tween(waitingBg, {alpha: 0}, 0.5);
				FlxTween.tween(waitingText, {alpha: 0}, 0.5);
				FlxTween.tween(waitMusic, {volume: 0}, 0.5);

				SESave.data.frames = safeFrames;
				Conductor.recalculateTimings();
			case Packets.BROADCAST_SCORE:
				var id:Int = data[0];
				var score:Int = data[1];
				if(Math.isNaN(id)){
					trace('Error for Packet BROADCAST_CURRENT_INFO: Invalid ID(${data[0]}) ');
					showTempmessage('Error for Packet BROADCAST_CURRENT_INFO: Invalid ID(${data[0]}) ');
					return true;
				}
				if(Math.isNaN(score)){
					trace('Error for Packet BROADCAST_CURRENT_INFO, ID($id): Invalid Score(${data[1]}) ');
					return true;
				}

				clients[id].score = score;
				clients[id].scoreText = "S:" + score+ " M:n/a A:n/a";
				clientsGroup.members[clientTexts[id]].text = Std.string(score);
			case Packets.BROADCAST_CURRENT_INFO:
				var id:Int = data[0];
				var score:Int = data[1];
				var misses:Int = data[2];
				var accuracy:Float = data[3];
				if(accuracy > 100) accuracy /= 100;
				if(Math.isNaN(id)){
					trace('Error for Packet BROADCAST_CURRENT_INFO: Invalid ID(${data[0]}) ');
					showTempmessage('Error for Packet BROADCAST_CURRENT_INFO: Invalid ID(${data[0]}) ');
					return true;
				}
				if(Math.isNaN(score)){
					trace('Error for Packet BROADCAST_CURRENT_INFO, ID($id): Invalid Score(${data[1]}) ');
					return true;
				}
				if(Math.isNaN(misses)){
					trace('Error for Packet BROADCAST_CURRENT_INFO, ID($id): Invalid Miss count(${data[2]}) ');
					return true;
				}
				if(Math.isNaN(accuracy)){
					trace('Error for Packet BROADCAST_CURRENT_INFO, ID($id): Invalid Accuracy(${data[3]}) ');
					return true;
				}

				clients[id].score = score;
				clients[id].scoreText = "S:" + score+ " M:" + misses+ " A:" + accuracy;
				clientsGroup.members[clientTexts[id]].text = score + "\n" + accuracy + "%  " + misses;

			case Packets.PLAYER_LEFT:
				var id:Int = data[0];
				var nickname:String = OnlineLobbyState.clients[id].name;

				clientsGroup.members[clientTexts[id]].setFormat(CoolUtil.font, 16, FlxColor.RED, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				if(clients[id].scoreText == null || clients[id].scoreText == "" || clients[id].scoreText == "N/A") clientsGroup.members[clientTexts[id]].text = 'left';
				for(Array in CoolLeaderBoard){
					if(Array[3] == clientsGroup.members[clientTexts[id]]){
						var Box1 = new FlxSprite().makeGraphic(275, 50, 0x7FBF0000); // #BF0000
						Box1.y = FlxG.height - Box1.height;
						Box1.cameras = [camHUD];
						Box1.setPosition(Array[0].x,Array[0].y);
						add(Box1);
						var Box2 = new FlxSprite().makeGraphic(150, 50, 0x7FFF0000); // #FF0000
						Box2.cameras = [camHUD];
						Box2.setPosition(Array[1].x,Array[1].y);
						add(Box2);
						remove(Array[0]); Array[0].destroy();
						remove(Array[1]); Array[1].destroy();
						Array[0] = Box1;
						Array[1] = Box2;
						Array[2].setFormat(CoolUtil.font, 16, FlxColor.RED, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
						remove(Array[2]); add(Array[2]);
						remove(Array[3]); add(Array[3]);
						break;
					}
				}

				OnlineLobbyState.removePlayer(id);
				Chat.PLAYER_LEAVE(nickname);
				clientCount--;

			case Packets.REJECT_CHAT_MESSAGE:
				Chat.SPEED_LIMIT();
			case Packets.SERVER_CHAT_MESSAGE:
				if(StringTools.startsWith(data[0],"'32d5d167'")) OnlineLobbyState.handleServerCommand(data[0].toLowerCase(),0); else Chat.SERVER_MESSAGE(data[0]);

			case Packets.FORCE_GAME_END:
				FlxG.switchState(new OnlineLobbyState(true));
			case Packets.KEYPRESS:
				if (PlayState.p2canplay){
					try{

						if(data[1] == null){data[1] = 0;}
						var charID = 1;
						if(data[2] != null && data[2] != 0) charID = data[2];
						// trace('packet lmao ${data}');

						if(data[0] == -1 && data[1] != null && data[1] != 0 ){
							PlayState.charAnim(1,Note.noteAnims[Std.int(data[1] - 1)],true);
						}else{
							var killedNote = false;
							var mustPress = false;
							if(noteData[data[0]] != null){
								var note = noteData[data[0]][0];
								
								if(note != null && note.hit != null && note.miss != null){
									mustPress = note.mustPress;
									if(data[1] != null && data[1] != 0 || note.shouldntBeHit){ // Miss
										note.miss(charID,note);
									}else{
										note.hit(charID,note);
									}
									note.mustPress = mustPress;
									if(!note.mustPress){ // Oi, dumbass, don't delete notes from the player
										note.kill();
										notes.remove(note, true);
										note.destroy();
									}
									return true;
								}else{
									var noteData:Int = noteData[data[0]][1];
									switch (charID) {
										case 0:PlayState.instance.BFStrumPlayAnim(noteData);
										case 1:if (SESave.data.cpuStrums) {PlayState.instance.DadStrumPlayAnim(noteData);}
									}; // Strums
									PlayState.charAnim(charID,Note.noteAnims[noteData] = (if(data[1] != null && data[1] != 0 ) "miss" else ""),true); // Play animation
								}
							}
							for (i => note in notes.members){
								mustPress = false;
								if(note.noteID == data[0]){
									mustPress = note.mustPress;
									if(data[1] != null && data[1] != 0 || note.shouldntBeHit){ // Miss
										note.miss(charID,note);
									}else{
										note.hit(charID,note);
									}
									note.mustPress = mustPress;
									if(!note.mustPress){ // Oi, dumbass, don't delete notes from the player
										note.kill();
										notes.remove(note, true);
										note.destroy();
									}
									break;
								}
							}
						}
					}catch(e){
						showTempmessage('Error with KEYPRESS: $data',FlxColor.RED);
						// Reset animations
						PlayState.boyfriend.dance(true);
						PlayState.dad.dance(true);
						trace('Error with KEYPRESS: $data ${e.message}');
					}
				}
			case Packets.BROADCAST_NEW_PLAYER:
				var id:Int = data[0];
				var nickname:String = data[1];

				OnlineLobbyState.addPlayer(id, nickname);
				Chat.PLAYER_JOIN(nickname);
				clientCount++;

				CoolLeaderBoard.push([]);
				var Box1 = new FlxSprite().makeGraphic(275, 50, 0x7F7F7F7F); // #7F7F7F
				Box1.y = FlxG.height - Box1.height;
				CoolLeaderBoard[CoolLeaderBoard.length - 1].push(Box1);
				Box1.cameras = [camHUD];
				add(Box1);
				var Box2 = new FlxSprite().makeGraphic(150, 50, 0x7FBFBFBF); // #BFBFBF
				CoolLeaderBoard[CoolLeaderBoard.length - 1].push(Box2);
				Box2.cameras = [camHUD];
				Box2.x += 10;
				Box2.y = Box1.y;
				add(Box2);
				var nametext = new FlxText(Box2.x + 10, Box2.y + 12.5, '${nickname}',16);
				nametext.setFormat(CoolUtil.font, 16, FlxColor.YELLOW, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				CoolLeaderBoard[CoolLeaderBoard.length - 1].push(nametext);
				nametext.cameras = [camHUD];
				add(nametext);
				var scoretext = new FlxText(Box2.x + Box2.width + 10, Box2.y + 5, 'In lobby',16);
				scoretext.setFormat(CoolUtil.font, 16, FlxColor.YELLOW, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				CoolLeaderBoard[CoolLeaderBoard.length - 1].push(scoretext);
				scoretext.cameras = [camHUD];
				add(scoretext);
				clientTexts[id] = clientsGroup.length;
				clientsGroup.add(scoretext);
			case Packets.DISCONNECT:
				FlxG.switchState(new OnlinePlayMenuState("Disconnected from server"));
			default: return false;
		}}catch(e){
			var packetName = "Unknown";
			if(PacketsShit.fields[packetId] != null){
				packetName = PacketsShit.fields[packetId].name;
			}
			trace(e);
			Chat.OutputChatMessage("[Client] You had an error when receiving packet '" + '${packetName}' + "' with ID '" + '$packetId' + "' :");
			Chat.OutputChatMessage(e.message);
			var err = ('${e.stack}').split('\n');
			var _e = "";
			while ((_e = err.pop()) != null){
				Chat.OutputChatMessage('||${_e}');

			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(new OnlineLobbyState(true));
		}
		return true;

	}
	

	function SendScore() {
		if (TitleState.supported)
			Sender.SendPacket(Packets.SEND_CURRENT_INFO, [PlayState.songScore,PlayState.misses,Math.ceil(PlayState.accuracy * 100)], OnlinePlayMenuState.socket);
		else
			Sender.SendPacket(Packets.SEND_SCORE, [PlayState.songScore], OnlinePlayMenuState.socket);

	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// health = 1; // if you already have practiceMode on why even set the health

		if (!ready)
		{
			Conductor.songPosition = -5000;
			Conductor.lastSongPos = -5000;
			if (waitMusic.volume < 0.75)
				waitMusic.volume += 0.01 * elapsed;
		}
		if(SESave.data.animDebug){
			Overlay.debugVar += '\nClient count:${clientCount}'
				+'\nLast Packet: ${lastPacketID};${lastPacket}';
		}
	}

	override function destroy()
	{
		// This function is called when the State changes. For example, when exiting via the pause menu.
		FlxG.sound.music.onComplete = null;

		SESave.data.frames = originalSafeFrames;
		Conductor.recalculateTimings();
		super.destroy();
	}
	override function testanimdebug(){
		return;
	}
}