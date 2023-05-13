package meta.instances.stages;

class MSPaint extends BaseStage
{
	override function new(parent:Dynamic)
	{
		super(parent);
		var bg:BGSprite = new BGSprite('mspaint', -600, 100);

		bg.setGraphicSize(Std.int(bg.width * 1.5));
		bg.updateHitbox();

		addToStage(bg);
	}
}
