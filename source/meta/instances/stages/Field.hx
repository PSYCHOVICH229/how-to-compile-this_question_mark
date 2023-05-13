package meta.instances.stages;

import shaders.ChromaticAberrationShader.ChromaticAberrationEffect;
import openfl.filters.ShaderFilter;
import meta.data.ClientPrefs;
import flixel.FlxG;
import flixel.FlxSprite;
import openfl.filters.BitmapFilter;

class Field extends BaseStage
{
	public inline static final DEFAULT_CHROMATIC_ABERRATION:Float = .065;

	public var gameFilter:Array<BitmapFilter> = [];
	public var hudFilter:Array<BitmapFilter> = [];

	public var chromaticAberration:ChromaticAberrationEffect;
	public var staticOverlay:FlxSprite;

	override function new(parent:Dynamic)
	{
		super(parent);
		var bg:BGSprite = new BGSprite('kill/field/background', 300, -70, .2, .2);

		addToStage(bg);
		addToStage(new BGSprite('kill/field/foregrounds'));

		if (!ClientPrefs.getPref('lowQuality'))
		{
			insert(parent.members.indexOf(bg), new BGSprite('kill/field/clouds', 200, 100, .4, .4));
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
		super.onStageAdded();
	}

	override function destroy()
	{
		parent.camGame.setFilters([]);
		parent.camHUD.setFilters([]);

		super.destroy();
	}
}
