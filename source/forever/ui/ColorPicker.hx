package forever.ui;

import forever.data.utils.ColorUtils;
import forever.data.utils.Vec3;
import flixel.math.FlxMath;
import forever.data.utils.FNFOutlineSprite;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup.FlxSpriteGroup;
import flixel.FlxG;
import flixel.system.FlxAssets.FlxShader;

/**
 * The `ColorPicker` object allow you to make a color picker.
 * If we click on the slider, the hue of the box will change depending on the mouse position.
 * You can also make it trigger a function when the hue changes using the `onChange` variable.
 * @author Sword352, help + idea by Ne_Eo
 * @see Original color picker shader: https://www.shadertoy.com/view/NlyGRz
 */
class ColorPicker extends FlxSpriteGroup
{
	/**
	 * The hue of this ColorPicker.
	 */
	public var hue(default, set):Float = 0;

	/**
	 * The saturation of this ColorPicker.
	 */
	public var saturation(default, set):Float = 0;

	/**
	 * The value/brightness of this ColorPicker.
	 */
	public var brightness(default, set):Float = 0;

	/**
	 * The current of this ColorPicker.
	 */
	public var currentColor(default, set):FlxColor = 0xFFFFFFFF;

	/**
	 * Whether to change the color depending on the mouse position on the picker and slider.
	 */
	public var changeOnMouse:Bool = true;

	/**
	 * Callback trigerred when the color changes.
	 */
	public var onChange:Void->Void = null;

	/**
	 * Internal, the picker of this ColorPicker.
	 */
	var picker:FNFOutlineSprite;

	/**
	 * Internal, the slider of this ColorPicker.
	 */
	var slider:FNFOutlineSprite;

    /**
     * Internal, the rectangle shown in the slider.
     */
    var sliderRect:FNFOutlineSprite;

	/**
	 * Internal, the `Vec3` used to get the correct color;
	 */
	var _vector:Vec3;

    // Helper booleans
	var callBackEnabled:Bool = true;
	var didChange:Bool = false;
    var inUpdate:Bool = false;

	/**
	 * Makes a new ColorPicker
	 * @param X The X position of the ColorPicker
	 * @param Y The Y position of the ColorPicker
	 * @param Width The width of the ColorPicker
	 * @param Height The height of the ColorPicker
	 */
	public function new(X:Float = 0, Y:Float = 0, Width:Int = 256, Height:Int = 256)
	{
		super(X, Y);

		picker = new FNFOutlineSprite().makeSolid(Width, Height);
		picker.setOutline(2, FlxColor.BLACK);
		picker.shader = new ColorPickerShader();
		add(picker);

		slider = new FNFOutlineSprite().makeSolid(Std.int(Height / 12), Height);
		slider.setOutline(2, FlxColor.BLACK);
		slider.shader = new ColorPickerSliderShader();
		add(slider);
		slider.x = x + width + 25;

        sliderRect = new FNFOutlineSprite().makeSolid(Std.int(slider.width), Std.int(slider.height / 20), FlxColor.GRAY);
        sliderRect.setOutline(2, FlxColor.BLACK);
        add(sliderRect);

		_vector = new Vec3();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

        inUpdate = true;
		callBackEnabled = didChange = false;

        sliderRect.setPosition(slider.x, slider.y + hue);

		if (changeOnMouse && FlxG.mouse.pressed)
		{
			print('SATURATION $saturation BRIGHTNESS $brightness HUE $hue', DEBUG);

			if (slider.isOverlaped())
			{
				hue = (FlxG.mouse.screenY - slider.getScreenPosition(_point, slider.camera).y) / slider.height;
			}

			if (picker.isOverlaped())
			{
				saturation = (FlxG.mouse.screenX - picker.getScreenPosition(_point, picker.camera).x) / picker.width;
				brightness = (FlxG.mouse.screenY - picker.getScreenPosition(_point, picker.camera).y) / picker.height;
			}
		}

		callBackEnabled = true;
		currentColor = FlxColor.fromHSB(hue * 360, saturation * 100, brightness * 100);
        inUpdate = false;
	}

	/**
	 * Returns an `FlxColor` depending on the position on the picker and slider.
	 */
	public inline function getColor():FlxColor
	{
		return currentColor;
	}

	function set_hue(Hue:Float):Float
	{
		if (hue != Hue)
            didChange = true;

		hue = Hue;
		_vector.x = hue;
		picker.shader.data.hue.value = [Hue];

		if (callBackEnabled && onChange != null && didChange)
			onChange();

		return Hue;
	}

	function set_saturation(Saturation:Float):Float
	{
		if (saturation != Saturation)
            didChange = true;

		saturation = Saturation;
		_vector.y = saturation;

		if (callBackEnabled && onChange != null && didChange)
			onChange();

		return Saturation;
	}

	function set_brightness(Brightness:Float):Float
	{
		if (brightness != Brightness)
            didChange = true;

		brightness = Brightness;
		_vector.z = Brightness;

		if (callBackEnabled && onChange != null && didChange)
			onChange();

		return Brightness;
	}

	function set_currentColor(c:FlxColor):FlxColor
	{
        currentColor = c;

        if (!inUpdate) {
            var hsv = ColorUtils.rgbToHsv(new Vec3(c.redFloat, c.greenFloat, c.blueFloat));

			didChange = false;

            callBackEnabled = false;
            hue = hsv.x;
            saturation = hsv.y;
            brightness = hsv.z;
            callBackEnabled = true;
        }

		if (callBackEnabled && onChange != null && didChange)
			onChange();

        return currentColor;
	}
}

class ColorPickerShader extends FlxShader
{
	@:glFragmentSource('
    #pragma header

    vec3 hsvToRgb(vec3 hsv){ //hsv.x = hue, hsv.y = saturation, hsv.z = value
	    vec3 col = vec3(hsv.x, hsv.x + 2.0/3.0, hsv.x + 4.0/3.0); //inputs for r, g, and b
	    col = clamp(abs(mod(col*2.0, 2.0)-1.0)*3.0 - 1.0, 0.0, 1.0)*hsv.z*hsv.y + hsv.z - hsv.z*hsv.y; //hue function (graph it on desmos)
	    return col;
    }

    uniform float hue;

    void main()
    {
	    vec2 uv = openfl_TextureCoordv.xy;
	    vec3 col = hsvToRgb(vec3(hue, uv.x, 1.0-uv.y));

	    gl_FragColor = vec4(col,1.0);
    }')

	public function new() {
		super();
		hue.value = [0.0];
	}
}

class ColorPickerSliderShader extends FlxShader
{
	@:glFragmentSource('
    #pragma header

    vec3 hsvToRgb(vec3 hsv){ //hsv.x = hue, hsv.y = saturation, hsv.z = value
	    vec3 col = vec3(hsv.x, hsv.x + 2.0/3.0, hsv.x + 4.0/3.0); //inputs for r, g, and b
	    col = clamp(abs(mod(col*2.0, 2.0)-1.0)*3.0 - 1.0, 0.0, 1.0)*hsv.z*hsv.y + hsv.z - hsv.z*hsv.y; //hue function (graph it on desmos)
	    return col;
    }

    void main() {
	    vec2 uv = openfl_TextureCoordv.xy;
	    vec3 col = hsvToRgb(vec3(uv.y,1.0,1.0));

	    gl_FragColor = vec4(col,1.0);
    }')

	public function new() { super(); }
}