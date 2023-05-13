package states.options;

import meta.PlayerSettings;
import meta.CoolUtil;
import meta.data.ClientPrefs;
import meta.instances.Alphabet;
import meta.Discord.DiscordClient;
import meta.Controls;
import flash.text.TextField;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxG;
import flixel.FlxSprite;
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

class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay'];
	private var grpOptions:FlxTypedGroup<Alphabet>;

	private static var curSelected:Int = 0;
	public static var menume1:FlxSprite;

	private function openSelectedSubstate(label:String)
	{
		switch (label)
		{
			case 'Controls':
				openSubState(new ControlsSubState());
			case 'Graphics':
				openSubState(new GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new VisualsUISubState());
			case 'Gameplay':
				openSubState(new GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				LoadingState.loadAndSwitchState(new NoteOffsetState(), false, true);
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create()
	{
		DiscordClient.changePresence("Options Menu", null);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menume'));
		bg.color = 0xFFea71fd;

		bg.updateHitbox();
		bg.screenCenter();

		bg.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		add(bg);

		grpOptions = new FlxTypedGroup();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);

			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;

			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		changeSelection();

		ClientPrefs.saveSettings();
		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var delta:Int = PlayerSettings.controls.diff(UI_DOWN, UI_UP, JUST_PRESSED, JUST_PRESSED);
		if (delta != 0)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			changeSelection(delta);
		}

		if (PlayerSettings.controls.is(BACK))
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
		if (PlayerSettings.controls.is(ACCEPT))
			openSelectedSubstate(options[curSelected]);
	}

	private function changeSelection(change:Int = 0)
	{
		curSelected = CoolUtil.repeat(curSelected, change, options.length);

		var bullShit:Int = 0;
		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = .6;
			if (item.targetY == 0)
			{
				item.alpha = 1;

				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;

				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
	}
}
