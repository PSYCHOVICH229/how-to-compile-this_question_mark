package meta.instances.stages;

import states.PlayState;
import flixel.math.FlxPoint;
import meta.data.ClientPrefs;

class Shaggy extends BaseStage
{
	override function new(parent:Dynamic)
	{
		super(parent);
		var stageOffset:FlxPoint = new FlxPoint(-400);

		var bg:BGSprite = new BGSprite('shaggy/background', stageOffset.x, stageOffset.y, .2, .2);
		var platform:BGSprite = new BGSprite('shaggy/platform', stageOffset.x, stageOffset.y + 100);

		addToStage(bg);
		addToStage(platform);

		if (!ClientPrefs.getPref('lowQuality'))
		{
			var money:BGSprite = new BGSprite('shaggy/money', stageOffset.x, stageOffset.y, .6, .6);
			addToStage(money);
		}
	}

	override function onSongStart()
	{
		PlayState.introKey = PlayState.introSoundKey = PlayState.otherAssetsLibrary = PlayState.introAssetsLibrary = 'fnm';
		PlayState.startDelay = .5;

		super.onSongStart();
	}
}
