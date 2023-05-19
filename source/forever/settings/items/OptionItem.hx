package forever.settings.items;

import flixel.util.FlxColor;
import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import forever.data.Controls;
import flixel.math.FlxMath;
import flixel.FlxG;

enum OptionItemType
{
    Bool;
    Int;
    Selection;
    Undefined;
}

/**
 * This is the OptionItem class, the text in options to modify the settings.
 * @author Sword352
 */
class OptionItem extends flixel.text.FlxText
{
    public var targetY:Float = 0;
    public var onChange:Dynamic->Void = null;
    public var type:OptionItemType;
    public var description:String = "";

    public var intLimit:Null<Int> = null;
    public var intMax:Null<Int> = null;

    public var isSelected:Bool = true;

    var currentOption:String = null;
    var currentValueBool:Bool = false;
    var currentValueInt:Int = 0;
    var currentOptionIndex:Int = 0;
    var optionsArray:Array<String> = [];

    var defaultText:String;

    public function new(option:String)
    {
        super();
        setFormat(Paths.font('vcr'), 34);

        if (Init.gameSettings.get(option) != null)
        {
            currentOption = option;
            description = Init.gameSettings.get(option)[1];

            if (Std.isOfType(Init.gameSettings.get(option)[0], StdTypes.Bool))
            {
                type = Bool;
                currentValueBool = Init.trueSettings.get(option);
            }
            else if (Std.isOfType(Init.gameSettings.get(option)[0], StdTypes.Int))
            {
                type = Int;
                currentValueInt = Init.trueSettings.get(option);

                if (Init.gameSettings.get(option)[2] != null)
                {
                    intLimit = Init.gameSettings.get(option)[2][0];
                    intMax = Init.gameSettings.get(option)[2][1];
                }
            }
            else if (Std.isOfType(Init.gameSettings.get(option)[0], String))
            {
                type = Selection;
                optionsArray = Init.gameSettings.get(option)[2];
                currentOptionIndex = Init.gameSettings.get(option)[2].indexOf(Init.trueSettings.get(option));
            }
            else
                type = Undefined;
        }
        else
            type = Undefined;

        defaultText = type == Undefined ? option.toUpperCase() : option;
        updateText();
    }

    var holdTimer:Float = 0;
    var holdLimitation:Float = 0;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (type != Undefined && isSelected)
        {
            if (Controls.current.justPressed("accept") && type == Bool)
            {
                currentValueBool = !currentValueBool;
                callback(currentValueBool);
                saveValue(currentValueBool);
                FlxG.sound.play(Paths.sound("confirmMenu"));
            }
            else if (type != Bool)
            {
                if (Controls.current.anyJustPressed(["left", "right"]))
                {
                    holdTimer = 0;
                    holdLimitation = 0;
                    updateNonBoolValue();
                    FlxG.sound.play(Paths.sound("scrollMenu"));
                }

                if (Controls.current.anyPressed(["left", "right"]))
                {
                    holdTimer += elapsed;
        
                    if (holdTimer > 0.5)
                    {
                        holdLimitation += 0.05;

                        if (holdLimitation > (FlxG.keys.pressed.SHIFT ? 0.05 : 0.2))
                        {
                            holdLimitation = 0;
                            updateNonBoolValue();
                        }
                    }
                }
            }

            updateText();
        }

        var lerpRatio = Tools.boundFPS(0.10) * 2;
        y = FlxMath.lerp(y, ((FlxG.height - height) / 2) + (targetY * 30), lerpRatio);
        x = FlxMath.lerp(x, (FlxG.width - width) / 2, lerpRatio);
    }

    function updateNonBoolValue()
    {
        var pressedLeft = Controls.current.justPressed("left") || Controls.current.pressed("left");

        if (type == Int)
        {
            if (intMax != null && intLimit != null)
                currentValueInt = FlxMath.wrap(currentValueInt + (pressedLeft ? -1 : 1), intLimit, intMax);
            else
                pressedLeft ? currentValueInt-- : currentValueInt++;
        
            callback(currentValueInt);
            saveValue(currentValueInt);
        }
        else
        {
            currentOptionIndex = FlxMath.wrap(pressedLeft ? currentOptionIndex - 1 : currentOptionIndex + 1, 0, optionsArray.length - 1);
            callback(optionsArray[currentOptionIndex]);
            saveValue(optionsArray[currentOptionIndex]);
        }
    }

    function saveValue(value:Dynamic)
    {
        Init.trueSettings.set(currentOption, value);
        Init.saveSettings();
    }

    function callback(value:Dynamic)
    {
        if (onChange != null)
            onChange(value);
    }

    function updateText()
    {
        switch (type)
        {
            case Bool:
                text = '${defaultText}:  ${currentValueBool ? '<green>ON<green>' : '<red>OFF<red>'}';
                applyMarkup(text, [new FlxTextFormatMarkerPair(new FlxTextFormat(currentValueBool ? FlxColor.GREEN : FlxColor.RED), currentValueBool ? '<green>' : '<red>')]);
            case Int:
                text = '${defaultText}:  ${currentValueInt}';
            case Selection:
                text = '< ${defaultText}:  ${optionsArray[currentOptionIndex]} >';
            case Undefined:
                text = defaultText.toUpperCase();
        }
    }
}