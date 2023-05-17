package;

import flixel.math.FlxMath;
import states.TitleState;
import states.substates.MusicBeatSubstate;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;

class CustomFadeTransition extends MusicBeatSubstate
{
	public static var playTitleMusic:Bool = false;

	public static var finishCallback:Void->Void;
	public static var nextCamera:FlxCamera;

	private var leTween:FlxTween = null;
	private var isTransIn:Bool = false;

	private var transGradient:FlxSprite;
	private var transBlack:FlxSprite;

	public function new(duration:Float, isTransIn:Bool)
	{
		super();
		this.isTransIn = isTransIn;

		var zoom:Float = FlxMath.bound(FlxG.camera.zoom, 1 / 100, 1);

		var height:Int = Std.int(FlxG.height / zoom) + 1;
		var width:Int = Std.int(FlxG.width / zoom) + 1;

		transGradient = FlxGradient.createGradientFlxSprite(width, height, (isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]));
		transBlack = new FlxSprite().makeGraphic(width, height + 400, FlxColor.BLACK);

		transGradient.scrollFactor.set();
		transBlack.scrollFactor.set();

		transBlack.x = transGradient.x -= (width - FlxG.width) / 2;

		add(transGradient);
		add(transBlack);

		if (isTransIn)
		{
			doTitleShit();

			transGradient.y = transBlack.y - transBlack.height;
			leTween = FlxTween.tween(transGradient, {y: transGradient.height + 50}, duration, {
				onComplete: function(twn:FlxTween)
				{
					close();
				},
				ease: FlxEase.linear
			});
		}
		else
		{
			transBlack.y = (transGradient.y = -transGradient.height) - transBlack.height + 50;
			leTween = FlxTween.tween(transGradient, {y: transGradient.height + 50}, duration, {
				onComplete: function(twn:FlxTween)
				{
					if (finishCallback != null)
					{
						finishCallback();
						finishCallback = null;
					}
				},
				ease: FlxEase.linear
			});
		}

		if (nextCamera != null)
			transBlack.cameras = transGradient.cameras = [nextCamera];
		nextCamera = null;
	}

	public inline static function doTitleShit()
	{
		if (playTitleMusic)
		{
			TitleState.playTitleMusic(0);
			FlxG.sound.music?.fadeIn(1, 0, 1);

			playTitleMusic = false;
		}
	}

	override function update(elapsed:Float)
	{
		if (isTransIn)
		{
			transBlack.y = transGradient.y + transGradient.height;
		}
		else
		{
			transBlack.y = transGradient.y - transBlack.height;
		}
		super.update(elapsed);
	}

	override function destroy()
	{
		if (!isTransIn && finishCallback != null)
		{
			finishCallback();
			finishCallback = null;
		}
		if (leTween != null)
		{
			leTween.cancel();
			leTween.destroy();

			leTween = null;
		}
		super.destroy();
	}
}
