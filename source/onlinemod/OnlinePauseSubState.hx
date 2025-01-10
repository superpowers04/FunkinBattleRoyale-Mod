package onlinemod;

// import llua.Lua;
import Controls.Control;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class OnlinePauseSubState extends MusicBeatSubstate
{
	var ready:Bool = false;

	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = ['Resume', 'Exit to lobby', 'Exit to menu'];
	var curSelected:Int = 0;

	var offline:Bool;

	public function new() {

		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += PlayState.SONG.song;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(CoolUtil.font, 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += CoolUtil.difficultyString();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(CoolUtil.font, 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		var notPaused:FlxText = new FlxText(20, 47, 0, "", 48);
		notPaused.text = "GAME IS NOT PAUSED";
		notPaused.scrollFactor.set();
		notPaused.setFormat(CoolUtil.font, 32);
		notPaused.screenCenter(X);
		notPaused.updateHitbox();
		add(notPaused);

		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		for (i in 0...menuItems.length) {
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

		changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];


		// Without this, the input that opens the menu also causes the pause menu to close.
		new FlxTimer().start(0.1, (timer:FlxTimer) -> {
			ready = true;
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(!ready) return;
		
		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		// var accepted = controls.ACCEPT;

		if (upP) changeSelection(-1);
		else if (downP) changeSelection(1);

		if (controls.ACCEPT) {
			var daSelected:String = menuItems[curSelected];

			switch (daSelected)
			{
				case "Resume":
					close();
				case "Exit to lobby":
					if (TitleState.supported){
						Sender.SendPacket(Packets.SEND_CURRENT_INFO, [PlayState.songScore,PlayState.misses,Std.int(PlayState.accuracy)], OnlinePlayMenuState.socket);
					}else{Sender.SendPacket(Packets.SEND_SCORE, [PlayState.songScore], OnlinePlayMenuState.socket);}

					Sender.SendPacket(Packets.GAME_END, [], OnlinePlayMenuState.socket);
					if(SEServer.instance != null){
						SEServer.broadcastToAllClients(Packets.FORCE_GAME_END,[]);
					}
					
					FlxG.switchState(new OnlineLobbyState(true,false));
				case "Exit to menu":
					OnlinePlayMenuState.socket.close();
					if(SEServer.instance != null){
						SEServer.shutdownServer();
					}
					FlxG.switchState(new OnlinePlayMenuState("Disconnected"));
			}
		}
	}

	function changeSelection(change:Int = 0):Void {
		curSelected += change;

		if (curSelected < 0) curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length) curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = (item.targetY == 0 ? 1 : 0.6);
		}
	}
}
