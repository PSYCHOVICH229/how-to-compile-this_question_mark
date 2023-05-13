package meta.instances.badminton;

import flixel.tweens.FlxTween;
import flixel.FlxSprite;

class ShuttleSplash extends FlxSprite
{
	public function new()
	{
		super();

		frames = Paths.getSparrowAtlas('badminton/shuttleSplash');
		animation.addByPrefix('hit', 'splash', 16, false);

		setGraphicSize(Std.int(width * .7));
		updateHitbox();

		alpha = .75;

		scrollFactor.set(1, 1);
		antialiasing = false;
	}
	public inline function splash(x:Float, y:Float)
	{
		setPosition(x, y);
		animation.finishCallback = function(name:String)
		{
			animation.finishCallback = null;
			kill();
		}
		animation.play('hit', true, false);
	}
}
