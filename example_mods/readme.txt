This was last updated as of 0.11.0.

This file might look weird inside of Notepad, I highly recommend using Notepad++, SublimeText or VSCode for editing and reading text files

If this file is confusing or you need help, feel free to join the Discord server and ask for help https://discord.gg/28GPGTRuuR
It is highly recommended you do NOT follow any youtube or video tutorials, changes to the engine could make them outdated or they could modify the game in unintended ways

FOLDERS AND WHAT THEY MEAN:
 - stages | Where custom stages go
 - characters | Where custom characters go
 - charts | Where charts will go. You can just put the json files, inst and voices in a folder and Super Engine will automatically read them
 - noteassets | You can put a png and xml from note skins here
 - weeks | Where weeks go, eventually there should be documentation on how to make them at https://github.com/superpowers04/Super-Engine/wiki
 - packs | You can make folders and then put charts and characters inside of them to organise your charts, characters and add pack specific scripts without having 20 copies of the same script. While this isn't required, it might make your mods folder less of a mess
 - scripts | Global scripts that you can use to do things like adding new features and such, scripts can contain options and such. 
    Look at https://cdn.discordapp.com/attachments/908215636352716831/916629405147742228/Arrow_Options.zip for an example
    You can find a wiki here: https://github.com/superpowers04/Super-Engine/wiki/Character-and-Chart-scripts
 
EXTRA FILES:
 You can use custom title music by adding oggs:
  Morning theme is from 6(6 AM) to 11(11 AM) - breakfast or mods/title-morning.ogg
  Regular theme is from 11(11 AM) to 18(6 PM) - Gettin' Freaky or mods/title-day.ogg
  Evening theme is from 18(6 PM) to 22(10 PM) - Give a Lil Bit Back or mods/title-evening.ogg
  Night theme is active from 22(10 PM) to 6(6 AM) - Fresh Chill Mix or mods/title-night.ogg
 You can also manually edit the mods/menuTimes.json that's generated by the game
 
 A custom background can be used by placing a png named bg.png in the mods folder. 
  The game's resolution is about 1280px Horizontally and 720px vertically
 
 Custom fonts can be used by putting a ttf file named font.ttf in your mods folder. 
  This can be enforced with Visibility > Force Generic Font, note that not all menus will work with all fonts and some things might appear off.
  A good font that could be used is https://gamebanana.com/tools/8509, it keeps the funkin style in places that a normal font is used

ENABLING DEBUG/CONTENT CREATION MODE:
	You can find this under Modifications in Options, labeled "Content Creation".


Lua Scripting Support:
	Due to bugs, lua's been disabled for now.

CONTENT CREATION MODE:
	Enabling Content Creation Mode will allow you to access a whole bunch of developer utilities as outlined here.

	If you press F10, you can open a console. This allows you to view the game's output, run some commands and code while the game's running.

	Pressing Shift+F8 will partially pause the game and enable the debug overlay. You can use this to move around objects
		Left Click will grab an object
		 - Pressing Shift while clicking will prevent the game from looping groups
		 - Pressing Ctrl while clicking will reverse the grab order, you can use this to grab objects behind other objects
		 - Scrolling will rotate the held object
		 - Holding ALT will give you the position of the object you're hovering over
		Right Click will move the camera
		 - Scrolling will zoom in and out
		Pressing 3 will trace the position of the last clicked object to the console



ADDING EXISTING CHARTS:
	There are multiple ways to do this:

	The main way is to move the chart and it's respective Inst.ogg/Voices.ogg's to a new folder named the song inside of mods/charts
	
	You can make folders inside of mods/packs to organise your songs, make a new folder inside of Packs, named whatever. 
		Make a charts folder inside of that, then put your songs from mods/charts into there

	You can also use the Import Songs From Existing Mods option

	If you don't want to add a song but would like to play it, just drag and drop the chart into your game. The game will try to detect the Inst and Voices from there.


MAKING CHARTS:
	Go to Options > Modifications > Content Creation Mode and turn it on. 
	Make a new folder inside of mods/charts named the song
	Move your audio files(Inst.ogg and Voices.ogg, Make sure they're properly converted and not just renamed MP3's) into the folder
	Open Modded Songs, hover over the song like you're about to play it and press 7(Or right click on the song)
	Then you're free to chart, just don't forget to save


MAKING CHARACTERS:
 Importing the characters:
	There are 2 ways to do this
	1:
		Make a new folder inside of mods/characters,
		then drop the png and xml into the folder, and rename them to "character.png" and "character.xml". (If you don't see .png or .xml on the original file names then they aren't needed)
 	2:
 		Drag and drop the png onto the game, select the name you want and press continue
 Ingame:
	Go to Options > Modifications > Content Creation Mode and make sure it's on. 
	Go to Options > Modifications > Opponent Character > find your character(All invalid characters appear at the top) and then Press 2. 
	You can press H for help with using animation debug.
	Press M to open a menu for switching between offsetting, repositioning the camera and the add animations/config editor
	Saving after adding animations is recommended.

	If you want to edit a BF character, add the animations the character as an opponent. 
	Upon exiting the animation binder, press 3 to save, then 7 to switch over to offsetting for BF

	*BF characters usually use inverted animations so BF NOTE RIGHT will be singLEFT and BF NOTE LEFT will be singRIGHT.
 
 
 If there are things you'd like to do that aren't possible with the animation editor, editing the json manually might be a good idea.
 You can find the older wiki page for character jsons here: https://github.com/superpowers04/Super-Engine/wiki/Character-JSON
 You can also provide a script.hscript to add custom scripting to your characters for things like custom animations, character position manipulation and more
 
MAKING STAGES:
	Stages are more complex than making a character as there is no Stage Debug or Stage Maker. 
	Stages are handled through scripts instead of a json, this makes them much harder to get into, but you can do some really cool things with stages as they are basically just a script
	If you end up getting confused or need help, feel free to ask for help on the Discord server

	I'd recommend getting a better text editor like Sublime Text or Notepad++ as they are easier to code with than Notepad. 
	* If you're using sublime text, Make sure to install the Haxe package

	This assumes you have file extensions visible in your file manager 
	* On Windows, you can change this in the View tab of Explorer

	To make a new stage:
		Make a folder named `stages` in your mods folder, add a folder to that named whatever you want the stage to be named
		Make a file named `script.hscript`, this'll be the script you'll use to create the stage.

		Now we have a stage, but if we go ingame with it, it won't actually do anything yet. Lets try adding an image.
		Copy and paste an image into the script's folder(I'd recommend just using your desktop wallpaper as a test but any image is fine) If you want things to be neat, you can make a subfolder named `sprites` and put the picture there

		Open your script.hscript and add ```function initScript(){}```. initScript is the first function that's run when a script is loaded.
		Anything in between the {}'s will be run when initScript is called.

		Now lets actually add our image to the game
		Super Engine has a custom class named BRtools, it allows you to easily create sprites, play sounds and other things without needing to know where the script is. We'll be using this to create our sprite
 
		Add `var background = BRtools.loadFlxSprite(0,0,"wallpaper.png");` inside of the brackets,
		This will create a variable named `background` and then it'll be set to a sprite. The sprite will be positioned at the top left corner of the screen and it'll use the file named "wallpaper.png" as it's graphic
		* The first 0 is it's X value, the higher it is, the more to the right it'll be, the lower it is, the more to the left it'll be
		* The second 0 is it's Y value, the higher it is, the more to the bottom it'll be, the lower it is, the more to the top it'll be
		* "wallpaper.png" is the file the sprite will use as it's image. If you used a subfolder, you'll need to add it to the string, like `sprites/wallpaper.png` 
		** The game's playspace/stage size is 1280x720, no matter the resolution of the device
		This will load the sprite but we need to actually add it to the state, for that we can use `state.add(background);`