package se;
typedef YourMother = Dynamic;


@:publicFields class SESave{
	public static var data:SESave = new SESave();

	// Performance
	var fpsCap:Float = 120;
	var preformance:Bool = false;
	var performance(get,set):Bool;
	@:keep inline function get_performance() return preformance;
	@:keep inline function set_performance(v) return preformance = v;
	// Gameplay
	var downscroll:Bool = false;
	var offset:Float = 0;
	var changedHitX:Float = -1;
	var changedHitY:Float = -1;
	var changedHit:Bool = false;
	var seenForcedText:Bool = false;
	var scrollSpeed:Float = 1;
	var ghost:Bool = false;
	var frames:Int = 10;
	// Display
	var watermark:Bool = true;
	var accuracyDisplay:Bool = true;
	var songPosition:Bool = true;
	var fps:Bool = false;
	var flashing:Bool = true;
	var playStateObjectLocations:Dynamic = new Map<String,YourMother>();
	var flashingLights(get,set):Bool;
	@:keep inline function get_flashingLights() return flashing;
	@:keep inline function set_flashingLights(v) return flashing = v;
	var npsDisplay:Bool = false;
	var accuracyMod:Int = 2;
	var distractions:Bool = true;
	var resetButton:Bool = false;
	var botplay:Bool = false;
	var cpuStrums:Bool = true;
	var strumline:Bool = false;
	// Modification stuff
	var opponent:String = "bf";
	var playerChar:String = "bf";
	var gfChar:String = "gf";
	var selStage:String = "default";
	var animDebug:Bool = false;
	var noteSplash:Bool = true;
	var charAuto:Bool = true;
	var stageAuto:Bool = true;
	var charAutoBF:Bool = false;
	var lastServer:String = "";
	var lastServerPort:String = "";
	var nickname:String = "";
	var guiGap:Float = 0;
	var inputEngine:Int = 1;
	var hitSound:Bool = false;
	var noteAsset:String = "default";
	var noterating:Bool = true;
	var camMovement:Bool = true;
	var practiceMode:Bool = false;
	var dadShow:Bool = true;
	var bfShow:Bool = true;
	var gfShow:Bool = true;
	var playVoices:Bool = false;
	var updateCheck:Bool = true;
	var songUnload:Bool = true;
	var useBadArrowTex:Bool = true;
	var middleScroll:Bool = true;
	var oppStrumLine:Bool = true;
	var oppStrumline(get,set):Bool;
	@:keep inline function get_oppStrumline() return oppStrumLine;
	@:keep inline function set_oppStrumline(v) return oppStrumLine = v;
	var playMisses:Bool = true;
	var scripts:Array<String> = [];
	var songInfo:Int = 0;
	var mainMenuChar:Bool = false;
	var useFontEverywhere:Bool = false;
	var accurateNoteSustain:Bool = true;
	var undlaSize:Int = 0;
	var undlaTrans:Float = 0.1;
	var instVol:Float = 0.8;
	var masterVol:Float = 1;
	var voicesVol:Float = 1;
	var missVol:Float = 0.1;
	var hitVol:Float = 0.6;
	var otherVol:Float = 0.6;
	var allowServerScripts:Bool = false;
	var shittyMiss:Bool = false;
	var badMiss:Bool = false;
	var goodMiss:Bool = false;
	var beatBouncing:Bool = true;
	var ratingOnNote:Bool = false;
	var scrollOSUSpeed:Float = 2;
	var luaScripts:Bool = true;
	var judgeSick:Float = Ratings.getDefRating("sick");
	var judgeGood:Float = Ratings.getDefRating("good");
	var judgeBad:Float = Ratings.getDefRating("bad");
	var judgeShit:Float = Ratings.getDefRating("shit");
	var skipToFirst:Bool = true;
	var debounce:Bool = false;
	var legacyCharter:Bool = false;
	var savedServers:Array<Array<Dynamic>> = [];
	var favourites(get,default):Array<se.formats.SongInfo> = [];
	function get_favourites() {
		if(favourites == null){favourites = [];} 
		return favourites;
	}
	var discordDRP:Bool = true;
	var doCoolLoading:Bool = false;
	var transparentPause:Bool = true;
	var fullscreen:Bool = false;
	var persistBF:Bool = false;
	var persistGF:Bool = false;
	var menuScripts:Bool = false;
	var easterEggs:Bool = true;

	var upBind:String = "W";
	var downBind:String = "S";
	var leftBind:String = "A";
	var rightBind:String = "D";
	var killBind:String = "R";
	var gpupBind:String = "DPAD_UP";
	var gpdownBind:String = "DPAD_DOWN";
	var gpleftBind:String = "DPAD_LEFT";
	var gprightBind:String = "DPAD_RIGHT";
	var AltupBind:String = "N";
	var AltdownBind:String = "X";
	var AltleftBind:String = "Z";
	var AltrightBind:String = "M";
	var lastUpdateID:Int = MainMenuState.versionIdentifier;
	var useHurtArrows:Bool = false;
	var keys:Array<Array<String>> = KeyBinds.defaultKeys;
	var cacheMultiList:Bool = false;
	#if mobile
	var useTouch:Bool = true;
	var useStrumsAsButtons:Bool = true;
	#else
	var useTouch:Bool = false;
	var useStrumsAsButtons:Bool = false;
	// var chartRepo:String ='';
	// var charRepo:String ='';
	var simpleMainMenu:Bool = false;
	#end


	var logGameplay:Bool = false;
	var showTimings:Bool = true;
	var showCombo:Bool = true;
	var showHelp:Bool = true;
	var chart_waveform:Bool = true;


	var rotateScroll:Int = 0;
	var flipScrollX:Bool = false;
	var flipScrollY:Bool = false;
	var resyncVoices:Bool = true;

	var useSystemCursor:Bool = false;
	var lang:String = "english";
	var HDDMode:Bool = false;
	var PECharSeperate:Bool = false;
	var PECharLoading:Bool = false;
	var QuickReloading:Bool = false;
	var loadPsychEvents:Bool = false;

	public function new(){}
}