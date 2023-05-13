package meta;

import meta.data.ClientPrefs;
import openfl.media.Sound;
import flixel.sound.FlxSound;
import openfl.utils.Assets;
import flixel.FlxG;
import flixel.system.FlxAssets.FlxSoundAsset;

using StringTools;

class Hitsound
{
	private inline static final NULL_HITSOUND:String = 'none';

	private static var libraryPath:String = Paths.getLibraryPath('sounds/hitsounds/');
	private static var assetList:Array<String>;

	public static function formatToHitsound(?string:String):String
	{
		var start:Null<String> = Paths.formatToSongPath(string ?? NULL_HITSOUND);
		return switch (start)
		{
			case 'default': 'hitsound';
			case 'top-10': 'topten';

			case '': NULL_HITSOUND;
			default: start;
		};
	}

	public static function canPlayHitsound():Bool
	{
		return ClientPrefs.getPref('hitsoundVolume') > 0 && formatToHitsound(ClientPrefs.getPref('hitsound')) != NULL_HITSOUND;
	}

	public static function play(cache:Bool = false):Null<FlxSound>
	{
		if (assetList == null)
			assetList = Assets.list(SOUND);
		if (!canPlayHitsound())
			return null;

		var playing:String = formatToHitsound(ClientPrefs.getPref('hitsound'));
		var asset:Null<FlxSoundAsset> = null;

		var path:String = 'hitsounds/$playing';
		var assetPath:String = 'sounds/$path';

		if (Paths.fileExists('$assetPath.' + Paths.SOUND_EXT, SOUND))
		{
			switch (cache)
			{
				case true:
					CoolUtil.precacheSound(path);
				default:
					asset = Paths.sound(path);
			}
		}
		else
		{
			var sounds:Array<FlxSoundAsset> = new Array();
			for (asset in assetList)
			{
				if (asset.startsWith(libraryPath))
				{
					var arrayDir:Array<String> = asset.split('/');
					arrayDir.pop();
					if (arrayDir.pop() == playing)
					{
						var cached:Null<Sound> = Paths.saveSound(asset);
						if (cached != null && !cache)
							sounds.push(cached);
					}
				}
			}
			if (!cache && sounds.length > 0)
				asset = FlxG.random.getObject(sounds);
		}

		if (!cache && asset != null)
			return FlxG.sound.play(asset, ClientPrefs.getPref('hitsoundVolume'));
		return null;
	}
}
