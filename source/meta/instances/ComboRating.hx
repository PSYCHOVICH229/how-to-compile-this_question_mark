package meta.instances;

import meta.Conductor.Rating;
import flixel.FlxG;
import meta.data.ClientPrefs;
import states.PlayState;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;

class ComboRating extends FlxSpriteGroup
{
	private var comboTwn:FlxTween;

	private var comboNums:FlxSpriteGroup;
	private var comboSprite:FlxSprite;

	private var ratingSprite:FlxSprite;

	override function new()
	{
		super();

		comboNums = new FlxSpriteGroup();
		scrollFactor.set();

		add(comboNums);
	}

	public function startGroup()
	{
		var tweenTime:Float = Conductor.crochet / 1000;
		var doubleCrochet:Float = tweenTime * 2;

		var instance:PlayState = PlayState.instance;
		comboNums.forEachAlive(function(numScore:FlxSprite)
		{
			instance.modchartTweens.push(FlxTween.tween(numScore, {alpha: 0}, tweenTime, {
				onComplete: function(tween:FlxTween)
				{
					if (numScore != null)
					{
						numScore.kill();
						comboNums.remove(numScore, true);
						numScore.destroy();
					}
					instance.cleanupTween(tween);
				},
				startDelay: tweenTime
			}));
		});
		instance.modchartTweens.push(comboTwn = FlxTween.tween(this, {alpha: 0}, tweenTime, {
			startDelay: doubleCrochet,
			onComplete: function(twn:FlxTween)
			{
				kill();
				instance.cleanupTween(twn);
			}
		}));

		var groupX:Float = FlxG.width * .35;
		if (PlayState.instance.shitFlipped)
			groupX = FlxG.width - groupX;
		x = groupX;
	}

	public function setupGroup()
	{
		if (comboTwn != null)
		{
			comboTwn.cancel();
			comboTwn.destroy();

			comboTwn = null;
		}

		if (ratingSprite != null)
		{
			ratingSprite.kill();
			remove(ratingSprite, true);

			ratingSprite.destroy();
			ratingSprite = null;
		}
		if (comboSprite != null)
		{
			comboSprite.kill();
			remove(comboSprite, true);

			comboSprite.destroy();
			comboSprite = null;
		}
		comboNums.forEach(function(comboNum:FlxSprite)
		{
			comboNum.kill();
			comboNums.remove(comboNum);
			comboNum.destroy();
		});
		alpha = 1;
	}

	public function showComboSprite()
	{
		var comboOffset:Array<Int> = ClientPrefs.getPref('comboOffset');
		var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');

		comboSprite = new FlxSprite(-40).loadGraphic(Paths.image('combo', PlayState.otherAssetsLibrary));
		comboSprite.screenCenter(Y);

		comboSprite.x += comboOffset[5];
		comboSprite.y -= comboOffset[4];

		comboSprite.acceleration.y = 200;
		comboSprite.velocity.y -= 140;

		comboSprite.velocity.x += FlxG.random.int(1, 10);
		comboSprite.antialiasing = globalAntialiasing;

		comboSprite.setGraphicSize(Std.int(comboSprite.width * switch (PlayState.introKey)
		{
			case 'compressed': .7;
			default: .5;
		}));

		comboSprite.updateHitbox();
		add(comboSprite);
	}

	public function showComboNums(combo:Int)
	{
		var comboOffset:Array<Int> = ClientPrefs.getPref('comboOffset');
		var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');

		var seperatedScore:Array<Int> = [];
		if (combo >= 1000)
			seperatedScore.push(Math.floor(combo / 1000) % 10);

		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);

		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite((43 * daLoop) - 90).loadGraphic(Paths.image('num$i', PlayState.otherAssetsLibrary));

			numScore.antialiasing = globalAntialiasing;
			numScore.screenCenter(Y);

			numScore.y -= comboOffset[3] - 80;
			numScore.x += comboOffset[2];

			numScore.setGraphicSize(Std.int(numScore.width * switch (PlayState.introKey)
			{
				case 'compressed': .5;
				default: 1;
			}));

			numScore.updateHitbox();
			numScore.acceleration.y = FlxG.random.int(200, 300);

			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			comboNums.add(numScore);
			daLoop++;
		}
	}

	public function showRatingSprite(daRating:Rating)
	{
		var instance:PlayState = PlayState.instance;

		var comboOffset:Array<Int> = ClientPrefs.getPref('comboOffset');
		var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');

		ratingSprite = new FlxSprite(-40).loadGraphic(Paths.image(daRating.image, PlayState.otherAssetsLibrary));

		ratingSprite.screenCenter(Y);
		ratingSprite.y -= 60;

		ratingSprite.x += comboOffset[0];
		ratingSprite.y -= comboOffset[1];

		ratingSprite.acceleration.y = 550;
		ratingSprite.velocity.y -= 140;

		ratingSprite.antialiasing = globalAntialiasing;

		ratingSprite.setGraphicSize(Std.int(ratingSprite.width * .7));
		ratingSprite.updateHitbox();

		var lastRatingSprite:FlxSprite = ratingSprite;
		var tweenTime:Float = Conductor.crochet / 1000;

		instance.modchartTweens.push(FlxTween.tween(lastRatingSprite, {alpha: 0}, tweenTime * 2, {
			startDelay: tweenTime / 2,
			onComplete: function(twn:FlxTween)
			{
				if (lastRatingSprite == ratingSprite && ratingSprite != null)
				{
					lastRatingSprite.kill();
					remove(lastRatingSprite, true);

					lastRatingSprite.destroy();
					ratingSprite = null;

					instance.cleanupTween(twn);
				}
			}
		}));
		add(lastRatingSprite);
	}
}
