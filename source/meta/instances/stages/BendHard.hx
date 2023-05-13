package meta.instances.stages;

class BendHard extends BaseStage
{
	private var trioOpponent:Character;
	private var duoOpponent:Character;

	override function new(parent:Dynamic)
	{
		super(parent);
		var bg:BGSprite = new BGSprite('stage', -820, -250);

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

		parent.DUO_X = -325;
		parent.DUO_Y = parent.TRIO_Y;

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
