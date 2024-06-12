package;

import flixel.FlxG;

import sys.io.File;
// import flixel.util.FlxSave;
// import tjson.Json.JSONANONTYPE;
using StringTools;

class SEFlxSaveWrapper{
	public static function save(){
		SELoader.saveContent('SESETTINGS.json',Json.stringify(SESave.data).replace('"" :','" :').replace('"":','":'));
	}
	public static function saveTo(path:String = "SESETTINGS-BACK.json"){
		SELoader.saveContent(path,Json.stringify(SESave.data).replace('"" :','" :').replace('"":','":'));
	}
	public static function load():Void{
		if(!SELoader.exists('SESETTINGS.json')) return;
		try{

			var json = CoolUtil.cleanJSON(SELoader.loadText('SESETTINGS.json')).replace('"" :','" :').replace('"":','":');
			var fieldList = haxe.Json.parse(json); // 
			var save = Json.parse(json,SESave);
			var newSave = SESave.data = new SESave();
			for(field in Reflect.fields(fieldList)){
				if(field.startsWith('set_')){
					field = field.substring(4);
				}
				try{
					var stuff:Dynamic = Reflect.field(save,field);
					if(stuff == null) throw('how the fuck is $field null, THIS WAS LITERALLY SUPPLIED BY THE JSON');
					Reflect.setProperty(newSave,field,stuff);
				}catch(e){
					trace('Unable to load field "$field": $e');
				}
			}
			// SESave.data.keys = save.keys;
			// SELoader.saveContent("SESETTINGS-OLD.json",json);
			// trace('Unable to load settings from an invalid format');
			// try{
			// 	MusicBeatState.instance.showTempmessage('Settings file is in an invalid format\n Your settings have been reset!',0xFFFF0000);
			// }catch(e){}
		}catch(e){
			throw('Error while parsing SESettings.json:\n${e.message}');
		}
		


			
		
		
		// for(field in Reflect.fields(anon)){
		// 	if(!Reflect.hasField(SESave.data,field)){
		// 		trace('Invalid save field "$field" ignored');
		// 		continue;
		// 	}
		// 	// try{
		// 	Reflect.setProperty(SESave.data,field,Reflect.field(anon,field));
		// 	// }catch(e){
		// 	// 	trace('Invalid save field "$field" ignored');
		// 	// }
		// }
	};
}
