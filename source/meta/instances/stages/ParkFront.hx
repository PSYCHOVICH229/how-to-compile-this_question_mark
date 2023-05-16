package meta.instances.stages;

import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import meta.data.StageData;
import flixel.FlxG;
import flixel.FlxSprite;
import states.substates.GameOverSubstate;
import meta.data.ClientPrefs;

class ParkFront extends BaseStage
{
	private inline static final UPSCALING:Float = 1.1;

	private var flyingScrollingGroup:Array<Dynamic>;
	private var flyingGroup:FlxGroup;

	private final skyWindRight:BGSprite;
	private final skyWindLeft:BGSprite;

	private var deadBF:BGSprite;
	private var doingAirShit:Bool = false;

	override function new(parent:Dynamic)
	{
		super(parent);

		flyingGroup = new FlxGroup();
		flyingGroup.visible = false;

		flyingScrollingGroup = [];
		final bg:BGSprite = new BGSprite('park/3d/bg', 500, -920, 1, 1, false);

		bg.setGraphicSize(Std.int(bg.width * UPSCALING));
		bg.updateHitbox();

		final badminton:BGSprite = new BGSprite('park/3d/badminton', bg.x, bg.y, bg.scrollFactor.x, bg.scrollFactor.y, bg.antialiasing);

		badminton.setGraphicSize(Std.int(badminton.width * UPSCALING));
		badminton.updateHitbox();

		addToStage(bg);
		addBehindDad(badminton, 1);

		add(flyingGroup);

		final stageData:Null<StageFile> = StageData.getStageFile('park-front');
		if (stageData != null)
		{
			final stageScale:Float = 1 / ((stageData.defaultZoom ?? -1.) > 0 ? stageData.defaultZoom : 1);
			final flyingBackground:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * stageScale), Std.int(FlxG.height * stageScale), 0xFFB2FFFF);

			flyingGroup.add(flyingBackground);

			flyingBackground.scrollFactor.set();
			flyingBackground.screenCenter();

			final backClouds:BGSprite = new BGSprite('sky/backclouds', 0, 0, 0, 0, false);

			flyingGroup.add(backClouds);
			flyingScrollingGroup.push([backClouds, .5]);

			backClouds.setGraphicSize(Std.int(backClouds.width * stageScale));
			backClouds.updateHitbox();

			if (!ClientPrefs.getPref('lowQuality'))
			{
				final mountains:BGSprite = new BGSprite('sky/mountains', 0, 0, 0, 0, false);

				flyingGroup.add(mountains);
				flyingScrollingGroup.push([mountains, .25]);

				mountains.setGraphicSize(Std.int(mountains.width * stageScale));
				mountains.updateHitbox();

				final towers:BGSprite = new BGSprite('sky/towers', 0, 0, 0, 0, false);

				flyingGroup.add(towers);
				flyingScrollingGroup.push([towers, .4]);

				towers.setGraphicSize(Std.int(towers.width * stageScale));
				towers.updateHitbox();

				final clouds:BGSprite = new BGSprite('sky/clouds', 0, 0, 0, 0, false);

				flyingGroup.add(clouds);
				flyingScrollingGroup.push([clouds, .6]);

				clouds.setGraphicSize(Std.int(clouds.width * stageScale));
				clouds.updateHitbox();
			}

			skyWindLeft = new BGSprite('sky/wind', 0, 0, 0, 0, false);
			skyWindRight = new BGSprite('sky/wind', skyWindLeft.x + skyWindLeft.width, 0, 0, 0, false);

			skyWindLeft.alpha = skyWindRight.alpha = .75;

			flyingGroup.add(skyWindLeft);
			flyingGroup.add(skyWindRight);

			var skyVignette = new BGSprite('sky/skyVignette', 0, 0, 0, 0);
			flyingGroup.add(skyVignette);

			skyVignette.cameras = [parent.camHUD];
			skyVignette.screenCenter();
		}
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

	override function update(elapsed:Float)
	{
		if (doingAirShit)
		{
			// uuuuuup
			skyWindLeft.x = -((Conductor.songPosition / 1500) % 1) * skyWindLeft.width;
			skyWindRight.x = skyWindLeft.x + skyWindLeft.width;
		}
		super.update(elapsed);
	}
	public function doAirShit(doing:Bool = true)
	{
		if (doingAirShit != doing)
		{
			doingAirShit = flyingGroup.visible = doing;
			if (doing)
			{
				for (flyingShit in flyingScrollingGroup)
				{
					var flying:BGSprite = flyingShit[0];

					flying.setPosition(0, 25);
					parent.modchartTweens.push(FlxTween.tween(flying, {y: -25}, (Conductor.crochet * 4) / 1000,
						{ease: FlxEase.backIn, startDelay: (Conductor.crochet * 56) / 1000, onComplete: parent.cleanupTween}));
					parent.modchartTweens.push(FlxTween.tween(flying, {x: -flying.width * flyingShit[1] * .5}, (Conductor.crochet * 60) / 1000,
						{ease: FlxEase.linear, onComplete: parent.cleanupTween}));
				}
				parent.modchartTimers.push(new FlxTimer().start((Conductor.crochet * 56) / 1000, function(tmr:FlxTimer)
				{
					var superGradient:FlxSpriteGroup = new FlxSpriteGroup();

					superGradient.cameras = [parent.camOther];
					superGradient.scrollFactor.set();

					var gradientTop:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, Std.int(FlxG.height * .5), [0x00FFFFFF, FlxColor.WHITE], 4,
						90, false);
					var gradientBottom:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, Std.int(FlxG.height * .5), [FlxColor.WHITE, 0x00FFFFFF], 4,
						90, false);

					var superCover:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);

					gradientBottom.y = superCover.y + superCover.height;
					gradientTop.y = superCover.y - gradientTop.height;

					superGradient.add(superCover);

					superGradient.add(gradientBottom);
					superGradient.add(gradientTop);

					superGradient.y = FlxG.height + gradientTop.height;
					add(superGradient);

					parent.modchartTweens.push(FlxTween.tween(superGradient, {y: 0}, (Conductor.crochet * 4) / 1000, {
						ease: FlxEase.quintIn,
						onComplete: function(twn:FlxTween)
						{
							parent.modchartTweens.push(FlxTween.tween(superGradient, {y: -FlxG.height - gradientBottom.height},
								(Conductor.crochet * 4) / 1000, {
									ease: FlxEase.quintOut,
									onComplete: function(twn:FlxTween)
									{
										superGradient.kill();
										remove(superGradient, true);

										superGradient.destroy();
										parent.cleanupTween(twn);
									}
								}));
							parent.cleanupTween(twn);
						}
					}));
				}));
			}
			if (!doing || ClientPrefs.getPref('flashing'))
				parent.camOther.flash();
		}
	}
}
