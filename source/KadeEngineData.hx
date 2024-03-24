import openfl.Lib;
import flixel.FlxG;

typedef ObjectInfo = {
	var x:Float;
	var y:Float;
	// var isGroup:Bool;
	var ?subObjects:Map<String,ObjectInfo>;
}

// Ironically, this doesn't actually use anything kade engine related for saves,
//  I just think it's funny to have this still :3
class KadeEngineData {

	public static function initSave(){

		FlxG.save.bind('superengine', 'superpowers04');
		SEFlxSaveWrapper.load();
		// for(key => value in defaultOptions) if(Reflect.field(_data,key) == null) {Reflect.setField(_data,key,value);trace('Updated ${key} to ${value}');}

		var _data = SESave.data; 
		MainMenuState.lastVersionIdentifier = _data.lastUpdateID;
		SESave.data.lastUpdateID = MainMenuState.versionIdentifier;
		if(MainMenuState.lastVersionIdentifier != MainMenuState.versionIdentifier){ // This is going to be ugly but only executed every time the game's updated
			var lastVersionIdentifier = MainMenuState.lastVersionIdentifier;
			if(lastVersionIdentifier < 1) SESave.data.inputEngine = 1; // Update to new input
			if(lastVersionIdentifier < 2){
				// Hopefully fix issues with saves
				// SESave.data.charRepo = null;
				// SESave.data.chartRepo = null;
				if(_data.keys != null){
					_data.keys[0] = ['A','S','W','D','I','K','J',"L"];
				}
			}
		}
		se.translation.Lang.loadTranslations(_data.lang);

	 

		Conductor.recalculateTimings();
		KeyBinds.keyCheck();
		PlayerSettings.init();
		

		Main.watermarks = SESave.data.watermark;

		Main.instance.setFPSCap(SESave.data.fpsCap);
	}
}