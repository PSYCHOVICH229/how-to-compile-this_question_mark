package meta.instances.stages;

class Screwed extends BaseStage
{
	override function new(parent:Dynamic)
	{
		super(parent);
		var bg:BGSprite = new BGSprite('corn', -620, 0);

		bg.setGraphicSize(Std.int(bg.width * 3));
		bg.updateHitbox();

		addToStage(bg);
	}
}
