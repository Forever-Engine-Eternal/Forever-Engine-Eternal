package forever.states.editors;

import flixel.util.FlxSort;
import forever.objects.notes.Note;
import forever.ui.ForeverTabMenu;
import forever.ui.ForeverButton;
import flixel.math.FlxMath;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxGradient;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import forever.music.ChartFormat;
import forever.music.ChartLoader;
import forever.music.Conductor;
import forever.music.MusicBeat.MusicBeatState;

class ChartEditor extends MusicBeatState {
	public var song:ChartFormat;

	public var songMusic:FlxSound;
	public var vocals:FlxSound;

	public var checkerboard:FlxTiledSprite;
	public var checkerSize:Int = 40;

    public var renderedNotes:FlxTypedGroup<Note>;
	public var renderedSections:FlxTypedGroup<FlxSprite>;
	public var renderedLanes:FlxTypedGroup<FlxSprite>;
	public var lanesLine:FlxSprite;
	public var mouseCursor:FlxSprite;

	var recycledNotes:Map<Int, Array<Note>> = [
		0 => [],
		1 => [],
		2 => [],
		3 => []
	];

	public var songMeta(get, never):SongMetadata;

	var beatText:FlxText;
	var uiCamera:FlxCamera;

	function get_songMeta():SongMetadata
		return ChartLoader.songMeta;

	public function new(songName:String = 'test', difficulty:String = 'normal'):Void {
		song = ChartLoader.loadChart(songName, difficulty);
		super();
	}

	public override function create():Void {
		super.create();

		FlxG.mouse.visible = true;
		loadSong(songMeta.name);

		Conductor.mapBPMChanges(song);
		Conductor.changeBPM(song.bpm);

		uiCamera = new FlxCamera();
		uiCamera.bgColor.alpha = 0;
		FlxG.cameras.add(uiCamera, false);

		// initialize rendering groups
		renderedSections = new FlxTypedGroup<FlxSprite>();
		renderedLanes = new FlxTypedGroup<FlxSprite>();
		renderedNotes = new FlxTypedGroup<Note>();

		generateBackground();
		generateCheckerboard();
		generateUI();

		add(renderedLanes);
		add(renderedSections);
		add(renderedNotes);

		mouseCursor = new FlxSprite().makeGraphic(checkerSize, checkerSize);
		add(mouseCursor);

		lanesLine = new FlxSprite().makeGraphic(Std.int(checkerboard.width), 5, 0xFFFFFFFF);
		lanesLine.screenCenter();
		add(lanesLine);
		FlxG.camera.follow(lanesLine);
	}

	var lanesLineOffsetY:Float = 0;

	public override function update(elapsed:Float):Void {
		Conductor.songPosition = songMusic.time;

		super.update(elapsed);

		if (FlxG.mouse.x > checkerboard.x
			&& FlxG.mouse.x < (checkerboard.x + checkerboard.width)
			&& FlxG.mouse.y > 0
			&& FlxG.mouse.y < (getYfromStrum(songMusic.length)))
		{
			var fakeMouseX = FlxG.mouse.x - checkerboard.x;
			mouseCursor.x = (Math.floor((fakeMouseX) / checkerSize) * checkerSize) + checkerboard.x;
			if (FlxG.keys.pressed.SHIFT)
				mouseCursor.y = FlxG.mouse.y;
			else
				mouseCursor.y = Math.floor(FlxG.mouse.y / checkerSize) * checkerSize;

			if (FlxG.mouse.justPressed && curSect >= 0)
			{
				if (!FlxG.mouse.overlaps(renderedNotes))
				{
					// add a note
					var noteStrum = getStrumTime(mouseCursor.y);
					var noteDirection = adjustSide(Math.floor((mouseCursor.x - checkerboard.x) / checkerSize), song.sections[curSect].cameraPoints == 1);
	
					// noteCleanup(notesSection, noteStrum, noteData);
					var note = generateChartNote(noteStrum, noteDirection, false);
					song.sections[curSect].notes.push({timeStep: note.timeStep, direction: note.direction});
	
					// updateSelection(_song.notes[notesSection].sectionNotes[_song.notes[notesSection].sectionNotes.length - 1], notesSection, true);
					// isPlacing = true;
				}
				else
				{
					renderedNotes.forEachAlive(function(note:Note)
					{
						if (FlxG.mouse.overlaps(note))
						{
							if (FlxG.keys.pressed.CONTROL)
							{
								// selectNote(note);
							}
							else
							{
								// delete the epic note
								// var notesSection = getSectionfromY(note.y);
								// persona 3 mass destruction
								// destroySustain(note, notesSection);
	
								// noteCleanup(notesSection, note.strumTime, note.rawNoteData);
	
								note.kill();
								renderedNotes.remove(note);
								song.sections[curSect].notes.remove({timeStep: note.timeStep, direction: note.direction});
								recycledNotes.get(FlxMath.wrap(note.direction, 0, 4)).push(note);
								for (array in recycledNotes)
									array.sort(function(n1:Note, n2:Note) return FlxSort.byValues(FlxSort.ASCENDING, n1.timeStep, n2.timeStep));
								//
							}
						}
					});
				}
			}
		}

		beatText.text = 'STEP: ${curStep} - BEAT: ${curBeat} - SECT: ${curSect}';

		if (songMusic.playing)
			lanesLine.y = getYFromStep(Conductor.songPosition) + (FlxG.height / 2) + lanesLineOffsetY;

		if (FlxG.mouse.wheel != 0) {
			songMusic.pause();
			vocals.pause();

			if ((-FlxG.mouse.wheel < 0 && lanesLine.y >= checkerboard.y + 5) || -FlxG.mouse.wheel > 0) {
				lanesLineOffsetY = -(FlxG.mouse.wheel * (FlxG.keys.pressed.SHIFT ? 40 : 20));
				lanesLine.y += lanesLineOffsetY;
				songMusic.time += lanesLineOffsetY;
				vocals.time = songMusic.time;
			}
		}

		if (FlxG.keys.justPressed.SPACE) {
			if (!songMusic.playing) {
				songMusic.play();
				vocals.play();
			}
			else {
				songMusic.pause();
				vocals.pause();
			}
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S) {
			var data:String = haxe.Json.stringify({"song": song}, '\t');
			Tools.saveData('${songMeta.rawName.toLowerCase()}.json', data);
		}

		if (FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.ESCAPE) {
			FlxG.mouse.visible = false;

			var state:flixel.FlxState = new forever.states.menus.FreeplayState();
			if (FlxG.keys.justPressed.ESCAPE)
				state = new PlayState(songMeta.name, null, song);

			Main.switchState(state);
		}
	}

	function generateBackground():Void {
		var backdrop = new FlxBackdrop(Paths.image("menus/gridPurple"));
		backdrop.alpha = 0.5;
		backdrop.color = FlxColor.PURPLE;
		add(backdrop);

		var gradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [FlxColor.PURPLE, 0xFF350D35]);
		gradient.alpha = 0.4;
		gradient.scrollFactor.set();
		add(gradient);
	}

	function generateCheckerboard():Void {
		var bitmap:openfl.display.BitmapData = FlxGridOverlay.createGrid(checkerSize, checkerSize, checkerSize * 2, checkerSize * 2, true, 0xFFD6D6D6,
			0xFFBBBBBB);

		checkerboard = new FlxTiledSprite(null, checkerSize * 8, checkerSize);
		checkerboard.loadGraphic(bitmap);
		checkerboard.screenCenter(X);
		checkerboard.height = (songMusic.length / Conductor.stepCrochet) * checkerSize;
		add(checkerboard);

		for (i in 1...2) {
			var separator:FlxSprite = new FlxSprite().makeGraphic(5, Std.int(checkerboard.height), FlxColor.BLACK);
			separator.x = checkerboard.x + checkerSize * (4 * i);
			renderedLanes.add(separator);
		}

		// i think this thing should be canned??? it uses FlxTexts which extends FlxSprite so memory goes stonk @Sword352
		// TODO: generate multiple of these and change the Y based on the next beat
		/*for (i in 0...song.sections.length * 4) {
			var sectionLine:FlxText = new FlxText(checkerboard.x + checkerboard.width, 16 * checkerSize * i, 0, '${i + 1}');
			sectionLine.setFormat(Paths.font("vcr"), 32);
			renderedSections.add(sectionLine);
		}*/
	}

	function generateUI():Void {
		beatText = new FlxText(10, FlxG.height - 32).setFormat(Paths.font('vcr'), 22);
		beatText.cameras = [uiCamera];
		add(beatText);

		var testTab = new ForeverTabMenu(800, 30);
		testTab.cameras = [uiCamera];
		add(testTab);

		/*var testButton = new ForeverButton(10, 550, "test");
		testButton.cameras = [uiCamera];
		testButton.onPressedCallback = function() print('Pressed');
		testButton.onReleaseCallback = function() print('Released');
		testButton.onHoverCallback = function() print('Hover');
		testButton.onOutCallback = function() print('Out');
		add(testButton);*/
	}

	private function generateChartNote(strumTime, noteDirection, isSustain):Note
	{
		if (recycledNotes.get(noteDirection) != null && recycledNotes.get(noteDirection).length > 0)
		{
			var note:Note = recycledNotes.get(noteDirection).shift();
			renderedNotes.add(note);
			return note;
		}
		else
			trace('NULL!!!! ${noteDirection}');

		var note:Note = SkinManager.generateArrow(strumTime, noteDirection % 4, "", isSustain);
		// I love how there's 3 different engines that use this exact same variable name lmao
		note.direction = noteDirection;
		// note.sustainLength = daSus;
		note.setGraphicSize(checkerSize, checkerSize);
		note.updateHitbox();
	
		note.screenCenter(X);
		note.x -= ((checkerSize * 2) - (checkerSize / 2));
		note.x += Math.floor(adjustSide(noteDirection, song.sections[curSect].cameraPoints == 1) * checkerSize);
	
		note.y = Math.floor(getYfromStrum(strumTime));
	
		renderedNotes.add(note);
		return note;
		// generateSustain(daStrumTime, daNoteInfo, daSus, daNoteAlt, note);
	}
	
		/*private function generateSustain(daStrumTime:Float = 0, daNoteInfo:Int = 0, daSus:Float = 0, daNoteAlt:Float = 0, note:Note)
		{
			/*
				if (daSus > 0)
				{
					//prevNote = note;
					var constSize = Std.int(checkerSize / 3);
	
					var sustainVis:Note = new Note(daStrumTime + (Conductor.stepCrochet * daSus) + Conductor.stepCrochet, daNoteInfo % 4, daNoteAlt, prevNote, true);
					sustainVis.setGraphicSize(constSize,
						Math.floor(FlxMath.remapToRange((daSus / 2) - constSize, 0, Conductor.stepCrochet * verticalSize, 0, checkerSize * verticalSize)));
					sustainVis.updateHitbox();
					sustainVis.x = note.x + constSize;
					sustainVis.y = note.y + (checkerSize / 2);
	
					var sustainEnd:Note = new Note(daStrumTime + (Conductor.stepCrochet * daSus) + Conductor.stepCrochet, daNoteInfo % 4, daNoteAlt, sustainVis, true);
					sustainEnd.setGraphicSize(constSize, constSize);
					sustainEnd.updateHitbox();
					sustainEnd.x = sustainVis.x;
					sustainEnd.y = note.y + (sustainVis.height) + (checkerSize / 2);
	
					// loll for later
					sustainVis.rawNoteData = daNoteInfo;
					sustainEnd.rawNoteData = daNoteInfo;
	
					curRenderedSustains.add(sustainVis);
					curRenderedSustains.add(sustainEnd);
					//
	
					// set the note at the current note map
					curNoteMap.set(note, [sustainVis, sustainEnd]);
				}
			 
		}*/

	public function loadSong(songName:String) {
		songMusic = new FlxSound().loadEmbedded(Paths.inst(songName), false, true);

		// if (SONG.needsVoices)
		vocals = new FlxSound().loadEmbedded(Paths.voices(songName), false, true);
		// else
		//	vocals = new FlxSound();

		FlxG.sound.list.add(songMusic);
		FlxG.sound.list.add(vocals);
	}

	@:keep inline function getYFromStep(stepTime:Float):Float
		return flixel.math.FlxMath.remapToRange(stepTime, 0, songMusic.length, 0, (songMusic.length / Conductor.stepCrochet) * checkerSize);

	@:keep inline function getYfromStrum(strumTime:Float):Float
		return FlxMath.remapToRange(strumTime, 0, songMusic.length, 0, (songMusic.length / Conductor.stepCrochet) * checkerSize);

	@:keep inline function getStrumTime(yPos:Float):Float
		return FlxMath.remapToRange(yPos, 0, (songMusic.length / Conductor.stepCrochet) * checkerSize, 0, songMusic.length);

	@:keep inline function adjustSide(noteData:Int, sectionTemp:Bool)
		return sectionTemp ? (noteData - 4) % 8 : noteData;
}
