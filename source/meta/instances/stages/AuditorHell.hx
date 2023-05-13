package meta.instances.stages;

import states.PlayState;
import meta.instances.bars.Healthbar;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.ui.FlxBar;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import meta.data.ClientPrefs;
import flixel.FlxSprite;

class AuditorHell extends BaseStage
{
	private static var exTrickyLinesSing:Array<String> = [
		"YOU AREN'T FUNNY",
		"WHERE IS BOYFRIEND",
		"BOYFRIEND???",
		"WHO ARE YOU",
		"WHERE AM I",
		"THIS ISN'T RIGHT",
		"PNG",
		"SYSTEM UNRESPONSIVE"
	];

	private var stepMechanics:Array<Array<Dynamic>>;

	private var cachedSignFuck:FlxSprite;
	private var cachedGremlin:FlxSprite;

	private var converHole:BGSprite;
	private var cover:BGSprite;
	private var hole:BGSprite;

	private var cloneOne:FlxSprite;
	private var cloneTwo:FlxSprite;

	private var trickyStatic:FlxSprite;
	private var spookyText:FlxText;

	private var totalDamageTaken:Float = 0;
	private var spookySteps:Float = 0;

	private var interupt:Bool = false;
	private var grabbed:Bool = false;

	override function new(parent:Dynamic)
	{
		super(parent);

		converHole = new BGSprite('Spawnhole_Ground_COVER', 7, 578, .9, .9);
		hole = new BGSprite('Spawnhole_Ground_BACK', 50, 530, .9, .9);
		cover = new BGSprite('cover', -180, 755, .9, .9);

		var stageFront:BGSprite = new BGSprite('daBackground', -350, -355, .9, .9);
		var bg:BGSprite = new BGSprite('bg', -10, -10, .9, .9);

		var camOther:FlxCamera = parent.camOther;

		stageFront.setGraphicSize(Std.int(stageFront.width * 1.55));
		converHole.setGraphicSize(Std.int(converHole.width * 1.3));

		bg.setGraphicSize(Std.int(bg.width * 4));

		cover.setGraphicSize(Std.int(cover.width * 1.55));
		hole.setGraphicSize(Std.int(hole.width * 1.55));

		addToStage(bg);
		if (!ClientPrefs.getPref('lowQuality'))
		{
			Paths.image('Clone', 'clown');

			var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');
			if (ClientPrefs.getPref('flashing'))
			{
				trickyStatic = new FlxSprite().loadGraphic(Paths.image('TrickyStatic', 'clown'), true, 320, 180);
				trickyStatic.cameras = [camOther];

				trickyStatic.setGraphicSize(Std.int(trickyStatic.width * 8.3));
				trickyStatic.scrollFactor.set();

				trickyStatic.animation.add('static', [0, 1, 2], 24, true);
				trickyStatic.animation.play('static');

				trickyStatic.screenCenter();

				trickyStatic.antialiasing = globalAntialiasing;
				trickyStatic.alpha = .1;

				addToStage(trickyStatic);
			}

			var energyWall:BGSprite = new BGSprite("Energywall", 1350, -690, .9, .9);
			addToStage(energyWall);
			// Clown init
			cloneOne = new FlxSprite();
			cloneTwo = new FlxSprite();

			cloneOne.frames = cloneTwo.frames = Paths.getSparrowAtlas('Clone', 'clown');

			cloneOne.animation.addByPrefix('clone', 'Clone', 24, false);
			cloneTwo.animation.addByPrefix('clone', 'Clone', 24, false);

			cloneOne.scrollFactor.set(.9, .9);
			cloneTwo.scrollFactor.set(cloneOne.scrollFactor.x, cloneOne.scrollFactor.y);

			cloneOne.antialiasing = cloneTwo.antialiasing = globalAntialiasing;
			cloneOne.active = cloneOne.visible = cloneTwo.active = cloneTwo.visible = false;
		}
		addToStage(stageFront);
		if (PlayState.mechanicsEnabled)
		{
			// sign
			cachedSignFuck = new FlxSprite();
			cachedSignFuck.alpha = FlxMath.EPSILON;

			cachedSignFuck.frames = Paths.getSparrowAtlas('mech/Sign_Post_Mechanic', 'clown');
			// grelin
			cachedGremlin = new FlxSprite();
			cachedGremlin.alpha = FlxMath.EPSILON;

			cachedGremlin.frames = Paths.getSparrowAtlas('mech/HP GREMLIN', 'clown');

			add(cachedSignFuck);
			add(cachedGremlin);
		}

		addBehindDad(cloneOne);
		addBehindDad(cloneTwo);

		addBehindDad(cover);
		addBehindDad(converHole);

		addToStage(hole);

		var dad:Character = parent.dad;
		if (dad != null && dad.exSpikes != null)
			addBehindDad(dad.exSpikes, 1);
	}

	override function onSongStart()
	{
		gfVersion = 'gf-tied';
		switch (parent.curSong)
		{
			case 'expurgation':
				{
					stepMechanics = [
						// i want to shoot myself
						[[1235, 1584, 1923, 1932, 2036, 2202, 2258, 2326, 2604], doStopSign.bind(0, true)],
						[[384, 1218, 1567, 1917, 1927, 2193], doStopSign.bind(0)],
						[[610, 991, 1200, 1706, 2336], doStopSign.bind(3)],
						[[720, 1184, 1600], doStopSign.bind(2)],

						[1439, doStopSign.bind(3, true)],
						[2239, doStopSign.bind(2, true)],

						[
							[2304, 2480, 2608, 2544],
							function()
							{
								doStopSign(0, true);
								doStopSign(0);
							}
						],
						[
							[2447, 2512, 2575],
							function()
							{
								doStopSign(2);

								doStopSign(0, true);
								doStopSign(0);
							}
						],
						[
							[511, 2032],
							function()
							{
								doStopSign(2);
								doStopSign(0);
							}
						],

						[
							1328,
							function()
							{
								doStopSign(0, true);
								doStopSign(2);
							}
						],
						[
							2162,
							function()
							{
								doStopSign(2);
								doStopSign(3);
							}
						],
						[2655, doGremlin.bind(20, 13, true)]
					];
				}
		}
		super.onSongStart();
	}

	override function update(elapsed:Float)
	{
		if (cloneOne != null)
			cloneOne.update(elapsed);
		if (cloneTwo != null)
			cloneTwo.update(elapsed);

		if (spookyText != null)
		{
			spookyText.update(elapsed);
			spookyText.angle = FlxG.random.int(-5, 5);

			if (trickyStatic != null)
				trickyStatic.alpha = FlxG.random.float(.1, .5);
			if (spookySteps < parent.curStep)
			{
				if (trickyStatic != null)
					trickyStatic.alpha = .1;
				remove(spookyText, true);

				spookyText.destroy();
				spookyText = null;
			}
		}
		super.update(elapsed);
	}

	override function beatHit(beat:Int)
	{
		switch (parent.curSong)
		{
			case 'expurgation':
				{
					var health:Float = parent.health;
					if (beat % 8 == 4)
						doClone(FlxG.random.int(0, 1));
					if (PlayState.mechanicsEnabled && parent.curStep < 2400 && ((beat + 16) % 96) == 0 && health >= 1.5 && !grabbed)
					{
						doGremlin(40, 3);
						trace('checka $health');
					}
				}
		}
		super.beatHit(beat);
	}

	override function stepHit(step:Int)
	{
		if (PlayState.mechanicsEnabled && stepMechanics != null)
		{
			// oooooohhh boooy
			for (mechanic in stepMechanics)
			{
				var steps:Dynamic = mechanic[0];
				var func:Dynamic = mechanic[1];

				if (Std.isOfType(steps, Int))
				{
					if (step >= steps)
					{
						func();
						stepMechanics.remove(mechanic);
					}
				}
				else
				{
					var stepList:Array<Int> = steps;
					for (stepped in stepList)
					{
						if (step >= stepped)
						{
							steps.remove(stepped);
							func();

							if (steps.length <= 0)
							{
								stepMechanics.remove(mechanic);
								break;
							}
						}
					}
				}
			}
		}
		super.stepHit(step);
	}

	public function generateSpookyText()
	{
		var dad:Character = parent.dad;

		spookyText = new FlxText(FlxG.random.float(dad.x + 40, dad.x + 120), FlxG.random.float(dad.y + 200, dad.y + 300));
		spookyText.setFormat(Paths.font('impact.ttf'), 128, FlxColor.RED);

		spookyText.text = FlxG.random.getObject(exTrickyLinesSing);
		spookyText.bold = true;

		spookyText.active = false;
		FlxG.sound.play(Paths.sound('staticSound', 'clown'));

		add(spookyText);
	}

	public function doStopSign(sign:Int = 0, flipped:Bool = false)
	{
		trace('sign $sign');

		var daSign:FlxSprite = null;
		if (cachedSignFuck != null)
		{
			remove(cachedSignFuck, true);

			daSign = cachedSignFuck;
			daSign.alpha = 1;

			cachedSignFuck = null;
		}
		else
		{
			daSign = new FlxSprite();
			daSign.frames = Paths.getSparrowAtlas('mech/Sign_Post_Mechanic', 'clown');
		}
		daSign.setGraphicSize(Std.int(daSign.width * .67));

		daSign.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		daSign.cameras = [parent.camOther];

		switch (sign)
		{
			case 0:
				{
					daSign.animation.addByPrefix('sign', 'Signature Stop Sign 1', 24, false);

					daSign.x = FlxG.width - 650;
					daSign.y = -300;

					daSign.angle = -90;
				}
			case 2:
				{
					daSign.animation.addByPrefix('sign', 'Signature Stop Sign 3', 24, false);

					daSign.y = ClientPrefs.getPref('downScroll') ? -395 : -980;
					daSign.x = FlxG.width - 780;

					daSign.angle = -90;
				}
			case 3:
				{
					daSign.animation.addByPrefix('sign', 'Signature Stop Sign 4', 24, false);
					daSign.angle = -90;

					daSign.x = FlxG.width - 1070;
					daSign.y = -145;
				}
		}

		add(daSign);
		daSign.flipX = flipped;

		daSign.animation.play('sign');
		daSign.animation.finishCallback = function(pog:String)
		{
			trace('ended sign');
			daSign.kill();

			remove(daSign, true);
			daSign.destroy();
		}
	}

	// basic explanation of this is:
	// get the health to go to
	// tween the gremlin to the icon
	// play the grab animation and do some funny maths,
	// to figure out where to tween to.
	// lerp the health with the tween progress
	// if you loose any health, cancel the tween.
	// and fall off.
	// Once it finishes, fall off.
	public function doGremlin(hpToTake:Int, duration:Int, persist:Bool = false)
	{
		var healthBar:Healthbar = parent.healthBar;
		if (healthBar != null)
		{
			var camOther:FlxCamera = parent.camOther;

			var modchartTimers:Array<FlxTimer> = parent.modchartTimers;
			var modchartTweens:Array<FlxTween> = parent.modchartTweens;

			var iconP1:HealthIcon = parent.iconP1;

			interupt = false;
			grabbed = true;

			totalDamageTaken = 0;

			var gramlan:FlxSprite = null;
			if (cachedGremlin != null)
			{
				remove(cachedGremlin, true);

				gramlan = cachedGremlin;
				gramlan.alpha = 1;

				cachedGremlin = null;
			}
			else
			{
				gramlan = new FlxSprite();
				gramlan.frames = Paths.getSparrowAtlas('mech/HP GREMLIN', 'clown');
			}
			gramlan.setGraphicSize(Std.int(gramlan.width * .76));

			gramlan.y = healthBar.bg.y - 325;
			gramlan.x = parent.iconP1.x;

			gramlan.animation.addByIndices('grab', 'HP Gremlin ANIMATION', [
				2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24
			], "", 24, false);
			gramlan.animation.addByIndices('hold', 'HP Gremlin ANIMATION', [25, 26, 27, 28], "", 24);

			gramlan.animation.addByIndices('release', 'HP Gremlin ANIMATION', [29, 30, 31, 32], "", 24, false);
			gramlan.animation.addByIndices('come', 'HP Gremlin ANIMATION', [0, 1], "", 24, false);

			gramlan.antialiasing = ClientPrefs.getPref('globalAntialiasing');
			gramlan.cameras = [camOther];

			add(gramlan);
			if (ClientPrefs.getPref('downScroll'))
			{
				gramlan.flipY = true;
				gramlan.y -= 150;
			}
			// over use of flxtween :)
			var startHealth:Float = parent.health;
			var toHealth:Float = (hpToTake / 100) * startHealth; // simple math, convert it to a percentage then get the percentage of the health

			var perct:Float = toHealth / 2 * 100;
			var onc:Bool = false;

			trace('start: $startHealth\nto: $toHealth\nwhich is prect: $perct');
			FlxG.sound.play(Paths.sound('GremlinWoosh', 'clown'));

			gramlan.animation.play('come');
			gramlan.animation.finishCallback = function(pog:String)
			{
				if (pog == 'release')
				{
					gramlan.kill();
					remove(gramlan, true);

					gramlan.animation.finishCallback = null;
					gramlan.destroy();
				}
			}

			modchartTimers.push(new FlxTimer().start(.14, function(tmr:FlxTimer)
			{
				gramlan.animation.play('grab');
				modchartTweens.push(FlxTween.tween(gramlan, {x: iconP1.x - 140}, 1, {
					ease: FlxEase.elasticIn,
					onComplete: function(tween:FlxTween)
					{
						trace('I got em');

						gramlan.animation.play('hold');
						modchartTweens.push(FlxTween.tween(gramlan,
							{x: (healthBar.bar.x + (healthBar.bar.width * (FlxMath.remapToRange(perct, 0, 100, 100, 0) / 100) - 26)) - 75}, duration, {
								onUpdate: function(tween:FlxTween)
								{
									// lerp the health so it looks pog
									if (interupt && !onc && !persist)
									{
										onc = true;
										trace('oh shit');
										gramlan.animation.play('release');
									}
									else if (!interupt || persist)
									{
										var pp = Math.max(FlxMath.lerp(startHealth, toHealth, tween.scale), .1);
										parent.health = pp;
									}
									parent.doDeathCheck();
								},
								onComplete: function(tween:FlxTween)
								{
									if (interupt && !persist)
									{
										gramlan.kill();
										remove(gramlan, true);

										gramlan.destroy();
										grabbed = false;
									}
									else
									{
										trace('oh shit');

										gramlan.animation.play('release');
										if (persist && totalDamageTaken >= .7)
											parent.health -= totalDamageTaken; // just a simple if you take a lot of damage wtih this, you'll loose probably.
										grabbed = false;
									}
									parent.cleanupTween(tween);
								}
							}));
						parent.cleanupTween(tween);
					}
				}));
				parent.cleanupTimer(tmr);
			}));
		}
	}

	public function doClone(side:Int)
	{
		var dad:Character = parent.dad;
		var thisClone:FlxSprite = switch (side)
		{
			default:
				{
					cloneOne.setPosition(dad.x - 20);
					cloneOne;
				}
			case 1:
				{
					cloneTwo.setPosition(dad.x + 390);
					cloneTwo;
				}
		};

		if (thisClone.visible)
			return;

		thisClone.y = dad.y + 140;
		thisClone.visible = true;

		thisClone.animation.play('clone');
		thisClone.animation.finishCallback = function(pog:String)
		{
			thisClone.visible = false;
			thisClone.animation.finishCallback = null;
		}
	}
}
