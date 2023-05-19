package forever.settings.substates;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.FlxG;

/**
 * This is the controls sub state, where you can change your keybinds.
 * You shouldn't modify this sub state, except for visuals, unless you wanna modify the whole sub state.
 * To add a control, check the `gameControls` variable in Init.
 * @author Sword352
 */
class ControlsSubState extends forever.music.MusicBeat.MusicBeatSubState
{
    var items:FlxTypedGroup<ControlItem>;

    var curSelected:Int = 0;
    var curBind:Int = 0;

    override function create()
    {
        super.create();

        var controlsArray:Array<String> = [];
        for (controlString in Init.gameControls.keys())
			controlsArray[Init.gameControls.get(controlString)[1]] = controlString;

        items = new FlxTypedGroup<ControlItem>();

        for (i in 0...controlsArray.length)
        {
            var newItem = new ControlItem(controlsArray[i]);
            newItem.ID = i;
            newItem.targetY = i;
            items.add(newItem);
        }

        add(items);

        changeSelection();
        changeBind();
    }

    var transitioning:Bool = false;
    var isChangingKeybind:Bool = false;
    var justChangedKeybind:Bool = false;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (justChangedKeybind)
        {
            justChangedKeybind = false;
            return;
        }

        if (controls.anyJustPressed(["down", "up"]) && !isChangingKeybind && !justChangedKeybind && !transitioning)
            changeSelection(controls.justPressed("up") ? -1 : 1);

        if (controls.anyJustPressed(["left", "right"]) && !isChangingKeybind && !justChangedKeybind && !transitioning)
            changeBind(controls.justPressed("left") ? -1 : 1);

        if (controls.justPressed("accept") && !isChangingKeybind && items.members[curSelected].curSelected != 0 && !justChangedKeybind && !transitioning)
        {
            isChangingKeybind = true;
            items.members[curSelected].selectItem();
            items.members[curSelected].onChangeKeybind = function (key) {
                FlxG.sound.play(Paths.sound("confirmMenu"));
                isChangingKeybind = false;
                items.members[curSelected].onChangeKeybind = null;
                justChangedKeybind = true;
            };
        }

        if (controls.justPressed("back") && !isChangingKeybind && !justChangedKeybind)
        {
            transitioning = true;

            for (item in items)
                item.destroy();

            items.destroy();

            FlxG.sound.play(Paths.sound("cancelMenu"));
            cast(FlxG.state, OptionsState).closeOptionSubState();
        }
    }

    function changeSelection(change:Int = 0):Void
    {
        curSelected = FlxMath.wrap(curSelected + change, 0, items.length - 1);

        if (items.members[curSelected].text == "")
            return changeSelection(change);

        if (change != 0)
            FlxG.sound.play(Paths.sound("scrollMenu"));

        var changement:Int = 0;
        for (item in items)
        {
            item.targetY = changement - curSelected;
            item.alpha = item.ID == curSelected ? 1 : 0.6;

            changement++;
        }
    }

    function changeBind(change:Int = 0)
    {
        curBind = FlxMath.wrap(curBind + change, 0, 2);

        if (change != 0)
            FlxG.sound.play(Paths.sound("scrollMenu"));

        for (item in items)
        {
            item.curSelected = curBind;
            item.updateAlpha(item.alpha);
        }
    }
}