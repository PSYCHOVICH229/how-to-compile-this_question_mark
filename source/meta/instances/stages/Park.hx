package meta.instances.stages;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import states.substates.GameOverSubstate;
import flixel.group.FlxGroup.FlxTypedGroup;
import meta.data.ClientPrefs;

class Park extends BaseStage
{
	public static final SUPER_TWEEN_EASING:Dynamic = FlxEase.backIn;
	public inline static final SUPER_OFFSET_Y:Float = 1280;

	private inline static final SHIT_UPSCALING:Float = 1.25;

	private var bgGroup:FlxTypedGroup<BGSprite>;
	private var fgGroup:FlxTypedGroup<BGSprite>;

	private final deadBF:BGSprite;
	private var tweened:Bool = false;

	override function new(parent:Dynamic)
	{
		super(parent);

		final bg:BGSprite = new BGSprite('park/background', -100, -400, .1, .4, false);
		final fg:BGSprite = new BGSprite('park/foreground', 150, 0, 1, 1, false);

		bgGroup = new FlxTypedGroup();
		fgGroup = new FlxTypedGroup();

		addToStage(bgGroup);
		addToStage(fgGroup);

		bg.setGraphicSize(Std.int(bg.width * SHIT_UPSCALING));
		fg.setGraphicSize(Std.int(fg.width * SHIT_UPSCALING));

		bg.updateHitbox();
		fg.updateHitbox();

		bgGroup.add(bg);
		fgGroup.add(fg);

		if (!ClientPrefs.getPref('lowQuality'))
		{
			final city:BGSprite = new BGSprite('park/city', -50, -100, .25, .8, false);

			city.setGraphicSize(Std.int(city.width * SHIT_UPSCALING));
			city.updateHitbox();

			bgGroup.add(city);
			switch (parent.curSong)
			{
				case 'plot-armor':
					{
						// bf is fucking dead
						deadBF = new BGSprite('deadbflol', 1800, 950, 1, 1, true, ['bopper'], false);

						deadBF.setGraphicSize(Std.int(deadBF.width * .7));
						deadBF.updateHitbox();

						add(deadBF);
						// fgGroup.add(deadBF);
					}
			}
		}

		final ferrisWheel:BGSprite = new BGSprite('park/ferris_wheel', 10, 0, .4, .9, false);

		ferrisWheel.setGraphicSize(Std.int(ferrisWheel.width * SHIT_UPSCALING));
		ferrisWheel.updateHitbox();

		bgGroup.add(ferrisWheel);
	}

	override function onSongStart()
	{
		GameOverSubstate.deathSoundLibrary = GameOverSubstate.loopSoundLibrary = GameOverSubstate.endSoundLibrary = 'shuttleman';
		GameOverSubstate.deathSoundName = 'fnf_loss_sfx_raw_version';

		GameOverSubstate.endSoundName = 'gameOverEnd';
		GameOverSubstate.loopSoundName = 'gameOver';

		GameOverSubstate.conductorBPM = 190;
		super.onSongStart();
	}

	override function beatHit(beat:Int)
	{
		if (deadBF != null && beat % parent.gfSpeed == 0)
			deadBF.dance(true);
		super.beatHit(beat);
	}
	public inline function tweenOut(tweenTime:Float = 0)
	{
		if (!tweened)
		{
			tweened = true;
			fgGroup?.forEachAlive(function(fg:BGSprite)
			{
				parent.modchartTweens.push(FlxTween.tween(fg, {y: fg.y + SUPER_OFFSET_Y}, tweenTime,
					{ease: SUPER_TWEEN_EASING, onComplete: parent.cleanupTween}));
			});
		}
	}
}
