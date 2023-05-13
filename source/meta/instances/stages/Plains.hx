package meta.instances.stages;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.filters.ShaderFilter;
import shaders.WavyEffect;
import flixel.group.FlxGroup.FlxTypedGroup;
import states.PlayState;
import meta.data.ClientPrefs;

using StringTools;

class Plains extends BaseStage
{
	private var stageGroup:FlxTypedGroup<BGSprite>;

	private var wavyShader:WavyEffect;
	private var duoOpponent:Character;

	private var bgDancers:BGSprite;
	private var fgDancers:BGSprite;

	private var funnyGF:BGSprite;

	override function new(parent:Dynamic)
	{
		super(parent);
		var bg:BGSprite = new BGSprite('youtooz', -800, -550);

		bg.setGraphicSize(Std.int(bg.width * 3));
		bg.updateHitbox();

		addToStage(bg);

		stageGroup = new FlxTypedGroup();
		stageGroup.active = false;

		addToStage(stageGroup);
	}

	override function onSongStart()
	{
		var curSong:String = parent.curSong;
		switch (curSong)
		{
			case 'cervix':
				{
					if (ClientPrefs.getPref('shaders'))
					{
						wavyShader = new WavyEffect();
						wavyShader.amplitude = 0;

						parent.shaders.push(wavyShader);
						parent.camGame.setFilters([new ShaderFilter(wavyShader.shader)]);
					}
				}
			case 'intestinal-failure' | 'funny-duo' | 'abrasive':
				{
					killDuoOpponent();

					duoOpponent = new Character(0, 0, PlayState.SONG.player2.endsWith('youtooz') ? 'funnybf' : 'funnybf-youtooz');
					duoOpponent.active = false;

					addBehindBF(duoOpponent);
					parent.duoOpponent = duoOpponent;

					parent.DUO_X = -350;
					parent.DUO_Y = 125;

					funnyGF = new BGSprite('background/gametoons-gf', 275, 300, 1, 1, ['idle']);
					stageGroup.add(funnyGF);

					addToStage(funnyGF);
					if (!ClientPrefs.getPref('lowQuality'))
					{
						switch (curSong)
						{
							case 'funny-duo':
								{
									fgDancers = new BGSprite('background/funny_duo_foreground_dancers', -640, 345, .95, .25, ['idle']);
									bgDancers = new BGSprite('background/funny_duo_background_dancers', -240, 172, 1, 1, ['idle']);

									bgDancers.setGraphicSize(Std.int(bgDancers.width * .8));
									fgDancers.setGraphicSize(Std.int(fgDancers.width * .7));

									bgDancers.updateHitbox();
									fgDancers.updateHitbox();

									stageGroup.add(bgDancers);
									stageGroup.add(fgDancers);

									addBehindGF(bgDancers, 1);
									add(fgDancers);
								}
						}
					}
				}
		}
		super.onSongStart();
	}

	public inline function toggleWavy(enabled:Bool = false)
	{
		if (wavyShader != null)
			wavyShader.amplitude = enabled ? .07 : 0;
	}

	private inline function killDuoOpponent()
	{
		if (duoOpponent != null)
		{
			duoOpponent.kill();
			parent.dadGroup.remove(duoOpponent, true);

			if (duoOpponent == parent.duoOpponent)
				parent.duoOpponent = null;
			remove(duoOpponent, true);

			duoOpponent.destroy();
			duoOpponent = null;
		}
	}

	override function beatHit(beat:Int)
	{
		if (beat % parent.gfSpeed == 0)
		{
			stageGroup.forEach(function(stageInstance:BGSprite)
			{
				stageInstance.dance(true);
			});
		}
		super.beatHit(beat);
	}

	override function update(elapsed:Float)
	{
		if (duoOpponent != null)
			duoOpponent.update(elapsed);
		super.update(elapsed);
	}

	override function destroy()
	{
		killDuoOpponent();
		if (wavyShader != null)
		{
			parent.shaders.remove(wavyShader);
			parent.camGame.setFilters([]);
		}
		super.destroy();
	}
}
