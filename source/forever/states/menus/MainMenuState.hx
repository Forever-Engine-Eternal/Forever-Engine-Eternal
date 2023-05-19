package forever.states.menus;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import forever.backend.LevelData;
import forever.music.MusicBeat.MusicBeatState;
import sys.FileSystem;

/**
	This is the main menu state! Not a lot is going to change about it so it'll remain similar to the original, but I do want to condense some code and such.
	Get as expressive as you can with this, create your own menu!
**/
class MainMenuState extends MusicBeatState {
	var menuItems:FlxTypedGroup<FlxSprite>;
	var curSelected:Int = 0;

	var bg:FlxSprite; // the background has been separated for more control
	var magenta:FlxSprite;
	var camFollow:FlxObject;

	var optionShit:Array<String> = ['story mode', 'freeplay', 'credits', 'options'];

	override function create() {
		super.create();
		// set the transitions to the previously set ones
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		LevelData.loadLevels();

		// make sure the music is playing
		Tools.resetMenuMusic();

		Discord.changePresence('MAIN MENU', 'In Menus');

		// uh
		persistentUpdate = persistentDraw = true;

		var scrollY = 0.18 / optionShit.length;

		// background
		bg = new FlxSprite(-85);
		bg.loadGraphic(Paths.image('menus/menuBG'));
		bg.scrollFactor.set(0, scrollY);
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		magenta = new FlxSprite(-85).loadGraphic(Paths.image('menus/menuDesat'));
		magenta.scrollFactor.set(0, scrollY);
		magenta.setGraphicSize(Std.int(magenta.width * 1.1));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = true;
		magenta.color = 0xFFfd719b;
		add(magenta);

		// add the camera
		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		// add the menu items
		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		// loop through the menu options
		for (i in 0...optionShit.length) {
			var menuItem:FlxSprite = new FlxSprite(0, 15 + (i * 175));
			menuItem.frames = Paths.getSparrowAtlas('menus/mainmenu/${optionShit[i]}');
			// add the animations
			menuItem.animation.addByPrefix('idle', "basic", 24);
			menuItem.animation.addByPrefix('selected', "white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;

			// placements
			menuItem.screenCenter(X);
			// if the id is divisible by 2
			if (menuItem.ID % 2 == 0)
				menuItem.x += 1000;
			else
				menuItem.x -= 1000;

			// actually add the item
			menuItems.add(menuItem);
			menuItem.scrollFactor.set();
			menuItem.antialiasing = true;
			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollow, null, Tools.boundFPS(0.10));

		changeSelection();

		makeWatermark('Friday Night Funkin\' v${Main.gameVersions["funkin"].toString(true)}', FlxG.height - 18);
		makeWatermark('Forever Eternal v${Main.gameVersions["normal"].toString()}', FlxG.height - 36);

		var debugWatermark = makeWatermark(Main.gameVersions["debug"].toString(), FlxG.height - 18);
		debugWatermark.x = FlxG.width - debugWatermark.width;

		var mouseHandler = new forever.data.inputs.MouseHandler();
		mouseHandler.onWheelScroll = changeSelection;

		/*var test = new forever.ui.AchievementPopup("testing");
		test.scrollFactor.set();
		add(test);*/
	}

	function makeWatermark(text:String, y:Float):FlxText
	{
		var versionShit:FlxText = new FlxText(5, y, 0, text, 12);
		versionShit.setFormat(Paths.font("vcr"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionShit.scrollFactor.set();
		add(versionShit);
		return versionShit;
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float) {		
		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		if (FlxG.keys.justPressed.SEVEN) {
			persistentUpdate = false;
			camFollow.screenCenter();
			openSubState(new forever.states.subStates.EditorSubstate());
		}

		if (controls.anyJustPressed(["down", "up"]) && !selectedSomethin)
			changeSelection(controls.justPressed("up") ? -1 : 1);

		if ((controls.justPressed("accept")) && (!selectedSomethin)) {
			selectedSomethin = true;
			FlxG.sound.play(Paths.sound('confirmMenu'));

			if (!Init.trueSettings.get("Disable Flashing Lights"))
				FlxFlicker.flicker(magenta, 0.8, 0.1, false);

			menuItems.forEach(function(spr:FlxSprite) {
				if (curSelected != spr.ID) {
					FlxTween.tween(spr, {alpha: 0, x: FlxG.width * 2}, 0.4, {
						ease: FlxEase.quadOut,
						onComplete: function(twn:FlxTween) {
							spr.kill();
						}
					});
				}
				else {
					FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker) {
						var daChoice:String = optionShit[curSelected];

						switch (daChoice) {
							case 'story mode':
								if (LevelData.gameWeeks.length < 1)
									return FlxG.resetState();
								Main.switchState(new StoryMenuState());
							case 'freeplay': Main.switchState(new FreeplayState());
							case 'credits': Main.switchState(new CreditsState());
							case 'options':
								transIn = FlxTransitionableState.defaultTransIn;
								transOut = FlxTransitionableState.defaultTransOut;
								Main.switchState(new forever.settings.OptionsState());
						}
					});
				}
			});
		}

		super.update(elapsed);
		
		menuItems.forEach(function(menuItem:FlxSprite) {
			menuItem.screenCenter(X);
		});
	}


	private function changeSelection(change:Int = 0) {
		if (change != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		curSelected = flixel.math.FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);

		// reset all selections
		menuItems.forEach(function(spr:FlxSprite) {
			spr.animation.play('idle');
			spr.updateHitbox();
		});

		// set the sprites and all of the current selection
		camFollow.setPosition(menuItems.members[curSelected].getGraphicMidpoint().x, menuItems.members[curSelected].getGraphicMidpoint().y);

		if (menuItems.members[curSelected].animation.curAnim.name == 'idle')
			menuItems.members[curSelected].animation.play('selected');

		menuItems.members[curSelected].updateHitbox();
	}

	override function closeSubState() {
		super.closeSubState();
		changeSelection();
	}
}
