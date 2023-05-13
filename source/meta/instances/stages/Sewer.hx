package meta.instances.stages;

import flixel.FlxG;
import meta.data.ClientPrefs;
import flixel.graphics.FlxGraphic;
import openfl.Assets;

using StringTools;

class Sewer extends BaseStage
{
	override function new(parent:Dynamic)
	{
		super(parent);

		var bg:BGSprite = new BGSprite('sewer/background');
		var fg:BGSprite = new BGSprite('sewer/foreground');

		var sky:BGSprite = new BGSprite('sewer/sky', -75, -150, .2, .2);

		sky.setGraphicSize(Std.int(sky.width * 1.25));
		bg.setGraphicSize(Std.int(bg.width * 1.25));
		fg.setGraphicSize(Std.int(fg.width * 1.25));

		sky.updateHitbox();
		bg.updateHitbox();
		fg.updateHitbox();

		addToStage(sky);
		addToStage(bg);

		if (!ClientPrefs.getPref('lowQuality'))
		{
			var doodles:Array<FlxGraphic> = new Array();

			var library:String = Paths.currentLevel;
			var dirPath:String = 'doodles/';

			var doodlePath:String = Paths.getLibraryPath('$library/images/sewer/$dirPath');
			var assetList:Array<String> = Assets.list(IMAGE);

			for (asset in assetList)
			{
				if (asset.startsWith(doodlePath))
					doodles.push(Paths.returnGraphic('$library:$asset'));
			}

			var doodle:BGSprite = new BGSprite(FlxG.random.getObject(doodles));
			var beam:BGSprite = new BGSprite('sewer/beam');

			doodle.setGraphicSize(Std.int(doodle.width * 1.25));
			beam.setGraphicSize(Std.int(beam.width * 1.25));

			doodle.updateHitbox();
			beam.updateHitbox();

			addToStage(doodle);
			addToStage(beam);
		}
		addToStage(fg);
	}
}
