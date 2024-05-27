package;

import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.system.System;
import openfl.text.TextFormat;
import flixel.FlxG;
import flixel.system.debug.watch.EditableTextField;
import flixel.input.keyboard.FlxKey;
#if linc_luajit
import se.handlers.SELua;
#end

import hscript.Expr;
import hscript.Interp;

using StringTools;


// Recreation of openfl.display.fps, with memory being listed
class Overlay extends TextField {
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;
	static public var instance:Overlay = null;

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Int;
	@:noCompletion private var times:Array<Int>;
	public static var debugVar:String = "";

	public function new(x:Float = 10, y:Float = 10, color:Int = 0xFFFFFFFF)
	{
		super();
		instance = this;

		this.x = x;
		this.y = y;
		width = 1280;
		height = 720;
		// alpha = 0;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 12, color);
		text = "FPS: ";

		cacheCount = 0;
		currentTime = 0;
		times = [];

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			__enterFrame(e);
		});
		#end
	}
	var memPeak:Float = 0;
	// Event Handlers
	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		if(!visible) return;
		// #if sys
		currentTime = Std.int(haxe.Timer.stamp() * 1000);
		times.push(currentTime);

		while (times[0] < currentTime - 1000) times.shift();
		// #else
		// 	currentTime += flixel.FlxG.elapsed;
		// 	times.push(currentTime);

		// 	while (times[0] < currentTime - 1) times.shift();
		// #end


		scaleX = lime.app.Application.current.window.width / 1280;
		scaleY = lime.app.Application.current.window.height / 720;
		var currentCount = times.length;
		currentFPS = Math.round(currentCount);

		var mem:Float = Math.round((
			#if cpp
			cpp.NativeGc.memInfo(0)
			#else
			System.totalMemory
			#end
			/ 1024) / 1000);
		if (mem > memPeak)
			memPeak = mem;
		text = "" + currentFPS + " FPS/" + deltaTime + 
			" MS\nMemory Usage/Peak: " + mem + "MB/" + memPeak + "MB"
			#if cpp
			+"\nMemory Reserved/Current: " + Math.round((cpp.NativeGc.memInfo(3) / 1024) / 1000) + "MB/" + Math.round((cpp.NativeGc.memInfo(2) / 1024) / 1000) + "MB" 
			#end
			+ debugVar;
		// }

		cacheCount = currentCount;
	}
}
// Clone of Overlay but to show a console sort of thing instead
class Console extends TextField
{
	var muteKeys:Array<FlxKey>;
	var volumeUpKeys:Array<FlxKey>;
	var volumeDownKeys:Array<FlxKey>;
	public static var instance:Console = new Console();
	public var commandBox:ConsoleInput; 
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	public static var debugVar:String = "";
	var requestUpdate:Bool = false;
	public static var showConsole:Bool = false;
	var isShowingConsole:Bool = true;
	var wasMouseDisabled:Bool = false;

	public function new(x:Float = 20, y:Float = 20, color:Int = 0xFFFFFFFF)
	{
		super();
		instance = this;
		haxe.Log.trace = function(v, ?infos) {
			var str = haxe.Log.formatOutput(v,infos);
			#if js
			if (js.Syntax.typeof(untyped console) != "undefined" && (untyped console).log != null)
				(untyped console).log(str);
			#elseif lua
			untyped __define_feature__("use._hx_print", _hx_print(str));
			#elseif sys
			Sys.println(str);
			#end
			if(Console.instance != null) Console.instance.log(str);
		}


		this.x = x;
		this.y = y;
		width = 1240;
		height = 640;
		background = true;
		backgroundColor = 0xff100011;
		// alpha = 0;

		selectable = false;
		mouseEnabled = mouseWheelEnabled = false;
		text = "Start of log";
		alpha = 0;
		commandBox = new ConsoleInput();
		commandBox.defFormat = commandBox.defaultTextFormat = defaultTextFormat = new TextFormat("_sans", 18, color);
		commandBox._parent = this;

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			__enterFrame(e);
		});
		#end
	}
	var lineCount:Int = 0;
	var lines:Array<String> = [];

	@:keep inline public static function error(str:String) return Console.print('Error: ${str}');
	@:keep inline public static function print(str:String) return instance.log(str);
	public function log(str:String){
		if(SESave.data != null && !SESave.data.animDebug){return;}
		// text += "\n-" + lineCount + ": " + str;
		lineCount++;
		var lc = Std.string(lineCount);
		while(lc.length < 5) lc+=" ";
		lines.push('${lc}~$str');
		while(lines.length > 500){
			lines.shift();
		}
		requestUpdate = true;

	}
	var firstOpen:Bool = true;

	// Event Handlers
	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		if(FlxG.keys == null || SESave.data == null || !SESave.data.animDebug) return;
		if(showConsole && requestUpdate){
			text = lines.join("\n");
			requestUpdate = false;
			scrollV = 1000;
		}
		if(FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.F10){
			lines = [];
			trace("Cleared log");
		}else if(FlxG.keys != null && FlxG.keys.justPressed.F10 && SESave.data != null){
			showConsole = !showConsole;
		}
		if(isShowingConsole != showConsole){
			updateConsoleVisibility();
		}
		

	}
	function updateConsoleVisibility(){
		isShowingConsole = showConsole;
		commandBox.alpha = alpha = (if(showConsole) 1 else 0);
		#if linc_luajit
			if(commandBox.selua != null){ // Stack overflow if this isn't done
				commandBox.selua.stop();
				print('lua closed');
				commandBox.selua = null;
			}
		#end
		FlxG.keys.enabled = true;
		if(showConsole){
			wasMouseDisabled = FlxG.mouse.visible;
			FlxG.mouse.visible = true;
			requestUpdate = true;
			var _SY = (lime.app.Application.current.window.height / 720);
			var _SX = (lime.app.Application.current.window.width / 1280);
			width = 1240 * _SY;
			height = 640 * _SX;
			commandBox.y = y + height + 2;
			commandBox.x = x;
			commandBox.height = 30 * _SY;
			commandBox.width =width;
			if(firstOpen){
				firstOpen = false;
				print('Super Engine ${MainMenuState.ver} ${MainMenuState.buildType} ${MainMenuState.compileType} - Debug console. Type help for commands.\nDO NOT BLINDLY PASTE CODE INTO HERE, This console allows you to run arbitrary code.\nSuper is not held responsible for whatever you paste here');
			}



		}else{
			FlxG.mouse.visible = wasMouseDisabled;
		}
		commandBox.mouseEnabled =commandBox.mouseWheelEnabled = commandBox.selectable = mouseEnabled = mouseWheelEnabled = selectable = showConsole;
		SetVolumeControls(showConsole);

	}
	function SetVolumeControls(enabled:Bool)
	{
		if(FlxG.sound == null) return;
		if(muteKeys == null){
			muteKeys = FlxG.sound.muteKeys;
			volumeUpKeys = FlxG.sound.volumeUpKeys;
			volumeDownKeys = FlxG.sound.volumeDownKeys;
		}
		if (enabled){
			FlxG.sound.muteKeys = null;
			FlxG.sound.volumeUpKeys = null;
			FlxG.sound.volumeDownKeys = null;
		}else{
			FlxG.sound.muteKeys = muteKeys;
			FlxG.sound.volumeUpKeys = volumeUpKeys;
			FlxG.sound.volumeDownKeys = volumeDownKeys;
		}
	}
}

class ConsoleInput extends TextField{
	public var _parent:Console = null;
	public var interp:Interp;
	var parser:hscript.Parser;
	var hsbrtools:HSBrTools = new HSBrTools('',"CONSOLE");
	public var commandHistory:Array<String> = [];
	public var actualText:String = "";
	public inline static var CARETCHAR:String = "|";
	public var caretFormat:TextFormat = new TextFormat();
	public var defFormat:TextFormat = new TextFormat();

	#if linc_luajit
		public var selua:SELua;
	#end


	public function new(x:Float = 20, y:Float = 20, color:Int = 0xFFFFFFFF)
	{
		super();
		type="INPUT";
		selectable = false;
		mouseEnabled = mouseWheelEnabled = false;
		alpha = 0;
		background = true;
		backgroundColor = 0xff110011;

		caretFormat.color = 0xFFFFAAFF;
		updateShownText();
		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			__enterFrame(e);
		});
		#end
	}
	#if linc_luajit
		public function runlua(?songScript:String = ""){
			if(selua == null){ // No need to clog memory if lua isn't gonna be touched
				selua = new SELua();
				selua.BRTools = hsbrtools;
			}
			if(songScript == "") return;
			try{
				selua.exec(songScript);
			}catch(e){
				trace('Lua exception: ${e.message}');
			}
			return;
		}
	#end
	public function runHscript(?songScript:String = ""){
		if(interp == null){ // No need to clog memory if hscript isn't gonna be touched
			parser = HscriptUtils.createSimpleParser();
			interp = HscriptUtils.createSimpleInterp();
			interp.variables.set("BRtools", hsbrtools);
			interp.variables.set("t",Console.instance.log);
			interp.variables.set("log",Console.instance.log);
		}
		try{
			@:privateAccess
			parser.line = 0;
			interp.variables.set("state",cast (FlxG.state)); 
			interp.variables.set("game",cast (FlxG.state));
			interp.execute(parser.parseString(songScript,'CONSOLE'));
		}catch(e){
			var _line = '${parser.line}';
			try{
				var _split = songScript.split('\n');
				_line = '${parser.line};"${_split[parser.line - 1]}"';
			}catch(e){_line = '${parser.line}';}
			trace('Error parsing hscript\nLine:${_line}\n ${e.message}');
		}
		return interp;
	}
	var CURRENTCMDHISTORY = -1;
	var keyList:Map<FlxKey,String> = [ // I hate my life
		A => "a",
		B => "b",
		C => "c",
		D => "d",
		E => "e",
		F => "f",
		G => "g",
		H => "h",
		I => "i",
		J => "j",
		K => "k",
		L => "l",
		M => "m",
		N => "n",
		O => "o",
		P => "p",
		Q => "q",
		R => "r",
		S => "s",
		T => "t",
		U => "u",
		V => "v",
		W => "w",
		X => "x",
		Y => "y",
		Z => "z",
		SPACE => " ",
		ZERO => "0",
		ONE => "1",
		TWO => "2",
		THREE => "3",
		FOUR => "4",
		FIVE => "5",
		SIX => "6",
		SEVEN => "7",
		EIGHT => "8",
		NINE => "9",
		NUMPADZERO=> "0",
		NUMPADONE=> "1",
		NUMPADTWO=> "2",
		NUMPADTHREE=> "3",
		NUMPADFOUR=> "4",
		NUMPADFIVE=> "5",
		NUMPADSIX=> "6",
		NUMPADSEVEN=> "7",
		NUMPADEIGHT=> "8",
		NUMPADNINE=> "9",
		NUMPADMINUS => "-",
		NUMPADPLUS => "+",
		NUMPADPERIOD => ".",
		NUMPADMULTIPLY => "*",
		LBRACKET => "[",
		RBRACKET => "]",
		BACKSLASH => "\\",
		SEMICOLON => ";",
		QUOTE => "'",
		COMMA => ",",
		PERIOD => ".",
		SLASH => "/",
		MINUS => "-",
		PLUS => "=", 
	];
	var keyListUpper:Map<FlxKey,String> = [ // I hate my life*@ (get it, because it's shif- I'll see myself out)
		ZERO => ")",
		ONE => "!",
		TWO => "@",
		THREE => "#",
		FOUR => "$",
		FIVE => "%",
		SIX => "^",
		SEVEN => "&",
		EIGHT => "*",
		NINE => "(",
		LBRACKET => "{",
		RBRACKET => "}",
		BACKSLASH => "|",
		SEMICOLON => ":",
		QUOTE => "\"",
		COMMA => "<",
		PERIOD => ">",
		SLASH => "?",
		MINUS => "_",
		PLUS => "+",
	];
	var buffer:Array<FlxKey> = [];
	var caretPos:Int = 0;
	inline function updateShownText(){
		if(caretPos > actualText.length) caretPos = actualText.length;
		if(caretPos < 0) caretPos = 0;

		text = actualText.substring(0,caretPos) + CARETCHAR + actualText.substring(caretPos);
		setTextFormat(defFormat,0,text.length);
		setTextFormat(caretFormat,caretPos,caretPos+1);
	}
	@:keep inline function addTextAtCaret(str:String){
		return actualText = actualText.substring(0,caretPos) + str + actualText.substring(caretPos);
	}
	@:keep inline function cleanCommandHistory(){
		var i:Int = commandHistory.length + 1;
		var bef:String = "";
		var cur:String = "";
		while(i > 0){
			i--;
			bef = commandHistory[i - 1]; cur = commandHistory[i];
			if(bef == null){break;}
			if(bef == cur || bef == "") commandHistory.splice(i-1,1);
		}
	}
	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void // This is such a fucking mess, I should be using events but fuck it
	{
		if(FlxG.keys == null || alpha <= 0) return;


		if(FlxG.keys.pressed.CONTROL){
			if(FlxG.keys.pressed.BACKSPACE){
				
				actualText = actualText.substring(0,caretPos - 1) + actualText.substring(caretPos);
				caretPos--;
				updateShownText();
			}else if(FlxG.keys.justPressed.C){
				lime.system.Clipboard.text = actualText;
				Console.print('Copied input text to clipboard');
			}else if(FlxG.keys.justPressed.V){
				var text = lime.system.Clipboard.text;
				addTextAtCaret(text);
				caretPos+=text.length;
				updateShownText();
			}
		}else if(FlxG.keys.justPressed.BACKSPACE){
			actualText = actualText.substring(0,caretPos - 1) + actualText.substring(caretPos);
			caretPos--;
			updateShownText();
		}else if(FlxG.keys.justPressed.DELETE){
			actualText = actualText.substring(0,caretPos) + actualText.substring(caretPos + 1);
			updateShownText();
		}else if(FlxG.keys.justPressed.END){
			caretPos = actualText.length;
			updateShownText();
		}else if(FlxG.keys.justPressed.HOME){
			caretPos = 0;
			updateShownText();
		}else{
			var newBuffer = [];
			for(key => char in keyList){
				@:privateAccess
				if(Reflect.getProperty(FlxG.keys.justPressed,key)){
					newBuffer.push(key);
					if(!buffer.contains(key)){

						if(FlxG.keys.pressed.SHIFT){
							char = (keyListUpper[key] != null ? keyListUpper[key] : char.toUpperCase());
						}
						addTextAtCaret(char);
						caretPos++;
						updateShownText();
					}
				}
			}
			buffer = newBuffer;
		}


		if(FlxG.keys.pressed.SHIFT){
			if(FlxG.keys.justPressed.UP){
				if(CURRENTCMDHISTORY < commandHistory.length){
					actualText = commandHistory[CURRENTCMDHISTORY++];
				}
				updateShownText();
			}else if(FlxG.keys.justPressed.DOWN){
				if(CURRENTCMDHISTORY > 0){
					actualText = commandHistory[CURRENTCMDHISTORY--];
				}
				updateShownText();
			}
			if(FlxG.keys.pressed.LEFT){
				caretPos--;
				updateShownText();
			}
			if(FlxG.keys.pressed.RIGHT){
				caretPos++;
				updateShownText();
			}
		}else{
			if(FlxG.keys.justPressed.LEFT){
				caretPos--;
				updateShownText();
			}else if(FlxG.keys.justPressed.RIGHT){
				caretPos++;
				updateShownText();
			}else if(FlxG.keys.pressed.ENTER){
				if(actualText != ""){
					Console.print('> ${actualText}');
					CURRENTCMDHISTORY = 0;
					runCommand(actualText);
					
					commandHistory.unshift(actualText);
					cleanCommandHistory();
					actualText= "";
					updateShownText();
				}
			}
		}
	}
	var cmdList:Array<Array<String>> = [
		["help",'Prints this message'],
		["statehelp",'If a state has custom commands, they\'ll be listed here. If it doesn\'t, you\'ll get a "command not found" error'],

		['-- Utilities --'],
		["mainmenu",'Return to the main menu'],
		["reload",'Reloads current state'],
		["switchstate",'Switch to a state, Case/path sensitive!'],
		["defines",'Prints a bunch of defines, used for debugging purposes'],
		["playsong (name)",'Jumps to a song matching the name'],

		['-- Scripting --'],
		["hs (code)",'Run hscript code'],
		["hst (code)",'Run hscript code, encased in a trace'],
		#if(linc_luajit)
		["lua (code)",'Run lua code'],
		["luat (code)",'Run lua code, encased in a trace statement'],
		#end

		["getvalue (path)",'Returns a value from an object path'],
		["setvalue (path) (value)",'Sets a value from an object path'],
	];
	function runCommand(text:String):Dynamic{
		if(text.indexOf('>>') > 0){
			var redir:Array<String> = text.split(' >> ');
			var ret = runCommand(redir[0]);
			text = redir[1] + ' ${ret}';
		}
		var args:Array<String> = text.split(' ');
		switch(args[0].toLowerCase()){

			case 'hs': 
				if(!QuickOptionsSubState.getSetting("Song hscripts")){Console.error('Scripts are currently disabled!');return null;}
				return runHscript(text.substring(3));
			case 'lua': 
				#if linc_luajit
					if(!QuickOptionsSubState.getSetting("Song hscripts")){Console.error('Scripts are currently disabled!');return null;}
					runlua(text.substring(4));
				#else
					Console.error('Lua scripts aren\'t supported on this build or game was compiled without linc_luajit!');
				#end
				return null;
			case 'luat': 
				#if linc_luajit
					if(!QuickOptionsSubState.getSetting("Song hscripts")){Console.error('Scripts are currently disabled!');return null;}
					runlua('trace(${text.substring(5)})');
			
				#else
					Console.error('Lua scripts aren\'t supported on this build or game was compiled without linc_luajit!');
				#end
				return null;
			case 'hst' :
				if(!QuickOptionsSubState.getSetting("Song hscripts")){Console.error('Scripts are currently disabled!');return null;}
				return runHscript("trace(" + text.substring(3) + ");");
			case 'playsong' | 'play':
				var song = text.substring(text.indexOf(' ') + 1);
				if(song != "" && multi.MultiMenuState.playSongByName(song)){
					Console.showConsole = false;
					return true;
				}	
				Console.print('Unable to find song $song');
				
			case 'reload':
				Console.showConsole = false;
				FlxG.resetState();
			case 'mainmenu':
				Console.showConsole = false;
				MainMenuState.handleError("");
			case 'getvalue':
				try{
					var ret = '${ConsoleUtils.getValueFromPath(null,args[1])}';
					Console.print(ret);
					return ret;
				}catch(e){
					Console.error('Unable to grab value from ${args[1]}: ${e.message}');
					return null;
				}
			case 'defines':
				var defs = getDefs();
				Console.print(defs);
				return defs;
			case 'setvalue':
				if(!QuickOptionsSubState.getSetting("Song hscripts")){Console.error('Scripts are currently disabled!');return null;}
				var value:String = text.substring(text.indexOf(' ',10) + 1);
				var path:String = args[1];
				try{
					ConsoleUtils.setValueFromPath(path,value);
					Console.print('Set value ${path} to ${value}');
				}catch(e){
					Console.error('Unable to set value of ${args[1]} to ${value}: ${e.message}');
				}
			case 'switchstate':
				if(args[1] == null) {Console.error('No state specified!');return null;}
				try{
					var state:Class<flixel.FlxState> = cast Type.resolveClass(args[1]);
					if(state == null) {Console.error('Invalid state specified!');return null;}
					// if(!(state is )) return Console.print('${Type.getClassName(state)} is not a valid state!');
					Console.print('Attempting to switch to ${Type.getClassName(state)}');
					FlxG.switchState(Type.createInstance(state,[]));
				}catch(e){Console.error('Unable to switch states: ${e.message}');return null;}
				Console.showConsole = false;
			// case 'memusage':
			// 	// for(i =>member in FlxG.state.members){

			// 		Console.print('PlayState:${cpp.Stdlib.sizeof(PlayState)}');
				// }
			case 'trace' :
				// Console.print(haxe.CallStack.exceptionStack(true));
				text = text.substring(text.indexOf(' '));
				trace(text);
				return text;
			case 'stack' :
				// Console.print(haxe.CallStack.exceptionStack(true));
				return haxe.CallStack.exceptionStack(true);
			case 'quit' | 'exit':
				Sys.exit(0);
				return null;
			case 'close' | 'exitconsole' | 'hide':
				Console.showConsole = false;
				return null;
			case 'echo' | "print":
				text = text.substring(text.indexOf(' '));
				Console.print(text);
				return text;
			case 'help':
				var ret = 'Command list:';
				for(_ => v in cmdList){
					ret += (v[1] == null ? '\n${v[0]}' : '\n`${v[0]}` - ${v[1]}');
				}
				Console.print(ret);
				return null;
				              // \n"hs (CODE)" - Run hscript code\n"hst (CODE)" - Run HScript Code encased in a trace\n"reload" - Reset current state\n"mainmenu" - Go to the main menu');
			default:
				try{
					if(MusicBeatState.instance != null){
						var ret:Dynamic = MusicBeatState.instance.consoleCommand(text,args);
						if(ret != null) return ret;
					}
				}catch(e){
					Console.error(e.message);
				}
				Console.error('Command "${args[0]}" not found, run help for a list of commands');
		}
		return null;
	}
	@:keep inline function getDefs(){
		return "-- normal defs --"
		#if(windows)				+"\n windows" #end
		#if(macos)					+"\n macos" #end
		#if(linux)					+"\n linux" #end
		#if(android)				+"\n android" #end
		#if(web)					+"\n web" #end
		#if(flash)					+"\n flash" #end
		#if(sys)					+"\n sys" #end
		#if(target.sys)				+"\n target.sys" #end
		#if(target.static)			+"\n target.static" #end
		#if(target.threaded)		+"\n target.threaded" #end
		#if(ghaction)				+"\n ghaction" #end
		+"\n-- compiler defs --"
		#if(HXCPP_M64)				+"\n HXCPP_M64" #end
		#if(HXCPP_M32)				+"\n HXCPP_M32" #end
		#if(HXCPP_CHECK_POINTER)	+"\n HXCPP_CHECK_POINTER" #end
		#if(HXCPP_STACK_LINE)		+"\n HXCPP_STACK_LINE" #end
		#if(HXCPP_GC_GENERATIONAL)	+"\n HXCPP_GC_GENERATIONAL" #end
		#if(dce)					+"\n dce" #end
		#if(debug)					+"\n debug" #end
		+"\n-- flixel defs --"
		#if(FLX_DEBUG)				+"\n FLX_DEBUG" #end
		#if(FLX_NO_DEBUG)			+"\n FLX_NO_DEBUG" #end
		#if(FLX_NO_GAMEPAD)			+"\n FLX_NO_GAMEPAD" #end
		#if(FLX_NO_TOUCH)			+"\n FLX_NO_TOUCH" #end
		#if(FLX_NO_MOUSE)			+"\n FLX_NO_MOUSE" #end
		#if(FLX_NO_KEYBOARD)		+"\n FLX_NO_KEYBOARD" #end
		+"\n-- package defs --"
		#if(linc_luajit)			+"\n linc_luajit" #end
		#if(hscript)				+"\n hscript" #end
		#if(discord_rpc)			+"\n discord_rpc" #end
		;
	}
}

class ConsoleUtils{
	// function getIndexType(index:String):Dynamic{
	// 	index = index.substring(2,-1);
	// 	if(index )
	// }
	public static function getValueFromPath(object:Dynamic,path:String = "",returnErrors:Bool = true):Dynamic{
		var splitPath:Array<String> = path.split('.');


		if(path == "" || splitPath[0] == null){
			throw 'Path is empty!';
			return null;
		}
		if(object == null){
			var obj:String = splitPath.shift();
			if(obj.indexOf('[') > -1){
				var _obj = obj.split('[');
				obj = _obj[0];
				splitPath.unshift('this'+ _obj[1].substr(0,-1));
			}
			object = ConsoleUtils.quickObject(obj);
			if(object == null) object = Reflect.field((cast FlxG.state),obj);
			if(object == null) object = Type.resolveClass(obj);
			// if(object == null) object = getStaticObject(object);
			if(object == null && PlayState.instance != null) object = PlayState.instance.objects[obj];
			if(object == null) object = Reflect.field(PlayState,obj);
			if(object == null) object = Reflect.getProperty(PlayState,obj);

			if(object == null){
				throw 'Unable to find top-level object ${obj} from path ${path}';
				return null;
			}
			
		}
		var currentPath:String = "";
		while(splitPath.length > 0){
			currentPath = splitPath.shift();
			var subPath:String = "";
			if(currentPath.indexOf('[') > -1){
				var _obj = currentPath.split('[');
				currentPath = _obj[0];
				subPath = _obj[1].substr(0,-1);
			}
			if(currentPath != "this") object = Reflect.field(object,currentPath);
			if(object != null && subPath != ""){
				if(object is Array){
					object = object.get(Std.parseInt(subPath));
				}else if(subPath.indexOf(':') != -1){
					var _subPath = subPath.split(':');
					switch(_subPath[0]){
						case 'f':
							object = object.get(Std.parseFloat(_subPath[1]));
						case 'i':
							object = object.get(Std.parseInt(_subPath[1]));
						default:
							object = object.get(_subPath[1]);
					}

				}else{
					object = object.get(subPath);
				}
			}
			if(object == null){
				throw 'Unable to find object from path ${path}(On ${currentPath})';
				return null;
			}
		}
		if(object is String){
			return '[[$object]]';
		}
		return object;
	}

	public static function quickObject(vari:String):Dynamic{
		switch(vari){
			case "boyfriend" | "bf": return PlayState.boyfriend;
			case "opponent" | "dad": return PlayState.dad;

			case "player" | "playerCharacter": return PlayState.playerCharacter;
			case "opponentCharacter": return PlayState.opponentCharacter;

			case "girlfriend" | "gf": return PlayState.gf;
			case "song" | "SONG": return PlayState.SONG;
			case "PlayState": return PlayState;
			case "Note": return Note;
			case "Character": return Character;
			case "TitleState": return TitleState;
			case "MainMenuState": return MainMenuState;
			case "MusicBeatState": return MusicBeatState;
			case "state" | "State" | "game" | "Game": return cast FlxG.state; 
		}

		return null;
	}
	public static function setValueFromPath(path:String = "",value:Dynamic){
		var splitPath:Array<String> = path.split('.');
		var obj:Dynamic = null;
		if(splitPath.length > 1) obj = getValueFromPath(obj,path.substring(0,path.lastIndexOf('.')),false);
		if(obj is String) return obj;
		if(obj == null) throw('Object "${path}" is null!');
		var type = 0;
		if(value is String){
			if(value.substring(0,1) == "[[" || value.substring(0,1) == "]]"){
				value = value.substring(3,-2);
			}else if(value.substring(0,1) == "'" || value.substring(0,1) == '"'){
				value = value.substring(2,-1);
			}else if(!Math.isNaN(Std.parseFloat(value))){
				value = Std.parseFloat(value);
				type = 1;
			}else if(!Math.isNaN(Std.parseInt(value))){
				value = Std.parseInt(value);
				type = 1;
			}
		}
		var lastPath = splitPath.pop();
		var field = Reflect.field(obj,lastPath);
		if(field != null){
			if((field is Int || field is Float) && type != 1) {
				throw('Field of type ${Type.typeof(field)} is incompatible with ${Type.typeof(value)}');
				return;
			}
			if(field is Int) value = Std.int(value);
			// if(field is String) ;
		}

		Reflect.setField(obj,lastPath,value);
	}
}