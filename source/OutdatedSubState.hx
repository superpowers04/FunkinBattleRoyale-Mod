package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;

class OutdatedSubState extends MusicBeatState
{
	// TODO: INGAME DOWNLOADING

	public static var needVer:String = "Unknown";
	public static var currChanges:String = "Check for Updates needs to be enabled in Options > Misc!";
	
	private var bgColors:Array<String> = [
		'#314d7f',
		'#4e7093',
		'#70526e',
		'#594465'
	];
	private var colorRotation:Int = 1;

	override function create()
	{
		super.create();
		var bg:FlxSprite = new FlxSprite().loadGraphic(SearchMenuState.background);
		bg.color = 0x350035;
		bg.screenCenter();
		add(bg);
		
		var kadeLogo:FlxSprite = new FlxSprite(FlxG.width, 0).loadGraphic(Paths.image('logoBumpin'));
		kadeLogo.scale.y = 0.3;
		kadeLogo.scale.x = 0.3;
		kadeLogo.x -= kadeLogo.frameHeight;
		kadeLogo.y -= 180;
		kadeLogo.alpha = 0.8;
		kadeLogo.angle = 10;
		add(kadeLogo);
		var outdatedLMAO:FlxText = new FlxText(0, FlxG.height * 0.05, 0,if(TitleState.outdated) 'Super Engine is outdated, Your version: ${MainMenuState.ver} latest: ${needVer}' else 'Up to date: ${MainMenuState.ver}' , 32);
		outdatedLMAO.setFormat(CoolUtil.font, 32, TitleState.outdated ?  FlxColor.RED : FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		outdatedLMAO.scrollFactor.set();
		outdatedLMAO.screenCenter(flixel.util.FlxAxes.X);
		add(outdatedLMAO);

		var txt:FlxText = new FlxText(0, 0, FlxG.width,
			"\n\nChangelog:\n\n"
			+ currChanges.substring(0,1000)
			+ "\n\n\nPress Space to download latest update's zip, D to open a invite to the Discord server or Escape to close.\n\nYou can install it by downloading the zip and dragging the files\n into your game folder",
			32);
		
		txt.setFormat(CoolUtil.font, 32, FlxColor.fromRGB(200, 200, 200), CENTER);
		txt.borderColor = FlxColor.BLACK;
		txt.borderSize = 3;
		txt.borderStyle = FlxTextBorderStyle.OUTLINE;
		txt.screenCenter();
		add(txt);
		
		FlxTween.color(bg, 2, bg.color, FlxColor.fromString(bgColors[colorRotation]));
		FlxTween.angle(kadeLogo, kadeLogo.angle, -10, 2, {ease: FlxEase.quartInOut});
		
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			FlxTween.color(bg, 2, bg.color, FlxColor.fromString(bgColors[colorRotation]));
			if(colorRotation < (bgColors.length - 1)) colorRotation++;
			else colorRotation = 0;
		}, 0);
		
		new FlxTimer().start(Conductor.crochet * 0.001, function(tmr:FlxTimer)
		{
			FlxTween.angle(kadeLogo, kadeLogo.angle, -kadeLogo.angle, Conductor.crochet * 0.001, {ease: FlxEase.quartInOut});
		}, 0);
		
		new FlxTimer().start(Conductor.crochet * 0.001, function(tmr:FlxTimer)
		{
			FlxTween.tween(kadeLogo, {alpha: (kadeLogo.alpha == 0.8) ? 1 : 0.8}, Conductor.crochet * 0.001, {ease: FlxEase.quartInOut});
			
		}, 0);
	}
	var allowInput = true;
	override function update(elapsed:Float)
	{
		if(allowInput){

			if (controls.ACCEPT || FlxG.keys.justPressed.SPACE) {

				fancyOpenURL(if(MainMenuState.nightly == "")"https://nightly.link/superpowers04/Super-Engine/workflows/main/master/windowsBuild-Minimal.zip" else "https://nightly.link/superpowers04/Super-Engine/workflows/main/nightly/windowsBuild-Minimal.zip");
			}
			if (FlxG.keys.justPressed.D) {
				fancyOpenURL("https://discord.gg/28GPGTRuuR");
			}
			if (controls.BACK) {
				FlxG.switchState(new MainMenuState());
			}
		}
		super.update(elapsed);
	}
}
