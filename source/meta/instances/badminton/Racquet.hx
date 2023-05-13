package meta.instances.badminton;

import flixel.animation.FlxAnimation;
import flixel.math.FlxPoint;
import flixel.FlxSprite;

class Racquet extends FlxSprite
{
	private static var shuttleOffset:FlxPoint = new FlxPoint(170, 385);

	private var racquetOffset:FlxPoint;
	private var character:Character;

	public function new(character:Character, ?racquetOffset:FlxPoint = null)
	{
		super();
		if (racquetOffset == null)
			racquetOffset = new FlxPoint(75);

		this.racquetOffset = racquetOffset;
		this.character = character;

		scrollFactor.set(1, 1);
		antialiasing = false;

		frames = Paths.getSparrowAtlas('badminton/racquet');

		animation.addByPrefix('swing', 'swing', 18, false);
		animation.addByPrefix('idle', 'idle', 18, false);

		repositionRacquet();
		dance(true);

		animation.finishCallback = function(anim:String)
		{
			if (anim == 'swing')
			{
				// Go into resting
				dance(true);
				animation.finish();
			}
		};
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		repositionRacquet();
	}

	public inline function getRacquetPosition():FlxPoint
		return new FlxPoint(x + (shuttleOffset.x * (flipX ? -1 : 1)), y + shuttleOffset.y);

	private inline function repositionRacquet()
	{
		if (character != null)
		{
			flipX = character.flipX;

			x = character.x + (racquetOffset.x * (flipX ? -1 : 1));
			y = character.y + racquetOffset.y;
		}
	}

	public inline function swing()
		animation.play('swing', true);

	public inline function dance(force = false)
	{
		var curAnim:FlxAnimation = animation.curAnim;
		if (force || curAnim == null || curAnim.name != 'swing' || curAnim.finished)
			animation.play('idle', true);
	}
}
