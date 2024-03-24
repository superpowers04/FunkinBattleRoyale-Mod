package se.utilities;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.io.File;
import sys.FileSystem;
class SEMacrosBuild{
	inline static function zeroPad(val:Dynamic):String{
		if(val < 10) return '0$val';
		return '$val';
	}
	public static function initBuild():Array<Field> {
		var time = Date.now();
		var _buildTime:String = "";
		#if ghaction
		if(FileSystem.exists('version.downloadMe')){
			var content = File.getContent('version.downloadMe').split(';');
			_buildTime = content[0];
		}else{
		#end
			var _year = time.getFullYear(); 
			_year -= Math.floor(_year * 0.001) * 1000;
			var _month = zeroPad(time.getMonth()+1);
			var _date = zeroPad(time.getDate());
			var _min = zeroPad(time.getMinutes());
			var _hour = zeroPad(time.getHours());
			_buildTime = '$_year.$_month.$_date.$_hour$_min';
			trace('Building SE Version:${_buildTime}');
			if(FileSystem.exists('version.downloadMe')){
				var content = File.getContent('version.downloadMe').split(';');
				if(content[1] == null)
					trace('Unable to edit version.downloadMe!');
				// }else if(content[0] == _buildTime)
					// trace('version.downloadMe has same date as today, not updating');
				else
					File.saveContent('version.downloadMe','${_buildTime};${content[1]}');
			}
		
		#if ghaction
		}
		#end
		var fields = Context.getBuildFields();
		fields.push({name:"buildDate",access:[Access.APublic, Access.AStatic, Access.AFinal],pos:Context.currentPos(),
			kind:FieldType.FVar(macro:String, macro $v{_buildTime}), 
		});
		fields.push({name:"buildTime",access:[Access.APublic, Access.AStatic, Access.AFinal],pos:Context.currentPos(),
			kind:FieldType.FVar(macro:Float, macro $v{time.getTime()}), 
		});
		#if linc_luajit
		fields.push({name:"PsychLuaCompatScript",access:[Access.AInline, Access.APublic, Access.AStatic, Access.AFinal],pos:Context.currentPos(),
			kind:FieldType.FVar(macro:String, macro $v{File.getContent('source/se/handlers/PsychLuaCompatScript.lua')}), 
		});
		#end
		fields.push({name:"englishTranslation",access:[Access.AInline, Access.APublic, Access.AStatic, Access.AFinal],pos:Context.currentPos(),
			kind:FieldType.FVar(macro:String, macro $v{File.getContent('assets/preload/data/lang/english.json')}), 
		});

		return fields;
	}
}