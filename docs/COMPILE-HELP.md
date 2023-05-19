# How to Compile:

- First of all, you will need to install [Haxe](https://haxe.org/download/).
- **Haxe 4.3.0 does not work with HaxeFlixel at the moment, so please install the [4.2.5](https://haxe.org/download/version/4.2.5/) version!**
- Once Haxe is installed, you have to install [git-scm](https://git-scm.com/downloads/).
- **Windows Only** - After installing git, you will have to install the Windows dependencies. To install them, just run the bat file of your version of Windows. [Windows 10](vsc-deps/setup-W10.bat) / [Windows 11](vsc-deps/setup-W11.bat)
- After installing git, open a command prompt, run `cd root/directory/of/the/project` and run `haxe -cp ./actions -D analyzer-optimize -main Main --interp` to install all of the required dependencies.
- Finally, run `haxelib run lime setup` in the command prompt to setup lime.

After all of these steps, you will be able to compile Forever Engine: Eternal!
## If you get any problems while compiling even after doing all of these steps, please report the [issue](https://github.com/Forever-Engine-Eternal/Forever-Engine-Eternal/issues) with all of the required details.
## THIS ENGINE REQUIRE ALL OF THE LATEST DEPENDENCIES. WE ARE NOT RESPONSIBLE WITH ISSUES RELATED TO OLDER VERSIONS OF LIBRAIRIES.
## THIS ENGINE IS ONLY MEANT TO BE COMPILED ON DESKTOP. WE ARE NOT RESPONSIBLE WITH ISSUES RELATED TO OTHER PLATFORMS, SUCH AS NEKO AND HTML5.