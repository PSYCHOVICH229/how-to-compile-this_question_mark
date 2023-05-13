package states.options;

import meta.Hitsound;
import meta.data.ClientPrefs;
import states.options.Option;

using StringTools;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Gameplay Settings';
		rpcTitle = 'Gameplay Settings Menu'; // for Discord Rich Presence

		addOption(new Option('Controller Mode', 'Check this if you want to play with\na controller instead of using your Keyboard.', 'controllerMode', 'bool',
			false));
		addOption(new Option('Downscroll', // Name
			'If checked, notes go Down instead of Up.', // Description
			'downScroll', // Save data variable name
			'bool', // Variable type
			false // Default value
		));

		addOption(new Option('Middlescroll', 'If checked, your notes get centered.', 'middleScroll', 'bool', false));

		addOption(new Option('Opponent Notes', 'If unchecked, opponent notes get hidden.', 'opponentStrums', 'bool', true));
		addOption(new Option('Ghost Tapping', "If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.", 'ghostTapping',
			'bool', true));

		var option:Option = new Option('Mechanics', "If checked, mechanics (i.e horse cheese notes)\nwill be enabled.", 'mechanics', 'bool', true);
		option.onChange = onMechanicsChanged;

		addOption(option);
		addOption(new Option('Disable Reset Button', "If checked, pressing Reset won't do anything.", 'noReset', 'bool', false));

		var option:Option = new Option('Hitsound', "The type of hitsound you want to use.", 'hitsound', 'string', 'default',
			['Default', 'Funnying', 'Top 10', 'HIT_2', 'BF']);
		option.onChange = Hitsound.play.bind();
		addOption(option);

		var option:Option = new Option('Hitsound Volume', "The volume your hitsound plays at when a note is hit.", 'hitsoundVolume', 'percent', 0);

		option.onChange = Hitsound.play.bind();
		option.scrollSpeed = 1.6;

		option.minValue = 0;
		option.maxValue = 1;

		option.changeValue = .05;
		option.decimals = 2;

		addOption(option);
		super();
	}

	private function onMechanicsChanged():Void
	{
		PlayState.mechanicsEnabled = ClientPrefs.getPref('mechanics');
	}
}
