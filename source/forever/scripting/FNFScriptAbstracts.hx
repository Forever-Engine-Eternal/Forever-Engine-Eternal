package forever.scripting;

/**
 * Simple class to store abstracts to allow HScript to use them.
 */
class FNFScriptAbstracts {
    /**
     * Just an enum value pretty much.
     */
     public static var FlxInputState:Dynamic = {
        'JUST_RELEASED': -1,
        'RELEASED': 0,
        'PRESSED': 1,
        'JUST_PRESSED': 2
    };

    /**
     * Once again an enum that technically has more functions but for now those are just not gonna be supported ig.
     */
    public static var FlxAxes:Dynamic = {
        'X': 0x01,
        'Y': 0x10,
        'XY': 0x11,
        'NONE': 0x00
    };

    /**
     * Literally just all the static vars and functions from `flixel.util.FlxColor`.
     */
    public static var FlxColor:Dynamic = {
        // static vars
        'TRANSPARENT': flixel.util.FlxColor.TRANSPARENT,
        'WHITE': flixel.util.FlxColor.WHITE,
        'GRAY': flixel.util.FlxColor.GRAY,
        'BLACK': flixel.util.FlxColor.BLACK,
        'GREEN': flixel.util.FlxColor.GREEN,
        'LIME': flixel.util.FlxColor.LIME,
        'YELLOW': flixel.util.FlxColor.YELLOW,
        'ORANGE': flixel.util.FlxColor.ORANGE,
        'RED': flixel.util.FlxColor.RED,
        'PURPLE': flixel.util.FlxColor.PURPLE,
        'BLUE': flixel.util.FlxColor.BLUE,
        'BROWN': flixel.util.FlxColor.BROWN,
        'PINK': flixel.util.FlxColor.PINK,
        'MAGENTA': flixel.util.FlxColor.MAGENTA,
        'CYAN': flixel.util.FlxColor.CYAN,
        'colorLookup': flixel.util.FlxColor.colorLookup,
        // static funcs
        'fromInt': flixel.util.FlxColor.fromInt,
        'fromRGB': flixel.util.FlxColor.fromRGB,
        'fromRGBFloat': flixel.util.FlxColor.fromRGBFloat,
        'fromCMYK': flixel.util.FlxColor.fromCMYK,
        'fromHSB': flixel.util.FlxColor.fromHSB,
        'fromHSL': flixel.util.FlxColor.fromHSL,
        'fromString': flixel.util.FlxColor.fromString,
        'getHSBColorWheel': flixel.util.FlxColor.getHSBColorWheel,
        'interpolate': flixel.util.FlxColor.interpolate,
        'gradient': flixel.util.FlxColor.gradient,
        'multiply': flixel.util.FlxColor.multiply,
        'add': flixel.util.FlxColor.add,
        'subtract': flixel.util.FlxColor.subtract,
        'new': flixel.util.FlxColor.new
    };
}