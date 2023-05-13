package states.options;

import meta.data.ClientPrefs;
import flixel.FlxG;

using StringTools;

class VisualsUISubState extends BaseOptionsMenu
{
	public static var fullscreenOption:Option;

	private var changedMusic:Bool = false;

	public function new()
	{
		title = 'Visuals and UI';
		rpcTitle = 'Visuals & UI Settings Menu'; // for Discord Rich Presence

		addOption(new Option('Note Splashes', "If unchecked, hitting \"Sick!\" notes won't show particles.", 'noteSplashes', 'bool', true));
		addOption(new Option('Hide HUD', 'If checked, hides most HUD elements.', 'hideHUD', 'bool', false));

		addOption(new Option('Time Bar:', "What should the Time Bar display?", 'timeBarType', 'string', 'time-left',
			['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']));

		addOption(new Option('Flashing Lights', "Uncheck this if you're sensitive to flashing lights!", 'flashing', 'bool', true));
		addOption(new Option('Reduced Motion', "If checked, extra effects such as the camera moving when a character hits a note are disabled.",
			'reducedMotion', 'bool', false));

		addOption(new Option('Camera Zooms', "If unchecked, the camera won't zoom in on a beat hit.", 'camZooms', 'bool', true));
		addOption(new Option('Lyrics', "If checked, very titular \"lyrics\" will appear infront of the screen.", 'subtitles', 'bool', true));

		addOption(new Option('Combo Stacking', "If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read",
			'comboStacking', 'bool', true));
		addOption(new Option('Score Text Zoom on Hit', "If unchecked, disables the Score text zooming\neverytime you hit a note.", 'scoreZoom', 'bool', true));

		var option:Option = new Option('Health Bar Transparency', 'How transparent the health bar and icons should be.', 'healthBarAlpha', 'percent', 1);
		option.scrollSpeed = 1.6;

		option.minValue = 0;
		option.maxValue = 1;

		option.changeValue = .05;
		option.decimals = 2;

		addOption(option);
		var option:Option = new Option('Scroll Underlay Transparency', 'How transparent the underlay under your strumline should be.', 'scrollUnderlay',
			'percent', 0);
		option.scrollSpeed = 1.6;

		option.minValue = 0;
		option.maxValue = 1;

		option.changeValue = .05;
		option.decimals = 2;

		addOption(option);

		var option:Option = new Option('FPS Counter', 'If unchecked, hides FPS Counter.', 'showFPS', 'bool', false);
		option.onChange = ClientPrefs.onChangeSetting.bind('showFPS');

		addOption(option);
		#if !web
		fullscreenOption = new Option('Fullscreen', 'If checked, enables fullscreen.', 'fullscreen', 'bool', false);
		fullscreenOption.onChange = ClientPrefs.onChangeSetting.bind('fullscreen');

		addOption(fullscreenOption);
		#end
		var option:Option = new Option('Pause Screen Song:', "What song do you prefer for the Pause Screen?", 'pauseMusic', 'string', 'pulse',
			['None', 'Pulse', 'Shuttle Man', 'Breakfast', 'Scratch']);

		option.onChange = onChangePauseMusic;
		addOption(option);

		super();
	}

	override function destroy()
	{
		if (changedMusic)
			TitleState.playTitleMusic();
		fullscreenOption = null;
		super.destroy();
	}

	private function onChangePauseMusic()
	{
		var path:String = Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic'));
		trace(path);
		switch (path)
		{
			case 'none':
				FlxG.sound.music.volume = 0;
			default:
				{
					FlxG.sound?.music?.stop();

					FlxG.sound.playMusic(Paths.music(path));
					FlxG.sound.music.play(true);
				}
		}
		changedMusic = true;
	}
}
