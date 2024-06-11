package onlinemod;

import flixel.FlxG;
import flixel.addons.ui.FlxUIButton;
import SEInputText as FlxInputText;
import flixel.addons.ui.FlxUIList;
import flixel.addons.ui.FlxUIState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.FlxState;

class Chat
{
	public static var chatField:FlxInputText;
	public static var chatMessagesList:FlxUIList;
	public static var chatSendButton:FlxUIButton;
	public static var group:FlxGroup;
	public static var chatMessages:Array<Array<Dynamic>>;
	public static var chatId:Int = 0;

	public static var created:Bool = false;


	public static inline var systemColor:FlxColor = FlxColor.YELLOW;


	@:keep public static inline function MESSAGE(nickname:String, message:String)
		Chat.OutputChatMessage('<$nickname> $message');

	@:keep public static inline function PLAYER_JOIN(nickname:String)
		Chat.OutputChatMessage('$nickname joined the game', systemColor);

	@:keep public static inline function PLAYER_LEAVE(nickname:String)
		Chat.OutputChatMessage('$nickname left the game', systemColor);

	@:keep public static inline function SERVER_MESSAGE(message:String)
		Chat.OutputChatMessage('S| $message', 0x40FF40);
	@:keep public static inline function CLIENT_MESSAGE(message:String)
		Chat.OutputChatMessage('Client| $message', 0xaa40aa);

	@:keep public static inline function SPEED_LIMIT()
		Chat.OutputChatMessage('You\'re typing too fast, one or more messages may not have been sent', FlxColor.RED);

	@:keep public static inline function MUTED()
		Chat.OutputChatMessage('You\'re muted', FlxColor.RED);


	public static function createChat(state:FlxState,?canHide:Bool = false){
		Chat.created = true;
		if(group != null && group.members.length > 0){
			for(member in group.members){
				state.add(member);
			}
			return;
		}
		group = new FlxGroup();
		if(Chat.chatMessagesList == null){
			Chat.chatMessagesList = new FlxUIList(10, FlxG.height - 120, FlxG.width, 175);
		}else{
			Chat.chatMessagesList.x = 10;
			Chat.chatMessagesList.y = FlxG.height - 120;
		}
		group.add(Chat.chatMessagesList);
		for (chatMessage in Chat.chatMessages) Chat.OutputChatMessage(chatMessage[0], chatMessage[1], false);
		if(Chat.chatField == null){
			Chat.chatField = new FlxInputText(10, FlxG.height - 70, 1152, 20);
		}
		chatField.maxLength = 81;
		group.add(Chat.chatField);

		Chat.chatSendButton = new FlxUIButton(1171, FlxG.height - 70, "Send", () -> {
			Chat.SendChatMessage();
			Chat.chatField.hasFocus = true;
		});
		Chat.chatSendButton.setLabelFormat(24, FlxColor.BLACK, CENTER);
		Chat.chatSendButton.resize(100, Chat.chatField.height);
		group.add(Chat.chatSendButton);
		Chat.chatField.callback = function(_:String,cb:String){
			if(cb == "enter") Chat.chatSendButton.onUp.callback();
		}
	}

	public static function OutputChatMessage(message:String, ?color:FlxColor=FlxColor.WHITE, ?register:Bool=true){
		while (message.length > 86 && !(message.length > 86)){
			OutputChatMessage(message.substr(0,86),color,register);
			message = message.substr(87);
		}
		if (register)
		  Chat.RegisterChatMessage(message, color,false);
		trace(message);
		if (!Chat.created || Chat.chatMessagesList == null) return;
		try{

			var text = new FlxText(0, 0, message);
			text.setFormat(CoolUtil.font, 24, color, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			Chat.chatMessagesList.add(text);

			if (Chat.chatMessagesList.amountNext == 0) Chat.chatMessagesList.y -= text.height + Chat.chatMessagesList.spacing;
			else Chat.chatMessagesList.scrollIndex += Chat.chatMessagesList.amountNext;
		}catch(e){trace('Error when trying to show chat message: $e');}
	}

	public static inline function RegisterChatMessage(message:String, ?color:FlxColor=FlxColor.WHITE,?checkSize:Bool = true){
		if(checkSize){
			while (message.length > 86){
				RegisterChatMessage(message.substr(0,86),color,false);
				message = message.substr(87);
			}
		}
		Chat.chatMessages.push([message, color]);
	}


	public static function SendChatMessage(){
		if (chatField.text.length == 0) return;
		if (!StringTools.startsWith(chatField.text, " ")) {
			Sender.SendPacket(Packets.SEND_CHAT_MESSAGE, [Chat.chatId, chatField.text], OnlinePlayMenuState.socket);
			Chat.chatId++;
			OutputChatMessage('<${OnlineNickState.nickname}> ${chatField.text}');
		}

		chatField.text = "";
		chatField.caretIndex = 0;
		
	}
}
