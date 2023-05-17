package states.arcade;

import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import meta.PlayerSettings;
import meta.CoolUtil;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import openfl.Assets;
import flixel.text.FlxText;
import states.arcade.*;
import openfl.display.BitmapData;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import flixel.sound.FlxSound;
import flixel.FlxCamera;
import meta.Discord.DiscordClient;
import meta.data.ClientPrefs;
import flixel.FlxG;
import flixel.FlxSprite;

class ArcadeState extends MusicBeatState
{
	public inline static final screenHeight:Int = 345;
	public inline static final screenWidth:Int = 500;

	private inline static final ratio:Float = screenWidth / screenHeight;
	private inline static final itemSize:Int = 150;

	private inline static final itemPadding:Float = itemSize + 20;
	private inline static final itemBorder:Int = itemSize + 4;

	private inline static final itemY:Float = (screenHeight - itemSize) / 2;

	private inline static final menuInterpolation:Float = 1 / 360 / 60;
	private inline static final substateCooldown:Float = 1 / 5;

	private static var menuSelected:Int = 0;

	private static var currentMenu:Dynamic;
	private static final menus:Array<Dynamic> = [
		AchievementsSubstate,
		CreditsSubstate
		#if GAMEJOLT_ALLOWED, GameJoltSubstate #end
	];

	private static final menuNames:Array<String> = ['achievements', 'credits' #if GAMEJOLT_ALLOWED, 'gamejolt' #end];
	public static var instance:ArcadeState;

	public var camArcade:FlxCamera;
	public var camScreen:FlxCamera;
	public var camOther:FlxCamera;
	public var camBack:FlxCamera;

	private var onSubstate:Bool = false;
	private var shitting:Bool = false;

	private var screenEffects:FlxSprite;
	private var ambience:FlxSound;

	private var machineGroup:FlxSpriteGroup;

	private var buttonBlue:FlxSprite;
	private var buttonRed:FlxSprite;

	public static var stickHorizontalPress:Int = 0;
	public static var stickVerticalPress:Int = 0;

	public static var stickHorizontal:Int = 0;
	public static var stickVertical:Int = 0;

	public var focused:Bool = true;

	private var stick:FlxSprite;
	private var stickAnim:String;

	private var stickOffsets:Map<String, FlxPoint>;

	private var stickAnimsHorizontal:Map<Int, String> = [-1 => 'left', 1 => 'right'];
	private var stickAnimsVertical:Map<Int, String> = [-1 => 'down', 1 => 'up'];

	private var currentMenuText:FlxText;

	private var menuGroup:FlxSpriteGroup;
	private var menuEncased:FlxGroup;

	private var scrollGoal:FlxPoint;

	private static var previousScroll:FlxPoint;
	private static var currentSubstateTimer:Float = 0;

	private var didThing:Bool = false;
	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		camArcade = new FlxCamera();
		camOther = new FlxCamera();
		camBack = new FlxCamera();

		camScreen = new FlxCamera(0, 0, screenWidth, screenHeight, 1);

		camScreen.bgColor = FlxColor.BLACK;
		camOther.bgColor.alpha = camArcade.bgColor.alpha = camBack.bgColor.alpha = 0;

		// camScreen.active = false;
		resetCameraPosition();
		FlxG.cameras.reset();

		FlxG.cameras.add(camBack, false);
		FlxG.cameras.add(camScreen, false);

		FlxG.cameras.add(camArcade, true);
		FlxG.cameras.add(camOther, false);

		CustomFadeTransition.nextCamera = camOther;

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Arcade", null);

		menuEncased = new FlxGroup();
		menuEncased.cameras = [camScreen];

		menuGroup = new FlxSpriteGroup((screenWidth - itemSize) / 2);
		menuGroup.scrollFactor.set(1, 1);

		menuGroup.antialiasing = false;

		currentMenuText = new FlxText(0, screenHeight * .85, screenWidth).setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER);
		currentMenuText.scrollFactor.set();

		updateMenuText();
		scrollGoal = new FlxPoint();

		for (index in 0...menus.length)
		{
			var name:String = Paths.formatToSongPath(menuNames[index]);
			var menu:Dynamic = menus[index];

			if (Reflect.hasField(menu, 'preload'))
			{
				trace('PRELOADING $menu/$name');
				menu.preload();
			}

			var item:FlxSpriteGroup = new FlxSpriteGroup(itemPadding * index, itemY);

			var border:FlxSprite = new FlxSprite().makeGraphic(itemBorder, itemBorder, FlxColor.WHITE);
			var inside:FlxSprite = new FlxSprite();

			var assetPath:String = Paths.getPreloadPath('images/arcade/icons/$name.png');
			var exists:Bool = Assets.exists(assetPath, IMAGE);

			inside.makeGraphic(itemSize, itemSize, FlxColor.BLACK, exists);
			if (exists)
			{
				var icon:BitmapData = Assets.getBitmapData(assetPath);
				var pixels:BitmapData = inside.pixels;

				pixels.copyPixels(icon, pixels.rect, icon.rect.topLeft, null, null, true);
			}

			border.y = (inside.height - border.height) / 2;
			border.x = (inside.width - border.width) / 2;

			item.add(border);
			item.add(inside);

			menuGroup.add(item);
		}

		menuEncased.add(menuGroup);
		menuEncased.add(currentMenuText);

		add(menuEncased);

		FlxG.sound.music?.stop();
		FlxG.sound.playMusic(Paths.music('arcade/arcade_madnes_huge_bulge_madnes'), 0);

		ambience = new FlxSound().loadEmbedded(Paths.sound('arcade/arcadeAmbience'));
		FlxG.sound.list.add(ambience);

		ambience.looped = true;
		ambience.play();

		final globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');
		final screenImage:FlxGraphic = Paths.image('arcade/static');

		screenEffects = new FlxSprite().loadGraphic(screenImage, true, screenWidth, screenHeight);

		screenEffects.animation.add('static', [0, 1, 2, 3, 4, 5, 6, 7], 24, true);
		screenEffects.animation.play('static', true);

		screenEffects.cameras = [camScreen];
		screenEffects.scrollFactor.set();

		screenEffects.antialiasing = globalAntialiasing;
		screenEffects.visible = false;

		add(screenEffects);
		var background:FlxSprite = new FlxSprite().loadGraphic(Paths.image('arcade/background'));

		background.cameras = [camBack];
		background.screenCenter();

		background.scrollFactor.set();
		background.antialiasing = globalAntialiasing;

		machineGroup = new FlxSpriteGroup();

		machineGroup.cameras = [camArcade];
		machineGroup.scrollFactor.set();

		var machine:FlxSprite = new FlxSprite().loadGraphic(Paths.image('arcade/arcademachine'));
		machine.antialiasing = globalAntialiasing;
		// OTHER ARCADE SHIT
		stickOffsets = new Map();
		stick = new FlxSprite(115, 550);

		stick.antialiasing = globalAntialiasing;

		stick.frames = Paths.getSparrowAtlas('arcade/stick');
		stick.animation.addByPrefix('idle', 'stick0', 24, false);
		// HORIZONTAL
		stick.animation.addByPrefix('right', 'stickRIGHT', 24, false);
		stickOffsets.set('right', new FlxPoint(-3));

		stick.animation.addByPrefix('left', 'stickLEFT', 24, false);
		stickOffsets.set('left', new FlxPoint(35));
		// VERTICAL
		stick.animation.addByPrefix('up', 'stickUP', 24, false);
		stickOffsets.set('up', new FlxPoint(-3, -38));

		stick.animation.addByPrefix('down', 'stickDOWN', 24, false);
		stickOffsets.set('down', new FlxPoint(23, -40));
		// OTHER SHIT
		stick.animation.play('idle', true);
		buttonRed = new FlxSprite(575, 660);

		buttonRed.antialiasing = globalAntialiasing;
		buttonRed.frames = Paths.getSparrowAtlas('arcade/buttonRed');

		buttonRed.animation.addByPrefix('idle', 'buttonred0', 24, false);
		buttonRed.animation.addByPrefix('press', 'buttonredPRESS', 24, false);

		buttonRed.animation.finishCallback = function(name:String)
		{
			if (name != 'idle')
				buttonRed.animation.play('idle', true);
		}

		buttonBlue = new FlxSprite(495, 695);

		buttonBlue.antialiasing = globalAntialiasing;
		buttonBlue.frames = Paths.getSparrowAtlas('arcade/buttonBlue');

		buttonBlue.animation.addByPrefix('idle', 'buttonblue0', 24, false);
		buttonBlue.animation.addByPrefix('press', 'buttonbluePRESS', 24, false);

		buttonBlue.animation.finishCallback = function(name:String)
		{
			if (name != 'idle')
				buttonBlue.animation.play('idle', true);
		}

		// machineGroup.add(screenEffects);
		machineGroup.add(machine);
		machineGroup.add(stick);

		machineGroup.add(buttonRed);
		machineGroup.add(buttonBlue);

		machineGroup.screenCenter();
		machineGroup.y -= 5;

		camScreen.x = machine.x + ((machine.width - screenWidth) / 2);
		camScreen.y = machine.y + 42 + ((machine.height - screenHeight) / 2);

		add(background);
		add(machineGroup);

		if (#if debug true #else !ClientPrefs.getPref('visitedArcade') #end)
		{
			shitting = true;

			var cutsceneSound:FlxSound = new FlxSound().loadEmbedded(Paths.sound('arcade/arcadeCutscene'));
			var cutscene:FlxSprite = new FlxSprite(610, 185);

			var blackScreen:FlxSprite = new FlxSprite().makeGraphic(camScreen.width, camScreen.height, FlxColor.BLACK);

			blackScreen.cameras = [camScreen];
			blackScreen.scrollFactor.set();

			add(blackScreen);
			FlxG.sound.list.add(cutsceneSound);

			cutscene.frames = Paths.getSparrowAtlas('arcade/cutscene');
			cutscene.cameras = [camArcade];

			cutscene.scrollFactor.set();
			cutscene.antialiasing = globalAntialiasing;

			cutscene.animation.addByPrefix('cutscene', 'coin', 24, false);
			cutscene.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int)
			{
				if (frameNumber >= 30 && !didThing)
				{
					didThing = true;

					blackScreen.visible = false;
					screenEffects.visible = true;

					camArcade.shake(1 / 80, 1 / 10);
					blackScreen.kill();

					remove(blackScreen, true);

					blackScreen.destroy();
					blackScreen = null;

					trace('do static shit or something idk');
				}
			};
			cutscene.animation.finishCallback = function(name:String)
			{
				ClientPrefs.prefs.set('visitedArcade', true);
				new FlxTimer().start(.5, function(tmr:FlxTimer)
				{
					startFadingMusicIn();
					shitting = false;

					FlxTween.tween(screenEffects, {alpha: 0}, 1, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							screenEffects.kill();
							remove(screenEffects, true);

							screenEffects.destroy();
							screenEffects = null;
						}
					});
				});

				cutscene.kill();
				remove(cutscene, true);

				cutscene.destroy();
				cutscene = null;
			}

			add(cutscene);
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				cutsceneSound.play();

				cutscene.animation.play('cutscene', true);
				cutsceneSound.play(true); // JUST INCASE i love dick
			});
		}
		else
		{
			startFadingMusicIn();
		}

		instance = this;
		super.create();
	}

	private inline function updateStickOffset(stickAnimation:String)
	{
		if (stickOffsets.exists(stickAnimation))
		{
			var offset:FlxPoint = stickOffsets.get(stickAnimation);
			stick.offset.set(offset.x, offset.y);
		}
		else
		{
			stick.offset.set();
		}
	}
	private inline function startFadingMusicIn()
	{
		FlxG.sound.music?.fadeIn(2, 1 / 10, 1 / 2);
		FlxG.sound.music?.play(true);
	}

	private inline function updateMenuText()
		currentMenuText.text = menuNames[menuSelected]?.toUpperCase();
	private inline function resetCameraPosition()
	{
		if (previousScroll != null)
		{
			camScreen.scroll.set(previousScroll.x, previousScroll.y);
		}
		else
		{
			camScreen.scroll.set();
		}
	}
	private inline function closeMenu(force:Bool = false)
	{
		var closed:Bool = false;
		if (currentMenu != null)
		{
			currentMenu.close();
			currentMenu = null;

			closed = true;
		}
		if (closed || force)
			closeSubState();
	}

	override function update(elapsed:Float)
	{
		FlxG.mouse.visible = false;
		FlxG.mouse.enabled = false;
		// MAIN
		if (!shitting)
		{
			// VISUALS
			stickHorizontal = PlayerSettings.controls.diff(UI_RIGHT, UI_LEFT, PRESSED, PRESSED);
			stickVertical = PlayerSettings.controls.diff(UI_UP, UI_DOWN, PRESSED, PRESSED);

			var stickAnimation:String = stickAnimsVertical.exists(stickVertical) ? stickAnimsVertical.get(stickVertical) : stickAnimsHorizontal.exists(stickHorizontal) ? stickAnimsHorizontal.get(stickHorizontal) : 'idle';
			if (stickAnim != stickAnimation)
			{
				var lastStickAnim:String = stickAnim;

				stickAnim = stickAnimation;
				stick.animation.callback = null;

				switch (stickAnimation)
				{
					case 'idle':
						{
							stick.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int)
							{
								if (name == lastStickAnim)
								{
									if (frameNumber >= 5)
									{
										stick.animation.callback = null;
										stick.animation.play(stickAnimation, true);

										updateStickOffset(stickAnimation);
									}
								}
								else
								{
									stick.animation.callback = null;
								}
							};
							stick.animation.resume();
						}
					default:
						{
							stick.animation.play(stickAnimation, true);
							stick.animation.pause();

							updateStickOffset(stickAnimation);
						}
				}
			}
			// TIMERS
			if (currentSubstateTimer > 0)
				currentSubstateTimer -= elapsed;
			// CONTROLS
			stickHorizontalPress = PlayerSettings.controls.diff(UI_RIGHT, UI_LEFT, JUST_PRESSED, JUST_PRESSED);
			stickVerticalPress = PlayerSettings.controls.diff(UI_DOWN, UI_UP, JUST_PRESSED, JUST_PRESSED);
			// might change this later idfk
			if (stickVerticalPress != 0 || stickHorizontalPress != 0)
				FlxG.sound.play(Paths.sound('scrollMenu'), .3).setPosition(stick.x, stick.y);
			if (!onSubstate)
			{
				if (stickHorizontalPress != 0)
				{
					menuSelected = CoolUtil.repeat(menuSelected, stickHorizontalPress, menus.length);
					updateMenuText();
				}
				scrollGoal.x = itemPadding * menuSelected;

				camScreen.scroll.x = FlxMath.lerp(camScreen.scroll.x, scrollGoal.x, 1 - Math.pow(menuInterpolation, elapsed));
				camScreen.scroll.y = FlxMath.lerp(camScreen.scroll.y, scrollGoal.y, 1 - Math.pow(menuInterpolation, elapsed));
			}

			if (PlayerSettings.controls.is(ACCEPT))
			{
				buttonRed.animation.play('press', true);
				FlxG.sound.play(Paths.sound('cancelMenu'), .3).setPosition(buttonRed.x, buttonRed.y);

				switch (onSubstate)
				{
					case true:
						currentMenu?.onAcceptRequest();
					default:
						{
							trace('SWITCHING ARCADE SUBSTATE');

							var menu:Dynamic = menus[menuSelected];
							if (menu != null)
							{
								previousScroll = scrollGoal;
								camScreen.scroll.set();

								currentSubstateTimer = substateCooldown;
								onSubstate = true;

								closeMenu();

								currentMenu = Type.createInstance(menu, [camScreen]);
								openSubState(currentMenu);
							}
						}
				}
			}
			if (PlayerSettings.controls.is(BACK))
			{
				buttonBlue.animation.play('press', true);
				FlxG.sound.play(Paths.sound('cancelMenu'), .6).setPosition(buttonBlue.x, buttonBlue.y);

				if (onSubstate)
				{
					if (currentSubstateTimer <= 0 && currentMenu.onCloseRequest())
					{
						onSubstate = false;

						closeMenu(true);
						resetCameraPosition();
					}
				}
				else
				{
					previousScroll = scrollGoal;
					var blackScreen:FlxSprite = new FlxSprite(camScreen.x, camScreen.y).makeGraphic(camScreen.width, camScreen.height, FlxColor.BLACK);

					blackScreen.cameras = [camBack];
					blackScreen.scrollFactor.set();

					add(blackScreen);

					camScreen.destroy();
					camScreen = null;

					shitting = true;
					persistentUpdate = false;

					var fadeDuration:Float = 1;

					ambience?.fadeOut(fadeDuration);
					camOther.fade(FlxColor.BLACK, fadeDuration, false, null, true);

					FlxG.sound.music?.fadeOut(fadeDuration, 0, function(twn:FlxTween)
					{
						FlxG.sound.music?.stop();

						TitleState.playTitleMusic(0);
						MusicBeatState.switchState(new MainMenuState());
					});
				}
			}
			menuEncased.visible = !onSubstate;
		}
		super.update(elapsed);
	}
}
