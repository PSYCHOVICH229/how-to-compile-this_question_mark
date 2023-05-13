package meta.instances.stages;

import flixel.math.FlxPoint;
import flixel.group.FlxGroup.FlxTypedGroup;

class Squidgame extends BaseStage
{
	public var pinkSoldier:Character;

	override function new(parent:Dynamic)
	{
		super(parent);
		var bg:BGSprite = new BGSprite('back', -420, -220);

		bg.setGraphicSize(Std.int(bg.width * 1.5));
		bg.updateHitbox();

		addToStage(bg);
	}

	override function onSongStart()
	{
		pinkSoldier = new Character(120, 0, "pinksoldier");
		pinkSoldier.active = false;

		parent.dadGroup.insert(0, pinkSoldier);
		parent.startCharacterPos(pinkSoldier);

		addBehindDad(pinkSoldier);

		parent.secondOpponentStrums = new FlxTypedGroup();
		parent.secondOpponentDelta = new FlxPoint();

		super.onSongStart();
	}

	override function beatHit(beat:Int)
	{
		if (pinkSoldier != null && beat % parent.dad.danceEveryNumBeats == 0)
			pinkSoldier.dance(true);
		super.beatHit(beat);
	}

	override function update(elapsed:Float)
	{
		pinkSoldier?.update(elapsed);
		return;
	}
}
