package states.substates.pauses;

import states.substates.pauses.effects.PulseParticle;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.effects.particles.FlxEmitter;
import flixel.tweens.FlxTween;
import meta.data.ClientPrefs;
import flixel.FlxG;
import flixel.FlxSprite;

class Pulse extends BasePause
{
	private var emitter:FlxEmitter;
	private var disc:FlxSprite;

	private var lap:Float = 10;
	private var time:Float = 0;

	public function new(instance:PauseSubState)
	{
		// yesss
		super(instance, 90);
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF0F003F);

		disc = new FlxSprite().loadGraphic(Paths.image('pausemenu/disc'));
		disc.antialiasing = ClientPrefs.getPref('globalAntialiasing');

		disc.screenCenter(Y);
		disc.x = FlxG.width + disc.width;

		disc.scrollFactor.set();
		disc.alpha = 0;

		bg.scrollFactor.set();
		bg.alpha = 0;

		add(bg);
		add(disc);

		if (!ClientPrefs.getPref('lowQuality'))
		{
			emitter = new FlxEmitter();
			emitter.lifespan.set(crochet / 500);

			emitter.ignoreAngularVelocity = true;
			emitter.launchMode = CIRCLE;

			emitter.speed.set(500);
			var sizeMult:Float = Math.PI / 2;

			emitter.setSize(disc.width * sizeMult, disc.height * sizeMult);
			emitter.setPosition((FlxG.width - emitter.width) / 2, (FlxG.height - emitter.height) / 2);

			for (i in 0...250)
				emitter.add(new PulseParticle());
			add(emitter);
		}

		FlxTween.tween(bg, {alpha: .95}, .6, {ease: FlxEase.circOut});
		FlxTween.tween(disc, {x: (FlxG.width - disc.width) / 2, alpha: .5}, 1, {ease: FlxEase.sineInOut, startDelay: .4});
	}

	override function beatHit()
	{
		super.beatHit();
		disc.scale.set(1.1, 1.1);

		if (emitter != null && curBeat >= 16)
		{
			switch (curBeat % 8)
			{
				case 4 | 7:
					emitter.start(true, -1, 0);
			}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		time = (time + elapsed) % lap;

		var lerpSpeed:Float = FlxMath.bound(1 - (elapsed * Math.PI), 0, 1);
		disc.angle = (time / lap) * 360;

		disc.scale.x = FlxMath.lerp(1, disc.scale.x, lerpSpeed);
		disc.scale.y = FlxMath.lerp(1, disc.scale.y, lerpSpeed);
	}

	override function destroy()
	{
		if (emitter != null)
		{
			emitter.kill();
			remove(emitter, true);

			emitter.destroy();
			emitter = null;
		}

		remove(disc, true);
		disc.destroy();

		super.destroy();
	}
}
