package meta.instances.stages;

import shaders.Shaders.GlitchEffect;
import meta.data.ClientPrefs;

class Opposition extends BaseStage
{
	private var wiggle:GlitchEffect;

	override function new(parent:Dynamic)
	{
		super(parent);
		var bg:BGSprite = new BGSprite('what_the_fuck', -1200, -200);

		bg.setGraphicSize(Std.int(bg.width * 2));
		bg.updateHitbox();

		if (ClientPrefs.getPref('shaders'))
		{
			wiggle = new GlitchEffect();

			wiggle.waveAmplitude = .1;
			wiggle.waveFrequency = 5;
			wiggle.waveSpeed = 2;

			bg.shader = wiggle.shader;
			parent.shaders.push(wiggle);
		}
		addToStage(bg);
	}

	override function onSongStart()
	{
		parent.addTrail = true;
		super.onSongStart();
	}

	override function destroy()
	{
		if (wiggle != null && parent.shaders.contains(wiggle))
			parent.shaders.remove(wiggle);
		super.destroy();
	}
}
