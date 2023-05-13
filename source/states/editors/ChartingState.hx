package states.editors;

import flixel.addons.ui.FlxUIInputText;
import meta.instances.AttachedSprite;
import meta.instances.HealthIcon;
import meta.instances.notes.StrumNote;
import meta.instances.notes.Note;
import meta.instances.Prompt;
import meta.data.StageData;
import meta.CoolUtil;
import meta.data.ClientPrefs;
import states.editors.MasterEditorMenu;
import meta.Hitsound;
import meta.Conductor;
import meta.Conductor.BPMChangeEvent;
import meta.data.Song.SwagSection;
import meta.instances.Character;
import meta.instances.AttachedFlxText;
import meta.data.Song;
import meta.data.Song.SwagSong;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import haxe.Json;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

import meta.Discord.DiscordClient;

@:access(flixel.sound.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)
class ChartingState extends MusicBeatState
{
	public static final noteTypeList:Array<String> = // Used for backwards compatibility with .1 - .3.2 charts, though, you should add your hardcoded custom note types here too.
	[
		'', 'Alt Animation', 'Hey!', 'horse cheese note', 'GF Sing', 'No Animation', 'trickyNote', 'Duo Note', 'Trio Note', 'Both Opponents Note',
		'All Opponents Note'
	];

	private var noteTypeIntMap:Map<Int, String> = new Map();
	private var noteTypeMap:Map<String, Null<Int>> = new Map();

	public var ignoreWarnings = false;

	private var undos = [];
	private var redos = [];

	private static var shootChance:Int = Math.round(PlayState.shootChance);
	private static final eventStuff:Array<Dynamic> = [
		['', "Nothing. Yep, that's right."],
		[
			'Hey!',
			"Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for .6s"
		],
		[
			'Set GF Speed',
			"Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"
		],
		['Add Camera Zoom',
			"Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: "
			+ PlayState.GAME_BOP
			+ ")\nValue 2: UI zoom add (Default: "
			+ PlayState.HUD_BOP
			+ ")\nLeave the values blank if you want to use Default."],
		[
			'Change Default Zoom',
			"Adds the value to the default camera zoom\nValue 1: Camera zoom add\nValue 2: Tween Time in Beats (ease specified with a comma)\nLeave blank if you want to go back to the original zoom."
		],
		[
			'Roid',
			"Creates a red gradient.\nValue 1: Side (false: left, true: right)\nValue 2: Time in Beats (Default: 4)"
		],
		[
			'Set Shuttle Beats',
			"Directly sets the next beat the shuttle\nwill interpolate to.\nValue 1: Beat\nLeave blank or <0 to destroy the shuttle when it's hit."
		],
		[
			'Set Zoom Type',
			"Changes the zoom type\nValue 1: Camera zoom type (Default: 0)\nValue 2: Beat offset (Default: 0)\nLeave the values blank if you want to use Default."
		],
		['Legalize Nuclear Bombs', 'leglaize nuclear bombs'],
		[
			'Funny Duo',
			"Events for Funny Duo\nValue 1: The event to use.\nValue 2: Arguments."
		],
		['Nod Camera', 'Tilts the camera left/right every beat.\nValue 1: Enabled'],
		[
			'Foursome Lights',
			"Lights for Foursome\nValue 1: The angle (between 0 - 3).\nValue 2: Color and tween time."
		],
		['Foursome Frame', "Adds a frame\nValue 1: Frame type (0-1-false)"],
		['Foolish Type Beat', "Events for Foolish\nValue 1: The event to use."],
		[
			'Horse',
			"HORSE! AAAAAAUUHH IT'S A HORSE!\nAAAAAAUHHH IT'S A HORSE'S PEEPEEEEE!!!!\nValue 1: Active"
		],
		[
			'Play Video',
			'Plays a video.\nValue 1: Video name (assets/videos/...)\nValue 2: Camera (game, other, default: hud)'
		],
		[
			'Stop Videos',
			'Stops all currently playing videos.'
		],
		[
			'Vignette',
			"Creates a vignette that bops to the beat.\nValue 1: Enabled\nTo set the visibility, type 'true' or 'false'"
		],
		[
			'Shoot',
			'Today is Friday in California.\nCauses a gunshot to happen ~$shootChance% of the time.'
		],
		['Get Gun Out', 'Equips the gun in Bend Hard.'],
		[
			'Subtitles',
			"Makes subtitles appear.\nValue 1: Text\nValue 2: Character\nTo get rid of the text, leave value 1 blank."
		],
		[
			'Flash Camera',
			"Flashes the camera\nValue 1: Duration (Default: 1)\nValue 2: Color (Default: 0xFFFFFFFF)\nLeave the values blank if you want to use Default."
		],
		[
			'Cover Camera',
			"Covers the camera with a color.\nValue 1: Color (Default: 0xFF000000)\nValue 2: Fade in beats, (optional) Delay, Ease (Default: 1)"
		],
		[
			'Change Character Visibility',
			"Changes a character's visibility.\nTo set the visibility, type 'true' or 'false'\nValue 1: Character to set (Dad, BF or GF)\nValue 2: Visible (Default: True)"
		],
		[
			'Extend Timer',
			"Extends the timer to the next event, or the song's length\nwhen this event is reached."
		],
		['Play Sound', "Plays a sound\nValue 1: Sound to play."],
		[
			'Play Animation',
			"Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"
		],
		[
			'Camera Follow Pos',
			"Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."
		],
		[
			'Alt Idle Animation',
			"Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"
		],
		[
			'Sustain Shake',
			"Continuously shakes the screen until stopped.\nValue 1: Camera shake\nValue 2: HUD Shake\nLeave the values blank or as 0 to stop shaking the screen."
		],
		[
			'Screen Shake',
			"Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, .05\".\nThe first number (1) is the duration.\nThe second number (.05) is the intensity."
		],
		['Toggle Cervix Wavy Shader', 'In the name.\nValue 1: Enabled (true, false)'],
		[
			'Shift Note Rotation',
			'Makes the notes rotate 90 degrees.\nValue 1: Snap to angle (instant).'
		],
		['Relapse Float', 'Makes the Relapse Boy float.\nNo other purpose.'],
		['Relapse Spikes', 'Shows the spikes in the background.'],
		[
			'Relapse Pixelation',
			'Toggles the pixelation effect.\nValue 1: Enabled (true, false)'
		],
		[
			'Relapse Chromatic Aberration',
			'Changes the chromatic aberration for Relapse.\nValue 1: Strength\nValue 2: Tween time in beats,\nEasing style'
		],
		[
			'Relapse CRT Distortion',
			'Changes the CRT distortion for Relapse.\nValue 1: Strength\nValue 2: Tween time in beats,\nEasing ltyle'
		],
		[
			'Killgames Static Transparency',
			'Changes the alpha of the Killgames static,\nValue 1: Alpha\nValue 2: Tween tine in beats,\nEasing style'
		],
		['Killgames Murder', 'murder evil baest'],
		[
			'Change Character',
			"Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"
		],
		['Change Stage', "Value 1: Stage to change to\nValue 2: Other data"],
		[
			'Change Scroll Speed',
			"Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."
		],
		[
			'Change Strumline Visibility',
			'Value 1: Strumline (dad, bf, both)\nValue 2: Visible (true/false),\n(optional) Tween Time in Beats, Easing Style'
		]
	];

	private var _file:FileReference;
	private var UI_box:FlxUITabMenu;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	public static var curSec:Int = 0;

	private static var lastSong:String = '';

	private var bpmTxt:FlxText;

	private var camPos:FlxObject;
	private var strumLine:FlxSprite;
	private var quant:AttachedSprite;
	private var strumLineNotes:FlxTypedGroup<StrumNote>;

	public static var GRID_SIZE:Int = 40;

	private var CAM_OFFSET:Int = 360;
	private var dummyArrow:FlxSprite;

	private var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	private var curRenderedNotes:FlxTypedGroup<Note>;
	private var curRenderedNoteType:FlxTypedGroup<FlxText>;

	private var nextRenderedSustains:FlxTypedGroup<FlxSprite>;
	private var nextRenderedNotes:FlxTypedGroup<Note>;

	private var gridBG:FlxSprite;
	private var nextGridBG:FlxSprite;

	private var curEventSelected:Int = 0;
	private var _song:SwagSong;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	private var curSelectedNote:Array<Dynamic> = null;

	private var tempBpm:Float = 0;

	private var vocals:FlxSound = null;

	private var leftIcon:HealthIcon;
	private var rightIcon:HealthIcon;

	private var value1InputText:FlxUIInputText;
	private var value2InputText:FlxUIInputText;
	private var currentSongName:String;

	private var zoomTxt:FlxText;
	private var curZoom:Int = 2;

	private var zoomList:Array<Float> = [.25, .5, 1, 2, 3, 4, 6, 8, 12, 16, 24];

	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];

	private var waveformSprite:FlxSprite;
	private var gridLayer:FlxTypedGroup<FlxSprite>;

	public static var quantization:Int = 16;
	public static var curQuant = 3;

	public var quantizations:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];

	private var text:String = "";

	public static var vortex:Bool = false;

	public var mouseQuant:Bool = false;

	override function create()
	{
		// just do this here because it gets laggy on songs that take up lots of mem
		Paths.clearUnusedMemory();
		Paths.clearStoredMemory();

		if (PlayState.SONG != null)
		{
			_song = PlayState.SONG;
		}
		else
		{
			CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
			_song = {
				song: 'Test',
				notes: [],
				events: null,
				bpm: 120.0,
				needsVoices: true,
				player1: 'bf',
				player2: 'gf',
				speed: 2,
				stage: 'stage',
				validScore: false
			};
			addSection();
			PlayState.SONG = _song;
		}
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Chart Editor", StringTools.replace(_song.song, '-', ' '));

		ignoreWarnings = ClientPrefs.getPref('ignoreWarnings', false);
		vortex = ClientPrefs.getPref('chart_vortex', false);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menume'));

		bg.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		bg.scrollFactor.set();

		bg.color = 0xFF3B0856;
		add(bg);

		gridLayer = new FlxTypedGroup();
		add(gridLayer);

		waveformSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
		add(waveformSprite);

		var eventIcon:FlxSprite = new FlxSprite(-GRID_SIZE + 45, -40).loadGraphic(Paths.image('eventArrow'));

		rightIcon = new HealthIcon('gf');
		leftIcon = new HealthIcon('bf');

		eventIcon.scrollFactor.set(1, 1);

		rightIcon.scrollFactor.set(1, 1);
		leftIcon.scrollFactor.set(1, 1);

		eventIcon.setGraphicSize(30, 30);
		eventIcon.updateHitbox();

		add(eventIcon);

		add(leftIcon);
		add(rightIcon);

		curRenderedSustains = new FlxTypedGroup();
		curRenderedNotes = new FlxTypedGroup();
		curRenderedNoteType = new FlxTypedGroup();

		nextRenderedSustains = new FlxTypedGroup();
		nextRenderedNotes = new FlxTypedGroup();

		if (curSec >= _song.notes.length)
			curSec = _song.notes.length - 1;

		FlxG.mouse.visible = true;
		tempBpm = _song.bpm;
		addSection();

		// sections = _song.notes;

		currentSongName = Paths.formatToSongPath(_song.song);

		loadSong();
		reloadGridLayer();

		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * 9), 4);
		add(strumLine);

		quant = new AttachedSprite('chart_quant', 'chart_quant');
		quant.animation.addByPrefix('q', 'chart_quant', 0, false);
		quant.animation.play('q', true, false, 0);
		quant.sprTracker = strumLine;
		quant.xAdd = -32;
		quant.yAdd = 8;
		add(quant);

		strumLineNotes = new FlxTypedGroup();
		for (i in 0...8)
		{
			var note:StrumNote = new StrumNote(GRID_SIZE * (i + 1), strumLine.y, i % 4, 0);
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.playAnim('static', true);
			strumLineNotes.add(note);
			note.scrollFactor.set(1, 1);
		}
		add(strumLineNotes);

		camPos = new FlxObject(0, 0, 1, 1);
		camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},
			{name: "Events", label: 'Events'},
			{name: "Charting", label: 'Charting'},
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(300, 400);

		UI_box.x = 640 + GRID_SIZE / 2;
		UI_box.y = 25;

		UI_box.scrollFactor.set();

		text = "W/S or Mouse Wheel - Change Conductor's strum time
		\nA/D - Go to the previous/next section
		\nLeft/Right - Change Snap
		\nUp/Down - Change Conductor's Strum Time with Snapping
		\nHold Shift to move 4x faster
		\nHold Control and click on an arrow to select it
		\nZ/X - Zoom in/out
		\n
		\nEnter - Play your chart
		\nQ/E - Decrease/Increase Note Sustain Length
		\nSpace - Stop/Resume song";

		var tipTextArray:Array<String> = text.split('\n');
		for (i in 0...tipTextArray.length)
		{
			var tipText:FlxText = new FlxText(UI_box.x, UI_box.y + UI_box.height + 8, 0, tipTextArray[i], 16);

			tipText.y += i * 12;
			tipText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT /*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
			// tipText.borderSize = 2;
			tipText.scrollFactor.set();
			add(tipText);
		}
		add(UI_box);

		addSongUI();
		addSectionUI();
		addNoteUI();
		addEventsUI();
		addChartingUI();
		updateHeads();
		updateWaveform();
		// UI_box.selected_tab = 4;

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedNoteType);
		add(nextRenderedSustains);
		add(nextRenderedNotes);

		if (lastSong != currentSongName)
			changeSection();

		lastSong = currentSongName;

		zoomTxt = new FlxText(10, 10, 0, "Zoom: 1 / 1", 16);
		zoomTxt.scrollFactor.set();
		add(zoomTxt);

		updateGrid();
		super.create();
	}

	var check_mute_inst:FlxUICheckBox = null;
	var check_vortex:FlxUICheckBox = null;
	var check_warnings:FlxUICheckBox = null;

	var playSoundBf:FlxUICheckBox = null;
	var playSoundDad:FlxUICheckBox = null;

	var UI_songTitle:FlxUIInputText;

	var noteSkinInputText:FlxUIInputText;
	var noteSplashesInputText:FlxUIInputText;

	var stageDropDown:FlxUIDropDownMenuCustom;

	private function addSongUI():Void
	{
		UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		blockPressWhileTypingOn.push(UI_songTitle);

		var check_voices:FlxUICheckBox = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
			// trace('CHECKED!');
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveSong();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + 90, saveButton.y, "Reload Audio", function()
		{
			currentSongName = Paths.formatToSongPath(UI_songTitle.text);
			loadSong();
			updateWaveform();
		});
		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function()
			{
				loadJson(_song.song.toLowerCase());
			}, null, ignoreWarnings));
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'Load Autosave', function()
		{
			var autosaved:Null<String> = ClientPrefs.getPref('autosave');
			if (autosaved != null)
			{
				PlayState.SONG = Song.parseJSONshit(autosaved);
				MusicBeatState.resetState();
			}
		});
		var loadEventJson:FlxButton = new FlxButton(loadAutosaveBtn.x, loadAutosaveBtn.y + 30, 'Load Events', function()
		{
			var songName:String = Paths.formatToSongPath(_song.song);
			var file:String = Paths.json(songName, 'events', 'songs');

			if (OpenFlAssets.exists(file))
			{
				clearEvents();

				var events:SwagSong = Song.loadFromJson('events', songName);
				_song.events = events.events;

				changeSection(curSec);
			}
		});

		var saveEvents:FlxButton = new FlxButton(110, reloadSongJson.y, 'Save Events', function()
		{
			saveEvents();
		});
		var clear_events:FlxButton = new FlxButton(320, 310, 'Clear events', function()
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, clearEvents, null, ignoreWarnings));
		});

		clear_events.color = FlxColor.RED;
		clear_events.label.color = FlxColor.WHITE;

		var clear_notes:FlxButton = new FlxButton(320, clear_events.y + 30, 'Clear notes', function()
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function()
			{
				for (sec in 0..._song.notes.length)
				{
					_song.notes[sec].sectionNotes = [];
				}
				updateGrid();
			}, null, ignoreWarnings));
		});

		clear_notes.color = FlxColor.RED;
		clear_notes.label.color = FlxColor.WHITE;

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 70, 1, 1, 1, 400, 3);

		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		blockPressWhileTypingOnStepper.push(stepperBPM);
		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, stepperBPM.y + 35, .1, 1, .1, 10, 1);

		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';

		blockPressWhileTypingOnStepper.push(stepperSpeed);

		var tempMap:Map<String, Bool> = new Map();
		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));

		for (i in 0...characters.length)
			tempMap.set(characters[i], true);
		var player1DropDown:FlxUIDropDownMenuCustom = new FlxUIDropDownMenuCustom(10, stepperSpeed.y + 45,
			FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player1 = characters[Std.parseInt(character)];
			updateHeads();
		});
		player1DropDown.selectedLabel = _song.player1;
		blockPressWhileScrolling.push(player1DropDown);

		var player2DropDown:FlxUIDropDownMenuCustom = new FlxUIDropDownMenuCustom(player1DropDown.x, player1DropDown.y + 40,
			FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
			updateHeads();
		});
		player2DropDown.selectedLabel = _song.player2;
		blockPressWhileScrolling.push(player2DropDown);

		tempMap.clear();

		var stageFile:Array<String> = CoolUtil.coolTextFile(Paths.txt('stageList'));
		var stages:Array<String> = [];

		for (i in 0...stageFile.length)
		{
			// Prevent duplicates
			var stageToCheck:String = stageFile[i];
			if (!tempMap.exists(stageToCheck))
				stages.push(stageToCheck);
			tempMap.set(stageToCheck, true);
		}
		if (stages.length < 1)
			stages.push('stage');

		stageDropDown = new FlxUIDropDownMenuCustom(player1DropDown.x + 140, player1DropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray(stages, true),
			function(character:String)
			{
				_song.stage = stages[Std.parseInt(character)];
			});

		stageDropDown.selectedLabel = _song.stage;
		blockPressWhileScrolling.push(stageDropDown);

		var skin:String = PlayState.SONG.arrowSkin;
		if (skin == null)
			skin = '';

		noteSkinInputText = new FlxUIInputText(player2DropDown.x, player2DropDown.y + 50, 150, skin, 8);
		blockPressWhileTypingOn.push(noteSkinInputText);

		noteSplashesInputText = new FlxUIInputText(noteSkinInputText.x, noteSkinInputText.y + 35, 150, _song.splashSkin, 8);
		blockPressWhileTypingOn.push(noteSplashesInputText);

		var reloadNotesButton:FlxButton = new FlxButton(noteSplashesInputText.x + 5, noteSplashesInputText.y + 20, 'Change Notes', function()
		{
			var text:String = noteSkinInputText.text;
			if (text.length > 0)
			{
				_song.arrowSkin = text;
			}
			else if (_song.arrowSkin != null)
			{
				_song.arrowSkin = null;
			}
			updateGrid();
		});

		var tab_group_song:FlxUI = new FlxUI(null, UI_box);

		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);

		tab_group_song.add(clear_events);
		tab_group_song.add(clear_notes);

		tab_group_song.add(saveButton);
		tab_group_song.add(saveEvents);

		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);

		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(loadEventJson);

		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);

		tab_group_song.add(reloadNotesButton);

		tab_group_song.add(noteSkinInputText);
		tab_group_song.add(noteSplashesInputText);

		tab_group_song.add(new FlxText(stepperBPM.x, stepperBPM.y - 15, 0, 'Song BPM:'));
		tab_group_song.add(new FlxText(stepperSpeed.x, stepperSpeed.y - 15, 0, 'Song Speed:'));

		tab_group_song.add(new FlxText(player2DropDown.x, player2DropDown.y - 15, 0, 'Opponent:'));
		tab_group_song.add(new FlxText(player1DropDown.x, player1DropDown.y - 15, 0, 'Boyfriend:'));

		tab_group_song.add(new FlxText(stageDropDown.x, stageDropDown.y - 15, 0, 'Stage:'));

		tab_group_song.add(new FlxText(noteSkinInputText.x, noteSkinInputText.y - 15, 0, 'Note Texture:'));
		tab_group_song.add(new FlxText(noteSplashesInputText.x, noteSplashesInputText.y - 15, 0, 'Note Splashes Texture:'));

		tab_group_song.add(player2DropDown);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(stageDropDown);

		UI_box.addGroup(tab_group_song);
		FlxG.camera.follow(camPos);
	}

	var stepperBeats:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;

	var check_gfSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;

	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic>;

	private function addSectionUI():Void
	{
		var tab_group_section:FlxUI = new FlxUI(null, UI_box);

		tab_group_section.name = 'Section';
		check_mustHitSection = new FlxUICheckBox(10, 15, null, null, "Must hit section", 100);

		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = _song.notes[curSec].mustHitSection;

		check_gfSection = new FlxUICheckBox(check_mustHitSection.x + 110, check_mustHitSection.y, null, null, "GF section", 100);

		check_gfSection.name = 'check_gf';
		check_gfSection.checked = _song.notes[curSec].gfSection;
		// _song.needsVoices = check_mustHit.checked;

		check_altAnim = new FlxUICheckBox(check_gfSection.x + 80, check_gfSection.y, null, null, "Alt Animation", 100);
		check_altAnim.checked = _song.notes[curSec].altAnim;

		stepperBeats = new FlxUINumericStepper(check_mustHitSection.x, check_mustHitSection.y + 40, 1, 4, 1, 6, 2);

		stepperBeats.value = getSectionBeats();
		stepperBeats.name = 'section_beats';

		blockPressWhileTypingOnStepper.push(stepperBeats);
		check_changeBPM = new FlxUICheckBox(stepperBeats.x, stepperBeats.y + 20, null, null, 'Change BPM', 100);

		check_changeBPM.checked = _song.notes[curSec].changeBPM;
		check_changeBPM.name = 'check_changeBPM';

		stepperSectionBPM = new FlxUINumericStepper(check_changeBPM.x, check_changeBPM.y + 20, 1, Conductor.bpm, 0, 999, 1);
		if (check_changeBPM.checked)
		{
			stepperSectionBPM.value = _song.notes[curSec].bpm;
		}
		else
		{
			stepperSectionBPM.value = Conductor.bpm;
		}

		stepperSectionBPM.name = 'section_bpm';
		blockPressWhileTypingOnStepper.push(stepperSectionBPM);

		var check_eventsSec:FlxUICheckBox = null;
		var check_notesSec:FlxUICheckBox = null;

		var copyButton:FlxButton = new FlxButton(stepperSectionBPM.x, stepperSectionBPM.y + 30, "Copy Section", function()
		{
			notesCopied = [];
			sectionToCopy = curSec;
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				notesCopied.push(note);
			}

			var startThing:Float = sectionStartTime();
			var endThing:Float = sectionStartTime(1);

			if (_song.events != null)
			{
				for (event in _song.events)
				{
					var strumTime:Float = event[0];
					if (endThing > event[0] && event[0] >= startThing)
					{
						var copiedEventArray:Array<Dynamic> = [];
						for (i in 0...event[1].length)
						{
							var eventToPush:Array<Dynamic> = event[1][i];
							copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
						}
						notesCopied.push([strumTime, -1, copiedEventArray]);
					}
				}
			}
		});

		var pasteButton:FlxButton = new FlxButton(copyButton.x + 100, copyButton.y, "Paste Section", function()
		{
			if (notesCopied == null || notesCopied.length <= 0)
				return;

			var addToTime:Float = Conductor.stepCrochet * (getSectionBeats() * 4 * (curSec - sectionToCopy));
			for (note in notesCopied)
			{
				var copiedNote:Array<Dynamic> = [];
				var newStrumTime:Float = note[0] + addToTime;

				if (note[1] < 0)
				{
					if (check_eventsSec.checked)
					{
						var copiedEventArray:Array<Dynamic> = [];
						for (i in 0...note[2].length)
						{
							var eventToPush:Array<Dynamic> = note[2][i];
							copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
						}

						if (_song.events == null)
							_song.events = [];
						_song.events.push([newStrumTime, copiedEventArray]);
					}
				}
				else if (check_notesSec.checked)
				{
					copiedNote = [newStrumTime, note[1], note[2], note[3]];
					if (note[4] != null)
						copiedNote.push(note[4]);
					_song.notes[curSec].sectionNotes.push(copiedNote);
				}
			}
			updateGrid();
		});

		var clearSectionButton:FlxButton = new FlxButton(pasteButton.x + 100, pasteButton.y, "Clear", function()
		{
			if (check_notesSec.checked)
				_song.notes[curSec].sectionNotes = [];
			if (check_eventsSec.checked && _song.events != null)
			{
				var i:Int = _song.events.length - 1;

				var startThing:Float = sectionStartTime();
				var endThing:Float = sectionStartTime(1);

				while (i > -1)
				{
					var event:Array<Dynamic> = _song.events[i];
					if (event != null && endThing > event[0] && event[0] >= startThing)
						_song.events.remove(event);
					i--;
				}
			}
			curSelectedNote = null;

			updateGrid();
			updateNoteUI();
		});

		clearSectionButton.color = FlxColor.RED;
		clearSectionButton.label.color = FlxColor.WHITE;

		check_notesSec = new FlxUICheckBox(10, clearSectionButton.y + 25, null, null, "Notes", 100);
		check_notesSec.checked = true;

		check_eventsSec = new FlxUICheckBox(check_notesSec.x + 100, check_notesSec.y, null, null, "Events", 100);
		check_eventsSec.checked = true;

		var swapSection:FlxButton = new FlxButton(10, check_notesSec.y + 40, "Swap section", function()
		{
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				_song.notes[curSec].sectionNotes[i] = note;
			}
			updateGrid();
		});

		var stepperCopy:FlxUINumericStepper = null;
		var copyLastButton:FlxButton = new FlxButton(10, swapSection.y + 30, "Copy last section", function()
		{
			if (stepperCopy == null)
				return;

			var value:Int = Std.int(stepperCopy.value);
			if (value == 0)
				return;

			var daSec = FlxMath.maxInt(curSec, value);

			for (note in _song.notes[daSec - value].sectionNotes)
			{
				var strum:Float = note[0] + Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);

				var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
				_song.notes[daSec].sectionNotes.push(copiedNote);
			}

			var startThing:Float = sectionStartTime(-value);
			var endThing:Float = sectionStartTime(-value + 1);

			if (_song.events != null)
			{
				for (event in _song.events)
				{
					var strumTime:Float = event[0];
					if (endThing > event[0] && event[0] >= startThing)
					{
						strumTime += Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);

						var copiedEventArray:Array<Dynamic> = [];
						for (i in 0...event[1].length)
						{
							var eventToPush:Array<Dynamic> = event[1][i];
							copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
						}
						_song.events.push([strumTime, copiedEventArray]);
					}
				}
			}
			updateGrid();
		});

		copyLastButton.setGraphicSize(80, 30);
		copyLastButton.updateHitbox();

		stepperCopy = new FlxUINumericStepper(copyLastButton.x + 100, copyLastButton.y, 1, 1, -999, 999, 0);
		blockPressWhileTypingOnStepper.push(stepperCopy);

		var duetButton:FlxButton = new FlxButton(10, copyLastButton.y + 45, "Duet Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob:Int = note[1];
				if (boob > 3)
				{
					boob -= 4;
				}
				else
				{
					boob += 4;
				}

				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				duetNotes.push(copiedNote);
			}

			for (i in duetNotes)
			{
				_song.notes[curSec].sectionNotes.push(i);
			}

			updateGrid();
		});
		var mirrorButton:FlxButton = new FlxButton(duetButton.x + 100, duetButton.y, "Mirror Notes", function()
		{
			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1] % 4;
				boob = 3 - boob;
				if (note[1] > 3)
					boob += 4;

				note[1] = boob;
			}
			updateGrid();
		});
		copyLastButton.setGraphicSize(80, 30);
		copyLastButton.updateHitbox();

		tab_group_section.add(new FlxText(stepperBeats.x, stepperBeats.y - 15, 0, 'Beats per Section:'));

		tab_group_section.add(stepperBeats);
		tab_group_section.add(stepperSectionBPM);

		tab_group_section.add(check_mustHitSection);

		tab_group_section.add(check_gfSection);
		tab_group_section.add(check_altAnim);

		tab_group_section.add(check_changeBPM);

		tab_group_section.add(copyButton);
		tab_group_section.add(pasteButton);

		tab_group_section.add(clearSectionButton);

		tab_group_section.add(check_notesSec);
		tab_group_section.add(check_eventsSec);

		tab_group_section.add(swapSection);

		tab_group_section.add(stepperCopy);
		tab_group_section.add(copyLastButton);

		tab_group_section.add(duetButton);
		tab_group_section.add(mirrorButton);

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;
	var strumTimeInputText:FlxUIInputText; // I wanted to use a stepper but we can't scale these as far as i know :(

	var noteTypeDropDown:FlxUIDropDownMenuCustom;
	var currentType:Int = 0;

	private function addNoteUI():Void
	{
		var tab_group_note:FlxUI = new FlxUI(null, UI_box);

		tab_group_note.name = 'Note';
		stepperSusLength = new FlxUINumericStepper(10, 25, Conductor.stepCrochet / 2, 0, 0, Conductor.crochet * 16);

		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		blockPressWhileTypingOnStepper.push(stepperSusLength);
		strumTimeInputText = new FlxUIInputText(10, 65, 180, "0");

		tab_group_note.add(strumTimeInputText);
		blockPressWhileTypingOn.push(strumTimeInputText);

		var displayNameList:Array<String> = [];
		var key:Int = 0;

		while (key < noteTypeList.length)
		{
			displayNameList.push(noteTypeList[key]);

			noteTypeMap.set(noteTypeList[key], key);
			noteTypeIntMap.set(key, noteTypeList[key]);

			key++;
		}
		for (i in 1...displayNameList.length)
			displayNameList[i] = '$i. ' + displayNameList[i];

		noteTypeDropDown = new FlxUIDropDownMenuCustom(10, 105, FlxUIDropDownMenuCustom.makeStrIdLabelArray(displayNameList, true), function(character:String)
		{
			currentType = Std.parseInt(character);
			if (curSelectedNote != null && curSelectedNote[1] > -1)
			{
				curSelectedNote[3] = noteTypeIntMap.get(currentType);
				updateGrid();
			}
		});
		blockPressWhileScrolling.push(noteTypeDropDown);

		tab_group_note.add(new FlxText(10, 10, 0, 'Sustain length:'));
		tab_group_note.add(new FlxText(10, 50, 0, 'Strum time (in miliseconds):'));
		tab_group_note.add(new FlxText(10, 90, 0, 'Note type:'));

		tab_group_note.add(stepperSusLength);
		tab_group_note.add(strumTimeInputText);
		tab_group_note.add(noteTypeDropDown);

		UI_box.addGroup(tab_group_note);
	}

	var eventDropDown:FlxUIDropDownMenuCustom;
	var descText:FlxText;
	var selectedEventText:FlxText;

	private function addEventsUI():Void
	{
		var tab_group_event:FlxUI = new FlxUI(null, UI_box);

		tab_group_event.name = 'Events';
		descText = new FlxText(20, 200, 0, eventStuff[0][0]);

		var leEvents:Array<String> = [];
		for (i in 0...eventStuff.length)
			leEvents.push(eventStuff[i][0]);

		var text:FlxText = new FlxText(20, 30, 0, "Event:");

		tab_group_event.add(text);
		eventDropDown = new FlxUIDropDownMenuCustom(20, 50, FlxUIDropDownMenuCustom.makeStrIdLabelArray(leEvents, true), function(pressed:String)
		{
			var selectedEvent:Int = Std.parseInt(pressed);
			descText.text = eventStuff[selectedEvent][1];
			if (curSelectedNote != null && eventStuff != null)
			{
				if (curSelectedNote != null && curSelectedNote[2] == null)
				{
					curSelectedNote[1][curEventSelected][0] = eventStuff[selectedEvent][0];
				}
				updateGrid();
			}
		});
		blockPressWhileScrolling.push(eventDropDown);

		var text:FlxText = new FlxText(20, 90, 0, "Value 1:");
		tab_group_event.add(text);

		value1InputText = new FlxUIInputText(20, 110, 100);
		blockPressWhileTypingOn.push(value1InputText);

		var text:FlxText = new FlxText(20, 130, 0, "Value 2:");
		tab_group_event.add(text);

		value2InputText = new FlxUIInputText(20, 150, 100);
		blockPressWhileTypingOn.push(value2InputText);

		// New event buttons
		var removeButton:FlxButton = new FlxButton(eventDropDown.x + eventDropDown.width + 10, eventDropDown.y, '-', function()
		{
			if (curSelectedNote != null && curSelectedNote[2] == null) // Is event note
			{
				if (curSelectedNote[1].length < 2)
				{
					if (_song.events != null)
						_song.events.remove(curSelectedNote);
					curSelectedNote = null;
				}
				else
				{
					curSelectedNote[1].remove(curSelectedNote[1][curEventSelected]);
				}

				var eventsGroup:Array<Dynamic>;
				curEventSelected--;
				if (curEventSelected < 0)
					curEventSelected = 0;
				else if (curSelectedNote != null && curEventSelected >= (eventsGroup = curSelectedNote[1]).length)
					curEventSelected = eventsGroup.length - 1;

				changeEventSelected();
				updateGrid();
			}
		});

		removeButton.setGraphicSize(Std.int(removeButton.height), Std.int(removeButton.height));
		removeButton.updateHitbox();

		removeButton.color = FlxColor.RED;

		removeButton.label.color = FlxColor.WHITE;
		removeButton.label.size = 12;

		setAllLabelsOffset(removeButton, -30, 0);
		tab_group_event.add(removeButton);

		var addButton:FlxButton = new FlxButton(removeButton.x + removeButton.width + 10, removeButton.y, '+', function()
		{
			if (curSelectedNote != null && curSelectedNote[2] == null) // Is event note
			{
				var eventsGroup:Array<Dynamic> = curSelectedNote[1];
				eventsGroup.push(['', '', '']);

				changeEventSelected(1);
				updateGrid();
			}
		});

		addButton.setGraphicSize(Std.int(removeButton.width), Std.int(removeButton.height));
		addButton.updateHitbox();

		addButton.color = FlxColor.GREEN;
		addButton.label.color = FlxColor.WHITE;

		addButton.label.size = 12;
		setAllLabelsOffset(addButton, -30, 0);
		tab_group_event.add(addButton);

		var moveLeftButton:FlxButton = new FlxButton(addButton.x + addButton.width + 20, addButton.y, '<', function()
		{
			changeEventSelected(-1);
		});

		moveLeftButton.setGraphicSize(Std.int(addButton.width), Std.int(addButton.height));
		moveLeftButton.updateHitbox();

		moveLeftButton.label.size = 12;
		setAllLabelsOffset(moveLeftButton, -30, 0);
		tab_group_event.add(moveLeftButton);

		var moveRightButton:FlxButton = new FlxButton(moveLeftButton.x + moveLeftButton.width + 10, moveLeftButton.y, '>', function()
		{
			changeEventSelected(1);
		});

		moveRightButton.setGraphicSize(Std.int(moveLeftButton.width), Std.int(moveLeftButton.height));
		moveRightButton.updateHitbox();

		moveRightButton.label.size = 12;
		setAllLabelsOffset(moveRightButton, -30, 0);
		tab_group_event.add(moveRightButton);

		selectedEventText = new FlxText(addButton.x - 100, addButton.y + addButton.height + 6, (moveRightButton.x - addButton.x) + 186,
			'Selected Event: None');
		selectedEventText.alignment = CENTER;

		tab_group_event.add(selectedEventText);
		tab_group_event.add(descText);

		tab_group_event.add(value1InputText);
		tab_group_event.add(value2InputText);

		tab_group_event.add(eventDropDown);
		UI_box.addGroup(tab_group_event);
	}

	private inline function changeEventSelected(change:Int = 0)
	{
		if (curSelectedNote != null && curSelectedNote[2] == null) // Is event note
		{
			curEventSelected = CoolUtil.repeat(curEventSelected, change, Std.int(curSelectedNote[1].length));
			selectedEventText.text = 'Selected Event: ' + (curEventSelected + 1) + ' / ' + curSelectedNote[1].length;
		}
		else
		{
			curEventSelected = 0;
			selectedEventText.text = 'Selected Event: None';
		}
		updateNoteUI();
	}

	private inline function setAllLabelsOffset(button:FlxButton, x:Float, y:Float)
	{
		for (point in button.labelOffsets)
			point.set(x, y);
	}

	var metronome:FlxUICheckBox;
	var metronomeStepper:FlxUINumericStepper;
	var metronomeOffsetStepper:FlxUINumericStepper;

	var mouseScrollingQuant:FlxUICheckBox;
	var disableAutoScrolling:FlxUICheckBox;
	#if desktop
	var waveformUseInstrumental:FlxUICheckBox;
	var waveformUseVoices:FlxUICheckBox;
	#end
	var instVolume:FlxUINumericStepper;
	var voicesVolume:FlxUINumericStepper;

	private function addChartingUI()
	{
		var tab_group_chart:FlxUI = new FlxUI(null, UI_box);
		tab_group_chart.name = 'Charting';
		#if desktop
		waveformUseInstrumental = new FlxUICheckBox(10, 90, null, null, "Waveform for Instrumental", 100);
		waveformUseInstrumental.callback = function()
		{
			ClientPrefs.prefs.set('chart_waveformVoices', waveformUseVoices.checked = false);
			ClientPrefs.prefs.set('chart_waveformInst', waveformUseInstrumental.checked);

			ClientPrefs.saveSettings();
			updateWaveform();
		};
		waveformUseInstrumental.checked = ClientPrefs.getPref('chart_waveformInst', false);

		waveformUseVoices = new FlxUICheckBox(waveformUseInstrumental.x + 120, waveformUseInstrumental.y, null, null, "Waveform for Voices", 100);
		waveformUseVoices.callback = function()
		{
			ClientPrefs.prefs.set('chart_waveformInst', waveformUseInstrumental.checked = false);
			ClientPrefs.prefs.set('chart_waveformVoices', waveformUseVoices.checked);

			ClientPrefs.saveSettings();
			updateWaveform();
		};

		waveformUseVoices.checked = ClientPrefs.getPref('chart_waveformVoices', false);
		#end

		check_mute_inst = new FlxUICheckBox(10, 310, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.callback = function()
		{
			FlxG.sound.music.volume = CoolUtil.int(!check_mute_inst.checked);
		};
		check_mute_inst.checked = false;

		mouseScrollingQuant = new FlxUICheckBox(10, 200, null, null, "Mouse Scrolling Quantization", 100);
		mouseScrollingQuant.callback = function()
		{
			ClientPrefs.prefs.set('mouseScrollingQuant', mouseQuant = mouseScrollingQuant.checked);
			ClientPrefs.saveSettings();
		};
		mouseQuant = mouseScrollingQuant.checked = ClientPrefs.getPref('mouseScrollingQuant', false);

		check_vortex = new FlxUICheckBox(10, 160, null, null, "Vortex Editor (BETA)", 100);
		check_vortex.callback = function()
		{
			ClientPrefs.prefs.set('chart_vortex', vortex = check_vortex.checked);
			ClientPrefs.saveSettings();

			reloadGridLayer();
		};

		check_vortex.checked = ClientPrefs.getPref('chart_vortex', false);

		check_warnings = new FlxUICheckBox(10, 120, null, null, "Ignore Progress Warnings", 100);
		check_warnings.callback = function()
		{
			ClientPrefs.getPref('ignoreWarnings', ignoreWarnings = check_warnings.checked);
		};
		check_warnings.checked = ClientPrefs.getPref('ignoreWarnings', false);

		var check_mute_vocals = new FlxUICheckBox(check_mute_inst.x + 120, check_mute_inst.y, null, null, "Mute Vocals (in editor)", 100);
		check_mute_vocals.callback = function()
		{
			if (vocals != null)
			{
				var vol:Float = 1;

				if (check_mute_vocals.checked)
					vol = 0;
				vocals.volume = vol;
			}
		};

		check_mute_vocals.checked = false;
		playSoundBf = new FlxUICheckBox(check_mute_inst.x, check_mute_vocals.y + 30, null, null, 'Play Sound (Boyfriend notes)', 100, function()
		{
			ClientPrefs.prefs.set('chart_playSoundBf', playSoundBf.checked);
			ClientPrefs.saveSettings();
		});

		playSoundBf.checked = ClientPrefs.getPref('chart_playSoundBf', false);
		playSoundDad = new FlxUICheckBox(check_mute_inst.x + 120, playSoundBf.y, null, null, 'Play Sound (Opponent notes)', 100, function()
		{
			ClientPrefs.prefs.set('chart_playSoundDad', playSoundDad.checked);
			ClientPrefs.saveSettings();
		});

		playSoundDad.checked = ClientPrefs.getPref('chart_playSoundDad', false);
		metronome = new FlxUICheckBox(10, 15, null, null, "Metronome Enabled", 100, function()
		{
			ClientPrefs.prefs.set('chart_metronome', metronome.checked);
			ClientPrefs.saveSettings();
		});

		metronome.checked = ClientPrefs.getPref('chart_metronome', false);

		metronomeStepper = new FlxUINumericStepper(15, 55, 5, _song.bpm, 1, 1500, 1);
		metronomeOffsetStepper = new FlxUINumericStepper(metronomeStepper.x + 100, metronomeStepper.y, 25, 0, 0, 1000, 1);

		blockPressWhileTypingOnStepper.push(metronomeStepper);
		blockPressWhileTypingOnStepper.push(metronomeOffsetStepper);

		disableAutoScrolling = new FlxUICheckBox(metronome.x + 120, metronome.y, null, null, "Disable Autoscroll (Not Recommended)", 120, function()
		{
			ClientPrefs.prefs.set('chart_noAutoScroll', disableAutoScrolling.checked);
			ClientPrefs.saveSettings();
		});

		disableAutoScrolling.checked = ClientPrefs.getPref('chart_noAutoScroll', false);
		instVolume = new FlxUINumericStepper(metronomeStepper.x, 270, .1, 1, 0, 1, 1);

		instVolume.value = FlxG.sound.music.volume;
		instVolume.name = 'inst_volume';

		blockPressWhileTypingOnStepper.push(instVolume);
		voicesVolume = new FlxUINumericStepper(instVolume.x + 100, instVolume.y, .1, 1, 0, 1, 1);

		voicesVolume.value = vocals.volume;
		voicesVolume.name = 'voices_volume';

		blockPressWhileTypingOnStepper.push(voicesVolume);

		tab_group_chart.add(new FlxText(metronomeStepper.x, metronomeStepper.y - 15, 0, 'BPM:'));
		tab_group_chart.add(new FlxText(metronomeOffsetStepper.x, metronomeOffsetStepper.y - 15, 0, 'Offset (ms):'));

		tab_group_chart.add(new FlxText(instVolume.x, instVolume.y - 15, 0, 'Inst Volume'));
		tab_group_chart.add(new FlxText(voicesVolume.x, voicesVolume.y - 15, 0, 'Voices Volume'));

		tab_group_chart.add(metronome);
		tab_group_chart.add(disableAutoScrolling);

		tab_group_chart.add(metronomeStepper);
		tab_group_chart.add(metronomeOffsetStepper);
		#if desktop
		tab_group_chart.add(waveformUseInstrumental);
		tab_group_chart.add(waveformUseVoices);
		#end
		tab_group_chart.add(instVolume);
		tab_group_chart.add(voicesVolume);

		tab_group_chart.add(check_mute_inst);
		tab_group_chart.add(check_mute_vocals);

		tab_group_chart.add(check_vortex);

		tab_group_chart.add(mouseScrollingQuant);
		tab_group_chart.add(check_warnings);

		tab_group_chart.add(playSoundBf);
		tab_group_chart.add(playSoundDad);

		UI_box.addGroup(tab_group_chart);
	}

	private function loadSong():Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		var file:Dynamic = Paths.voices(currentSongName);
		vocals = new FlxSound();

		if (file != null && (Std.isOfType(file, Sound) || OpenFlAssets.exists(file)))
			vocals.loadEmbedded(file);
		FlxG.sound.list.add(vocals);

		generateSong();

		FlxG.sound.music.pause();
		Conductor.songPosition = sectionStartTime();
		FlxG.sound.music.time = Conductor.songPosition;
	}

	private function generateSong()
	{
		var file:Dynamic = Paths.inst(currentSongName);

		if (file != null && (Std.isOfType(file, Sound) || OpenFlAssets.exists(file)))
		{
			FlxG.sound.playMusic(file, .6);
		}
		else
		{
			FlxG.sound.music = new FlxSound().play();
		}

		if (instVolume != null)
			FlxG.sound.music.volume = instVolume.value;
		if (check_mute_inst != null && check_mute_inst.checked)
			FlxG.sound.music.volume = 0;

		FlxG.sound.music.onComplete = function()
		{
			FlxG.sound.music.pause();
			Conductor.songPosition = 0;

			if (vocals != null)
			{
				vocals.pause();
				vocals.time = 0;
			}

			changeSection();
			curSec = 0;

			updateGrid();
			updateSectionUI();

			vocals.play();
		};
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast(sender, FlxUICheckBox);
			var label = check.getLabel().text;

			switch (Paths.formatToSongPath(label))
			{
				case 'must-hit-section':
					{
						_song.notes[curSec].mustHitSection = check.checked;

						updateGrid();
						updateHeads();
					}
				case 'gf-section':
					{
						_song.notes[curSec].gfSection = check.checked;

						updateGrid();
						updateHeads();
					}
				case 'change-bpm':
					{
						_song.notes[curSec].changeBPM = check.checked;
						trace('changed bpm shit');
					}
				case "alt-animation":
					_song.notes[curSec].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);

			switch (wname)
			{
				case 'note_susLength':
					{
						if (curSelectedNote != null && curSelectedNote[1] > -1)
						{
							curSelectedNote[2] = nums.value;
							updateGrid();
						}
						else
						{
							sender.value = 0;
						}
					}
				case 'section_beats':
					{
						_song.notes[curSec].sectionBeats = nums.value;
						updateGrid();
					}
				case 'song_bpm':
					{
						tempBpm = nums.value;

						Conductor.mapBPMChanges(_song);
						Conductor.changeBPM(nums.value);
					}

				case 'inst_volume':
					FlxG.sound.music.volume = nums.value;
				case 'voices_volume':
					vocals.volume = nums.value;

				case 'song_speed':
					_song.speed = nums.value;
				case 'section_bpm':
					{
						_song.notes[curSec].bpm = nums.value;
						updateGrid();
					}
			}
		}
		else if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == noteSplashesInputText)
			{
				var text:String = noteSplashesInputText.text;

				if (text.length > 0)
				{
					_song.splashSkin = text;
				}
				else if (_song.splashSkin != null)
				{
					_song.splashSkin = null;
				}
			}
			else if (curSelectedNote != null)
			{
				// this prevents a crash involving placing an event and then a note but still writing values to the event
				var keepYourselfSafe:Bool = curSelectedNote[1] != null && curSelectedNote[1][curEventSelected] != null;
				if (keepYourselfSafe && sender == value1InputText)
				{
					curSelectedNote[1][curEventSelected][1] = value1InputText.text;
					updateGrid();
				}
				else if (keepYourselfSafe && sender == value2InputText)
				{
					curSelectedNote[1][curEventSelected][2] = value2InputText.text;
					updateGrid();
				}
				else if (sender == strumTimeInputText)
				{
					var value:Float = Std.parseFloat(strumTimeInputText.text);
					if (Math.isNaN(value))
						value = 0;
					curSelectedNote[0] = value;
					updateGrid();
				}
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	private function sectionStartTime(add:Int = 0):Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSec + add)
		{
			if (_song.notes[i] != null)
			{
				if (_song.notes[i].changeBPM)
				{
					daBPM = _song.notes[i].bpm;
				}
				daPos += getSectionBeats(i) * (1000 * 60 / daBPM);
			}
		}
		return daPos;
	}

	var lastConductorPos:Float;
	var colorSine:Float = 0;

	override function update(elapsed:Float)
	{
		curStep = recalculateSteps();
		if (FlxG.sound.music.time < 0)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if (FlxG.sound.music.time > FlxG.sound.music.length)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;

			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;

		_song.song = UI_songTitle.text;
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrochet * getSectionBeats() * 4));

		for (i in 0...8)
			strumLineNotes.members[i].y = strumLine.y;

		FlxG.mouse.visible = true; // cause reasons. trust me
		camPos.y = strumLine.y;
		if (!disableAutoScrolling.checked)
		{
			if (Math.ceil(strumLine.y) >= gridBG.height)
			{
				// trace(curStep);
				// trace((_song.notes[curSec].lengthInSteps) * (curSec + 1));
				// trace('DUMBSHIT');
				if (_song.notes[curSec + 1] == null)
					addSection();

				changeSection(curSec + 1, false);
			}
			else if (strumLine.y < -10)
			{
				changeSection(curSec - 1, false);
			}
		}
		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
		{
			dummyArrow.visible = true;
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
			{
				var gridmult = GRID_SIZE / (quantization / 16);
				dummyArrow.y = Math.floor(FlxG.mouse.y / gridmult) * gridmult;
			}
		}
		else
		{
			dummyArrow.visible = false;
		}
		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEachAlive(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.CONTROL)
						{
							selectNote(note);
						}
						else if (FlxG.keys.pressed.ALT)
						{
							selectNote(note);
							curSelectedNote[3] = noteTypeIntMap.get(currentType);
							updateGrid();
						}
						else
						{
							trace('tryin to delete note...');
							deleteNote(note);
						}
					}
				});
			}
			else if (FlxG.mouse.x > gridBG.x
				&& FlxG.mouse.x < gridBG.x + gridBG.width
				&& FlxG.mouse.y > gridBG.y
				&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
			{
				trace('added note');
				addNote();
			}
		}

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				CoolUtil.toggleVolumeKeys(false);
				blockInput = true;
				break;
			}
		}

		if (!blockInput)
		{
			for (stepper in blockPressWhileTypingOnStepper)
			{
				@:privateAccess
				var leText:Dynamic = stepper.text_field;
				var leText:FlxUIInputText = leText;

				if (leText.hasFocus)
				{
					CoolUtil.toggleVolumeKeys(false);
					blockInput = true;
					break;
				}
			}
		}

		if (!blockInput)
		{
			CoolUtil.toggleVolumeKeys(true);
			for (dropDownMenu in blockPressWhileScrolling)
			{
				if (dropDownMenu.dropPanel.visible)
				{
					blockInput = true;
					break;
				}
			}
		}

		if (!blockInput)
		{
			if (FlxG.keys.justPressed.ENTER)
			{
				autosaveSong();
				persistentUpdate = FlxG.mouse.visible = false;

				PlayState.SONG = _song;
				FlxG.sound.music.stop();

				if (vocals != null)
					vocals.stop();

				StageData.loadDirectory(_song);
				LoadingState.loadAndSwitchState(new PlayState());
			}

			if (curSelectedNote != null && curSelectedNote[1] > -1)
			{
				var delta:Int = CoolUtil.delta(FlxG.keys.justPressed.E, FlxG.keys.justPressed.Q);
				if (delta != 0)
					changeNoteSustain(delta * Conductor.stepCrochet);
			}
			if (FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.ESCAPE)
			{
				autosaveSong();

				persistentUpdate = false;
				FlxG.mouse.visible = false;

				PlayState.chartingMode = false;
				PlayState.mechanicsEnabled = ClientPrefs.getPref('mechanics');
				// if (onMasterEditor) {
				MusicBeatState.switchState(new #if debug MasterEditorMenu #else MainMenuState #end());
				TitleState.playTitleMusic();
			}

			if (FlxG.keys.justPressed.Z && FlxG.keys.pressed.CONTROL)
			{
				undo();
			}

			if (FlxG.keys.justPressed.Z && curZoom > 0 && !FlxG.keys.pressed.CONTROL)
			{
				curZoom--;
				updateZoom();
			}
			if (FlxG.keys.justPressed.X && curZoom < zoomList.length - 1)
			{
				curZoom++;
				updateZoom();
			}

			if (FlxG.keys.justPressed.TAB)
			{
				if (FlxG.keys.pressed.SHIFT)
				{
					UI_box.selected_tab -= 1;
					if (UI_box.selected_tab < 0)
						UI_box.selected_tab = 2;
				}
				else
				{
					UI_box.selected_tab += 1;
					if (UI_box.selected_tab >= 3)
						UI_box.selected_tab = 0;
				}
			}

			if (FlxG.keys.justPressed.SPACE)
			{
				if (FlxG.sound.music.playing)
				{
					FlxG.sound.music.pause();
					if (vocals != null)
						vocals.pause();
				}
				else
				{
					if (vocals != null)
					{
						vocals.pause();
						vocals.play(true, FlxG.sound.music.time);
					}
					FlxG.sound.music.play();
				}
			}

			if (FlxG.keys.justPressed.R)
				resetSection(FlxG.keys.pressed.SHIFT);
			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.music.pause();
				if (!mouseQuant)
				{
					FlxG.sound.music.time -= FlxG.mouse.wheel * Conductor.stepCrochet * .8;
				}
				else
				{
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;

					var increase:Float = 1 / snap;
					var increaseMult:Float = increase * (FlxG.mouse.wheel > 0 ? -1 : 1);

					var fuck:Float = CoolUtil.quantize(beat, snap) + increaseMult;
					FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
				}
				if (vocals != null)
				{
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
				}
			}
			// ARROW VORTEX SHIT NO DEADASS
			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				FlxG.sound.music.pause();

				var holdingShift:Float = 1;
				if (FlxG.keys.pressed.CONTROL)
					holdingShift = .25;
				else if (FlxG.keys.pressed.SHIFT)
					holdingShift = 4;

				var daTime:Float = 700 * FlxG.elapsed * holdingShift;

				if (FlxG.keys.pressed.W)
					FlxG.sound.music.time -= daTime;
				else
					FlxG.sound.music.time += daTime;

				if (vocals != null)
				{
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
				}
			}
			if (!vortex && FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
			{
				FlxG.sound.music.pause();
				updateCurStep();

				var beat:Float = curDecBeat;

				var snap:Float = quantization / 4;
				var increase:Float = 1 / snap;

				var fuck:Float = CoolUtil.quantize(beat, snap) + (increase * (CoolUtil.delta(FlxG.keys.justPressed.DOWN, FlxG.keys.justPressed.UP)));
				FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
			}

			var style = currentType;
			if (FlxG.keys.pressed.SHIFT)
				style = 3;

			var conductorTime = Conductor.songPosition; // + sectionStartTime();Conductor.songPosition / Conductor.stepCrochet;
			// AWW YOU MADE IT SEXY <3333 THX SHADMAR
			if (!blockInput)
			{
				curQuant = CoolUtil.repeat(curQuant, CoolUtil.delta(FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.LEFT), quantizations.length);

				quantization = quantizations[curQuant];
				quant.animation.play('q', true, false, curQuant);

				if (vortex)
				{
					var controlArray:Array<Bool> = [
						 FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR,
						FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX, FlxG.keys.justPressed.SEVEN, FlxG.keys.justPressed.EIGHT
					];

					if (controlArray.contains(true))
					{
						for (i in 0...controlArray.length)
						{
							if (controlArray[i])
								doANoteThing(conductorTime, i, style);
						}
					}

					var feces:Float;
					if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
					{
						FlxG.sound.music.pause();
						updateCurStep();

						var beat:Float = curDecBeat;

						var snap:Float = quantization / 4;
						var increase:Float = 1 / snap;

						var fuck:Float = CoolUtil.quantize(beat, snap) + (increase * (CoolUtil.delta(FlxG.keys.justPressed.DOWN, FlxG.keys.justPressed.UP)));
						feces = Conductor.beatToSeconds(fuck);

						FlxTween.tween(FlxG.sound.music, {time: feces}, .1, {ease: FlxEase.circOut});
						if (vocals != null)
						{
							vocals.pause();
							vocals.time = FlxG.sound.music.time;
						}

						var secStart:Float = sectionStartTime();
						var daTime:Float = (feces
							- secStart)
							- ((curSelectedNote != null ? curSelectedNote[0] : 0) - secStart); // idk math find out why it doesn't work on any other section other than 0

						if (curSelectedNote != null)
						{
							var controlArray:Array<Bool> = [
								 FlxG.keys.pressed.ONE, FlxG.keys.pressed.TWO, FlxG.keys.pressed.THREE, FlxG.keys.pressed.FOUR,
								FlxG.keys.pressed.FIVE, FlxG.keys.pressed.SIX, FlxG.keys.pressed.SEVEN, FlxG.keys.pressed.EIGHT
							];

							if (controlArray.contains(true))
							{
								for (i in 0...controlArray.length)
								{
									if (controlArray[i])
										if (curSelectedNote[1] == i)
											curSelectedNote[2] += daTime - curSelectedNote[2] - Conductor.stepCrochet;
								}
								updateGrid();
								updateNoteUI();
							}
						}
					}
				}
			}
			var shiftThing:Int = 1;
			if (FlxG.keys.pressed.SHIFT)
				shiftThing = 4;

			if (FlxG.keys.justPressed.D)
				changeSection(curSec + shiftThing);
			if (FlxG.keys.justPressed.A)
			{
				if (curSec <= 0)
				{
					changeSection(_song.notes.length - 1);
				}
				else
				{
					changeSection(curSec - shiftThing);
				}
			}
		}
		else if (FlxG.keys.justPressed.ENTER)
		{
			for (i in 0...blockPressWhileTypingOn.length)
			{
				if (blockPressWhileTypingOn[i].hasFocus)
				{
					blockPressWhileTypingOn[i].hasFocus = false;
				}
			}
		}

		_song.bpm = tempBpm;
		strumLineNotes.visible = quant.visible = vortex;

		if (FlxG.sound.music.time < 0)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if (FlxG.sound.music.time > FlxG.sound.music.length)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;

			changeSection();
		}

		Conductor.songPosition = FlxG.sound.music.time;
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrochet * getSectionBeats() * 4));
		camPos.y = strumLine.y;
		for (i in 0...8)
		{
			strumLineNotes.members[i].y = strumLine.y;
			strumLineNotes.members[i].alpha = FlxG.sound.music.playing ? 1 : .35;
		}

		var roundedPos:Float = FlxMath.roundDecimal(Conductor.songPosition / 1000, 2);
		var roundedLength:Float = FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2);
		var roundedBeat:Float = FlxMath.roundDecimal(curDecBeat, 2);

		bpmTxt.text = '$roundedPos / $roundedLength\nSection: $curSec\n\nBeat: $roundedBeat\n\nStep: $curStep\n\nBeat Snap: $quantization th';

		var playedSound:Array<Bool> = [false, false, false, false]; // Prevents ouchy GF sex sounds
		curRenderedNotes.forEachAlive(function(note:Note)
		{
			note.alpha = 1;
			if (curSelectedNote != null)
			{
				var noteDataToCheck:Int = note.noteData;
				if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection)
					noteDataToCheck += 4;

				if (curSelectedNote[0] == note.strumTime
					&& ((curSelectedNote[2] == null && noteDataToCheck < 0)
						|| (curSelectedNote[2] != null && curSelectedNote[1] == noteDataToCheck)))
				{
					colorSine += elapsed;
					var colorVal:Float = .7 + Math.sin(Math.PI * colorSine) * .3;
					note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal,
						.9); // Alpha can't be 100% or the color won't be updated for some reason, guess i will die
				}
			}

			if (note.strumTime <= Conductor.songPosition)
			{
				note.alpha = .4;
				if (note.strumTime > lastConductorPos && FlxG.sound.music.playing && note.noteData > -1)
				{
					var data:Int = note.noteData % 4;
					var noteDataToCheck:Int = note.noteData;

					if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection)
						noteDataToCheck += 4;

					strumLineNotes.members[noteDataToCheck].playAnim('confirm', true);
					strumLineNotes.members[noteDataToCheck].resetAnim = (note.sustainLength / 1000) + .15;

					if (!playedSound[data])
					{
						if ((playSoundBf.checked && note.mustPress) || (playSoundDad.checked && !note.mustPress))
						{
							var hitsound:Null<FlxSound> = Hitsound.play();
							if (hitsound != null)
								hitsound.pan = note.noteData < 4 ? -.6 : .6; // would be coolio
							playedSound[data] = true;
						}

						data = note.noteData;
						if (note.mustPress != _song.notes[curSec].mustHitSection)
							data += 4;
					}
				}
			}
		});

		if (metronome.checked && lastConductorPos != Conductor.songPosition)
		{
			var metroInterval:Float = 60 / metronomeStepper.value;

			var metroStep:Int = Math.floor(((Conductor.songPosition + metronomeOffsetStepper.value) / metroInterval) / 1000);
			var lastMetroStep:Int = Math.floor(((lastConductorPos + metronomeOffsetStepper.value) / metroInterval) / 1000);

			if (metroStep != lastMetroStep)
				FlxG.sound.play(Paths.sound('Metronome_Tick'));
		}
		lastConductorPos = Conductor.songPosition;
		super.update(elapsed);
	}

	private inline function updateZoom()
	{
		var daZoom:Float = zoomList[curZoom];

		var roundedZoom:Int = Math.round(1 / daZoom);
		var zoomThing:String = (daZoom < 1) ? '$roundedZoom / 1' : '1 / $daZoom';

		zoomTxt.text = 'Zoom: $zoomThing';
		reloadGridLayer();
	}

	var lastSecBeats:Float = 0;
	var lastSecBeatsNext:Float = 0;

	private inline function reloadGridLayer()
	{
		if (gridBG != null)
		{
			gridBG.kill();
			gridLayer.remove(gridBG, true);

			remove(gridBG, true);

			gridBG.destroy();
			gridBG = null;
		}
		if (nextGridBG != null)
		{
			nextGridBG.kill();
			gridLayer.remove(nextGridBG, true);

			remove(nextGridBG, true);

			nextGridBG.destroy();
			nextGridBG = null;
		}
		clearAllShit(gridLayer);
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 9, Std.int(GRID_SIZE * getSectionBeats() * 4 * zoomList[curZoom]), true, 0xFF090909,
			0xFF2A2A2A);

		#if desktop
		if (ClientPrefs.getPref('chart_waveformInst') || ClientPrefs.getPref('chart_waveformVoices'))
			updateWaveform();
		#end

		var leHeight:Int = Std.int(gridBG.height);
		var foundNextSec:Bool = false;

		if (sectionStartTime(1) <= FlxG.sound.music.length)
		{
			nextGridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 9, Std.int(GRID_SIZE * getSectionBeats(curSec + 1) * 4 * zoomList[curZoom]),
				0xFF090909, 0xFF2A2A2A);
			leHeight = Std.int(gridBG.height + nextGridBG.height);
			foundNextSec = true;
		}
		else
		{
			nextGridBG = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		}
		nextGridBG.y = gridBG.height;

		gridLayer.add(nextGridBG);
		gridLayer.add(gridBG);

		if (foundNextSec)
		{
			var gridBlack:FlxSprite = new FlxSprite(0, gridBG.height).makeGraphic(Std.int(GRID_SIZE * 9), Std.int(nextGridBG.height), FlxColor.BLACK);

			gridBlack.alpha = .4;
			gridLayer.add(gridBlack);
		}

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width - (GRID_SIZE * 4)).makeGraphic(2, leHeight, FlxColor.GRAY);
		gridLayer.add(gridBlackLine);
		if (waveformSprite != null)
			insert(members.indexOf(waveformSprite) + 1, gridBlackLine);

		if (vortex)
		{
			for (i in 1...4)
				gridLayer.add(new FlxSprite(gridBG.x, (GRID_SIZE * (4 * curZoom)) * i).makeGraphic(Std.int(gridBG.width), 1, 0x44FF0000));
		}

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + GRID_SIZE).makeGraphic(2, leHeight, FlxColor.GRAY);
		gridLayer.add(gridBlackLine);

		updateGrid();
	}

	var waveformPrinted:Bool = true;
	var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];

	private function updateWaveform()
	{
		#if desktop
		if (waveformPrinted)
		{
			waveformSprite.makeGraphic(Std.int(GRID_SIZE * 8), Std.int(gridBG.height), FlxColor.TRANSPARENT);
			waveformSprite.pixels.fillRect(new Rectangle(0, 0, gridBG.width, gridBG.height), FlxColor.TRANSPARENT);
		}
		waveformPrinted = false;
		if (!ClientPrefs.getPref('chart_waveformInst') && !ClientPrefs.getPref('chart_waveformVoices'))
		{
			// trace('Epic fail on the waveform lol');
			return;
		}

		wavData[0][0] = [];
		wavData[0][1] = [];
		wavData[1][0] = [];
		wavData[1][1] = [];

		var steps:Int = Math.round(getSectionBeats() * 4);

		var st:Float = sectionStartTime();
		var et:Float = st + (Conductor.stepCrochet * steps);

		if (ClientPrefs.getPref('chart_waveformInst'))
		{
			var sound:FlxSound = FlxG.sound.music;
			if (sound._sound != null && sound._sound.__buffer != null)
			{
				var bytes:Bytes = sound._sound.__buffer.data.toBytes();

				wavData = getWaveformData(sound._sound.__buffer, bytes, st, et, 1, wavData, Std.int(gridBG.height));
			}
		}

		if (ClientPrefs.getPref('chart_waveformVoices'))
		{
			var sound:FlxSound = vocals;
			if (sound._sound != null && sound._sound.__buffer != null)
			{
				var bytes:Bytes = sound._sound.__buffer.data.toBytes();

				wavData = getWaveformData(sound._sound.__buffer, bytes, st, et, 1, wavData, Std.int(gridBG.height));
			}
		}

		// Draws
		var gSize:Int = Std.int(GRID_SIZE * 8);
		var hSize:Int = Std.int(gSize / 2);

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var size:Float = 1;

		var leftLength:Int = (wavData[0][0].length > wavData[0][1].length ? wavData[0][0].length : wavData[0][1].length);
		var rightLength:Int = (wavData[1][0].length > wavData[1][1].length ? wavData[1][0].length : wavData[1][1].length);

		var length:Int = leftLength > rightLength ? leftLength : rightLength;
		var index:Int;

		for (i in 0...length)
		{
			index = i;

			lmin = FlxMath.bound(((index < wavData[0][0].length && index >= 0) ? wavData[0][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			lmax = FlxMath.bound(((index < wavData[0][1].length && index >= 0) ? wavData[0][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			rmin = FlxMath.bound(((index < wavData[1][0].length && index >= 0) ? wavData[1][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			rmax = FlxMath.bound(((index < wavData[1][1].length && index >= 0) ? wavData[1][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			waveformSprite.pixels.fillRect(new Rectangle(hSize - (lmin + rmin), i * size, (lmin + rmin) + (lmax + rmax), size), FlxColor.BLUE);
		}
		waveformPrinted = true;
		#end
	}

	/*
		[
			[[min...], [max...]], left
			[[min...], [max...]] right
		]
	 */
	private inline function getWaveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>,
			?steps:Float):Array<Array<Array<Float>>>
	{
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null)
			return [[[0], [0]], [[0], [0]]];

		var khz:Float = (buffer.sampleRate / 1000);
		var channels:Int = buffer.channels;

		var index:Int = Std.int(time * khz);

		var samples:Float = ((endTime - time) * khz);

		if (steps == null)
			steps = 1280;

		var samplesPerRow:Float = samples / steps;
		var samplesPerRowI:Int = Std.int(samplesPerRow);

		var gotIndex:Int = 0;

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var rows:Float = 0;

		var simpleSample:Bool = true; // samples > 17200;
		var v1:Bool = false;

		if (array == null)
			array = [[[0], [0]], [[0], [0]]];

		while (index < (bytes.length - 1))
		{
			if (index >= 0)
			{
				var byte:Int = bytes.getUInt16(index * channels * 2);

				if (byte > 65535 / 2)
					byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0)
				{
					if (sample > lmax)
						lmax = sample;
				}
				else if (sample < 0)
				{
					if (sample < lmin)
						lmin = sample;
				}

				if (channels >= 2)
				{
					byte = bytes.getUInt16((index * channels * 2) + 2);

					if (byte > 65535 / 2)
						byte -= 65535;

					sample = (byte / 65535);

					if (sample > 0)
					{
						if (sample > rmax)
							rmax = sample;
					}
					else if (sample < 0)
					{
						if (sample < rmin)
							rmin = sample;
					}
				}
			}

			v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
			while (simpleSample ? v1 : rows >= samplesPerRow)
			{
				v1 = false;
				rows -= samplesPerRow;

				gotIndex++;

				var lRMin:Float = Math.abs(lmin) * multiply;
				var lRMax:Float = lmax * multiply;

				var rRMin:Float = Math.abs(rmin) * multiply;
				var rRMax:Float = rmax * multiply;

				if (gotIndex > array[0][0].length)
					array[0][0].push(lRMin);
				else
					array[0][0][gotIndex - 1] = array[0][0][gotIndex - 1] + lRMin;

				if (gotIndex > array[0][1].length)
					array[0][1].push(lRMax);
				else
					array[0][1][gotIndex - 1] = array[0][1][gotIndex - 1] + lRMax;

				if (channels >= 2)
				{
					if (gotIndex > array[1][0].length)
						array[1][0].push(rRMin);
					else
						array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + rRMin;

					if (gotIndex > array[1][1].length)
						array[1][1].push(rRMax);
					else
						array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + rRMax;
				}
				else
				{
					if (gotIndex > array[1][0].length)
						array[1][0].push(lRMin);
					else
						array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin;

					if (gotIndex > array[1][1].length)
						array[1][1].push(lRMax);
					else
						array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + lRMax;
				}

				lmin = 0;
				lmax = 0;

				rmin = 0;
				rmax = 0;
			}

			index++;
			rows++;
			if (gotIndex > steps)
				break;
		}

		return array;
		#else
		return [[[0], [0]], [[0], [0]]];
		#end
	}

	private inline function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	private inline function recalculateSteps(add:Float = 0):Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime + add) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	private inline function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSec = 0;
		}

		if (vocals != null)
		{
			vocals.pause();
			vocals.time = FlxG.sound.music.time;
		}

		updateCurStep();
		updateGrid();

		updateSectionUI();
		updateWaveform();
	}

	private inline function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		trace('changing section $sec');
		if (_song.notes[sec] != null)
		{
			curSec = sec;
			if (updateMusic)
			{
				FlxG.sound.music.pause();
				FlxG.sound.music.time = sectionStartTime();

				if (vocals != null)
				{
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
				}
				updateCurStep();
			}
			if (getSectionBeats() != lastSecBeats
				|| (sectionStartTime(1) > FlxG.sound.music.length ? 0 : getSectionBeats(curSec + 1)) != lastSecBeatsNext)
			{
				reloadGridLayer();
			}
			else
			{
				updateGrid();
			}
			updateSectionUI();
		}
		else
		{
			changeSection();
		}

		Conductor.songPosition = FlxG.sound.music.time;
		updateWaveform();
	}

	private inline function updateSectionUI():Void
	{
		var sec = _song.notes[curSec];

		stepperBeats.value = getSectionBeats();
		check_mustHitSection.checked = sec.mustHitSection;

		check_gfSection.checked = sec.gfSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;

		stepperSectionBPM.value = sec.bpm;
		updateHeads();
	}

	private inline function updateHeads():Void
	{
		var section:SwagSection = _song.notes[curSec];

		var healthIconP1:String = loadHealthIconFromCharacter(_song.player1);
		var healthIconP2:String = if (section.gfSection) 'gf' else loadHealthIconFromCharacter(_song.player2);

		var mustHit:Bool = section.mustHitSection;
		var mustHitInt:Int = CoolUtil.int(mustHit) * 100;

		rightIcon.changeIcon(if (mustHit) healthIconP2 else healthIconP1);
		leftIcon.changeIcon(if (mustHit) healthIconP1 else healthIconP2);

		rightIcon.setFrameOnPercentage(100 - mustHitInt);
		leftIcon.setFrameOnPercentage(mustHitInt);

		rightIcon.setGraphicSize(0, 45);
		leftIcon.setGraphicSize(0, 45);

		rightIcon.updateHitbox();
		leftIcon.updateHitbox();

		rightIcon.setPosition(GRID_SIZE * 5, -100);
		leftIcon.setPosition(GRID_SIZE, -100);
	}

	private inline function loadHealthIconFromCharacter(char:String)
	{
		var characterPath:String = 'characters/$char.json';

		var defaultshit:String = Character.DEFAULT_CHARACTER;
		var path:String = Paths.getPreloadPath(characterPath);

		if (!OpenFlAssets.exists(path))
			path = Paths.getPreloadPath('characters/$defaultshit.json'); // If a character couldn't be found, change it to the default just to prevent a crash

		var rawJson = OpenFlAssets.getText(path);
		var json:CharacterFile = cast Json.parse(rawJson);

		return json.healthicon;
	}

	private inline function updateNoteUI():Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				stepperSusLength.value = curSelectedNote[2];
				if (curSelectedNote[3] != null)
				{
					currentType = noteTypeMap.get(curSelectedNote[3]);
					if (currentType <= 0)
					{
						noteTypeDropDown.selectedLabel = '';
					}
					else
					{
						noteTypeDropDown.selectedLabel = currentType + '. ' + curSelectedNote[3];
					}
				}
			}
			else
			{
				eventDropDown.selectedLabel = curSelectedNote[1][curEventSelected][0];
				var selected:Int = Std.parseInt(eventDropDown.selectedId);
				if (selected > 0 && selected < eventStuff.length)
				{
					descText.text = eventStuff[selected][1];
				}
				value1InputText.text = curSelectedNote[1][curEventSelected][1];
				value2InputText.text = curSelectedNote[1][curEventSelected][2];
			}
			strumTimeInputText.text = Std.string(curSelectedNote[0]);
		}
	}

	private inline function clearAllShit(rendered:FlxTypedGroup<Dynamic>):Void
	{
		for (thing in rendered.members)
		{
			thing.kill();
			rendered.remove(thing, true);

			remove(thing, true);

			thing.destroy();
			thing = null;
		}
		rendered.clear();
	}

	private inline function updateGrid():Void
	{
		clearAllShit(curRenderedNotes);
		clearAllShit(curRenderedSustains);
		clearAllShit(curRenderedNoteType);

		clearAllShit(nextRenderedNotes);
		clearAllShit(nextRenderedSustains);

		if (_song.notes[curSec].changeBPM && _song.notes[curSec].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[curSec].bpm);
			// trace('BPM of this section:');
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSec)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}
		// CURRENT SECTION
		// this isnt unused but thanks haxe
		var beatsCurrent:Float = getSectionBeats();
		for (i in _song.notes[curSec].sectionNotes)
		{
			var note:Note = setupNoteData(i, false);
			curRenderedNotes.add(note);

			if (note.sustainLength > 0)
				curRenderedSustains.add(setupSusNote(note, beatsCurrent));
			if (i[3] != null && note.noteType != null && note.noteType.length > 0)
			{
				var typeInt:Null<Int> = noteTypeMap.get(i[3]);
				var theType:String = typeInt == null ? '?' : Std.string(typeInt);

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 100, theType, 24);

				daText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				daText.xAdd = -32;
				daText.yAdd = 6;

				daText.borderSize = 1;

				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}
			note.mustPress = _song.notes[curSec].mustHitSection;
			if (i[1] > 3)
				note.mustPress = !note.mustPress;
		}

		// CURRENT EVENTS
		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);

		if (_song.events != null)
		{
			for (i in _song.events)
			{
				if (endThing > i[0] && i[0] >= startThing)
				{
					var note:Note = setupNoteData(i, false);
					curRenderedNotes.add(note);

					var strumTime:Int = Math.floor(note.strumTime);

					var eventVal1:String = note.eventVal1;
					var eventVal2:String = note.eventVal2;

					var eventName:String = note.eventName;
					var eventLength:Int = note.eventLength;

					var text:String = eventLength > 1 ? '$eventLength Events:\n$eventName' : 'Event: $eventName ($strumTime) ms\nValue 1: $eventVal1\nValue 2: $eventVal2';
					var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text, 12);

					daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
					daText.xAdd = -410;

					daText.borderSize = 1;
					if (note.eventLength > 1)
						daText.yAdd += 8;

					curRenderedNoteType.add(daText);
					daText.sprTracker = note;
					// trace('test: ' + i[0], 'startThing: ' + startThing, 'endThing: ' + endThing);
				}
			}
		}
		// NEXT SECTION
		var beatsNext:Float = getSectionBeats(1);
		if (curSec < _song.notes.length - 1)
		{
			for (i in _song.notes[curSec + 1].sectionNotes)
			{
				var note:Note = setupNoteData(i, true);

				note.alpha = .6;
				nextRenderedNotes.add(note);

				if (note.sustainLength > 0)
					nextRenderedSustains.add(setupSusNote(note, beatsNext));
			}
		}
		// NEXT EVENTS
		var startThing:Float = sectionStartTime(1);
		var endThing:Float = sectionStartTime(2);

		if (_song.events != null)
		{
			for (i in _song.events)
			{
				if (endThing > i[0] && i[0] >= startThing)
				{
					var note:Note = setupNoteData(i, true);

					note.alpha = .6;
					nextRenderedNotes.add(note);
				}
			}
		}
	}

	private inline function setupNoteData(i:Array<Dynamic>, isNextSection:Bool):Note
	{
		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var daSus:Dynamic = i[2];

		var note:Note = new Note(daStrumTime, daNoteInfo % 4, null, null, true);
		if (daSus != null)
		{
			// Common note
			if (!Std.isOfType(i[3], String)) // Convert old note type to new note type format
				i[3] = noteTypeIntMap.get(i[3]);
			if (i.length > 3 && (i[3] == null || i[3].length < 1))
				i.remove(i[3]);

			note.sustainLength = daSus;
			note.noteType = i[3];
		}
		else
		{
			// Event note
			note.loadGraphic(Paths.image('eventArrow'));

			note.eventName = getEventName(i[1]);
			note.eventLength = i[1].length;

			if (i[1].length < 2)
			{
				note.eventVal1 = i[1][0][1];
				note.eventVal2 = i[1][0][2];
			}

			note.noteData = -1;
			daNoteInfo = -1;
		}

		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = Math.floor(daNoteInfo * GRID_SIZE) + GRID_SIZE;
		if (isNextSection && _song.notes[curSec].mustHitSection != _song.notes[curSec + 1].mustHitSection)
		{
			if (daNoteInfo > 3)
			{
				note.x -= GRID_SIZE * 4;
			}
			else if (daSus != null)
			{
				note.x += GRID_SIZE * 4;
			}
		}

		var beats:Float = getSectionBeats(isNextSection ? 1 : 0);
		note.y = getYfromStrumNotes(daStrumTime - sectionStartTime(), beats);
		// if(isNextSection) note.y += gridBG.height;
		if (note.y < -150)
			note.y = -150;
		return note;
	}

	private inline function getEventName(names:Array<Dynamic>):String
	{
		var retStr:String = '';
		var addedOne:Bool = false;
		for (i in 0...names.length)
		{
			if (addedOne)
				retStr += ', ';
			retStr += names[i][0];
			addedOne = true;
		}
		return retStr;
	}

	private inline function setupSusNote(note:Note, beats:Float):FlxSprite
	{
		var height:Int = Math.floor(FlxMath.remapToRange(note.sustainLength, 0, Conductor.stepCrochet * 16, 0, GRID_SIZE * 16 * zoomList[curZoom])
			+ (GRID_SIZE * zoomList[curZoom])
			- GRID_SIZE / 2);
		var minHeight:Int = Std.int((GRID_SIZE * zoomList[curZoom] / 2) + GRID_SIZE / 2);

		if (height < minHeight)
			height = minHeight;
		if (height < 1)
			height = 1; // Prevents error of invalid height

		var spr:FlxSprite = new FlxSprite(note.x + (GRID_SIZE * .5) - 4, note.y + GRID_SIZE / 2).makeGraphic(8, height);
		return spr;
	}

	private inline function getYfromStrumNotes(strumTime:Float, beats:Float):Float
		return GRID_SIZE * beats * 4 * zoomList[curZoom] * (strumTime / (beats * 4 * Conductor.stepCrochet)) + gridBG.y;

	private inline function addSection(sectionBeats:Float = 4):Void
	{
		var sec:SwagSection = {
			sectionBeats: sectionBeats,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			gfSection: false,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false
		};

		_song.notes.push(sec);
	}

	private inline function selectNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;
		if (noteDataToCheck > -1)
		{
			if (note.mustPress != _song.notes[curSec].mustHitSection)
				noteDataToCheck += 4;
			for (i in _song.notes[curSec].sectionNotes)
			{
				if (i != curSelectedNote && i.length > 2 && i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					curSelectedNote = i;
					break;
				}
			}
		}
		else if (_song.events != null)
		{
			for (i in _song.events)
			{
				if (i != curSelectedNote && i[0] == note.strumTime)
				{
					curSelectedNote = i;
					curEventSelected = Std.int(curSelectedNote[1].length) - 1;
					changeEventSelected();
					break;
				}
			}
		}

		updateGrid();
		updateNoteUI();
	}

	private inline function deleteNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;
		if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection)
			noteDataToCheck += 4;

		if (note.noteData > -1) // Normal Notes
		{
			for (i in _song.notes[curSec].sectionNotes)
			{
				if (i == note || (i[0] == note.strumTime && i[1] == noteDataToCheck))
				{
					if (i == curSelectedNote)
						curSelectedNote = null;
					trace('FOUND EVIL NOTE');
					_song.notes[curSec].sectionNotes.remove(i);
					// break; (another day of thanking god for removing this break)
				}
			}
		}
		else if (_song.events != null) // Events
		{
			for (i in _song.events)
			{
				if (i == note || i[0] == note.strumTime)
				{
					if (i == curSelectedNote)
					{
						curSelectedNote = null;
						changeEventSelected();
					}
					// FlxG.log.add('FOUND EVIL EVENT');
					_song.events.remove(i);
					// break;
				}
			}
		}
		updateGrid();
	}

	public inline function doANoteThing(cs, d, style)
	{
		var delnote = false;
		if (strumLineNotes.members[d].overlaps(curRenderedNotes))
		{
			curRenderedNotes.forEachAlive(function(note:Note)
			{
				if (note.overlapsPoint(new FlxPoint(strumLineNotes.members[d].x + 1, strumLine.y + 1)) && note.noteData == d % 4)
				{
					// trace('tryin to delete note...');
					if (!delnote)
						deleteNote(note);
					delnote = true;
				}
			});
		}

		if (!delnote)
		{
			addNote(cs, d, style);
		}
	}

	private inline function addNote(strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null):Void
	{
		// curUndoIndex++;
		// var newsong = _song.notes;
		//	undos.push(newsong);
		trace(undos);

		var noteStrum:Float = getStrumTime(dummyArrow.y, false) + sectionStartTime();
		var noteData:Int = Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE);
		var noteSus:Float = 0;

		var daType:Int = currentType;

		if (strum != null)
			noteStrum = strum;
		if (data != null)
			noteData = data;

		if (type != null)
			daType = type;
		if (noteData > -1)
		{
			_song.notes[curSec].sectionNotes.push([noteStrum, noteData, noteSus, noteTypeIntMap.get(daType)]);
			curSelectedNote = _song.notes[curSec].sectionNotes[_song.notes[curSec].sectionNotes.length - 1];
		}
		else
		{
			var event = eventStuff[Std.parseInt(eventDropDown.selectedId)][0];
			var text1 = value1InputText.text;
			var text2 = value2InputText.text;

			if (_song.events == null)
				_song.events = [];
			_song.events.push([noteStrum, [[event, text1, text2]]]);

			curSelectedNote = _song.events[_song.events.length - 1];
			curEventSelected = 0;

			changeEventSelected();
		}

		if (FlxG.keys.pressed.CONTROL && noteData > -1)
		{
			for (i in _song.notes[curSec].sectionNotes)
			{
				if (i[0] == noteStrum && i[1] == (noteData + 4))
				{
					if (i == curSelectedNote)
						curSelectedNote = null;
					trace('FOUND EVIL NOTE');
					_song.notes[curSec].sectionNotes.remove(i);
					// break; (another day of thanking god for removing this break)
				}
			}
			_song.notes[curSec].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus, noteTypeIntMap.get(daType)]);
		}

		// trace(noteData + ', ' + noteStrum + ', ' + curSec);
		strumTimeInputText.text = curSelectedNote[0];

		updateGrid();
		updateNoteUI();
	}

	// will figure this out l8r
	private inline function redo()
	{
		// _song = redos[curRedoIndex];
	}

	private inline function undo()
	{
		// redos.push(_song);
		undos.pop();
		// _song.notes = undos[undos.length - 1];
		///trace(_song.notes);
		// updateGrid();
	}

	private inline function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if (!doZoomCalc)
			leZoom = 1;
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height * leZoom, 0, 16 * Conductor.stepCrochet);
	}

	private inline function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if (!doZoomCalc)
			leZoom = 1;
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height * leZoom);
	}

	private inline function loadJson(song:String):Void
	{
		// make it look sexier if possible
		var diffSelected:String = CoolUtil.difficulties[PlayState.storyDifficulty];
		var formattedSong:String = Paths.formatToSongPath(song);

		if (diffSelected != null && CoolUtil.difficulties.length > 0)
		{
			// PlayState.SONG = Song.loadFromJson('$formattedSong-$diffSelected', formattedSong);
			PlayState.SONG = Song.loadFromJson(diffSelected, formattedSong);
		}
		else
		{
			var split:Array<String> = formattedSong.split('-');
			var last:String = split[split.length - 1];

			var path:String = formattedSong;
			for (diff in CoolUtil.defaultDifficulties)
			{
				if (Paths.formatToSongPath(diff) == last)
				{
					path = formattedSong.substring(0, formattedSong.length - last.length - 1);
					diffSelected = diff;

					break;
				}
			}
			PlayState.SONG = Song.loadFromJson(diffSelected, path);
		}
		MusicBeatState.resetState();
	}

	private inline function autosaveSong():Void
	{
		ClientPrefs.prefs.set('autosave', Json.stringify({
			"song": _song
		}));
		ClientPrefs.saveSettings();
	}

	private inline function clearEvents()
	{
		if (_song.events != null)
		{
			var len:Int = _song.events.length;
			_song.events = null;

			if (len > 0)
				updateGrid();
		}
	}

	private function saveSong()
	{
		if (_song.events != null && _song.events.length > 1)
			_song.events.sort(sortByTime);
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json, "\t");
		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();

			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);

			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), Paths.formatToSongPath(_song.song) + ".json");
		}
	}

	private inline function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		if (Obj1 == null || Obj1[0] == null)
			return Obj2[0];
		if (Obj2 == null || Obj2[0] == null)
			return Obj1[0];

		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	private function saveEvents()
	{
		if (_song.events == null || _song.events.length <= 0)
			return;
		if (_song.events != null && _song.events.length > 1)
			_song.events.sort(sortByTime);

		var eventsSong:Dynamic = {
			events: _song.events
		};
		var json = {
			"song": eventsSong
		}

		var data:String = Json.stringify(json, "\t");
		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), "events.json");
		}
	}

	private inline function getSectionBeats(?section:Null<Int> = null):Float
		return _song?.notes[section ?? curSec]?.sectionBeats ?? 4.;

	private function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);

		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;

		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	private function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);

		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	private function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);

		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;

		FlxG.log.error("Problem saving Level data");
	}
}
