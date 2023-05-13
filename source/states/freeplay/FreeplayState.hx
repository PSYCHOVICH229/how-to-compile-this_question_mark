package states.freeplay;

import meta.data.WeekData;
import meta.PlayerSettings;
import meta.Discord.DiscordClient;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import meta.CoolUtil;
import meta.data.ClientPrefs;
import flixel.FlxSprite;
import flixel.FlxG;

class FreeplayState extends MusicBeatState
{
	public inline static final BEND_HARD_WEEK:String = 'bend';
	public inline static final KILLGAMES_WEEK:String = 'kill';

	public static var lastStateSelected:Null<Int> = null;
	private static var curSelected:Int = 0;

	public static var panels:Array<Array<Dynamic>> = [
		['storymode', StoryMenuState.storyWeeks, 0],
		['extras', ['freeplay'], 0],
		['covers', ['covers', 'expurgation', 'opposition', 'screwed'], 0]
	];

	private var outlineGroup:FlxSpriteGroup;
	private var panelGroup:FlxSpriteGroup;

	private var bg:FlxSprite;

	private var deselectedColor:FlxColor = FlxColor.BLACK;
	private var selectedColor:FlxColor = FlxColor.WHITE;

	private var borderThickness:Float = 8;
	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		persistentUpdate = persistentDraw = true;
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);

		var extraWeeks:Array<String> = panels[1][1];
		var coverWeeks:Array<String> = panels[2][1];

		#if !debug if (ClientPrefs.getPref('killgames')) #end extraWeeks.push(KILLGAMES_WEEK);
		#if !debug if (ClientPrefs.getPref('bendHard')) #end extraWeeks.push(BEND_HARD_WEEK);

		bg = new FlxSprite().loadGraphic(Paths.image('menume2'));
		bg.antialiasing = ClientPrefs.getPref('globalAntialiasing');

		outlineGroup = new FlxSpriteGroup();
		panelGroup = new FlxSpriteGroup();

		bg.scrollFactor.set();

		outlineGroup.scrollFactor.set();
		panelGroup.scrollFactor.set();

		var doubleThickness:Float = borderThickness * 2;
		for (i in 0...panels.length)
		{
			var name:String = panels[i][0];
			var panel:FlxSprite = new FlxSprite().loadGraphic(Paths.image(#if !debug !freeplaySectionUnlocked(i) ? 'freeplay/locked' : #end 'freeplay/' + Paths.formatToSongPath(name)));

			panel.antialiasing = ClientPrefs.getPref('globalAntialiasing');
			panel.scrollFactor.set();

			panel.x = (panel.width + (doubleThickness * 2)) * i;
			var outline:FlxSprite = new FlxSprite(panel.x, panel.y).makeGraphic(Math.round(panel.width + doubleThickness), Math.round(panel.height + doubleThickness), FlxColor.WHITE);

			outline.ID = i;
			panel.ID = i;

			outlineGroup.add(outline);
			panelGroup.add(panel);
		};

		bg.screenCenter();
		add(bg);

		add(outlineGroup);
		add(panelGroup);

		outlineGroup.screenCenter();
		panelGroup.screenCenter();

		changeSelection();
		super.create();
	}

	public inline static function freeplaySectionUnlocked(index:Int):Bool
	{
		var unlocked:Array<Bool> = ClientPrefs.getPref('freeplay');
		return panels[index] != null && unlocked[index];
	}

	public inline static function exitToFreeplay()
	{
		if (lastStateSelected != null)
		{
			var lastState:Array<Dynamic> = panels[lastStateSelected];

			ListState.selectedMenu = lastStateSelected;
			ListState.curSelected = lastState[2];
			ListState.weeks = lastState[1];

			MusicBeatState.switchState(new ListState());
			return;
		}
		MusicBeatState.switchState(new FreeplayState());
	}

	private function changeSelection(change:Int = 0)
	{
		curSelected = CoolUtil.repeat(curSelected, change, panels.length);
		outlineGroup.forEachAlive(function(outline:FlxSprite) {
			outline.color = outline.ID == curSelected ? selectedColor : deselectedColor;
		});
	}

	override function update(elapsed:Float)
	{
		FlxG.mouse.visible = false;

		var delta:Int = PlayerSettings.controls.diff(UI_RIGHT, UI_LEFT, JUST_PRESSED, JUST_PRESSED);
		if (delta != 0)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			changeSelection(delta);
		}
		if (PlayerSettings.controls.is(ACCEPT))
		{
			for (panel in panelGroup.members)
			{
				if (panel.ID == curSelected)
				{
					var stateSelected:Array<Dynamic> = panels[curSelected];
					#if !debug
					if (!freeplaySectionUnlocked(curSelected))
					{
						FlxG.sound.play(Paths.sound('cancelMenu'));
						return;
					}
					#end

					lastStateSelected = curSelected;
					persistentUpdate = false;

					ListState.selectedMenu = curSelected;

					ListState.curSelected = stateSelected[2];
					ListState.weeks = stateSelected[1];

					FlxG.sound.play(Paths.sound('scrollMenu'));
					MusicBeatState.switchState(new ListState());
				}
			}
		}
		if (PlayerSettings.controls.is(BACK))
		{
			persistentUpdate = false;

			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
		super.update(elapsed);
	}
}
