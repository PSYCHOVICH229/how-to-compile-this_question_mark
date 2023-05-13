#if FLX_SOUND_SYSTEM
package flixel.system.ui;

import meta.data.ClientPrefs;
import flixel.util.FlxSave;
import flixel.math.FlxMath;
import openfl.Assets;
import flixel.FlxG;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 */
class FlxSoundTray extends Sprite
{
	/**
	 * Because reading any data from DisplayObject is insanely expensive in hxcpp, keep track of whether we need to update it or not.
	 */
	public var active:Bool;

	/**
	 * Helps us auto-hide the sound tray after a volume change.
	 */
	private var _timer:Float = -1;

	/**
	 * The volume bar on the sound tray.
	 */
	private var _overlay:Bitmap;

	private var _funny:Bitmap;

	private var _bar:Bitmap;

	/**
	 * How wide the sound tray background is.
	 */
	private var _width:Int = 0;

	private var _tweenTime:Float = 1 / 700 / 60;

	private inline static final _defaultScaleBase:Float = 2;

	private var _defaultScale:Float = _defaultScaleBase;

	/**Whether or not changing the volume should make noise.**/
	private var _active:Bool = false;

	public var silent:Bool = false;

	private var barThickness:Int = 2;

	/**
	 * Sets up the "sound tray", the little volume meter that pops down sometimes.
	 */
	@:keep
	public function new()
	{
		super();

		visible = false;
		active = true;

		var meter:Bitmap = new Bitmap(Assets.getBitmapData(Paths.getPreloadPath('images/ui/guhmeter.png')));
		screenCenter();

		_width = Std.int(meter.width);
		_bar = new Bitmap(new BitmapData(Std.int(meter.width * .9), Std.int(meter.height * .1), false, 0xFFFFFFFF));

		_bar.x = meter.x + ((meter.width - _bar.width) / 2);
		_bar.y = meter.y + (_bar.height * 2) + (2 * scaleX);

		_overlay = new Bitmap(new BitmapData(Std.int(_bar.width), Std.int(_bar.height), false, 0xFF42CDFF));

		_overlay.x = _bar.x;
		_overlay.y = _bar.y;

		_overlay.scaleX = 0;
		// funny boy iocn
		_funny = new Bitmap(Assets.getBitmapData(Paths.getPreloadPath('images/ui/tiny.png')));
		_funny.y = _overlay.y + ((_overlay.height - _funny.height) / 2);
		// gay ass shit fart ass outline
		var outline:Bitmap = new Bitmap(new BitmapData(Std.int(_bar.width + (barThickness * scaleX)), Std.int(_bar.height + (barThickness * scaleY)), false,
			0xFF000000));

		outline.y = _bar.y + ((_bar.height - outline.height) / 2);
		outline.x = _bar.x + ((_bar.width - outline.width) / 2);

		addChild(meter);

		addChild(outline);
		addChild(_bar);

		addChild(_overlay);
		addChild(_funny);

		y = -height;
	}

	/**
	 * This function just updates the sound tray object.
	 */
	public function update(MS:Float):Void
	{
		screenCenter();

		var elapsed:Float = MS / 1000;
		var tweenTime:Float = 1 - Math.pow(_tweenTime, elapsed);

		var scaled:Float = FlxG.sound.muted ? 0 : FlxG.sound.volume;
		// the dick
		if (_timer > 0)
		{
			alpha = Math.min(alpha + (elapsed * 4), 1);
			y = FlxMath.lerp(y, 0, tweenTime);

			_overlay.scaleX = FlxMath.lerp(_overlay.scaleX, scaled, tweenTime);
			updateFunny();

			_timer -= elapsed;
		}
		else
		{
			if (_active)
			{
				alpha = Math.max(alpha - (elapsed * 4), 0);
				y = FlxMath.lerp(y, -height, tweenTime);

				visible = active = _active = alpha > 0;
				return;
			}
			_overlay.scaleX = scaled;
		}
	}

	private inline function updateFunny():Void
		_funny.x = (_overlay.x + (_bar.width * _overlay.scaleX)) - (_funny.width / 2);

	/**
	 * Makes the little volume tray slide out.
	 *
	 * @param	up Whether the volume is increasing.
	 */
	public inline function show(up:Bool = false):Void
	{
		if (!silent)
			FlxG.sound.play(Paths.sound('cuh'), 1, false);
		updateFunny();

		_timer = 1;
		_active = true;

		visible = true;
		active = true;
		// Save sound preferences
		var save:FlxSave = FlxG.save;
		if (save != null)
		{
			var data:Dynamic = save.data;

			data.volume = FlxG.sound.volume;
			data.mute = FlxG.sound.muted;

			ClientPrefs.saveSettings();
		}
	}

	public inline function screenCenter():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		// scale to fullscreen aswell
		_defaultScale = (stageWidth / 1280) * _defaultScaleBase;

		scaleX = _defaultScale;
		scaleY = _defaultScale;

		x = ((stageWidth - _width * _defaultScale) - FlxG.game.x) / 2;
	}
}
#end
