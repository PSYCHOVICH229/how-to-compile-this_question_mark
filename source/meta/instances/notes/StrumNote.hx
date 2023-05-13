package meta.instances.notes;

import meta.data.ClientPrefs;
import flixel.animation.FlxAnimation;
import shaders.ColorSwap;
import states.PlayState;
import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class StrumNote extends FlxSprite
{
	private var colorSwap:ColorSwap;
	public var resetAnim:Float = 0;

	private var noteData:Int = 0;
	public var direction:Float = 90;

	public var middleScroll:Bool = false;
	public var downScroll:Bool = false;

	public var coolOffsetX:Float = 0;
	public var coolOffsetY:Float = 0;

	public var sustainReduce:Bool = true;
	public var player:Int = 0;

	public var texture(default, set):String = null;
	public var library:String = null;

	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function new(?x:Float = 0, ?y:Float = 0, leData:Int, player:Int, ?library:String = null)
	{
		colorSwap = new ColorSwap();

		shader = colorSwap.shader;
		noteData = leData;

		this.player = player;
		this.library = library;
		this.noteData = leData;

		super(x, y);

		var skin:String = 'FUNNY_NOTE_assets';
		if (PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1)
			skin = PlayState.SONG.arrowSkin;

		texture = skin; // Load texture and anims
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public inline function playAnim(anim:String, ?force:Bool = false)
	{
		animation.play(anim, force);

		centerOffsets();
		centerOrigin();

		var curAnim:FlxAnimation = animation.curAnim;
		if (curAnim == null || curAnim.name == 'static')
		{
			colorSwap.hue = 0;

			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		}
		else
		{
			if (curAnim != null && curAnim.name == 'confirm')
				centerOrigin();
		}
	}

	public inline function reloadNote()
	{
		var curAnim:FlxAnimation = animation.curAnim;
		var lastAnim:Null<String> = curAnim?.name ?? null;

		frames = Paths.getSparrowAtlas(texture, library);

		animation.addByPrefix('green', 'arrowUP');
		animation.addByPrefix('blue', 'arrowDOWN');

		animation.addByPrefix('purple', 'arrowLEFT');
		animation.addByPrefix('red', 'arrowRIGHT');

		antialiasing = ClientPrefs.getPref('globalAntialiasing');
		setGraphicSize(Note.noteWidth);

		var dir:String = switch (Math.abs(noteData) % 4)
		{
			case 3: 'right';
			case 1: 'down';
			case 2: 'up';

			default: 'left';
		}
		animation.addByPrefix('static', 'arrow' + dir.toUpperCase(), 24, false);

		animation.addByPrefix('confirm', '$dir confirm', 24, false);
		animation.addByPrefix('pressed', '$dir press', 24, false);

		updateHitbox();

		if (lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
		else
		{
			playAnim('static');
		}
	}

	public inline function postAddedToGroup()
	{
		x += Note.noteWidth * (noteData + .5);
		switch (middleScroll && !PlayState.isFNM)
		{
			case true:
				{
					x += ((FlxG.width - (Note.noteWidth * 5)) / 2);
					switch (player)
					{
						case 0:
							{
								// oponet
								var sign:Int = ((Std.int(noteData / 2) - 1) * 2) + 1;
								x += (PlayState.MIDDLESCROLL_PADDING * sign) + (Note.noteWidth * (sign * 2));
							}
					}
				}
			default:
				{
					// this might be hacky
					switch (player)
					{
						case 0 | 1:
							// multiply 5 instead of 4.5 because of this being ADDED . So ts . .5 + 4.5
							x += player * (FlxG.width - (Note.noteWidth * 5));
					}
				}
		}
		ID = noteData;
	}
}
