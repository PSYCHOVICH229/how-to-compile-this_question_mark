package states.options;

import meta.PlayerSettings;
import meta.InputFormatter;
import meta.instances.AttachedText;
import meta.CoolUtil;
import meta.instances.Alphabet;
import meta.data.ClientPrefs;
import states.substates.MusicBeatSubstate;
import meta.Discord.DiscordClient;
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

class ControlsSubState extends MusicBeatSubstate
{
	private static var curSelected:Int = 1;
	private static var curAlt:Bool = false;

	private inline static final defaultKey:String = 'RESET TO DEFAULT KEYS';

	private var bindLength:Int = 0;

	var optionShit:Array<Dynamic> = [
		['NOTES'], ['Left', 'note_left'], ['Down', 'note_down'], ['Up', 'note_up'], ['Right', 'note_right'], [''], ['UI'], ['Left', 'ui_left'],
		['Down', 'ui_down'], ['Up', 'ui_up'], ['Right', 'ui_right'], [''], ['Reset', 'reset'], ['Accept', 'accept'], ['Back', 'back'], ['Pause', 'pause'],
		[''], ['MECHANICS'], ['Hit', 'hit'], [''], ['VOLUME'], ['Mute', 'volume_mute'], ['Up', 'volume_up'], ['Down', 'volume_down'], [''], ['DEBUG'],
		['Key 1', 'debug_1'], ['Key 2', 'debug_2'] #if debug, ['Key 3', 'debug_3'], ['Key 4', 'debug_4'] #end];

	private var grpOptions:FlxTypedGroup<Alphabet>;

	private var grpInputsAlt:Array<AttachedText> = [];
	private var grpInputs:Array<AttachedText> = [];

	var rebindingKey:Bool = false;
	var nextAccept:Int = 5;

	public function new()
	{
		super();
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menume'));

		bg.color = 0xFFea71fd;
		bg.screenCenter();

		bg.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		add(bg);

		grpOptions = new FlxTypedGroup();
		add(grpOptions);

		optionShit.push(['']);
		optionShit.push([defaultKey]);

		for (i in 0...optionShit.length)
		{
			var isDefaultKey:Bool = (optionShit[i][0] == defaultKey);
			var isCentered:Bool = unselectableCheck(i, true);

			var optionText:Alphabet = new Alphabet(200, 300, optionShit[i][0], (!isCentered || isDefaultKey));
			optionText.isMenuItem = true;

			if (isCentered)
			{
				optionText.screenCenter(X);

				optionText.y -= 55;
				optionText.startPosition.y -= 55;
			}

			optionText.changeX = false;
			optionText.distancePerItem.y = 60;

			optionText.targetY = i - curSelected;
			optionText.snapToPosition();

			grpOptions.add(optionText);
			if (!isCentered)
			{
				addBindTexts(optionText, i);
				bindLength++;

				if (curSelected < 0)
					curSelected = i;
			}
		}
		changeSelection();
	}

	var bindingTime:Float = 0;

	override function update(elapsed:Float)
	{
		if (rebindingKey)
		{
			var keyPressed:Int = FlxG.keys.firstJustPressed();
			if (keyPressed > -1)
			{
				var keySelected:String = optionShit[curSelected][1];
				var keysArray:Array<FlxKey> = ClientPrefs.getKeyArray(ClientPrefs.keyBinds.get(keySelected));

				var altInt:Int = CoolUtil.int(curAlt);
				var opposite:Int = 1 - altInt;

				keysArray[altInt] = keyPressed;
				if (keysArray[opposite] == keysArray[altInt])
					keysArray[opposite] = NONE;

				ClientPrefs.setKey(keySelected, keysArray);
				reloadKeys();

				ClientPrefs.saveSettings();
				FlxG.sound.play(Paths.sound('confirmMenu'));

				rebindingKey = false;
			}

			bindingTime += elapsed;
			if (bindingTime > 5)
			{
				if (curAlt)
				{
					grpInputsAlt[curSelected].alpha = 1;
				}
				else
				{
					grpInputs[curSelected].alpha = 1;
				}

				FlxG.sound.play(Paths.sound('scrollMenu'));

				rebindingKey = false;
				bindingTime = 0;
			}
		}
		else
		{
			var delta:Int = PlayerSettings.controls.diff(UI_DOWN, UI_UP, JUST_PRESSED, JUST_PRESSED);
			if (delta != 0)
				changeSelection(delta);
			if (PlayerSettings.controls.is(UI_LEFT, JUST_PRESSED) || PlayerSettings.controls.is(UI_RIGHT, JUST_PRESSED))
				changeAlt();

			if (PlayerSettings.controls.is(BACK))
			{
				ClientPrefs.reloadControls();
				close();

				FlxG.sound.play(Paths.sound('cancelMenu'));
			}

			if (PlayerSettings.controls.is(ACCEPT) && nextAccept <= 0)
			{
				if (optionShit[curSelected][0] == defaultKey)
				{
					ClientPrefs.keyBinds = ClientPrefs.defaultKeys.copy();

					reloadKeys();
					changeSelection();

					FlxG.sound.play(Paths.sound('confirmMenu'));
				}
				else if (!unselectableCheck(curSelected))
				{
					bindingTime = 0;
					rebindingKey = true;

					if (curAlt)
					{
						grpInputsAlt[getInputTextNum()].alpha = 0;
					}
					else
					{
						grpInputs[getInputTextNum()].alpha = 0;
					}

					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
			}
		}

		if (nextAccept > 0)
			nextAccept -= 1;
		super.update(elapsed);
	}

	private inline function getInputTextNum()
	{
		var num:Int = 0;
		for (i in 0...curSelected)
		{
			if (optionShit[i].length > 1)
			{
				num++;
			}
		}
		return num;
	}

	private inline function changeSelection(change:Int = 0)
	{
		do
		{
			curSelected = CoolUtil.repeat(curSelected, change, optionShit.length);
		}
		while (unselectableCheck(curSelected));
		var bullShit:Int = 0;

		for (grpInput in grpInputs)
			grpInput.alpha = .6;
		for (grpInputAlt in grpInputsAlt)
			grpInputAlt.alpha = .6;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (!unselectableCheck(bullShit - 1))
			{
				item.alpha = .6;
				if (item.targetY == 0)
				{
					item.alpha = 1;
					for (grpInput in (if (curAlt) grpInputsAlt else grpInputs))
					{
						if (grpInput.sprTracker == item)
						{
							grpInput.alpha = 1;
							break;
						}
					}
				}
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	private inline function changeAlt()
	{
		curAlt = !curAlt;
		for (grpInput in grpInputs)
		{
			if (grpInput.sprTracker == grpOptions.members[curSelected])
			{
				grpInput.alpha = !curAlt ? 1 : .6;
				break;
			}
		}
		for (grpInputAlt in grpInputsAlt)
		{
			if (grpInputAlt.sprTracker == grpOptions.members[curSelected])
			{
				grpInputAlt.alpha = curAlt ? 1 : .6;
				break;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	private inline function unselectableCheck(num:Int, ?checkDefaultKey:Bool = false):Bool
	{
		if (optionShit[num][0] == defaultKey)
			return checkDefaultKey;
		return optionShit[num].length < 2 && optionShit[num][0] != defaultKey;
	}

	private inline function addBindTexts(optionText:Alphabet, num:Int)
	{
		var keys:Array<Dynamic> = ClientPrefs.getKeyArray(ClientPrefs.keyBinds.get(optionShit[num][1]));
		var text1 = new AttachedText(InputFormatter.getKeyName(keys[0]), 400, -55);

		text1.setPosition(optionText.x + 400, optionText.y - 55);
		text1.sprTracker = optionText;

		var text2 = new AttachedText(InputFormatter.getKeyName(keys[1]), 650, -55);

		text2.setPosition(optionText.x + 650, optionText.y - 55);
		text2.sprTracker = optionText;

		grpInputs.push(text1);
		grpInputsAlt.push(text2);

		add(text1);
		add(text2);
	}

	private inline function reloadKeys()
	{
		while (grpInputs.length > 0)
		{
			var item:AttachedText = grpInputs[0];
			item.kill();

			grpInputs.remove(item);
			item.destroy();
		}
		while (grpInputsAlt.length > 0)
		{
			var item:AttachedText = grpInputsAlt[0];
			item.kill();

			grpInputsAlt.remove(item);
			item.destroy();
		}

		trace('Reloaded keys: ' + ClientPrefs.keyBinds);
		for (i in 0...grpOptions.length)
		{
			if (!unselectableCheck(i, true))
				addBindTexts(grpOptions.members[i], i);
		}

		var bullShit:Int = 0;
		for (grpInput in grpInputs)
			grpInput.alpha = .6;
		for (grpInputAlt in grpInputsAlt)
			grpInputAlt.alpha = .6;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (!unselectableCheck(bullShit - 1))
			{
				item.alpha = .6;
				if (item.targetY == 0)
				{
					item.alpha = 1;
					for (grpInput in (if (curAlt) grpInputsAlt else grpInputs))
					{
						if (grpInput.sprTracker == item)
							grpInput.alpha = 1;
					}
				}
			}
		}
	}
}
