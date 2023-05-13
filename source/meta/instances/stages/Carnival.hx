package meta.instances.stages;

import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import states.substates.GameOverSubstate;
import flixel.math.FlxMath;
import flixel.math.FlxAngle;
import shaders.ColorSwap;
import flixel.group.FlxSpriteGroup;
import flixel.FlxG;
import flixel.group.FlxGroup;
import meta.data.ClientPrefs;

class Carnival extends BaseStage
{
	private inline static final CARNIVAL_SCALE:Float = 1.2;
	public var eggbob:Character;

	private var bgGroup:FlxTypedGroup<BGSprite>;
	private var bg:BGSprite;

	private var rotatingWheel:BGSprite;
	private var carts:FlxSpriteGroup;

	public var cartShaking:Float = 0;

	private var eggbobEntered:Bool = false;
	private var fadedIn:Bool = false;

	private var ferrisCarts:Array<Dynamic> = [
		[5, -320], // up (0 red)
		[230, -190], // top right (1 orange)
		[330, 10], // right (2 green)
		[160, 250], // bottom right (3 green but reserved for beatbox boy)
		[-20, 300], // bottom (4 cyan)
		[-200, 200], // bottom left (5 blue)
		[-300, -10], // left (6 purple)
		[-210, -200] // top left (7 pink)
	];

	override function new(parent:Dynamic)
	{
		super(parent);

		var grass:BGSprite = new BGSprite('carnival/grass', -300, -300, .2, .6, false);
		var fg:BGSprite = new BGSprite('carnival/fg', 0, 0, 1, 1, false);

		bg = new BGSprite('carnival/bg', -250, -250, .1, .4, false);
		bgGroup = new FlxTypedGroup();

		var fgGroup:FlxGroup = new FlxGroup();

		grass.setGraphicSize(Std.int(grass.width * CARNIVAL_SCALE));
		bg.setGraphicSize(Std.int(bg.width * CARNIVAL_SCALE));

		grass.updateHitbox();
		bg.updateHitbox();

		fg.setGraphicSize(Std.int(fg.width * CARNIVAL_SCALE));
		fg.updateHitbox();

		bgGroup.add(bg);
		fgGroup.add(fg);

		if (!ClientPrefs.getPref('lowQuality'))
		{
			// ferris wheel
			var length:Int = ferrisCarts.length;
			rotatingWheel = new BGSprite('carnival/wheel', 1273 * CARNIVAL_SCALE, 7 * CARNIVAL_SCALE, 1, 1, false);

			rotatingWheel.setGraphicSize(Std.int(rotatingWheel.width * CARNIVAL_SCALE));
			rotatingWheel.updateHitbox();

			carts = new FlxSpriteGroup(0, 0, length);
			for (i in 0...length)
			{
				var cart:FlxSpriteGroup = new FlxSpriteGroup();

				var front:BGSprite = new BGSprite('cart/front', 0, 0, 1, 1, false);
				var back:BGSprite = new BGSprite('cart/back', 0, 30, 1, 1, false);

				var shader:ColorSwap = new ColorSwap();
				shader.hue = (cart.ID = i) / length;

				front.shader = back.shader = shader.shader;
				cart.add(back);

				switch (i)
				{
					case 0:
						{
							switch (FlxG.random.bool())
							{
								case true:
									{
										trace('jemeremy');
										cart.add(new BGSprite('cart/jemeremy'));
									}
								default:
									{
										trace('body');
										var character:BGSprite = new BGSprite('cart/body', 30, 20);

										character.setGraphicSize(Std.int(character.width * .9));
										character.updateHitbox();

										cart.add(character);
									}
							}
						}
					case 1:
						{
							var person:String = FlxG.random.bool() ? 'canny' : 'orang';
							trace(person);

							cart.add(new BGSprite('cart/$person', 0, 0, 1, 1, false));
						}
					case 2:
						{
							switch (FlxG.random.bool())
							{
								case true:
									{
										trace('creature');
										cart.add(new BGSprite('cart/creature', 0, 0, 1, 1, false));
									}
								default:
									{
										trace('lizord');
										var character:BGSprite = new BGSprite('cart/lizord', -30, -5);

										character.setGraphicSize(Std.int(character.width * .9));
										character.updateHitbox();

										cart.add(character);
									}
							}
						}
					case 3:
						{
							trace('beatbox boy :)');
							cart.add(new BGSprite('cart/beatboxboy', 50, 35, 1, 1, false));
						}
					case 4:
						{
							var character:String = FlxG.random.bool() ? 'boycunt' : 'nb';

							trace(character);
							cart.add(new BGSprite('cart/$character'));
						}
					case 5:
						{
							trace('gergory');
							cart.add(new BGSprite('cart/gergory'));
						}
					case 6:
						{
							switch (FlxG.random.bool())
							{
								case true:
									{
										trace('raymond');
										cart.add(new BGSprite('cart/raymond', 0, 0, 1, 1, false));
									}
								default:
									{
										trace('orichi');
										cart.add(new BGSprite('cart/legit_npc', 20, 55));
									}
							}
						}
					case 7:
						{
							switch (FlxG.random.bool())
							{
								case true:
									{
										trace('asdffdssdfsdf');
										cart.add(new BGSprite('cart/asdffdssdfsdf', 60, 65, 1, 1, false));
									}
								default:
									{
										trace('callie');
										cart.add(new BGSprite('cart/callie', 75, 40, 1, 1, false));
									}
							}
						}
				}

				cart.add(front);
				carts.add(cart);
			}
			repositionCarts();

			var wheelSupport:BGSprite = new BGSprite('carnival/wheelsupport', 0, 0, 1, 1, false);
			var wheelBase:BGSprite = new BGSprite('carnival/wheelbase', 0, 0, 1, 1, false);

			wheelSupport.setGraphicSize(Std.int(wheelSupport.width * CARNIVAL_SCALE));
			wheelBase.setGraphicSize(Std.int(wheelBase.width * CARNIVAL_SCALE));

			wheelSupport.updateHitbox();
			wheelBase.updateHitbox();
			// bg
			var city:BGSprite = new BGSprite('carnival/city', -300, -200, .25, .8, false);

			city.setGraphicSize(Std.int(city.width * CARNIVAL_SCALE));
			city.updateHitbox();

			bgGroup.add(city);
			// fg
			var bunker:BGSprite = new BGSprite('carnival/bunker', 0, 0, 1, 1, false);
			var house:BGSprite = new BGSprite('carnival/house', 0, 0, 1, 1, false);
			var sign:BGSprite = new BGSprite('carnival/sign', 0, 0, 1, 1, false);

			bunker.setGraphicSize(Std.int(bunker.width * CARNIVAL_SCALE));
			house.setGraphicSize(Std.int(house.width * CARNIVAL_SCALE));
			sign.setGraphicSize(Std.int(sign.width * CARNIVAL_SCALE));

			bunker.updateHitbox();
			house.updateHitbox();
			sign.updateHitbox();

			fgGroup.add(bunker);
			fgGroup.add(sign);

			fgGroup.add(house);
			fgGroup.add(wheelBase);

			fgGroup.add(rotatingWheel);
			fgGroup.add(carts);

			fgGroup.add(wheelSupport);
		}
		bgGroup.add(grass);

		addToStage(bgGroup);
		addToStage(fgGroup);

		switch (parent.curSong)
		{
			case 'foursome':
			{
				trace('have a eggob');

				eggbob = new Character(0, 0, 'eggbob', true);
				eggbob.active = false;

				eggbob.alpha = FlxMath.EPSILON;
				addBehindBF(eggbob);

				eggbob.kill();
			}
		}
	}

	override function onSongStart()
	{
		GameOverSubstate.deathSoundLibrary = GameOverSubstate.loopSoundLibrary = GameOverSubstate.endSoundLibrary = 'shuttleman';
		GameOverSubstate.deathSoundName = 'fnf_loss_sfx_raw_version';

		GameOverSubstate.endSoundName = 'gameOverEnd';
		GameOverSubstate.loopSoundName = 'gameOver';

		GameOverSubstate.conductorBPM = 190;
	}
	override function onStageAdded()
	{
		if (eggbob != null)
		{
			parent.DUO_X = 760;
			parent.DUO_Y = 310;

			parent.duoOpponent = eggbob;
			trace('make the egg');

			super.onStageAdded();
		}
	}

	override function update(elapsed:Float)
	{
		rotatingWheel.angle = (Conductor.songPosition / 50) % 360;
		repositionCarts();

		cartShaking = FlxMath.lerp(cartShaking, 0, FlxMath.bound(elapsed * 8, 0, 1));
		eggbob?.update(elapsed);

		super.update(elapsed);
	}
	override function destroy()
	{
		killDuoOpponent();
		super.destroy();
	}

	public inline function enterEggbob()
	{
		if (!eggbobEntered && eggbob != null)
		{
			trace('enter this bob');
			eggbobEntered = true;

			eggbob.x += FlxG.width;
			eggbob.y += 15;

			eggbob.alpha = 1;
			parent.modchartTweens.push(FlxTween.tween(eggbob, {x: parent.DAD_X + parent.DUO_X, y: parent.DAD_Y + parent.DUO_Y}, 1, {ease: FlxEase.sineInOut, onComplete: parent.cleanupTween}));
		}
	}
	public inline function tweenIn(tweenTime:Float = 0)
	{
		if (!fadedIn)
		{
			fadedIn = true;
			bgGroup?.forEachAlive(function(bgShit:BGSprite)
			{
				var lastY:Float = bgShit.y;

				bgShit.y -= 1200;
				parent.modchartTweens.push(FlxTween.tween(bgShit, {y: lastY}, tweenTime, {ease: FlxEase.quintOut, onComplete: parent.cleanupTween}));
			});
		}
	}

	private inline function killDuoOpponent()
	{
		if (eggbob != null)
		{
			eggbob.kill();
			parent.dadGroup.remove(eggbob, true);

			if (eggbob == parent.duoOpponent)
				parent.duoOpponent = null;
			remove(eggbob, true);

			eggbob.destroy();
			eggbob = null;
		}
	}
	private inline function repositionCarts()
	{
		rotatingWheel.angle += Math.abs(cartShaking / Math.PI);
		var angle:Float = (rotatingWheel.angle + 90) * FlxAngle.TO_RAD;

		var sin:Float = Math.sin(angle);
		var cos:Float = Math.cos(angle);
		// i know this is the opposite
		rotatingWheel.offset.set(cartShaking, -cartShaking);
		carts.forEachAlive(function(cart:FlxSprite)
		{
			var id:Int = cart.ID;
			var position:Array<Dynamic> = ferrisCarts[id];

			var pivotY:Float = rotatingWheel.y + ((rotatingWheel.height - cart.height) / 2);
			var pivotX:Float = rotatingWheel.x + ((rotatingWheel.width - cart.width) / 2);

			var x:Float = (position[0] * CARNIVAL_SCALE) + (cartShaking / 2);
			var y:Float = (position[1] * CARNIVAL_SCALE) - (cartShaking / 2);

			var rotatedX:Float = (x * cos) - (y * sin);
			var rotatedY:Float = (x * sin) + (y * cos);

			cart.angle = Math.sin((Conductor.songPosition / 100) * (((id % 4) + 1) / carts.length)) * 5 * ((id % 3) + 1) - (cartShaking / Math.PI);

			cart.x = pivotX + rotatedX;
			cart.y = pivotY + rotatedY;
		});
	}
}
