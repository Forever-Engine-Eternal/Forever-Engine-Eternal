package forever;

import flixel.util.FlxColor;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;
import flixel.util.FlxSave;
import flixel.util.FlxTimer;
import forever.music.Conductor;
import forever.states.TitleState;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
#if sys
import sys.FileSystem;
#end

typedef SpriteAnimation = {
	var name:String;
	var ?prefix:String;
	var ?frames:Array<Int>;
	var ?indices:Array<Int>;
	var ?loop:Bool;
	var ?fps:Null<Int>;

	var ?offset:Array<Null<Float>>;
}

class Tools {
	public static final EternalGithubRepoURL:String = "https://github.com/BeastlyGabi/Forever-Engine-Eternal";
	public static final invisibleAlpha:Float = 0.000000001;

	/**
	 * Sets the volume keys to new ones, each parameter is optional, as setting them to null results in the default keys
	 * 
	 * @param keysUp        the Volume UP (+) Keys, e.g [FlxKey.NUMPADPLUS, FlxKey.PLUS]
	 * @param keysDown      the Volume DOWN (-) Keys, e.g [FlxKey.NUMPADMINUS, FlxKey.MINUS]
	 * @param keysMute      the Volume MUTE (silent) Keys, e.g [FlxKey.NUMPADZERO, FlxKey.ZERO]
	**/
	@:keep public static inline function setVolKeys(?keysUp:Array<FlxKey>, ?keysDown:Array<FlxKey>, ?keysMute:Array<FlxKey>):Void {
		if (keysUp == null)
			keysUp = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
		if (keysDown == null)
			keysDown = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
		if (keysMute == null)
			keysMute = [FlxKey.NUMPADZERO, FlxKey.ZERO];

		FlxG.sound.muteKeys = keysMute;
		FlxG.sound.volumeDownKeys = keysDown;
		FlxG.sound.volumeUpKeys = keysUp;
	}

	/**
	 * Centers the specified object to the bounds of another object
	 *
	 * USAGE:
	 * ```haxe
	 * var myOverlay:FlxSprite = new FlxSprite(0, 150).makeGraphic(300, 500, 0xFF000000);
	 * myOverlay.screenCenter(X);
	 * add(myOverlay);
	 *
	 * var myObject:FlxObject = new FlxObject(0, 0, 1, 1);
	 * myObject.centerOverlay(myOverlay, X);
	 * add(myObject);
	 * ```
	 *
	 * @author SwickTheGreat
	 *
	 * @param object         the child object that should be centered
	 * @param base           the base object, used for the center calculations
	 * @param axes           in which axes should the child object be centered? (default: XY)
	 * @return               child object, now centered according to the base object
	 */
	@:keep public static inline function centerOverlay(object:FlxObject, base:FlxObject, axes:FlxAxes = XY):FlxObject {
		if (object == null || base == null)
			return object;
		if (axes.x)
			object.x = base.x + (base.width / 2) - (object.width / 2);
		if (axes.y)
			object.y = base.y + (base.height / 2) - (object.height / 2);
		return object;
	}

	/**
	 * Adds an object behind the specified group
	 *
	 * USAGE:
	 * ```haxe
	 * // this will add the object to the beginning position of the current state
	 * var exampleObject:FlxObject = new FlxObject(0, 0, 1, 1)
	 * exampleObject.addToPos(FlxG.state, 0);
	 * ```
	 *
	 * @param group              the group in which the object should get added
	 * @param index              the position of the object
	 */
	@:keep public static inline function addToPos(object:FlxBasic, group:FlxGroup, index:Int):FlxBasic {
		group.insert(index, object);
		return object;
	}

	/**
	 * Helper Function to check if an Object is out of range
	 * 
	 * USAGE:
	 * ```haxe
	 * var myObject:FlxObject = new FlxObject(0, 0, 1, 1);
	 * print('is myObject out of range? - ' + myObject.outOfRange()); // true or false
	 * ```
	 */
	@:keep public static inline function outOfRange(object:FlxObject):Bool {
		if (object.y > FlxG.height || object.y < -object.height)
			return true;
		return false;
	}

	/**
	 * Launches the user's Web Browser with the specified URL
	 * @param url          the URL to open
	 */
	@:keep public static inline function openURL(url:String):Void {
		#if linux
		Sys.command('/usr/bin/xdg-open', [url]);
		#else
		FlxG.openURL(url);
		#end
	}

	@:keep public static inline function dashToSpace(string:String):String
		return string.replace("-", " ");

	@:keep public static inline function spaceToDash(string:String):String
		return string.replace(" ", "-");

	@:keep public static inline function swapSpaceDash(string:String):String
		return string.contains('-') ? dashToSpace(string) : spaceToDash(string);

	@:keep public static inline function coolTextFile(path:String):Array<String> {
		var list:String;
		return [
			for (i in Assets.getText(path).split("\n"))
				if ((list = i.trim()) != "" && !list.startsWith("#")) list
		];
	}

	@:keep public static inline function getOffsetsFromTxt(path:String):Array<Array<String>> {
		var fullText:String = Assets.getText(path);
		var firstArray:Array<String> = fullText.split('\n');
		var swagOffsets:Array<Array<String>> = [];

		for (i in firstArray)
			swagOffsets.push(i.split(' '));

		return swagOffsets;
	}

	@:keep public static inline function returnAssetsLibrary(library:String, ?subDir:String = 'assets/images'):Array<String> {
		var libraryArray:Array<String> = [];
		var unfilteredLibrary = FileSystem.readDirectory('${subDir}/${library}');
		for (folder in unfilteredLibrary)
			if (!folder.contains('.'))
				libraryArray.push(folder);
		return libraryArray;
	}

	@:keep public static inline function getAnimsFromTxt(path:String):Array<Array<String>> {
		var fullText:String = Assets.getText(path);
		var firstArray:Array<String> = fullText.split('\n');
		var swagOffsets:Array<Array<String>> = [];

		for (i in firstArray)
			swagOffsets.push(i.split('--'));
		return swagOffsets;
	}

	/*
		TODO: find a way to do a reference to the variable referenced in the oldAmount argument
		instead of copying the value of the variable referenced in the oldAmount argument
		@Sword352
	 */
	/*@:keep public static function fixedLerp(a:Float, b:Float, ratio:Float, limit:Float, oldAmount:Float):Float
		{
			a = FlxMath.lerp(a, b, ratio);
			if (oldAmount == a && a != limit)
				a >= limit ? a-- : a++;
			oldAmount = a;
			return a;
	}*/
	
	@:keep public static inline function numberArray(max:Int, ?min = 0):Array<Int>
		return [for (i in min...max) i];

	@:keep public static inline function boundFPS(input:Float) @:privateAccess return input * (60 / Main.infoCounter.info.times.length);

	@:keep public static inline function setSubstateCameras(substate:flixel.FlxSubState)
		substate.cameras = [flixel.FlxG.cameras.list[flixel.FlxG.cameras.list.length - 1]];

	// set up maps and stuffs
	@:keep public static inline function resetMenuMusic(?music:String, ?library:String, ?bpm:Int = 102, resetVolume:Bool = false) {
		// make sure the music is playing
		if (music == null)
			music = TitleState.titleData.musicFile;
		if (library == null)
			library = TitleState.titleData.musicFolder;

		if (((FlxG.sound.music != null) && (!FlxG.sound.music.playing)) || (FlxG.sound.music == null)) {
			FlxG.sound.playMusic(Paths.music(music, library), (resetVolume) ? 0 : 0.7);
			if (resetVolume)
				FlxG.sound.music.fadeIn(4, 0, 0.7);
			Conductor.changeBPM(bpm);
		}
		//
	}

	@:keep public static inline function returnSkinAsset(asset:String, assetModifier:String = 'base', changeableSkin:String = 'default', baseLibrary:String,
			?defaultChangeableSkin:String = 'default', ?defaultBaseAsset:String = 'base'):String {
		var realAsset = '${baseLibrary}/${changeableSkin}/${assetModifier}/${asset}';
		if (!FileSystem.exists(Paths.getPath('images/${realAsset}', IMAGE))) {
			realAsset = '${baseLibrary}/${defaultChangeableSkin}/${assetModifier}/${asset}';
			if (!FileSystem.exists(Paths.getPath('images/${realAsset}', IMAGE)))
				realAsset = '${baseLibrary}/${defaultChangeableSkin}/${defaultBaseAsset}/${asset}';
		}

		return realAsset;
	}

	@:keep public static inline function getUIAsset(asset:String, skin:String = 'base', folder:String = 'images', type:Paths.AssetType = IMAGE):Dynamic {
		var realAsset:Dynamic = null;

		switch (type) {
			case IMAGE:
				realAsset = Paths.image('${folder}/${skin}/${asset}', true);
				if (!FileSystem.exists(Paths.getPath('${folder}/${skin}/${asset}', IMAGE)))
					realAsset = Paths.image('${folder}/base/${asset}', true);
			case SOUND:
				realAsset = Paths.sound('${folder}/${skin}/${asset}', true);
				if (!FileSystem.exists(Paths.getPath('${folder}/${skin}/${asset}', SOUND)))
					realAsset = Paths.sound('${folder}/base/${asset}', true);
			default:
				realAsset = Paths.getPath('${folder}/${skin}/${asset}', type);
				if (!FileSystem.exists(Paths.getPath('${folder}/${skin}/${asset}', type)))
					realAsset = Paths.getPath('${folder}/base/${asset}', type);
		}

		return realAsset;
	}

	@:keep public static inline function killMusic(songsArray:Array<FlxSound>) {
		// neat function thing for songs
		for (i in 0...songsArray.length) {
			// stop
			songsArray[i].stop();
			songsArray[i].destroy();
		}
	}

	@:keep public static inline function invokeTempSave(funcToDo:FlxSave->Void, name:String, ?folder:String = "Sword352/FE-Eternal"):Void {
		var tmpSav:FlxSave = new FlxSave();
		tmpSav.bind(name, folder);
		// run save function
		funcToDo(tmpSav);
		// close the save file (saves content and destroys it, saving on memory)
		tmpSav.close();
	}

	@:keep public static inline function parseXMLColor(color:String):FlxColor {
		if (color.contains(",")) {
			var colorArray:Array<Int> = [for (i in color.split(",")) Std.parseInt(i)];
			return FlxColor.fromRGB(colorArray[0], colorArray[1], colorArray[2]);
		}

		return FlxColor.fromString(color);
	}

	static var _file:FileReference;

	@:keep public static inline function saveData(fileName:String, data:String):Void {
		if ((data != null) && (data.length > 0)) {
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), '${fileName}');
		}
	}

	@:keep static inline function onSaveComplete(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Data saved.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	@:keep static inline function onSaveCancel(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the given data.
	 */
	@:keep static inline function onSaveError(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("An error occurred while saving data");
	}

	@:keep public static inline function pauseEveryTween():Void
		FlxTween.globalManager.forEach(function(twn:FlxTween) twn.active = false);

	@:keep public static inline function pauseEveryTimer():Void
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) tmr.active = false);

	@:keep public static inline function resumeEveryTween():Void
		FlxTween.globalManager.forEach(function(twn:FlxTween) twn.active = true);

	@:keep public static inline function resumeEveryTimer():Void
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) tmr.active = true);
}
