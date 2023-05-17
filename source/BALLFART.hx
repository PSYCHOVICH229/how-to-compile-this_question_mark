package;

import meta.data.ClientPrefs;
import meta.data.Song.SwagSong;
import meta.data.Song;
import haxe.Json;
import states.TitleState;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxGame;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;
#if web
import states.AntiPiracyState;
import js.html.Location;
import js.Browser;
#end
// crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import meta.Discord.DiscordClient;
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class BALLFART extends Sprite
{
	public static final blarf:Dynamic = {
		width: 1280, // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
		height: 720, // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
		zoom: -1., // If -1, zoom is automatically calculated to fit the window dimensions.
		initialState: TitleState, // The FlxState the game starts with.
		framerate: 60, // How many frames per second the game should run at.
		skipSplash: true, // Whether to skip the flixel splash screen that appears in release mode.
		startFullscreen: false // Whether to start the game in fullscreen on desktop targets
	};
	#if CRASH_HANDLER
	public inline static final REPORT_PAGE:String = #if debug 'https://github.com/funny-studios/vs-funny-boyfriend' #else 'https://github.com/funny-studios/funnying-forever' #end;
	public inline static final CRASH_DIRECTORY:String = "./crash/";
	#end
	public inline static final CONTROL_BIND:String = "FUNNYING_CONTROLS_V2";
	public inline static final DATA_BIND:String = "FUNNYING_DATA_V2";

	public static var fpsVar:FPS;
	#if web
	public static final whitelistedLocations:Array<String> = [
		'paracosm-daemon.itch.io',
		'itch.io',
		'gamejolt.net',
		'gamejolt.com',
		'127.0.0.1',
		'localhost'
	];
	#end

	// You can pretty much ignore everything from here on - your code should go in your states.
	public static function main():Void
		Lib.current.addChild(new BALLFART());

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
			FlxG.signals.gameResized.add(onResizeGame);
		}
	}

	private inline function init(?event:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);
		setupGame();
	}

	private function onResizeGame(width:Int, height:Int)
	{
		@:privateAccess
		{
			for (camera in FlxG.cameras?.list)
			{
				if ((camera?._filters?.length ?? -1) > 0)
				{
					var sprite:Sprite = camera?.flashSprite;
					if (sprite != null)
					{
						sprite.__cacheBitmap = null;
						sprite.__cacheBitmapData
							= sprite.__cacheBitmapData2
							= sprite.__cacheBitmapData3
								= null;
						sprite.__cacheBitmapColorTransform = null;
					}
				}
			}
		}
	}

	private function setupGame():Void
	{
		var stageHeight:Int = Lib.current.stage.stageHeight;
		var stageWidth:Int = Lib.current.stage.stageWidth;

		if (blarf.zoom < 0)
		{
			var ratioX:Float = stageWidth / blarf.width;
			var ratioY:Float = stageHeight / blarf.height;

			blarf.zoom = Math.min(ratioX, ratioY);

			blarf.height = Math.ceil(stageHeight / blarf.zoom);
			blarf.width = Math.ceil(stageWidth / blarf.zoom);
		}
		ClientPrefs.loadDefaultKeys();
		#if web
		var host:String = Browser?.location?.hostname;
		if (host == null || !whitelistedLocations.contains(host))
			blarf.initialState = AntiPiracyState;
		#end
		addChild(new FlxGame(blarf.width, blarf.height, blarf.initialState, blarf.framerate, blarf.framerate, blarf.skipSplash, blarf.startFullscreen));

		fpsVar = new FPS(10, 3, FlxColor.CYAN);
		addChild(fpsVar);

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		if (fpsVar != null)
			fpsVar.visible = ClientPrefs.getPref('showFPS');
		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end
		#if DISCORD_ALLOWED
		if (!DiscordClient.isInitialized)
		{
			DiscordClient.initialize();
			Lib.application.window.onClose.add(function()
			{
				DiscordClient.shutdown();
			});
		}
		#end

		FlxG.autoPause = #if web false #else true #end;
		FlxG.mouse.visible = false;
	}

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	private static function onCrash(e:UncaughtErrorEvent):Void
	{
		var dateNow:String = Date.now().toString().replace(" ", "_").replace(":", "'");
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);

		var path:String = CRASH_DIRECTORY + 'funnying' + #if debug '_debug' #else '' #end + '_$dateNow.txt';
		var errMsg:String = "";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += '$file (line $line)\n';
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += '\nUncaught Error: ${e.error}\nPlease report this error to the GitHub page: $REPORT_PAGE\n\n> Crash Handler written by: sqirra-rng';
		if (!FileSystem.exists(CRASH_DIRECTORY))
			FileSystem.createDirectory(CRASH_DIRECTORY);

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Lib.application.window.alert(errMsg, "Error!");
		DiscordClient.shutdown();

		Sys.exit(1);
	}
	#end
}
