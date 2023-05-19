package forever.scripting;

import forever.data.ObjectState;
import hscript.Interp;
import hscript.Parser;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class FNFScript {
	public var parser:Parser;
	public var interp:Interp;

	var _curPath:String = null;
	var _curScript:String = null;
	var _state:ObjectState = NONE;

	public var defaultImports:Map<String, Dynamic> = [
		"Std" => Std,
		"Math" => Math,
		"StringTools" => StringTools,
		"FlxG" => flixel.FlxG,
		"FlxSprite" => flixel.FlxSprite,
		"FlxSound" => flixel.system.FlxSound,
		"FlxTween" => flixel.tweens.FlxTween,
		"FlxEase" => flixel.tweens.FlxEase,
		"FlxTimer" => flixel.util.FlxTimer,
		"FlxMath" => flixel.math.FlxMath,
		"FNFSprite" => forever.data.utils.FNFSprite,
		"Conductor" => forever.music.Conductor,
		"FlxGroup" => flixel.group.FlxGroup,
		"Tools" => forever.Tools,
		"Paths" => Paths,

		// Abstracts
		"FlxColor" => FNFScriptAbstracts.FlxColor,
		"FlxInputState" => FNFScriptAbstracts.FlxInputState,
		"FlxAxes" => FNFScriptAbstracts.FlxAxes,

		// FlxTweenType
		"PERSIST" => flixel.tweens.FlxTween.FlxTweenType.PERSIST,
		"LOOPING" => flixel.tweens.FlxTween.FlxTweenType.LOOPING,
		"PINGPONG" => flixel.tweens.FlxTween.FlxTweenType.PINGPONG,
		"ONESHOT" => flixel.tweens.FlxTween.FlxTweenType.ONESHOT,
		"BACKWARD" => flixel.tweens.FlxTween.FlxTweenType.BACKWARD
	];

	public function new(path:String):Void {
		parser = new Parser();
		interp = new Interp();

		parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
		interp.allowPublicVariables = interp.allowStaticVariables = true;

		// loop through extensions to make sure the path exists
		for (ext in Paths.AssetType.SCRIPT.getExtension()) {
			// path with ext
			if (FileSystem.exists(path) && path.endsWith('${ext}')) {
				_curPath = path;
				_curScript = File.getContent(path);
				print('Loading module ${path}', SCRIPT);
				break;
			}
			// path without ext
			if (FileSystem.exists('${path}${ext}')) {
				_curPath = '${path}${ext}';
				_curScript = File.getContent('${path}${ext}');
				print('Loading module ${path}', SCRIPT);
				break;
			}
		}

		parser.preprocesorValues.set("version", Main.gameVersions["normal"].toString(true));
		parser.preprocesorValues.set("debug", #if debug true #else false #end);
		parser.preprocesorValues.set("platform", #if windows "windows" #elseif macos "macos" #elseif linux "linux" #else "unknown" #end);

		for (key in defaultImports.keys())
			interp.variables.set(key, defaultImports.get(key));

		try {
			interp.execute(parser.parseString(_curScript, "FNFScript:" + _curPath));
			set("trace", function(_info:String) print('${_curPath}:${interp.posInfos().lineNumber}: ${_info}', FROM_SCRIPT));
			set("print", function(_info:String) print('${_curPath}:${interp.posInfos().lineNumber}: ${_info}', FROM_SCRIPT));
			set("unlockAchievement", forever.backend.Achievements.unlockAchievement);
			set("close", this.destroy);
			_state = ALIVE;
		}
		catch (e:haxe.Exception) {
			print('${_curPath}: Tried to load script, which failed with error: ${e} - ${e.details()}', SCRIPT_ERROR);
			this.destroy();
		}
	}

	public function destroy():Void {
		_state = DEAD;

		@:privateAccess {
			if (interp != null) {
				interp.scriptObject = null;
				interp.errorHandler = null;
				interp.variables.clear();
				interp.variables = null;
				interp.publicVariables = null;
				interp.staticVariables = null;
				for(l in interp.locals)
					if (l != null)
						l.r = null;
				interp.locals.clear();
				interp.locals = null;
				interp.binops.clear();
				interp.binops = null;
				interp.depth = 0;
				interp.inTry = false;
				while(interp.declared.length > 0)
					interp.declared.shift();
				interp.declared = null;
				interp.returnValue = null;
				interp.isBypassAccessor = false;
				interp.importEnabled = false;
				interp.allowStaticVariables = false;
				interp.allowPublicVariables = false;
				while(interp.importBlocklist.length > 0)
					interp.importBlocklist.shift();
				interp.importBlocklist = null;
				while(interp.__instanceFields.length > 0)
					interp.importBlocklist.shift();
				interp.__instanceFields = null;
				interp.curExpr = null;
			}

			if (parser != null) {
				parser.line = 0;
				parser.opChars = null;
				parser.identChars = null;
				parser.opPriority.clear();
				parser.opPriority = null;
				parser.opRightAssoc.clear();
				parser.opRightAssoc = null;
				parser.preprocesorValues.clear();
				parser.preprocesorValues = null;
				parser.input = null;
				parser.readPos = 0;
				parser.char = 0;
				parser.ops = null;
				parser.idents = null;
				parser.uid = 0;
				parser.origin = null;
				parser.tokenMin = 0;
				parser.tokenMax = 0;
				parser.oldTokenMin = 0;
				parser.oldTokenMax = 0;
				parser.tokens = null;
			}
		}
		
		parser = null;
		interp = null;
	}

	public function get(_var:String):Dynamic {
		if (this._state != DEAD)
			return interp.variables.get(_var);
		return null;
	}

	public function exists(_var:String):Bool {
		if (this._state != DEAD)
			return interp.variables.exists(_var);
		return false;
	}

	public function set(_var:String, to:Dynamic):Void {
		if (this._state != DEAD)
			interp.variables.set(_var, to);
	}

	public function setScriptObject(obj:Dynamic):Void {
		if (this._state != DEAD)
			interp.scriptObject = obj;
	}

	/**
	 * Executes a function on your Script
	 *
	 * EXAMPLE USAGE:
	 *
	 * ```haxe
	 * // on script
	 * function myFunction(myParam:Bool, mySecondParam:Bool):Void
	 * {
	 *		print("Hello, Parameter Number 1 is" + myParam + "!");
	 *		print("Hello, Parameter Number 2 is" + mySecondParam + "!");
	 * }
	 *
	 * // on state
	 * var myScript:FNFScript = new FNFScript('assets/data/scripts/myScript.hx');
	 * myScript.call("myFunction", [true, false]); // "Hello, Parameter Number 1 is true!" - "Hello, Parameter Number 2 is false!""
	 * ```
	 * @param _func the Function Name
	 * @param args the Function Arguments
	 */
	public function call(_func:String, ?args:Array<Dynamic>):Dynamic {
		if (this._state == DEAD)
			return null;

		if (args == null)
			args = [];

		var func:Dynamic = get(_func);
		try {
			if (func != null && exists(_func))
				return Reflect.callMethod(this, func, args);
			return null;
		}
		catch (e:haxe.Exception) {
			print('${_curPath}: Tried to call function ${_func}, which failed with error: ${e} - ${e.details()}', SCRIPT_ERROR);
			return null;
		}
	}
}
