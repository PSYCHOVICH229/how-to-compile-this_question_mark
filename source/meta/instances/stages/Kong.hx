package meta.instances.stages;

class Kong extends BaseStage
{
	override function new(parent:Dynamic)
	{
		super(parent);
		var bg:BGSprite = new BGSprite('back');

		bg.setGraphicSize(Std.int(bg.width * 4));
		bg.updateHitbox();

		addToStage(bg);
	}
}
