package meta.instances.stages;

import shaders.PixelationShader.PixelationEffect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import shaders.ChromaticAberrationShader.ChromaticAberrationEffect;
import shaders.CRTDistortionShader.CRTDistortionEffect;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import states.PlayState;
import flixel.FlxG;
import meta.data.ClientPrefs;

class Relapse extends BaseStage
{
	private inline static final BACKGROUND_PLATFORM_SPEED:Float = 890;
	private inline static final FOREGROUND_PLATFORM_SPEED:Float = 750;
	// 0.37 is the ref czM zoom
	private inline static final FLOAT_SPEED:Float = 600;
	private inline static final FOG_SPEED:Float = 500;

	private inline static final UPSCALING:Float = 1.8;

	private inline static final FRONT_PILLAR_Y:Float = -80 * UPSCALING;
	private inline static final BACK_PILLAR_Y:Float = -120 * UPSCALING;

	private inline static final FLOAT_START_Y:Float = 480;

	public inline static final DEFAULT_CHROMATIC_ABERRATION:Float = .05;
	public inline static final DEFAULT_CRT_DISTORTION:Float = .4;

	private static var tau:Float = Math.PI * 2;

	private var relapseFloating:Bool = false;
	private var relapseSpikes:Bool = false;

	private var floatY:Float = FLOAT_START_Y;

	private var floatStartY:Float = 0;
	private var floatAlpha:Float = 0;

	public var frontPillars:BGSprite;
	public var backPillars:BGSprite;

	public var spikes:BGSprite;

	private var fog:BGSprite;

	public var chromaticAberration:ChromaticAberrationEffect;
	public var crtDistortion:CRTDistortionEffect;

	public var pixelation:PixelationEffect;
	public var pixelationFilter:ShaderFilter;

	public var gameFilter:Array<BitmapFilter> = [];
	public var hudFilter:Array<BitmapFilter> = [];

	override function new(parent:Dynamic)
	{
		super(parent);

		var lowQuality:Bool = ClientPrefs.getPref('lowQuality');
		var bg:BGSprite = new BGSprite('relapse/background', -FlxG.width / 2, -FlxG.height / 2, .2, .2);

		bg.setGraphicSize(Std.int(bg.width * UPSCALING));
		bg.updateHitbox();

		spikes = new BGSprite('relapse/spikes', -300 * UPSCALING * .8, 0, .4, .4);

		spikes.setGraphicSize(Std.int(spikes.width * UPSCALING * .8));
		spikes.updateHitbox();

		spikes.visible = false;
		var cliff:BGSprite = new BGSprite('relapse/cliff', -50 * UPSCALING, -75 * UPSCALING, .95, .95);

		cliff.setGraphicSize(Std.int(cliff.width * UPSCALING));
		cliff.updateHitbox();

		var bfRock:BGSprite = new BGSprite('relapse/bfrock');

		bfRock.setGraphicSize(Std.int(bfRock.width * UPSCALING));
		bfRock.updateHitbox();

		var arch:BGSprite = new BGSprite('relapse/arch');

		arch.setGraphicSize(Std.int(arch.width * UPSCALING));
		arch.updateHitbox();

		addToStage(bg);
		if (!lowQuality)
		{
			fog = new BGSprite('relapse/fog', -600 * UPSCALING, -100 * UPSCALING, .3, .3);

			fog.setGraphicSize(Std.int(fog.width * UPSCALING));
			fog.updateHitbox();

			backPillars = new BGSprite('relapse/pillars', -170 * UPSCALING, BACK_PILLAR_Y, .75, .75);

			backPillars.setGraphicSize(Std.int(backPillars.width * UPSCALING));
			backPillars.updateHitbox();

			addToStage(fog);
		}

		addToStage(spikes);
		addToStage(cliff);

		if (backPillars != null)
			addToStage(backPillars);

		addToStage(bfRock);
		addToStage(arch);

		if (!lowQuality)
		{
			frontPillars = new BGSprite('relapse/frontpillars', -90 * UPSCALING, FRONT_PILLAR_Y, .95, .95);

			frontPillars.setGraphicSize(Std.int(frontPillars.width * UPSCALING));
			frontPillars.updateHitbox();

			addBehindBF(frontPillars, 1);
			var noiseGraphic:FlxGraphic = Paths.image('noise');

			var noise:FlxSprite = new FlxSprite().loadGraphic(noiseGraphic, true, Std.int(noiseGraphic.width / 4), Std.int(noiseGraphic.height / 4));
			var vignette:FlxSprite = new FlxSprite().loadGraphic(Paths.image('miyamotoVignette'));

			noise.setGraphicSize(FlxG.width, FlxG.height);
			noise.updateHitbox();

			noise.screenCenter();
			noise.alpha = .1;

			noise.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int)
			{
				noise.flipX = FlxG.random.bool();
				noise.flipY = FlxG.random.bool();
			};

			noise.animation.add('noise', [0, 1, 2, 3], 24, true);
			noise.animation.play('noise');

			noise.antialiasing = vignette.antialiasing = ClientPrefs.getPref('globalAntialiasing');
			noise.cameras = vignette.cameras = [parent.camOther];

			vignette.setGraphicSize(FlxG.width, FlxG.height);
			vignette.updateHitbox();

			vignette.screenCenter();
			vignette.alpha = .75;

			vignette.scrollFactor.set();
			noise.scrollFactor.set();

			add(noise);
			add(vignette);
		}
	}

	override function onSongStart()
	{
		PlayState.barsAssets = 'relapse';
		super.onSongStart();
	}

	override function onStageAdded()
	{
		if (ClientPrefs.getPref('shaders'))
		{
			crtDistortion = new CRTDistortionEffect();
			crtDistortion.distortionFactor = DEFAULT_CRT_DISTORTION;

			chromaticAberration = new ChromaticAberrationEffect();
			chromaticAberration.strength = DEFAULT_CHROMATIC_ABERRATION;

			pixelation = new PixelationEffect();
			pixelation.size = 8;

			pixelationFilter = new ShaderFilter(pixelation.shader);
			var aberrationFilter:ShaderFilter = new ShaderFilter(chromaticAberration.shader);

			gameFilter = [aberrationFilter, new ShaderFilter(crtDistortion.shader)];
			hudFilter = [aberrationFilter];

			parent.camGame.setFilters(gameFilter);
			parent.camHUD.setFilters(hudFilter);
		}
		super.onStageAdded();
	}

	public function showSpikes()
	{
		if (!relapseSpikes)
		{
			relapseSpikes = true;

			spikes.y = (FlxG.height + spikes.height) * .5;
			spikes.alpha = 0;

			spikes.visible = true;

			parent.modchartTweens.push(FlxTween.tween(spikes, {y: -250 * UPSCALING * .8}, Conductor.crochet / 250,
				{ease: FlxEase.backOut, onComplete: parent.cleanupTween}));
			parent.modchartTweens.push(FlxTween.tween(spikes, {alpha: 1}, Conductor.crochet / 1000, {ease: FlxEase.sineOut, onComplete: parent.cleanupTween}));
			// y: -250 * UPSCALING * .8
		}
	}

	// https://www.youtube.com/watch?v=ineRAzi68Js
	public function startRisingInTheSky()
	{
		floatStartY = parent.stageData.opponent[1];
		floatAlpha = 0;

		relapseFloating = true;
	}

	public function togglePixelation(enabled:Bool = false)
	{
		var contains:Bool = gameFilter.contains(pixelationFilter);
		if (enabled)
		{
			if (!contains)
				gameFilter.insert(0, pixelationFilter);
		}
		else if (contains)
		{
			gameFilter.remove(pixelationFilter);
		}
	}

	override function destroy()
	{
		parent.camGame.setFilters([]);
		parent.camHUD.setFilters([]);

		super.destroy();
	}

	override function beatHit(beat:Int)
	{
		if (!ClientPrefs.getPref('reducedMotion'))
		{
			if ((beat % 4) == 0 && FlxG.random.bool(15))
				parent.camHUD.shake(1 / FlxG.random.float(15, 20), (Conductor.stepCrochet / 1000) * FlxG.random.int(1, 2), null, true);
			if (parent.gameShakeAmount <= 0 && relapseFloating && (beat % 2) == 0)
				parent.camGame.shake(1 / FlxG.random.float(150, 200), Conductor.crochet / 1000, null, false);
		}
		super.beatHit(beat);
	}

	override function update(elapsed:Float)
	{
		var songPosition:Float = Conductor.songPosition;
		if (fog != null)
			fog.alpha = .1 + Math.abs(Math.sin((songPosition / FOG_SPEED) % Math.PI) * .9);

		if (frontPillars != null)
		{
			frontPillars.y = FRONT_PILLAR_Y + Math.sin((songPosition / FOREGROUND_PLATFORM_SPEED) % tau) * 30;
			frontPillars.angle = Math.cos((songPosition / FOREGROUND_PLATFORM_SPEED) % tau) * 2;

			if (backPillars != null)
				backPillars.angle = -frontPillars.angle;
		}
		if (backPillars != null)
			backPillars.y = BACK_PILLAR_Y + Math.cos((Math.PI + (songPosition / BACKGROUND_PLATFORM_SPEED)) % tau) * 60;

		if (relapseFloating)
		{
			if (floatAlpha < 1)
				floatAlpha = Math.min(floatAlpha + elapsed, 1);

			floatY = FLOAT_START_Y + (Math.cos((Math.PI + (songPosition / FLOAT_SPEED)) % tau) * 60);

			parent.dad.x = parent.stageData.opponent[0];
			parent.dad.y = floatStartY + ((floatY - floatStartY) * FlxEase.backOut(floatAlpha));

			parent.startCharacterPos(parent.dad);
		}
		super.update(elapsed);
	}
}
