package forever.states.menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import forever.backend.LevelData;
import forever.data.*;
import forever.music.Conductor;
import forever.music.MusicBeat.MusicBeatState;
import forever.ui.Alphabet;
import forever.ui.HealthIcon;
import openfl.media.Sound;
import sys.FileSystem;
import sys.thread.Mutex;
import sys.thread.Thread;

class FreeplayState extends MusicBeatState {
	//
	var songs:Array<FreeplaySong> = [];

	var curSelected:Int = 0;

	static var lastSelected:Int = -1;

	var curSongPlaying:Int = -1;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var rankText:FlxText;
	var diffText:FlxText;

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var lerpAccuracy:Float = 0;
	var currentAccuracy:Float = 0;
	var currentRank:String;
	var currentBreaks:Int = 0;

	var songThread:Thread;
	var threadActive:Bool = true;
	var mutex:Mutex;

	var grpSongs:FlxTypedGroup<Alphabet>;
	var curPlaying:Bool = false;

	var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var scoreBG:FlxSprite;
	var mainColor:FlxColor = FlxColor.WHITE;

	var existingSongs:Array<String> = [];
	var existingDifficulties:Array<Array<String>> = [];

	override function create() {
		super.create();

		mutex = new Mutex();

		if (LevelData.gameWeeks.length > 0) {
			for (i in 0...LevelData.gameWeeks.length) {
				var weekSongs:Array<String> = LevelData.gameWeeks[i][0];
				var weekIcons:Array<String> = LevelData.gameWeeks[i][1];
				var weekColors:Array<FlxColor> = LevelData.gameWeeks[i][2];
				var weekBpms:Array<Float> = LevelData.gameWeeks[i][4];
				var weekDifficulties:Array<String> = LevelData.gameWeeks[i][5];
				addWeek(weekSongs, i, weekIcons, weekColors, weekBpms, weekDifficulties);

				for (j in weekSongs)
					if (!existingSongs.contains(j.toLowerCase()))
						existingSongs.push(j.toLowerCase());
			}
		}

		for (i in LevelData.loadFreeplayList()) {
			if (!existingSongs.contains(i.song.toLowerCase())) {
				addSong(i.song, 1, i.icon, i.color, i.bpm, i.difficulties);
				existingSongs.push(i.song.toLowerCase());
			}
		}

		Discord.changePresence('FREEPLAY MENU', 'In Menus');

		persistentUpdate = true;

		bg = new FlxSprite().loadGraphic(Paths.image('menus/menuDesat'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length) {
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].song, true, false);
			songText.xTo = -200;
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].icon);
			icon.sprTracker = songText;
			icon.boppingIcon = !Init.trueSettings.get('Reduced Movements');

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - scoreText.width, 0).makeGraphic(Std.int(FlxG.width * 0.65), 86, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		rankText = new FlxText(scoreBG.x, scoreText.y + 104, 0, "", 32);
		rankText.alignment = CENTER;
		rankText.font = scoreText.font;
		rankText.alpha = showRatingText ? 1 : 0;
		add(rankText);

		diffText = new FlxText(scoreText.x, scoreText.y + scoreText.height, 0, "", 24);
		diffText.alignment = CENTER;
		diffText.font = scoreText.font;
		diffText.x = scoreBG.getGraphicMidpoint().x;
		add(diffText);

		add(scoreText);

		if (lastSelected != -1) {
			if (lastSelected > grpSongs.members.length || lastSelected < 0)
				lastSelected = 0;
			curSelected = lastSelected;
		}

		changeSelection();
		changeDiff();

		if (!Init.trueSettings.get('Reduced Movements'))
			for (i in 0...grpSongs.length)
				FlxTween.tween(grpSongs.members[i], {x: 0}, 0.4, {ease: FlxEase.quartOut});

		var mouseHandler = new forever.data.inputs.MouseHandler();
		mouseHandler.onWheelScroll = changeSelection;
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, songColor:FlxColor, bpm:Float, ?difficulties:Array<String>) {
		songName = Tools.spaceToDash(songName);

		if (difficulties == null)
			difficulties = LevelData.defaultDiffs;

		var coolDifficultyArray = [];
		for (i in difficulties)
			if (FileSystem.exists(Paths.songJson(songName, songName + '-' + i))
				|| (FileSystem.exists(Paths.songJson(songName, songName)) && i == "NORMAL"))
				coolDifficultyArray.push(i);

		if (coolDifficultyArray.length > 0) {
			songs.push(new FreeplaySong(songName, songCharacter, songColor, weekNum, bpm));
			existingDifficulties.push(coolDifficultyArray);
		}
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>, ?songColor:Array<FlxColor>, bpms:Array<Float>, ?difficulties:Array<String>) {
		if (songCharacters == null)
			songCharacters = ['bf'];
		if (songColor == null)
			songColor = [FlxColor.WHITE];
		if (difficulties == null)
			difficulties = LevelData.defaultDiffs;

		var num:Array<Int> = [0, 0, 0];
		for (song in songs) {
			addSong(song.toLowerCase(), weekNum, songCharacters[num[0]], songColor[num[1]], bpms[num[2]], difficulties);

			if (songCharacters.length != 1)
				num[0]++;
			if (songColor.length != 1)
				num[1]++;
			if (bpms.length != 1)
				num[2]++;
		}
	}

	static var showRatingText:Bool = false;

	override function update(elapsed:Float) {
		super.update(elapsed);
		
		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		// TODO: Fix the beatHit not being called each time it should @Sword352
		if (FlxG.sound.music.playing) {
			Conductor.songPosition = FlxG.sound.music.time;
			if (Conductor.songPosition == Conductor.lastSongPos)
				Conductor.songPosition += elapsed * 1000;
		}

		var lerpVal:Float = Tools.boundFPS(0.1);

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, lerpVal));
		if (Math.abs(lerpScore - intendedScore) <= 20)
			lerpScore = intendedScore;

		lerpAccuracy = FlxMath.lerp(lerpAccuracy, currentAccuracy, lerpVal);
		if (Math.abs(lerpAccuracy - currentAccuracy) <= 0.01)
			lerpAccuracy = Math.floor(currentAccuracy * 100) / 100;

		bg.scale.set(FlxMath.lerp(bg.scale.x, 1, lerpVal), FlxMath.lerp(bg.scale.y, 1, lerpVal));

		if (controls.anyJustPressed(["up", "down"]))
			changeSelection(controls.justPressed("up") ? -1 : 1);
		if (controls.anyJustPressed(["left", "right"]))
			changeDiff(controls.justPressed("left") ? -1 : 1);

		if (controls.justPressed("back")) {
			threadActive = false;
			FlxG.sound.play(Paths.sound("cancelMenu"));
			if (!FlxG.keys.pressed.SHIFT)
				if (FlxG.sound.music != null)
					FlxG.sound.music.stop();
			Main.switchState(new MainMenuState());
		}

		if (controls.justPressed("accept")) {
			PlayState.storyWeek = songs[curSelected].week;
			PlayState.isStoryMode = false;
			LevelData.curDifficulties = existingDifficulties[curSelected];
			// PlayState.storyDifficulty = curDifficulty;

			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
			threadActive = false;

			var diff:String = existingDifficulties[curSelected][curDifficulty];
			Main.switchState(new PlayState(Tools.spaceToDash(songs[curSelected].song.toLowerCase()), diff));
		}

		// Adhere the position of all the things (I'm sorry it was just so ugly before I had to fix it Shubs)
		scoreText.text = "HIGH SCORE:" + lerpScore;
		scoreText.x = FlxG.width - scoreText.width - 5;

		rankText.text = 'BREAKS: ${currentBreaks}\nRANK: ${currentRank}\nACCURACY: ${FlxMath.roundDecimal(lerpAccuracy, 2)}%';
		// rankText.alpha = FlxMath.lerp(rankText.alpha, showRatingText ? 1 : 0, lerpVal);

		scoreBG.width = scoreText.width + 8;
		scoreBG.x = FlxG.width - scoreBG.width;
		scoreBG.scale.y = FlxMath.lerp(scoreBG.scale.y, showRatingText ? 5 : 1, lerpVal);
		diffText.x = scoreBG.x + (scoreBG.width / 2) - (diffText.width / 2);
		rankText.centerOverlay(scoreText, X);

		if (FlxG.keys.justPressed.CONTROL) {
			showRatingText = !showRatingText;
			FlxTween.cancelTweensOf(rankText);
			FlxTween.tween(rankText, {alpha: showRatingText ? 1 : 0}, 0.2);
		}

		Conductor.lastSongPos = Conductor.songPosition;
	}

	override function beatHit() {
		super.beatHit();

		if (!Init.trueSettings.get('Reduced Movements')) {
			iconArray[curSelected].bop();
			bg.scale.set(1.075, 1.075);
		}
	}

	var lastDifficulty:String;

	function changeDiff(change:Int = 0) {
		curDifficulty += change;
		if (lastDifficulty != null && change != 0)
			while (existingDifficulties[curSelected][curDifficulty] == lastDifficulty)
				curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = existingDifficulties[curSelected].length - 1;
		if (curDifficulty > existingDifficulties[curSelected].length - 1)
			curDifficulty = 0;

		reloadScore();

		diffText.text = '< ' + existingDifficulties[curSelected][curDifficulty] + ' >';
		lastDifficulty = existingDifficulties[curSelected][curDifficulty];
	}

	function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		reloadScore();

		// set up color stuffs
		mainColor = songs[curSelected].color;

		// song switching stuffs
		for (i in 0...iconArray.length) {
			iconArray[i].alpha = curSelected == i ? 1 : 0.6;
			iconArray[i].boppingIcon = curSelected == i && !Init.trueSettings.get('Reduced Movements');
		}

		var bullShit:Int = 0;
		for (item in grpSongs.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = item.targetY == 0 ? 1 : 0.6;
			item.active = item.targetY > -5 || item.targetY < 5;
		}

		lastSelected = curSelected;

		changeDiff();
		changeSongPlaying();

		if (bg.color != mainColor) {
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 0.35, bg.color, mainColor);
		}
	}

	function changeSongPlaying() {
		if (songThread == null) {
			songThread = Thread.create(function() {
				while (true) {
					if (!threadActive)
						return;

					var index:Null<Int> = Thread.readMessage(false);
					if (index != null) {
						if (index == curSelected && index != curSongPlaying) {
							// dashToSpace because doing Paths.inst would do a swapSpaceDash of the argument
							var inst:Sound = Paths.inst(Tools.dashToSpace(songs[curSelected].song.toLowerCase()));

							if (index == curSelected && threadActive) {
								mutex.acquire();

								FlxG.sound.playMusic(inst);
								if (FlxG.sound.music.fadeTween != null)
									FlxG.sound.music.fadeTween.cancel();

								FlxG.sound.music.volume = 0.0;
								FlxG.sound.music.fadeIn(1.0, 0.0, 1.0);
								mutex.release();
								curSongPlaying = curSelected;

								Conductor.changeBPM(songs[curSelected].bpm);
								Conductor.songPosition = 0;
							}
						}
					}
				}
			});
		}

		songThread.sendMessage(curSelected);
	}

	function reloadScore() {
		var scoreData = Highscore.getScore(songs[curSelected].song, curDifficulty);
		intendedScore = scoreData.score;
		currentRank = scoreData.rating;
		currentAccuracy = scoreData.accuracy;
		currentBreaks = scoreData.breaks;
	}
}
