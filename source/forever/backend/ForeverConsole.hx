package forever.backend;

import openfl.events.Event;
import flixel.util.FlxColor;
import openfl.display.Bitmap;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.FlxG;
import openfl.display.Sprite;

using StringTools;

class ForeverConsole extends Sprite
{
    public static var consoleVisible(default, set):Bool;
    static var _INSTANCE:ForeverConsole;
    static var currentLogs:Array<TextField> = [];
    static var currentBoxes:Array<Bitmap> = [];

    public function new()
    {
        super();
        _INSTANCE = this;
        consoleVisible = false;

        var eternalText = new TextField();
        eternalText.autoSize = LEFT;
        eternalText.selectable = false;
        eternalText.textColor = 0xFFFFFFFF;
        eternalText.text = 'Forever Engine: Eternal\nVersion: ${Main.gameVersions["normal"].toString()}';
        eternalText.sharpness = 100;
        addChild(eternalText);

        var eternalFormat = new TextFormat("Pixel Arial 11 Bold", 16);
        eternalFormat.align = CENTER;
        eternalText.defaultTextFormat = eternalFormat;

        addEventListener(Event.ENTER_FRAME, function(_) {
            graphics.clear();
            graphics.beginFill(0x000000, consoleVisible ? 0.5 : 0);
            graphics.drawRect(0, 0, lime.app.Application.current.window.width, lime.app.Application.current.window.height);
            graphics.endFill();

            eternalText.x = (lime.app.Application.current.window.width - eternalText.width) / 2;

            for (text in currentLogs)
                text.x = (lime.app.Application.current.window.width - text.width) / 50;

            for (box in currentBoxes)
                box.width = FlxG.game.width;
        });
    }

    public function addText(textToWrite:String, color:FlxColor)
    {
        var text = new TextField();
        text.text = textToWrite;
        text.defaultTextFormat = new TextFormat("Pixel Arial 11 Bold", 10);
        if (currentLogs[currentLogs.length - 1] != null)
            text.y = currentLogs[currentLogs.length - 1].y + 15;
        else
            text.y = 0;

        text.selectable = false;

        addChild(text);
        currentLogs.push(text);

        var box = new Bitmap(FlxG.bitmap.create(FlxG.width, 25, color).bitmap);
        box.alpha = 0.5;
        box.y = text.y + 2;
        box.scaleX = box.scaleY = text.scaleX;
        addChild(box);
        currentBoxes.push(box);
    }

    public static function print(text:String, color:FlxColor)
    {
        _INSTANCE.addText(text, color);
    }

    public static function clear()
    {
        for (i in currentLogs)
        {
            _INSTANCE.removeChild(i);
            i = null;
        }

        for (i in currentBoxes)
        {
            _INSTANCE.removeChild(i);
            i = null;
        }

        currentLogs = [];
        currentBoxes = [];
    }

    static function set_consoleVisible(value:Bool):Bool return consoleVisible = _INSTANCE.visible = value;
}