package states;

import flixel.group.FlxSpriteGroup;
import flixel.addons.display.FlxBackdrop;
import flixel.sound.FlxSound;
import lime.ui.Window;
import meta.InputFormatter;
import flixel.FlxCamera;
#if GAMEJOLT_ALLOWED
import states.gamejolt.*;
#end
import meta.data.ClientPrefs;
import meta.CoolUtil;
import meta.data.Song;
import meta.Conductor;
import meta.data.Highscore;
import meta.PlayerSettings;
import states.freeplay.FreeplayState;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Json;
import openfl.Lib;
import openfl.Assets;
import meta.Discord.DiscordClient;
import meta.instances.Alphabet;
import meta.Achievements;

using StringTools;

typedef TitleData =
{
	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	backgroundSprite:String,
	bpm:Int
}

class TitleState extends MusicBeatState
{
	private inline static final BACKDROP_SCALE:Float = 1.6;
	private inline static final LOGO_SCALE:Float = 1.15;

	private inline static final TYPE:String = 'bendhard';
	private inline static final EXITING_AT:Float = 1.5;

	public static var loopingDisableMechanics:Bool = false;
	public static var initialized:Bool = false;

	private static var titleJSON:TitleData;
	private inline static final tooMany:Int = 24;

	private var sickBeats:Int = -1; // Basically curBeat but won't be skipped if you hold the tab or resize the screen

	public static var closedState:Bool = false;

	private var exitElapsed:Float = 0;
	private var exitTimer:Float = 0;

	private var canYouFuckingWait:Bool = false;
	private var skippedIntro:Bool = false;

	private var typeTween:FlxTween;

	private var typeArray:Array<String>;
	private var typed:FlxText;

	private var credGroup:FlxGroup;
	private var credTextShit:Alphabet;

	private var textGroup:FlxGroup;

	private var curWacky:Array<Array<String>> = [];

	private var camTransition:FlxCamera;
	private var camOther:FlxCamera;
	private var camGame:FlxCamera;

	private var bopRight:Bool = false;
	private var camAngleTwn:FlxTween;

	private var exiting:FlxSprite;
	private var acceptButton:FlxSprite;

	private var titleGroup:FlxSpriteGroup;

	private var funnyLogo:FlxSprite;
	private var transitioning:Bool = false;

	private var tiles:FlxBackdrop;
	private var backdropTimer:Float = 0;

	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		persistentUpdate = persistentDraw = true;
		titleJSON = Json.parse(Assets.getText(Paths.getPreloadPath("images/titleJSON.json")));

		camTransition = new FlxCamera();
		camOther = new FlxCamera();
		camGame = new FlxCamera();

		camTransition.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);

		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camTransition, false);

		CustomFadeTransition.nextCamera = camTransition;
		refreshArray();

		FlxG.game.focusLostFramerate = 30;
		FlxG.keys.preventDefaultKeys = [TAB];

		CoolUtil.toggleVolumeKeys(true);
		PlayerSettings.init();
		/// 3 messages
		for (i in 0...3)
			curWacky.push(rollWacky(curWacky));
		super.create();

		FlxG.save.bind(BALLFART.DATA_BIND);
		ClientPrefs.loadPrefs();
		#if GAMEJOLT_ALLOWED
		// initialize here, silly billy :)
		FlxGameJoltCustom.verbose = true;
		if (!FlxGameJoltCustom.initialized)
			FlxGameJoltCustom.init(APIStuff.gameJoltID, APIStuff.gameJoltKey, false);
		GameJolt.loadAccount(ClientPrefs.getPref('gameJoltUsername'), ClientPrefs.getPref('gameJoltToken'));
		#end

		FlxG.fixedTimestep = false;
		FlxG.mouse.visible = false;

		if (!ClientPrefs.getPref('flashWarning') && !FlashingState.leftState)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;

			MusicBeatState.switchState(new FlashingState());
		}
		else
		{
			canYouFuckingWait = true;
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				startIntro();
			});
		}
	}

	public inline static function playTitleMusic(volume:Float = 1)
	{
		FlxG.sound.playMusic(Paths.music('menu_theme'), volume);
		if (titleJSON != null)
			Conductor.changeBPM(titleJSON.bpm);
	}

	private inline function startIntro()
	{
		persistentUpdate = true;

		var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');
		titleGroup = new FlxSpriteGroup();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, CoolerTransition.BACKGROUND_COLOR);

		tiles = new FlxBackdrop(Paths.image('ui/transition/tile'), XY);
		tiles.setGraphicSize(Std.int(tiles.width * BACKDROP_SCALE));

		tiles.scrollFactor.set(1, 1);
		tiles.alpha = .4;

		var staticOverlay:FlxSprite = new FlxSprite().loadGraphic(Paths.image('arcade/static'), true, Std.int(FlxG.width / 4), Std.int(FlxG.height / 4));

		staticOverlay.animation.add('static', [0, 1, 2, 3], 24, true);
		staticOverlay.animation.play('static', true);

		staticOverlay.scrollFactor.set();
		staticOverlay.alpha = .05;

		staticOverlay.setGraphicSize(FlxG.width, FlxG.height);
		staticOverlay.updateHitbox();

		staticOverlay.screenCenter();

		titleGroup.add(bg);
		titleGroup.add(tiles);
		titleGroup.add(staticOverlay);

		funnyLogo = new FlxSprite();
		funnyLogo.frames = Paths.getSparrowAtlas('titleDance');

		funnyLogo.antialiasing = globalAntialiasing;

		funnyLogo.animation.addByPrefix('bump', 'dance', 24, false);
		funnyLogo.animation.play('bump');

		funnyLogo.setGraphicSize(Std.int(funnyLogo.width * LOGO_SCALE));

		funnyLogo.updateHitbox();
		funnyLogo.screenCenter();

		funnyLogo.x += titleJSON.titlex;
		funnyLogo.y += titleJSON.titley;

		acceptButton = new FlxSprite().loadGraphic(Paths.image('accept_button'));
		acceptButton.screenCenter();

		acceptButton.x += titleJSON.startx;
		acceptButton.y += titleJSON.starty;

		typed = new FlxText();

		typed.setFormat(Paths.font('comic.ttf'), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		typed.bold = true;

		titleGroup.add(typed);
		titleGroup.add(acceptButton);

		add(titleGroup);
		titleGroup.kill();

		credGroup = new FlxGroup();
		textGroup = new FlxGroup();

		add(funnyLogo);
		add(credGroup);
		#if !web
		exiting = new FlxSprite().loadGraphic(Paths.image('ui/exiting'));
		exiting.alpha = 0;

		add(exiting);
		#end
		var backgroundImage:FlxSprite = new FlxSprite().loadGraphic(Paths.image(titleJSON.backgroundSprite));

		backgroundImage.antialiasing = globalAntialiasing;
		backgroundImage.screenCenter();

		credGroup.add(backgroundImage);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();

		credTextShit.visible = false;
		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 3, {ease: FlxEase.quadInOut, type: PINGPONG});

		switch (initialized)
		{
			case true:
				skipIntro();
			default:
				{
					initialized = true;

					playTitleMusic(.1);
					beatHit();
				}
		}
		canYouFuckingWait = false;
	}

	override function update(elapsed:Float)
	{
		var lastSongPosition:Float = Conductor.songPosition;
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// sometimes it jsut dont go....
		FlxG.mouse.visible = false;
		super.update(elapsed);
		// loop beathit
		if (lastSongPosition > Conductor.songPosition)
			beatHit();
		if (canYouFuckingWait)
			return;

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		var pressedEnter:Bool = (FlxG.keys.justPressed.ENTER || PlayerSettings.controls.is(ACCEPT)) // (acceptButton incase you bind accept to b like a dumbass)
			|| (gamepad != null && gamepad.justPressed.START);

		if (tiles != null)
		{
			backdropTimer += (elapsed * .5) % 1;
			tiles.x = tiles.y = backdropTimer * 180 * BACKDROP_SCALE;
		}

		var sinkInput:Bool = false;
		if (!transitioning && skippedIntro)
		{
			if (exiting != null)
			{
				exitElapsed = (exitElapsed + (elapsed * 4)) % (Math.PI * 2);
				if (PlayerSettings.controls.is(BACK, PRESSED))
				{
					sinkInput = true;
					exitTimer += elapsed;

					if (exitTimer >= EXITING_AT)
					{
						FlxG.fullscreen = false;

						var window:Window = Lib.application.window;
						if (window != null)
							window.fullscreen = false;
						return Sys.exit(0);
					}
				}
				else if (exitTimer > 0)
				{
					exitTimer = Math.min(Math.max(exitTimer - (elapsed * 3), 0), .5);
				}

				exiting.alpha = FlxMath.bound(exitTimer * 2, 0, 1);
				exiting.angle = Math.sin(exitElapsed) * 3;

				exiting.setPosition(Math.sin(exitElapsed) * 5, Math.cos(exitElapsed) * 15);
			}
			if (!sinkInput && typeArray.length > 0 #if !debug && FreeplayState.freeplaySectionUnlocked(1) #end)
			{
				var pressed:Int = FlxG.keys.firstJustPressed();
				if (pressed >= 0 && FlxKey.toStringMap.exists(pressed))
				{
					var key:String = InputFormatter.getKeyName(pressed);
					var letter:String = typeArray[0].toUpperCase();

					var didType:Bool = false;
					if (key == letter)
					{
						didType = true;
						FlxG.sound.play(Paths.sound('scrollMenu'), .2);

						typed.color = FlxColor.GREEN;
						typed.text = letter;

						typeArray.shift();
						if (typeArray.length <= 0)
						{
							transitioning = true;
							// bended hard
							ClientPrefs.prefs.set('bendHard', true);
							ClientPrefs.saveSettings();

							switch (ClientPrefs.getPref('flashing'))
							{
								default:
									camGame.fade(FlxColor.GREEN, .5, false, null, true);
								case true:
									camGame.flash(FlxColor.GREEN, .5, null, true);
							}

							FlxG.sound.play(Paths.sound('confirmMenu'), .5);
							FlxTween.tween(acceptButton, {alpha: 0}, 1, {
								onComplete: function(twn:FlxTween)
								{
									// MusicBeatState.switchState(new MainMenuState());
									var song:String = 'bend-hard';

									CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
									PlayState.storyDifficulty = CoolUtil.defaultDifficultyInt;

									PlayState.isStoryMode = false;
									PlayState.SONG = Song.loadFromJson(CoolUtil.getDifficultyFilePath(PlayState.storyDifficulty), song);

									CustomFadeTransition.nextCamera = camTransition;
									MusicBeatState.coolerTransition = true;

									LoadingState.loadAndSwitchState(new PlayState(), true);

									closedState = true;
									twn.destroy();
								}
							});
						}
						sinkInput = true;
					}
					else if (typeArray.length < TYPE.length)
					{
						didType = true;

						typed.color = FlxColor.RED;
						typed.text = "X";

						refreshArray();
						FlxG.sound.play(Paths.sound('cancelMenu'), .2);
					}
					if (didType)
					{
						if (typeTween != null)
						{
							typeTween.cancel();
							typeTween.destroy();
						}

						typed.updateHitbox();
						typed.screenCenter(X);

						typed.y = FlxG.height - (typed.height + 16);
						typed.alpha = 1;

						typeTween = FlxTween.tween(typed, {alpha: 0}, .5, {
							ease: FlxEase.linear,
							onComplete: function(twn:FlxTween)
							{
								if (typeTween != null)
								{
									twn.destroy();
									typeTween = null;
								}
							}
						});
					}
				}
			}
			if (!sinkInput)
			{
				if (FlxG.keys.justPressed.D)
					CoolUtil.browserLoad('https://www.youtube.com/watch?v=hUTu2_0ElK8');
				#if debug
				if (FlxG.keys.justPressed.R)
				{
					closedState = true;

					transitioning = true;
					loopingDisableMechanics = true;

					LoadingState.loadAndSwitchState(new DisableMechanicsState(), false, true);
				}
				#end
			}
			if (pressedEnter && !sinkInput)
			{
				transitioning = true;
				acceptButton.scale.set(1.25, 1.25);

				var lastY:Float = acceptButton.y;
				acceptButton.y -= 15;

				FlxTween.tween(acceptButton, {y: lastY, "scale.x": 1, "scale.y": 1}, 1, {ease: FlxEase.backOut});
				FlxTween.tween(acceptButton, {alpha: 0}, 1, {ease: FlxEase.quintIn});

				switch (ClientPrefs.getPref('flashing'))
				{
					case true:
						camGame.flash(FlxColor.WHITE, 1, null, true);
					default:
						camGame.fade(FlxColor.BLACK, 1, false, null, true);
				}
				FlxG.sound.play(Paths.sound('confirmMenu'), .7);
				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					MusicBeatState.switchState(new MainMenuState());
					closedState = true;
				});
			}
		}

		if (initialized && pressedEnter && !skippedIntro)
			skipIntro();
		if (ClientPrefs.getPref('camZooms'))
		{
			var lerpSpeed:Float = FlxMath.bound(1 - (elapsed * Math.PI), 0, 1);
			camGame.zoom = FlxMath.lerp(camGame.initialZoom, camGame.zoom, lerpSpeed);
		}
	}

	override function beatHit()
	{
		super.beatHit();
		if (funnyLogo != null)
			funnyLogo.animation.play('bump', true);

		if (ClientPrefs.getPref('camZooms'))
			camGame.zoom += PlayState.HUD_BOP;
		if (!ClientPrefs.getPref('reducedMotion'))
		{
			if (camAngleTwn != null)
			{
				camAngleTwn.cancel();
				camAngleTwn.destroy();

				camAngleTwn = null;
			}

			var invert:Float = bopRight ? 1 : -1;

			camGame.angle = .5 * invert;
			camGame.y = 1 * invert;

			bopRight = !bopRight;
			camAngleTwn = FlxTween.tween(camGame, {y: 0, angle: 0}, Conductor.stepCrochet / 500, {ease: FlxEase.sineOut});
		}
		if (!(closedState || skippedIntro))
		{
			// sickBeats++;
			for (i in sickBeats...curBeat)
			{
				switch (i + 1)
				{
					case 0:
						{
							FlxG.sound.music.fadeIn(2, .1, .7);
							createCoolText(['the funnying team']);
						}
					case 2:
						addMoreText('presents');

					case 4:
						{
							deleteCoolText();
							createCoolText(['a mod for']);
						}
					case 6:
						addMoreText('the friday night funkin');

					case 8:
						deleteCoolText();

					case 10:
						createCoolText([curWacky[0][0]]);
					case 12:
						addMoreText(curWacky[0][1]);

					case 14:
						{
							deleteCoolText();
							createCoolText([curWacky[1][0]]);
						}
					case 16:
						addMoreText(curWacky[1][1]);

					case 18:
						{
							deleteCoolText();
							createCoolText([curWacky[2][0]]);
						}
					case 20:
						addMoreText(curWacky[2][1]);

					case 22:
						deleteCoolText();

					case 24:
						createCoolText(['its finally']);
					case 26:
						addMoreText('out');

					case 28:
						{
							deleteCoolText();
							createCoolText(['funnying']);
						}

					case 30:
						addMoreText('forever');
					case 32:
						skipIntro();
				}
			}
			sickBeats = curBeat;
		}
	}

	private inline function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var text:String = textArray[i];
			var textSize:Float = FlxMath.bound(tooMany / text.length, .5, 1);

			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.scaleX = textSize;

			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;

			if (credGroup != null && textGroup != null)
			{
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	private inline function addMoreText(text:String, ?offset:Float = 0)
	{
		if (textGroup != null && credGroup != null)
		{
			var textSize:Float = FlxMath.bound(tooMany / text.length, .5, 1);
			var coolText:Alphabet = new Alphabet(0, 0, text, true);

			coolText.scaleX = textSize;
			coolText.scaleY = textSize;

			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;

			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	private inline static function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (text in firstArray)
			swagGoodArray.push(text.split('--'));
		return swagGoodArray;
	}

	private inline function refreshArray():Void
		typeArray = TYPE.split('');

	// FIXED COMPARING VERS I THINK
	private static function rollWacky(?comparing:Array<Array<String>> = null):Array<String>
	{
		var introTexts:Array<Array<String>> = getIntroTextShit();
		var introText:Array<String>;

		var maxTries:Int = introTexts.length;
		var tries:Int = 0;

		do
		{
			introText = FlxG.random.getObject(introTexts);
			tries++;
		}
		while (comparing == null || (comparing.contains(introText) && tries < maxTries));
		return introText;
	}

	// I REMOVED COMPARING FROM THIS SINCE ITS UNNEEDED
	// private inline static function rollWacky():Array<String>
	//	return FlxG.random.getObject(getIntroTextShit());

	private inline function deleteCoolText()
	{
		while (textGroup.length > 0)
		{
			var member = textGroup.members[0];
			if (member != null)
			{
				member.kill();

				credGroup.remove(member, true);
				textGroup.remove(member, true);

				member.destroy();
				continue;
			}
			break;
		}
	}

	private inline function skipIntro():Void
	{
		if (!skippedIntro)
		{
			skippedIntro = true;

			deleteCoolText();
			remove(credGroup, true);

			titleGroup.revive();
			camGame.flash(FlxColor.WHITE, 4);
			#if GAMEJOLT_ALLOWED
			GameJolt.awardAchievement(this, camOther);
			#end
		}
	}
}
