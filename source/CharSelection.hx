package;
// About 90% of code used from OfflineMenuState
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxInputText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import sys.io.File;
import TitleState;

using StringTools;

class CharSelection extends SearchMenuState
{
	var defText:String = "Use shift to scroll faster";
	var exampleImage:FlxSprite;
	var uiIcon:HealthIcon;
	var charNameText:FlxText;
	var curChar = "";
	var curCharNameSpaced = "";
	var curCharID = 0;
	var isNameSpaced:Bool = false;
	// Type
	// -1 = automatic
	// 0 = valid
	// 1 = invalid
	var chars:Array<Array<Dynamic>> = []; // [NAME,TYPE,ID,DESCRIPTION,OBJ]
	var charIDList:Array<Int> = [];
	override function reloadList(?reload:Bool = false,?search:String=""){try{
			curSelected = 0;
			if(reload){CoolUtil.clearFlxGroup(grpSongs);}
			songs = [];
			charIDList = [];
			charIDList[-1] = -1;
			searchList = songs;

			var i:Int = 0;
			var query = new EReg((~/[-_ ]/g).replace(search.toLowerCase(),'[-_ ]'),'i');
			for (i => char in chars){
				if(search == "" || query.match(char[0].toLowerCase()) ){
					_addToList(char,i);
				}
			}
		}catch(e) MainMenuState.handleError('Error with loading stage list ${e.message}');
	}
	function _addToList(char:Array<Dynamic>,i:Int = 0){
		songs.push(char[0]);
		charIDList.push(i);
		var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, char[0], true, false);
		controlLabel.cutOff = 12;
		controlLabel.isMenuItem = true;
		controlLabel.targetY = i;
		if (i != 0) controlLabel.alpha = 0.6;
		if(char[1] == 1){
			controlLabel.color = FlxColor.RED;
		}else if(!isNameSpaced){
			if(char[4] != null && char[4].getNamespacedName().toLowerCase() == curCharNameSpaced){
				curCharID = i;
				isNameSpaced = true;
				controlLabel.color = FlxColor.GREEN;
				trace('found ns at $i ${char[0]}/$curChar');
			}else if(char[0].toLowerCase() == curChar){
				curCharID = i;
				controlLabel.color = FlxColor.GREEN;
				trace('found at $i ${char[0]}/$curChar');
			}
		}


		grpSongs.add(controlLabel);
	}

	override function create()
	{try{
		TitleState.checkCharacters();
		scriptSubDirectory = "/charselect/";
		switch (Options.PlayerOption.playerEdit){
			case 0: curChar = SESave.data.playerChar;
			case 1: curChar = SESave.data.opponent;
			case 2: curChar = SESave.data.gfChar;
		}
		// var char = TitleState.findCharByNamespace(curChar);
		// trace('$curChar;$char');
		if(curChar.contains('|')){
			var e = curChar.indexOf("|");
			curChar = (curCharNameSpaced = curChar.toLowerCase()).substring(e + 1);
		}else{
			curCharNameSpaced = curChar = curChar.toLowerCase();
		}

		chars = [];
		if (Options.PlayerOption.playerEdit == 0){
			chars.push(['automatic',-1,'Automatically choose whatever BF is suitable for the chart']);
		}
		searchList = [];
		if(TitleState.invalidCharacters.length > 0 && onlinemod.OnlinePlayMenuState.socket == null){
			for (i => v in TitleState.invalidCharacters) {
				chars.push([v.id,1,i,null,v]);
			}
		}
		for (i => v in TitleState.characters) {
			if(!v.hidden){
				chars.push([v.id,0,i,v.description,v]);
			}
		}

		super.create();
		loadScripts();
		infoTextBorder.makeGraphic(500,720,FlxColor.BLACK);
		infoTextBorder.setPosition(1280 - infoTextBorder.width,140);
		infotext.fieldWidth = infoTextBorder.width - 20;
		var title = "";
		switch (Options.PlayerOption.playerEdit){
			case 0: title="Change BF";bg.color = 0x007799;
			case 1: title="Change Opponent";bg.color = 0x600060;
			case 2: title="Change GF";bg.color = 0x771521;
			default: title= "You found a 'secret',\n You should exit this menu to prevent further 'secret's";bg.color = 0xff0000;
		}



		if (title != "") addTitleText(title);
		titleText.screenCenter(X);
		if (onlinemod.OnlinePlayMenuState.socket == null) defText = "Use shift to scroll faster;\nCharacter Editor keys: 1=bf, 2=dad, 3=gf;\n";
		if(!SESave.data.performance){

			uiIcon = new HealthIcon("face",Options.PlayerOption.playerEdit == 0);
			uiIcon.updateAnim(100);
			uiIcon.x = infoTextBorder.x + (infoTextBorder.width * 0.5) - (uiIcon.width * 0.5);
			uiIcon.y = infoTextBorder.y + 50;
			uiIcon.centerOffsets();
			overLay.add(uiIcon);
		}

		// exampleImage = new FlxSprite();
		// exampleImage.scrollFactor.set();
		// exampleImage.visible = false;
		// overLay.add(exampleImage);

		charNameText = new FlxText(5, uiIcon.y + uiIcon.height + 10, 0, "yes", 20);
		charNameText.wordWrap = false;
		charNameText.scrollFactor.set();
		charNameText.setFormat(CoolUtil.font, 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		overLay.add(charNameText);

		// FlxTween.angle(uiIcon, -40, 40, 1.12, {ease: FlxEase.quadInOut, type: PINGPONG});  
		changeSelection(curCharID); 

	}catch(e) MainMenuState.handleError('Error with charsel "create" ${e.message}');}
	override function extraKeys(){
		var curSelected =getChar();
		if (chars[curSelected] != null && chars[curSelected][1] != -1 && onlinemod.OnlinePlayMenuState.socket == null){
			var _char = formatChar(chars[curSelected]);
			if(chars[curSelected][4].type == 1 && (FlxG.keys.justPressed.ONE || FlxG.keys.justPressed.TWO || FlxG.keys.justPressed.THREE)){
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxTween.tween(grpSongs.members[curSelected], {x: grpSongs.members[curSelected].x + 100}, 0.4, {ease: FlxEase.bounceInOut,onComplete: function(twn:FlxTween){return;}});
				FlxTween.tween(infotext, {alpha:0}, 0.2, {ease: FlxEase.quadInOut,onComplete: function(twn:FlxTween){FlxTween.tween(infotext, {alpha:1}, 0.2, {ease: FlxEase.quadInOut,onComplete: function(twn:FlxTween){return;}});}});
				
				updateInfoText('This character is a script based character and cannot be edited!');
				
				retAfter = false;
				return;
			}else{

				if (FlxG.keys.justPressed.ONE)  {LoadingScreen.loadAndSwitchState(new AnimationDebug(_char,true ,0,true));}
				if (FlxG.keys.justPressed.TWO)  {LoadingScreen.loadAndSwitchState(new AnimationDebug(_char,false,1,true));}
				if (FlxG.keys.justPressed.THREE){LoadingScreen.loadAndSwitchState(new AnimationDebug(_char,false,2,true));}
			}
		}
	}
	inline function formatChar(char:Array<Dynamic>):String{
		return ((char[1] == 1 ? "INVALID|" : ((char[4] != null && char[4].nameSpace != null) ? '${char[4].nameSpace}|' : "")) +'${char[0]}');
	}
	inline function getChar(){
		return charIDList[curSelected];
	}
	inline function updateName(?name = "funninameherelmaomlmaonjosn"){
		if(name != "funninameherelmaomlmaonjosn"){
			charNameText.text = name;
			charNameText.x = (infoTextBorder.x + (infoTextBorder.width * 0.5) - (charNameText.width * 0.5));
		}

	}
	override function updateInfoText(str:String = ""){
		if(infotext != null){
			infotext.text = str;
			infotext.wordWrap = true;
			infotext.scrollFactor.set();
			infotext.y = uiIcon.y + uiIcon.height + 50;
			infotext.x = infoTextBorder.x + 10;
		}
	}
	override function changeSelection(change:Int = 0){
		var _oldSel = curSelected;
		super.changeSelection(change);
		// if(_oldSel != curSelected){
		// 	grpSongs.members[_oldSel].cutOff = 12;
		// }
		retAfter = true;
		var curSelected =getChar();
		var char = chars[curSelected];
		// if(!SESave.data.performance){
		// 	try{
		// 		if(char != null && char[4] != null && SELoader.exists('${char[4].path}/${char[4].folderName}/charSel.png')){
		// 			exampleImage.loadGraphic(SELoader.loadGraphic('${char[4].path}/${char[4].folderName}/charSel.png'));
		// 			// exampleImage.x = 
		// 			if(exampleImage.width >= 1280 || exampleImage.width >= 720){
		// 				exampleImage.screenCenter(XY);
		// 			}
		// 			exampleImage.visible = true;
		// 			uiIcon.visible = false;
		// 		}else{
		// 			uiIcon.visible = true;
		// 			exampleImage.visible = false;
		// 		}
		// 	}catch(e){
		// 		showTempmessage('Unable to show characters image: ${e.message}');
		// 	}
		// }

		// if (songs[curSelected] != "" && TitleState.invalidCharacters.contains(songs[curSelected])){
		// 	grpSongs.members[curSelected].color = FlxColor.RED;
		// 	updateInfoText();
		// }else 

		var text = '${defText}';
		if(char != null){
			if(char[4] != null){
				if(char[4].nameSpace == "" || char[4].nameSpace == null || char[4].nameSpace == "SECharactersFolder") text+="Provided by your characters folder;\n";
				else if(char[4].nameSpace == "INTERNAL") text+="Provided by the base game;\n";
				else text+='Provided by ${char[4].nameSpace};\n';
			}
			if(char[1] == 1){
				text+="This character is invalid, you need to set them up in the Character Editor.\nTo set them up now:\n Press 1 for a Player\n Press 2 for an Opponent\n or Press 3 for a GF.\nIf you need help please ask on my Discord" + #if(!mobile) ", you can access it from the changelog screen" + #end ";\n";
			}else if(char[3] == null){
				text+='\nThis character has no description.\n\nYou can provide one by making a description.txt inside of the characters folder with the description';
			}else{
				text+='\n${char[3]}';
			}
		}
		updateInfoText(text);
		updateName((if(char == null || char[0] == null) "Unknown?!?!?" else char[0]));
		if(!SESave.data.performance){
			if(chars[curSelected][4] == null){
				uiIcon.changeSprite(formatChar(chars[curSelected]),'face',false,((char == null || char[4] == null ) ? null : chars[curSelected][4].path));

			}else{
				uiIcon.fromCharInfo(chars[curSelected][4]); 
			}
			uiIcon.x = infoTextBorder.x + (infoTextBorder.width * 0.5) - (uiIcon.width * 0.5);
			uiIcon.y = infoTextBorder.y + 50;
			uiIcon.centerOffsets();
			uiIcon.updateAnim((char[1] == 1) ? 0 : 100);
		}

	}

	override function select(sel:Int = 0){
		var _char = 'automatic';
		var curSelected =getChar();
		retAfter = true;

		if(curSelected == -1){
			SESave.data.playerChar = 'automatic';

			return;
		}
		if(chars[curSelected][1] == 1){
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxTween.tween(grpSongs.members[curSelected], {x: grpSongs.members[curSelected].x + 100}, 0.4, {ease: FlxEase.bounceInOut,onComplete: function(twn:FlxTween){return;}});
			FlxTween.tween(infotext, {alpha:0}, 0.2, {ease: FlxEase.quadInOut,onComplete: function(twn:FlxTween){FlxTween.tween(infotext, {alpha:1}, 0.2, {ease: FlxEase.quadInOut,onComplete: function(twn:FlxTween){return;}});}});
			if(grpSongs.members[curSelected].x > 500){
				updateInfoText('This character\'s invalid dammit! To set them up now, press 1 for BF, 2 for dad, 3 for GF. If you need help please ask on my Discord, you can access it from the changelog screen');
			}
			retAfter = false;
			return;
		}

		var _char =formatChar(chars[curSelected]);

		switch (Options.PlayerOption.playerEdit){
			case 0:
				SESave.data.playerChar = _char;
			case 1:
				SESave.data.opponent = _char;
			case 2:
				SESave.data.gfChar = _char;
		}
		// for(i in 0...grpSongs.members.length){
		// 	if(grpSongs.members[i].color == FlxColor.GREEN){
		// 		grpSongs.members[i].color = FlxColor.WHITE;
		// 		break;
		// 	}
		// }
		// grpSongs.members[curSelected].color = FlxColor.GREEN;
	}
	var _iconTween:FlxTween;
	override function beatHit(){
		super.beatHit();
		uiIcon.scale.set(1.1,1.1);
		if(_iconTween != null)_iconTween.cancel();
		_iconTween = FlxTween.tween(uiIcon.scale, {x: 1,y: 1}, Conductor.stepCrochet * 0.003, {ease: FlxEase.quadOut});
	}
}