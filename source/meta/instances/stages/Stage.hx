package meta.instances.stages;

import meta.data.ClientPrefs;

class Stage extends BaseStage
{
	public function new(parent:Dynamic)
	{
		super(parent);

		var bg:BGSprite = new BGSprite('stageback', -600, -200);
		var stageFront:BGSprite = new BGSprite('stagefront', -650, 600);

		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();

		addToStage(bg);
		addToStage(stageFront);

		if (!ClientPrefs.getPref('lowQuality'))
		{
			var stageLight:BGSprite = new BGSprite('stage_light', -125, 0, .9, .9);

			stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
			stageLight.updateHitbox();

			add(stageLight);
			var stageLight:BGSprite = new BGSprite('stage_light', 1225, 0, .9, .9);

			stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
			stageLight.updateHitbox();

			stageLight.flipX = true;
			add(stageLight);

			var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);

			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * .9));
			stageCurtains.updateHitbox();

			add(stageCurtains);
		}
	}
}
