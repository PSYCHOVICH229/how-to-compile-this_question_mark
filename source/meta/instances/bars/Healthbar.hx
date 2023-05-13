package meta.instances.bars;

import meta.data.Song;
import meta.data.ClientPrefs;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxBar;

class Healthbar extends FlxSpriteGroup
{
	private inline static final barPath:String = 'ui/bars/health';

	public var flipped(default, set):Bool = false;
	public var percent:Float = 0;

	public var opponentColor:Array<Int>;
	public var playerColor:Array<Int>;

	public var bg:AttachedSprite;
	public var bar:FlxBar;

	public var barOffset:Int = 0;
	public var skin:String = '';

	public function new(?skin:String = '')
	{
		super();
		bg = new AttachedSprite();

		add(bg);
		applySkin(skin);
	}

	private function set_flipped(value:Bool):Bool
	{
		if (bar != null)
			bar.fillDirection = value ? LEFT_TO_RIGHT : RIGHT_TO_LEFT;
		return value;
	}

	public function updateHealthColor(?p1Colors:Array<Int>, ?p2Colors:Array<Int>)
	{
		if (p1Colors != null)
			playerColor = p1Colors;
		if (p2Colors != null)
			opponentColor = p2Colors;

		if (bar != null && playerColor != null && opponentColor != null)
		{
			bar.createFilledBar(FlxColor.fromRGB(opponentColor[0], opponentColor[1], opponentColor[2]),
				FlxColor.fromRGB(playerColor[0], playerColor[1], playerColor[2]));
			bar.updateBar();
		}
	}

	public function applySkin(skin:String)
	{
		this.skin = skin;
		if (bar != null)
		{
			bar.kill();
			remove(bar, true);

			bar.destroy();
			bar = null;
		}

		var downScroll:Bool = ClientPrefs.getPref('downScroll');
		var barY:Float = FlxG.height * (downScroll ? .075 : .85);

		barOffset = 0;

		var barDirection:FlxBarFillDirection = flipped ? LEFT_TO_RIGHT : RIGHT_TO_LEFT;
		switch (Paths.formatToSongPath(skin))
		{
			case 'fnm':
				{
					bg.loadGraphic(Paths.image('$barPath/healthBar'));
					barY = FlxG.height * (downScroll ? .11 : .89);

					bar = new FlxBar(0, 0, barDirection, Std.int(bg.width - 8), Std.int(bg.height - 8), this, 'percent', 0, 2);
					bar.numDivisions = 200;

					bg.xAdd = bg.yAdd = -4;
					barOffset = 1;
				}
			case 'relapse':
				{
					bg.loadGraphic(Paths.image('$barPath/hulth_reloper'));

					bar = new FlxBar(0, 0, barDirection, 605, 14, this, 'percent', 0, 2);
					bar.numDivisions = 200;

					bg.xAdd = -15;
					bg.yAdd = -14;
				}
			case 'killgames':
				{
					bg.loadGraphic(Paths.image('$barPath/kill_meter'));

					bar = new FlxBar(0, 0, barDirection, 607, 16, this, 'percent', 0, 2);
					bar.numDivisions = 200;

					bg.xAdd = -16;
					bg.yAdd = -12;
				}

			default:
				{
					bg.loadGraphic(Paths.image('$barPath/hulth_meanther'));

					bar = new FlxBar(0, 0, barDirection, 605, 14, this, 'percent', 0, 2);
					bar.numDivisions = 200;

					bg.xAdd = -15;
					bg.yAdd = -14;
				}
		}
		updateHealthColor();

		bg.y = barY;
		bg.screenCenter(X);

		if (bar != null)
		{
			bar.scrollFactor.set();
			bar.cameras = cameras;

			bar.setPosition(bg.x + ((bg.width - bar.width) / 2), bg.y + ((bg.height - bar.height) / 2));
			bg.sprTracker = bar;

			var index:Int = members.indexOf(bg);
			insert((index >= 0 ? index : 0) + barOffset, bar);
		}
	}
}
