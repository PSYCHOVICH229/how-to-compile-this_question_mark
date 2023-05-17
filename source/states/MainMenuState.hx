package states;

import openfl.display.Sprite;
import haxe.io.Path;
import meta.PlayerSettings;
import states.arcade.ArcadeState;
import openfl.utils.Assets;
import states.options.OptionsState;
import meta.data.ClientPrefs;
import meta.CoolUtil;
import states.freeplay.FreeplayState;
import meta.Conductor;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.Lib;

using StringTools;

import meta.Discord.DiscordClient;
#if debug
import states.editors.MasterEditorMenu;
#end

class MainMenuState extends MusicBeatState
{
	private inline static final CLICK_COOLDOWN:Float = .5;

	public inline static final quandaleEngineVersion:String = '1.0.0';
	public inline static final physicsEngineVersion:String = '0.6.3';

	private inline static final backgroundPath:String = 'backgrounds/';
	private inline static final iconPath:String = 'icons/';

	private inline static final menuPath:String = 'menucustom/';

	private inline static final iconPadding:Float = 130;
	private inline static final iconSize:Int = 200;

	private inline static final pickOffset:Float = 100;
	private inline static final offsetY:Float = 140;

	private static var libraryPath:String = Paths.getLibraryPath('images/$menuPath');
	private static var assetList:Array<String>;

	private static var backgroundList:Array<String>;
	private static var iconList:Array<String>;

	public static var curSelected:Int = 0;

	private var mouseTween:FlxTween;

	private var camGame:FlxCamera;
	private var camFriday:FlxCamera;
	private var camOther:FlxCamera;

	private var optionShit:Array<String> = ['story_mode', 'freeplay', 'arcade', 'options'];
	private var menuItems:FlxTypedGroup<FlxSprite>;

	private var magenta:FlxSprite;

	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject;

	private var debugKeys:Array<FlxKey>;

	private var fridayScale:Float = .5;
	private var fridayDelta:Float = 0;

	private var friday:FlxSprite;

	private var iconText:FlxText;
	private var icon:FlxSprite;

	private var selectedBackground:Null<String>;
	private var selectedIcon:String;

	private var selectedSomethin:Bool = false;
	private var lastBeatHit:Int = -1;

	private static var mouseEnabled:Bool = false;

	private var clickCooldown:Float = 0;

	override function create()
	{
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);

		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		camGame = new FlxCamera();

		camFriday = new FlxCamera();
		camOther = new FlxCamera();

		camFriday.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);

		FlxG.cameras.add(camFriday, false);
		FlxG.cameras.add(camOther, false);

		CustomFadeTransition.nextCamera = camOther;

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = mouseEnabled = true;
		if (assetList == null)
			assetList = Assets.list(IMAGE);
		if (backgroundList == null)
		{
			backgroundList = new Array();
			filter(backgroundList, libraryPath + backgroundPath);
		}
		if (iconList == null)
		{
			iconList = new Array();
			filter(iconList, libraryPath + iconPath);
		}

		var backgroundRoll:Int = FlxG.random.int(0, backgroundList.length) - 1; // oh i see why i did this

		selectedBackground = backgroundRoll >= 0 ? backgroundList[backgroundRoll] : null;
		selectedIcon = iconList[FlxG.random.int(0, iconList.length - 1)];

		var customCredits:String = '';
		if (selectedBackground != null && Assets.exists('$selectedBackground/author.txt', TEXT))
		{
			customCredits += 'background by '
				+ Assets.getText('$selectedBackground/author.txt')
				+ (Assets.exists('$selectedBackground/link.txt') ? ' (RIGHT CLICK TO OPEN LINK)' : '')
				+ '\n\n';
		}

		var bg:FlxSprite = new FlxSprite()
			.loadGraphic(selectedBackground != null ? Paths.returnGraphic('$selectedBackground/image.png') : Paths.image('menume1'));

		var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');
		var yScroll:Float = optionShit.length > 0 ? (1 / (optionShit.length * 2)) : 0;

		icon = new FlxSprite().loadGraphic(Paths.returnGraphic('$selectedIcon/image.png'));

		icon.scrollFactor.set(0, yScroll * .7);
		icon.setGraphicSize(iconSize, iconSize);

		icon.updateHitbox();

		icon.x = iconPadding / 2;
		icon.y = FlxG.height - icon.height - iconPadding;

		icon.antialiasing = globalAntialiasing;
		icon.cameras = [camGame];

		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.1));

		bg.updateHitbox();
		bg.setPosition(FlxG.width - bg.width, (FlxG.height - bg.height) / 2);

		bg.antialiasing = globalAntialiasing;
		bg.cameras = [camGame];

		magenta = new FlxSprite(bg.x,
			bg.y).loadGraphic(selectedBackground != null ? Paths.returnGraphic('$selectedBackground/image.png') : Paths.image('menume3'));
		if (selectedBackground != null)
			magenta.color = 0xFFFD71F4;

		magenta.scrollFactor.set(0, yScroll);

		magenta.setGraphicSize(Std.int(bg.width), Std.int(bg.height));
		magenta.updateHitbox();

		magenta.visible = false;
		magenta.antialiasing = globalAntialiasing;

		magenta.cameras = [camGame];

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);

		camFollow.cameras = [camGame];
		camFollowPos.cameras = [camGame];

		add(bg);
		add(magenta);

		add(icon);

		add(camFollow);
		add(camFollowPos);

		var curDate = Date.now();
		var hours:Int = curDate.getHours();

		if (#if debug friday == null #else (curDate.getDay() == 5 && hours >= 20) || (curDate.getDay() == 6 && hours <= 5) #end)
		{
			trace('It\'s Friday Night!! $hours');

			friday = new FlxSprite().loadGraphic(Paths.image('frid'));
			friday.scrollFactor.set();

			friday.setGraphicSize(Std.int(friday.width * fridayScale));
			friday.updateHitbox();

			friday.alpha = .9;

			friday.x = 50;
			friday.y = 50;

			friday.cameras = [camFriday];
			add(friday);
		}

		menuItems = new FlxTypedGroup();
		menuItems.cameras = [camGame];

		add(menuItems);
		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite(0, i * offsetY).loadGraphic(Paths.image('mainmenu/menu_' + optionShit[i]));
			menuItem.ID = i;

			menuItem.antialiasing = globalAntialiasing;
			menuItem.scrollFactor.set(0, 1);

			menuItem.updateHitbox();
			menuItem.x = FlxG.width + (menuItem.width * 2) + pickOffset;

			menuItem.cameras = [camGame];
			menuItems.add(menuItem);

			FlxTween.tween(menuItem, {x: FlxG.width - menuItem.width - 10}, .5, {startDelay: .5 + (i / 10), ease: FlxEase.backOut});
		}

		camGame.follow(camFollowPos, null, 1);
		var versionShit:FlxText = new FlxText(0, 0, FlxG.width,
			customCredits + 'dingulus engine v$quandaleEngineVersion (physics engine $physicsEngineVersion)\nfunnying v' + Lib.application.meta.get('version'),
			12);
		versionShit.scrollFactor.set();

		versionShit.setFormat(Paths.font("comic.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionShit.updateHitbox();

		versionShit.x = 8;
		versionShit.y = FlxG.height - (versionShit.height + versionShit.x);

		versionShit.cameras = [camGame];
		add(versionShit);

		var iconAuthor:String = '$selectedIcon/author.txt';
		if (Assets.exists(iconAuthor, TEXT))
		{
			var text:String = 'by ' + Assets.getText(iconAuthor);
			if (Assets.exists('$selectedIcon/link.txt', TEXT))
				text += '\n(CLICK TO OPEN SOCIALS)';

			iconText = new FlxText(0, 0, 0, text).setFormat(Paths.font('comic.ttf'), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);

			iconText.borderSize = 1;
			iconText.bold = true;

			iconText.visible = false;
			iconText.alpha = .875;

			iconText.cameras = [camGame];
			add(iconText);
		}

		changeItem();
		camFollowPos.y = camFollow.y;

		super.create();
	}

	override function update(elapsed:Float)
	{
		var lastSongPosition:Float = Conductor.songPosition;
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + (.5 * elapsed), .8);
			Conductor.songPosition = FlxG.sound.music.time;
		}
		super.update(elapsed);
		// loop beathit
		if (lastSongPosition > Conductor.songPosition)
		{
			lastBeatHit = curBeat - 1;
			beatHit();
		}
		if (friday != null)
		{
			fridayDelta += elapsed * 4;
			friday.scale.set(fridayScale + (Math.sin(fridayDelta) * (fridayScale / 2)), fridayScale + (Math.cos(fridayDelta) * (fridayScale / 2)));
		}

		var overlappingIcon:Bool = FlxG.mouse.overlaps(icon);
		var lerpVal:Float = FlxMath.bound(elapsed * 7.5, 0, 1);

		camFollowPos.setPosition(0, FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		if (!selectedSomethin)
		{
			var delta:Int = CoolUtil.delta(PlayerSettings.controls.is(UI_DOWN, JUST_PRESSED), PlayerSettings.controls.is(UI_UP, JUST_PRESSED));
			if (delta != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(delta);
			}

			if (PlayerSettings.controls.is(BACK))
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				CustomFadeTransition.nextCamera = camOther;
				MusicBeatState.switchState(new TitleState());
			}
			if (PlayerSettings.controls.is(ACCEPT))
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				var daChoice:String = optionShit[curSelected];
				switch (daChoice)
				{
					default:
						{
							var flashing:Bool = ClientPrefs.getPref('flashing');
							if (flashing)
								FlxFlicker.flicker(magenta, 1.1, .15, false, true);

							CustomFadeTransition.nextCamera = camOther;
							if (mouseTween != null)
							{
								mouseTween.cancel();
								mouseTween.destroy();
							}

							var mouseContainer:Sprite = FlxG.mouse.cursorContainer;
							if (mouseContainer != null)
							{
								mouseTween = FlxTween.tween(mouseContainer, {alpha: 0}, .5, {
									ease: FlxEase.quadIn,
									onComplete: function(twn:FlxTween)
									{
										mouseTween.cancel();
										mouseTween.destroy();

										mouseTween = null;
										mouseContainer.alpha = 0;
									}
								});
							}

							mouseEnabled = false;
							menuItems.forEach(function(spr:FlxSprite)
							{
								if (curSelected == spr.ID)
								{
									switch (flashing)
									{
										case true:
											FlxFlicker.flicker(spr, 1, .06, false, true, function(flick:FlxFlicker)
											{
												doShit(daChoice);
												// flick.destroy();
											});
										default:
											FlxTween.tween(spr, {alpha: 0}, 1, {
												onComplete: function(twn:FlxTween)
												{
													doShit(daChoice);
													twn.destroy();
												}
											});
									}
								}
								else
								{
									FlxTween.tween(spr, {alpha: 0}, .4, {
										ease: FlxEase.quadOut,
										onComplete: function(twn:FlxTween)
										{
											spr.kill();
											twn.destroy();
										}
									});
								}
							});
						}
				}
			}
			#if debug
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				mouseEnabled = false;

				CustomFadeTransition.nextCamera = camOther;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}
		if (ClientPrefs.getPref('camZooms'))
			camGame.zoom = FlxMath.lerp(camGame.initialZoom, camGame.zoom, FlxMath.bound(1 - (elapsed * Math.PI), 0, 1));

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.offset.x = FlxMath.lerp(spr.offset.x, (spr.ID == curSelected) ? (pickOffset + (spr.width / 2)) : 0, lerpVal);
		});
		icon.alpha = 1;

		FlxG.mouse.enabled = FlxG.mouse.visible = true;
		if (clickCooldown > 0)
			clickCooldown -= elapsed;
		if (mouseEnabled)
		{
			if (iconText != null)
			{
				iconText.setPosition(Math.max(FlxG.mouse.x - (iconText.width / 2), -(FlxG.width / 2) + 4), FlxG.mouse.y - iconText.height);
				iconText.visible = overlappingIcon;
			}
			if (overlappingIcon)
			{
				var link:String = '$selectedIcon/link.txt';
				if (Assets.exists(link, TEXT))
				{
					icon.alpha = .7;
					if (FlxG.mouse.justPressed && clickCooldown <= 0)
					{
						trace('open icon link');

						clickCooldown = CLICK_COOLDOWN;
						CoolUtil.browserLoad(Assets.getText(link));
					}
				}
			}
			else if (FlxG.mouse.justPressedRight
				&& clickCooldown <= 0
				&& selectedBackground != null
				&& Assets.exists('$selectedBackground/link.txt', TEXT))
			{
				trace('open bg link');

				clickCooldown = CLICK_COOLDOWN;
				CoolUtil.browserLoad(Assets.getText('$selectedBackground/link.txt'));
			}
		}
		else if (iconText != null)
		{
			iconText.visible = false;
		}
	}

	override function beatHit()
	{
		super.beatHit();
		if (ClientPrefs.getPref('camZooms') && lastBeatHit < curBeat)
			camGame.zoom += PlayState.GAME_BOP;
		lastBeatHit = curBeat;
	}

	override function destroy()
	{
		trace('set mouse alpha back up ples');
		if (mouseTween != null)
		{
			mouseTween.cancel();
			mouseTween.destroy();

			mouseTween = null;
		}

		var mouseContainer:Sprite = FlxG.mouse.cursorContainer;
		if (mouseContainer != null)
			mouseContainer.alpha = 1;

		FlxG.mouse.visible = false;
		super.destroy();
	}

	private inline function filter(array:Array<Dynamic>, start:String)
	{
		for (asset in assetList)
		{
			if (asset.startsWith(start))
				array.push(Path.directory(asset));
		}
	}

	private inline static function doShit(daChoice:String)
	{
		var newState:Dynamic = switch (daChoice)
		{
			case 'options': OptionsState;

			case 'story_mode': StoryMenuState;
			case 'arcade':
				{
					if (FlxG.sound.music != null)
						FlxG.sound.music?.fadeOut(.5);
					ArcadeState;
				}

			case 'freeplay': FreeplayState;
			default: null;
		}
		if (newState != null)
			MusicBeatState.switchState(Type.createInstance(newState, []));
	}

	private inline function changeItem(change:Int = 0)
	{
		curSelected = CoolUtil.repeat(curSelected, change, menuItems.length);
		menuItems.forEach(function(spr:FlxSprite)
		{
			if (spr.ID == curSelected)
				camFollow.setPosition(0, spr.getGraphicMidpoint().y);
		});
	}
}
