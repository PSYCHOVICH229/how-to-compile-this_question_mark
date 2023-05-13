package meta.instances.notes;

import meta.data.Song.SwagSong;
import meta.data.ClientPrefs;
import flixel.animation.FlxAnimation;
import states.editors.ChartingState;
import states.PlayState;
import flixel.FlxG;
import flixel.FlxSprite;
import shaders.ColorSwap;

using StringTools;

typedef EventNote =
{
	strumTime:Float,
	event:String,

	value1:String,
	value2:String
}

class Note extends FlxSprite
{
	public inline static final noteWidth:Int = 112; // 160 * .7

	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;

	public var canBeHit:Bool = false;

	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;

	public var prevNote:Note;
	public var nextNote:Note;

	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;

	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var colorSwap:ColorSwap;

	public var inEditor:Bool = false;
	public var gfNote:Bool = false;

	public var animSuffix:String = '';

	public var earlyHitMult:Float = .5;
	public var lateHitMult:Float = 1;

	public var lowPriority:Bool = false;

	private var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];

	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;

	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public var offsetAngle:Float = 0;

	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;

	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = .023;
	public var missHealth:Float = .0475;

	public var rating:String = 'unknown';

	public var ratingMod:Float = 0; // 9 = unknown, .25 = shit, .5 = bad, .75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;
	public var library:String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;

	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; // plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var isFNM:Bool = false;

	private function set_multSpeed(value:Float):Float
	{
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		// trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) // haha funny twitter shit
	{
		if (isSustainNote && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String
	{
		if (texture != value)
			reloadNote('', value);

		texture = value;
		return value;
	}

	private function set_noteType(value:String):String
	{
		noteSplashTexture = PlayState.SONG.splashSkin;
		if (noteData >= 0 && noteType != value)
		{
			if (!isSustainNote)
				earlyHitMult = 1;
			switch (Paths.formatToSongPath(value))
			{
				case 'alt-animation':
					animSuffix = '-alt';
				case 'horse-cheese-note':
					{
						ignoreNote = true;
						lowPriority = true;

						texture = "horse_cheese_notes";

						colorSwap.hue = 0;
						colorSwap.saturation = 0;
						colorSwap.brightness = 0;

						noteSplashDisabled = true;
						lateHitMult = 1;

						earlyHitMult = .3;
						lateHitMult = .4;

						hitCausesMiss = !isSustainNote;
					}
				case 'trickynote':
					{
						ignoreNote = true;
						lowPriority = true;

						library = 'clown';
						texture = "ALL_deathnotes";

						colorSwap.hue = 0;
						colorSwap.saturation = 0;
						colorSwap.brightness = 0;

						noteSplashDisabled = true;
						lateHitMult = 1;

						earlyHitMult = .2;
						lateHitMult = .3;

						hitCausesMiss = !isSustainNote;
					}

				case 'no-animation':
					{
						noAnimation = true;
						noMissAnimation = true;
					}
			}
			noteType = value;
		}

		noteSplashHue = colorSwap.hue;
		noteSplashSat = colorSwap.saturation;
		noteSplashBrt = colorSwap.brightness;

		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?library:String = null)
	{
		super(0, FlxG.height);
		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		this.library = library;

		isSustainNote = sustainNote;

		this.inEditor = inEditor;
		this.strumTime = strumTime;

		if (!inEditor)
			this.strumTime += ClientPrefs.getPref('noteOffset');

		this.noteData = noteData;
		if (noteData > -1)
		{
			texture = '';

			colorSwap = new ColorSwap();
			shader = colorSwap.shader;

			if (!isSustainNote)
				animation.play(colArray[noteData % 4] + 'Scroll');
		}

		if (prevNote != null)
			prevNote.nextNote = this;
		if (isSustainNote && prevNote != null)
		{
			hitsoundDisabled = true;

			multAlpha = .6;
			alpha = multAlpha;

			if (ClientPrefs.getPref('downScroll'))
				flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(colArray[noteData % 4] + 'holdend');

			updateHitbox();
			offsetX -= width / 2;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colArray[prevNote.noteData % 4] + 'hold');
				prevNote.scale.y *= (Conductor.stepCrochet / 100) * 1.05;

				if (PlayState.instance != null)
					prevNote.scale.y *= PlayState.instance.songSpeed;
				prevNote.updateHitbox();
			}
		}
	}

	public inline function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '')
	{
		var song:SwagSong = PlayState.SONG;
		var skin:String = texture;

		if (skin.length < 1 && song != null)
		{
			skin = song.arrowSkin;
			if (skin == null || skin.length < 1)
				skin = 'FUNNY_NOTE_assets';
		}

		var curAnim:FlxAnimation = animation.curAnim;
		var animName:String = curAnim?.name ?? null;

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length - 1] = prefix + arraySkin[arraySkin.length - 1] + suffix;

		var lastScaleY:Float = scale.y;
		var blahblah:String = arraySkin.join('/');

		frames = Paths.getSparrowAtlas(blahblah, library);
		switch (skin)
		{
			case 'FUNNY_NOTE_assets':
				setGraphicSize(noteWidth);
		}
		loadNoteAnims();

		antialiasing = ClientPrefs.getPref('globalAntialiasing');
		if (isSustainNote)
			scale.y = lastScaleY;

		updateHitbox();

		if (animName != null)
			animation.play(animName, true);
		if (inEditor)
		{
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
			updateHitbox();
		}
	}

	private inline function loadNoteAnims()
	{
		animation.addByPrefix(colArray[noteData] + 'Scroll', colArray[noteData] + '0');
		if (isSustainNote)
		{
			switch (noteData)
			{
				default:
					animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + ' hold end');
				case 0:
					animation.addByPrefix('purpleholdend', 'pruple end hold'); // ?????
			}
			animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + ' hold piece');
		}

		setGraphicSize(Std.int(width * .7));
		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var songPosition:Float = Conductor.songPosition;
		var earlyZone:Float = songPosition + (Conductor.safeZone * earlyHitMult);

		if (mustPress)
		{
			var lateZone:Float = songPosition - (Conductor.safeZone * lateHitMult);
			// ok river
			canBeHit = strumTime >= lateZone && strumTime <= earlyZone;
			if (strumTime < (songPosition - Conductor.safeZone) && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;
			if (strumTime <= earlyZone)
			{
				if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}
		if (tooLate && !(inEditor || isFNM))
			alpha = Math.min(alpha, .3);
	}
}
