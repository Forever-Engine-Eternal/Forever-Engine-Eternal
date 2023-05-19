package forever.settings.items;

import forever.data.Controls;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.FlxG;
import flixel.util.FlxColor;

/**
 * This is the ControlItem class, the text in the controls category of the settings to modify the controls.
 * @author Sword352
 */
class ControlItem extends flixel.group.FlxGroup.FlxTypedGroup<FlxText>
{
    public var targetY:Float = 0;
    public var alpha(default, set):Float = 1;
    public var curSelected:Int = 0;
    public var text(get, never):String;
    public var onChangeKeybind:FlxKey->Void = null;

    var controlText:FlxText;
    var controlBind:FlxText;
    var secondControlBind:FlxText;

    var control:String = null;

    public function new(control:String)
    {
        super();

        controlText = new FlxText(150).setFormat(Paths.font('vcr'), 44);
        controlText.ID = 0;
        add(controlText);

        if (Init.gameControls.get(control) != null)
        {
            this.control = control;
            controlText.text = control;

            controlBind = new FlxText(0, 0, 0, formatKey(Init.gameControls.get(control)[0][0])).setFormat(Paths.font('vcr'), 44, FlxColor.WHITE, CENTER);
            controlBind.ID = 1;
            add(controlBind);

            secondControlBind = new FlxText(900, 0, 0, formatKey(Init.gameControls.get(control)[0][1])).setFormat(Paths.font('vcr'), 44, FlxColor.WHITE, LEFT);
            secondControlBind.ID = 2;
            add(secondControlBind);

            repositionItems();
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        controlText.y = FlxMath.lerp(controlText.y, ((FlxG.height - controlText.height) / 2) + (targetY * 40), Tools.boundFPS(0.10) * 2);
        if (control != null)
            controlBind.y = secondControlBind.y = controlText.y;

        if (FlxG.keys.justPressed.ANY && changingKeybind)
        {
            var pressedControl:FlxKey = cast FlxG.keys.firstJustPressed();

            if (Init.gameControls.get(control)[0][curSelected - 1] == pressedControl)
                pressedControl = NONE;

            Init.gameControls.get(control)[0][curSelected - 1] = pressedControl;
            members[curSelected].text = formatKey(pressedControl);

            Controls.refreshKeys();
            Init.saveControls();

            for (item in members)
                item.visible = true;

            updateAlpha(alpha);
            repositionItems();

            changingKeybind = false;

            if (onChangeKeybind != null)
                onChangeKeybind(pressedControl);
        }
    }

    var changingKeybind:Bool = false;

    public function selectItem()
    {
        if (control != null)
        {
            changingKeybind = true;

            for (item in [for (i in members) if (i.ID != curSelected) i])
                item.visible = false;

            FlxG.sound.play(Paths.sound("scrollMenu"));
        }
    }

    public function updateAlpha(value:Float)
    {
        for (item in members)
        {
            if (value == 1)
            {
                if (item.ID == curSelected)
                    item.alpha = value;
                else
                    item.alpha = 0.6;
            }
            else
                item.alpha = value;
        }
    }

    public function repositionItems()
    {
        if (control != null)
        {
            controlBind.screenCenter(X);
            secondControlBind.x = 1100 - secondControlBind.width;
        }
    }

    private function formatKey(key:FlxKey):String
    {
        var keyString:String = key.toString();

        if (key == NONE)
            keyString = "None";

        return keyString;
    }

    function set_alpha(value:Float):Float
    {
        updateAlpha(value);
        return alpha = value;
    }
    
    function get_text():String
    {
        return controlText.text;
    }
}