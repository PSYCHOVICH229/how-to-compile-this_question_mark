package;

import flash.media.Sound;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class Paths
{
	public inline static final SOUND_EXT = #if web "mp3" #else "ogg" #end;
	public inline static final VIDEO_EXT = "mp4";

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];
	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];
	public static var currentLevel:String;
	// A file name can't contain any of the following characters:
	// \ / : * ? " < > |
	public static final invalidChars:EReg = ~/[~&\\;:<>#]+/g;
	public static final hideChars:EReg = ~/[.,'"%?!]+/g;
	/// haya I love you for the base cache dump I took to the max
	public static final dumpExclusions:Array<String> = [
		'assets/images/ui/transition/barBottom.png',
		'assets/images/ui/transition/barTop.png',
		'assets/images/ui/transition/textBottom.png',
		'assets/images/ui/transition/textTop.png',
		'assets/images/ui/transition/microphone.png',
		'assets/images/ui/transition/tile.png',
		'assets/images/arcade/static.png'
	];

	public inline static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				// get rid of it
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null)
				{
					OpenFlAssets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);

					obj.destroy();
					currentTrackedAssets.remove(key);
				}
			}
		}
		// run the garbage collector for good measure lmfao
		System.gc();
	}

	public inline static function clearStoredMemory(?cleanUnused:Bool = false)
	{
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj:FlxGraphic = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				OpenFlAssets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);

				obj.destroy();
			}
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && key != null)
			{
				// trace('test: ' + dumpExclusions, key);
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		OpenFlAssets.cache.clear("songs");
	}

	public inline static function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function getPath(file:String, ?type:AssetType = null, ?library:Null<String> = null)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}
		return getPreloadPath(file);
	}

	public inline static function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default")
		{
			getPreloadPath(file);
		}
		else
		{
			getLibraryPathForce(file, library);
		}
	}

	private inline static function getLibraryPathForce(file:String, library:String)
		return '$library:assets/$library/$file';

	public inline static function getPreloadPath(file:String = '')
		return 'assets/$file';

	public inline static function file(file:String, type:AssetType = TEXT, ?library:String)
		return getPath(file, type, library);

	public inline static function txt(key:String, ?library:String)
		return getPath('data/$key.txt', TEXT, library);

	public inline static function json(dir:String, key:String, ?library:String)
		return getPath('$dir/$key.json', null, library);

	public static function video(key:String)
		return 'assets/videos/$key.$VIDEO_EXT';

	public static function sound(key:String, ?library:String):Sound
		return returnSound('sounds', key, library);

	public inline static function soundRandom(key:String, min:Int, max:Int, ?library:String)
		return sound(key + FlxG.random.int(min, max), library);

	public inline static function music(key:String, ?library:String):Sound
		return returnSound('music', key, library);

	public inline static function voices(song:String):Any
	{
		var path:String = formatToSongPath(song) + '/Voices';
		return Assets.exists('songs:' + getPath('songs/$path.$SOUND_EXT', SOUND), SOUND) ? returnSound('songs', path) : null;
	}

	public inline static function inst(song:String):Any
	{
		var path:String = formatToSongPath(song) + '/Inst';
		return Assets.exists('songs:' + getPath('songs/$path.$SOUND_EXT', SOUND), SOUND) ? returnSound('songs', path) : null;
	}

	public inline static function image(key:String, ?library:String):FlxGraphic
		return returnGraphic(getPath('images/$key.png', IMAGE, library));

	public inline static function font(key:String)
		return 'assets/fonts/$key';

	public inline static function fileExists(key:String, type:AssetType, ?library:String)
		return OpenFlAssets.exists(getPath(key, type, library));

	public inline static function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));

	public inline static function getPackerAtlas(key:String, ?library:String)
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));

	public inline static function formatToSongPath(path:Null<String>):String
		return hideChars.split(invalidChars.split(path?.trim() ?.replace(' ', '-') ?? "").join("-")).join("").toLowerCase();

	// completely rewritten asset loading? fuck!
	public inline static function returnGraphic(path:String):Null<FlxGraphic>
	{
		if (OpenFlAssets.exists(path, IMAGE))
		{
			if (!currentTrackedAssets.exists(path))
			{
				var newGraphic:FlxGraphic = FlxG.bitmap.add(path, false, path);

				newGraphic.persist = true;
				currentTrackedAssets.set(path, newGraphic);
			}
			localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}
		trace('oh no $path is returning null NOOOO');
		return null;
	}

	public static function saveSound(path:String, ?key:String = null):Null<Sound>
	{
		var gottenPath:String = path.substring(path.indexOf(':') + 1, path.length);
		if (!currentTrackedSounds.exists(gottenPath)) // currentTrackedSounds.set(path, Sound.fromFile('./$path'));
		{
			var shit:String = (key == 'songs' ? 'songs:' : '') + path;
			if (OpenFlAssets.exists(shit, SOUND))
			{
				currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(shit));
			}
			else
			{
				trace('oh no $path is returning null NOOOO');
				return null;
			}
		}
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	public inline static function returnSound(path:String, key:String, ?library:String = null):Null<Sound> // I hate this so god damn much
		// trace(gottenPath);
		return saveSound(getPath('$path/$key.$SOUND_EXT', SOUND, library), path);
}
