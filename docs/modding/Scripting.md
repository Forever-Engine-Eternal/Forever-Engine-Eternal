Forever Engine Eternal allows a scripting system powered by HScript.
HScript is a scripting system allowing to write haxe code outside of the source code.
Everything can be made using functions called by the game, such as `create`. It does not allow custom classes at the moment, but will be available soon.

HScript files support these following extensions:
```
.hx
.hxs
.hxc
.hsc
.hscript
.hxclass (When the custom HScript classes will release)
```

HScript files have several variables exposed publicly to every created script, those being:
```
Std
Math
FlxG
FlxSprite
FlxSound
FlxGroup
FlxTween
FlxEase
FlxTimer
FlxColor
FlxMath
FlxInputState
FlxAxes
FNFSprite
Conductor
StringTools
Tools
Paths

// FlxTweenType
PERSIST
LOOPING
PINGPONG
ONESHOT
BACKWARD
```
You can also import classes like in a .hx script.
**For now, only classes can be imported. Imports for abstracts, enums and typedefs doesn't works at the moment, but we are working on it to make it possible to import them.**

HScript can be used in various things like shaders, stages etc.
Happy coding!