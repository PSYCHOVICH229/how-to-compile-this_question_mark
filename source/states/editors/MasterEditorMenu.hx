package states.editors;

import meta.PlayerSettings;
import meta.CoolUtil;
import meta.Discord.DiscordClient;
import meta.instances.Alphabet;
import meta.instances.Character;
import states.editors.*;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
#if sys
import sys.FileSystem;
#end

using StringTools;

class MasterEditorMenu extends MusicBeatState
{
	var options:Array<String> = [
		'Dialogue Editor',
		'Dialogue Portrait Editor',
		'Character Editor',
		'Chart Editor'
	];
	private var grpTexts:FlxTypedGroup<Alphabet>;
	private var directories:Array<String> = [null];

	private var curSelected = 0;
	private var curDirectory = 0;
	private var directoryTxt:FlxText;

	override function create()
	{
		FlxG.camera.bgColor = FlxColor.BLACK;
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Editors Main Menu", null);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menume'));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		grpTexts = new FlxTypedGroup();
		add(grpTexts);

		for (i in 0...options.length)
		{
			var leText:Alphabet = new Alphabet(90, 320, options[i], true);

			leText.isMenuItem = true;
			leText.targetY = i;

			grpTexts.add(leText);
			leText.snapToPosition();
		}
		changeSelection();

		FlxG.mouse.visible = false;
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (PlayerSettings.controls.is(UI_UP, JUST_PRESSED))
		{
			changeSelection(-1);
		}
		if (PlayerSettings.controls.is(UI_DOWN, JUST_PRESSED))
		{
			changeSelection(1);
		}

		if (PlayerSettings.controls.is(BACK))
		{
			MusicBeatState.switchState(new MainMenuState());
		}

		if (PlayerSettings.controls.is(ACCEPT))
		{
			switch (options[curSelected])
			{
				case 'Character Editor':
					LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false), false, true);
				case 'Dialogue Portrait Editor':
					LoadingState.loadAndSwitchState(new DialogueCharacterEditorState(), false, true);
				case 'Dialogue Editor':
					LoadingState.loadAndSwitchState(new DialogueEditorState(), false, true);
				case 'Chart Editor': // felt it would be cool maybe
					LoadingState.loadAndSwitchState(new ChartingState(), false, true);
			}
			FlxG.sound.music.volume = 0;
		}

		var bullShit:Int = 0;
		for (item in grpTexts.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = .6;
			// item.setGraphicSize(Std.int(item.width * .8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		super.update(elapsed);
	}

	private function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), .4);
		curSelected = CoolUtil.repeat(curSelected, change, options.length);
	}
}
