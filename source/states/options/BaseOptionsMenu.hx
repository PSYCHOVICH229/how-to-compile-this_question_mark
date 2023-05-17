package states.options;

import meta.PlayerSettings;
import meta.CoolUtil;
import meta.data.ClientPrefs;
import meta.instances.AttachedText;
import meta.instances.PrefCheckbox;
import meta.instances.Character;
import states.substates.MusicBeatSubstate;
import meta.Discord.DiscordClient;
import meta.instances.Alphabet;
import meta.Controls;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;

using StringTools;

class BaseOptionsMenu extends MusicBeatSubstate
{
	public static var instance:BaseOptionsMenu;

	private var curSelected:Int = 0;
	private var optionsArray:Array<Option>;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxGroup:FlxTypedGroup<PrefCheckbox>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	private var boyfriend:Character = null;
	private var curOption:Option = null;

	private var descBox:FlxSprite;
	private var descText:FlxText;

	private var nextAccept:Int = 5;

	private var holdTime:Float = 0;
	private var holdValue:Float = 0;

	public var title:String;
	public var rpcTitle:String;

	public function new()
	{
		super();
		instance = this;

		if (title == null)
			title = 'Options';
		if (rpcTitle == null)
			rpcTitle = 'Options Menu';

		DiscordClient.changePresence(rpcTitle, null);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menume'));
		bg.color = 0xFFea71fd;

		bg.screenCenter();
		bg.antialiasing = ClientPrefs.getPref('globalAntialiasing');

		add(bg);
		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup();
		add(grpOptions);

		grpTexts = new FlxTypedGroup();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup();
		add(checkboxGroup);

		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = .6;

		add(descBox);
		var titleText:Alphabet = new Alphabet(75, 40, title, true);

		titleText.scaleX = .6;
		titleText.scaleY = .6;

		titleText.alpha = .4;
		add(titleText);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		descText.scrollFactor.set();
		descText.borderSize = 2.4;

		add(descText);
		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(290, 260, optionsArray[i].name, false);

			optionText.isMenuItem = true;
			optionText.targetY = i;

			grpOptions.add(optionText);
			if (optionsArray[i].type == 'bool')
			{
				var checkbox:PrefCheckbox = new PrefCheckbox(optionText.x - 105, optionText.y, optionsArray[i].getValue() == true);

				checkbox.sprTracker = optionText;
				checkbox.ID = i;

				checkboxGroup.add(checkbox);
			}
			else
			{
				optionText.x -= 80;
				optionText.startPosition.x -= 80;

				var valueText:AttachedText = new AttachedText('' + optionsArray[i].getValue(), optionText.width + 80);

				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;

				valueText.ID = i;

				grpTexts.add(valueText);
				optionsArray[i].setChild(valueText);
			}
			if (optionsArray[i].showBoyfriend && boyfriend == null)
				reloadBoyfriend();

			updateTextFrom(optionsArray[i]);
		}

		changeSelection();
		reloadCheckboxes();
	}

	public inline function addOption(option:Option)
	{
		if (optionsArray == null || optionsArray.length < 1)
			optionsArray = [];
		optionsArray.push(option);
	}

	override function update(elapsed:Float)
	{
		var delta:Int = PlayerSettings.controls.diff(UI_DOWN, UI_UP, JUST_PRESSED, JUST_PRESSED);
		if (delta != 0)
			changeSelection(delta);

		if (PlayerSettings.controls.is(BACK))
		{
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if (nextAccept <= 0)
		{
			if (curOption.type == 'bool')
			{
				if (PlayerSettings.controls.is(ACCEPT))
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));

					curOption.setValue(!curOption.getValue());
					curOption.change();

					reloadCheckboxes();
				}
			}
			else if (PlayerSettings.controls.is(UI_LEFT, PRESSED) || PlayerSettings.controls.is(UI_RIGHT, PRESSED))
			{
				var pressed = (PlayerSettings.controls.is(UI_LEFT, JUST_PRESSED) || PlayerSettings.controls.is(UI_RIGHT, JUST_PRESSED));
				if (holdTime > .5 || pressed)
				{
					if (pressed)
					{
						switch (curOption.type)
						{
							case 'int' | 'float' | 'percent':
								{
									holdValue = FlxMath.bound(curOption.getValue()
										+ (curOption.changeValue * PlayerSettings.controls.diff(UI_RIGHT, UI_LEFT, PRESSED, PRESSED)),
										curOption.minValue, curOption.maxValue);
									curOption.setValue(switch (curOption.type)
									{
										case 'float' | 'percent':
											FlxMath.roundDecimal(holdValue, curOption.decimals);
										default:
											Math.round(holdValue);
									});
								}
							case 'string':
								{
									var num:Int = CoolUtil.repeat(curOption.curOption,
										PlayerSettings.controls.diff(UI_RIGHT, UI_LEFT, JUST_PRESSED, JUST_PRESSED), curOption.options.length);

									curOption.curOption = num;
									curOption.setValue(Paths.formatToSongPath(curOption.options[num]));
								}
						}

						updateTextFrom(curOption);
						curOption.change();

						FlxG.sound.play(Paths.sound('scrollMenu'));
					}
					else if (curOption.type != 'string')
					{
						holdValue = FlxMath.bound(holdValue
							+ (curOption.scrollSpeed * elapsed * (PlayerSettings.controls.diff(UI_RIGHT, UI_LEFT, PRESSED, PRESSED))),
							curOption.minValue, curOption.maxValue);
						curOption.setValue(switch (curOption.type)
						{
							case 'float' | 'percent':
								FlxMath.roundDecimal(Math.round(holdValue / curOption.changeValue) * curOption.changeValue, curOption.decimals);
							default:
								Math.round(holdValue);
						});

						updateTextFrom(curOption);
						curOption.change();
					}
				}
				if (curOption.type != 'string')
					holdTime += elapsed;
			}
			else if (PlayerSettings.controls.is(UI_LEFT, JUST_RELEASED) || PlayerSettings.controls.is(UI_RIGHT, JUST_RELEASED))
			{
				clearHold();
			}
			if (PlayerSettings.controls.is(RESET))
			{
				for (i in 0...optionsArray.length)
				{
					var leOption:Option = optionsArray[i];
					leOption.setValue(leOption.defaultValue);
					if (leOption.type != 'bool')
					{
						switch (leOption.type)
						{
							case 'string':
								{
									leOption.setValue(Paths.formatToSongPath(leOption.defaultValue));

									var value:String = leOption.getValue();
									var num:Int = -1;

									for (i in 0...leOption.options.length)
									{
										if (Paths.formatToSongPath(leOption.options[i]) == value)
										{
											num = i;
											break;
										}
									}
									if (num > -1)
										leOption.curOption = num;
								}
						}
						updateTextFrom(leOption);
					}
					leOption.change();
				}

				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}

		if (boyfriend?.animation?.curAnim?.finished ?? false)
			boyfriend.dance();
		if (nextAccept > 0)
			nextAccept -= 1;

		super.update(elapsed);
	}

	private inline function updateTextFrom(option:Option)
	{
		var text:String = option.displayFormat;
		var val:Dynamic = switch (option.type)
		{
			case 'string': option.options[option.curOption];
			case 'percent': option.getValue() * 100;

			default: option.getValue();
		}

		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	private inline function clearHold()
	{
		if (holdTime > .5)
			FlxG.sound.play(Paths.sound('scrollMenu'));
		holdTime = 0;
	}

	private inline function changeSelection(change:Int = 0)
	{
		curSelected = CoolUtil.repeat(curSelected, change, optionsArray.length);

		descText.text = optionsArray[curSelected].description;
		descText.screenCenter(Y);

		descText.y += 270;

		var bullShit:Int = 0;
		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = .6;
			if (item.targetY == 0)
				item.alpha = 1;
		}
		for (text in grpTexts)
		{
			text.alpha = .6;
			if (text.ID == curSelected)
				text.alpha = 1;
		}

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));

		descBox.updateHitbox();
		if (boyfriend != null)
			boyfriend.visible = optionsArray[curSelected].showBoyfriend;

		curOption = optionsArray[curSelected]; // shorter lol
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	public inline function reloadBoyfriend()
	{
		var wasVisible:Bool = false;
		if (boyfriend != null)
		{
			wasVisible = boyfriend.visible;
			boyfriend.kill();

			remove(boyfriend, true);

			boyfriend.destroy();
			boyfriend = null;
		}

		boyfriend = new Character(840, 170, 'bf', true, true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * .75));

		boyfriend.updateHitbox();
		boyfriend.dance();

		insert(1, boyfriend);
		boyfriend.visible = wasVisible;
	}

	public inline function reloadCheckboxes()
	{
		for (checkbox in checkboxGroup)
			checkbox.daValue = (optionsArray[checkbox.ID].getValue() == true);
	}
}
