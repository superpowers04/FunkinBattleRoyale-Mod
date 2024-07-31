package;


import hscript.Expr;
import hscript.Interp;
import hscriptfork.InterpSE;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import sys.io.File;
import sys.FileSystem;
import ScriptableStates;
import se.handlers.SELua;


class ScriptableStateManager {
	// public static var interps:Map<String,Interp> = [];
	// public static var interp:Interp;
	public static var _subState:Dynamic;
	public static var lastState:String = "";
	public static var goToLastState:Bool = false;
	public static var currentPath:String = "";
	public static function init(state:Class<FlxState>):Dynamic{
		try{
			goToLastState = false;
			// interp = _interp;
			// interps = ["main" => interp];
			@:privateAccess
			{
				_subState = cast Type.createInstance(state,[]);
			// 	interp.variables.set("state",_subState);
			}
			
			// callInterp("new",[]);
			return _subState;
		}catch(e){
			SelectScriptableState.handleError('Error occured when trying to create state: ${e.message}\n${e.stack}');
			return null;
		}
	}
	public static function initState(state:MusicBeatState){
		_subState = state;
		loadScript('state.hscript');

	}
	public static function die(){
		// interps.clear();
		// interp = null;
		_subState = null;
	}
	// public static override function update(e:Float){
	// 	callInterp("update",[e]);
	// 	super.update(e);
	// 	callInterp("updateAfter",[e]);
	// }
	public static function loadScript(path:String):Dynamic{
		// var _it = 0;
		// var _id = id;
		// while(interps[id] != null){
		// 	id = '${_id}-${_it++}';
		// }
		// if(scriptFolder){
		// 	path = interps["main"].variables.get("BRtools").path + "/" + path;
		// }

		// var interp = interps[id] = SelectScriptableState.parseHS(SELoader.loadText(path), new HSBrTools(path.substr(0,path.lastIndexOf("/"))), id);
		var interp = _subState.loadSingleScript(currentPath+path);
		if(interp == null) return null;
	// 		interp.variables.set("id",id);
		if(interp is SELua){
			var interp:SELua = cast interp;
			interp.variables.set("close",function(){ FlxG.switchState(new SelectScriptableState()); }); // Closes a script
			interp.variables.set("Manager",ScriptableStateManager);
			interp.variables.set("ScriptableStateManager",ScriptableStateManager);
			interp.variables.set("FlxG",FlxG);
		}
		if(interp is Interp){
			var interp:Interp = cast interp;
			interp.variables.set("close",function(){ FlxG.switchState(new SelectScriptableState()); }); // Closes a script
			interp.variables.set("Manager",ScriptableStateManager);
			interp.variables.set("ScriptableStateManager",ScriptableStateManager);
			interp.variables.set("FlxG",FlxG);
		}

		return interp;
		
	}
	@:keep public static inline function callSingleInterp(func_name:String, args:Array<Dynamic>,id:String){
		_subState.callSingleInterp(func_name,args,id);
		// try{
		// 	if (interps[id] == null) {trace('No Interp ${id}!');return;}
		// 	if (!interps[id].variables.exists(func_name)) {return;}
		// 	var method = interps[id].variables.get(func_name);

		// 	Reflect.callMethod(interps[id],method,args);
		// }catch(e:hscript.Expr.Error){try{handleError('${func_name} for "${id}":\n ${e.toString()}');}catch(e){
		// 		MainMenuState.handleError(e,'Errored on ${func_name} for "${id}": ${e.toString()}');
		// 	}}
	}
	public static function handleError(str:String){ // Literally just a redirect
		SelectScriptableState.handleError(str);
	}
	public static var cancelCurrentFunction:Bool = false;
	@:keep public static inline function callInterp(func_name:String, args:Array<Dynamic>,?id:String = "") { // Modified from Modding Plus, literally no reason to recreate it myself
			_subState.callInterp(func_name,args,id);
			// cancelCurrentFunction = false;
			// try{
			// 	// args.insert(0,this);
			// 	if (id == "") {

			// 		for (name in interps.keys()) {
			// 			callSingleInterp(func_name,args,name);
			// 		}
			// 	}else callSingleInterp(func_name,args,id);
			// }catch(e:hscript.Expr.Error){try{handleError('${func_name} for "${id}":\n ${e.toString()}');}catch(e){
			// 	MainMenuState.handleError(e,'Errored on ${func_name} for "${id}": ${e.toString()}');
			// }}

		}
}

class SelectScriptableState extends SearchMenuState{
	@:keep inline public static function callInterpet(func_name:String, args:Array<Dynamic>,interp:Interp){
		try{
			if (!interp.variables.exists(func_name)) {return;}
			// trace('$func_name:$id $args');
			
			var method = interp.variables.get(func_name);
			Reflect.callMethod(interp,method,args);
		}catch(e:hscript.Expr.Error){handleError('${func_name}:\n ${e.toString()}');}
	}
	// public static function parseHS(?script:String = "",?brTools:HSBrTools = null,?id:String = ""):Null<Interp>{
	// 	if (script == "") {handleError("Script has no contents!");return null;}
	// 	var interp = HscriptUtils.createSimpleInterp();
	// 	var parser = new hscript.Parser();
	// 	try{
	// 		parser.allowTypes = parser.allowJSON = parser.allowMetadata = true;

	// 		var program;
	// 		// parser.parseModule(songScript);
	// 		program = parser.parseString(script);

	// 		if (brTools != null) {
	// 			trace('Using hsBrTools');
	// 			interp.variables.set("BRtools",brTools); 
	// 			brTools.reset();
	// 		}else {
	// 			trace('Using assets folder');
	// 			interp.variables.set("BRtools",new HSBrTools("assets/"));
	// 		}
	// 		interp.variables.set("id",id);
	// 		interp.variables.set("close",function(){ FlxG.switchState(new SelectScriptableState()); }); // Closes a script
	// 		interp.variables.set("Manager",ScriptableStateManager);
	// 		interp.variables.set("ScriptableStateManager",ScriptableStateManager);
	// 		interp.variables.set("FlxG",FlxG);
	// 		interp.variables.set("state",null);
	// 		interp.execute(program);
	// 		if(brTools != null)brTools.reset();
	// 		callInterpet("initScript",[],interp);
	// 		return interp;
	// 	}catch(e){
	// 		handleError('Error parsing ${id} hscript, Line:${parser.line};\n Error:${e.message}');
	// 		// interp = null;
	// 	}
	// 	return null;
	// }

	public static function handleError(err:String){
		// try{ScriptableStateManager.die();}catch(e){}
		// MainMenuState.handleError(err);
		throw(err);
		// Main.game.forceStateSwitch(new SelectScriptableState(err));
	}

	static var defText:String = "Use shift to scroll faster";
	var descriptions:Map<String,String> = new Map<String,String>();
	var err = "";
	var unusableList:Array<Bool> = [];
	override public function new(?err:String = ""){
		super();
		this.err = err;
		ScriptableStateManager.die();
		ScriptableStateManager.lastState = "";
		ScriptableStateManager.goToLastState = false;
	}
	override function addToList(char:String,i:Int = 0){
		songs.push(char);
		var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, char, true, false);
		controlLabel.isMenuItem = true;
		controlLabel.targetY = i;
		// if(unusableList[i]) controlLabel.color = FlxColor.RED;
		if (i != 0) controlLabel.alpha = 0.6;
		grpSongs.add(controlLabel);
	}

	override function reloadList(?reload = false,?search=""){try{
		curSelected = 0;
		if(reload){grpSongs.clear();}
		songs = [];

		var i:Int = 0;
		var query = new EReg((~/[-_ ]/g).replace(search.toLowerCase(),'[-_ ]'),'i'); // Regex that allows _ and - for songs to still pop up if user puts space, game ignores - and _ when showing
		for (char in searchList){
			if(search == "" || query.match(char.toLowerCase()) ){
				addToList(char,i);
				i++;
			}
		}
	}catch(e) MainMenuState.handleError('Error with loading stage list ${e.message}');}

	override function ret(){
		FlxG.switchState(new MainMenuState());
	}
	override function create()
	{try{
		searchList = [];
		retAfter = false;
		if(SELoader.exists('mods/scripts')) {
			for (directory in orderList(SELoader.readDirectory('mods/scripts/'))) {
				var _dir:Bool = SELoader.isDirectory("mods/scripts/"+directory);
				if (_dir && SELoader.exists("mods/scripts/"+directory+"/state/state.hscript"))
				{
					unusableList[searchList.length] = false;
					searchList.push(directory);
					if (SELoader.exists("mods/scripts/"+directory+"/description.txt")){
						descriptions[directory] = SELoader.loadText('mods/scripts/${directory}/description.txt');
					}
				}
				// else if (_dir){
				// 	unusableList[searchList.length] = true;
				// 	searchList.push(directory);
				// 	if (FileSystem.exists("mods/scripts/"+directory+"/description.txt")){
				// 		descriptions[directory] = "This script has no state.hscript and cannot be run!";
				// 	}
				// }
			}
		}
		if (searchList[0] == null){searchList = ['No scripts found!'];trace('No scripts found!');}
		// searchList = TitleState.choosableStages;
		super.create();

		addTitleText("Select a script to run");
		if(err != ""){
			showTempmessage(err,FlxColor.RED,10);
		}
		bg.color = 0x444460;
	}catch(e) MainMenuState.handleError('Error with stagesel "create" ${e.message}');}

	override function changeSelection(change:Int = 0){
		super.changeSelection(change);
		var song = songs[curSelected];
		if (song != "" && descriptions[song] != null ){
		  updateInfoText('${defText}; ' + descriptions[song]);
		}else{
		  updateInfoText('${defText}; No description for this script.');
		}
	}

	override function select(sel:Int = 0){
		// SESave.data.selStage = songs[sel];
		if(songs[sel] != 'No scripts found!' && SELoader.exists("mods/scripts/" + songs[sel] + "/state/state.hscript")){
			selectState(songs[sel]);
		}
	}
	public static function selectState(scriptName){
		var stateType = "musicbeatstate";
		if(SELoader.exists("mods/scripts/" + scriptName + "/statetype.txt")){
			stateType = SELoader.getContent("mods/scripts/" + scriptName + "/statetype.txt");
		}
		var state:Class<FlxState> = null;
		switch(stateType.toLowerCase()){
			case "searchmenustate":
				state = ScriptableSearchMenuState;
			// case "sickmenustate":
				// state = SickMenuState;
			case "musicbeatstate":
				state = ScriptableMusicBeatState;
			// case "quickoptionssubstate":
			// 	state = QuickOptionsSubState;
			// case "playstate":
			// 	state = PlayState;
		}
		if(state == null){MusicBeatState.instance.showTempmessage('Script is trying to use class "${stateType}" but that isn\'t a valid state!',FlxColor.RED); return;}

		// var _interp = parseHS(SELoader.loadText("mods/scripts/" + scriptName + "/state/state.hscript"), new HSBrTools("mods/scripts/" + scriptName),"main");
		// if(_interp == null){
		// 	// showTempmessage("");
		// 	return;
		// }
		ScriptableStateManager.currentPath = "mods/scripts/" + scriptName+"/state/";
		var _state = ScriptableStateManager.init(state);
		if(_state == null) return ScriptableStateManager.die();
		ScriptableStateManager.lastState = scriptName;
		FlxG.switchState(_state);
		// FlxG.switchState(new state(_interp,state));
		// switch(stateType.toLowerCase()){
		// 	default:
		// 		// FlxG.switchState(new ScriptableMusicBeatState(_interp));
		// }
		// reloadList();
	}
}



/*  Generated thanks to lua lmoa  */





