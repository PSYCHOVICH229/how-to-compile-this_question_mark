package meta.instances.stages;

import flixel.FlxG;
import meta.data.ClientPrefs;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;

class BendHard extends BaseStage
{
	private var trioOpponent:Character;
	private var duoOpponent:Character;

	private var gun:FlxSprite;
	private var hasGunOut:Bool = false;

	override function new(parent:Dynamic)
	{
		super(parent);
		final bg:BGSprite = new BGSprite('stage', -820, -250);

		bg.setGraphicSize(Std.int(bg.width * 2.5));
		bg.updateHitbox();

		killOpponents();
		addToStage(bg);
	}

	override function onSongStart()
	{
		trioOpponent = new Character(0, 0, 'bendy');
		duoOpponent = new Character(0, 0, 'sans');

		trioOpponent.active = false;
		duoOpponent.active = false;

		addToStage(trioOpponent);
		addToStage(duoOpponent);

		parent.trioOpponent = trioOpponent;
		parent.duoOpponent = duoOpponent;

		parent.TRIO_X = 125;
		parent.DUO_X = -325;

		parent.DUO_Y = parent.TRIO_Y = -50;
		gun = new FlxSprite(parent.DAD_X + parent.TRIO_X + trioOpponent.positionArray[0] + 360, parent.DAD_Y + parent.TRIO_Y + trioOpponent.positionArray[0] + 300, Paths.image('gun'));

		gun.setGraphicSize(Std.int(gun.width * .4));
		gun.updateHitbox();

		gun.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		gun.cameras = [parent.camGame];

		gun.visible = false;
		add(gun);

		Paths.image('gun');
		super.onSongStart();
	}

	private function killOpponents()
	{
		if (duoOpponent != null)
		{
			duoOpponent.kill();
			parent.dadGroup.remove(duoOpponent, true);

			if (duoOpponent == parent.duoOpponent)
				parent.duoOpponent = null;
			remove(duoOpponent, true);

			duoOpponent.destroy();
			duoOpponent = null;
		}
		if (trioOpponent != null)
		{
			trioOpponent.kill();
			parent.dadGroup.remove(trioOpponent, true);

			if (trioOpponent == parent.trioOpponent)
				parent.trioOpponent = null;
			remove(trioOpponent, true);

			trioOpponent.destroy();
			trioOpponent = null;
		}
	}
	public function whipOutGun()
	{
		if (!hasGunOut)
		{
			hasGunOut = true;

			gun.offset.y = 10;
			gun.angle = -15;

			gun.alpha = 0;
			gun.visible = true;

			parent.modchartTweens.push(FlxTween.tween(gun, { "offset.y": 0, angle: 0, alpha: 1 }, Conductor.crochet / 1000, { ease: FlxEase.sineOut, onComplete: parent.cleanupTween }));
			if (duoOpponent != null)
			{
				parent.modchartTweens.push(FlxTween.tween(duoOpponent, { x: parent.DUO_X - FlxG.width }, Conductor.crochet / 500, { ease: FlxEase.quintIn, startDelay: Conductor.crochet / 500, onComplete: function(twn:FlxTween) {
					duoOpponent.visible = false;
					duoOpponent.kill();

					parent.cleanupTween(twn);
				} }));
			}
			parent.modchartTweens.push(FlxTween.tween(parent.dad, { alpha: 0 }, Conductor.crochet / 500, { ease: FlxEase.quintIn, startDelay: Conductor.crochet / 500, onComplete: function(twn:FlxTween) {
				parent.dad.visible = false;
				parent.dad.kill();

				parent.cleanupTween(twn);
			} }));
		}
	}

	override function update(elapsed:Float)
	{
		duoOpponent?.update(elapsed);
		trioOpponent?.update(elapsed);

		super.update(elapsed);
	}

	override function destroy()
	{
		killOpponents();
		super.destroy();
	}
}
