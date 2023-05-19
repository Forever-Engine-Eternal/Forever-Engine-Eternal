package forever.data;

import openfl.display.BitmapData;
import forever.backend.ForeverConsole;
import external.memory.Memory;
import flixel.FlxG;
import flixel.util.FlxStringUtil;
import haxe.Timer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;

/* import flixel.math.FlxMath;
import forever.music.Conductor; */

class FPSOverlay extends Sprite {
	public var fpsBG:Sprite;
	public var info:FPS;

	public function new(x:Float = 10, y:Float = 10):Void {
		super();

		fpsBG = new Sprite();
		fpsBG.graphics.beginFill(0);
		fpsBG.graphics.drawRect(0, 0, 1, 50);
		fpsBG.graphics.endFill();
		fpsBG.visible = false;
		fpsBG.alpha = 0.5;
		addChild(fpsBG);

		info = new FPS(x, y);
		addChild(info);

		addEventListener(Event.ENTER_FRAME, function(_:Event):Void {
			fpsBG.scaleX = info.x + info.width + 5;
			fpsBG.height = info.height + 10;
			visible = info.visible;
		});

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):Void {
			switch (e.keyCode) {
				case Keyboard.F3:
					fpsBG.visible = !fpsBG.visible;
					FlxG.save.data.fpsBoxShown = fpsBG.visible;
					FlxG.save.flush();
				case Keyboard.F4:
					info.showDebugInfo = !info.showDebugInfo;
					FlxG.save.data.fpsShowDebugInfo = info.showDebugInfo;
					FlxG.save.flush();
				case Keyboard.F6:
					ForeverConsole.consoleVisible = !ForeverConsole.consoleVisible;
					ForeverConsole.print("ugh!", flixel.util.FlxColor.RED);
				case Keyboard.F7:
					ForeverConsole.clear();
				case Keyboard.F11:
					FlxG.fullscreen = !FlxG.fullscreen;
					Init.saveSettings();
			}
		});
	}

	public function loadSettings()
	{
		fpsBG.visible = FlxG.save.data.fpsBoxShown;
		info.showDebugInfo = FlxG.save.data.fpsShowDebugInfo;
	}
}

/**
	Overlay that displays FPS and memory usage.

	Based on this tutorial:
	https://keyreal-code.github.io/haxecoder-tutorials/17_displaying_fps_and_memory_usage_using_openfl.html
**/
class FPS extends TextField {
	public var showDebugInfo:Bool = false;

	var times:Array<Float> = [];
	var memPeak:Float = 0;

	public function new(x:Float, y:Float) {
		super();

		this.x = x;
		this.y = x;

		autoSize = LEFT;
		selectable = false;

		defaultTextFormat = new TextFormat(Paths.font('dm-sans'), 14, 0xFFFFFF);
		text = "";

		var debugData = Main.gameVersions["debug"].toString();

		addEventListener(Event.ENTER_FRAME, function(_:Event) {
			var now:Float = Timer.stamp();
			times.push(now);
			while (times[0] < now - 1)
				times.shift();

			var trueFPS:Int = times.length;
			if (!Init.trueSettings.get('Accurate Fps') && times.length > Init.trueSettings.get('Framerate Cap'))
				trueFPS = Init.trueSettings.get('Framerate Cap');

			var mem:Float = Init.trueSettings.get('Accurate Memory') ? Memory.getCurrentUsage() : System.totalMemory;

			if (!Init.trueSettings.get('Accurate Memory') && mem > memPeak)
				memPeak = mem;
			else if (Init.trueSettings.get('Accurate Memory'))
				memPeak = Memory.getPeakUsage();

			text = "";
			if (Init.trueSettings.get("FPS Counter"))
				text += '${trueFPS} FPS\n';
			if (Init.trueSettings.get("Memory Counter"))
				text += '${FlxStringUtil.formatBytes(mem)} / ${FlxStringUtil.formatBytes(memPeak)}\n';
			if (showDebugInfo)
			{
				// text += '\nConductor info:\nSong Position: ${Conductor.songPosition}';
				text += '\nObjects:\nAlive: ${FlxG.state.members.length}\nDead: ${([for (i in FlxG.state.members) if (i != null && !i.exists) i]).length}\n';
				text += '\nForever Engine: Eternal\n${debugData}';
			}	
			
			visible = text.length > 0;
		});
	}
}
