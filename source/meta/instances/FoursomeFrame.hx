package meta.instances;

import meta.data.ClientPrefs;
import flixel.group.FlxGroup;
import openfl.geom.Matrix;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import states.PlayState;
import openfl.geom.Rectangle;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.FlxSprite;

class FoursomeFrame extends FlxGroup
{
	private inline static final GRAPHIC_PATHS:String = 'shuttleman';

	private inline static final INACTIVE_POLLING_RATE:Float = 1 / 24;
	private inline static final POLLING_RATE:Float = INACTIVE_POLLING_RATE * .5;

	private var leTweens:Array<FlxTween> = new Array();

	private final bottomGraphic:FlxGraphic = Paths.image('slice/superframebottom', GRAPHIC_PATHS);
	private final topGraphic:FlxGraphic = Paths.image('slice/superframetop', GRAPHIC_PATHS);

	private final bottomBackground:FlxGraphic = Paths.image('slice/bobfriendside', GRAPHIC_PATHS);
	private final topBackground:FlxGraphic = Paths.image('slice/funnyboyside', GRAPHIC_PATHS);

	private var bottomFrameOutline:FlxSprite;
	private var topFrameOutline:FlxSprite;

	private var bottomData:BitmapData;
	private var topData:BitmapData;

	private var bottomMask:FlxSprite;
	private var topMask:FlxSprite;

	public var bottomCharacter:Character;
	public var topCharacter:Character;

	public var type(default, set):Int = -1;

	private var poll:Float = -1;

	private var instance:PlayState;

	public function new()
	{
		super();

		active = false;
		instance = PlayState.instance;

		bottomFrameOutline = new FlxSprite(0, FlxG.height).loadGraphic(Paths.image('slice/superoutlinebottom', GRAPHIC_PATHS));
		topFrameOutline = new FlxSprite().loadGraphic(Paths.image('slice/superoutlinetop', GRAPHIC_PATHS));

		bottomFrameOutline.scrollFactor.set();
		topFrameOutline.scrollFactor.set();

		topFrameOutline.y = -topFrameOutline.height;

		bottomMask = new FlxSprite(0,
			bottomFrameOutline.y + (bottomFrameOutline.height - bottomGraphic.height)).makeGraphic(bottomGraphic.width, bottomGraphic.height, FlxColor.WHITE,
				true);
		topMask = new FlxSprite(0, -topGraphic.height).makeGraphic(topGraphic.width, topGraphic.height, FlxColor.WHITE, true);

		topMask.antialiasing = bottomMask.antialiasing = topFrameOutline.antialiasing = bottomFrameOutline.antialiasing = false;

		bottomMask.scrollFactor.set();
		topMask.scrollFactor.set();

		bottomCharacter = new Character(-95, -100, 'bobfriend-foursome', false);
		topCharacter = new Character(0, 0, 'funnybf', false);

		FlxG.bitmap.add(bottomCharacter.graphic);
		FlxG.bitmap.add(topCharacter.graphic);

		bottomCharacter.active = topCharacter.active = false;

		var bottomRect:Rectangle = bottomGraphic.bitmap.rect;
		var topRect:Rectangle = topGraphic.bitmap.rect;

		bottomData = new BitmapData(bottomGraphic.width, bottomGraphic.height, true, FlxColor.BLACK);
		topData = new BitmapData(topGraphic.width, topGraphic.height, true, FlxColor.BLACK);

		var bottomMatrix:Matrix = new Matrix();

		bottomMatrix.scale(.85, .85);
		bottomData.draw(bottomBackground.bitmap, bottomMatrix, null, null, bottomRect, false);
		bottomData.copyChannel(bottomGraphic.bitmap, bottomRect, bottomRect.topLeft, ALPHA, ALPHA);
		topData.copyPixels(topBackground.bitmap, new Rectangle(0, 75, topRect.width, topRect.height), topRect.topLeft);
		topData.copyChannel(topGraphic.bitmap, topRect, topRect.topLeft, ALPHA, ALPHA);
		bottomMask.visible = topMask.visible = bottomFrameOutline.visible = topFrameOutline.visible = false;

		add(bottomMask);
		add(topMask);

		add(bottomFrameOutline);
		add(topFrameOutline);
	}

	override function destroy()
	{
		if (topCharacter != null)
		{
			topCharacter.destroy();
			topCharacter = null;
		}
		if (bottomCharacter != null)
		{
			bottomCharacter.destroy();
			bottomCharacter = null;
		}
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		if (type >= 0)
		{
			// Limit how often the bitmap is updated since it is not being used for anything crazy
			final pollingRate:Float = type >= 1 ? INACTIVE_POLLING_RATE : POLLING_RATE;
			poll = (poll < 0) ? pollingRate : (poll + elapsed);
			if (poll >= pollingRate)
			{
				maskShit(pollingRate, topData, topGraphic, topMask, .3, topCharacter);
				if (type >= 1)
					maskShit(pollingRate, bottomData, bottomGraphic, bottomMask, .65, bottomCharacter);
				poll %= pollingRate;
			}
		}
		else
		{
			poll = -1;
		}
		super.update(elapsed);
	}

	private inline function maskShit(rate:Float, data:BitmapData, graphic:FlxGraphic, mask:FlxSprite, downscale:Float = 1, ?character:Character = null)
	{
		mask.pixels.lock();

		mask.pixels.image.dirty = true;
		mask.graphic.persist = false;

		mask.pixels.disposeImage();
		mask.pixels.dispose();

		mask.graphic.dump();
		mask.graphic.destroy();

		FlxG.bitmap.remove(mask.graphic);

		var maskData:BitmapData = data.clone();
		var bitmap:BitmapData = graphic.bitmap;
		// Copy the character
		if (character != null)
		{
			character.update(Math.round(poll / rate) * rate);

			var framePixels:BitmapData = character.updateFramePixels();
			var matrix:Matrix = new Matrix();

			matrix.scale(downscale, downscale);
			matrix.translate(character.x + (character.offset.x * (downscale - 1)), character.y + (character.offset.y * (downscale - 1)));

			maskData.draw(framePixels, matrix, null, null,
				new Rectangle(framePixels.rect.x + matrix.tx, framePixels.rect.y + matrix.ty, framePixels.width * downscale, framePixels.height * downscale),
				false // !character.noAntialiasing && ClientPrefs.getPref('globalAntialiasing') HUGE PERFORMANCE HIT!!!!!!
			);
			// Finally, copy the alpha channel for the mask effect
			maskData.copyChannel(bitmap, bitmap.rect, bitmap.rect.topLeft, ALPHA, ALPHA);
		}
		mask.loadGraphic(maskData);
	}

	private inline function pushTween(twn:FlxTween)
	{
		leTweens.push(twn);
		instance.modchartTweens.push(twn);
	}

	private inline function cleanupTween(twn:FlxTween)
	{
		if (leTweens.contains(twn))
			leTweens.remove(twn);
		instance.cleanupTween(twn);
	}

	private function set_type(type:Int):Int
	{
		if (this.type != type)
		{
			this.type = type;
			switch (type)
			{
				case 0:
					{
						topMask.visible = topFrameOutline.visible = true;

						pushTween(FlxTween.tween(topMask, {y: 0}, Conductor.crochet / 1000, {ease: FlxEase.quintOut, onComplete: instance.cleanupTween}));
						pushTween(FlxTween.tween(topFrameOutline, {y: 0}, Conductor.crochet / 1000,
							{ease: FlxEase.quintOut, onComplete: instance.cleanupTween}));
					}
				case 1:
					{
						bottomMask.visible = bottomFrameOutline.visible = true;

						pushTween(FlxTween.tween(bottomMask, {y: FlxG.height - bottomGraphic.height}, Conductor.crochet / 1000,
							{ease: FlxEase.quintOut, onComplete: instance.cleanupTween}));
						pushTween(FlxTween.tween(bottomFrameOutline, {y: FlxG.height - bottomFrameOutline.height}, Conductor.crochet / 1000,
							{ease: FlxEase.quintOut, onComplete: instance.cleanupTween}));
					}

				default:
					{
						this.type = -1;
						for (tween in leTweens)
							cleanupTween(tween);
						pushTween(FlxTween.tween(topMask, {y: -topGraphic.height}, Conductor.crochet / 500, {
							ease: FlxEase.quintOut,
							onComplete: function(twn:FlxTween)
							{
								topMask.visible = false;
								cleanupTween(twn);
							}
						}));
						pushTween(FlxTween.tween(topFrameOutline, {y: -topFrameOutline.height}, Conductor.crochet / 500, {
							ease: FlxEase.quintOut,
							onComplete: function(twn:FlxTween)
							{
								topFrameOutline.visible = false;
								cleanupTween(twn);
							}
						}));

						pushTween(FlxTween.tween(bottomMask, {y: FlxG.height + (bottomFrameOutline.height - bottomGraphic.height)}, Conductor.crochet / 500, {
							ease: FlxEase.quintOut,
							onComplete: function(twn:FlxTween)
							{
								bottomMask.visible = false;
								cleanupTween(twn);
							}
						}));
						pushTween(FlxTween.tween(bottomFrameOutline, {y: FlxG.height}, Conductor.crochet / 500, {
							ease: FlxEase.quintOut,
							onComplete: function(twn:FlxTween)
							{
								bottomFrameOutline.visible = false;
								cleanupTween(twn);
							}
						}));
					}
			}
		}
		return type;
	}

	public function dance(beat:Int)
	{
		if (topCharacter != null && (type >= 0))
			instance.charDance(topCharacter, beat);
		if (bottomCharacter != null && (type >= 1))
			instance.charDance(bottomCharacter, beat);
	}
}
