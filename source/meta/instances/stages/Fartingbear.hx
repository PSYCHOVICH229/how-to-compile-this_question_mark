package meta.instances.stages;

import states.PlayState;

class Fartingbear extends BaseStage
{
	override function new(parent:Dynamic)
	{
		super(parent);
		addToStage(new BGSprite('FARTING_'));
	}

	override function onSongStart()
	{
		PlayState.introKey = PlayState.introSoundKey = PlayState.otherAssetsLibrary = PlayState.introAssetsLibrary = 'fnm';
		PlayState.startDelay = .5;

		super.onSongStart();
	}
}
