package states.substates.pauses.effects;

import flixel.FlxSprite;

class ShuttleDancer extends FlxSprite
{
	private var looped:Bool = false;

	public function new(x:Float, y:Float, character:String, anim:String, loop:Bool = false)
	{
		super(x, y);
		this.looped = loop;

		frames = Paths.getSparrowAtlas(character);
		animation.addByPrefix('dance', anim, 24, loop);

		dance();
	}

	public function dance()
	{
		animation.play('dance', !looped);
	}
}
