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
	private static final options:Array<String> = ['Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay'];

	public static var toPlayState:Bool = false;
	private static var curSelected:Int = 0;

	private var grpOptions:FlxTypedGroup<Alphabet>;

	private var selectorRight:Alphabet;
	private var selectorLeft:Alphabet;

	private function openSelectedSubstate(label:String)
	{
		switch (Paths.formatToSongPath(label))
		{
			case 'controls':
				openSubState(new ControlsSubState());
			case 'graphics':
				openSubState(new GraphicsSettingsSubState());
			case 'visuals-and-ui':
				openSubState(new VisualsUISubState());
			case 'gameplay':
				openSubState(new GameplaySettingsSubState());

			case 'adjust-delay-and-combo':
				LoadingState.loadAndSwitchState(new NoteOffsetState(), false, true);
		}
	}

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
		selectorRight = new Alphabet(0, 0, '<', true);

		add(selectorLeft);
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
			if (toPlayState)
			{
				toPlayState = false;

				FlxG.sound.music?.fadeOut(.5, 0);
				MusicBeatState.switchState(new PlayState());
			}
			else
			{
				MusicBeatState.switchState(new MainMenuState());
			}
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
