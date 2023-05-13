package meta.instances.stages;

class Forest extends BaseStage
{
	override function new(parent:Dynamic)
	{
		super(parent);
		var bg:BGSprite = new BGSprite('bg', -350, -200, .6, .6, false);

		bg.setGraphicSize(Std.int(bg.width * 1.05));
		bg.updateHitbox();

		addToStage(bg);
	}
}
