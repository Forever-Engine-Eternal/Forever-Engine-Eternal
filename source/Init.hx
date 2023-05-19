package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;
import forever.Tools;
import forever.data.Controls;
import forever.data.Highscore;
import openfl.filters.BitmapFilter;
import openfl.filters.ColorMatrixFilter;

using StringTools;

/**
	This is the initialisation class. if you ever want to set anything before the game starts or call anything then this is probably your best bet.
	A lot of this code is just going to be similar to the flixel templates' colorblind filters because I wanted to add support for those as I'll
	most likely need them for skater, and I think it'd be neat if more mods were more accessible.
**/
class Init extends FlxState {
	// "Setting Name" => [settingValue, settingDescription, [settingOptions]]
	// setting type is decided by it's value
	// if the settingValue is an int and your option need limits, set [settingOptions] as [optionIntLimit, optionIntMax]
	public static var gameSettings:Map<String, Array<Dynamic>> = [
		// GAMEPLAY
		'Downscroll' => [false, 'Whether to have the strumline vertically flipped in gameplay.'],
		'Ghost Tapping' => [false, "Enables Ghost Tapping, allowing you to press inputs without missing."],
		'Centered Notefield' => [false, "Center the notes, disables the enemy's notes."],
		'Offset' => [0, "Define the offset for your notes."],
		// TEXT
		'Counter' => [
			'None',
			'Choose whether you want somewhere to display your judgements, and where you want it.',
			['None', 'Left', 'Right']
		],
		'Display Accuracy' => [true, 'Whether to display your accuracy on screen.'],
		'Skip Text' => [
			'freeplay only',
			'Decides whether to skip cutscenes and dialogue in gameplay. May be always, only in freeplay, or never.',
			['never', 'freeplay only', 'always']
		],
		'Song Timer' => [true, 'Decides whether to show a timer in gameplay.'],
		'End Screen' => [
			true,
			'Whether a end screen should show up when you beat a song in Freeplay Mode.'
		],
		// CUSTOMIZATION
		"Note Skin" => ['default', 'Choose a note skin.'],
		'Disable Note Splashes' => [
			false,
			'Whether to disable note splashes in gameplay. Useful if you find them distracting.'
		],
		"Opaque Arrows" => [false, "Makes the arrows at the top of the screen opaque again."],
		"Opaque Holds" => [false, "Huh, why isnt the trail cut off?"],
		'Fixed Judgements' => [
			false,
			"Fixes the judgements to the camera instead of to the world itself, making them easier to read."
		],
		'Simply Judgements' => [
			false,
			"Simplifies the judgement animations, displaying only one judgement / rating sprite at a time."
		],
		'Stage Opacity' => [100, 'Darkens non-ui elements, useful if you find the characters and stages distracting.', [0, 100]],
		// ACCESSIBILITY
		'Auto Pause' => [true, 'Whether to pause the game automatically if the window is unfocused.'],
		'FPS Counter' => [true, 'Whether to display the FPS counter.'],
		'Memory Counter' => [true, 'Whether to display approximately how much memory is being used.'],
		'Reduced Movements' => [
			false,
			'Whether to reduce movements, like icons bouncing or beat zooms in gameplay.'
		],
		'Disable Camera Panning' => [false, 'When enabled, hitting notes will no longer move the camera.'],
		'Disable Flashing Lights' => [false, 'Whether to display flashing lights on menus and during gameplay.'],
		'Disable Antialiasing' => [false, 'Whether to disable Anti-aliasing. Helps improve performance in FPS.'],
		'Disable Reset Button' => [true, 'Whether to prevent the RESET (R) button from killing the player.'],
		'Filter' => [
			'none',
			'Choose a filter for colorblindness.',
			['none', 'Deuteranopia', 'Protanopia', 'Tritanopia']
		],
		'GPU Rendering' => [false, 'Wheter to use the GPU instead of the CPU to render images.'],
		"Framerate Cap" => [60, 'Define your maximum FPS.', [30, 360]],
		"Accurate Fps" => [false, "If checked, shows accurate framerate on the fps counter."],
		"Accurate Memory" => [false, "If checked, shows accurate memory on the fps counter."],
	];

	public static var trueSettings:Map<String, Dynamic> = [];

	public static var gameControls:Map<String, Array<Dynamic>> = [
		'LEFT' => [[FlxKey.LEFT, A], 0],
		'DOWN' => [[FlxKey.DOWN, S], 1],
		'UP' => [[FlxKey.UP, W], 2],
		'RIGHT' => [[FlxKey.RIGHT, D], 3],
		//
		'ACCEPT' => [[FlxKey.SPACE, Z, FlxKey.ENTER], 5],
		'BACK' => [[FlxKey.BACKSPACE, X, FlxKey.ESCAPE], 6],
		'PAUSE' => [[FlxKey.ENTER, P], 7],
		'RESET' => [[FlxKey.R, FlxKey.NONE], 8],
	];

	public static var filters:Array<BitmapFilter> = []; // the filters the game has active
	/// initalise filters here
	public static var gameFilters:Map<String, {filter:BitmapFilter, ?onUpdate:Void->Void}> = [
		"Deuteranopia" => {
			var matrix:Array<Float> = [
				0.43, 0.72, -.15, 0, 0,
				0.34, 0.57, 0.09, 0, 0,
				-.02, 0.03,    1, 0, 0,
				   0,    0,    0, 1, 0,
			];
			{filter: new ColorMatrixFilter(matrix)}
		},
		"Protanopia" => {
			var matrix:Array<Float> = [
				0.20, 0.99, -.19, 0, 0,
				0.16, 0.79, 0.04, 0, 0,
				0.01, -.01,    1, 0, 0,
				   0,    0,    0, 1, 0,
			];
			{filter: new ColorMatrixFilter(matrix)}
		},
		"Tritanopia" => {
			var matrix:Array<Float> = [
				0.97, 0.11, -.08, 0, 0,
				0.02, 0.82, 0.16, 0, 0,
				0.06, 0.88, 0.18, 0, 0,
				   0,    0,    0, 1, 0,
			];
			{filter: new ColorMatrixFilter(matrix)}
		}
	];

	override public function create():Void {
		FlxG.save.bind("settings", "Sword352/FE-Eternal");

		forever.backend.Logs.init();
		forever.backend.Achievements.init();
		forever.shaders.ShaderCoordsFix.init();
		Controls.current = new Controls();

		Highscore.load();
		loadControls();
		loadSettings();
		Main.infoCounter.loadSettings();

		// apply saved filters
		FlxG.game.setFilters(filters);

		// Some additional changes to default HaxeFlixel settings, both for ease of debugging and usability.
		FlxG.game.focusLostFramerate = 60; // This set the focus lost framerate to 60 to avoid capped-fps bugs
		FlxG.fixedTimestep = false; // This ensures that the game is not tied to the FPS
		FlxG.mouse.useSystemCursor = true; // Use system cursor because it's prettier
		FlxG.mouse.visible = false; // Hide mouse on start

		Main.switchState(new forever.states.PreloadState());
	}

	@:keep public static inline function loadSettings():Void {
		// IF YOU WANT TO SAVE MORE THAN ONE VALUE MAKE YOUR VALUE AN ARRAY INSTEAD
		for (setting in gameSettings.keys())
			trueSettings.set(setting, gameSettings.get(setting)[0]);

		// NEW SYSTEM, INSTEAD OF REPLACING THE WHOLE THING I REPLACE EXISTING KEYS
		// THAT WAY IT DOESNT HAVE TO BE DELETED IF THERE ARE SETTINGS CHANGES
		if (FlxG.save.data.settings != null) {
			var settingsMap:Map<String, Dynamic> = FlxG.save.data.settings;
			for (singularSetting in settingsMap.keys())
				if (gameSettings.get(singularSetting) != null)
					trueSettings.set(singularSetting, FlxG.save.data.settings.get(singularSetting));
		}

		// lemme fix that for you
		for (setting in gameSettings.keys())
		{
			if (Std.isOfType(gameSettings.get(setting)[0], Int))
			{
				if (gameSettings.get(setting)[2] != null && gameSettings.get(setting)[2][0] != null && gameSettings.get(setting)[2][1] != null)
					resetOutOfBounds(setting, gameSettings.get(setting)[0], gameSettings.get(setting)[2][0], gameSettings.get(setting)[2][1]);
			}
		}

		gameSettings.get("Note Skin")[2] = Tools.returnAssetsLibrary('noteskins/notes');
		if (!gameSettings.get("Note Skin")[2].contains(trueSettings.get("Note Skin")))
			trueSettings.set("Note Skin", 'default');

		if (FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;
		if (FlxG.save.data.fullscreen != null)
			FlxG.fullscreen = FlxG.save.data.fullscreen;

		updateAll();
	}

	private static function resetOutOfBounds(setting:String, toValue:Int, min:Int = 0, max:Int = 100):Void {
		if (!Std.isOfType(Init.trueSettings.get(setting)[0], Int)
			|| Init.trueSettings.get(setting)[0] < min
			|| Init.trueSettings.get(setting)[1] > min)
			Init.trueSettings.get(setting)[0] = toValue;
	}

	@:keep public static inline function loadControls():Void {
		Tools.invokeTempSave(function(ctrl:FlxSave) {
			if ((ctrl.data.gameControls != null) && (Lambda.count(ctrl.data.gameControls) == Lambda.count(gameControls)))
				gameControls = ctrl.data.gameControls;
		}, "controls");
		Controls.refreshKeys();
		saveControls();
	}

	@:keep public static inline function saveSettings():Void {
		// ez save lol
		FlxG.save.data.settings = trueSettings;
		FlxG.save.data.volume = FlxG.sound.volume;
		FlxG.save.data.mute = FlxG.sound.muted;
		FlxG.save.data.fullscreen = FlxG.fullscreen;
		FlxG.save.flush();
		updateAll();
	}

	@:keep public static inline function saveControls():Void
		Tools.invokeTempSave(function(ctrl:FlxSave) ctrl.data.gameControls = gameControls, "controls");

	@:keep public static inline function updateAll() {
		FlxG.autoPause = trueSettings.get('Auto Pause');
		Main.updateFramerate(trueSettings.get("Framerate Cap"));
		flixel.FlxSprite.defaultAntialiasing = !Init.trueSettings.get('Disable Antialiasing');

		reloadColorblindFilters();
	}

	@:keep public static inline function reloadColorblindFilters() {
		filters = [];
		FlxG.game.setFilters(filters);

		var theFilter:String = trueSettings.get('Filter');
		if (gameFilters.get(theFilter) != null)
			if (gameFilters.get(theFilter).filter != null)
				filters.push(gameFilters.get(theFilter).filter);
		FlxG.game.setFilters(filters);
	}
}
