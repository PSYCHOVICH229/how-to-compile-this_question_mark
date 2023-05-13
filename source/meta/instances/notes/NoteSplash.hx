package meta.instances.notes;

import meta.data.ClientPrefs;
import states.PlayState;
import shaders.ColorSwap;
import flixel.FlxG;
import flixel.FlxSprite;

class NoteSplash extends FlxSprite
{
	private static var indexShit:Array<String> = ['note splash purple', 'note splash blue', 'note splash green', 'note splash red'];

	public var colorSwap:ColorSwap = null;

	private var textureLoaded:String = null;
	private var library:String = null;

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0, ?library:String = null)
	{
		super(x, y);
		this.library = library;

		var skin:String = PlayState.getNoteSplash();
		loadAnims(skin);
		// holy shit this is fucking valid
		shader = (colorSwap = new ColorSwap()).shader;

		setupNoteSplash(x, y, note);
		antialiasing = ClientPrefs.getPref('globalAntialiasing');
	}

	public inline function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = 'noteSplashes', hueColor:Float = 0, satColor:Float = 0,
			brtColor:Float = 0)
	{
		alpha = .6;
		if (textureLoaded != texture)
			loadAnims(texture);

		setPosition(x - (Note.noteWidth * .95), y - Note.noteWidth);
		colorSwap.hue = hueColor;

		colorSwap.saturation = satColor;
		colorSwap.brightness = brtColor;

		offset.set(10, 10);
		animation.finishCallback = function(name:String)
		{
			animation.finishCallback = null;
			kill();
		}

		var animNum:Int = FlxG.random.int(1, 2);
		animation.play('note$note-$animNum', true);
	}

	private inline function loadAnims(skin:String)
	{
		frames = Paths.getSparrowAtlas(skin, library);
		for (i in 0...2)
		{
			var index:Int = i + 1;
			for (note in 0...indexShit.length)
				animation.addByPrefix('note$note-$index', indexShit[note] + ' $index', 24, false);
		}
	}
}
