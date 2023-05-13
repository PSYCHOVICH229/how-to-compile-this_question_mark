package states.substates;

import meta.data.ClientPrefs;
import openfl.Lib;
import flixel.FlxSprite;
import flixel.FlxG;

class JumpscareSubstate extends MusicBeatSubstate
{
	var scary:FlxSprite;

	public function new()
	{
		super();
		scary = new FlxSprite().loadGraphic(Paths.image('jumpedscare', 'fnm'));

		scary.setGraphicSize(FlxG.width, FlxG.height);
		scary.updateHitbox();

		scary.antialiasing = ClientPrefs.getPref('globalAntialiasing');

		scary.screenCenter();
		scary.y += scary.height / 2;

		add(scary);
		FlxG.sound.play(Paths.sound('freddyDeath', 'fnm')).onComplete = function()
		{
			#if sys
			Sys.exit(0);
			#else
			Lib.application.window.close();
			#end
		};
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		scary.angle += elapsed * 5;

		scary.scale.x += elapsed;
		scary.scale.y += elapsed;

		scary.screenCenter();
		scary.y += scary.height / 2;
	}
}
