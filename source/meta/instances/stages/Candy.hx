package meta.instances.stages;

import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import shaders.ChromaticAberrationShader.ChromaticAberrationEffect;
import openfl.filters.ShaderFilter;
import meta.data.ClientPrefs;
import flixel.FlxG;
import flixel.FlxSprite;
import openfl.filters.BitmapFilter;

class Candy extends BaseStage
{
	public inline static final DEFAULT_CHROMATIC_ABERRATION:Float = .04;

	public var gameFilter:Array<BitmapFilter> = [];
	public var hudFilter:Array<BitmapFilter> = [];

	public var chromaticAberration:ChromaticAberrationEffect;

	public var evilBeast:Character;
	public var deadBeast:BGSprite;

	public var staticOverlay:FlxSprite;
	public var boppers:BGSprite;

	public var evilBeastDead:Bool = false;
	public var evilEntered:Bool = false;

	override function new(parent:Dynamic)
	{
		super(parent);

		var bg:BGSprite = new BGSprite('kill/candygame/background');
		var props:BGSprite = new BGSprite('kill/candygame/props');

		addToStage(bg);
		addBehindBF(props);

		deadBeast = new BGSprite('kill/candygame/Dead_Beast', 1800, 950, 1, 1, true);
		deadBeast.visible = false;

		deadBeast.kill();

		deadBeast.setGraphicSize(Std.int(deadBeast.width * .5));
		deadBeast.updateHitbox();

		addBehindBF(deadBeast);
		deadBeast.kill();

		evilBeast = new Character(0, 0, 'evilbeast', false);
		evilBeast.active = false;

		evilBeast.alpha = FlxMath.EPSILON;

		addBehindBF(evilBeast);
		evilBeast.kill();

		if (!ClientPrefs.getPref('lowQuality'))
		{
			boppers = new BGSprite('kill/candygame/bopgames', 927, 640, 1, 1, true, ['boppers']);

			boppers.setGraphicSize(Std.int(boppers.width * 1.2));
			boppers.updateHitbox();

			addBehindDad(boppers);
			var vignette:FlxSprite = new FlxSprite().loadGraphic(Paths.image('miyamotoVignette'));

			vignette.setGraphicSize(FlxG.width, FlxG.height);
			vignette.updateHitbox();

			vignette.screenCenter();
			vignette.alpha = .75;

			vignette.cameras = [parent.camOther];
			vignette.scrollFactor.set();

			add(vignette);
		}
		if (ClientPrefs.getPref('flashing'))
		{
			staticOverlay = new FlxSprite().loadGraphic(Paths.image('arcade/static'), true, Std.int(FlxG.width / 4), Std.int(FlxG.height / 4));

			staticOverlay.setGraphicSize(FlxG.width, FlxG.height);
			staticOverlay.updateHitbox();

			staticOverlay.screenCenter();
			staticOverlay.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int)
			{
				staticOverlay.flipX = FlxG.random.bool();
				staticOverlay.flipY = FlxG.random.bool();
			};

			staticOverlay.animation.add('static', [0, 1, 2, 3], 24, true);
			staticOverlay.animation.play('static', true);

			staticOverlay.cameras = [parent.camOther];
			staticOverlay.alpha = Lobby.DEFAULT_STATIC_ALPHA;

			add(staticOverlay);
		}
	}

	private inline function killDuoOpponent()
	{
		if (evilBeast != null)
		{
			evilBeast.kill();
			parent.dadGroup.remove(evilBeast, true);

			if (evilBeast == parent.duoOpponent)
				parent.duoOpponent = null;
			remove(evilBeast, true);

			evilBeast.destroy();
			evilBeast = null;
		}
	}

	public inline function killEvilBeast()
	{
		if (!evilBeastDead)
		{
			evilBeastDead = true;
			evilBeast.visible = false;

			evilBeast.kill();

			deadBeast.visible = true;
			deadBeast.revive();
		}
	}

	public inline function enterEvil()
	{
		if (!evilEntered)
		{
			evilEntered = true;

			evilBeast.x += FlxG.width;
			evilBeast.alpha = 1;

			parent.modchartTweens.push(FlxTween.tween(evilBeast, {x: parent.DAD_X + parent.DUO_X}, 1,
				{ease: FlxEase.sineInOut, onComplete: parent.cleanupTween}));
		}
	}

	override function onStageAdded()
	{
		parent.DUO_X = 560;
		parent.DUO_Y = 200;

		parent.duoOpponent = evilBeast;
		if (ClientPrefs.getPref('shaders'))
		{
			chromaticAberration = new ChromaticAberrationEffect();
			chromaticAberration.strength = DEFAULT_CHROMATIC_ABERRATION;

			var aberrationFilter:ShaderFilter = new ShaderFilter(chromaticAberration.shader);

			gameFilter = [aberrationFilter];
			hudFilter = [aberrationFilter];

			parent.camGame.setFilters(gameFilter);
			parent.camHUD.setFilters(hudFilter);
		}
		super.onStageAdded();
	}

	override function beatHit(beat:Int)
	{
		if (boppers != null && (beat % parent.dad.danceEveryNumBeats) == 0)
			boppers.dance(true);
		super.beatHit(beat);
	}

	override function update(elapsed:Float)
	{
		evilBeast?.update(elapsed);
		super.update(elapsed);
	}

	override function destroy()
	{
		parent.camGame.setFilters([]);
		parent.camHUD.setFilters([]);

		killDuoOpponent();
		super.destroy();
	}
}
