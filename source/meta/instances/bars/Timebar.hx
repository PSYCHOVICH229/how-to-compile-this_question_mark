package meta.instances.bars;

import meta.data.Song;
import meta.data.ClientPrefs;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxBar;

class Timebar extends FlxSpriteGroup
{
	private inline static final barPath:String = 'ui/bars/time';

	private inline static final TEXT_SONG_NAME_SIZE:Int = 24;
	private inline static final TEXT_SIZE:Int = 32;

	public var flashing:Bool = false;

	private var isSongName:Bool = false;

	public var lastColor:Array<Int>;
	// SHUT UP.
	public var emptyColor:FlxColor;
	public var fullColor:FlxColor;

	public var percent:Float = 0;

	public var bg:AttachedSprite;
	public var bar:FlxBar;

	public var txt:FlxText;

	public var timeBarType:String;
	public var skin:String = '';

	public function new(?skin:String = '', ?flashing:Bool = false, timeBarType:String, ?SONG:SwagSong)
	{
		super();
		this.flashing = flashing;

		isSongName = timeBarType == 'song-name';
		txt = new FlxText(0, 0, FlxG.width).setFormat(null, isSongName ? TEXT_SONG_NAME_SIZE : TEXT_SIZE, FlxColor.WHITE, CENTER, OUTLINE);

		txt.scrollFactor.set();
		txt.borderSize = 2;

		if (SONG != null && isSongName)
			txt.text = SONG.song;

		bg = new AttachedSprite();

		add(bg);
		add(txt);

		applySkin(skin);
	}

	public inline function updateTimeColor(?color:Array<Int>)
	{
		if (bar != null)
		{
			if (flashing)
			{
				if (color == null)
					color = lastColor;
				if (color != null)
				{
					lastColor = color;

					bar.createFilledBar(emptyColor, FlxColor.fromRGB(color[0], color[1], color[2]));
					bar.updateBar();
				}
			}
			else
			{
				bar.createFilledBar(emptyColor, fullColor);
				bar.updateBar();
			}
		}
	}

	public inline function applySkin(skin:String)
	{
		this.skin = skin;
		if (bar != null)
		{
			bar.kill();
			remove(bar, true);

			bar.destroy();
			bar = null;
		}

		var skinPath:String = Paths.formatToSongPath(skin);
		switch (skinPath)
		{
			case 'relapse':
				{
					bg.loadGraphic(Paths.image('$barPath/time_lapsed_bar'));
					txt.font = Paths.font('VINERITC.ttf');

					bar = new FlxBar(0, 0, LEFT_TO_RIGHT, 381, 8, this, 'percent', 0, 1);
					bar.numDivisions = 500;

					txt.borderColor = 0xFF6E7582;
					txt.color = 0xFFF0E1F8;

					emptyColor = 0xFFCECECE;
					fullColor = 0xFF202020;

					bg.xAdd = -10;
					bg.yAdd = -8;
				}
			case 'killgames':
				{
					bg.loadGraphic(Paths.image('$barPath/kill_bars'));
					txt.font = Paths.font('squid.ttf');

					bar = new FlxBar(0, 0, LEFT_TO_RIGHT, 382, 9, this, 'percent', 0, 1);
					bar.numDivisions = 500;

					txt.borderColor = 0xFF850909;
					txt.color = 0xFF5C0A17;

					emptyColor = 0xFF2A1B1B;
					fullColor = 0xFF8D1313;

					bg.xAdd = -9;
					bg.yAdd = -8;
				}

			default:
				{
					bg.loadGraphic(Paths.image('$barPath/timeBar'));

					bar = new FlxBar(0, 0, LEFT_TO_RIGHT, 388, 12, this, 'percent', 0, 1);
					bar.numDivisions = 500;

					txt.font = Paths.font('comic.ttf');

					txt.borderColor = 0xFF001E02;
					txt.color = FlxColor.WHITE;

					emptyColor = 0xFFD6F4FF;
					fullColor = 0xFF99FFA8;

					bg.xAdd = -4;
					bg.yAdd = -7;
				}
		}
		updateTimeColor();

		bg.y = (ClientPrefs.getPref('downScroll') ? (FlxG.height - 45) : 8) + ((TEXT_SIZE - bg.height) / 2);
		bg.screenCenter(X);

		txt.x = bg.x + ((bg.width - txt.fieldWidth) / 2);
		txt.y = bg.y - (txt.size / 2) + switch (skinPath)
		{
			case 'killgames': 8;
			default: 4;
		};

		if (bar != null)
		{
			bar.scrollFactor.set();
			bar.cameras = cameras;

			bar.setPosition(bg.x + ((bg.width - bar.width) / 2), bg.y + ((bg.height - bar.height) / 2));
			bg.sprTracker = bar;

			var index:Int = members.indexOf(bg);
			insert(index >= 0 ? index : 0, bar);
		}
	}
}
