package meta.instances.stages;

import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import shaders.ChromaticAberrationShader.ChromaticAberrationEffect;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import states.PlayState;
import flixel.util.FlxStringUtil;
import flixel.FlxG;
import meta.data.ClientPrefs;
import flixel.text.FlxText;

class Lobby extends BaseStage
{
	public inline static final DEFAULT_CHROMATIC_ABERRATION:Float = .065;
	public inline static final DEFAULT_STATIC_ALPHA:Float = .05;

	public var gameFilter:Array<BitmapFilter> = [];
	public var hudFilter:Array<BitmapFilter> = [];

	public var chromaticAberration:ChromaticAberrationEffect;
	public var customTimer:FlxText;

	public var staticOverlayTwn:FlxTween;
	public var staticOverlay:FlxSprite;

	public var boppers:BGSprite;

	override function new(parent:Dynamic)
	{
		super(parent);

		var bg:BGSprite = new BGSprite('kill/lobby/background');
		customTimer = new FlxText(705, 195, FlxG.width).setFormat(Paths.font('vcr.ttf'), 128, 0xFFD42B2B, CENTER, OUTLINE, 0xFF631E1E);

		customTimer.borderSize = 8;
		customTimer.alpha = 0;

		addToStage(bg);
		addToStage(customTimer);

		if (!ClientPrefs.getPref('lowQuality'))
		{
			boppers = new BGSprite('kill/lobby/redboppers', 900, 730, 1, 1, true, ['bop'], false);

			boppers.setGraphicSize(Std.int(boppers.width * 1.35));
			boppers.updateHitbox();

			addBehindDad(boppers);
			var vignette:FlxSprite = new FlxSprite().loadGraphic(Paths.image('miyamotoVignette'));

			vignette.setGraphicSize(FlxG.width, FlxG.height);
			vignette.updateHitbox();

			vignette.screenCenter();
			vignette.alpha = .8;

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
			staticOverlay.alpha = DEFAULT_STATIC_ALPHA;

			add(staticOverlay);
		}
	}

	override function onStageAdded()
	{
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

		updateTime();
		super.onStageAdded();
	}

	override function onSongStart()
	{
		PlayState.barsAssets = 'killgames';
		super.onSongStart();
	}

	override function beatHit(beat:Int)
	{
		if (boppers != null && (beat % parent.dad.danceEveryNumBeats) == 0)
			boppers.dance(true);
		super.beatHit(beat);
	}

	private function updateTime()
	{
		var curTime:Float = Conductor.songPosition - ClientPrefs.getPref('noteOffset');
		var lengthUsing:Float = (parent.maskedSongLength > 0) ? parent.maskedSongLength : parent.songLength;

		customTimer.text = FlxStringUtil.formatTime(Math.floor(Math.max((lengthUsing - curTime) / 1000, 0)), false);
		customTimer.alpha = lengthUsing > 0 ? Math.max(Math.min((curTime / 1000) - 1, .5), 0) : 0;

		if (parent.timeBar != null)
			parent.timeBar.visible = false;
	}

	override function destroy()
	{
		parent.camGame.setFilters([]);
		parent.camHUD.setFilters([]);

		if (staticOverlayTwn != null)
		{
			staticOverlayTwn.cancel();
			parent.cleanupTween(staticOverlayTwn);
			staticOverlayTwn = null;
		}
		if (parent.timeBar != null)
			parent.timeBar.visible = true;
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		updateTime();
		super.update(elapsed);
	}
}
