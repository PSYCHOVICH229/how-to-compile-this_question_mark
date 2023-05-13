package states.substates.pauses;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import states.substates.pauses.effects.ShuttleDancer;

class ShuttleMan extends Default
{
	private var dancers:FlxTypedGroup<ShuttleDancer>;

	public function new(instance:PauseSubState)
	{
		super(instance, 200, true);
		dancers = new FlxTypedGroup();

		var shuttleman:ShuttleDancer = new ShuttleDancer(900, 400, 'pausemenu/shuttleman/shuttleman', 'bruh', true);
		var logo:ShuttleDancer = new ShuttleDancer(400, -50, 'pausemenu/shuttleman/logo', 'logo bumpin');

		logo.setGraphicSize(Std.int(logo.width * .7));
		logo.updateHitbox();

		shuttleman.scrollFactor.set();
		logo.scrollFactor.set();

		shuttleman.visible = false;
		logo.visible = false;

		dancers.add(shuttleman);
		dancers.add(logo);

		add(dancers);
	}

	override function beatHit()
	{
		super.beatHit();
		if (curBeat == 16)
		{
			for (dancer in dancers.members)
			{
				var scaleX:Float = dancer.scale.x;
				var scaleY:Float = dancer.scale.y;

				dancer.scale.set();
				dancer.visible = true;

				FlxTween.tween(dancer, {"scale.x": scaleX, "scale.y": scaleY}, .6, {ease: FlxEase.quartOut});
			}
		}
		for (dancer in dancers.members)
			dancer.dance();
	}

	override function destroy()
	{
		dancers.destroy();
		super.destroy();
	}
}
