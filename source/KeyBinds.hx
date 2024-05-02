import flixel.FlxG;
import flixel.input.FlxInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionInputDigital;
import flixel.input.actions.FlxActionManager;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

class KeyBinds
{

	public static var gamepad:Bool = false;
	public static var defaultKeys:Array<Array<String>> = [
		["A","S","W","D",'J','K','I','L',"R","ZERO","MINUS","PLUS"],
		["A","D"],
		["A","SPACE","D"],
		["A","S","W","D","Z","X","N","M"],
		["A","S","SPACE","W","D"],
		["S","D","F","J","K","L"],
		["S","D","F","SPACE","J","K","L"],
		["A","S","D","F","J","K","L","SEMICOLON"],
		["A","S","D","F","SPACE","J","K","L","SEMICOLON"],
		["Q","W","E","R","V","N","U","I","O","P"],
		["Q","W","E","R","V","Space","N","U","I","O","P"],
		["A","S","D","F","C","V","N","M","J","K","L","SEMICOLON"],
		["A","S","D","F","C","V","SPACE","N","M","J","K","L","SEMICOLON"],
		["Q","W","E","R","S","D","F","J","K","L","U","I","O","P"],
		["Q","W","E","R","S","D","F","SPACE","J","K","L","U","I","O","P"],
		["Q","W","E","R","A","S","D","F","H","J","K","L","U","I","O","P"],
		["Q","W","E","R","A","S","D","F","SPACE","H","J","K","L","U","I","O","P"],
		["Q","W","E","R","A","S","D","F","V","B","H","J","K","L","U","I","O","P"],
		["Q","W","E","R","A","S","D","F","C","V","SPACE","N","M","H","J","K","L","U","I","O","P"],
	];

	public static function keyCheck():Void{
		for(count => keys in defaultKeys){
			var _keys = SESave.data.keys[count];
			if(_keys == null){
				SESave.data.keys[count] = keys.copy();
				continue;
			}
			for(index => key in keys){
				if(_keys[index] != null) continue;
				_keys[index] = key;
			}
		}
		SESave.data.leftBind = SESave.data.keys[0][0];
		SESave.data.downBind = SESave.data.keys[0][1];
		SESave.data.upBind = SESave.data.keys[0][2];
		SESave.data.rightBind = SESave.data.keys[0][3];
		SESave.data.AltupBind = SESave.data.keys[0][4];
		SESave.data.AltdownBind = SESave.data.keys[0][5];
		SESave.data.AltleftBind = SESave.data.keys[0][6];
		SESave.data.AltrightBind = SESave.data.keys[0][7];
		SESave.data.killBind = SESave.data.keys[0][8];
		if(FlxG.sound.volumeUpKeys != null) CoolUtil.toggleVolKeys(true);
	}
	public static function resetBinds():Void{
		SESave.data.keys = [];
		for(count => keys in defaultKeys){
			SESave.data.keys[count] = keys.copy();
		}
		keyCheck();
		if (SESave.data.AltupBind == null) SESave.data.AltupBind = "F12";
		if (SESave.data.AltdownBind == null) SESave.data.AltdownBind = "F12";
		if (SESave.data.AltleftBind == null) SESave.data.AltleftBind = "F12";
		if (SESave.data.AltrightBind == null) SESave.data.AltrightBind = "F12";
		PlayerSettings.player1.controls.loadKeyBinds();
	}

}