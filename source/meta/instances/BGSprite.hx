package meta.instances;

import meta.data.ClientPrefs;
import flixel.FlxSprite;

class BGSprite extends FlxSprite
{
	private var idleAnim:String;

	public function new(image:Dynamic, x:Float = 0, y:Float = 0, ?scrollX:Float = 1, ?scrollY:Float = 1, ?antialiasing:Bool = true,
			?animArray:Array<String> = null, ?loop:Bool = false)
	{
		super(x, y);
		if (animArray != null)
		{
			frames = Std.isOfType(image, String) ? Paths.getSparrowAtlas(image) : image;
			for (i in 0...animArray.length)
			{
				var anim:String = animArray[i];
				animation.addByPrefix(anim, anim, 24, loop);

				if (idleAnim == null)
				{
					idleAnim = anim;
					animation.play(anim);
				}
			}
		}
		else
		{
			if (image != null)
				loadGraphic(Std.isOfType(image, String) ? Paths.image(image) : image);
			active = false;
		}

		scrollFactor.set(scrollX, scrollY);
		this.antialiasing = antialiasing && ClientPrefs.getPref('globalAntialiasing');
	}

	public inline function dance(?forceplay:Bool = false)
	{
		if (idleAnim != null)
			animation.play(idleAnim, forceplay);
	}
}
