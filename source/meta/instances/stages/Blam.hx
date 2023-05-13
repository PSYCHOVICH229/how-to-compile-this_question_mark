package meta.instances.stages;

import flixel.FlxG;
import meta.data.ClientPrefs;

class Blam extends BaseStage
{
	// yes......yes.......yes.......yes......
	public var blamLightColors:Array<Int> = [0xFFFAFAC7, 0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
	public var colorShits:Array<BGSprite>;

	override function new(parent:Dynamic)
	{
		super(parent);

		var bg:BGSprite = new BGSprite('background', 0, 0, .2, .2, false);
		var city:BGSprite = new BGSprite('city', 0, -100, .4, false);

		var ground:BGSprite = new BGSprite('ground', 0, 0, 1, 1, false);
		var blamLights:BGSprite = new BGSprite('lights', 0, -100, .4, 1, false);

		colorShits = new Array();
		colorShits.push(blamLights);

		blamLights.setGraphicSize(Std.int(blamLights.width * 1.15));
		ground.setGraphicSize(Std.int(ground.width * 1.15));
		city.setGraphicSize(Std.int(city.width * 1.15));
		bg.setGraphicSize(Std.int(bg.width * 1.15));

		blamLights.updateHitbox();
		ground.updateHitbox();
		city.updateHitbox();
		bg.updateHitbox();

		addToStage(bg);

		addToStage(city);
		addToStage(blamLights);

		switch (ClientPrefs.getPref('lowQuality'))
		{
			case true:
				addToStage(ground);
			default:
				{
					var pillars:BGSprite = new BGSprite('pillars', 0, 0, 1, 1, false);
					var cable:BGSprite = new BGSprite('cable', 0, 0, 1, 1, false);

					pillars.setGraphicSize(Std.int(pillars.width * 1.15));
					cable.setGraphicSize(Std.int(cable.width * 1.15));

					pillars.updateHitbox();
					cable.updateHitbox();

					addToStage(pillars);
					addToStage(ground);
					addToStage(cable);
				}
		}
		for (sprite in colorShits)
			sprite.color = ClientPrefs.getPref('flashing') ? FlxG.random.getObject(blamLightColors) : blamLightColors[0];
	}

	override function beatHit(beat:Int)
	{
		if ((beat % 4) == 0)
		{
			for (sprite in colorShits)
			{
				var previousColor:Int = sprite.color;
				do
				{
					sprite.color = FlxG.random.getObject(blamLightColors);
				}
				while (sprite.color == previousColor);
			}
		}
		super.beatHit(beat);
	}
}
