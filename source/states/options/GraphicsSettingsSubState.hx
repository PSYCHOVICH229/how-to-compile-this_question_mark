package states.options;

import meta.data.ClientPrefs;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;

using StringTools;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Graphics';
		rpcTitle = 'Graphics Settings Menu'; // for Discord Rich Presence

		addOption(new Option('Low Quality', // Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', // Description
			'lowQuality', // Save data variable name
			'bool', // Variable type
			false // Default value
		));

		var option:Option = new Option('Anti-Aliasing', 'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'globalAntialiasing', 'bool', true);

		option.showBoyfriend = true;
		option.onChange = onChangeAntiAliasing; // Changing onChange is only needed if you want to make a special interaction after it changes the value

		addOption(option);
		addOption(new Option('Shaders', 'If unchecked, disables shaders.\nIt\'s used for some visual effects, and CPU intensive for weaker PCs.', 'shaders',
			'bool', true));
		#if !html5 // Apparently other framerates isn't correctly supported on Browser?
		var option:Option = new Option('Framerate', "Sets the game's framerate to the selected value.", 'framerate', 'int', 60);

		option.minValue = 30;
		option.maxValue = 480;

		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;

		addOption(option);
		#end
		super();
	}

	private function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			if (sprite != null && (sprite is FlxSprite) && !(sprite is FlxText))
				cast(sprite, FlxSprite).antialiasing = ClientPrefs.getPref('globalAntialiasing');
		}
	}

	private function onChangeFramerate()
	{
		var framerate:Int = ClientPrefs.getPref('framerate');
		if (framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = framerate;
			FlxG.drawFramerate = framerate;
		}
		else
		{
			FlxG.drawFramerate = framerate;
			FlxG.updateFramerate = framerate;
		}
	}
}
