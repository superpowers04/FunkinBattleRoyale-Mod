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

import sys.io.File;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

using StringTools;

class ArrowSelection extends SearchMenuState
{
	public var playerStrums:FlxTypedGroup<StrumArrow> = new FlxTypedGroup<StrumArrow>();
	function generateStaticArrows(player:Int,?skin:String):Void{
		for (i in 0...4){
			// FlxG.log.add(i);
			var babyArrow:StrumArrow = new StrumArrow(i,0, if (SESave.data.downscroll) FlxG.height - 165 else 50,skin);

			babyArrow.init();
			// babyArrow.x += Note.swagWidth * i + i;

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();
			babyArrow.alpha = 0;
			FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			playerStrums.add(babyArrow);
			babyArrow.playStatic();
			babyArrow.screenCenter(X);
			babyArrow.x += ((babyArrow.width + 20) * babyArrow.id - 2); 
		}
	}
	override function create(){
		{ // Looks for all notes, This will probably be rarely accessed, so loading like this shouldn't be a problem
			
			searchList = ["default"];

			var dataDir:String = "mods/noteassets/";
			var customArrows:Array<String> = [];
			if (SELoader.exists(dataDir)) {
				for (file in SELoader.readDirectory(dataDir)) {
					if (file.endsWith(".png") && !file.endsWith("-bad.png") && !file.endsWith("-splash.png")){
						var name = file.substr(0,-4);
						if (SELoader.exists('${dataDir}${name}.xml'))
						{
							customArrows.push(name);

						}
					}
				}
			}else{MainMenuState.handleError('mods/noteassets is not a folder. You need to create it to use custom arrow skins!');}
			{
				var dataDir = "mods/packs/";
				for (_dir in SELoader.readDirectory(dataDir)) {
					var dataDir = 'mods/packs/$_dir/noteassets/';
					if(SELoader.exists(dataDir)) {

						for (file in SELoader.readDirectory(dataDir)) {
							if (file.endsWith(".png") && !file.endsWith("-bad.png") && !file.endsWith("-splash.png")) {
								var name = file.substr(0,-4);
								if (SELoader.exists('${dataDir}${name}.xml')) {
									// Really shit but it works
									customArrows.push('../packs/$_dir/noteassets/$name');

								}
							}
						}
					}
				}
			}
			// customCharacters.sort((a, b) -> );
			haxe.ds.ArraySort.sort(customArrows, function(a, b) {
						 if(a < b) return -1;
						 else if(b > a) return 1;
						 else return 0;
					});
			for (char in customArrows){
				searchList.push(char);
			}
		}

		generateStaticArrows(1,'skin');
		super.create();
		bg.color = 0xFFFF6E6E;
		infotext.text = "Hold shift to scroll faster, Press CTRL to toggle viewing the entire note asset";
		add(playerStrums);

		changeSelection();
	}
	override function addToList(char:String,i:Int = 0){
		songs.push(char);
		if(char.indexOf('packs/') != -1){
			char = char.substr(char.indexOf('packs/') + 6).replace('noteassets/',"");
		}
		var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, char, true, false,false,useAlphabet);
		controlLabel.isMenuItem = true;
		controlLabel.targetY = i;
		if (i != 0)
			controlLabel.alpha = 0.6;
		grpSongs.add(controlLabel);
	}
	override function update(e){ // This is shit but I don't want these to update
		// members.pop();
		super.update(e);
		// members.push(notes);
	}
	override function beatHit(){
		super.beatHit();
		if(playerStrums.members[curBeat % 4] != null) {
			playerStrums.members[curBeat % 4]?.confirm();
			playerStrums.members[(curBeat - 2) % 4]?.playStatic();
			playerStrums.members[(curBeat - 1) % 4]?.press();
		}

	}
	// override function extraKeys(){
		// if(FlxG.keys.justPressed.CONTROL) {arrowDisplay = !arrowDisplay;updateArrowDisplay();}
	// }
	var arrowDisplay:Bool = false;
	public var notes:FlxTypedGroup<FakeNote> = new FlxTypedGroup<FakeNote>();
	inline static var time = 100000000000;
	public function updateArrowDisplay(){
		if(playerStrums.members[0] == null) return;
		if(arrowDisplay && notes.members[0] == null) {

			add(notes);
			var note:FakeNote = null;
			var noteSus:FakeNote = null;
			var noteSusEnd:FakeNote = null;
			var strumNote:StrumArrow = null;
			// for (i in 0 ... 4) {
			// 	strumNote = playerStrums.members[i];
			// 	note = new FakeNote(time,i,null,false);
			// 	noteSus = new FakeNote(time,i,note,true);
			// 	noteSusEnd = new FakeNote(time,i,noteSus,true);

			// 	note.x = strumNote.x + (strumNote.width * 0.5);
			// 	noteSus.x = strumNote.x + (strumNote.width * 0.5);
			// 	noteSusEnd.x = strumNote.x + (strumNote.width * 0.5);

			// 	note.y = strumNote.y + strumNote.height;
			// 	noteSus.y = note.y + note.height;
			// 	noteSusEnd.y = noteSus.y + noteSus.height * 2;

			// 	notes.add(note);
			// 	notes.add(noteSus);
			// 	notes.add(noteSusEnd);
			// }
		}
		for (i in notes.members) {
			i.visible = arrowDisplay;
		}
		// if(notes.members[0] != null && arrowDisplay){
		// 	var i:Int = 0;
		// 	var note:FakeNote = null;
		// 	while (i < notes.members.length) {
		// 		notes.members[i].changeSprite(songs[curSelected]);
		// 		i++;
		// 	}
		// }
	}
	override function changeSelection(change:Int = 0) {
		super.changeSelection(change);
		for (arrow in playerStrums.members){
			playerStrums.remove(arrow);
			arrow.destroy();
		}
		generateStaticArrows(1,songs[curSelected]);
		updateArrowDisplay();
	}
	override function select(sel:Int = 0) {
		SESave.data.noteAsset = songs[curSelected];

	}
}



