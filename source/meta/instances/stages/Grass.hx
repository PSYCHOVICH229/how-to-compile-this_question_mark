package meta.instances.stages;

class Grass extends BaseStage
{
	override function new(parent:Dynamic)
	{
		super(parent);
		var bushes:BGSprite = new BGSprite('grass/bushes', -500, -100, .8, .9);

		var bg:BGSprite = new BGSprite('grass/bg', -600, -100, .2, .2);
		var fg:BGSprite = new BGSprite('grass/fg', -500, -100);

		addToStage(bg);
		addToStage(bushes);
		addToStage(fg);
	}
}
