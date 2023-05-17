package meta;

import haxe.Exception;
import states.substates.GameOverSubstate;
import flixel.util.FlxColor;
import meta.data.ClientPrefs;
import states.PlayState;
import flixel.FlxSprite;
import flixel.FlxG;

using StringTools;

import openfl.utils.Assets;

class CoolUtil
{
	public static final defaultDifficulties:Array<String> = ['Easy', 'Normal', 'Raw'];
	public static final defaultDifficultyInt:Int = Std.int(defaultDifficulties.length / 2);

	public static var defaultDifficulty:String = defaultDifficulties[defaultDifficultyInt]; // The chart that has no suffix and starting difficulty on Freeplay/Story Mode
	public static var difficulties:Array<String> = [];

	public inline static function difficultyString(?num:Null<Int>):Null<String>
		return difficulties[num ?? PlayState.storyDifficulty]?.toUpperCase();
	public inline static function getDifficultyFilePath(?num:Null<Int>)
		return Paths.formatToSongPath(difficultyString(num) ?? defaultDifficulty);

	public inline static function quantize(f:Float, snap:Float) // changed so this actually works lol
		return Math.fround(f * snap) / snap;

	public inline static function toggleVolumeKeys(enabled:Bool = true)
	{
		if (enabled)
		{
			var keyBinds:Map<String, Array<Dynamic>> = ClientPrefs.keyBinds;

			FlxG.sound.volumeDownKeys = ClientPrefs.copyKey(keyBinds.get('volume_down'));
			FlxG.sound.volumeUpKeys = ClientPrefs.copyKey(keyBinds.get('volume_up'));

			FlxG.sound.muteKeys = ClientPrefs.copyKey(keyBinds.get('volume_mute'));
		}
		else
		{
			FlxG.sound.muteKeys = FlxG.sound.volumeDownKeys = FlxG.sound.volumeUpKeys = [];
		}
	}

	public inline static function repeat(value:Int, delta:Int, loop:Int):Int
		return wrap(value + delta, loop);

	public inline static function wrap(value:Int, loop:Int):Int
		return value < 0 ? ((loop + value) % loop) : (value % loop);

	public inline static function int(value:Bool):Int
		return value ? 1 : 0;

	public inline static function delta(a:Bool, b:Bool):Int
		return int(a) - int(b);

	public inline static function coolTextFile(path:String):Array<String>
		return Assets.exists(path, TEXT) ? listFromString(Assets.getText(path)) : [];

	public inline static function listFromString(string:String):Array<String>
		return [for (i in string.trim().split('\n')) i.trim()];

	public inline static function dominantColor(sprite:FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth)
		{
			for (row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel != 0)
				{
					if (countByColor.exists(colorOfThisPixel))
					{
						countByColor[colorOfThisPixel]++;
					}
					else if (countByColor[colorOfThisPixel] != -13520687)
					{
						countByColor[colorOfThisPixel] = 1;
					}
				}
			}
		}

		var maxCount:Int = 0;
		var maxKey:Int = 0; // after the loop this will store the max color

		countByColor[FlxColor.BLACK] = 0;
		for (key in countByColor.keys())
		{
			var curCount:Int = countByColor[key];
			if (curCount >= maxCount)
			{
				maxCount = curCount;
				maxKey = key;
			}
		}
		return maxKey;
	}

	// uhhhh does this even work at all? i'm starting to doubt
	public inline static function precacheSound(sound:String, ?library:String = null):Void
		Paths.sound(sound, library);

	public inline static function precacheMusic(sound:String, ?library:String = null):Void
		Paths.music(sound, library);

	public inline static function totalFuckingReset():Void
	{
		GameOverSubstate.resetVariables();
		PlayState.introSoundKey = PlayState.barsAssets = PlayState.noteAssetsLibrary = PlayState.otherAssetsLibrary = PlayState.introAssetsLibrary = null;

		PlayState.introAssetsSuffix = '';
		PlayState.introKey = 'default';
	}

	public inline static function precacheSong(song:String):Void
	{
		Paths.inst(song);
		Paths.voices(song);
	}

	public inline static function browserLoad(site:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}
}
