package onlinemod;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIButton;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;

using StringTools;

class OnlineResultState extends MusicBeatState {

  public function new(clients:Map<Int, String>)
  {
    super();
  }

  override function create()
  {
    var bg:FlxSprite = SELoader.loadFlxSprite('assets/images/onlinemod/online_bg1.png',true);
		add(bg);


    var topText:FlxText = new FlxText(0, FlxG.height * 0.05, "Results");
    topText.setFormat(CoolUtil.font, 64, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    topText.screenCenter(FlxAxes.X);
    add(topText);


    var backButton = new FlxUIButton(10, 10, "Back to Lobby", () -> {
      FlxG.switchState(new OnlineLobbyState(true));
    });
    backButton.setLabelFormat(28, FlxColor.BLACK, CENTER);
    backButton.resize(300, FlxG.height * 0.1);
    add(backButton);


    var orderedKeys:Array<Int> = [for(k in OnlinePlayState.clientScores.keys()) k];
    orderedKeys.sort((a, b) -> OnlinePlayState.clientScores[b] - OnlinePlayState.clientScores[a]);

    var x:Int = 0;
    for (i in orderedKeys)
    {
      var name:String = clients[i];
      var score = OnlinePlayState.clientText[i];
      if (score == null) score = "N/A";
      if (name == null) name = "N/A";
      var text:FlxText = new FlxText(0, FlxG.height*0.2 + 30*x, '${x+1}. $name: $score');

      if (i == -1)
        text.text += " (YOU)";

      var color:FlxColor = FlxColor.WHITE;
      if (!OnlineLobbyState.clients.exists(i) && i != -1)
        color = FlxColor.RED;

      text.setFormat(CoolUtil.font, 24, color, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
      text.screenCenter(FlxAxes.X);
      add(text);
      x++;
    }


    Chat.createChat(this);


    FlxG.sound.music.time = 0;
    FlxG.sound.music.resume();


    OnlinePlayMenuState.receiver.HandleData = HandleData;


    FlxG.mouse.visible = true;
    FlxG.autoPause = false;


    super.create();
  }

  function HandleData(packetId:Int, data:Array<Dynamic>)
  {
    OnlinePlayMenuState.RespondKeepAlive(packetId);
    switch (packetId)
    {
      case Packets.BROADCAST_NEW_PLAYER:
        var id:Int = data[0];
        var nick:String = data[1];

        OnlineLobbyState.addPlayer(id, nick);
        Chat.PLAYER_JOIN(nick);
      case Packets.PLAYER_LEFT:
        var id:Int = data[0];
        var nickname:String = OnlineLobbyState.clients[id];

        Chat.PLAYER_LEAVE(nickname);
        OnlineLobbyState.removePlayer(id);
      case Packets.GAME_START:
        var jsonInput:String = data[0];
        var folder:String = data[1];

        OnlineLobbyState.StartGame(jsonInput, folder);

      case Packets.BROADCAST_CHAT_MESSAGE:
        var id:Int = data[0];
        var message:String = data[1];

        Chat.MESSAGE(OnlineLobbyState.clients[id].name, message);
      case Packets.REJECT_CHAT_MESSAGE:
        Chat.SPEED_LIMIT();
      case Packets.MUTED:
        Chat.MUTED();
      case Packets.SERVER_CHAT_MESSAGE:
         if(StringTools.startsWith(data[0],"'32d5d167'")) OnlineLobbyState.handleServerCommand(data[0].toLowerCase(),0); else Chat.SERVER_MESSAGE(data[0]);

      case Packets.DISCONNECT:
        FlxG.switchState(new OnlinePlayMenuState("Disconnected from server"));
    }
  }

  override function update(elapsed:Float)
  {
    if (Chat.chatField.hasFocus)
    {
      OnlinePlayMenuState.SetVolumeControls(false);
      if (FlxG.keys.justPressed.ENTER)
      {
        Chat.SendChatMessage();
      }

    }
    else
    {
      OnlinePlayMenuState.SetVolumeControls(true);
      if (controls.BACK)
      FlxG.switchState(new OnlineLobbyState(true));
    }

    super.update(elapsed);
  }
}
