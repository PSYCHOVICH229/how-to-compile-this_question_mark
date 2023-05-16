package meta.instances;

import openfl.Assets;
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
	private inline static final BOTTOM_CACHE:String = 'SHUTTLE_FOURSOME_FRAME_BOTTOM';
	private inline static final TOP_CACHE:String = 'SHUTTLE_FOURSOME_FRAME_TOP';

	private inline static final GRAPHIC_PATHS:String = 'shuttleman';

	private inline static final INACTIVE_POLLING_RATE:Float = 1 / 24;
	private inline static final POLLING_RATE:Float = INACTIVE_POLLING_RATE * .5;

	private final bottomFrameOutline:FlxSprite;
	private final topFrameOutline:FlxSprite;

	private final bottomGraphic:FlxGraphic;
	private final topGraphic:FlxGraphic;

	private var bottomData:BitmapData;
	private var topData:BitmapData;

	private var bottomMask:FlxSprite;
	private var topMask:FlxSprite;

	public var bottomCharacter:Character;
	public var topCharacter:Character;

	public var type(default, set):Int = -1;

	private var leTweens:Array<FlxTween> = new Array();
	private var poll:Float = -1;

	private var instance:PlayState;
	public function new()
	{
		super();

		active = false;
		instance = PlayState.instance;

		if (ClientPrefs.getPref('lowQuality'))
		{
			trace('shit fart ass quality mode');

			bottomFrameOutline = new FlxSprite(0, FlxG.height).loadGraphic(Paths.image('slice/superbottomprebakewd', GRAPHIC_PATHS));
			topFrameOutline = new FlxSprite().loadGraphic(Paths.image('slice/supertopprebaked', GRAPHIC_PATHS));
		}
		else
		{
			bottomGraphic = Paths.image('slice/superframebottom', GRAPHIC_PATHS);
			topGraphic = Paths.image('slice/superframetop', GRAPHIC_PATHS);

			bottomFrameOutline = new FlxSprite(0, FlxG.height).loadGraphic(Paths.image('slice/superoutlinebottom', GRAPHIC_PATHS));
			topFrameOutline = new FlxSprite().loadGraphic(Paths.image('slice/superoutlinetop', GRAPHIC_PATHS));

			bottomMask = new FlxSprite(0, bottomFrameOutline.y + (bottomFrameOutline.height - bottomGraphic.height));
			topMask = new FlxSprite(0, -topGraphic.height);

			topMask.antialiasing = bottomMask.antialiasing = topFrameOutline.antialiasing = bottomFrameOutline.antialiasing = false;

			bottomMask.scrollFactor.set();
			topMask.scrollFactor.set();

			bottomCharacter = new Character(-95, -100, 'bobfriend-foursome', false);
			topCharacter = new Character(0, 0, 'funnybf', false);

			bottomCharacter.active = topCharacter.active = false;

			var bottomRect:Rectangle = bottomGraphic.bitmap.rect;
			var topRect:Rectangle = topGraphic.bitmap.rect;

			bottomData = new BitmapData(bottomGraphic.width, bottomGraphic.height, true, FlxColor.BLACK);
			topData = new BitmapData(topGraphic.width, topGraphic.height, true, FlxColor.BLACK);

			var bottomMatrix:Matrix = new Matrix();
			bottomMatrix.scale(.85, .85);

			topData.copyPixels(Paths.image('slice/funnyboyside', GRAPHIC_PATHS).bitmap, new Rectangle(0, 75, topRect.width, topRect.height), topRect.topLeft);
			bottomData.draw(Paths.image('slice/bobfriendside', GRAPHIC_PATHS).bitmap, bottomMatrix, null, null, bottomRect, false);

			bottomData.copyChannel(bottomGraphic.bitmap, bottomRect, bottomRect.topLeft, ALPHA, ALPHA);
			topData.copyChannel(topGraphic.bitmap, topRect, topRect.topLeft, ALPHA, ALPHA);

			bottomMask.visible = topMask.visible = false;

			add(bottomMask);
			add(topMask);
		}
		bottomFrameOutline.visible = topFrameOutline.visible = false;

		bottomFrameOutline.scrollFactor.set();
		topFrameOutline.scrollFactor.set();

		topFrameOutline.y = -topFrameOutline.height;

		add(bottomFrameOutline);
		add(topFrameOutline);
	}

	override function destroy()
	{
		bottomCharacter?.destroy();
		topCharacter?.destroy();

		bottomCharacter = null;
		topCharacter = null;

		super.destroy();
	}

	override function update(elapsed:Float)
	{
		if (type >= 0 && topMask != null && bottomMask != null)
		{
			// Limit how often the bitmap is updated since it is not being used for anything crazy
			final pollingRate:Float = if (type >= 1) INACTIVE_POLLING_RATE else POLLING_RATE;
			poll = if (poll < 0) pollingRate else (poll + elapsed);
			if (poll >= pollingRate)
			{
				maskShit(pollingRate, TOP_CACHE, topData, topGraphic.bitmap, topMask, .3, topCharacter);
				if (type >= 1)
					maskShit(pollingRate, BOTTOM_CACHE, bottomData, bottomGraphic.bitmap, bottomMask, .65, bottomCharacter);
				poll %= pollingRate;
			}
		}
		else
		{
			poll = -1;
		}
		super.update(elapsed);
	}

	private inline function maskShit(rate:Float, cache:String, base:BitmapData, bitmap:BitmapData, mask:FlxSprite, scale:Float = 1, ?character:Character = null)
	{
		var data:BitmapData = base.clone();
		// Copy the character
		if (character != null)
		{
			character.update(Math.round(poll / rate) * rate);

			var frame:BitmapData = character.updateFramePixels();
			var matrix:Matrix = null;

			if (scale != 1)
			{
				matrix = new Matrix();

				matrix.scale(scale, scale);
				matrix.translate(character.x + (character.offset.x * (scale - 1)), character.y + (character.offset.y * (scale - 1)));
			}
			data.draw(frame, matrix, null, null,
				new Rectangle(frame.rect.x + matrix.tx, frame.rect.y + matrix.ty, frame.width * scale, frame.height * scale),
				false // !character.noAntialiasing && ClientPrefs.getPref('globalAntialiasing') HUGE PERFORMANCE HIT!!!!!!
			);
			// Finally, copy the alpha channel for the mask effect
			data.copyChannel(bitmap, bitmap.rect, bitmap.rect.topLeft, ALPHA, ALPHA);
		}

		Assets.cache.removeBitmapData(cache);
		FlxG.bitmap.removeByKey(cache);

		if (mask.graphic != null)
			FlxG.bitmap.remove(mask.graphic);

		mask.loadGraphic(data, false, 0, 0, false, cache);
		mask.graphic.persist = false;
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
						topFrameOutline.visible = true;
						if (topMask != null)
						{
							topMask.visible = true;
							pushTween(FlxTween.tween(topMask, {y: 0}, Conductor.crochet / 1000, {ease: FlxEase.quintOut, onComplete: instance.cleanupTween}));
						}
						pushTween(FlxTween.tween(topFrameOutline, {y: 0}, Conductor.crochet / 1000,
							{ease: FlxEase.quintOut, onComplete: instance.cleanupTween}));
					}
				case 1:
					{
						bottomFrameOutline.visible = true;
						if (bottomMask != null)
						{
							bottomMask.visible = true;
							pushTween(FlxTween.tween(bottomMask, {y: FlxG.height - bottomGraphic.height}, Conductor.crochet / 1000,
								{ease: FlxEase.quintOut, onComplete: instance.cleanupTween}));
						}
						pushTween(FlxTween.tween(bottomFrameOutline, {y: FlxG.height - bottomFrameOutline.height}, Conductor.crochet / 1000,
							{ease: FlxEase.quintOut, onComplete: instance.cleanupTween}));
					}

				default:
					{
						this.type = -1;
						for (tween in leTweens)
							cleanupTween(tween);
						if (topMask != null)
						{
							pushTween(FlxTween.tween(topMask, {y: -topGraphic.height}, Conductor.crochet / 500, {
								ease: FlxEase.quintOut,
								onComplete: function(twn:FlxTween)
								{
									topMask.visible = false;
									cleanupTween(twn);
								}
							}));
						}
						if (bottomMask != null)
						{
							pushTween(FlxTween.tween(bottomMask, {y: FlxG.height + (bottomFrameOutline.height - bottomGraphic.height)}, Conductor.crochet / 500, {
								ease: FlxEase.quintOut,
								onComplete: function(twn:FlxTween)
								{
									bottomMask.visible = false;
									cleanupTween(twn);
								}
							}));
						}

						pushTween(FlxTween.tween(topFrameOutline, {y: -topFrameOutline.height}, Conductor.crochet / 500, {
							ease: FlxEase.quintOut,
							onComplete: function(twn:FlxTween)
							{
								topFrameOutline.visible = false;
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
