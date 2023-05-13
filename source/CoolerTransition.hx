package;

import meta.data.Song.SwagSong;
import states.PlayState;
import flixel.text.FlxText;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import states.MusicBeatState;
import meta.data.ClientPrefs;
import flixel.util.FlxTimer;
import states.substates.MusicBeatSubstate;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class CoolerTransition extends MusicBeatSubstate
{
	public inline static final BACKGROUND_COLOR:FlxColor = 0xFF191628;
	private inline static final SHAKE_AMOUNT:Float = 12;

	private inline static final SPRITE_SCALING:Float = 1.2;
	private inline static final TWEEN_DURATION:Float = .6;

	public static var silent:Bool = false;
	private static var stopwatch:Float = 0;

	private var tweenArray:Array<FlxTween> = new Array();
	private var leTimer:FlxTimer;

	private var isTransIn:Bool = false;

	private var transitionGroup:FlxSpriteGroup;
	private var transitionCamera:FlxCamera;

	private var background:FlxBackdrop;

	public function new(isTransIn:Bool)
	{
		super();
		this.isTransIn = isTransIn;

		transitionCamera = new FlxCamera();
		transitionCamera.bgColor = FlxColor.TRANSPARENT;

		transitionCamera.zoom = 1;
		FlxG.cameras.add(transitionCamera, false);

		var height:Int = FlxG.height;
		var width:Int = FlxG.width;

		transitionGroup = new FlxSpriteGroup();

		var transBottom:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/transition/barBottom'));
		var textBottom:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/transition/textBottom'));

		var transTop:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/transition/barTop'));
		var textTop:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/transition/textTop'));

		var microphone:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/transition/microphone'));
		var staticOverlay:FlxSprite = new FlxSprite().loadGraphic(Paths.image('arcade/static'), true, Std.int(width / 4), Std.int(height / 4));

		var loadingText:FlxText = new FlxText(0, 0, width, 'loading').setFormat(Paths.font('vcr.ttf'), 42, 0xFF400B78, CENTER, OUTLINE, 0xFF7910A0);

		staticOverlay.animation.add('static', [0, 1, 2, 3], 24, true);
		staticOverlay.animation.play('static', true);

		staticOverlay.scrollFactor.set();
		background = new FlxBackdrop(Paths.image('ui/transition/tile'), XY);

		background.scrollFactor.set(1, 1);
		background.alpha = 0;

		transBottom.screenCenter();
		textBottom.screenCenter();

		transTop.screenCenter();
		textTop.screenCenter();

		loadingText.screenCenter();
		microphone.screenCenter();

		loadingText.y += 280;

		transBottom.x += 99 * SPRITE_SCALING;
		transBottom.y += 65 * SPRITE_SCALING;

		transTop.x -= 51 * SPRITE_SCALING;
		transTop.y -= 96 * SPRITE_SCALING;

		textBottom.x += 117 * SPRITE_SCALING;
		textBottom.y += 62 * SPRITE_SCALING;

		textTop.x -= 59 * SPRITE_SCALING;
		textTop.y -= 112 * SPRITE_SCALING;

		microphone.x -= 206 * SPRITE_SCALING;
		microphone.y -= 28 * SPRITE_SCALING;

		transBottom.y -= 30;
		transTop.y -= 30;

		textBottom.y -= 30;
		textTop.y -= 30;

		microphone.y -= 30;
		if (isTransIn)
		{
			if (!silent)
				FlxG.sound.play(Paths.sound('transition/transitionOut'));
			silent = false;
			MusicBeatState.coolerTransition = false;

			var transBG:FlxSprite = new FlxSprite().makeGraphic(width, height, BACKGROUND_COLOR);
			CustomFadeTransition.doTitleShit();

			transBG.scrollFactor.set();
			transBG.alpha = 1;

			loadingText.alpha = .5;

			background.alpha = .4;
			staticOverlay.alpha = .05;

			tweenArray.push(FlxTween.tween(loadingText, {alpha: 0}, TWEEN_DURATION, {ease: FlxEase.quadIn}));

			tweenArray.push(FlxTween.tween(transBG, {alpha: 0}, TWEEN_DURATION, {ease: FlxEase.quadIn}));
			tweenArray.push(FlxTween.tween(background, {alpha: 0}, TWEEN_DURATION, {ease: FlxEase.quadIn}));
			tweenArray.push(FlxTween.tween(staticOverlay, {alpha: 0}, TWEEN_DURATION, {ease: FlxEase.quadIn}));

			tweenArray.push(FlxTween.tween(transBottom, {y: transBottom.y + height + transBottom.height}, TWEEN_DURATION, {ease: FlxEase.backIn}));
			tweenArray.push(FlxTween.tween(transTop, {y: transTop.y + height + transTop.height}, TWEEN_DURATION, {ease: FlxEase.backIn}));

			tweenArray.push(FlxTween.tween(textBottom, {y: textBottom.y + height + textBottom.height}, TWEEN_DURATION, {ease: FlxEase.backIn}));
			tweenArray.push(FlxTween.tween(textTop, {y: textTop.y + height + textTop.height}, TWEEN_DURATION, {ease: FlxEase.backIn}));

			tweenArray.push(FlxTween.tween(microphone, {y: microphone.y + height + microphone.height}, TWEEN_DURATION, {ease: FlxEase.backIn}));
			leTimer = new FlxTimer().start(TWEEN_DURATION, function(tmr:FlxTimer)
			{
				close();
			});

			transBG.cameras = [transitionCamera];
			transitionGroup.add(transBG);
		}
		else
		{
			if (!silent)
				FlxG.sound.play(Paths.sound('transition/transitionIn'));

			var bgHeight:Int = Std.int(height / 2) + 1;

			var bgBottom:FlxSprite = new FlxSprite(0, height * SPRITE_SCALING).makeGraphic(width, bgHeight, BACKGROUND_COLOR);
			var bgTop:FlxSprite = new FlxSprite(0, -bgHeight * SPRITE_SCALING).makeGraphic(width, bgHeight, BACKGROUND_COLOR);

			loadingText.alpha = 0;

			bgBottom.scrollFactor.set();
			bgTop.scrollFactor.set();

			var transBottomY:Float = transBottom.y;
			var transTopY:Float = transTop.y;

			var textBottomY:Float = textBottom.y;
			var textTopY:Float = textTop.y;

			transBottom.y += height + transBottom.height;
			transTop.y -= height + transTop.height;

			textBottom.y += height + textBottom.height;
			textTop.y -= height + textTop.height;

			staticOverlay.alpha = 0;
			microphone.alpha = 0;
			// this fucking sucks
			// bars
			tweenArray.push(FlxTween.tween(transBottom, {y: transBottomY + 30}, TWEEN_DURATION, {
				ease: FlxEase.cubeIn,
				onComplete: function(twn:FlxTween)
				{
					tweenArray.push(FlxTween.tween(transBottom, {y: transBottomY + 50}, TWEEN_DURATION / 2, {
						ease: FlxEase.sineOut,
						onComplete: function(twn:FlxTween)
						{
							var micX:Float = microphone.x;
							var micY:Float = microphone.y;

							microphone.x += 240;
							microphone.y += 120;

							tweenArray.push(FlxTween.tween(microphone, {alpha: 1}, TWEEN_DURATION / 3, {ease: FlxEase.sineOut}));
							tweenArray.push(FlxTween.tween(microphone, {x: micX, y: micY}, TWEEN_DURATION / 2, {ease: FlxEase.sineOut}));

							tweenArray.push(FlxTween.tween(transBottom, {y: transBottomY}, TWEEN_DURATION / 2, {ease: FlxEase.sineIn}));
							tweenArray.push(FlxTween.tween(loadingText, {alpha: .5}, TWEEN_DURATION / 2, {ease: FlxEase.sineIn}));
						}
					}));
				}
			}));
			tweenArray.push(FlxTween.tween(transTop, {y: transTopY + 30}, TWEEN_DURATION, {
				ease: FlxEase.cubeIn,
				onComplete: function(twn:FlxTween)
				{
					tweenArray.push(FlxTween.tween(transTop, {y: transTopY + 10}, TWEEN_DURATION / 2, {
						ease: FlxEase.sineOut,
						onComplete: function(twn:FlxTween)
						{
							tweenArray.push(FlxTween.tween(transTop, {y: transTopY}, TWEEN_DURATION / 2, {ease: FlxEase.sineIn}));
						}
					}));
				}
			}));
			// text
			tweenArray.push(FlxTween.tween(textBottom, {y: textBottomY + 30}, TWEEN_DURATION, {
				ease: FlxEase.cubeIn,
				onComplete: function(twn:FlxTween)
				{
					tweenArray.push(FlxTween.tween(textBottom, {y: textBottomY + 50}, TWEEN_DURATION / 2, {
						ease: FlxEase.sineOut,
						onComplete: function(twn:FlxTween)
						{
							tweenArray.push(FlxTween.tween(textBottom, {y: textBottomY}, TWEEN_DURATION / 2, {ease: FlxEase.sineIn}));
						}
					}));
				}
			}));
			tweenArray.push(FlxTween.tween(textTop, {y: textTopY + 30}, TWEEN_DURATION, {
				ease: FlxEase.cubeIn,
				onComplete: function(twn:FlxTween)
				{
					tweenArray.push(FlxTween.tween(textTop, {y: textTopY + 10}, TWEEN_DURATION / 2, {
						ease: FlxEase.sineOut,
						onComplete: function(twn:FlxTween)
						{
							tweenArray.push(FlxTween.tween(textTop, {y: textTopY}, TWEEN_DURATION / 2, {ease: FlxEase.sineIn}));
						}
					}));
				}
			}));
			// bg
			tweenArray.push(FlxTween.tween(bgBottom, {y: height - (bgHeight * SPRITE_SCALING)}, TWEEN_DURATION, {ease: FlxEase.cubeIn}));
			tweenArray.push(FlxTween.tween(bgTop, {y: bgHeight - (bgHeight * SPRITE_SCALING)}, TWEEN_DURATION, {ease: FlxEase.cubeIn}));

			tweenArray.push(FlxTween.tween(staticOverlay, {alpha: .05}, TWEEN_DURATION, {ease: FlxEase.quadIn}));
			// other shit
			for (nextCamera in FlxG.cameras.list)
			{
				if (nextCamera != transitionCamera)
					tweenArray.push(FlxTween.tween(nextCamera, {zoom: nextCamera.zoom + .15}, TWEEN_DURATION, {ease: FlxEase.cubeIn}));
			}
			tweenArray.push(FlxTween.tween(transitionCamera, {zoom: 1.25}, TWEEN_DURATION, {
				ease: FlxEase.cubeIn,
				onComplete: function(twn:FlxTween)
				{
					transitionCamera.bgColor = BACKGROUND_COLOR;
					new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
					{
						if (tmr.loopsLeft <= 0)
						{
							transitionCamera.scroll.set();
						}
						else
						{
							transitionCamera.scroll.set(FlxG.random.float(-SHAKE_AMOUNT, SHAKE_AMOUNT), FlxG.random.float(-SHAKE_AMOUNT, SHAKE_AMOUNT));
						}
					}, 15);

					tweenArray.push(FlxTween.tween(background, {alpha: .4}, TWEEN_DURATION, {ease: FlxEase.cubeOut}));
					tweenArray.push(FlxTween.tween(transitionCamera, {zoom: 1}, TWEEN_DURATION, {ease: FlxEase.backIn}));
				}
			}));
			leTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				var song:SwagSong = PlayState.SONG;
				if (song != null)
					PlayState.cacheShitForSong(song);
				if (CustomFadeTransition.finishCallback != null)
				{
					CustomFadeTransition.finishCallback();
					CustomFadeTransition.finishCallback = null;
				}
			});

			transitionGroup.add(bgBottom);
			transitionGroup.add(bgTop);
		}

		transitionGroup.add(background);
		transitionGroup.add(microphone);

		transitionGroup.add(transBottom);
		transitionGroup.add(textBottom);

		transitionGroup.add(transTop);
		transitionGroup.add(textTop);

		transitionGroup.add(loadingText);
		transitionGroup.add(staticOverlay);

		transitionGroup.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		transitionGroup.scale.x = transitionGroup.scale.y = SPRITE_SCALING;

		// transitionGroup.scrollFactor.set(1, 1);
		transitionGroup.cameras = [transitionCamera];

		staticOverlay.setGraphicSize(width, height);
		staticOverlay.updateHitbox();

		staticOverlay.screenCenter();
		CustomFadeTransition.nextCamera = null;

		add(transitionGroup);
	}

	override function update(elapsed:Float)
	{
		stopwatch = (stopwatch + elapsed) % 1;
		background.x = background.y = stopwatch * 180 * SPRITE_SCALING;

		super.update(elapsed);
	}

	override function destroy()
	{
		if (!isTransIn && CustomFadeTransition.finishCallback != null)
		{
			CustomFadeTransition.finishCallback();
			CustomFadeTransition.finishCallback = null;
		}
		if (leTimer != null)
		{
			leTimer.cancel();
			leTimer.destroy();

			leTimer = null;
		}
		if (tweenArray != null)
		{
			for (tween in tweenArray)
			{
				tween.cancel();
				tween.destroy();
			}
			tweenArray = null;
		}
		super.destroy();
	}
}
