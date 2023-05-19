package forever.states;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxSprite;

/**
 * Preloading state to preload assets using a thread.
 * @author Sword352, base caching by BeastlyGhost
 */
class PreloadState extends forever.music.MusicBeat.MusicBeatState
{
    // map for preloading assets and saving them to the dump exclusions
	static var preloadList:haxe.ds.StringMap<String> = [
		// add here assets that will be cached when the game loads
		"alphabet" => Paths.getPath("images/UI/base/alphabet", IMAGE),
		"freakyMenu" => Paths.getPath('music/freakyMenu', SOUND),
		"foreverMenu" => Paths.getPath('music/foreverMenu', SOUND),
		"breakfast" => Paths.getPath('music/breakfast', SOUND),
		"BOYFRIEND" => Paths.getPath('characters/bf/BOYFRIEND', IMAGE), // he's in like 90% of mods so whatever
        "menuBG" => Paths.getPath("images/menus/menuBG", IMAGE),
        "menuBGBlue" => Paths.getPath("images/menus/menuBGBlue", IMAGE),
        "menuBGMagenta" => Paths.getPath("images/menus/menuBGMagenta", IMAGE),
        "menuDesat" => Paths.getPath("images/menus/menuDesat", IMAGE),
	];

    var maxCount:Int = Lambda.count(preloadList);
    var curCount:Int = 0;

    var loadingText:FlxText;
    var moon:FlxSprite;

    override function create()
    {
        Paths.gcEnable();

        super.create();

        var backdrop = new flixel.addons.display.FlxBackdrop(Paths.image("menus/gridPurple"));
        backdrop.color = FlxColor.BLUE;
        backdrop.moves = true;
        backdrop.velocity.set(-50, 25);
        add(backdrop);

        var overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLUE);
        overlay.alpha = 0.4;
        add(overlay);
        
        moon = new FlxSprite().loadGraphic(Paths.image("menus/eternal-moon"));
        moon.scale.set(0.75, 0.75);
        moon.updateHitbox();
        moon.screenCenter();
        moon.antialiasing = true;
        add(moon);

        loadingText = new FlxText().setFormat(Paths.font('vcr'), 52);
        loadingText.screenCenter(X).y = FlxG.height - loadingText.height - 200;
        add(loadingText);

        for (assetKey in preloadList.keys())
            new openfl.utils.Future(() -> cache(assetKey));
    }

    var isTransitioning:Bool = false;

    override function update(elapsed:Float)
    {
        moon.alpha = curCount / maxCount;
        loadingText.text = 'Loading...      ${curCount}/${maxCount}';
        loadingText.screenCenter(X);

        if (isTransitioning) return;

        if (curCount == maxCount)
        {
            isTransitioning = true;
            Main.switchState(new TitleState());
            return;
        }

        super.update(elapsed);
    }

    // here we preload assets that are on the asset queue
    private function cache(key:String)
    {
        var asset = preloadList.get(key);

        if (asset != null)
        {
            // preloading the asset
            print('preloading ${key}', DEBUG);
			Paths.excludeAsset(asset);

			for (j in Paths.getExtensionsFor(IMAGE))
				if (asset.endsWith(j))
					Paths.returnGraphic(asset.split("/")[1], true); // little workaround for images loading ig @Sword352

			for (j in Paths.getExtensionsFor(SOUND))
				if (asset.endsWith(j))
					Paths.returnSound(asset, true);

            preloadList.remove(asset);
            curCount++;
        }
    }
}