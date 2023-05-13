package meta.instances;

import flixel.FlxSprite;

class GoofyCountdown extends FlxSprite
{
	override function update(elapsed:Float)
	{
		alpha = Math.max(alpha - (elapsed * (Conductor.stepCrochet / 30)), 0);
		if (alpha <= 0)
			return kill();
	}
}
