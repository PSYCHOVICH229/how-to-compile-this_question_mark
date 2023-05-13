package states.substates;

import flixel.FlxSprite;
import meta.PlayerSettings;
import meta.instances.Character;
import meta.Conductor;
import shaders.ColorSwap;
import flixel.animation.FlxAnimation;
import states.freeplay.FreeplayState;
import flixel.FlxG;
import meta.CoolUtil;
import meta.data.ClientPrefs;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class GameOverSubstate extends MusicBeatSubstate
{
	public inline static final neededShitsFailed:Int = 2;

	public var dead:FlxSprite;
	public var boyfriend:Character;

	public static var deathSoundName:String;
	public static var endSoundName:String;
	public static var loopSoundName:String;
	public static var characterName:String;

	public static var deathSoundLibrary:String = null;
	public static var loopSoundLibrary:String = null;
	public static var endSoundLibrary:String = null;

	public static var instance:GameOverSubstate;
	public static var conductorBPM:Float;

	private var dumbassZoom:Float = 1;

	private var isFollowingAlready:Bool = false;
	private var isEnding:Bool = false;

	private var lastBeat:Int = -1;

	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;

	private var updateCamera:Bool = false;
	private var playingDeathSound:Bool = false;

	private var swagShader:ColorSwap = null;
	public inline static function resetVariables()
	{
		deathSoundName = 'fnf_loss_sfx';
		characterName = 'bf';

		endSoundName = 'diecon';
		loopSoundName = 'over';

		deathSoundLibrary = null;
		loopSoundLibrary = null;
		endSoundLibrary = null;

		conductorBPM = 130;
	}

	override function create()
	{
		instance = this;
		super.create();
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float)
	{
		super();
		Conductor.songPosition = 0;

		switch (characterName)
		{
			case 'deadleman':
			{
				trace('deadleman');
				dead = new FlxSprite().loadGraphic(Paths.image('he_died'));

				dead.screenCenter(X);
				dead.updateHitbox();

				dead.antialiasing = ClientPrefs.getPref('globalAntialiasing');
				camFollow = new FlxPoint(dead.getGraphicMidpoint().x, dead.getGraphicMidpoint().y);

				add(dead);
			}
			default:
			{
				boyfriend = new Character(x, y, characterName, true);

				boyfriend.x += boyfriend.positionArray[0];
				boyfriend.y += boyfriend.positionArray[1];

				boyfriend.playAnim('firstDeath');
				camFollow = new FlxPoint(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);

				add(boyfriend);
			}
		}
		switch (deathSoundLibrary)
		{
			case 'shuttleman':
				{
					swagShader = new ColorSwap();
					swagShader.speed = .1;

					if (dead != null)
						dead.shader = swagShader.shader;
					if (boyfriend != null)
						boyfriend.shader = swagShader.shader;
				}
		}

		var instance:PlayState = PlayState.instance;
		dumbassZoom = switch (Paths.formatToSongPath(characterName))
		{
			default:
				instance?.stageData?.defaultZoom ?? FlxG.camera.initialZoom;
			case 'daniyar':
				.5;
		}

		FlxG.sound.play(Paths.sound(deathSoundName, deathSoundLibrary));
		Conductor.changeBPM(conductorBPM);
		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));

		add(camFollowPos);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (updateCamera)
		{
			var lerpVal:Float = FlxMath.bound(elapsed * 2, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (ClientPrefs.getPref('camZooms'))
		{
			FlxG.camera.zoom = FlxMath.lerp(dumbassZoom, FlxG.camera.zoom, FlxMath.bound(1 - (elapsed * Math.PI), 0, 1));
		}
		else
		{
			FlxG.camera.zoom = dumbassZoom;
		}

		if (PlayerSettings.controls.is(ACCEPT))
		{
			endBullshit();
		}
		else if (PlayerSettings.controls.is(BACK) && !isEnding)
		{
			FlxG.sound.music.stop();

			PlayState.mechanicsEnabled = ClientPrefs.getPref('mechanics');
			PlayState.deathCounter = 0;

			PlayState.chartingMode = false;
			PlayState.seenCutscene = false;

			if (PlayState.isStoryMode)
			{
				MusicBeatState.switchState(new StoryMenuState());
			}
			else
			{
				FreeplayState.exitToFreeplay();
			}

			TitleState.playTitleMusic();
		}

		if (dead != null)
		{
			if (!isFollowingAlready)
			{
				FlxG.camera.follow(camFollowPos, LOCKON, 1);
				isFollowingAlready = updateCamera = true;
			}
			if (!playingDeathSound)
				coolStartDeath();
		}
		else if (boyfriend != null)
		{
			var curAnim:FlxAnimation = boyfriend.animation.curAnim;
			if (curAnim != null && curAnim.name == 'firstDeath')
			{
				var formattedName:String = Paths.formatToSongPath(characterName);
				var shitFartAssFrame:Int = switch (formattedName)
				{
					case 'funnybf-playable': 26;
					case 'daniyar': 6;

					default: 12;
				}
				if ((curAnim.curFrame >= shitFartAssFrame || curAnim.finished) && !isFollowingAlready)
				{
					FlxG.camera.follow(camFollowPos, LOCKON, 1);
					switch (deathSoundLibrary)
					{
						case 'clown':
							FlxG.sound.play(Paths.sound('Micdrop', deathSoundLibrary));
					}
					isFollowingAlready = updateCamera = true;
				}
				if (curAnim.finished && !boyfriend.startedDeath && !playingDeathSound)
					coolStartDeath();
			}
		}

		if (FlxG.sound.music.playing)
			Conductor.songPosition = FlxG.sound.music.time;
		if (swagShader != null)
		{
			var delta:Int = PlayerSettings.controls.diff(UI_RIGHT, UI_LEFT, PRESSED, PRESSED);
			if (delta != 0)
				swagShader.update(elapsed, delta); // swagShader.hue = (swagShader.hue + (elapsed * delta * .1)) % 360;
		}
	}

	override function beatHit()
	{
		super.beatHit();
		if (lastBeat != curBeat && !isEnding)
		{
			if (boyfriend != null)
			{
				if (!boyfriend.startedDeath)
					return;
				if (boyfriend.animation.name == 'deathLoop' && boyfriend.animation.finished)
					boyfriend.playAnim('deathLoop', true);
			}
			if (ClientPrefs.getPref('camZooms'))
				FlxG.camera.zoom += PlayState.HUD_BOP;
		}
		lastBeat = curBeat;
	}

	private function coolStartDeath(?volume:Float = 1):Void
	{
		if (playingDeathSound)
			return;
		if (boyfriend != null)
		{
			if (boyfriend.startedDeath)
				return;
			boyfriend.startedDeath = true;
		}
		playingDeathSound = true;

		FlxG.sound.playMusic(Paths.music(loopSoundName, loopSoundLibrary), volume);
		beatHit();
	}

	private inline function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			if (boyfriend != null)
				boyfriend.playAnim('deathConfirm', true);

			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName, endSoundLibrary));

			new FlxTimer().start(.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					if (!PlayState.chartingMode
						&& PlayState.mechanicsEnabled
						&& ClientPrefs.getPref('mechanics')
						&& (PlayState.instance?.shitsFailedLol ?? -1) >= neededShitsFailed
							&& PlayState.deathCounter > 0
							&& (PlayState.deathCounter % DisableMechanicsState.deathAmount) == 0)
					{
						trace('died too many times ask if they wanna tun off machanics');
						MusicBeatState.switchState(new DisableMechanicsState());
					}
					else
					{
						MusicBeatState.resetState();
					}
				});
			});
		}
	}
}
