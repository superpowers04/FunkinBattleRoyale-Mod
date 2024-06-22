package onlinemod;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIButton;
import SEInputText as FlxInputText;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import onlinemod.Player;

class OnlineNickState extends MusicBeatState
{
  var errorText:FlxText;
  var nickField:FlxInputText;

  public static var nickname:String;

  override function create()
  {
	var bg:FlxSprite = SELoader.loadFlxSprite('assets/images/menuDesat.png',true);
	bg.color = 0xFFFF6E6E;
	add(bg);


	var topText = new FlxText(0, FlxG.height * 0.25, "Insert nickname");
	topText.setFormat(CoolUtil.font, 64, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	topText.screenCenter(FlxAxes.X);
	add(topText);


	errorText = new FlxText(0, FlxG.height * 0.375, FlxG.width, "");
	errorText.setFormat(CoolUtil.font, 32, FlxColor.WHITE, CENTER);
	add(errorText);


	var nickText:FlxText = new FlxText(FlxG.width/2 - 250, FlxG.height * 0.5 - 40, "Nickname:");
	nickText.setFormat(CoolUtil.font, 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	add(nickText);

	nickField = new FlxInputText(0, FlxG.height * 0.5, 500, 32);
	nickField.setFormat(32, FlxColor.BLACK, CENTER);
	nickField.screenCenter(FlxAxes.X);
	nickField.customFilterPattern = ~/[^A-Za-z0-9.-]/;
	nickField.maxLength = 13;
	nickField.hasFocus = true;
	add(nickField);


	var confirmButton = new FlxUIButton(0, FlxG.height * 0.65, "Confirm", () -> {
	  
		if (OnlinePlayMenuState.socket != null && OnlinePlayMenuState.socket.connected){
			var _Player = OnlineLobbyState.clients[-1] = new Player(SESave.data.nickname = nickname = nickField.text,-1);
			_Player.self = true;
			OnlineLobbyState.client = _Player; 
			Sender.SendPacket(Packets.SEND_NICKNAME, [nickname], OnlinePlayMenuState.socket);
		}else{
			FlxG.switchState(new OnlinePlayMenuState('Socket closed unexpectedly?'));

		}
	});
	confirmButton.setLabelFormat(32, FlxColor.BLACK, CENTER);
	confirmButton.resize(300, FlxG.height * 0.1);
	confirmButton.screenCenter(FlxAxes.X);
	add(confirmButton);


	OnlinePlayMenuState.AddXieneText(this);


	FlxG.mouse.visible = true;


	OnlinePlayMenuState.receiver.HandleData = HandleData;

	nickField.text = SESave.data.nickname;
	super.create();
  }

  function HandleData(packetId:Int, data:Array<Dynamic>)
  {
	switch (packetId)
	{
		case Packets.NICKNAME_CONFIRM:{

			switch (data[0]) {
			  case 0:
				SetErrorText("Nickname accepted", FlxColor.LIME);
				FlxG.switchState(new OnlineLobbyState());
			  case 1:
				SetErrorText("Nickname already claimed");
			  case 2:
				SetErrorText("Game already in progress");
			  case 3:
				SetErrorText("Invalid nickname");
			  case 4:
				FlxG.switchState(new OnlinePlayMenuState("Game is already full"));
			}
			return true;
		}

	}
	return false;
  }

  override function update(elapsed:Float)
  {
	if (!nickField.hasFocus)
	{
	  if (controls.BACK)
	  {
		FlxG.switchState(new OnlinePlayMenuState());

		if (OnlinePlayMenuState.socket.connected)
		{
		  OnlinePlayMenuState.socket.close();
		}
	  }
	}


	super.update(elapsed);
  }

  function SetErrorText(text:String, color:FlxColor=FlxColor.RED)
  {
	errorText.text = text;
	errorText.setFormat(32, color);
	errorText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
  }
}
