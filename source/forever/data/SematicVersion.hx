package forever.data;

import sys.io.Process;

/**
 * Helper object for semantic versioning.
 * @see   http://semver.org/
 */
class SematicVersion {
	public var major(default, null):Int;
	public var minor(default, null):Int;
	public var patch(default, null):Int;
	public var extraData(default, null):String;
	public var showGitSHA(default, null):Bool;

	public function new(Major:Int, Minor:Int, Patch:Int, ShowGitSHA:Bool = false, ExtraData:String = null):Void {
		major = Major;
		minor = Minor;
		patch = Patch;
		showGitSHA = ShowGitSHA;
		extraData = ExtraData;
	}

	/**
	 * Formats the version in the format "HaxeFlixel MAJOR.MINOR.PATCH-COMMIT_SHA",
	 * e.g. HaxeFlixel 3.0.4.
	 * If this is a dev version, the git sha is included.
	 */
	public function toString(sematic:Bool = false):String {
		var returnString:String = '${major}.${minor}';
		returnString += sematic ? '.${patch}' : '${patch}';
		if (extraData != null)
			returnString += ' ${extraData}';
		if (showGitSHA) {
			var sha:String = getGitSHA();
			if (sha != "") {
				sha = "@" + sha.substring(0, 7);
				returnString += ' ${sha}';
			}
		}
		return returnString;
	}

	public static function getGitSHA():String {
		var sha:String = getProcessOutput("git", ["rev-parse", "HEAD"]);
		var shaRegex = ~/[a-f0-9]{40}/g;
		if (!shaRegex.match(sha))
			sha = "";
		return sha;
	}

	public static function getProcessOutput(cmd:String, args:Array<String>):String {
		try {
			var process:Process = new Process(cmd, args);
			var output:String = try process.stdout.readAll().toString() catch (_:Dynamic) "";
			process.close();
			return output;
		} catch (_:Dynamic)
			return "";
	}
}
