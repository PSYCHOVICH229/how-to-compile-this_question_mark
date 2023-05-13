package meta.instances.stages;

import flixel.math.FlxMath;
import flixel.FlxG;
import meta.data.ClientPrefs;

class Hell extends BaseStage
{
	private inline static final PLATFORM_SPEED:Float = 1000;
	private inline static final FOG_SPEED:Float = 4500;

	private inline static final UPSCALING:Float = 1.7;

	public var horsePlatform:BGSprite;
	public var itsAHorse:Character;

	private var fogRight:BGSprite;
	private var fogLeft:BGSprite;

	override function new(parent:Dynamic)
	{
		super(parent);
		var bg:BGSprite = new BGSprite('hell/background', -FlxG.width / 2, 0, 0, .8);

		bg.setGraphicSize(Std.int(bg.width * UPSCALING));
		bg.updateHitbox();

		var mountains:BGSprite = new BGSprite('hell/mountains', 0, 0, .6, .8);
		var sign:BGSprite = new BGSprite('hell/sign', -150, -75, .5, .7);

		mountains.setGraphicSize(Std.int(mountains.width * UPSCALING));
		mountains.updateHitbox();

		sign.setGraphicSize(Std.int(sign.width * UPSCALING));
		sign.updateHitbox();

		var foreground:BGSprite = new BGSprite('hell/foreground', 200);

		foreground.setGraphicSize(Std.int(foreground.width * UPSCALING));
		foreground.updateHitbox();

		addToStage(bg);
		if (!ClientPrefs.getPref('lowQuality'))
		{
			var clouds:BGSprite = new BGSprite('hell/clouds', -300, 0, .3, .6);

			clouds.setGraphicSize(Std.int(clouds.width * UPSCALING));
			clouds.updateHitbox();

			fogLeft = new BGSprite('hell/fog', -300, 0, .2, .6);

			fogLeft.setGraphicSize(Std.int(fogLeft.width * UPSCALING));
			fogLeft.updateHitbox();

			fogRight = new BGSprite('hell/fog', fogLeft.x + fogLeft.width, 0, .2, .6);

			fogRight.setGraphicSize(Std.int(fogLeft.width));
			fogRight.updateHitbox();

			addToStage(clouds);

			addToStage(fogLeft);
			addToStage(fogRight);
		}

		addToStage(sign);
		addToStage(mountains);

		horsePlatform = new BGSprite('hell/rock', 1650, 0, .9, .95);

		horsePlatform.setGraphicSize(Std.int(horsePlatform.width * UPSCALING));
		horsePlatform.updateHitbox();

		horsePlatform.alpha = FlxMath.EPSILON;

		itsAHorse = new Character(0, 0, 'the-horse');
		itsAHorse.scrollFactor.set(horsePlatform.scrollFactor.x, horsePlatform.scrollFactor.y);

		itsAHorse.alpha = FlxMath.EPSILON;

		addToStage(horsePlatform);
		addToStage(itsAHorse);

		addToStage(foreground);
	}

	override function update(elapsed:Float)
	{
		var songPosition:Float = Conductor.songPosition;
		if (fogLeft != null && fogRight != null)
		{
			var time:Float = songPosition / FOG_SPEED;
			var scroll:Float = fogLeft.width * (time % 1);

			fogLeft.x = -scroll;
			fogRight.x = fogLeft.x + fogLeft.width;

			fogLeft.y = -Math.abs(Math.cos((time * 2) % (Math.PI * 2))) * 10;
			fogRight.y = fogLeft.y;
		}
		horsePlatform.offset.y = Math.sin((songPosition / PLATFORM_SPEED) % (Math.PI * 2)) * 50;

		itsAHorse.y = horsePlatform.y - horsePlatform.offset.y - 750;
		itsAHorse.x = horsePlatform.x + ((itsAHorse.width - horsePlatform.width) / 2);

		parent.startCharacterPos(itsAHorse);
		super.update(elapsed);
	}

	override function beatHit(beat:Int)
	{
		parent.charDance(itsAHorse, beat);
		super.beatHit(beat);
	}
}
