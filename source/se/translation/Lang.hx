package se.translation;
import tjson.Json;
import se.utilities.SEMacros;


class Lang{
	public static var current:Map<String,String> = [];
	public static var language:String = "";
	@:keep inline public static function get(translation:String = "") return current[translation] ?? translation;
	public static function format(translation:String,?values:Array<Dynamic>){
		var translation = current[translation] ?? translation;
		if(values == null || values[0] == null) return translation;
		var splits = translation.split('%%');
		var joinedText = splits.pop();
		while(splits.length > 0) joinedText = splits.pop() + values.pop() + joinedText;
		return joinedText;
	}
	@:keep inline public static function getInternal(){
		var lang = cast Json.parse(SEMacros.englishTranslation);
		for (field in Reflect.fields(lang)){
			var fieldValue = Reflect.field(lang,field);
			if(!(fieldValue is String)) continue;
			current[field] = fieldValue;
		}
	}

	public static function loadTranslations(lang){
		language = lang;
		if(SELoader.exists('assets/data/lang/$lang.json')){
			return fromFile('assets/data/lang/$lang.json');
		}
		if(SELoader.exists('mods/lang/$lang.json')){
			return fromFile('mods/lang/$lang.json');
		}
	}
	public static function fromFile(file:String){ // TODO: OVERLAP TRANSLATIONS WITH ENGLISH TRANSLATIONS 
		try{
			current = [];
			getInternal();
			if(language != 'english'){
				var lang = cast Json.parse(SELoader.getContent(file));
				for (field in Reflect.fields(lang)){
					var fieldValue = Reflect.field(lang,field);
					if(!(fieldValue is String)) continue;
					current[field] = fieldValue;
				}
				// if(current == null) throw('No translation found!');
				trace('Loaded translation $file');
			}
		}catch(e){
			getInternal();
			trace('Error trying to load translations: $e');
		}
	}

}