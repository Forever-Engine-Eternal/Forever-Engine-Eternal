package forever.backend;

import flixel.util.FlxColor;
import sys.FileSystem;

class LevelData {
	// TODO: custom difficulties per level
	public static final defaultDiffs:Array<String> = ["EASY", "NORMAL", "HARD"];
	public static var curDifficulties:Array<String> = defaultDiffs;
	public static var gameWeeks:Array<Dynamic> = [];

	public static function loadLevels(clearCurrent:Bool = false):Void {
		if (clearCurrent)
			LevelData.gameWeeks = [];

		if (FileSystem.exists(Paths.getPath('data/weekList', TXT))) {
			var weekFile:String = Paths.getPath('data/weekList', TXT).trim();
			var weekData:SSIni = new SSIni(weekFile);
			for (key in weekData.sections.keys()) {
				var seperator:String = ", ";
				var data = weekData.sections.get(key);
				var songList:Array<String> = data.get("songs").split(seperator);
				var iconList:Array<String> = data.get("icons").split(seperator);
				var tempColors:Array<String> = data.get("colors").split(seperator);
				var bpms:Array<Float> = [for (bpm in data.get("bpms").split(seperator)) Std.parseFloat(bpm)];
				var difficulties:Array<String> = data.exists("diffs") ? data.get("diffs").split(seperator) : defaultDiffs;
				var colorList:Array<FlxColor> = [];

				for (i in 0...tempColors.length) {
					if (!tempColors[i].startsWith("#"))
						tempColors[i] = "#" + tempColors[i];
					colorList[i] = FlxColor.fromString(tempColors[i]);
				}

				var keyParams:Array<String> = key.split(" - ");
				var week:Dynamic = [songList, iconList, colorList, keyParams[1], bpms, difficulties];
				if (!LevelData.gameWeeks.contains(week))
					LevelData.gameWeeks[Std.parseInt(keyParams[0])] = week;
			}
		}
	}

	public static function loadFreeplayList():Array<FreeplaySong> {
		var songList:Array<FreeplaySong> = [];

		if (FileSystem.exists(Paths.txt('data/freeplaySonglist'))) {
			for (i in Tools.coolTextFile(Paths.txt('data/freeplaySonglist'))) {
				var structure:Array<String> = i.split("--");
				// check splits on text file
				var song:String = structure[0];
				var icon:String = structure[1];
				var stringColor:String = structure[2];
				if (!structure[2].startsWith("#"))
					stringColor = "#" + structure[2];
				var bpm:Float = Std.parseFloat(structure[3]);

				var color:FlxColor = FlxColor.fromString(stringColor);
				var difficulties:Array<String> = structure[4] != null ? structure[4].split(",") : defaultDiffs;

				if (FileSystem.exists(Paths.songJson(song, song)))
					songList.push(new FreeplaySong(song.toLowerCase(), icon, color, 1, bpm, difficulties));
			}
		}

		return songList;
	}
}

class FreeplaySong {
	public var song:String;
	public var icon:String;
	public var color:FlxColor;
	public var week:Int;
	public var difficulties:Array<String> = [];
	public var bpm:Float;

	public function new(song:String, icon:String, color:FlxColor, week:Int, bpm:Float, ?difficulties:Array<String>):Void {
		this.song = song;
		this.icon = icon;
		this.color = color;
		this.week = week;
		this.bpm = bpm;
		this.difficulties = difficulties;
	}
}
