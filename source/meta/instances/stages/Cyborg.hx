package meta.instances.stages;

import states.PlayState;

class Cyborg extends BaseStage
{
	override function new(parent:Dynamic)
	{
		super(parent);
		addToStage(new BGSprite('cyborg')); // poop time
	}

	override function onSongStart()
	{
		PlayState.introKey = PlayState.introSoundKey = PlayState.otherAssetsLibrary = PlayState.introAssetsLibrary = 'fnm';
		PlayState.startDelay = .5;

		super.onSongStart();
	}
}
