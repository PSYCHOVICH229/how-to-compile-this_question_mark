package meta.instances.stages;

import states.PlayState;
import states.substates.GameOverSubstate;

class CompressedStage extends Stage
{
	override function onSongStart()
	{
		gfVersion = 'gf-compressed';

		PlayState.noteAssetsLibrary = PlayState.otherAssetsLibrary = PlayState.introAssetsLibrary = PlayState.introKey = GameOverSubstate.deathSoundLibrary = GameOverSubstate.loopSoundLibrary = GameOverSubstate.endSoundLibrary = 'compressed';
		PlayState.introSoundKey = 'default';

		GameOverSubstate.endSoundName = 'gameOverEnd';
		GameOverSubstate.loopSoundName = 'gameOver';

		GameOverSubstate.conductorBPM = 100;
		super.onSongStart();
	}
}
