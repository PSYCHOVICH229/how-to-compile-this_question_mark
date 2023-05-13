package meta.instances.stages;

class Banana extends BaseStage
{
	override function new(parent:Dynamic)
	{
		super(parent);
		var bg:BGSprite = new BGSprite('stage', -350, -300);

		bg.setGraphicSize(Std.int(bg.width * 1.15));
		bg.updateHitbox();

		addToStage(bg);
	}
}
