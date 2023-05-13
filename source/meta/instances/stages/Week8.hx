package meta.instances.stages;

class Week8 extends BaseStage
{
	override function new(parent:Dynamic)
	{
		super(parent);
		var bg:BGSprite = new BGSprite('stage');

		bg.setGraphicSize(Std.int(bg.width * 1.3));
		bg.updateHitbox();

		addToStage(bg);
	}

	override function onSongStart()
	{
		gfVersion = 'gf-week8';
		super.onSongStart();
	}
}
