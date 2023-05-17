package states;

import flixel.math.FlxAngle;
import meta.instances.FoursomeFrame;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.display.BitmapData;
import meta.instances.ComboRating;
import openfl.utils.Dictionary;
import openfl.filters.ShaderFilter;
import shaders.CRTDistortionShader.CRTDistortionEffect;
import shaders.ChromaticAberrationShader.ChromaticAberrationEffect;
import meta.instances.bars.Healthbar;
import meta.instances.bars.Timebar;
import openfl.display.Application;
import openfl.media.Sound;
import meta.PlayerSettings;
import meta.Controls.Control;
import flixel.input.FlxInput.FlxInputState;
import haxe.ds.Map;
import states.substates.PauseSubState;
import meta.Hitsound;
import meta.CoolUtil;
import flixel.util.FlxGradient;
import lime.ui.Window;
import openfl.Lib;
import meta.Achievements.Achievement;
import states.freeplay.FreeplayState;
import shaders.Shaders.GlitchEffect;
import shaders.ColorSwap;
import meta.instances.notes.Note;
import meta.instances.BGSprite;
import meta.instances.notes.StrumNote;
import meta.instances.Character;
import meta.instances.notes.NoteSplash;
import meta.instances.DialogueBox;
import meta.instances.notes.Note.EventNote;
import meta.instances.HealthIcon;
import meta.instances.GoofyCountdown;
import meta.instances.badminton.*;
import meta.instances.stages.*;
import states.substates.GameOverSubstate;
import meta.data.Highscore;
import meta.data.WeekData;
import meta.data.Song;
import states.substates.JumpscareSubstate;
import meta.data.Song.SwagSection;
import meta.data.Song.SwagSong;
import meta.data.ClientPrefs;
import meta.Conductor;
import meta.data.StageData;
import meta.Conductor.Rating;
import states.editors.CharacterEditorState;
import states.editors.ChartingState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.transition.FlxTransitionableState;
import flixel.animation.FlxAnimation;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.KeyboardEvent;
import openfl.utils.Assets as OpenFlAssets;
import meta.Discord.DiscordClient;

using StringTools;
using flixel.util.FlxSpriteUtil;

#if sys
import sys.FileSystem;
#end
#if VIDEOS_ALLOWED
import hxcodec.flixel.VideoHandler;
import hxcodec.flixel.VideoSprite;
#end

class PlayState extends MusicBeatState
{
	// CONSTANTS
	public inline static final GAME_BOP:Float = .015;
	public inline static final HUD_BOP:Float = .03;

	public inline static final SKIP_PADDING:Float = 10;
	public inline static final SKIP_SIZE:Int = 32;

	private inline static final ICON_SCALE:Int = 150;
	public inline static final MAX_HEALTH:Float = 2;

	public inline static final MIDDLESCROLL_OPPONENT_TRANSPARENCY:Float = .35;
	public inline static final MIDDLESCROLL_PADDING:Int = 16;

	public inline static final LOSING_PERCENT:Float = 20;

	private static var defaultCameraOffset:Array<Float> = [0, 0];
	private static var defaultScrollFactor:Array<Float> = [1, 1];

	// EVENTS
	#if VIDEOS_ALLOWED
	public var modchartVideos:Array<VideoSprite> = new Array();
	#end
	public var modchartTweens:Array<FlxTween> = new Array();
	public var modchartTimers:Array<FlxTimer> = new Array();

	public var strumlineTweens:Array<Dynamic> = new Array();
	public var stageGroup:FlxTypedGroup<BaseStage> = new FlxTypedGroup();

	public var stages:Array<Array<Dynamic>> = new Array();
	public var stageUpdates:Array<Dynamic> = new Array();

	#if VIDEOS_ALLOWED
	public var videos:Array<VideoSprite> = new Array();
	#end
	public var trail:FlxTrail;
	// MECHANICS
	public static var mechanicsEnabled:Bool = ClientPrefs.getPref('mechanics');
	// [ divide by, minimum difficulty ]
	private static var healthDrainMap:Map<String, Dynamic> = [
		'pyromania' => [1.5, 0],
		'roided' => [2, 0],
		'killgames' => [1.4, 0],
		'relapse' => [1.35, 0],
		'opposition' => [1, 0]
	];

	public var totalShitsFailed:Int = 0;
	public var shitsFailedLol:Int = 0;

	// ROIDED
	private var roid:Bool = false;
	// FUNNY DUO
	private var goofyAww:FlxTypedGroup<GoofyCountdown>;

	private var noddingCamera:Bool = false;
	private var nodRight:Bool = false;

	// FOURSOME
	private static var foursomeLightColors:Array<FlxColor> = [0xFF52FFF3, 0xFF58FFA3, 0xFFFF5FFA, 0xFFFF4A39];
	private var eggbobFocused:Bool = false;

	private var foursomeFrameType:Int = -1;
	private var foursomeFrame:FoursomeFrame;
	// RELAPSE
	private var crazyShitMode:Bool = false;
	private var noteGearShift:Int = 0;

	private var crtDistortionTwn:FlxTween;
	private var aberrationTwn:FlxTween;

	private static var relapseFaces:Array<String> = [':)', ':]', ':(', ':[', '[:', '(:', ']:', '):', ':D', 'D:'];

	// FOOLISH
	private var pizza:FlxSprite;

	// QICO
	public inline static final shootChance:Float = (1 / 3) * 100;

	private var shootHealthCap:Float = 1 / 20;
	private var shootSound:FlxSound;
	// KILLGAMES
	private var evilFocused:Bool = false;

	// SCORE
	public static var ratingsData:Array<Rating>;
	private static var defaultRatingStuff:Array<Dynamic> = [
		['horse dog phase 2', .2], // From 0% to 19%
		['horse dog', .4], // From 20% to 39%
		['kill yourself', .5], // From 40% to 49%
		['am busy', .6], // From 50% to 59%
		['fuck yo u', .7], // From 60% to 69%
		['Goog', .8], // From 70% to 79%
		['grangt', .9], // From 80% to 89%
		['Funny!', 1], // From 90% to 99%
		['standing ovation', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];
	private static var ratingStuffMap:Map<String, Array<Dynamic>> = [
		'relapse' => [
			['TERRIBLE', .2], // From 0% to 19%
			['BAD', .5], // From 40% to 49%
			['OK', .8], // From 70% to 79%
			['GOOD', .9], // From 80% to 89%
			[':]', 1] // The value on this one isn't used actually, since Perfect is always "1"
		],
		'killgames' => [
			['Killed Games', .2], // From 0% to 19%
			['Games Killed', .5], // From 40% to 49%
			['Zero Games', .8], // From 70% to 79%
			['Squid Game?', 1] // The value on this one isn't used actually, since Perfect is always "1"
		]
	];

	private var ratingName:String = '?';

	private var ratingPercent:Float;
	private var ratingFC:String;

	private var songScore:Int = 0;
	private var songHits:Int = 0;
	private var songMisses:Int = 0;

	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	private var combo:Int = 0;

	private var horsedogs:Int = 0;
	private var funnies:Int = 0;
	private var googs:Int = 0;
	private var bads:Int = 0;

	// CAMPAIGN
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;

	public static var storyMisses:Map<String, Int> = [];
	public static var storyPlaylist:Array<String>;

	public static var storyDifficulty:Int = 1;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;

	// CHARACTERS
	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;

	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;

	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var DUO_X:Float = -350;
	public var DUO_Y:Float = 125;

	public var TRIO_Y:Float = -50;
	public var TRIO_X:Float = 125;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public var girlfriendCameraOffset:Array<Float> = null;
	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;

	public var girlfriendScrollFactor:Array<Float> = null;
	public var boyfriendScrollFactor:Array<Float> = null;
	public var opponentScrollFactor:Array<Float> = null;

	public var boyfriend:Character;
	public var dad:Character;
	public var gf:Character;
	// in bend hard: bendy
	public var trioOpponent:Character;
	// in bend hard: sans
	public var duoOpponent:Character;

	// NOTES
	private var noteKillOffset:Float = Note.noteWidth * 2;

	private var totalPlayed:Int = 0;
	private var totalNotesHit:Float = 0;

	private var notes:FlxTypedGroup<Note>;

	private var unspawnNotes:Array<Note> = [];
	private var eventNotes:Array<EventNote> = [];

	private var noteTypeMap:Map<String, Bool> = new Map();
	private var eventPushedMap:Map<String, Bool> = new Map();

	private var strumNoteTweens:Dictionary<StrumNote, FlxTween> = new Dictionary();
	private var strumLine:FlxSprite;

	private var strumLineNotes:FlxTypedGroup<StrumNote>;
	private var opponentStrums:FlxTypedGroup<StrumNote>;

	private var playerStrums:FlxTypedGroup<StrumNote>;

	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	private var worldStrumLineNotes:FlxTypedGroup<StrumNote>;
	private var worldNotes:FlxTypedGroup<Note>;

	private var worldStrumLine:FlxSprite;

	public var secondOpponentStrums:FlxTypedGroup<StrumNote>;

	// CAMERA
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;

	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	private var defaultCamZoom:Float = 1.05;
	private var camZooming:Bool = false;

	private var gameZoomAdd:Float = 0;
	private var hudZoomAdd:Float = 0;

	private var gameZoom:Float = 1;
	private var hudZoom:Float = 1;

	// SONG
	private inline static final vocalResyncTime:Int = 20;
	public static var startOnTime:Float = 0;

	public static var SONG:SwagSong = null;

	public var curSong:String;

	private var spawnTime:Float = 2000;

	public var vocals:FlxSound;
	public var inst:FlxSound;

	private var songSpeedTween:FlxTween;

	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";

	private var songPercent:Float = 0;
	private var generatedMusic:Bool = false;

	public var startingSong:Bool = false;

	private var endingSong:Bool = false;

	private var lastStepHit:Int = -1;
	private var lastBeatHit:Int = -1;

	private var previousFrameTime:Int = 0;
	private var lastReportedPlayheadPosition:Int = 0;

	private var startPosition:Float = -5000;
	private var songTime:Float = 0;

	// STAGE
	public static var curStage:Dynamic;

	public var stageData:StageFile;

	// lol
	private var preloadedTrickyNotes:Bool = false;
	private var spawnAnim:FlxSprite;

	// opposition shit
	public var addTrail:Bool = false;

	private var circleTime:Float = 0;

	// ASSETS
	public static var introAssetsLibrary:String = null;

	public static var otherAssetsLibrary:String = null;
	public static var noteAssetsLibrary:String = null;

	public static var barsAssets:String = null;

	public static var introAssetsSuffix:String;
	private static var introAssets:Map<String, Array<String>> = [
		'compressed' => ['ready', 'set', 'go'],
		'fnm' => ['ready', 'set', 'go'],
		'default' => ['rady', 'set', 'kys']
	];
	private static var introSounds:Map<String, Array<String>> = [
		'default' => ['intro3', 'intro2', 'intro1', 'introGo'],
		'fnm' => ['fnm_intro1', 'fnm_intro2', 'fnm_intro3', 'fnm_introGo'],
		'kys' => ['kill', 'your', 'self', 'NOW']
	];
	// GAMEPLAY
	private inline static final healthDrainCap:Float = 1 / 2;
	private inline static final healthDrain:Float = 1 / 45;

	public var cpuControlled:Bool = false;
	public var health:Float = MAX_HEALTH / 2;

	private var healthGain:Float = 1;
	private var healthLoss:Float = 1;

	public var gfSpeed:Int = 1;

	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	// BOTPLAY
	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;
	// ICONS
	public var iconAlpha:Float = 1;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	private var iconP1OffsetFollow:FlxPoint;
	private var iconP2OffsetFollow:FlxPoint;

	private var iconP1Offset:FlxPoint;
	private var iconP2Offset:FlxPoint;

	// CAMERA
	public var camOther:FlxCamera;
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;

	private var cameraSpeed:Float = 1;

	private var camZoomTypeBeatOffset:Int = 0;
	private var camZoomType:Int = 0;

	private var camZoomTypes:Array<Array<Dynamic>>;
	private var isCameraOnForcedPos:Bool = false;

	private var camGameTwn:FlxTween;
	private var camHUDTwn:FlxTween;
	private var cameraTwn:FlxTween;

	private var cameraOffset:Float = 25;
	public var secondOpponentDelta:FlxPoint;

	private var opponentDelta:FlxPoint;
	private var playerDelta:FlxPoint;
	// DIALOGUE
	private var dialogueBoxShit:DialogueBox;

	private var dialogueJson:DialogueFile = null;
	private var dialogueCount:Int = 0;
	// TIMERS
	private var startTimer:FlxTimer;
	private var finishTimer:FlxTimer;

	// UI
	public var updateTime:Bool = true;

	private var showComboNum:Bool = true;
	private var showCombo:Bool = true;
	private var showRating:Bool = true;

	private var comboGroup:FlxTypedGroup<ComboRating>;

	private var skipArrowStartTween:Bool = false;
	private var transitioning = false;

	public var healthBar:Healthbar;
	public var timeBar:Timebar;

	private var opponentScrollUnderlay:FlxSprite;
	private var playerScrollUnderlay:FlxSprite;
	private var scoreTxt:FlxText;

	private var scoreTxtTween:FlxTween;
	private var subtitlesTwn:FlxTween;

	private static var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	private var inCutscene:Bool = false;
	private var skipCountdown:Bool = false;

	private var isDead:Bool = false;

	public var shaders:Array<Dynamic>;

	private var skipCutscene:FlxText;
	#if VIDEOS_ALLOWED
	private var video:VideoSprite;
	#end

	private var coverFade:FlxSprite;
	private var cameraCover:FlxSprite;

	private var hitsoundsPlayed:Array<Int>;
	private var songCover:FlxSprite;

	private var timerExtensions:Array<Float>;
	private var vignetteEnabled:Bool = false;

	private var vignetteImage:FlxSprite;
	private var vignetteTween:FlxTween;

	private var legalize:FlxSprite;
	private var subtitlesTxt:FlxText;

	public var gameShakeAmount:Float = 0;
	public var hudShakeAmount:Float = 0;

	public var maskedSongLength:Float = -1;
	public var songLength:Float = 0;

	private var horseImages:Array<FlxGraphic>;

	public var shitFlipped:Bool = false;

	private var yourStrumline:FlxSprite;
	// BADMINTON
	private var shuttlecockBeats:Float = 4;
	private var shuttlecock:Shuttlecock;

	private var hasPlayedShuttleAnimation:Bool = false;
	private var shuttleSkippedTime:Float = 0;

	private var shuttleSwingButton:FlxSprite;

	private var shuttleButtonColorSwap:ColorSwap;
	private var shuttleColorSwap:ColorSwap;

	private var shuttleEarlyDeadzone:Float = 10;
	private var shuttleLateDeadzone:Float = 10;

	private var shuttleMissAlpha:Float = 1.25;

	private var lastShuttleHit:Float = 0;
	private var newNextShuttleBeats:Array<Float>;

	private var shuttleStunnedFor:Float = 0;
	private var shuttleStunTime:Float = .4;

	private var shuttleHealth:Float = 1 / 1.5;
	private var destroyShuttleOnNextHit:Bool = false;

	// COUNTDOWN
	public static var introSoundPrefix:String;

	public static var introSoundKey:String;
	public static var introKey:String;

	private var countdownImage:FlxSprite;

	private static var ease:Dynamic = FlxEase.cubeInOut;
	public static var startDelay:Float = 0;

	private var startedCountdown:Bool = false;
	private var canPause:Bool = true;

	// FNM
	private static final FNM_PLAYER_COLOR:Array<Int> = [0, 0, 255];
	private static final FNM_ENEMY_COLOR:Array<Int> = [255, 0, 0];

	private inline static final FNM_ICON_BOP:Float = .5;

	public static var isFNM:Bool = false;
	private var fnmElapsed:Float = 0;

	private var storyDifficultyText:String;
	// Discord RPC variables
	private var detailsPausedText:String;
	private var detailsText:String;

	private var authorGroup:FlxSpriteGroup;

	// GENERAL
	public static var instance:PlayState;
	public static var focused:Bool = true;

	private var canReset:Bool = true;

	public var paused:Bool = false;

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	private var debugKeysFinish:Array<FlxKey>;
	private var debugKeysSkip:Array<FlxKey>;
	// Less laggy controls
	private var controlArray:Array<Control>;
	private var keysArray:Array<Dynamic>;

	private var strumsBlocked:Array<Bool> = [];

	// FUNCTIONS
	// OVERRIDE
	override public function create()
	{
		Paths.clearStoredMemory();
		instance = this;

		opponentDelta = new FlxPoint();
		playerDelta = new FlxPoint();

		shaders = new Array();

		camZoomType = 0;
		// [ On Beat (bool), Function ]
		camZoomTypes = [
			[
				true,
				function()
				{
					if ((curBeat + camZoomTypeBeatOffset) % 4 == 0)
					{
						gameZoomAdd += GAME_BOP;
						hudZoomAdd += HUD_BOP;
					}
				}
			],
			[
				true,
				function()
				{
					if ((curBeat + camZoomTypeBeatOffset) % 2 == 0)
					{
						gameZoomAdd += GAME_BOP;
						hudZoomAdd += HUD_BOP;
					}
				}
			],
			[
				true,
				function()
				{
					var multiplier:Float = switch (curSong)
					{
						case 'funny-foreplay':
							{
								if (curStage is Carnival)
									curStage.cartShaking = FlxG.random.float(18, 26) * ((FlxG.random.int(0, 1) * 2) - 1);
								if (!ClientPrefs.getPref('reducedMotion'))
								{
									camGame.shake(1 / 120, Conductor.stepCrochet / 375);
									camHUD.shake(1 / 240, Conductor.stepCrochet / 500);
								}
								// retun
								Math.PI / 2;
							}
						default:
							1;
					}

					gameZoomAdd += GAME_BOP * multiplier;
					hudZoomAdd += HUD_BOP * multiplier;
				}
			],
			[
				false,
				function()
				{
					var beatDiv:Dynamic = switch ((curStep + (camZoomTypeBeatOffset * 4)) % 32)
					{
						case 0 | 3 | 6 | 10 | 14 | 28:
							1;

						case 16 | 17 | 18 | 19 | 22 | 23 | 24 | 25 | 30:
							4;
						case 7 | 11 | 31:
							-3;

						default:
							false;
					};
					if (beatDiv != false)
					{
						gameZoomAdd += GAME_BOP / beatDiv;
						hudZoomAdd += HUD_BOP / beatDiv;
					}
				}
			],
			[
				false,
				function()
				{
					var beatDiv:Dynamic = switch ((curStep + (camZoomTypeBeatOffset * 4)) % 16)
					{
						case 0 | 2 | 4 | 6 | 8 | 10 | 12:
							1;

						case 1 | 3 | 5 | 7 | 9 | 11:
							-Math.PI / 2;
						case 13 | 14 | 15:
							-3;

						default:
							false;
					};
					if (beatDiv != false)
					{
						gameZoomAdd += GAME_BOP / beatDiv;
						hudZoomAdd += HUD_BOP / beatDiv;
					}
				}
			],
			[
				false,
				function()
				{
					var beatDiv:Dynamic = switch ((curStep + (camZoomTypeBeatOffset * 4)) % 32)
					{
						case 0 | 3 | 4 | 7 | 8 | 11 | 12 | 15 | 16 | 18 | 20 | 22 | 23 | 24 | 27 | 28 | 30 | 31:
							2;
						default:
							false;
					};
					if (beatDiv != false)
					{
						gameZoomAdd += GAME_BOP / beatDiv;
						hudZoomAdd += HUD_BOP / beatDiv;
					}
				}
			],
			[
				false,
				function()
				{
					var beatDiv:Dynamic = switch ((curStep + (camZoomTypeBeatOffset * 4)) % 64)
					{
						case 16 | 22 | 48 | 52 | 56 | 60:
							1;
						case 0 | 32:
							.7;

						default:
							false;
					}
					if (beatDiv != false)
					{
						gameZoomAdd += GAME_BOP / beatDiv;
						hudZoomAdd += HUD_BOP / beatDiv;
					}
				}
			],
			[
				true,
				function()
				{
					var doBump:Bool = switch ((curBeat + camZoomTypeBeatOffset) % 8)
					{
						case 0 | 2 | 4 | 5 | 7:
							true;
						default:
							false;
					};
					if (doBump)
					{
						gameZoomAdd += GAME_BOP;
						hudZoomAdd += HUD_BOP;
					}
				}
			]
		];

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));

		debugKeysFinish = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_3'));
		debugKeysSkip = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_4'));

		PauseSubState.songName = null; // Reset to default

		controlArray = [NOTE_LEFT, NOTE_DOWN, NOTE_UP, NOTE_RIGHT];
		keysArray = new Array();
		// bad way of caching but if it aint broke dont fix it
		for (control in controlArray)
		{
			for (mapping in ClientPrefs.keyBinds.iterator())
			{
				if (ClientPrefs.isControl(mapping) && mapping[1] == control)
				{
					keysArray.push(ClientPrefs.copyKey(mapping));
					break;
				}
			}
		}
		inst?.stop();
		// Gameplay settings
		healthGain = #if !debug isStoryMode ? 1 : #end
			ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = #if !debug isStoryMode ? 1 : #end
			ClientPrefs.getGameplaySetting('healthloss', 1);

		cpuControlled = #if !debug !isStoryMode && #end ClientPrefs.getGameplaySetting('botplay', false);

		var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');
		var hideHUD:Bool = ClientPrefs.getPref('hideHUD');

		var healthBarAlpha:Float = ClientPrefs.getPref('healthBarAlpha');
		var timeBarType:String = ClientPrefs.getPref('timeBarType');

		var middleScroll:Bool = ClientPrefs.getPref('middleScroll');
		var downScroll:Bool = ClientPrefs.getPref('downScroll');

		camGame = new FlxCamera();

		camHUD = new FlxCamera();
		camOther = new FlxCamera();

		camOther.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		grpNoteSplashes = new FlxTypedGroup(12);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		detailsText = isStoryMode ? ('Story Mode: ' + (WeekData.getCurrentWeek()?.data?.weekName ?? "?")) : "Freeplay";
		// String for when the game is paused
		detailsPausedText = 'Paused - $detailsText';
		curSong = Paths.formatToSongPath(SONG.song);

		startDelay = Conductor.crochet / 1000;

		boyfriendGroup = new FlxSpriteGroup(); // new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(); // new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(); // new FlxSpriteGroup(GF_X, GF_Y);

		comboGroup = new FlxTypedGroup<ComboRating>(ClientPrefs.getPref('comboStacking') ? 4 : 1);
		comboGroup.cameras = [camHUD];

		var stageName:String = SONG?.stage ?? StageData.getStage(curSong);
		var curStageClass:Dynamic = StageData.getStageClass(stageName);

		stageData = StageData.getStageFile(stageName);

		setupStageShit();
		cacheShitForSong(SONG);

		camGame.zoom = (defaultCamZoom = gameZoom = stageData.defaultZoom) + gameZoomAdd;
		add(stageGroup);

		add(gfGroup);
		add(dadGroup);
		add(boyfriendGroup);

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);

		dadGroup.add(dad);
		boyfriend = new Character(0, 0, SONG.player1, true);

		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);

		generateSong(SONG.song);

		CoolUtil.totalFuckingReset();
		Paths.setCurrentLevel(stageData?.directory ?? '');

		curStage = Type.createInstance(curStageClass, [instance]);
		curStage.active = false;

		curStage.onSongStart();
		checkForGirlfriend();

		stageGroup.add(curStage);
		curStage.onStageAdded();

		postStageShit();
		stageUpdates.push(curStage);

		var application:Application = Lib.application;
		var windowText:String = '?';

		var applicationWindow:Window = application.window;
		var meta:Map<String, String> = application.meta;

		if (meta != null && meta.exists('name'))
			windowText = meta.get('name');

		var authorPath:String = '$curSong/author.txt';
		var coverPath:String = 'covers/$curSong';

		if (Paths.fileExists('images/$coverPath.png', IMAGE) && !hideHUD)
		{
			songCover = new FlxSprite().loadGraphic(Paths.image(coverPath));
			songCover.antialiasing = globalAntialiasing;

			songCover.cameras = [camHUD];
			songCover.scrollFactor.set();

			songCover.alpha = 0;
			songCover.visible = false;
		}
		if (Paths.fileExists(authorPath, TEXT, 'songs'))
		{
			trace('path fooound');

			var authorList:String = CoolUtil.coolTextFile(Paths.getPath(authorPath, TEXT, 'songs')).join('\n');
			if (songCover == null && !hideHUD)
			{
				authorGroup = new FlxSpriteGroup();

				var authors:String = '$authorList - ' + SONG.song;
				var boxWidth:Int = Std.int(FlxG.width * .4);

				var authorPadding:Float = 8;
				var authorHeight:Int = 50;

				var iconSize:Int = Std.int((authorHeight - authorPadding) * .9);
				var authorText:FlxText = new FlxText(0, 0, boxWidth - iconSize - (authorPadding * 2),
					authors).setFormat(Paths.font('comic.ttf'), 24, FlxColor.WHITE, LEFT);

				authorText.updateHitbox();

				var authorBG:FlxSprite = new FlxSprite().makeGraphic(boxWidth, authorHeight + Std.int(authorText.height - authorText.size), FlxColor.BLACK);
				var authorIcon:FlxSprite = new FlxSprite().loadGraphic(Paths.image('song'));

				authorText.x = iconSize + (authorPadding * 2);

				authorIcon.setGraphicSize(iconSize, iconSize);
				authorIcon.updateHitbox();

				authorText.y = (authorBG.height - authorText.height) / 2;

				authorIcon.y = (authorBG.height - iconSize) / 2;
				authorIcon.x = authorPadding;

				authorIcon.antialiasing = globalAntialiasing;
				authorBG.antialiasing = false;

				authorIcon.alpha = .75;
				authorText.alpha = authorIcon.alpha;

				authorBG.alpha = .5;

				authorText.cameras = [camOther];
				authorBG.cameras = [camOther];

				authorGroup.cameras = [camOther];

				authorGroup.x = FlxG.width - authorBG.width;
				authorGroup.screenCenter(Y);

				authorGroup.y += authorBG.height;
				authorGroup.add(authorBG);

				authorGroup.add(authorIcon);
				authorGroup.add(authorText);
			}
			windowText += ' - $authorList';
		}
		if (applicationWindow != null)
		{
			var title:String = switch (curSong)
			{
				case 'relapse':
					'?';
				case 'killgames':
					'Ain\'t No Game.';

				default:
					{
						var txt:String = windowText + ' - ' + SONG.song;
						if (CoolUtil.difficulties.length > 1)
							txt += ' [ $storyDifficultyText ]';
						txt;
					}
			};
			applicationWindow.title = title;
		}
		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			if (gf != null)
				gf.visible = false;
		}

		var camPos:FlxPoint = new FlxPoint();
		if (gf != null)
		{
			var midpoint:FlxPoint = gf.getMidpoint();
			camPos.set(girlfriendCameraOffset[0]
				+ midpoint.x
				+ gf.cameraPosition[0], girlfriendCameraOffset[1]
				+ midpoint.y
				+ gf.cameraPosition[1]);
		}
		else
		{
			var midpoint:FlxPoint = dad.getMidpoint();
			camPos.set(opponentCameraOffset[0]
				+ midpoint.x
				+ 150
				+ dad.cameraPosition[0], opponentCameraOffset[1]
				+ midpoint.y
				- 100
				+ dad.cameraPosition[1]);
		}

		var file:String = Paths.json(curSong, 'dialogue', 'songs'); // Checks for json/Physics Engine dialogue
		if (OpenFlAssets.exists(file))
			dialogueJson = DialogueBox.parseDialogue(file);

		Conductor.songPosition = startPosition;
		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);

		if (mechanicsEnabled)
		{
			switch (curSong)
			{
				// Shuttleman songs
				// hotshot later lopl
				case 'hotshot':
					{
						shuttlecockBeats = switch (curSong)
						{
							// for faster shuttle ball slaps
							default:
								4;
						};
						shuttlecock = new Shuttlecock(dad, boyfriend);

						shuttleButtonColorSwap = new ColorSwap();
						shuttleColorSwap = new ColorSwap();

						shuttlecock.shader = shuttleColorSwap.shader;
						shuttlecock.cameras = [camGame];

						shuttlecock.offset.y = 100;
						shuttlecock.alpha = 0;

						shuttlecock.nextBeat = shuttlecockBeats;
						shuttlecock.curveAlpha = 0;

						newNextShuttleBeats = new Array();

						add(shuttlecock.splashes);
						add(shuttlecock.racquets);

						add(shuttlecock);
						if (!hideHUD)
						{
							shuttleSwingButton = new FlxSprite();
							shuttleSwingButton.frames = Paths.getSparrowAtlas('badminton/swing');

							shuttleSwingButton.cameras = [camHUD];
							shuttleSwingButton.scrollFactor.set();

							shuttleSwingButton.setGraphicSize(Std.int(shuttleSwingButton.width * .6));
							shuttleSwingButton.screenCenter(X);

							shuttleSwingButton.shader = shuttleButtonColorSwap.shader;
							shuttleSwingButton.antialiasing = false;

							shuttleSwingButton.offset.y = -40;
							shuttleSwingButton.alpha = 0;

							shuttleSwingButton.y = 100;
							if (!downScroll)
								shuttleSwingButton.y = FlxG.height - shuttleSwingButton.height - shuttleSwingButton.y;
							// 1-10 is IDLE!
							shuttleSwingButton.animation.addByIndices('press', 'spacebar', [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20], '', 24, false);
							shuttleSwingButton.animation.addByIndices('idle', 'spacebar', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], '', 24, true);

							shuttleSwingButton.animation.play('idle');
							add(shuttleSwingButton);
						}
					}
			}
		}
		if (secondOpponentStrums != null && curStage is Squidgame)
		{
			var pinkSoldier:Character = curStage.pinkSoldier;
			if (pinkSoldier != null)
			{
				worldStrumLine = new FlxSprite(pinkSoldier.x - 50, pinkSoldier.y - 100).makeGraphic(FlxG.width, 10);
				worldStrumLine.scrollFactor.set(1, 1);
			}

			worldStrumLineNotes = new FlxTypedGroup();
			worldStrumLineNotes.visible = ClientPrefs.getPref('opponentStrums');
		}
		if (downScroll)
			strumLine.y = FlxG.height - Note.noteWidth - 50;
		if (songCover != null)
		{
			songCover.x = Note.noteWidth / 2;
			songCover.y = songCover.height + strumLine.height + 16;
		}
		strumLine.scrollFactor.set();

		var scrollUnderlay:Float = ClientPrefs.getPref('scrollUnderlay', -1);
		if (scrollUnderlay > 0)
		{
			var underlayWidth:Int = (Note.noteWidth * 4) + MIDDLESCROLL_PADDING;
			var underlayHeight:Int = Math.ceil(FlxG.height / camHUD.zoom);

			playerScrollUnderlay = new FlxSprite().makeGraphic(underlayWidth, underlayHeight, FlxColor.BLACK);

			playerScrollUnderlay.alpha = scrollUnderlay;
			playerScrollUnderlay.scrollFactor.set();

			playerScrollUnderlay.cameras = [camHUD];
			switch (middleScroll)
			{
				case true:
					playerScrollUnderlay.screenCenter(X);
				default:
					{
						// 4.5 , 4 notes + half of width (centering)
						// i fixed this shit finally WOOHOO!!!! FREE MATH
						var underlayCenter:Float = ((Note.noteWidth * 4) - underlayWidth) / 2;
						playerScrollUnderlay.x = FlxG.width - (Note.noteWidth * 4.5) + underlayCenter;

						if (ClientPrefs.getPref('opponentStrums'))
						{
							opponentScrollUnderlay = new FlxSprite((Note.noteWidth / 2) + underlayCenter).makeGraphic(underlayWidth, underlayHeight,
								FlxColor.BLACK);

							opponentScrollUnderlay.alpha = scrollUnderlay;
							opponentScrollUnderlay.scrollFactor.set();

							opponentScrollUnderlay.cameras = [camHUD];
							add(opponentScrollUnderlay);
						}
					}
			}
			add(playerScrollUnderlay);
		}

		// yes...
		if (ClientPrefs.getPref('subtitles'))
		{
			subtitlesTxt = new FlxText(0, 0, FlxG.width, "", 32);
			subtitlesTxt.setFormat(Paths.font("comic.ttf"), subtitlesTxt.size, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.WHITE);

			subtitlesTxt.borderColor = FlxColor.BLACK;

			subtitlesTxt.bold = true;
			subtitlesTxt.scrollFactor.set();

			subtitlesTxt.borderSize = 2;
			subtitlesTxt.cameras = [camOther];
		}
		if (worldStrumLineNotes != null)
			add(worldStrumLineNotes);

		add(comboGroup);
		strumLineNotes = new FlxTypedGroup();

		add(strumLineNotes);
		add(grpNoteSplashes);

		notes = new FlxTypedGroup();
		if (worldStrumLineNotes != null)
		{
			worldNotes = new FlxTypedGroup();

			worldStrumLineNotes.cameras = worldNotes.cameras = [camGame];
			worldNotes.visible = ClientPrefs.getPref('opponentStrums');

			add(worldNotes);
		}
		add(notes);
		if (foursomeFrame != null)
			add(foursomeFrame);

		opponentStrums = new FlxTypedGroup();
		playerStrums = new FlxTypedGroup();

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		camGame.follow(camFollowPos, LOCKON, 1);
		camGame.focusOn(camFollow);

		gameZoomAdd = switch (curSong)
		{
			case 'murked-up':
				5 - defaultCamZoom;
			default:
				0;
		}
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		isCameraOnForcedPos = true;
		switch (curSong)
		{
			default:
				moveCameraSection();
			case 'expurgation':
				{
					moveCamera(true);
					snapCamFollowToPos(camFollow.x, camFollow.y);
				}
		}

		var showTime:Bool = !(timeBarType == 'disabled' || isFNM);
		if (showTime)
		{
			timeBar = new Timebar(barsAssets, ClientPrefs.getPref('flashing'), timeBarType, SONG);
			timeBar.antialiasing = globalAntialiasing;

			timeBar.cameras = [camHUD];
			timeBar.offset.y = (timeBar.height + timeBar.y) * (downScroll ? -1 : 1);

			add(timeBar);
		}
		if (!hideHUD)
		{
			var barY:Float = FlxG.height * (if (isFNM) (if (downScroll) .11 else .89) else (if (downScroll) .075 else .85));
			if (healthBarAlpha > 0)
			{
				healthBar = new Healthbar(if (isFNM) 'fnm' else barsAssets);

				healthBar.antialiasing = globalAntialiasing;
				healthBar.flipped = shitFlipped;
				// healthBar
				healthBar.alpha = healthBarAlpha;
				healthBar.cameras = [camHUD];

				iconP2 = new HealthIcon((if (shitFlipped) boyfriend else dad).healthIcon, false, isFNM);
				iconP1 = new HealthIcon((if (shitFlipped) dad else boyfriend).healthIcon, true, isFNM);

				iconP1.y = iconP2.y = healthBar.bar.y - 75;

				iconP1.alpha = iconP2.alpha = healthBarAlpha;
				iconP1.cameras = iconP2.cameras = [camHUD];

				iconP1Offset = new FlxPoint();
				iconP2Offset = new FlxPoint();

				iconP1OffsetFollow = new FlxPoint();
				iconP2OffsetFollow = new FlxPoint();

				reloadHealthBarColors();
				add(healthBar);

				add(iconP1);
				add(iconP2);
			}
			switch (isFNM)
			{
				default:
					{
						scoreTxt = new FlxText(0, barY + 45, FlxG.width);
						switch (Paths.formatToSongPath(barsAssets))
						{
							default:
								scoreTxt.setFormat(Paths.font("comic.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);

							case 'relapse':
								scoreTxt.setFormat(Paths.font("VINERITC.ttf"), 20, 0xFFF0E1F8, CENTER, OUTLINE, 0xFF6E7582);
							case 'killgames':
								scoreTxt.setFormat(Paths.font('squid.ttf'), 20, 0xFF410505, CENTER, OUTLINE, 0xFF940D0C);
						}
						scoreTxt.borderSize = 1.25;
					}
				case true:
					{
						scoreTxt = new FlxText(0, 0,
							healthBar?.bg?.width ?? cast(FlxG.width, Float)).setFormat(Paths.font('ariblk.ttf'), 18, FlxColor.WHITE,
								healthBar != null ? RIGHT : CENTER);
						if (healthBar != null)
						{
							scoreTxt.setPosition(healthBar.bg.x, healthBar.bg.y + healthBar.bg.height);
						}
						else
						{
							scoreTxt.screenCenter(X);
							scoreTxt.y = barY;
						}
						scoreTxt.y -= scoreTxt.size / 4;
					}
			}

			scoreTxt.scrollFactor.set();
			scoreTxt.cameras = [camHUD];

			add(scoreTxt);
		}

		botplayTxt = new FlxText(
			0,
			(timeBar?.bg?.y ?? 0.) + (if (downScroll) -120 else 30) + (if (middleScroll) 120 * (if (downScroll) -1 else 1) else 0),
			FlxG.width - 800,
			"this person\nis cheating"
		).setFormat(Paths.font("comic.ttf"), 32, 0xFFD6F4FF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF42CDFF);
		botplayTxt.scrollFactor.set();

		botplayTxt.visible = cpuControlled;
		botplayTxt.borderSize = 1.25;

		botplayTxt.updateHitbox();
		botplayTxt.screenCenter(X);

		botplayTxt.cameras = [camHUD];
		add(botplayTxt);

		if (authorGroup != null)
			add(authorGroup);
		grpNoteSplashes.cameras = [camHUD];

		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];

		startingSong = true;
		if (canPlayStoryCutscene() && !seenCutscene)
		{
			switch (curSong)
			{
				case 'gastric-bypass':
					startVideo('animation_gastric_bypass');
				case 'roided':
					startVideo('animation_roided');

				case 'pyromania':
					startVideo('animation_pyromania');

				case 'cervix':
					startVideo('animation_cervix');
				case 'funny-duo':
					startVideo('animation_funny_duo');
				case 'intestinal-failure':
					startVideo('animation_intestinal_failure');

				case 'murked-up':
					startVideo('animation_murked_up');
				case 'blamger':
					startVideo('animation_blamger');
				case 'qico':
					startVideo('animation_qico');

				case 'plot-armor':
					startVideo('animation_plot_armor');
				case 'funny-foreplay':
					startVideo('animation_funny_foreplay');
				case 'foursome':
					startVideo('animation_foursome');

				default:
					{
						if (dialogueJson != null)
						{
							startDialogue(dialogueJson);
						}
						else
						{
							startCountdown();
						}
					}
			}
			seenCutscene = true;
		}
		else
		{
			switch (curSong)
			{
				default:
					startCountdown();
				case 'expurgation':
					{
						spawnAnim = new FlxSprite(dad.x - DAD_X, dad.y - DAD_Y);

						var glitchSound:String = 'TrickyGlitch';
						var spawnSound:String = 'Trickyspawn';

						CoolUtil.precacheSound('staticSound');

						var glitch:FlxSound = new FlxSound().loadEmbedded(Paths.sound(glitchSound, 'clown'));
						var spawn:FlxSound = new FlxSound().loadEmbedded(Paths.sound(spawnSound, 'clown'));

						var glitched:Bool = false;

						FlxG.sound.list.add(glitch);
						FlxG.sound.list.add(spawn);

						spawnAnim.cameras = [camGame];

						spawnAnim.frames = Paths.getSparrowAtlas('EXENTER', 'clown');
						spawnAnim.animation.addByPrefix('start', 'Entrance', 24, false);

						spawnAnim.antialiasing = globalAntialiasing;
						dad.visible = false;

						modchartTimers.push(new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
						{
							dadGroup.add(spawnAnim);
							spawnAnim.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int)
							{
								if (frameNumber >= 24 && !glitched)
								{
									glitched = true;
									glitch.play();

									spawnAnim.animation.callback = null;
								}
							}
							spawnAnim.animation.finishCallback = function(pog:String)
							{
								startCountdown();
								spawnAnim.animation.finishCallback = null;

								glitch.fadeOut();
								dad.visible = true;

								spawnAnim.visible = false;
								spawnAnim.kill();

								dadGroup.remove(spawnAnim, true);

								spawnAnim.destroy();
								spawnAnim = null;
							}

							spawnAnim.animation.play('start');
							spawn.play();

							cleanupTimer(tmr);
						}));
					}
			}
		}
		recalculateRating(true); // no-zoom
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, getFormattedSong(), getHealthIconOf(iconP2, dad));
		if (!ClientPrefs.getPref('controllerMode'))
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		super.create();
		Paths.clearUnusedMemory();
	}

	override public function update(elapsed:Float)
	{
		FlxG.mouse.visible = false;

		var songPosition:Float = Conductor.songPosition;
		var sinkCutscene:Bool = false;

		if (inCutscene)
		{
			sinkCutscene = true;
			#if VIDEOS_ALLOWED
			if (PlayerSettings.controls.is(ACCEPT) && video != null)
			{
				trace('skiped');

				FlxG.sound.play(Paths.sound('cancelMenu'));
				if (video.finishCallback != null)
					video.finishCallback();

				video.bitmap.stop();
				video.bitmap.dispose();

				video.kill();
				remove(video, true);

				video.destroy();
				video = null;
			}
			#end
		}
		else
		{
			var curSwagSection:SwagSection = SONG.notes[curSection];
			var lerpVal:Float = FlxMath.bound(elapsed * 2.4 * cameraSpeed, 0, 1);

			if (generatedMusic && curSwagSection != null && !endingSong && !isCameraOnForcedPos)
				moveCameraSection();

			var dadSinging:Bool = characterIsSinging(dad);

			var cancelBoyfriend:Bool = true;
			var cancelDad:Bool = true;

			if (duoOpponent != null)
			{
				if (curStage is Carnival && cancelBoyfriend)
				{
					if (!characterIsSinging(boyfriend))
						cancelCameraDelta(duoOpponent);
					if (characterIsSinging(duoOpponent))
						cancelBoyfriend = false;
				}
				else if (!dadSinging && cancelDad)
				{
					cancelCameraDelta(duoOpponent, true);
					if (characterIsSinging(duoOpponent))
						cancelDad = false;
				}
			}
			if (trioOpponent != null && cancelDad)
			{
				if (!dadSinging)
					cancelCameraDelta(trioOpponent, true);
				if (characterIsSinging(trioOpponent))
					cancelDad = false;
			}
			switch (Type.getClass(curStage))
			{
				case Hell:
					{
						var itsAHorse:Character = curStage.itsAHorse;
						if (itsAHorse != null)
						{
							if (!dadSinging)
								cancelCameraDelta(itsAHorse, true);
							if (characterIsSinging(itsAHorse))
								cancelDad = false;
						}
					}
				case Squidgame:
					{
						var pinkSoldier:Character = curStage.pinkSoldier;
						if (pinkSoldier != null)
							cancelCameraDelta(pinkSoldier);
					}
			}
			if (cancelBoyfriend)
				cancelCameraDelta(boyfriend);
			if (cancelDad)
				cancelCameraDelta(dad);

			var usePlayerDelta:Bool = curSwagSection != null && curSwagSection.mustHitSection;

			var point:FlxPoint = usePlayerDelta ? playerDelta : opponentDelta;
			var multiplier:Float = (ClientPrefs.getPref('reducedMotion') || isFNM) ? 0 : cameraOffset;

			var followX:Float = camFollow.x + (point.x * multiplier);
			var followY:Float = camFollow.y + (point.y * multiplier);

			if (secondOpponentDelta != null)
			{
				var newZoom:Float = stageData.defaultZoom;
				if (!usePlayerDelta)
				{
					var secondX:Float = secondOpponentDelta.x;
					var secondY:Float = secondOpponentDelta.y;

					followX += secondX * multiplier;
					followY += secondY * multiplier;

					if (secondX != 0 || secondY != 0)
					{
						followX += 250;
						followY -= 130;

						if (curStage is Squidgame)
						{
							var pinkSoldier:Character = curStage.pinkSoldier;
							if (pinkSoldier != null)
								newZoom += .35;
						}
					}
				}
				defaultCamZoom = newZoom;
			}
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, followX, lerpVal), FlxMath.lerp(camFollowPos.y, followY, lerpVal));
		}

		switch (curSong)
		{
			case 'opposition':
				{
					var multiply:Float = 200;

					dad.x = Math.sin(circleTime) * multiply;
					dad.y = Math.cos(circleTime) * multiply;

					startCharacterPos(dad);

					dad.x -= dad.width;
					circleTime = (circleTime - (elapsed * 2)) % (Math.PI * 2);
				}
		}

		for (shader in shaders)
			shader?.update(elapsed);
		#if VIDEOS_ALLOWED
		for (video in modchartVideos)
			video?.update(elapsed);
		#end

		if (botplayTxt != null && botplayTxt.visible)
		{
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (PlayerSettings.controls.is(PAUSE) && startedCountdown && canPause && !sinkCutscene)
		{
			persistentUpdate = false;
			persistentDraw = paused = true;

			inst?.pause();
			vocals?.pause();

			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			DiscordClient.changePresence(detailsPausedText, getFormattedSong(), getHealthIconOf(iconP2, dad));
		}
		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			#if debug
			openChartEditor();
			#else
			switch (curSong)
			{
				case 'squidgames':
					{
						if (ClientPrefs.getPref('killgames'))
						{
							openChartEditor();
						}
						else
						{
							var extraWeeks:Array<String> = FreeplayState.panels[1][1];
							// Incase the user exists KILLGAMES prematurely
							if (!extraWeeks.contains(FreeplayState.KILLGAMES_WEEK))
							{
								if (extraWeeks.contains(FreeplayState.BEND_HARD_WEEK))
									extraWeeks.insert(extraWeeks.indexOf(FreeplayState.BEND_HARD_WEEK), FreeplayState.KILLGAMES_WEEK);
								else
									extraWeeks.push(FreeplayState.KILLGAMES_WEEK);
							}

							ClientPrefs.prefs.set('killgames', true);
							ClientPrefs.saveSettings();

							CoolUtil.difficulties = ['aint-no-game'];

							persistentUpdate = false;
							persistentDraw = paused = true;

							inst?.pause();
							vocals?.pause();

							storyDifficulty = 0;
							isStoryMode = false;

							SONG = Song.loadFromJson(CoolUtil.getDifficultyFilePath(storyDifficulty), 'killgames');

							CustomFadeTransition.nextCamera = camOther;
							MusicBeatState.coolerTransition = true;

							LoadingState.loadAndSwitchState(new PlayState(), true);
						}
					}
				default:
					{
						if (!isStoryMode)
						{
							for (week => file in WeekData.weeksLoaded)
							{
								for (song in file.data.songs)
								{
									if (song[0] == SONG.song)
									{
										if (StoryMenuState.weekCompleted.exists(week) || file.data.hideStoryMode)
											openChartEditor();
										break;
									}
								}
							}
						}
					}
			}
			#end
		}

		health = Math.min(health, MAX_HEALTH);
		if (healthBar != null)
		{
			final healthAlpha:Float = ClientPrefs.getPref('healthBarAlpha', 1) * iconAlpha;
			healthBar.percent = health;

			healthBar.visible = healthAlpha > 0;
			healthBar.alpha = healthAlpha;

			if (iconP1 != null && iconP2 != null)
			{
				final curHealth:Float = (health / MAX_HEALTH) * 100;
				final hideHUD:Bool = ClientPrefs.getPref('hideHUD');

				final bar:FlxBar = healthBar.bar;

				final healthOffset:Float = bar.offset.x;
				final healthX:Float = bar.x + healthOffset + (bar.width * ((if (shitFlipped) curHealth else FlxMath.remapToRange(curHealth, 0, 100, 100, 0)) / 100));

				final otherOpponentsVisible:Bool = (duoOpponent?.visible ?? false) || (trioOpponent?.visible ?? false);
				final dadVisible:Bool = (dad.visible || otherOpponentsVisible || (spawnAnim != null && spawnAnim.visible)) && dadGroup.visible;

				final p2:Character = if (shitFlipped) boyfriend else dad;
				final p1:Character = if (shitFlipped) dad else boyfriend;

				final p1Group:FlxSpriteGroup = if (shitFlipped) dadGroup else boyfriendGroup;
				final p2Group:FlxSpriteGroup = if (shitFlipped) boyfriendGroup else dadGroup;

				iconP1.visible = !hideHUD && healthAlpha > 0 && (if (p1 == dad) dadVisible else (p1.visible && p1Group.visible));
				iconP2.visible = !hideHUD && healthAlpha > 0 && (if (p2 == dad) dadVisible else (p1.visible && p1Group.visible));

				if (healthBar.visible && (iconP1.visible || iconP2.visible))
				{
					iconP1.alpha = healthAlpha * (if (p1 == dad && otherOpponentsVisible) 1 else p1.alpha) * p1Group.alpha;
					iconP2.alpha = healthAlpha * (if (p2 == dad && otherOpponentsVisible) 1 else p2.alpha) * p2Group.alpha;

					final inverseHealth:Float = 100 - curHealth;

					iconP2.setFrameOnPercentage(if (shitFlipped) curHealth else inverseHealth);
					iconP1.setFrameOnPercentage(if (shitFlipped) inverseHealth else curHealth);

					iconP1.y = iconP2.y = bar.y - bar.offset.y - 75;
					switch (isFNM)
					{
						default:
							{
								iconP1.x = healthX + (((if (iconP2.visible) ICON_SCALE * iconP1.scale.x else 0) - ICON_SCALE) * .5) - healthOffset + iconP1Offset.x;
								iconP2.x = healthX - (((if (iconP1.visible) ICON_SCALE * iconP2.scale.x else 0) + ICON_SCALE) * .5) + healthOffset + iconP2Offset.x;

								iconP1.y += iconP1Offset.y;
								iconP2.y += iconP2Offset.y;
							}
						case true:
							{
								var iconScaleOffset:Float = ICON_SCALE * ((1 - HealthIcon.FNM_SCALING) * .5);

								iconP1.x = healthX + healthOffset - iconScaleOffset;
								iconP2.x = healthX - healthOffset - (ICON_SCALE - iconScaleOffset);
							}
					}
				}
			}
		}
		if (scoreTxt != null)
			scoreTxt.alpha = iconAlpha;

		var scrollUnderlayAlpha:Float = ClientPrefs.getPref('scrollUnderlay', 0);
		var underlayHeight:Int = Math.ceil(FlxG.height / camHUD.zoom);

		if (playerScrollUnderlay != null && boyfriend != null)
		{
			var alphaMult:Float = 0;
			var length:Int = 0;

			playerStrums.forEachAlive(function(strum:StrumNote) {
				length++;
				alphaMult += strum.alpha;
			});
			if (length > 0)
				alphaMult /= length;

			playerScrollUnderlay.alpha = scrollUnderlayAlpha * boyfriend.alpha * alphaMult;
			playerScrollUnderlay.height = underlayHeight;
		}
		if (opponentScrollUnderlay != null && dad != null)
		{
			var alphaMult:Float = 0;
			var length:Int = 0;

			opponentStrums.forEachAlive(function(strum:StrumNote) {
				length++;
				alphaMult += strum.alpha;
			});
			if (length > 0)
				alphaMult /= length;

			opponentScrollUnderlay.alpha = scrollUnderlayAlpha * dad.alpha * alphaMult;
			opponentScrollUnderlay.height = underlayHeight;
		}

		#if debug
		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene)
		{
			persistentUpdate = false;
			paused = true;

			cancelMusicFadeTween();
			LoadingState.loadAndSwitchState(new CharacterEditorState(SONG.player2, true, Paths.currentLevel), false, true);
		}
		#end

		var elapsedMult:Float = elapsed * 1000;
		if (startedCountdown)
			songPosition += elapsedMult;
		if (startingSong)
		{
			if (startedCountdown)
			{
				if (songPosition >= 0)
					startSong();
			}
			else
			{
				songPosition = startDelay * startPosition;
			}
		}
		else if (!paused)
		{
			songTime += elapsedMult;
			// intrerolatpion
			if (Conductor.lastSongPos != songPosition)
			{
				songTime = (songTime + songPosition) / 2;
				Conductor.lastSongPos = songPosition;
			}
			if (updateTime && timeBar != null)
			{
				var timeBarType:String = Paths.formatToSongPath(ClientPrefs.getPref('timeBarType'));
				var curTime:Float = songPosition - ClientPrefs.getPref('noteOffset');

				var lengthUsing:Float = (maskedSongLength > 0) ? maskedSongLength : songLength;

				curTime = Math.max(curTime, 0);
				songPercent = curTime / lengthUsing;

				timeBar.percent = songPercent;

				var songCalc:Float = lengthUsing - curTime;
				if (timeBarType == 'time-elapsed')
					songCalc = curTime;

				var secondsTotal:Int = Math.floor(Math.max(songCalc / 1000, 0));
				if (timeBarType != 'song-name')
					timeBar.txt.text = FlxStringUtil.formatTime(secondsTotal, false);
			}
			if (iconP1 != null && iconP2 != null)
			{
				var offsetLerpSpeed:Float = 1 - Math.pow((1 / (Conductor.bpm * 4) / 60) / gfSpeed, elapsed);
				iconP1Offset.set(FlxMath.lerp(iconP1Offset.x, iconP1OffsetFollow.x, offsetLerpSpeed),
					FlxMath.lerp(iconP1Offset.y, iconP1OffsetFollow.y, offsetLerpSpeed));
				iconP2Offset.set(FlxMath.lerp(iconP2Offset.x, iconP2OffsetFollow.x, offsetLerpSpeed),
					FlxMath.lerp(iconP2Offset.y, iconP2OffsetFollow.y, offsetLerpSpeed));

				var followLerpSpeed:Float = 1 - Math.pow((1 / (Conductor.bpm * 2) / 60) / gfSpeed, elapsed);

				iconP1OffsetFollow.set(FlxMath.lerp(iconP1OffsetFollow.x, 0, followLerpSpeed), FlxMath.lerp(iconP1OffsetFollow.y, 0, followLerpSpeed));
				iconP2OffsetFollow.set(FlxMath.lerp(iconP2OffsetFollow.x, 0, followLerpSpeed), FlxMath.lerp(iconP2OffsetFollow.y, 0, followLerpSpeed));
			}
		}

		var lerpSpeed:Float = FlxMath.bound(1 - (elapsed * Math.PI), 0, 1);
		if (isFNM)
		{
			fnmElapsed += elapsed;
			if (fnmElapsed >= FNM_ICON_BOP)
			{
				fnmElapsed %= FNM_ICON_BOP;
				iconBop();
			}
		}
		if (camZooming)
		{
			if (cameraTwn == null)
				gameZoom = FlxMath.lerp(defaultCamZoom, gameZoom, lerpSpeed);
			// commented out because i could maybe keep it constant
			// hudZoom = FlxMath.lerp(1, hudZoom, lerpSpeed);
			gameZoomAdd = FlxMath.lerp(0, gameZoomAdd, lerpSpeed);
			hudZoomAdd = FlxMath.lerp(0, hudZoomAdd, lerpSpeed);
		}
		if (vignetteImage != null)
		{
			vignetteImage.setGraphicSize(FlxG.width, FlxG.height);
			vignetteImage.updateHitbox();

			// vignetteImage.alpha = FlxMath.lerp(CoolUtil.int(vignetteEnabled), vignetteImage.alpha, lerpSpeed);
		}
		if (foursomeFrame != null && foursomeFrame.type >= 0)
			foursomeFrame.update(elapsed);

		camGame.zoom = gameZoom + gameZoomAdd; // FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, lerpSpeed);
		camHUD.zoom = hudZoom + hudZoomAdd; // FlxMath.lerp(1, camHUD.zoom, lerpSpeed);

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.getPref('noReset') && PlayerSettings.controls.is(RESET) && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = -1;
			trace("RESET = True");
		}
		doDeathCheck();
		if (unspawnNotes[0] != null)
		{
			var weirdAssMap:Map<Note, Note> = new Map();
			var time:Float = spawnTime;

			if (songSpeed < 1)
				time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1)
				time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - songPosition <= time)
			{
				var insertingIn:FlxTypedGroup<Note> = notes;
				var dunceNote:Note = unspawnNotes[0];

				if (dunceNote.noteType != null) // FUCK YOU HTML5
				{
					var formattedNoteType:String = Paths.formatToSongPath(dunceNote.noteType);
					switch (formattedNoteType)
					{
						case 'duo-note' | 'both-opponents-note':
							{
								if (!dunceNote.mustPress && worldNotes != null)
								{
									// HOPE THIS WORKS!!!!!!!!!!!
									if (formattedNoteType == 'both-opponents-note')
									{
										var cloneNote:Note = new Note(dunceNote.strumTime, dunceNote.noteData, weirdAssMap.get(dunceNote.prevNote),
											dunceNote.isSustainNote, dunceNote.inEditor);
										weirdAssMap.set(dunceNote, cloneNote);

										cloneNote.noteType = dunceNote.noteType;
										cloneNote.multSpeed = dunceNote.multSpeed;

										cloneNote.sustainLength = dunceNote.sustainLength;
										cloneNote.colorSwap = dunceNote.colorSwap;

										notes.insert(0, cloneNote);
									}

									dunceNote.reloadNote('', 'Pink_Note_Assets');
									if (dunceNote.isSustainNote)
										dunceNote.flipY = false;

									dunceNote.scrollFactor.set(1, 1);
									insertingIn = worldNotes;
								}
							}
					}
				}
				insertingIn.insert(0, dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			Conductor.songPosition = songPosition;
			if (!inCutscene)
			{
				if (cpuControlled)
				{
					bfDance();
				}
				else
				{
					keyShit();
				}
				if (startedCountdown)
				{
					hitsoundsPlayed = [];
					iterateNotes(notes);

					if (worldNotes != null)
						iterateNotes(worldNotes, secondOpponentStrums.members);
				}
				else
				{
					notes.forEachAlive(function(daNote:Note)
					{
						daNote.canBeHit = daNote.wasGoodHit = false;
					});
				}
			}
			checkEventNote();
		}
		// SHUTTLECOCK FUNCTIONS
		if (shuttlecock != null && !(paused || startingSong))
		{
			var hitKey:Bool = !cpuControlled && shuttleStunnedFor <= 0 && PlayerSettings.controls.is(HIT);
			var didHit:Bool = false;

			if (songPosition >= 0)
			{
				var nextBeatCrochet:Float = Conductor.crochet * shuttlecock.nextBeat;
				var didSkipTime:Bool = shuttleSkippedTime > songPosition && shuttleSkippedTime > nextBeatCrochet;

				var newAlpha:Float = (songPosition - lastShuttleHit) / (nextBeatCrochet - lastShuttleHit); // (Conductor.crochet * shuttlecockBeats);
				var flipped:Bool = shuttlecock.flipX;

				var isPlayersTurn:Bool = flipped && !cpuControlled;
				var pass:Bool = !isPlayersTurn && newAlpha >= 1;

				var clampedAlpha:Float = isPlayersTurn ? newAlpha : Math.min(newAlpha, 1);

				shuttlecock.curveAlpha = clampedAlpha;
				didHit = pass;

				shuttlecock.alpha = isPlayersTurn ? .85 : 1;
				shuttleColorSwap.brightness = 0;

				if (didSkipTime)
				{
					trace('skipped time ' + (shuttleSkippedTime - songPosition));
					pass = true;
				}
				else
				{
					if (shuttleSwingButton != null)
					{
						shuttleButtonColorSwap.brightness = flipped ? 0 : -.5;
						if (clampedAlpha >= 1 && flipped && !hasPlayedShuttleAnimation)
						{
							hasPlayedShuttleAnimation = true;
							shuttleSwingButton.animation.play('press', true);
						}

						var curAnim:FlxAnimation = shuttleSwingButton.animation.curAnim;
						if (curAnim != null && curAnim.name == 'press' && curAnim.finished)
							shuttleSwingButton.animation.play('idle');
					}
					if (!pass && isPlayersTurn)
					{
						var lateFrames:Float = elapsed + (1 / shuttleLateDeadzone);
						if (newAlpha >= (1 - (elapsed + (1 / shuttleEarlyDeadzone))) && newAlpha <= (1 + lateFrames))
						{
							shuttleColorSwap.brightness = .3;
							shuttlecock.alpha = 1;

							if (hitKey)
							{
								// formula so you cant just get all ur health right off the bat if you SUCK
								var timing:Float = Math.pow(1 - Math.abs(1 - newAlpha), Math.max(7 - (combo / 5), 1));

								didHit = true;
								pass = true;

								health = Math.min(health + ((shuttleHealth / 5) * healthGain * timing), MAX_HEALTH);
								shuttleStunnedFor = 0;
							}
						}
						else if (newAlpha >= (shuttleMissAlpha + lateFrames))
						{
							pass = true;

							totalShitsFailed++;
							shitsFailedLol++;

							songMisses++;
							recalculateRating(true);

							combo = 0;
							health = Math.min(health - (shuttleHealth * healthLoss), MAX_HEALTH);

							shuttleStunnedFor = shuttleStunTime;
							boyfriend.stunned = true;

							modchartTimers.push(new FlxTimer().start(shuttleStunTime * 2, function(tmr:FlxTimer)
							{
								boyfriend.stunned = false;
								cleanupTimer(tmr);
							}));
							shuttlecock.miss();
						}
					}
				}
				if (pass)
				{
					if (didHit && !didSkipTime)
					{
						shuttlecock.hit();
						if (!flipped)
							shuttlecock.playAnimation(dad); // && dad.animOffsets.exists('hit')) { dad.playAnim('hit', true); dad.specialAnim = true; }
					}
					// Flip it
					shuttlecock.flipX = !flipped;

					shuttlecock.lastPoint = 1 - clampedAlpha;
					shuttlecock.curveAlpha = 0;

					lastShuttleHit = shuttlecock.nextBeat * Conductor.crochet;
					while (newNextShuttleBeats.length > 0)
					{
						var value:Float = newNextShuttleBeats[0];

						if (value >= 0 && shuttlecock.nextBeat > value)
						{
							newNextShuttleBeats.shift();
						}
						else
						{
							break;
						}
					}

					if (newNextShuttleBeats.length > 0)
					{
						shuttlecock.nextBeat = newNextShuttleBeats.pop();
						newNextShuttleBeats = new Array();
					}
					else
					{
						shuttlecock.nextBeat += shuttlecockBeats;
					}

					killShuttlecock();

					if (shuttleSwingButton != null && !hasPlayedShuttleAnimation && flipped)
						shuttleSwingButton.animation.play('press', true);
					hasPlayedShuttleAnimation = false;
				}
				shuttleStunnedFor = Math.max(shuttleStunnedFor - elapsed, 0);
				if ((hitKey || (cpuControlled && flipped && didHit)) && !didSkipTime)
				{
					switch (didHit)
					{
						case true:
							shitsFailedLol = Std.int(Math.max(shitsFailedLol - 1, 0));
						default:
							shuttleStunnedFor = shuttleStunTime;
					}
					if (shuttlecock != null)
						shuttlecock.playAnimation(boyfriend);
				}
			}
		}
		if (crazyShitMode)
		{
			var circleTime:Float = (songPosition / Conductor.crochet) % (Math.PI * 2);
			var noteOffsetDistance:Float = 15;

			strumLineNotes.forEachAlive(function(strumNote:StrumNote)
			{
				var offset:Float = (strumNote.player > 0 ? (4 - strumNote.ID) : strumNote.ID) * .4;

				strumNote.x = strumLine.x + (Math.sin(circleTime + offset) * noteOffsetDistance * ((strumNote.player * 2) - 1)) + strumNote.coolOffsetX;
				strumNote.y = strumLine.y + (Math.cos(Math.PI + circleTime + offset) * noteOffsetDistance) + strumNote.coolOffsetY;

				strumNote.postAddedToGroup();
			});
		}
		#if debug
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.anyJustPressed(debugKeysFinish))
			{
				killNotes();
				if (inst != null)
				{
					inst.onComplete();
					inst.onComplete = null;
				}
			}
			else if (FlxG.keys.anyJustPressed(debugKeysSkip))
			{
				// Go 10 seconds into the future :O
				var skipping:Float = songPosition + 10000;

				setSongTime(skipping);
				clearNotesBefore(skipping);

				shuttleSkippedTime = skipping + (elapsed * 1000) + ((1 / shuttleEarlyDeadzone) * 1000) + 34;
				if (inst != null && skipping >= inst.length)
				{
					killNotes();

					inst.onComplete();
					inst.onComplete = null;
				}
			}
		}
		#end
		for (stage in stageUpdates)
			stage.update(elapsed);
		super.update(elapsed);
	}

	// TIMING
	override function stepHit()
	{
		super.stepHit();

		var songPosition:Float = Conductor.songPosition - Conductor.offset;
		var music:FlxSound = inst;

		if (!startingSong
			&& music != null
			&& songPosition >= 0
			&& Conductor.songPosition <= music.length
			&& (Math.abs(music.time - songPosition) > vocalResyncTime
				&& music.length > songPosition
				&& music.time < music.length
				&& music.playing)
			|| (SONG.needsVoices
				&& vocals != null
				&& Math.abs(vocals.time - songPosition) > vocalResyncTime
				&& vocals.length > songPosition
				&& vocals.time < vocals.length
				&& vocals.time < music.length
				&& vocals.playing))
			resyncVocals();
		if (curStep == lastStepHit)
			return;

		var zoomFunction:Array<Dynamic> = camZoomTypes[camZoomType];
		if (zoomFunction != null && canZoomCamera() && !zoomFunction[0])
			zoomFunction[1]();

		doSustainShake();
		lastStepHit = curStep;

		if (curStage != null)
			curStage.stepHit(curStep);
	}

	override function beatHit()
	{
		super.beatHit();
		if (lastBeatHit == curBeat)
			return;
		if (generatedMusic)
		{
			if (worldNotes != null)
				worldNotes.sort(FlxSort.byY, FlxSort.DESCENDING);
			notes.sort(FlxSort.byY, (ClientPrefs.getPref('downScroll') && !isFNM) ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		var zoomFunction:Array<Dynamic> = camZoomTypes[camZoomType];
		if (!isFNM)
			iconBop(curBeat);

		if (zoomFunction != null && canZoomCamera() && zoomFunction[0])
			zoomFunction[1]();
		if (noddingCamera && !ClientPrefs.getPref('reducedMotion'))
		{
			var duration:Float = Conductor.crochet / 1000;
			var inverse:Float = nodRight ? 1 : -1;

			var degrees:Float = .05 * FlxAngle.TO_DEG;
			var angling:Float = .5 * inverse;

			if (camHUDTwn != null)
			{
				cleanupTween(camHUDTwn);
				camHUDTwn = null;
			}
			if (camGameTwn != null)
			{
				cleanupTween(camGameTwn);
				camGameTwn = null;
			}

			camHUD.angle = angling * 2;
			camGame.angle = angling;

			camGame.y = .5 * degrees * Math.PI;
			camGame.x = degrees * inverse;

			camHUD.x = 2 * degrees * inverse;
			camHUD.y = degrees * Math.PI;

			camGameTwn = FlxTween.tween(camGame, {x: 0, y: 0, angle: 0}, duration, {
				ease: FlxEase.quadIn,
				onComplete: function(twn:FlxTween)
				{
					cleanupTween(twn);
					camGameTwn = null;
				}
			});
			camHUDTwn = FlxTween.tween(camHUD, {x: 0, y: 0, angle: 0}, duration, {
				ease: FlxEase.quadIn,
				onComplete: function(twn:FlxTween)
				{
					cleanupTween(twn);
					camHUDTwn = null;
				}
			});
			nodRight = !nodRight;
		}

		groupDance(gfGroup, curBeat);
		groupDance(boyfriendGroup, curBeat);
		groupDance(dadGroup, curBeat);

		if (foursomeFrame != null)
			foursomeFrame.dance(curBeat);
		if (curStage != null)
			curStage.beatHit(curBeat);
		lastBeatHit = curBeat;
	}

	override function sectionHit()
	{
		super.sectionHit();

		var section:SwagSection = SONG.notes[curSection];
		if (section != null)
		{
			updateTimeColor();
			if (section.changeBPM)
				Conductor.changeBPM(section.bpm);
		}
		if (curStage != null)
			curStage.sectionHit(curSection);
	}

	// SUBSTATES
	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			inst?.pause();
			vocals?.pause();

			if (camGameTwn != null)
				camGameTwn.active = false;
			if (camHUDTwn != null)
				camHUDTwn.active = false;

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;

			if (songSpeedTween != null)
				songSpeedTween.active = false;
			if (cameraTwn != null)
				cameraTwn.active = false;

			for (tween in modchartTweens)
				tween.active = false;
			for (timer in modchartTimers)
				timer.active = false;
			#if VIDEOS_ALLOWED
			for (video in modchartVideos)
				video.bitmap.pause();
			#end
		}
		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (inst != null && !startingSong)
				resyncVocals(true);

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;

			if (camGameTwn != null)
				camGameTwn.active = true;
			if (camHUDTwn != null)
				camHUDTwn.active = true;

			if (songSpeedTween != null)
				songSpeedTween.active = true;
			if (cameraTwn != null)
				cameraTwn.active = true;

			for (tween in modchartTweens)
				tween.active = true;
			for (timer in modchartTimers)
				timer.active = true;
			#if VIDEOS_ALLOWED
			for (video in modchartVideos)
				video.bitmap.resume();
			#end

			paused = false;
			DiscordClient.changePresence(detailsText, getFormattedSong(), getHealthIconOf(iconP2, dad), startTimer == null ? true : startTimer.finished,
				songLength - Conductor.songPosition - ClientPrefs.getPref('noteOffset'));
		}
		super.closeSubState();
	}

	// FOCUS
	override public function onFocus():Void
	{
		if (health > 0 && !paused)
		{
			quickUpdatePresence();
			if (!startingSong)
				resyncVocals(true);
		}
		focused = true;

		// if (video != null)
		// 	video.bitmap.resume();
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		if (health > 0 && !paused)
			quickUpdatePresence("PAUSED - ", false);
		focused = false;

		// if (video != null)
		// 	video.bitmap.pause();
		super.onFocusLost();
	}

	override function destroy()
	{
		var application:Application = Lib.application;
		if (!ClientPrefs.getPref('controllerMode'))
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		if (shuttlecock != null)
			shuttlecock.destroy();
		if (curStage != null)
			curStage.destroy();

		if (application != null)
		{
			var meta:Map<String, String> = application.meta;
			if (meta != null && meta.exists('name'))
				application.window.title = meta.get('name');
		}
		super.destroy();
	}

	// SETTERS
	private function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in notes)
				note.resizeByRatio(ratio);
			for (note in unspawnNotes)
				note.resizeByRatio(ratio);
		}

		songSpeed = value;
		noteKillOffset = (Note.noteWidth * 2) / songSpeed;

		return value;
	}

	// NOTES
	private inline static function getNoteDataPoint(leData:Int):FlxPoint
	{
		return new FlxPoint(switch (leData)
		{
			case 0:
				-1;
			case 3:
				1;

			default:
				0;
		}, switch (leData)
			{
				case 2:
					-1;
				case 1:
					1;

				default:
					0;
			});
	}

	public inline static function getNoteSplash():String
		return (SONG != null && SONG.splashSkin != null && SONG.splashSkin.length > 0) ? SONG.splashSkin : 'noteSplashes';

	private inline function eventPushed(event:EventNote)
	{
		var eventName:String = Paths.formatToSongPath(event.event);
		switch (eventName)
		{
			case 'shoot':
				{
					CoolUtil.precacheSound('gunshot');
					CoolUtil.precacheSound('ANGRY');
				}

			case 'legalize-nuclear-bombs':
				{
					if (legalize == null && !ClientPrefs.getPref('lowQuality'))
					{
						legalize = new FlxSprite();

						legalize.frames = Paths.getSparrowAtlas('goofy/peak');
						legalize.animation.addByPrefix('bomb', 'bomb', 24, false);

						legalize.cameras = [camOther];

						legalize.setGraphicSize(FlxG.width, FlxG.height);
						legalize.screenCenter();

						legalize.alpha = FlxMath.EPSILON;
						add(legalize);
					}
				}

			case 'funny-duo':
				{
					if (goofyAww == null)
					{
						goofyAww = new FlxTypedGroup(6);
						add(goofyAww);
					}
					for (i in 1...4)
						Paths.image('goofy/$i');
					Paths.image('goofy/moyai');
				}
			case 'foolish-type-beat':
				{
					if (pizza == null)
					{
						pizza = new FlxSprite();

						pizza.frames = Paths.getSparrowAtlas('pizza');
						pizza.animation.addByPrefix('pizza', 'pizza', 24, false);

						pizza.antialiasing = ClientPrefs.getPref('globalAntialiasing');
						pizza.cameras = [camOther];

						pizza.alpha = FlxMath.EPSILON;
						pizza.screenCenter();

						add(pizza);
					}

					Paths.image('mission_passed');
					Paths.image('background');
					Paths.image('ron');
				}

			case 'vignette':
				{
					if (vignetteImage == null)
					{
						var imagePath:FlxGraphic = Paths.image('vignette');

						vignetteImage = new FlxSprite().loadGraphic(imagePath, false);
						vignetteImage.antialiasing = ClientPrefs.getPref('globalAntialiasing');

						vignetteImage.setGraphicSize(FlxG.width, FlxG.height);
						vignetteImage.updateHitbox();

						vignetteImage.screenCenter();
						vignetteImage.scrollFactor.set();

						vignetteImage.cameras = [camOther];
						vignetteImage.alpha = 0;

						add(vignetteImage);
					}
				}
			case 'extend-timer':
				{
					if (timerExtensions == null)
						timerExtensions = new Array();

					timerExtensions.push(event.strumTime);
					maskedSongLength = timerExtensions[0];
				}
			#if VIDEOS_ALLOWED
			case 'play-video':
				{
					var bitmap:VideoHandler = new VideoHandler();
					bitmap.openingCallback = function()
					{
						bitmap.openingCallback = null;
						if (bitmap.bitmapData != null)
							FlxG.bitmap.add(bitmap.bitmapData, false, bitmap.mrl);

						bitmap.stop();
						bitmap.dispose();

						bitmap = null;
					}

					bitmap.canUseSound = false;
					bitmap.playVideo(Paths.video(event.value1), false, false);

					var video:VideoSprite = new VideoSprite();

					video.bitmap.canSkip = false;
					video.active = false;

					video.cameras = [
						switch (Paths.formatToSongPath(event.value2))
						{
							case 'other' | 'camother' | '2':
								camOther;
							case 'game' | 'camgame' | '0':
								camGame;

							default:
								camHUD;
						}
					];
					video.kill();

					video.scrollFactor.set();
					videos.push(video);
				}
			#end
			case 'change-character':
				{
					var newCharacter:String = event.value2;
					if (Assets.exists(Paths.getPreloadPath('characters/$newCharacter.json')))
						preloadCharacter(newCharacter);
				}

			case 'foursome-frame':
				{
					if (foursomeFrame == null)
					{
						foursomeFrame = new FoursomeFrame();
						foursomeFrame.cameras = [camHUD];
					}
				}

			case 'change-stage':
				{
					var stageName:String = event.value1;
					var stageClass:Dynamic = StageData.getStageClass(stageName);
					// default
					switch (Paths.formatToSongPath(event.value2))
					{
						case 'start-b':
							{
								trace('preload the supert transtiojn shits');

								preloadCharacter('funnybf-playable');
								preloadCharacter('funnybf-youtooz');
							}
					}

					if (stageClass == null)
						StageData.getStageClass(SONG?.stage ?? StageData.getStage(curSong));
					if (stageClass != null)
					{
						trace('prelooooaaabb $stageName');

						var stageFile:StageFile = StageData.getStageFile(stageName);
						Paths.setCurrentLevel(stageFile?.directory ?? '');

						var stage:Dynamic = Type.createInstance(stageClass, [instance]);

						stage.initData = event.value2;
						stage.active = false;

						stageGroup.add(stage);

						stage.kill();
						stages.push([stage, stageFile]);
					}
				}
		}
		if (!eventPushedMap.exists(eventName))
			eventPushedMap.set(eventName, true);
	}

	private function eventNoteEarlyTrigger(event:EventNote):Float
	{
		switch (Paths.formatToSongPath(event.event))
		{
			case 'set-shuttle-beats':
				return (1 / shuttleEarlyDeadzone) * 1000;
				// case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				//	return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	private function iterateNotes(noteGroup:FlxTypedGroup<Note>, ?strumMembersConst:Array<StrumNote>)
	{
		// this should hopefully fix delayed doubles???? i got no fucking clue
		var opponentNotesToHit:Array<Note> = [];
		var playerNotesToHit:Array<Note> = [];

		var fakeCrochet:Float = Conductor.calculateCrochet(SONG.bpm);
		var songPosition:Float = Conductor.songPosition;

		noteGroup.forEachAlive(function(daNote:Note)
		{
			var strumMembers:Array<StrumNote> = strumMembersConst ?? (daNote.mustPress ? playerStrums : opponentStrums).members;
			var strumMember:StrumNote = strumMembers[daNote.noteData];

			if (strumMember != null)
			{
				var strumX:Float = strumMember.x;
				var strumY:Float = strumMember.y;

				var strumDirection:Float = strumMember.direction;
				var strumAngle:Float = strumMember.angle;

				var strumScroll:Bool = strumMember.downScroll;
				var strumAlpha:Float = strumMember.alpha;

				switch (Paths.formatToSongPath(daNote.noteType))
				{
					case 'trickynote':
						strumX -= 164;
				}

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;

				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;

				daNote.distance = .45 * (songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed * (if (strumScroll) 1 else -1);

				var angleDir = strumDirection * Math.PI / 180;
				if (daNote.copyAngle && !daNote.isSustainNote)
					daNote.angle = strumDirection - 90 + strumAngle;
				if (daNote.copyAlpha && !isFNM)
					daNote.alpha = strumAlpha;

				if (daNote.copyX)
				{
					daNote.x = strumX + Math.cos(angleDir) * daNote.distance;
					// if (daNote.isSustainNote)
					// fixes offset that pissed me off
					//	daNote.x -= 2;
				}
				if (daNote.copyY)
				{
					daNote.y = strumY + Math.sin(angleDir) * daNote.distance;
					// Jesus fuck this took me so much mother fucking time AAAAAAAAAA
					if (strumScroll && daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith('end'))
						{
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;

							daNote.y -= 19;
						}

						daNote.y += (Note.noteWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
					}
				}

				var center:Float = strumY + Note.noteWidth / 2;
				if (strumMember.sustainReduce
					&& daNote.isSustainNote
					&& (daNote.mustPress || !daNote.ignoreNote)
					&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					if (strumScroll)
					{
						if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);

							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
					else
					{
						if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);

							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
				}
				// Kill extremely late notes and cause misses
				if (songPosition > (noteKillOffset / daNote.lateHitMult) + daNote.strumTime)
				{
					if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
						noteMiss(daNote);

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
				else
				{
					switch (daNote.mustPress)
					{
						case true:
							{
								if (cpuControlled
									&& !daNote.blockHit
									&& (daNote.strumTime <= songPosition
										|| (daNote.isSustainNote && daNote.canBeHit && daNote.prevNote.wasGoodHit)))
									playerNotesToHit.push(daNote);
							}
						default:
							{if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote) opponentNotesToHit.push(daNote);}
					}
				}
			}
		});

		for (note in opponentNotesToHit)
			opponentNoteHit(note);
		for (note in playerNotesToHit)
			goodNoteHit(note);
	}

	private function generateStaticArrows(player:Int):Void
	{
		var opponentStrumVisible:Bool = ClientPrefs.getPref('opponentStrums');

		var middleScroll:Bool = ClientPrefs.getPref('middleScroll');
		var downScroll:Bool = ClientPrefs.getPref('downScroll');

		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var isWorldStrumLine:Bool = player > 1;

			var strumLinePushing:FlxTypedGroup<StrumNote> = isWorldStrumLine ? worldStrumLineNotes : strumLineNotes;
			var strumLineParent:FlxTypedGroup<StrumNote> = switch (player)
			{
				case 2:
					secondOpponentStrums;
				case 1:
					playerStrums;

				default:
					opponentStrums;
			}

			var strumLineSprite:FlxSprite = isWorldStrumLine ? worldStrumLine : strumLine;
			var targetAlpha:Float = (player < 1 && !opponentStrumVisible) ? 0 : switch (isWorldStrumLine)
			{
				default:
					(middleScroll && player < 1 && !isFNM) ? MIDDLESCROLL_OPPONENT_TRANSPARENCY : 1;
				case true:
					.65;
			}

			var babyArrow:StrumNote = new StrumNote(isWorldStrumLine ? strumLineSprite.x : 0, strumLineSprite.y, i,
				isWorldStrumLine ? 0 : shitFlipped ? 1 - player : player, noteAssetsLibrary);

			if (!isWorldStrumLine)
			{
				babyArrow.downScroll = downScroll;
				babyArrow.middleScroll = middleScroll;
			}
			babyArrow.ID = i;
			if (isStoryMode || skipArrowStartTween || isFNM)
			{
				babyArrow.alpha = targetAlpha;
			}
			else
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;

				var tweenArray:Map<Int, FlxTween> = null;
				var pushShit:Array<Dynamic> = null;

				for (tweenShit in strumlineTweens)
				{
					if (tweenShit[0] == strumLineParent)
					{
						pushShit = tweenShit;
						tweenArray = tweenShit[1];

						if (tweenArray.exists(i))
						{
							var twn:FlxTween = tweenArray[i];

							twn.cancel();
							cleanupTween(twn);
							tweenArray.remove(i);
						}
						break;
					}
				}
				if (pushShit == null)
				{
					tweenArray = new Map();
					pushShit = [strumLineParent, tweenArray];

					strumlineTweens.push(pushShit);
				}

				var twn:FlxTween = FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: targetAlpha}, 1,
					{ease: FlxEase.circOut, startDelay: .5 + (.2 * i), onComplete: cleanupTween});

				modchartTweens.push(twn);
				tweenArray[i] = twn;
			}

			switch (player)
			{
				default:
					strumLineParent.add(babyArrow);
				case 2:
					{
						if (strumLineParent != null)
						{
							babyArrow.texture = 'Pink_Note_Assets';
							babyArrow.scrollFactor.set(1, 1);

							strumLineParent.add(babyArrow);
						}
					}
			}

			strumLinePushing.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	private inline function killNotes()
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];

			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}

		unspawnNotes = [];
		eventNotes = [];
	}

	private inline function pushEvents(eventsData:Array<Dynamic>)
	{
		var noteOffset:Int = ClientPrefs.getPref('noteOffset');
		for (event in eventsData) // Event Notes
		{
			for (i in 0...event[1].length)
			{
				var eventThing:Dynamic = event[1][i];
				var newEventNote:Array<Dynamic> = [event[0], eventThing[0], eventThing[1], eventThing[2]];

				var subEvent:EventNote = {
					strumTime: newEventNote[0] + noteOffset,
					event: newEventNote[1],

					value1: newEventNote[2],
					value2: newEventNote[3]
				};

				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}
	}

	// SONG
	private function resyncVocals(?forceMusic:Bool = false, ?skipOtherBullshitChecks:Bool = false):Void
	{
		if (finishTimer != null || inst == null)
			return;

		var curTime:Float = inst.time;
		var curVocals:Float = vocals?.time ?? curTime;

		var isntRestartingSong:Bool = skipOtherBullshitChecks || curTime < inst.length;
		if ((forceMusic == true
			|| (SONG.needsVoices
				&& vocals != null
				&& (curVocals > curTime + vocalResyncTime || curVocals < curTime - vocalResyncTime)
				&& vocals.length > curTime))
			&& isntRestartingSong)
		{
			trace('resync checks passed');
			// im like 90% sure this yields so i'm force restarting it and caching the current music time, then restarting it
			inst.play(true);
			inst.time = curTime;

			if (SONG.needsVoices && vocals != null && curTime < vocals.length)
			{
				vocals.play(true);
				vocals.time = curTime;
			}
		}
		if (isntRestartingSong)
			Conductor.songPosition = curTime;
	}

	private inline function getFormattedRating(accountFNM:Bool = true):String
	{
		return switch (isFNM && accountFNM)
		{
			case true:
				'score: $songScore';
			default:
				{
					var format:String = switch (Paths.formatToSongPath(barsAssets))
					{
						case 'relapse':
							'SCORE: $songScore | MISSES: $songMisses | RATING: $ratingName';
						case 'killgames':
							'SCORE: $songScore | KILLS: $songMisses | GAMES: $ratingName';

						default:
							'score: $songScore | horse cheeses: $songMisses | rating: $ratingName';
					}
					return (ratingName == '?') ? format : '$format (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%) - $ratingFC';
				}
		}
	}

	private inline function getFormattedSong(?getRating:Bool = true):String
	{
		var formatted:String = SONG.song + ' ($storyDifficultyText)';
		if (getRating)
			formatted += '\n' + getFormattedRating();
		return formatted;
	}

	private inline function startAndEnd(skipTransIn:Bool = false)
	{
		switch (endingSong)
		{
			case true:
				cleanupEndSong(skipTransIn);
			default:
				startCountdown();
		}
	}

	private inline function generateSong(dataPath:String):Void
	{
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype', 'multiplicative');
		switch (songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		Conductor.changeBPM(SONG.bpm);

		inst = new FlxSound();
		inst.loadEmbedded(Paths.inst(dataPath), false, false);

		FlxG.sound.list.add(inst);
		if (SONG.needsVoices)
		{
			vocals = new FlxSound();
			vocals.loadEmbedded(Paths.voices(dataPath), false, false);

			FlxG.sound.list.add(vocals);
		}

		var noteData:Array<SwagSection> = SONG.notes;
		var file:String = Paths.json(curSong, 'events', 'songs');

		if (OpenFlAssets.exists(file))
			pushEvents(Song.loadFromJson('events', curSong).events);

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;
				var noteType:String = Paths.formatToSongPath(songNotes[3]);

				switch (noteType)
				{
					case 'horse-cheese-note' | 'trickynote':
						{if (!mechanicsEnabled) continue;}
				}
				if (songNotes[1] > 3)
					gottaHitNote = !section.mustHitSection;

				var oldNote:Note = unspawnNotes.length > 0 ? unspawnNotes[Std.int(unspawnNotes.length - 1)] : null;
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false, noteAssetsLibrary);

				swagNote.isFNM = isFNM;

				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];

				swagNote.gfNote = (section.gfSection && (songNotes[1] < 4));

				var compatabilityType:Dynamic = songNotes[3];
				swagNote.noteType = Std.isOfType(compatabilityType,
					String) ? noteType : ChartingState.noteTypeList[compatabilityType]; // Backward compatibility + compatibility with Week 7 charts

				switch (noteType)
				{
					case 'horse-cheese-note':
						{
							if (horseImages == null)
							{
								trace("PRELOAD HORSES AND THE NOTES");

								CoolUtil.precacheSound('ANGRY');
								Paths.image('horse_cheese_notes');

								var dirPath:String = 'horses/';
								var library:String = 'shared';

								var horsePath:String = Paths.getLibraryPath('$library/images/$dirPath');

								var horseTemp:Array<FlxGraphic> = new Array();
								var assetList:Array<String> = OpenFlAssets.list(IMAGE);

								for (asset in assetList)
								{
									if (asset.startsWith(horsePath))
										horseTemp.push(Paths.returnGraphic('$library:$asset'));
								}
								horseImages = horseTemp;
							}
						}
					case 'trickynote':
						{
							if (!preloadedTrickyNotes)
							{
								preloadedTrickyNotes = true;
								trace('PRELOAD TRICKY NOTES');
								Paths.image('ALL_deathnotes', 'clown');
							}
						}
				}

				swagNote.scrollFactor.set();
				var susLength:Float = swagNote.sustainLength / Conductor.stepCrochet;

				unspawnNotes.push(swagNote);
				if (susLength > 0)
				{
					var floorSus:Int = Math.round(susLength);
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / songSpeed), daNoteData,
							oldNote, true, false, noteAssetsLibrary);

						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < 4));

						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();

						sustainNote.isFNM = isFNM;
						unspawnNotes.push(sustainNote);
					}
				}
				if (!noteTypeMap.exists(swagNote.noteType))
					noteTypeMap.set(swagNote.noteType, true);
			}
		}
		if (SONG.events != null)
			pushEvents(SONG.events);

		for (event in eventNotes)
			event.strumTime -= eventNoteEarlyTrigger(event);
		if (eventNotes.length > 1)
			eventNotes.sort(sortByTime); // No need to sort if there's a single one or none at all

		noteTypeMap.clear();
		noteTypeMap = null;

		eventPushedMap.clear();
		eventPushedMap = null;

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	private inline function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (inst != null)
		{
			inst.onComplete = finishSong.bind();
			inst.volume = 0;

			inst.play(true);
		}
		if (vocals != null)
		{
			vocals.volume = 0;
			if (SONG.needsVoices)
				vocals.play(true);
		}
		if (coverFade != null)
		{
			var delay:Float = switch (curSong)
			{
				case 'pyromania':
					Conductor.crochet / 2000;
				case 'killgames':
					Conductor.crochet / 250;

				default:
					0;
			};
			var tweenLength:Float = switch (curSong)
			{
				case 'killgames' | 'murked-up':
					Conductor.crochet / 250;
				case 'pyromania':
					(Conductor.crochet * 3.5) / 1000;

				case 'plot-armor':
					(Conductor.crochet / 1000) * 28;
				case 'foursome':
					(Conductor.crochet / 1000) * 24;

				case 'bend-hard':
					(Conductor.crochet / 1000) * 32;
				default:
					0;
			};

			modchartTweens.push(FlxTween.tween(coverFade, {alpha: 0}, tweenLength, {
				onComplete: function(twn:FlxTween)
				{
					coverFade.kill();
					remove(coverFade, true);

					coverFade.destroy();
					coverFade = null;

					cleanupTween(twn);
				},
				ease: FlxEase.quartIn,
				startDelay: delay
			}));
		}
		if (inst != null)
		{
			Conductor.songPosition = inst.time;
			resyncVocals(true, true);
			// Conductor.songPosition = inst.time;

			inst.volume = 1;
		}
		if (vocals != null)
			vocals.volume = 1;
		var startDelay:Float = switch (curSong)
		{
			case 'pyromania' | 'murked-up':
				6;
			case 'foursome' | 'plot-armor' | 'bend-hard':
				24;

			default:
				4;
		};

		if (songCover != null)
		{
			modchartTweens.push(FlxTween.tween(songCover, {x: -songCover.width}, Conductor.crochet / 500, {
				ease: FlxEase.quartIn,
				startDelay: (Conductor.crochet * startDelay) / 1000,
				onComplete: function(twn:FlxTween)
				{
					songCover.kill();
					remove(songCover, true);

					songCover.destroy();
					songCover = null;

					cleanupTween(twn);
				}
			}));
		}
		if (authorGroup != null)
		{
			modchartTweens.push(FlxTween.tween(authorGroup, {x: FlxG.width}, Conductor.crochet / 1000, {
				ease: FlxEase.quartIn,
				startDelay: (Conductor.crochet * startDelay) / 1000,
				onComplete: function(twn:FlxTween)
				{
					authorGroup.kill();
					remove(authorGroup, true);

					authorGroup.destroy();
					authorGroup = null;

					cleanupTween(twn);
				}
			}));
		}

		if (yourStrumline != null)
		{
			modchartTweens.push(FlxTween.tween(yourStrumline, {alpha: 0}, (Conductor.crochet * 4) / 1000, {
				ease: FlxEase.quartInOut,
				startDelay: (Conductor.crochet * 12) / 1000,
				onComplete: function(twn:FlxTween)
				{
					yourStrumline.kill();
					remove(yourStrumline, true);

					yourStrumline.destroy();
					yourStrumline = null;

					cleanupTween(twn);
				}
			}));
		}
		if (shuttleSwingButton != null)
		{
			modchartTweens.push(FlxTween.tween(shuttleSwingButton, {alpha: 0}, (Conductor.crochet * 4) / 1000, {
				ease: FlxEase.quartInOut,
				startDelay: (Conductor.crochet * 24) / 1000,
				onComplete: function(twn:FlxTween)
				{
					shuttleSwingButton.kill();
					remove(shuttleSwingButton, true);
					shuttleSwingButton.destroy();

					shuttleButtonColorSwap = null;
					shuttleSwingButton = null;

					cleanupTween(twn);
				}
			}));
		}
		// hit the shuttle ball
		if (shuttlecock != null)
		{
			shuttlecock.playAnimation(dad);
			shuttlecock.hit();
		}
		if (startOnTime > 0)
			setSongTime(startOnTime - 500);

		startOnTime = 0;
		if (paused)
		{
			inst?.pause();
			vocals?.pause();
		}

		camZooming = true; // curSong != 'tutorial';
		// update(FlxG.elapsed);
		// stepHit();
		// Song duration in a float, useful for the time left feature
		songLength = inst?.length ?? 0.;
		if (timeBar != null)
			modchartTweens.push(FlxTween.tween(timeBar, {"offset.y": 0}, .5, {ease: FlxEase.circOut, onComplete: cleanupTween}));

		update(Conductor.songPosition / 1000);
		stepHit();
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, getFormattedSong(), getHealthIconOf(iconP2, dad), true, songLength);
	}

	public inline function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		trace('finish song please!');

		var finishCallback:Void->Void = endSong; // In case you want to change it in a specific song.
		var delay:Float = 0;

		if (unspawnNotes.length > 0)
		{
			var last:Note = unspawnNotes[unspawnNotes.length - 1];
			delay = Math.abs(Conductor.crochet + (last.strumTime - Conductor.songPosition)) / 1000;
		}

		updateTime = false;
		if (inst != null)
		{
			inst.volume = 0;
			inst.pause();
		}
		if (vocals != null)
		{
			vocals.volume = 0;
			vocals.pause();
		}

		var noteOffset:Int = ClientPrefs.getPref('noteOffset');
		if (ignoreNoteOffset)
		{
			finishCallback();
		}
		else
		{
			finishTimer = new FlxTimer().start((noteOffset / 1000) + delay, function(tmr:FlxTimer)
			{
				finishCallback();
			});
		}
	}

	private function cleanupEndSong(skipTransIn:Bool = false, useValidScore:Bool = true)
	{
		trace('setting mechanics enabled to ' + ClientPrefs.getPref('mechanics'));
		mechanicsEnabled = ClientPrefs.getPref('mechanics');
		if (!transitioning)
		{
			var isValid:Bool = SONG.validScore && useValidScore;
			if (isValid)
			{
				var percent:Float = ratingPercent;
				if (Math.isNaN(percent))
					percent = 0;
				Highscore.saveScore(curSong, songScore, storyDifficulty, percent);
			}

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				if (storyPlaylist.length <= 0)
				{
					cancelMusicFadeTween();
					if (isValid)
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

					ClientPrefs.saveSettings();
					FlxTransitionableState.skipNextTransIn = skipTransIn;

					CustomFadeTransition.nextCamera = FlxTransitionableState.skipNextTransIn ? null : camOther;
					CustomFadeTransition.playTitleMusic = MusicBeatState.coolerTransition = true;

					MusicBeatState.switchState(new StoryMenuState());

					changedDifficulty = false;
					persistentUpdate = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = false;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					SONG = Song.loadFromJson(difficulty, storyPlaylist[0]);
					inst?.stop();

					cancelMusicFadeTween();

					CustomFadeTransition.nextCamera = camOther;
					MusicBeatState.coolerTransition = true;

					LoadingState.loadAndSwitchState(new PlayState());
					persistentUpdate = false;
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');

				FlxTransitionableState.skipNextTransIn = skipTransIn;
				cancelMusicFadeTween();

				CustomFadeTransition.nextCamera = skipTransIn ? null : camOther;
				CustomFadeTransition.playTitleMusic = MusicBeatState.coolerTransition = true;

				FreeplayState.exitToFreeplay();

				changedDifficulty = false;
				persistentUpdate = false;
			}
			transitioning = true;
		}
	}

	private inline function areCutscenesDisabled():Bool
		return #if VIDEOS_ALLOWED Paths.formatToSongPath(ClientPrefs.getPref('cutscenes')) == 'disabled' #else true #end;
	private inline function canPlayStoryCutscene():Bool
	{
		#if VIDEOS_ALLOWED
		var cutsceneMode:String = Paths.formatToSongPath(ClientPrefs.getPref('cutscenes'));
		return !areCutscenesDisabled() && (isStoryMode || cutsceneMode == 'all-songs');
		#else
		return false;
		#end
	}
	private inline function doShitAtTheEnd():Void
	{
		trace('yaaaaay');

		var cutscenesDisabled:Bool = areCutscenesDisabled();
		switch (curSong)
		{
			case 'banana':
			{
				if (!cutscenesDisabled)
					startVideo('minion_fucking_dies', true);
			}
			case 'farting-bars':
			{
				if (!cutscenesDisabled)
					startVideo('billehbawb_loves_fnaf', true);
			}
			case 'braindead':
				{
					switch (!cutscenesDisabled && ClientPrefs.getPref('flashing'))
					{
						case true:
							startVideo('sexy_anthony_1', true);
						default:
							cleanupEndSong();
					}
				}
			case 'pyromania' | 'funny-duo':
				{
					switch (canPlayStoryCutscene())
					{
						case true:
							startVideo(switch (curSong)
							{
								case 'funny-duo':
									'bf_fucking_dies';
								default:
									'animation_pyromania_end';
							}, true);
						default:
							cleanupEndSong();
					}
				}

			default:
				cleanupEndSong();
		}
	}

	private function endSong():Void
	{
		// Should kill you if you tried to cheat
		if (!(startingSong || cpuControlled))
		{
			notes.forEach(function(daNote:Note)
			{
				if (daNote.strumTime < songLength && !daNote.hitCausesMiss)
				{
					health -= daNote.missHealth * healthLoss;
					songMisses++;
				}
			});

			for (daNote in unspawnNotes)
			{
				if (daNote.strumTime < songLength && !daNote.hitCausesMiss)
				{
					health -= daNote.missHealth * healthLoss;
					songMisses++;
				}
			}
			if (doDeathCheck())
				return;
		}
		killShuttlecock(true);
		if (timeBar != null)
			timeBar.visible = false;

		canPause = false;
		endingSong = true;

		camZooming = false;
		inCutscene = false;

		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		var achievement:Achievement = null;
		var fzoneMode:Bool = storyDifficultyText == CoolUtil.defaultDifficulties[0];

		var fzoneSound:FlxSound = null;
		var fzone:FlxSprite = null;

		var lastAchievementHeight:Float = 0;
		var achievementIndex:Int = 0;

		switch (curSong)
		{
			case 'hotshot':
				{
					// i know missing a pass gives you a miss
					if (!cpuControlled && mechanicsEnabled && songMisses <= 0 && totalShitsFailed <= 0)
					{
						trace('total hotshot fc');
						achievement = Achievement.makeAchievement('badminton_champion', camOther);
						if (achievement != null)
						{
							achievementIndex++;
							lastAchievementHeight = achievement.bg.height;
						}
					}
				}

			case 'killgames':
				{
					trace('killed hard');
					achievement = Achievement.makeAchievement('KILL_GAME', camOther);
					if (achievement != null)
					{
						achievementIndex++;
						lastAchievementHeight = achievement.bg.height;
					}
				}
			case 'bend-hard':
				{
					trace('bended hard');

					achievement = Achievement.makeAchievement('the_hard_bend', camOther);
					if (achievement != null)
					{
						achievementIndex++;
						lastAchievementHeight = achievement.bg.height;
					}
				}
		}
		if (isStoryMode)
		{
			campaignMisses += songMisses;
			campaignScore += songScore;

			if (storyMisses != null)
				storyMisses.set(curSong, songMisses);
			storyPlaylist.shift();
			if (storyPlaylist.length <= 0 && !ClientPrefs.getGameplaySetting('botplay', false) && (Paths.formatToSongPath(storyDifficultyText) != Paths.formatToSongPath(CoolUtil.defaultDifficulties[0])))
			{
				var curWeek:String = WeekData.weeksList[storyWeek];
				StoryMenuState.weekCompleted.set(curWeek, true);

				var achievementName:Null<String> = switch (curWeek)
				{
					case 'funny':
						'week1';
					case 'trio':
						'week2';
					case 'blam':
						'unblammy';
					case 'shuttleman':
						'unbshuttlery';

					default:
						null;
				};
				switch (curWeek)
				{
					case 'blam':
						{
							trace('unlock extra shitssssss');

							var unlocked:Array<Bool> = ClientPrefs.getPref('freeplay');
							for (index in 0...FreeplayState.panels.length)
							{
								if (!FreeplayState.freeplaySectionUnlocked(index))
									unlocked[index] = true;
							}
							ClientPrefs.prefs.set('unlocked', unlocked);
						}
				}

				trace(curWeek);
				trace(achievementName);
				trace(campaignMisses);

				if (achievementName != null && campaignMisses <= 0)
				{
					trace('SUPER FC. $achievementName');
					achievement = Achievement.makeAchievement(achievementName, camOther);
					if (achievement != null)
					{
						achievementIndex++;
						lastAchievementHeight = achievement.bg.height;
					}
				}
			}
		}
		if (ClientPrefs.getPref("framerate") == 420)
		{
			trace('GAMER FPS');
			var dopeAchievement:Achievement = Achievement.makeAchievement('WEED', camOther, false, null, null, null, (Achievement.padding + lastAchievementHeight) * achievementIndex);
			if (dopeAchievement != null)
			{
				achievementIndex++;
				lastAchievementHeight = dopeAchievement.bg.height;

				if (achievement == null)
				{
					achievement = dopeAchievement;
				}
				else
				{
					add(dopeAchievement);
				}
			}
		}

		if (fzoneMode)
		{
			fzone = new FlxSprite().loadGraphic(Paths.image('fzone'));

			fzone.antialiasing = ClientPrefs.getPref('globalAntialiasing');
			fzone.cameras = [camOther];

			fzone.setGraphicSize(FlxG.width, FlxG.height);
			fzone.updateHitbox();

			fzone.screenCenter();
			fzone.alpha = 1;

			fzoneSound = new FlxSound().loadEmbedded(Paths.soundRandom('fzone', 1, 7));
			add(fzone);

			var fzoneAchievement:Achievement = Achievement.makeAchievement('benjuu', camOther, false, null, null, null,
				(Achievement.padding + lastAchievementHeight) * achievementIndex);
			if (fzoneAchievement != null)
			{
				achievementIndex++;
				lastAchievementHeight = fzoneAchievement.bg.height;

				if (achievement == null)
				{
					achievement = fzoneAchievement;
				}
				else
				{
					add(fzoneAchievement);
				}
			}
		}
		if (achievement != null)
		{
			if (achievement.finished)
			{
				achievement.destroy();
				achievement = null;

				if (fzoneMode)
				{
					fzoneSound.onComplete = doShitAtTheEnd;
				}
				else
				{
					doShitAtTheEnd();
				}
			}
			else
			{
				if (fzone != null)
				{
					FlxTween.tween(fzone, {alpha: 0}, 2, {
						ease: FlxEase.quartIn,
						onComplete: function(twn:FlxTween)
						{
							fzone.kill();
							remove(fzone, true);

							fzone.destroy();
							fzone = null;
						}
					});
				}

				achievement.onFinish = doShitAtTheEnd;
				add(achievement);
			}
		}
		else if (fzoneMode)
		{
			fzoneSound.onComplete = doShitAtTheEnd;
		}
		else
		{
			doShitAtTheEnd();
		}
		if (fzoneSound != null)
			fzoneSound.play();
		ClientPrefs.saveSettings();
	}

	private function startCountdown():Void
	{
		inCutscene = false;
		isCameraOnForcedPos = false;

		skipCountdown = switch (curSong)
		{
			case 'murked-up' | 'pyromania' | 'plot-armor' | 'foursome' | 'killgames' | 'bend-hard':
				true;
			default:
				false;
		}

		if (skipCountdown || startOnTime > 0)
			skipArrowStartTween = true;

		generateStaticArrows(0);
		generateStaticArrows(1);

		if (secondOpponentStrums != null)
			generateStaticArrows(2);
		startedCountdown = true;

		var introSoundAlts:Array<String> = introSounds.get(introSoundKey ?? 'default');
		var introAlts:Array<String> = introAssets.get(introKey);

		var lastTween:FlxTween = null;

		Conductor.songPosition = startDelay * startPosition;
		if (shuttleSwingButton != null)
			modchartTweens.push(FlxTween.tween(shuttleSwingButton, {alpha: 1, "offset.y": 0}, (Conductor.crochet * 4) / 1000,
				{ease: FlxEase.quartInOut, startDelay: (Conductor.crochet * 2) / 1000, onComplete: cleanupTween}));
		if (shuttlecock != null)
			modchartTweens.push(FlxTween.tween(shuttlecock, {alpha: 1, "offset.y": 0}, (Conductor.crochet * 4) / 1000,
				{ease: FlxEase.quartInOut, startDelay: Conductor.crochet / 1000, onComplete: cleanupTween}));

		if (yourStrumline != null)
		{
			add(yourStrumline);

			yourStrumline.visible = true;
			modchartTweens.push(FlxTween.tween(yourStrumline, {alpha: 1, "offset.y": 0}, (Conductor.crochet * 4) / 1000,
				{ease: FlxEase.quartInOut, startDelay: Conductor.crochet / 1000, onComplete: cleanupTween}));
		}
		if (songCover != null)
		{
			add(songCover);

			songCover.visible = true;
			modchartTweens.push(FlxTween.tween(songCover, {alpha: 1}, Conductor.crochet / 1000, {ease: FlxEase.quintInOut, onComplete: cleanupTween}));
		}

		var startSongDelay:Float = 0;
		if (startOnTime > 0)
		{
			if (inst != null)
				inst.volume = 0;

			clearNotesBefore(startOnTime);
			setSongTime(startOnTime - 350);

			return;
		}
		else
		{
			switch (curSong)
			{
				case 'pyromania' | 'murked-up' | 'plot-armor' | 'foursome' | 'killgames' | 'bend-hard':
					{
						coverFade = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);

						coverFade.cameras = [camOther];
						coverFade.scrollFactor.set();

						coverFade.antialiasing = false;
						if (curStage is Lobby && curStage.staticOverlay != null)
						{
							insert(members.indexOf(curStage.staticOverlay), coverFade);
						}
						else if (songCover != null)
						{
							insert(members.indexOf(songCover), coverFade);
						}
						else
						{
							add(coverFade);
						}
						startSongDelay = -startDelay * 2500;
					}
			}
			if (skipCountdown)
			{
				setSongTime(startSongDelay);
				return;
			}
		}
		countdownImage = new FlxSprite();

		countdownImage.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		countdownImage.scrollFactor.set();

		countdownImage.cameras = [camHUD];
		countdownImage.alpha = 0;

		insert(members.indexOf(notes), countdownImage);
		// So it doesn't lag
		for (alt in introAlts)
			Paths.image(alt, introAssetsLibrary);
		for (shit in introSoundAlts)
			CoolUtil.precacheSound('countdown/$shit', introAssetsLibrary);

		var newAlphaShit:Int = CoolUtil.int(isFNM);
		startTimer = new FlxTimer().start(startDelay, function(tmr:FlxTimer)
		{
			var loopsLeft:Int = tmr.loopsLeft;
			var beat:Int = loopsLeft + 1;

			var loop:Int = tmr.elapsedLoops - 1;
			var imageCount:Int = loop - 1;

			groupDance(gfGroup, beat);
			groupDance(boyfriendGroup, beat);
			groupDance(dadGroup, beat);

			// stageDance(beat);
			if (curStage != null)
				curStage.beatHit(beat);
			if (!isFNM)
				iconBop(beat);
			if ((imageCount >= 0 && imageCount < introAlts.length) && countdownImage != null)
			{
				countdownImage.loadGraphic(Paths.image(introAlts[imageCount], introAssetsLibrary));
				// FUCK HAXEFLIXEL
				if (lastTween != null && !lastTween.finished)
				{
					lastTween.cancel();
					cleanupTween(lastTween);
					lastTween = null;
				}

				countdownImage.updateHitbox();
				countdownImage.screenCenter();

				countdownImage.alpha = 1;
				var tween:FlxTween = FlxTween.tween(countdownImage, {alpha: newAlphaShit}, Conductor.crochet / 1000, {
					ease: ease,
					onComplete: function(twn:FlxTween)
					{
						if (loopsLeft <= 0)
						{
							countdownImage.alpha = 0;
							remove(countdownImage, true);
							countdownImage.destroy();
						}
						lastTween = null;
						cleanupTween(twn);
					}
				});

				modchartTweens.push(tween);
				lastTween = tween;
			}
			if (loop < introSoundAlts.length)
			{
				var snd:Sound = Paths.sound('countdown/'
					+
					((introSoundKey == null && loop == 0 && FlxG.random.bool(33)) ? 'lesscoolthree' : introSoundAlts[loop]) /* introSoundPrefix + 'intro' + (loopsLeft <= 0 ? 'Go' : Std.string(loopsLeft)) + introAssetsSuffix */,
					introAssetsLibrary);
				if (snd != null)
					FlxG.sound.play(snd, .6, false);
			}
		}, 4);
	}

	public inline function cancelMusicFadeTween()
	{
		if (inst != null)
		{
			if (inst.fadeTween != null)
			{
				inst.fadeTween.cancel();
				inst.fadeTween.destroy();
			}
			inst.fadeTween = null;
		}
	}

	// HEALTH
	public function doDeathCheck(?skipHealthCheck:Bool = false):Bool
	{
		if ((skipHealthCheck || health <= 0) && !isDead)
		{
			trace('im dying ,.........help me');

			killShuttlecock(true);
			boyfriend.stunned = true;
			if (!chartingMode)
				deathCounter++;

			paused = true;

			inst?.stop();
			vocals?.stop();

			persistentUpdate = false;
			persistentDraw = false;

			if (cameraTwn != null)
				cameraTwn.active = false;

			for (tween in modchartTweens)
				cleanupTween(tween);
			for (timer in modchartTimers)
				cleanupTimer(timer);
			#if VIDEOS_ALLOWED
			for (video in modchartVideos)
				cleanupVideo(video);
			#end

			var deathGuy:Character = getCurrentlyControlling();

			GameOverSubstate.characterName = deathGuy.getDeathAnimation();
			DiscordClient.changePresence('Game Over - $detailsText', getFormattedSong(false), getHealthIconOf(iconP2, dad));

			switch (Paths.formatToSongPath(deathGuy.curCharacter))
			{
				case 'fartingbear':
					openSubState(new JumpscareSubstate());
				default:
					{
						if (isFNM)
						{
							cleanupEndSong(true, false);
						}
						else
						{
							openSubState(new GameOverSubstate(deathGuy.getScreenPosition().x - deathGuy.positionArray[0],
							deathGuy.getScreenPosition().y - deathGuy.positionArray[1], camFollowPos.x, camFollowPos.y));
						}
					}
			}
			isDead = true;
			return true;
		}
		return false;
	}

	// UI
	private inline function reloadHealthBarColors()
	{
		if (healthBar != null)
		{
			if (isFNM)
			{
				healthBar.updateHealthColor(FNM_PLAYER_COLOR, FNM_ENEMY_COLOR);
			}
			else
			{
				var p1Character:Character = getCurrentlyControlling();
				var p2Character:Character = dad;

				if (curStage is Candy && curStage.evilBeast != null && evilFocused)
					p2Character = curStage.evilBeast;
				healthBar.updateHealthColor(p1Character.healthColorArray, p2Character.healthColorArray);
			}
		}
		updateTimeColor();
	}

	private inline function updateTimeColor()
	{
		if (updateTime && timeBar != null)
		{
			var section:SwagSection = SONG.notes[curSection];
			if (section != null)
				timeBar.updateTimeColor((section.gfSection && gf != null) ? gf.healthColorArray : (section.mustHitSection ? getCurrentlyControlling().healthColorArray : dad.healthColorArray));
		}
	}

	private inline function updateScore(noZoom:Bool = false)
	{
		if (scoreTxt != null)
		{
			scoreTxt.text = getFormattedRating();
			if (ClientPrefs.getPref('scoreZoom') && !isFNM && !noZoom)
			{
				if (scoreTxtTween != null)
				{
					scoreTxtTween.cancel();
					cleanupTween(scoreTxtTween);
					scoreTxtTween = null;
				}

				scoreTxt.scale.x = 1.075;
				scoreTxt.scale.y = scoreTxt.scale.x;

				scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, .2, {
					onComplete: function(twn:FlxTween)
					{
						cleanupTween(twn);
						scoreTxtTween = null;
					}
				});
			}
		}
	}

	private function popUpScore(note:Note = null):Void
	{
		if (vocals != null)
			vocals.volume = 1;

		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.getPref('ratingOffset'));
		// tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff);
		var score:Int = daRating.score;

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;

		if (!note.ratingDisabled)
			daRating.increase();
		note.rating = daRating.name;
		if (!cpuControlled)
		{
			songScore += score;
			if (!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;

				recalculateRating();
			}
		}

		if (isFNM)
			return;
		if (daRating.noteSplash && !note.noteSplashDisabled)
			spawnNoteSplashOnNote(note);
		if (ClientPrefs.getPref('hideHUD'))
			return;

		var newGroup:ComboRating = comboGroup.recycle(ComboRating);
		if (comboGroup.members.contains(newGroup))
			comboGroup.remove(newGroup, true);

		newGroup.setupGroup();
		if (showCombo && combo >= 10)
			newGroup.showComboSprite();
		if (showRating)
			newGroup.showRatingSprite(daRating);
		if (showComboNum)
			newGroup.showComboNums(combo);

		comboGroup.add(newGroup);
		newGroup.startGroup();
	}

	// INPUT
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		// trace('Pressed: ' + eventKey);
		if (!(cpuControlled || paused)
			&& key > -1
			&& (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.getPref('controllerMode')))
		{
			if (!(boyfriend.stunned || endingSong) && generatedMusic)
			{
				// more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				if (inst != null)
					Conductor.songPosition = inst.time;

				var canMiss:Bool = !ClientPrefs.getPref('ghostTapping') || isFNM;

				var sortedNotesList:Array<Note> = [];
				var pressNotes:Array<Note> = [];

				notes.forEachAlive(function(daNote:Note)
				{
					if (strumsBlocked[daNote.noteData] != true
						&& daNote.canBeHit
						&& daNote.mustPress
						&& !daNote.tooLate
						&& !daNote.wasGoodHit
						&& !daNote.isSustainNote
						&& !daNote.blockHit)
					{
						if (daNote.noteData == key)
							sortedNotesList.push(daNote);
						canMiss = true;
					}
				});

				if (sortedNotesList.length > 0)
				{
					if (sortedNotesList.length > 1)
						sortedNotesList.sort(sortHitNotes);

					var notesStopped:Bool = false;
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes)
						{
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
							{
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							}
							else
							{
								notesStopped = true;
								break;
							}
						}
						if (notesStopped)
							break;

						goodNoteHit(epicNote);
						pressNotes.push(epicNote);
					}
				}
				else if (canMiss)
				{
					noteMissPress(key);
				}
				Conductor.songPosition = lastTime;
			}

			var strumNote:StrumNote = playerStrums.members[key];
			if (strumsBlocked[key] != true && strumNote != null && strumNote.animation.curAnim.name != 'confirm')
			{
				strumNote.playAnim('pressed');
				strumNote.resetAnim = 0;
			}
		}
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (!cpuControlled && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
		}
		// trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
						return i;
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		var controllerMode:Bool = ClientPrefs.getPref('controllerMode');
		// HOLDING
		var parsedHoldArray:Array<Bool> = parseKeys(PRESSED);
		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (controllerMode)
		{
			var parsedArray:Array<Bool> = parseKeys(JUST_PRESSED);
			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] && strumsBlocked[i] != true)
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}
		// FlxG.watch.addQuick('asdfa', upP);
		if (!boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (strumsBlocked[daNote.noteData] != true
					&& daNote.isSustainNote
					&& parsedHoldArray[daNote.noteData]
					&& daNote.canBeHit
					&& daNote.mustPress
					&& !daNote.tooLate
					&& !daNote.wasGoodHit
					&& !daNote.blockHit)
					goodNoteHit(daNote);
			});
			if (!endingSong)
				bfDance();
		}
		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (controllerMode || strumsBlocked.contains(true))
		{
			var parsedArray:Array<Bool> = parseKeys(JUST_RELEASED);
			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] || strumsBlocked[i] == true)
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	private inline function parseKeys(?state:FlxInputState):Array<Bool>
		return [
			for (i in 0...controlArray.length)
				PlayerSettings.controls.is(controlArray[i], state)
		];

	// NOTES
	private function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (cpuControlled && (note.ignoreNote || note.hitCausesMiss))
				return;

			var formattedNoteType:String = Paths.formatToSongPath(note.noteType);
			var leData:Int = Std.int(Math.abs(note.noteData));

			if (Hitsound.canPlayHitsound()
				&& !(note.hitsoundDisabled || isFNM || (hitsoundsPlayed != null && hitsoundsPlayed.contains(leData))))
			{
				Hitsound.play();
				if (hitsoundsPlayed != null)
					hitsoundsPlayed.push(leData);
			}

			var chars:Array<Character> = [note.gfNote ? gf : getCurrentlyControlling()];
			if (note.hitCausesMiss)
			{
				noteMiss(note);
				quickUpdatePresence();

				if (!note.noteSplashDisabled && !note.isSustainNote)
					spawnNoteSplashOnNote(note);
				switch (formattedNoteType)
				{
					case 'horse-cheese-note': // horse cheese note
						{
							totalShitsFailed++;
							shitsFailedLol++;

							if (dad.animOffsets.exists('horsecheese'))
							{
								dad.playAnim('horsecheese', true);
								dad.specialAnim = true;
							}
							modchartTimers.push(new FlxTimer().start(1 / 20, function(tmr:FlxTimer)
							{
								if (horseImages != null)
								{
									var roll:FlxGraphic = FlxG.random.getObject(horseImages);
									var width = FlxG.width * FlxG.random.float(.4, .8);

									var horsey:FlxSprite = new FlxSprite().loadGraphic(roll);
									FlxG.sound.play(Paths.sound("ANGRY"), 1);

									horsey.setGraphicSize(Std.int(width), Std.int(width * FlxG.random.float(.1, 2)));
									horsey.cameras = [camOther];

									horsey.antialiasing = ClientPrefs.getPref('globalAntialiasing');

									horsey.updateHitbox();
									horsey.screenCenter();

									horsey.y += (FlxG.height / 2) * FlxG.random.float(-1, 1);
									horsey.x += (FlxG.width / 2) * FlxG.random.float(-1, 1);

									horsey.angle = FlxG.random.int(-360, 360);

									horsey.flipY = FlxG.random.bool(20);
									horsey.flipX = FlxG.random.bool();

									horsey.alpha = FlxG.random.float(.9);
									add(horsey);

									modchartTweens.push(FlxTween.tween(horsey, {alpha: 0}, FlxG.random.float(5, 20), {
										ease: FlxEase.sineInOut,
										onComplete: function(twn:FlxTween)
										{
											shitsFailedLol--;
											horsey.kill();

											remove(horsey, true);
											horsey.destroy();

											cleanupTween(twn);
										}
									}));
								}
								if (boyfriend.animOffsets.exists('hurt'))
								{
									boyfriend.playAnim('hurt', true);
									boyfriend.specialAnim = true;
								}
								cleanupTimer(tmr);
							}));
						}
					case 'trickynote':
						{
							trace('kill bf NOW!');
							// just fucking kill him
							shitsFailedLol += GameOverSubstate.neededShitsFailed;
							totalShitsFailed++;

							health = -1;
							doDeathCheck(true);

							FlxG.sound.play(Paths.sound('death', 'clown'));
						}
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo = Std.int(Math.min(combo + 1, 9999));
				popUpScore(note);
			}
			health += note.hitHealth * healthGain;

			var isEndNote:Bool = note.animation.curAnim.name.endsWith('end');
			if (!note.noAnimation)
			{
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + switch (formattedNoteType)
				{
					case 'alt-animation':
						note.animSuffix;
					default:
						'';
				};

				if (!isEndNote)
				{
					var didPlay:Bool = false;
					for (char in chars)
					{
						var thisCharPlayed:Bool = playCharacterAnim(char, animToPlay, note);
						didPlay = didPlay || thisCharPlayed;
					}
					if (didPlay)
						playerDelta = getNoteDataPoint(leData);
				}
				if (formattedNoteType == 'hey')
				{
					if (boyfriend.animOffsets.exists('hey'))
					{
						boyfriend.playAnim('hey', true);

						boyfriend.specialAnim = true;
						boyfriend.heyTimer = .6;
					}
					if (gf != null && gf.animOffsets.exists('cheer'))
					{
						gf.playAnim('cheer', true);

						gf.specialAnim = true;
						gf.heyTimer = .6;
					}
				}
			}

			if (cpuControlled)
			{
				var time:Float = .15;
				if (note.isSustainNote && !isEndNote)
					time += .15;

				playStrumAnim(0, Std.int(Math.abs(note.noteData)), time);
			}
			else
			{
				var spr = playerStrums.members[note.noteData];
				if (spr != null)
					spr.playAnim(isFNM ? 'pressed' : 'confirm', true);
			}

			note.wasGoodHit = true;
			if (vocals != null)
				vocals.volume = 1;
			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
		quickUpdatePresence();
	}

	private inline function getCurrentlyControlling():Character
		return if (curStage is Carnival && curStage.eggbob != null && eggbobFocused) curStage.eggbob else boyfriend;
	private inline function doNoteMissShit(direction:Int = 1):Void
	{
		if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			gf.playAnim('sad');

		combo = 0;
		songScore -= 10;

		if (!endingSong)
			songMisses++;

		totalPlayed++;
		recalculateRating(true);

		switch (isFNM)
		{
			case true:
				FlxG.sound.play(Paths.sound('fnm_missnote', 'fnm'), .5);
			default:
				{
					if (vocals != null)
						vocals.volume = 0;
					FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(.1, .2));
				}
		}

		var theMisserInQuestion:Character = getCurrentlyControlling();
		if (theMisserInQuestion.hasMissAnimations)
		{
			var missAnimation:String = singAnimations[Std.int(Math.abs(direction))] + 'miss';
			if (theMisserInQuestion.animOffsets.exists(missAnimation))
				theMisserInQuestion.playAnim(missAnimation, true);
		}
		quickUpdatePresence();
	}

	private function noteMiss(daNote:Note):Void
	{
		// You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note remove
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note
				&& daNote.mustPress
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		health -= daNote.missHealth * healthLoss;
		doNoteMissShit(daNote.noteData);
	}

	private function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		if (ClientPrefs.getPref('ghostTapping') && !isFNM)
			return;
		if (!getCurrentlyControlling().stunned)
		{
			health -= .05 * healthLoss;
			doNoteMissShit(direction);
		}
	}

	private function opponentNoteHit(note:Note):Void
	{
		var formattedNoteType:String = Paths.formatToSongPath(note.noteType);
		var isAlternative:Bool = false;

		var strumsHit:Array<Int> = [1];
		var isEndNote:Bool = note.animation.curAnim.name.endsWith('end');

		if (formattedNoteType == 'hey')
		{
			switch (dad.curCharacter)
			{
				case 'exTricky':
					{
						dad.playAnim('Hank', true);

						dad.specialAnim = true;
						dad.heyTimer = Conductor.crochet / 1000;
					}
				default:
					{
						if (dad.animOffsets.exists('hey'))
						{
							dad.playAnim('hey', true);

							dad.specialAnim = true;
							dad.heyTimer = .6;
						}
					}
			}
		}
		else if (!note.noAnimation)
		{
			var chars:Array<Character> = [dad];
			var altAnim:String = '';

			var section:SwagSection = SONG.notes[curSection];
			if (section != null)
			{
				if ((section.altAnim || formattedNoteType == 'alt-animation') && !section.gfSection)
					altAnim = note.animSuffix;
			}
			switch (formattedNoteType)
			{
				case 'trio-note':
					{
						chars = [];
						switch (curSong)
						{
							case 'foursome':
								{
									if (foursomeFrame != null && foursomeFrame.type >= 0)
										chars = [foursomeFrame.bottomCharacter];
								}
							default:
								chars = [trioOpponent];
						}
					}
				case 'duo-note' | 'both-opponents-note':
					{
						var isDuoNote:Bool = formattedNoteType == 'duo-note';
						if (isDuoNote)
							chars = [];
						switch (curSong)
						{
							case 'foursome':
								{
									if (isDuoNote && foursomeFrame != null && foursomeFrame.type >= 0)
										chars = [foursomeFrame.topCharacter];
								}

							case 'squidgames':
								{
									isAlternative = true;
									if (curStage is Squidgame)
										chars.push(curStage.pinkSoldier);

									if (isDuoNote)
										strumsHit = [];
									strumsHit.push(2);
								}
							case 'pyromania':
								{
									isAlternative = true;
									if (curStage is Hell)
										chars.push(curStage.itsAHorse);
								}
							case 'abrasive' | 'bend-hard':
								chars.push(duoOpponent);
						}
					}
			}

			var didPlay:Bool = false;
			if (note.gfNote)
			{
				chars = [gf];
			}
			else if (curStage is Candy && curStage.evilBeast != null && evilFocused)
			{
				chars = [curStage.evilBeast];
			}
			if (!isEndNote)
			{
				var leData:Int = Std.int(Math.abs(note.noteData));
				for (char in chars)
				{
					if (char != null)
					{
						var thisCharPlayed:Bool = playCharacterAnim(char, singAnimations[leData] + altAnim, note);
						didPlay = didPlay || thisCharPlayed;
					}
				}
				if (didPlay)
				{
					var camDelta:FlxPoint = getNoteDataPoint(leData);
					if (isAlternative && secondOpponentDelta != null)
					{
						secondOpponentDelta = camDelta;
					}
					else
					{
						opponentDelta = camDelta;
					}
				}
			}
			switch (curSong)
			{
				case 'roided':
					{
						if (!ClientPrefs.getPref('reducedMotion') && (didPlay || isEndNote))
						{
							var shakeMultiplier:Float = note.isSustainNote ? .8 : isEndNote ? .4 : 1;

							gameZoomAdd += shakeMultiplier / 128;
							hudZoomAdd += shakeMultiplier / 86;

							camGame.shake((1 / 180) * shakeMultiplier, Conductor.stepCrochet / 1000);
							camHUD.shake((1 / 240) * shakeMultiplier, Conductor.stepCrochet / 1000);
						}
					}
			}
		}

		if (vocals != null)
			vocals.volume = 1;
		var time:Float = .15;

		if (note.isSustainNote && !isEndNote)
			time *= 2;
		if (mechanicsEnabled)
		{
			var difficultyClamp = Math.max(storyDifficulty, 1);

			var fixedDrain:Float = healthDrain * (difficultyClamp / 3);
			var fixedDrainCap:Float = healthDrainCap / difficultyClamp;

			var drainDiv:Dynamic = healthDrainMap.exists(curSong) ? healthDrainMap.get(curSong) : null;
			if (drainDiv != null && drainDiv[1] <= storyDifficulty && !note.isSustainNote)
			{
				var divider:Float = drainDiv[0];
				if (health > fixedDrainCap)
					health = Math.max(health - ((fixedDrain / divider) * healthLoss), fixedDrainCap);
			}
		}

		if (curStage != null && curStage is AuditorHell && dad != null && Paths.formatToSongPath(dad.curCharacter) == 'extricky')
		{
			if (FlxG.random.bool(60) && curStage.spookyText == null && curStage.spookySteps < curStep && !note.isSustainNote)
			{
				curStage.spookySteps = curStep + 3;
				curStage.generateSpookyText();
			}
		}
		if (!ClientPrefs.getPref('reducedMotion'))
		{
			switch (curSong)
			{
				case 'opposition':
					{
						var stepCrochet:Float = Conductor.stepCrochet / 1000;

						camGame.shake(1 / 200, stepCrochet);
						camHUD.shake(1 / 120, stepCrochet);
					}
			}
		}

		for (strum in strumsHit)
			playStrumAnim(strum, Std.int(Math.abs(note.noteData)), time);

		note.hitByOpponent = true;
		if (!note.isSustainNote) // does this cause a memory leka i got no ucking clue
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	private inline function playStrumAnim(player:Int, id:Int, time:Float)
	{
		var strumLine:FlxTypedGroup<StrumNote> = switch (player)
		{
			case 2:
				worldStrumLineNotes;
			case 1:
				strumLineNotes;

			default:
				playerStrums;
		};

		var spr:StrumNote = strumLine.members[id];
		if (spr != null)
		{
			spr.playAnim(isFNM ? 'pressed' : 'confirm', true);
			spr.resetAnim = time;
		}
	}

	public inline function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;

				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			i--;
		}

		i = notes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;

				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			i--;
		}
	}

	public inline function setSongTime(time:Float)
	{
		if (inst != null && time >= 0 && time < inst.length)
		{
			inst.play(true);
			inst.time = time;
		}
		if (SONG.needsVoices && vocals != null && time >= 0 && time < vocals.length)
		{
			vocals.play(true);
			vocals.time = time;
		}

		Conductor.songPosition = time;
		songTime = time;
	}

	private function triggerEventNote(eventName:String, value1:String, value2:String, strum:Float)
	{
		switch (Paths.formatToSongPath(eventName))
		{
			case 'hey':
				{
					var time:Float = Std.parseFloat(value2);
					var value:Int = switch (Paths.formatToSongPath(value1))
					{
						case 'gf' | 'girlfriend' | '1':
							1;
						case 'bf' | 'boyfriend' | '0':
							0;

						default:
							2;
					};

					if (Math.isNaN(time) || time <= 0)
					{
						time = Conductor.crochet / 1000;
					}
					else
					{
						time *= Conductor.crochet / 1000;
					}

					if (value != 0)
					{
						var characterAnimation:Character = dad.curCharacter.startsWith('gf') ? dad : gf;
						characterAnimation.playAnim('cheer', true);

						characterAnimation.specialAnim = true;
						characterAnimation.heyTimer = time;
					}
					if (value != 1)
					{
						boyfriend.playAnim('hey', true);

						boyfriend.specialAnim = true;
						boyfriend.heyTimer = time;
					}
				}
			case 'horse':
				{
					if (curStage is Hell)
					{
						var horsePlatform:BGSprite = curStage.horsePlatform;
						var itsAHorse:Character = curStage.itsAHorse;

						if (itsAHorse != null && horsePlatform != null)
						{
							var horseY:Float = DAD_Y + (FlxG.height * 3);
							if (value1.toLowerCase().startsWith('true'))
							{
								horsePlatform.y = horseY;

								horsePlatform.alpha = 1;
								itsAHorse.alpha = 1;

								modchartTweens.push(FlxTween.tween(horsePlatform, {y: 1300}, Conductor.crochet / 250, {
									ease: FlxEase.backOut,
									onComplete: cleanupTween,
									onUpdate: function(twn:FlxTween)
									{
										var shakeShit:Float = (1 - twn.percent) * .02;

										camGame.shake(shakeShit, Conductor.stepCrochet / 1000);
										camHUD.shake(shakeShit / 2, Conductor.stepCrochet / 1000);
									}
								}));
							}
							else if (itsAHorse != null && horsePlatform != null)
							{
								modchartTweens.push(FlxTween.tween(horsePlatform, {y: horseY}, Conductor.crochet / 250, {
									ease: FlxEase.backIn,
									onComplete: function(twn:FlxTween)
									{
										itsAHorse.kill();
										horsePlatform.kill();

										remove(itsAHorse, true);
										remove(horsePlatform, true);

										itsAHorse = null;
										horsePlatform = null;

										cleanupTween(twn);
									}
								}));
							}
						}
					}
				}

			case 'set-gf-speed':
				{
					var value:Int = Std.parseInt(value1);
					if (Math.isNaN(value) || value1.length <= 0)
						value = 1;
					gfSpeed = value;
				}

			case 'add-camera-zoom':
				{
					if (canZoomCamera())
					{
						var camZoomAdding:Float = Std.parseFloat(value1);
						var hudZoomAdding:Float = Std.parseFloat(value2);

						if (Math.isNaN(camZoomAdding) || value1.length <= 0)
							camZoomAdding = GAME_BOP;
						if (Math.isNaN(hudZoomAdding) || value2.length <= 0)
							hudZoomAdding = HUD_BOP;

						gameZoomAdd += camZoomAdding;
						hudZoomAdd += hudZoomAdding;
					}
				}
			#if VIDEOS_ALLOWED
			case 'play-video':
				{
					var video:Null<VideoSprite> = videos.shift();
					if (video != null)
					{
						var videoBackground:FlxSprite = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
						var killingLikeTheGames:Bool = false;

						videoBackground.screenCenter();
						videoBackground.scrollFactor.set();

						videoBackground.antialiasing = false;
						videoBackground.cameras = video.cameras;

						video.alpha = videoBackground.alpha = 0;
						video.graphicLoadedCallback = function()
						{
							video.updateHitbox();
							video.screenCenter();
						}
						video.finishCallback = function()
						{
							if (videoBackground != null && !killingLikeTheGames)
							{
								killingLikeTheGames = true;
								modchartTweens.push(FlxTween.tween(videoBackground, {alpha: 0}, .5, {
									ease: FlxEase.quintOut,
									onComplete: function(twn:FlxTween)
									{
										videoBackground.kill();
										remove(videoBackground, true);

										videoBackground.destroy();
										videoBackground = null;

										cleanupTween(twn);
									}
								}));
							}
							video.finishCallback = null;
							cleanupVideo(video);
						}

						add(videoBackground);
						add(video);

						video.revive();
						video.playVideo(Paths.video(value1), false, false);

						video.bitmap.canUseSound = false;

						modchartTweens.push(FlxTween.tween(videoBackground, {alpha: 1}, .5, {ease: FlxEase.quintOut, onComplete: cleanupTween}));
						modchartTweens.push(FlxTween.tween(video, {alpha: 1}, .5, {ease: FlxEase.quintOut, onComplete: cleanupTween}));

						modchartVideos.push(video);
					}
				}
			case 'stop-videos':
				{
					for (video in modchartVideos)
						cleanupVideo(video);
				}
			#end

			case 'vignette':
				{
					if (vignetteImage != null)
					{
						var enabled:Bool = value1.toLowerCase().startsWith('true');
						if (vignetteEnabled != enabled)
						{
							if (vignetteTween != null)
							{
								vignetteTween.cancel();
								vignetteTween.destroy();

								vignetteTween = null;
							}

							vignetteEnabled = enabled;
							modchartTweens.push(vignetteTween = FlxTween.tween(vignetteImage, {alpha: CoolUtil.int(enabled)}, Conductor.crochet / 500,

								{ease: FlxEase.quartOut, onComplete: cleanupTween}));
						}
					}
				}

			case 'extend-timer':
				{
					if (timerExtensions != null)
					{
						timerExtensions.shift();

						var next:Dynamic = timerExtensions[0];
						var toValue:Float = (next != null && next > 0) ? next : songLength;
						// maskedSongLength = value; instead of tweenMask.bind(timeTxt)
						modchartTweens.push(FlxTween.num(maskedSongLength, toValue, Conductor.crochet / 1000, {
							ease: FlxEase.sineOut,
							onComplete: function(twn:FlxTween)
							{
								maskedSongLength = toValue;
								cleanupTween(twn);
							}
						}, function(value:Float) {
							maskedSongLength = value;
						}));
					}
				}
			case 'subtitles':
				{
					if (subtitlesTxt != null && ClientPrefs.getPref('subtitles'))
					{
						if (subtitlesTwn != null)
						{
							cleanupTween(subtitlesTwn);
							subtitlesTwn = null;
						}
						if (value1.length > 0)
						{
							var char:Character = switch (Paths.formatToSongPath(value2))
							{
								case 'trio' | 'trio-opponent':
									trioOpponent;
								case 'duo' | 'duo-opponent':
									duoOpponent;

								case 'gf' | 'girlfriend':
									gf;
								case 'dad' | 'opponent':
									dad;

								default:
									boyfriend;
							};
							subtitlesTxt.text = value1;

							subtitlesTxt.updateHitbox();
							subtitlesTxt.screenCenter();

							var subtitlesY:Float = ((healthBar?.bar?.height ?? 0.) + (scoreTxt?.height ?? 0.) + subtitlesTxt.borderSize) * 2;
							var subtitlesSize:Float = subtitlesTxt.size;

							subtitlesTxt.y = switch (ClientPrefs.getPref('downScroll'))
							{
								default:
									FlxG.height - subtitlesSize - subtitlesY - subtitlesTxt.height;
								case true:
									subtitlesY + (subtitlesSize * 1.5);
							};

							if (char == gf && gf == null)
							{
								subtitlesTxt.color = 0xFFA5004D;
							}
							else
							{
								var color:FlxColor = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
								switch (curSong)
								{
									case 'bend-hard':
										{
											// i have to do it like this becauase haxe sucks fat dick
											if (char == trioOpponent)
											{
												color = 0xFFFFEBBA;
											}
											else if (char == duoOpponent)
											{
												color = 0xFFBFCDFF;
											}
											else if (char == dad)
											{
												color = 0xFFF9BBBB;
											}
										}
									case 'foursome':
										{
											if (curStage is Carnival && curStage.eggbob != null && eggbobFocused && char == boyfriend)
											{
												var healthColorArray:Array<Int> = curStage.eggbob.healthColorArray;
												color = FlxColor.fromRGB(healthColorArray[0], healthColorArray[1], healthColorArray[2]);
											}
											else if (char == dad && foursomeFrame != null && foursomeFrame.type >= 0)
											{
												color = switch (foursomeFrame.type) {
													default: 0xFF5BAFE0;
													case 1: 0xFF030387;
												};
											}
										}
								}
								subtitlesTxt.color = color;
							}

							final baseColor:FlxColor = subtitlesTxt.color;
							final invertedColor:FlxColor = baseColor.getInverted().getComplementHarmony();

							final brightness:Float = ((baseColor.red + baseColor.green + baseColor.blue) / 3) / 255;

							subtitlesTxt.borderColor = if (brightness < .5) invertedColor.getLightened(1 - (brightness * .5)) else invertedColor.getDarkened(brightness);
							subtitlesTxt.alpha = .8;

							subtitlesTxt.visible = true;
							add(subtitlesTxt);
						}
						else
						{
							modchartTweens.push(subtitlesTwn = FlxTween.tween(subtitlesTxt, { alpha: 0 }, Conductor.crochet / 500, { ease: FlxEase.linear, onComplete: function(twn:FlxTween) {
								subtitlesTxt.visible = false;

								remove(subtitlesTxt, true);
								cleanupTween(twn);

								subtitlesTwn = null;
							} }));
						}
					}
				}

			case 'shoot':
				{
					var canShake:Bool = !ClientPrefs.getPref('reducedMotion');
					var duration:Float = Conductor.stepCrochet / 1000;

					if (curSong != 'bend-hard')
						FlxG.sound.play(Paths.sound('gunshot'), .7).setPosition(dad.x, dad.y);
					if (ClientPrefs.getPref('flashing'))
						camHUD.flash(0x3FFFFFFF, duration * 2, null, true);

					if (canShake)
					{
						gameZoomAdd += 1 / 25;
						hudZoomAdd += 1 / 50;

						camGame.shake(1 / 160, duration, null, true);
						camHUD.shake(1 / 90, duration, null, true);
					}
					if (mechanicsEnabled && FlxG.random.bool(shootChance))
					{
						if (health > shootHealthCap)
						{
							health = switch (curSong)
							{
								default:
									Math.max(health * (FlxG.random.float(.85, .95) * FlxMath.lerp(1, .8, Math.max(storyDifficulty / 2, 0))), shootHealthCap);
								case 'bend-hard':
									Math.max(health * FlxG.random.float(.8, .85), shootHealthCap);
							}
						}
						if (boyfriend.animOffsets.exists('hurt'))
						{
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
						FlxG.sound.play(Paths.sound('ANGRY'), .7).setPosition(boyfriend.x, boyfriend.y);
					}
				}
			case 'get-gun-out':
				{
					if (curStage is BendHard)
						curStage.whipOutGun();
				}

			case 'roid':
				{
					var value:Float = Std.parseFloat(value2);

					var defaultBeats:Float = 4;
					var beats:Float = (Math.isNaN(value) || value <= 0) ? defaultBeats : value;

					var multiplier:Float = Math.min((beats / defaultBeats) * (Math.PI / 2), 1);
					if (mechanicsEnabled)
					{
						health = Math.max(health
							- ((healthDrain * storyDifficulty * multiplier * 2) * (1 - (Math.min(combo / Math.max(50 * storyDifficulty, 1), 1) * .9))),

							healthDrainCap / storyDifficulty);
					}

					var side:Bool = roid;
					var str:String = Paths.formatToSongPath(value1);

					if (str.length > 0)
						side = str.startsWith('true');

					var duration:Float = (Conductor.crochet * beats) / 1000;
					if (!ClientPrefs.getPref('reducedMotion'))
					{
						gameZoomAdd += (1 / 16) * multiplier;
						hudZoomAdd += (1 / 32) * multiplier;

						if (camHUDTwn != null)
						{
							camHUDTwn.cancel();
							cleanupTween(camHUDTwn);
							camHUDTwn = null;
						}
						if (camGameTwn != null)
						{
							camGameTwn.cancel();
							cleanupTween(camGameTwn);
							camGameTwn = null;
						}

						camHUD.angle = 1 * (side ? 1 : -1);
						camGame.angle = -camHUD.angle;

						camGame.x += camGame.angle * 8 * (FlxG.random.bool() ? -1 : 1);
						camGame.y += camHUD.angle * 8 * (FlxG.random.bool() ? -1 : 1);

						camHUD.y += camGame.angle * 4 * (FlxG.random.bool() ? -1 : 1);
						camHUD.x += camHUD.angle * 4 * (FlxG.random.bool() ? -1 : 1);

						camGameTwn = FlxTween.tween(camGame, {x: 0, y: 0, angle: 0}, duration, {
							ease: FlxEase.quartOut,
							onComplete: function(twn:FlxTween)
							{
								cleanupTween(twn);
								camGameTwn = null;
							}
						});
						camHUDTwn = FlxTween.tween(camHUD, {x: 0, y: 0, angle: 0}, duration, {
							ease: FlxEase.quartOut,
							onComplete: function(twn:FlxTween)
							{
								cleanupTween(twn);
								camHUDTwn = null;
							}
						});
					}
					if (ClientPrefs.getPref('flashing'))
					{
						var gradient:FlxSprite = FlxGradient.createGradientFlxSprite(Std.int(FlxG.width * .8 * multiplier), FlxG.height,
							[FlxColor.RED, FlxColor.TRANSPARENT], 1, roid ? 180 : 0, false);

						gradient.cameras = [camOther];
						gradient.scrollFactor.set();

						gradient.updateHitbox();
						gradient.screenCenter(Y);

						gradient.alpha = .75 * multiplier;
						camGame.flash(FlxColor.fromRGBFloat(1, 0, 0, gradient.alpha / 3), duration, null, true);

						if (roid)
							gradient.x = FlxG.width - gradient.width;

						add(gradient);
						modchartTweens.push(FlxTween.tween(gradient, {alpha: 0}, duration, {
							ease: FlxEase.quartOut,
							onComplete: function(twn:FlxTween)
							{
								gradient.kill();
								remove(gradient, true);

								gradient.destroy();
								gradient = null;

								cleanupTween(twn);
							}
						}));
					}
					roid = !side;
				}
			case 'foursome-lights':
				{
					if (ClientPrefs.getPref('flashing'))
					{
						var args:Array<String> = value2.split(',');

						var tweenTimeString:Null<String> = args[1];
						var tweenTime:Float = 2;

						if (tweenTimeString != null)
						{
							var parsedTweenTime:Float = Std.parseFloat(tweenTimeString.trim());
							if (!Math.isNaN(parsedTweenTime))
								tweenTime = parsedTweenTime;
						}
						if (tweenTime > 0)
						{
							var angle:Float = Std.parseFloat(value1);

							var lightLength:Int = foursomeLightColors.length - 1;
							var color:Int = FlxG.random.int(0, lightLength);

							var colorString:Null<String> = args[0];
							if (colorString != null)
							{
								var trimmedColor:String = colorString.trim();
								if (trimmedColor.length > 0)
								{
									var parsedColor:Int = Std.parseInt(trimmedColor);
									if (!Math.isNaN(parsedColor) && parsedColor > -1)
										color = Std.int(FlxMath.bound(parsedColor, 0, lightLength));
								}
							}
							// use this twice because . Fuck
							var selectedColor:FlxColor = foursomeLightColors[color];
							var gradient:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [selectedColor, FlxColor.TRANSPARENT,], 8,
								Std.int(((Math.isNaN(angle) ? 0 : angle) % 4) * 90), true);

							gradient.screenCenter();
							gradient.alpha = .65;

							gradient.scrollFactor.set();
							gradient.cameras = [camHUD];

							add(gradient);
							modchartTweens.push(FlxTween.tween(gradient, {alpha: 0}, (Conductor.crochet * tweenTime) / 1000, {
								onComplete: function(twn:FlxTween)
								{
									gradient.kill();
									remove(gradient, true);

									gradient.destroy();
									gradient = null;

									cleanupTween(twn);
								}
							}));
						}
					}
				}
			case 'foursome-frame':
				{
					if (foursomeFrame != null)
					{
						var parsed:Int = Std.parseInt(value1);
						foursomeFrame.type = (Math.isNaN(parsed) || value1.length <= 0) ? -1 : parsed;
					}
				}

			case 'set-shuttle-beats':
				{
					var value:Float = Std.parseFloat(value1);
					if (newNextShuttleBeats != null)
					{
						if (!Math.isNaN(value) && value > 0)
						{
							if (!newNextShuttleBeats.contains(value))
								newNextShuttleBeats.push(value);
						}
						else
						{
							trace('shuttle beat val $value');
							destroyShuttleOnNextHit = true;
						}
					}
				}
			case 'set-zoom-type':
				{
					var beats:Int = Std.parseInt(value2);
					var type:Int = Std.parseInt(value1);

					camZoomType = Math.isNaN(type) ? 0 : Std.int(Math.min(type, camZoomTypes.length - 1));
					camZoomTypeBeatOffset = Math.isNaN(beats) ? 0 : beats;
				}

			case 'change-default-zoom':
				{
					var value:Float = Std.parseFloat(value1);
					var split:Array<String> = value2.split(',');

					var beats:Float = Std.parseFloat(split[0]);

					var zoomAmount:Float = (Math.isNaN(value) || value1.length <= 0) ? 0 : value;
					var newZoom:Float = stageData.defaultZoom + zoomAmount;

					if (defaultCamZoom != newZoom)
					{
						if (cameraTwn != null)
						{
							cameraTwn.cancel();
							cleanupTween(cameraTwn);
							cameraTwn = null;
						}
						defaultCamZoom = newZoom;
						if (!Math.isNaN(beats))
						{
							if (beats > 0)
							{
								var start:Float = gameZoom;

								var ease:Dynamic = FlxEase.quartIn;
								var name:String = split[1];

								if (name != null)
								{
									name = name.trim();
									if (name.length > 0 && Reflect.hasField(FlxEase, name))
										ease = Reflect.field(FlxEase, name);
								}
								cameraTwn = FlxTween.num(start, newZoom, (Conductor.crochet / 1000) * beats, {
									ease: ease,
									onComplete: function(twn:FlxTween)
									{
										gameZoom = newZoom;
										camGame.zoom = newZoom + gameZoomAdd;

										defaultCamZoom = stageData.defaultZoom + zoomAmount;

										cleanupTween(twn);
										cameraTwn = null;
									}
								}, function(value:Float) {
									gameZoom = value;
									// might be necessary idk super.update() is called after the camzoom function so lol
									camGame.zoom = gameZoom + gameZoomAdd;
								});
							}
							else
							{
								gameZoom = newZoom;
							}
						}
					}
				}
			case 'change-character-visibility':
				{
					var visibility:String = value2.toLowerCase();
					var char:Character = switch (Paths.formatToSongPath(value1))
					{
						case 'gf' | 'girlfriend':
							gf;
						case 'dad' | 'opponent':
							dad;

						default:
							boyfriend;
					};
					char.visible = visibility.length <= 1 || visibility.startsWith('true');
				}

			case 'legalize-nuclear-bombs':
				{
					if (legalize != null)
					{
						legalize.alpha = .5;
						legalize.animation.play('bomb');

						modchartTweens.push(FlxTween.tween(legalize, {alpha: 0}, Conductor.crochet / 250, {
							ease: FlxEase.sineIn,
							onComplete: function(twn:FlxTween)
							{
								legalize.kill();
								remove(legalize, true);

								legalize.destroy();
								legalize = null;

								cleanupTween(twn);
							}
						}));
					}
				}

			case 'nod-camera':
				{
					noddingCamera = Paths.formatToSongPath(value1).startsWith('true');
					if (!noddingCamera)
						nodRight = false;
				}
			case 'funny-duo':
				{
					if (!ClientPrefs.getPref('lowQuality'))
					{
						var current:Int = Std.parseInt(value1);
						switch (current)
						{
							// moyai
							case 0:
								{
									var moyai:FlxSprite = new FlxSprite().loadGraphic(Paths.image('goofy/moyai'));

									moyai.cameras = [camHUD];
									moyai.setGraphicSize(Std.int(moyai.width * 2));

									moyai.updateHitbox();
									moyai.screenCenter();

									moyai.antialiasing = ClientPrefs.getPref('globalAntialiasing');
									moyai.alpha = 1;

									add(moyai);
									modchartTweens.push(FlxTween.tween(moyai, {alpha: 0, "scale.x": moyai.scale.x * 2, "scale.y": moyai.scale.y * 2},
										Conductor.crochet / 250, {
											ease: FlxEase.sineOut,
											onComplete: function(twn:FlxTween)
											{
												moyai.kill();
												remove(moyai, true);

												moyai.destroy();
												moyai = null;

												cleanupTween(twn);
											}
										}));
								}
							// goofy ass countdown
							case 1 | 2 | 3:
								{
									var countdownAlpha:Float = Std.parseFloat(value2);
									if (Math.isNaN(countdownAlpha))
										countdownAlpha = 1;

									var goofy:GoofyCountdown = goofyAww.recycle(GoofyCountdown);
									goofy.cameras = [camHUD];

									goofy.loadGraphic(Paths.image('goofy/$current'));
									goofy.setGraphicSize(Std.int(goofy.width * FlxG.random.float(.7, .9)), Std.int(goofy.height * FlxG.random.float(.5, .8)));

									goofy.angle = FlxG.random.float(-10, 10);

									goofy.updateHitbox();
									goofy.screenCenter();

									goofy.antialiasing = ClientPrefs.getPref('globalAntialiasing');
									goofy.alpha = countdownAlpha;

									goofyAww.add(goofy);
								}
						}
					}
				}
			case 'foolish-type-beat':
				{
					if (!ClientPrefs.getPref('lowQuality'))
					{
						var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');
						switch (Std.parseInt(value1))
						{
							// mission passed
							case 0:
								{
									var missionPassed:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mission_passed'));

									missionPassed.antialiasing = globalAntialiasing;
									missionPassed.cameras = [camOther];

									missionPassed.screenCenter();
									missionPassed.alpha = 0;

									add(missionPassed);
									modchartTweens.push(FlxTween.tween(missionPassed, {alpha: 1}, Conductor.crochet / 1000, {
										ease: FlxEase.linear,
										onComplete: function(twn:FlxTween)
										{
											modchartTimers.push(new FlxTimer().start((Conductor.crochet / 1000) * 10.5, function(tmr:FlxTimer)
											{
												missionPassed.kill();
												remove(missionPassed, true);

												missionPassed.destroy();
												missionPassed = null;

												cleanupTimer(tmr);
											}));
											cleanupTween(twn);
										}
									}));
								}
							// ron
							case 1:
								{
									var ron:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ron'));

									ron.antialiasing = globalAntialiasing;
									ron.cameras = [camOther];

									ron.screenCenter();
									add(ron);

									modchartTimers.push(new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
									{
										ron.kill();
										remove(ron, true);

										ron.destroy();
										ron = null;

										cleanupTimer(tmr);
									}));
								}
							// calebcity
							case 2:
								{
									if (pizza != null)
									{
										pizza.animation.play('pizza', true);
										pizza.alpha = 1;

										modchartTweens.push(FlxTween.tween(pizza, {alpha: 0}, Conductor.crochet / 250, {
											onComplete: function(twn:FlxTween)
											{
												pizza.kill();
												remove(pizza, true);

												pizza.destroy();
												pizza = null;

												cleanupTween(twn);
											}
										}));
									}
								}
							// funny
							case 3:
								{
									var funny:FlxSprite = new FlxSprite().loadGraphic(Paths.image('background'), -2230, -1360);
									var wiggle:GlitchEffect = new GlitchEffect();

									wiggle.waveAmplitude = .1;
									wiggle.waveFrequency = 5;
									wiggle.waveSpeed = 2;

									funny.antialiasing = globalAntialiasing;
									funny.cameras = [camGame];

									funny.shader = wiggle.shader;
									funny.setGraphicSize(Std.int(funny.width * 2));

									funny.updateHitbox();
									funny.screenCenter();

									shaders.push(wiggle);
									insert(members.indexOf(dadGroup), funny);

									gfGroup.visible = false;
									if (curStage != null)
										curStage.kill();

									modchartTimers.push(new FlxTimer().start(Conductor.crochet / 250, function(tmr:FlxTimer)
									{
										funny.kill();
										remove(funny, true);

										funny.destroy();
										funny = null;

										shaders.remove(wiggle);
										wiggle = null;

										gfGroup.visible = true;
										if (curStage != null)
											curStage.revive();
										cleanupTimer(tmr);
									}));
								}
						}
					}
				}

			case 'flash-camera':
				{
					if (ClientPrefs.getPref('flashing'))
					{
						var duration:Float = Std.parseFloat(value1);
						var color:String = value2;

						if (color.length > 1)
						{
							if (!color.startsWith('0x'))
								color = '0xFF$color';
						}
						else
						{
							color = "0xFFFFFFFF";
						}
						camOther.flash(Std.parseInt(color), Math.isNaN(duration) || value1.length <= 0 ? 1 : duration, null, true);
					}
				}
			case 'cover-camera':
				{
					var color:String = value1;
					var fadeShit:Array<String> = value2.split(',');

					var duration:Float = (Std.parseFloat(fadeShit[0].trim()) * Conductor.crochet) / 1000;
					var delay:Float = 0;

					var delayStr:String = fadeShit[1];
					if (delayStr != null)
					{
						delay = Std.parseFloat(delayStr.trim());
						if (Math.isNaN(delay))
							delay = 0;

						delay *= Conductor.crochet;
						delay /= 1000;
					}

					var ease:Dynamic = FlxEase.linear;
					var name:String = fadeShit[2];

					if (name != null)
					{
						name = name.trim();
						if (name.length > 0 && Reflect.hasField(FlxEase, name))
							ease = Reflect.field(FlxEase, name);
					}

					if (color.length > 1)
					{
						if (!color.startsWith('0x'))
							color = '0xFF$color';
					}
					else
					{
						color = "0xFF000000";
					}
					if (cameraCover != null)
					{
						cameraCover.kill();
						remove(cameraCover, true);
						cameraCover.destroy();
					}

					var thisCover:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, Std.parseInt(color));

					thisCover.cameras = [camOther];
					thisCover.scrollFactor.set();

					thisCover.antialiasing = false;
					cameraCover = thisCover;

					if (duration <= 0 && delay > 0)
					{
						add(thisCover);
						modchartTimers.push(new FlxTimer().start(delay, function(tmr:FlxTimer)
						{
							if (cameraCover == thisCover && thisCover != null)
							{
								thisCover.kill();
								remove(thisCover, true);

								thisCover.destroy();
								thisCover = null;

								cameraCover = null;
							}
							cleanupTimer(tmr);
						}));
					}
					else if (duration > 0)
					{
						add(thisCover);
						modchartTweens.push(FlxTween.tween(cameraCover, {alpha: 0}, duration, {
							ease: ease,
							startDelay: delay,
							onComplete: function(twn:FlxTween)
							{
								if (cameraCover == thisCover && thisCover != null)
								{
									thisCover.kill();
									remove(thisCover, true);

									thisCover.destroy();
									thisCover = null;

									cameraCover = null;
								}
								cleanupTween(twn);
							}
						}));
					}
					else
					{
						add(thisCover);
					}
				}

			case 'play-sound':
				{
					try
					{
						var sound:Dynamic = Reflect.field(this, value1);
						if (sound != null && sound is FlxSound)
							sound.play(true);
					}
					catch (e:Dynamic)
					{
						trace('Unknown sound tried to be played - $e');
					}
				}

			case 'shift-note-rotation':
				{
					if (mechanicsEnabled)
					{
						var lastAngle:Float = (noteGearShift * 90) % 360;
						for (strumNote => strumTween in strumNoteTweens)
						{
							strumTween.cancel();
							cleanupTween(strumTween);

							strumNote.coolOffsetX = strumNote.coolOffsetY = 0;
							strumNoteTweens.remove(strumNote);
						}

						var val1:Int = Std.parseInt(value1);
						if (value1.length <= 0 || Math.isNaN(val1))
						{
							noteGearShift = (noteGearShift % 4) + 1;

							shitsFailedLol += GameOverSubstate.neededShitsFailed;
							totalShitsFailed++;

							strumLineNotes.forEachAlive(function(strumNote:StrumNote)
							{
								var invert:Float = strumNote.player > 0 ? 1 : -1;
								strumNote.angle = lastAngle * invert;

								var thisTwn:FlxTween = FlxTween.tween(strumNote, {angle: noteGearShift * 90 * invert}, Conductor.crochet / 500, {
									ease: FlxEase.quartIn,
									onUpdate: function(twn:FlxTween)
									{
										var scale:Float = twn.scale + .25;
										var scaleMult:Float = ((scale > .5) ? Math.max(1 - scale, 0) : scale) * 10;

										strumNote.coolOffsetX = (FlxG.random.bool() ? -1 : 1) * scaleMult;
										strumNote.coolOffsetY = (FlxG.random.bool() ? -1 : 1) * scaleMult;
									},
									onComplete: function(twn:FlxTween)
									{
										strumNote.coolOffsetX = strumNote.coolOffsetY = 0;
										if (strumNoteTweens.exists(strumNote))
											strumNoteTweens.remove(strumNote);
										cleanupTween(twn);
									}
								});

								modchartTweens.push(thisTwn);
								strumNoteTweens[strumNote] = thisTwn;
							});
						}
						else
						{
							totalShitsFailed = 0;
							shitsFailedLol = 0;

							noteGearShift = val1 % 4;
							strumLineNotes.forEachAlive(function(strumNote:StrumNote)
							{
								var invert:Float = strumNote.player > 0 ? 1 : -1;

								strumNote.angle = noteGearShift * 90 * invert;
								strumNote.coolOffsetX = strumNote.coolOffsetY = 0;
							});
						}
					}
				}

			case 'relapse-spikes':
				{
					if (curStage is Relapse)
						curStage.showSpikes();
				}
			case 'relapse-float':
				{
					if (curStage is Relapse && !crazyShitMode)
					{
						crazyShitMode = true;
						curStage.startRisingInTheSky();
					}
				}

			case 'relapse-pixelation':
				{
					if (curStage is Relapse)
						curStage.togglePixelation(value1.toLowerCase().startsWith('true'));
				}
			case 'relapse-chromatic-aberration':
				{
					if (curStage is Relapse)
					{
						var chromaticAberration:Null<ChromaticAberrationEffect> = curStage.chromaticAberration;
						if (chromaticAberration != null)
						{
							var amount:Float = Std.parseFloat(value1);
							if (Math.isNaN(amount) || value1.length <= 0)
								amount = Relapse.DEFAULT_CHROMATIC_ABERRATION;

							var args:Array<String> = value2.split(',');

							var durationString:Null<String> = args[0];
							var duration:Float = Std.parseFloat(durationString);

							if (aberrationTwn != null)
							{
								aberrationTwn.cancel();
								cleanupTween(aberrationTwn);
								aberrationTwn = null;
							}
							if (duration <= 0 || durationString == null || durationString.length <= 0)
							{
								chromaticAberration.strength = amount;
							}
							else
							{
								var easingString:Null<String> = args[1];
								var easing:Dynamic = Reflect.field(FlxEase, easingString?.trim() ?? null) ?? FlxEase.linear;

								modchartTweens.push(aberrationTwn = FlxTween.tween(chromaticAberration, {strength: amount},
									(Conductor.crochet / 1000) * duration, {
										ease: easing,
										onComplete: function(twn)
										{
											cleanupTween(twn);
											aberrationTwn = null;
										}
									}));
							}
						}
					}
				}
			case 'relapse-crt-distortion':
				{
					if (curStage is Relapse)
					{
						var crtDistortion:Null<CRTDistortionEffect> = curStage.crtDistortion;
						if (crtDistortion != null)
						{
							var amount:Float = Std.parseFloat(value1);
							if (Math.isNaN(amount) || value1.length <= 0)
								amount = Relapse.DEFAULT_CRT_DISTORTION;

							var args:Array<String> = value2.split(',');

							var durationString:Null<String> = args[0];
							var duration:Float = Std.parseFloat(durationString);

							if (crtDistortionTwn != null)
							{
								crtDistortionTwn.cancel();
								cleanupTween(crtDistortionTwn);
								crtDistortionTwn = null;
							}
							if (duration <= 0 || durationString == null || durationString.length <= 0)
							{
								crtDistortion.distortionFactor = amount;
							}
							else
							{
								var easingString:Null<String> = args[1];
								var easing:Dynamic = Reflect.field(FlxEase, easingString?.trim() ?? null) ?? FlxEase.linear;

								modchartTweens.push(crtDistortionTwn = FlxTween.tween(crtDistortion, {distortionFactor: amount},
									(Conductor.crochet / 1000) * duration, {
										ease: easing,
										onComplete: function(twn)
										{
											cleanupTween(twn);
											crtDistortionTwn = null;
										}
									}));
							}
						}
					}
				}

			case 'killgames-static-transparency':
				{
					if (curStage is Lobby)
					{
						var staticOverlay:Null<FlxSprite> = curStage.staticOverlay;
						if (staticOverlay != null)
						{
							var amount:Float = Std.parseFloat(value1);
							if (Math.isNaN(amount) || value1.length <= 0)
								amount = Lobby.DEFAULT_STATIC_ALPHA;

							var args:Array<String> = value2.split(',');

							var durationString:Null<String> = args[0];
							var duration:Float = Std.parseFloat(durationString);

							if (curStage.staticOverlayTwn != null)
							{
								curStage.staticOverlayTwn.cancel();
								cleanupTween(curStage.staticOverlayTwn);
								curStage.staticOverlayTwn = null;
							}
							if (duration <= 0 || durationString == null || durationString.length <= 0)
							{
								staticOverlay.alpha = amount;
							}
							else
							{
								var easingString:Null<String> = args[1];
								var easing:Dynamic = Reflect.field(FlxEase, easingString?.trim() ?? null) ?? FlxEase.linear;

								modchartTweens.push(curStage.staticOverlayTwn = FlxTween.tween(staticOverlay, {alpha: amount},
									(Conductor.crochet / 1000) * duration, {
										ease: easing,
										onComplete: function(twn)
										{
											cleanupTween(twn);
											curStage.staticOverlayTwn = null;
										}
									}));
							}
						}
					}
				}
			case 'killgames-murder':
				{
					if (curStage is Candy)
						curStage.killEvilBeast();
				}

			case 'play-animation':
				{
					// trace('Anim to play: ' + value1);
					var char:Character = switch (Paths.formatToSongPath(value2))
					{
						case 'bf' | 'boyfriend':
							boyfriend;
						case 'gf' | 'girlfriend':
							gf;

						default:
							{
								var val2:Int = Std.parseInt(value2);
								if (Math.isNaN(val2))
									val2 = 0;
								switch (val2)
								{
									case 1:
										boyfriend;
									case 2:
										gf;

									default:
										dad;
								}
							}
					}

					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'camera-follow-pos':
				{
					if (camFollow != null)
					{
						var val1:Float = Std.parseFloat(value1);
						var val2:Float = Std.parseFloat(value2);

						isCameraOnForcedPos = false;
						if (!(Math.isNaN(val1) || value1.length <= 0) || !(Math.isNaN(val2) || value2.length <= 0))
						{
							if (Math.isNaN(val1))
								val1 = 0;
							if (Math.isNaN(val2))
								val2 = 0;

							camFollow.x = val1;
							camFollow.y = val2;

							isCameraOnForcedPos = true;
						}
					}
				}
			case 'alt-idle-animation':
				{
					var char:Character = switch (Paths.formatToSongPath(value1))
					{
						case 'boyfriend' | 'bf':
							boyfriend;
						case 'gf' | 'girlfriend':
							gf;

						default:
							{
								var val:Int = Std.parseInt(value1);
								if (Math.isNaN(val))
									val = 0;
								switch (val)
								{
									case 1:
										boyfriend;
									case 2:
										gf;

									default:
										dad;
								}
							}
					}

					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'sustain-shake':
				{
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);

					if (Math.isNaN(val1))
						val1 = 0;
					if (Math.isNaN(val2))
						val2 = 0;

					gameShakeAmount = val1;
					hudShakeAmount = val2;

					doSustainShake();
				}
			case 'screen-shake':
				{
					if (!ClientPrefs.getPref('reducedMotion'))
					{
						var valuesArray:Array<String> = [value1, value2];
						var targetsArray:Array<FlxCamera> = [camGame, camHUD];

						for (i in 0...targetsArray.length)
						{
							var split:Array<String> = valuesArray[i].split(',');

							var intensity:Float = 0;
							var duration:Float = 0;

							if (split[0] != null)
								duration = (Conductor.crochet * Std.parseFloat(split[0].trim())) / 1000;
							if (split[1] != null)
								intensity = Std.parseFloat(split[1].trim());

							if (Math.isNaN(duration))
								duration = 0;
							if (Math.isNaN(intensity))
								intensity = 0;

							if (duration > 0 && intensity != 0)
								targetsArray[i].shake(intensity, duration);
						}
					}
				}

			case 'toggle-cervix-wavy-shader':
				{
					if (curStage is Plains)
						curStage.toggleWavy(Paths.formatToSongPath(value1).startsWith('true'));
				}

			case 'change-character':
				{
					var charType:Int = switch (Paths.formatToSongPath(value1))
					{
						case 'gf' | 'girlfriend':
							2;
						case 'dad' | 'opponent':
							1;

						default:
							{
								var temp:Int = Std.parseInt(value1);
								Math.isNaN(temp) ? 0 : temp;
							}
					}
					var characterPositioning:Character = switch (charType)
					{
						case 1:
							dad;
						case 2:
							gf;

						default:
							boyfriend;
					}
					if (characterPositioning != null)
					{
						var iconCharacter:Character = characterPositioning;
						var forceChange:Bool = characterPositioning.curCharacter != value2;

						switch (charType)
						{
							default:
								characterPositioning.setPosition(GF_X, GF_Y);

							case 0:
								{
									if (curStage is Carnival)
									{
										if (duoOpponent != null && ((value2 == duoOpponent.curCharacter && !eggbobFocused) || (value2 == boyfriend.curCharacter && eggbobFocused)))
										{
											curStage.enterEggbob();
											eggbobFocused = value2 == duoOpponent.curCharacter;

											if (eggbobFocused)
												iconCharacter = duoOpponent;
											forceChange = false;
										}
										else if (forceChange)
										{
											forceChange = false;

											characterPositioning.setPosition(BF_X, BF_Y);
											characterPositioning.setCharacter(value2);

											startCharacterPos(characterPositioning);
											switch (value2)
											{
												case 'funnybf-guitar':
													{
														trace('push youtooz bf');
														modchartTweens.push(FlxTween.tween(
															characterPositioning,
															{ x: characterPositioning.x - 300 },
															Conductor.crochet / 1000,
															{ ease: FlxEase.quintOut, onComplete: cleanupTween }
														));
														dad.visible = false;
													}
												default:
													{
														dad.visible = true;
													}
											}
										}
									}
									else
									{
										characterPositioning.setPosition(BF_X, BF_Y);
									}
								}
							case 1:
								{
									switch (Type.getClass(curStage))
									{
										case Candy:
										{
											if (duoOpponent != null && ((value2 == duoOpponent.curCharacter && !evilFocused) || (value2 == dad.curCharacter && evilFocused)))
											{
												curStage.enterEvil();
												evilFocused = value2 == duoOpponent.curCharacter;

												if (evilFocused)
													iconCharacter = duoOpponent;
												forceChange = false;
											}
										}
										default:
										{
											if (dad.curCharacter != value2)
											{
												if (gf == null || dad.curCharacter != gf.curCharacter)
												{
													if (gf != null)
														gf.visible = true;
													characterPositioning.setPosition(DAD_X, DAD_Y);
												}
												else
												{
													if (gf != null)
														gf.visible = false;
													characterPositioning.setPosition(GF_X, GF_Y);
												}
											}
											if (duoOpponent != null)
											{
												duoOpponent.setPosition(DAD_X + DUO_X, DAD_Y + DUO_Y);
												duoOpponent.setCharacter(value2.endsWith('youtooz') ? 'funnybf' : 'funnybf-youtooz');

												startCharacterPos(duoOpponent);
											}
										}
									}
								}
						}
						if (forceChange)
						{
							characterPositioning.setCharacter(value2);
							startCharacterPos(characterPositioning, characterPositioning == dad);
						}
						var iconChanging:HealthIcon = switch (charType)
						{
							default:
								null;

							case 0:
								iconP1;
							case 1:
								iconP2;
						};
						if (iconChanging != null)
						{
							iconChanging.changeIcon(iconCharacter.healthIcon);
							reloadHealthBarColors();
						}
					}
				}
			case 'change-stage':
				{
					if (stages.length > 0)
					{
						var stageShit:Array<Dynamic> = stages.shift();

						var stageFile:StageFile = stageShit[1];
						var newStage:Dynamic = stageShit[0];
						// TODO: foursome change stage will have custom tween shit n whatnot
						var lastStage:Dynamic = curStage;
						Paths.setCurrentLevel(stageFile?.directory ?? '');

						stageData = stageFile;
						curStage = newStage;

						var forceDifferent:Bool = false;
						inline function murder()
						{
							setupStageShit();

							moveCameraSection();
							snapCamFollowToPos(camFollow.x, camFollow.y);

							if (dad != null)
							{
								dad.setPosition(DAD_X, DAD_Y);
								startCharacterPos(dad, true);
							}
							if (boyfriend != null)
							{
								boyfriend.setPosition(BF_X, BF_Y);
								startCharacterPos(boyfriend);
							}

							newStage.onStageAdded();
							postStageShit();

							if (lastStage != null)
							{
								lastStage.kill();
								if (stageUpdates.contains(lastStage))
									stageUpdates.remove(lastStage);

								stageGroup.remove(lastStage, true);
								lastStage.destroy();
							}

							newStage.revive();
							stageUpdates.push(newStage);
						}
						switch (Paths.formatToSongPath(value2))
						{
							case 'start-a':
								{
									if (lastStage is Carnival && newStage is ParkFront)
									{
										isCameraOnForcedPos = true;
										snapCamFollowToPos(1200, -1000);

										boyfriendGroup.visible = dadGroup.visible = gfGroup.visible = false;
										iconAlpha = 0;

										newStage.doAirShit(true);
										modchartTimers.push(new FlxTimer().start((Conductor.crochet * 60) / 1000, function(tmr:FlxTimer)
										{
											isCameraOnForcedPos = false;

											snapCamFollowToPos(1350, -800);
											moveCamera(true);

											boyfriendGroup.visible = dadGroup.visible = gfGroup.visible = true;
											iconAlpha = 1;

											newStage.doAirShit(false);
										}));
									}
								}
							case 'start-b':
								{
									if (lastStage is Park && newStage is Carnival)
									{
										forceDifferent = true;

										trace('YAY YAY YIPPEE WOOOOOOOOOOOOOOW');
										inline function shakey()
										{
											camGame.shake(1 / 250, Conductor.stepCrochet / 500, null, true);
											camHUD.shake(1 / 500, Conductor.stepCrochet / 500, null, true);
										}
										if (!ClientPrefs.getPref('reducedMotion'))
										{
											shakey();
											modchartTimers.push(new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
											{
												shakey();
												trace(tmr.loopsLeft);
												if (tmr.loopsLeft <= 0)
													cleanupTimer(tmr);
											}, 12));
										}

										modchartTweens.push(FlxTween.tween(this, {iconAlpha: 0}, Conductor.crochet / 1000,
											{ease: FlxEase.quintOut, onComplete: cleanupTween}));
										modchartTimers.push(new FlxTimer().start((Conductor.crochet * 10) / 1000, function(tmr:FlxTimer)
										{
											trace('tween out');
											final tweenTime:Float = Conductor.crochet / 250;

											isCameraOnForcedPos = true;
											lastStage.tweenOut(tweenTime);

											var previousX:Float = camFollowPos.x;
											var previousY:Float = camFollowPos.y;

											var newX:Float = 900;
											var newY:Float = 1150;

											var previousZoom:Float = defaultCamZoom;
											var newZoom:Float = 10;

											function snapShit(value:Float)
												snapCamFollowToPos(FlxMath.lerp(previousX, newX, value), FlxMath.lerp(previousY, newY, value));
											function zoomShit(value:Float)
											{
												gameZoom = value;
												// might be necessary idk super.update() is called after the camzoom function so lol
												camGame.zoom = gameZoom + gameZoomAdd;
											}

											modchartTweens.push(FlxTween.tween(boyfriend, {y: boyfriend.y + Park.SUPER_OFFSET_Y}, tweenTime,
												{ease: Park.SUPER_TWEEN_EASING, onComplete: cleanupTween}));
											modchartTweens.push(FlxTween.tween(dad, {y: dad.y + Park.SUPER_OFFSET_Y}, tweenTime,
												{ease: Park.SUPER_TWEEN_EASING, onComplete: cleanupTween}));

											modchartTweens.push(FlxTween.num(0, 1, tweenTime, {
												ease: FlxEase.quintIn,
												onComplete: function(twn:FlxTween)
												{
													boyfriend.setCharacter('funnybf-playable');
													iconP1?.changeIcon(boyfriend.healthIcon);

													dad.setCharacter('funnybf-youtooz');
													iconP2?.changeIcon(dad.healthIcon);

													reloadHealthBarColors();

													murder();
													moveCamera(true);

													newStage.tweenIn(tweenTime * .5);

													previousX = 500;
													previousY = -1200;

													newX = camFollow.x;
													newY = camFollow.y;

													snapCamFollowToPos(previousX, previousY);

													modchartTweens.push(FlxTween.tween(this, {iconAlpha: 1}, tweenTime * .5, {onComplete: cleanupTween}));
													modchartTweens.push(FlxTween.num(0, 1, tweenTime * .5, {
														ease: FlxEase.quintOut,
														onComplete: function(twn:FlxTween)
														{
															isCameraOnForcedPos = false;
															cleanupTween(twn);
														}
													}, snapShit));
													cleanupTween(twn);
												}
											}, snapShit));
											cameraTwn = FlxTween.num(previousZoom, newZoom, tweenTime, {
												ease: FlxEase.quintIn,
												onComplete: function(twn:FlxTween)
												{
													previousZoom = newZoom;
													newZoom = stageFile.defaultZoom + .5;

													cameraTwn = FlxTween.num(previousZoom, newZoom, tweenTime * .25, {
														ease: FlxEase.quintOut,
														onComplete: function(twn:FlxTween)
														{
															cleanupTween(twn);
															cameraTwn = null;
														}
													}, zoomShit);
													cleanupTween(twn);
												},
											}, zoomShit);
											cleanupTimer(tmr);
										}));
									}
								}
						}
						if (!forceDifferent)
						{
							murder();
							trace('...RAAAH');
						}
					}
				}
			case 'change-scroll-speed':
				{
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);

					if (Math.isNaN(val1) || value1.length <= 0)
						val1 = 1;
					if (Math.isNaN(val2) || value2.length <= 0)
						val2 = 0;

					var newValue:Float = switch (songSpeedType)
					{
						default:
							SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;
						case "constant":
							ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;
					}

					if (val2 <= 0)
					{
						songSpeed = newValue;
					}
					else
					{
						songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, (Conductor.crochet * val2) / 1000, {
							ease: FlxEase.quintIn,
							onComplete: function(twn:FlxTween)
							{
								cleanupTween(twn);
								songSpeedTween = null;
							}
						});
					}
				}
			case 'change-strumline-visibility':
				{
					var strumShit:String = Paths.formatToSongPath(value1);

					var args:Array<String> = value2.split(',');
					var alpha:Float = if (Paths.formatToSongPath(args[0]).startsWith('true')) 1 else 0;

					var beatsString:Null<String> = args[1];
					var beats:Float = Std.parseFloat(beatsString != null && beatsString.length > 0 ? beatsString.trim() : null);

					beats = Math.isNaN(beats) ? -1 : beats;

					var fuck:Dynamic;
					inline function cleanTweens(strumline:FlxTypedGroup<StrumNote>)
					{
						for (strumThing in strumlineTweens)
						{
							if (strumThing[0] == strumline)
							{
								var tweens:Map<Int, FlxTween> = strumThing[1];
								for (i => twn in tweens)
								{
									twn.cancel();
									cleanupTween(twn);
									tweens.remove(i);
								}
								strumlineTweens.remove(strumThing);
							}
						}
					}

					var middleScroll:Bool = ClientPrefs.getPref('middleScroll');
					if (beats > 0)
					{
						var ease:Dynamic = FlxEase.linear;
						var name:String = args[2];

						if (name != null)
						{
							name = name.trim();
							if (name.length > 0 && Reflect.hasField(FlxEase, name))
								ease = Reflect.field(FlxEase, name);
						}
						fuck = function(strumline:FlxTypedGroup<StrumNote>)
						{
							cleanTweens(strumline);

							var strumMap:Map<Int, FlxTween> = new Map();
							var strumPush:Array<Dynamic> = [strumline, strumMap];

							strumline.forEach(function(note:StrumNote)
							{
								var i:Int = note.ID;
								var twn:FlxTween = FlxTween.tween(note, {alpha: alpha * (if (strumline == opponentStrums && middleScroll) MIDDLESCROLL_OPPONENT_TRANSPARENCY else 1)}, (Conductor.crochet / 1000) * beats, {
									ease: ease,
									onComplete: function(thisTween:FlxTween)
									{
										if (strumMap[i] == thisTween)
										{
											strumMap.remove(i);
											if (strumlineTweens.contains(strumPush) && Lambda.count(strumMap) <= 0)
												strumlineTweens.remove(strumPush);
										}
										cleanupTween(thisTween);
									}
								});
								if (strumMap.exists(i))
								{
									var shit:FlxTween = strumMap[i];

									shit.cancel();
									strumMap.remove(i);

									cleanupTween(shit);
								}

								modchartTweens.push(twn);
								strumMap[i] = twn;
							});
							strumlineTweens.push(strumPush);
						}
					}
					else
					{
						fuck = function(strumline:FlxTypedGroup<StrumNote>)
						{
							cleanTweens(strumline);
							strumline.forEach(function(note:StrumNote)
							{
								note.alpha = alpha * (if (strumline == opponentStrums && middleScroll) MIDDLESCROLL_OPPONENT_TRANSPARENCY else 1);
							});
						}
					}
					switch (strumShit)
					{
						default:
							fuck((strumShit == 'dad') ? opponentStrums : playerStrums);
						case 'both' | 'all':
							{
								fuck(opponentStrums);
								fuck(playerStrums);
							}
					}
				}
		}
	}

	private inline function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var event:EventNote = eventNotes[0];
			if (event == null)
				break;

			var leStrumTime:Float = event.strumTime;
			if (Conductor.songPosition < leStrumTime)
				break;

			triggerEventNote(event.event, event?.value1?.trim() ?? '', event?.value2?.trim() ?? '', leStrumTime);
			eventNotes.remove(event);
		}
	}

	private inline function spawnNoteSplashOnNote(note:Note)
	{
		if (ClientPrefs.getPref('noteSplashes') && !isFNM && note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	private inline function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		var skin:String = getNoteSplash();

		var hue:Float = 0;
		var sat:Float = 0;
		var brt:Float = 0;

		if (data >= 0)
		{
			if (note != null)
			{
				skin = note.noteSplashTexture;

				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);

		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	private inline static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;
		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	// CAMERA
	private function moveCameraSection():Void
	{
		var section:SwagSection = SONG.notes[curSection];
		if (section == null)
			return;
		if (gf != null && section.gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);

			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];

			tweenCamZoom(true);
			return;
		}
		moveCamera(!section.mustHitSection);
	}

	private inline function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			if (curStage is Candy && evilFocused && duoOpponent != null)
			{
				var midpoint:FlxPoint = duoOpponent.getMidpoint();
				camFollow.set(midpoint.x + (curStage.evilBeastDead ? 50 : -200), midpoint.y + (curStage.evilBeastDead ? 40 : -100));

				camFollow.x += duoOpponent.cameraPosition[0];
				camFollow.y += duoOpponent.cameraPosition[1];
			}
			else
			{
				var midpoint:FlxPoint = dad.getMidpoint();
				camFollow.set(midpoint.x + 150, midpoint.y - 100);

				camFollow.x += dad.cameraPosition[0];
				camFollow.y += dad.cameraPosition[1];
			}

			camFollow.x += opponentCameraOffset[0];
			camFollow.y += opponentCameraOffset[1];

			tweenCamZoom(true);
		}
		else
		{
			var midpoint:FlxPoint = boyfriend.getMidpoint();
			camFollow.set(midpoint.x - 100, midpoint.y - 100);

			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			tweenCamZoom();
		}
	}

	private inline function cancelCameraDelta(char:Character, forceDad:Bool = false)
	{
		if (!characterIsSinging(char))
		{
			var deltaCancel:FlxPoint = switch (char.isPlayer)
			{
				default:
					(char == dad || forceDad) ? opponentDelta : secondOpponentDelta;
				case true:
					playerDelta;
			};
			deltaCancel.set();
		}
	}

	private inline function tweenCamZoom(opponent:Bool = false)
	{
		var start:Float = defaultCamZoom;
		switch (curSong)
		{
			case 'tutorial':
				{
					var zoomAmount:Float = opponent ? .3 : 0;
					var target:Float = stageData.defaultZoom + zoomAmount;

					if (start != target)
					{
						if (cameraTwn != null)
						{
							cameraTwn.cancel();
							cleanupTween(cameraTwn);
							cameraTwn = null;
						}
						defaultCamZoom = target;
						cameraTwn = FlxTween.num(start, target, Conductor.crochet / 1000, {
							ease: FlxEase.elasticInOut,
							onComplete: function(twn:FlxTween)
							{
								gameZoom = target;
								camGame.zoom = target + gameZoomAdd;

								defaultCamZoom = stageData.defaultZoom + zoomAmount;

								cleanupTween(twn);
								cameraTwn = null;
							}
						}, function(value:Float) {
							gameZoom = value;
							camGame.zoom = gameZoom + gameZoomAdd;
						});
					}
				}
		}
	}

	private inline function snapCamFollowToPos(x:Float, y:Float)
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	private inline function doSustainShake()
	{
		if (!ClientPrefs.getPref('reducedMotion'))
		{
			var stepCrochet:Float = Conductor.stepCrochet / 1000;
			if (gameShakeAmount > 0)
				camGame.shake(gameShakeAmount, stepCrochet);
			if (hudShakeAmount > 0)
				camHUD.shake(hudShakeAmount, stepCrochet);
		}
	}

	private inline function canZoomCamera():Bool
		return camZooming && ClientPrefs.getPref('camZooms') && !isFNM && !endingSong;

	// CHARACTERS
	private function playCharacterAnim(?char:Character = null, animToPlay:String, note:Note):Bool
	{
		if (char != null && !char.specialAnim)
		{
			var curAnim:FlxAnimation = char.animation.curAnim;
			var isSingAnimation:Bool = false;

			if (curAnim != null && !curAnim.name.endsWith('miss'))
			{
				for (anim in singAnimations)
				{
					if (curAnim.name.startsWith(anim))
					{
						isSingAnimation = true;
						break;
					}
				}
			}

			var lastNote:Note = char.lastNoteHit;
			var canOverride:Bool = curAnim == null || lastNote == null || curAnim.finished || !isSingAnimation;

			if (canOverride
				|| lastNote.noteData == note.noteData
				|| (note.isSustainNote ? ((lastNote.strumTime + lastNote.sustainLength +
					(Conductor.stepCrochet * char.singDuration * .5)) < note.strumTime) : ((lastNote.strumTime < note.strumTime
					|| (lastNote.strumTime == note.strumTime && note.sustainLength > lastNote.sustainLength)))))
			{
				if (!note.isSustainNote || canOverride)
					char.lastNoteHit = note;

				char.playAnim(animToPlay, true);
				char.holdTimer = 0;

				if (!ClientPrefs.getPref('reducedMotion') && iconP1 != null && iconP2 != null)
				{
					var offsetPoint:FlxPoint = getNoteDataPoint(note.noteData).scale(note.isSustainNote ? 30 : 50);

					var bfCharacter:Character = if (curStage is Carnival && curStage.eggbob != null && eggbobFocused) curStage.eggbob else boyfriend;
					var dadCharacter:Character = switch (Type.getClass(curStage)) {
						case Candy:
							if (curStage.evilBeast != null && evilFocused) curStage.evilBeast else dad;
						case BendHard:
							char;

						default:
							dad;
					};

					var charP1:Character = if (shitFlipped) dadCharacter else bfCharacter;
					var charP2:Character = if (shitFlipped) bfCharacter else dadCharacter;

					if (char == charP1)
					{
						// p1 offset
						iconP1OffsetFollow = offsetPoint;
					}
					else if (char == charP2)
					{
						// p2 offset
						iconP2OffsetFollow = offsetPoint;
					}
				}
				return true;
			}
		}
		return false;
	}

	public inline function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && gf != null && char.curCharacter == gf.curCharacter)
			// IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);

		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public inline function charDance(char:Character, beat:Int)
	{
		var curAnim:FlxAnimation = char.animation.curAnim;
		if (curAnim != null
			&& (beat % (gfGroup.members.contains(char) ? (char.danceEveryNumBeats * gfSpeed) : char.danceEveryNumBeats)) == 0)
		{
			if (!char.stunned && (curAnim.finished || !characterIsSinging(char)))
				char.dance();
			if (shuttlecock != null && shuttlecock.racquetMap.exists(char))
				shuttlecock.racquetMap.get(char).dance();
		}
	}

	private inline function bfDance()
	{
		var curAnim:FlxAnimation = boyfriend.animation.curAnim;
		if (curAnim != null)
		{
			var animName = curAnim.name;
			if (boyfriend.holdTimer > ((Conductor.stepCrochet / 1000) * boyfriend.singDuration)
				&& (characterIsSinging(boyfriend) && !animName.endsWith("miss")))
				boyfriend.dance();
		}
	}

	private inline function groupDance(chars:FlxSpriteGroup, beat:Int)
	{
		for (char in chars.members)
		{
			if (Std.isOfType(char, Character))
				charDance(cast(char, Character), beat);
		}
	}

	private inline static function characterIsSinging(character:Character):Bool
		return (character?.animation?.curAnim?.name?.startsWith('sing') ?? false) && !(character?.animation?.curAnim?.finished ?? true);

	// ICONS
	private inline function iconBop(beat:Int = 0)
	{
		if (iconP1 != null && iconP2 != null)
		{
			var crochetDiv:Float = 1300;
			switch (isFNM)
			{
				case true:
					{
						var newScaling:Float = HealthIcon.FNM_SCALING + .075;

						iconP1.scale.set(newScaling, newScaling);
						iconP2.scale.set(newScaling, newScaling);

						modchartTweens.push(FlxTween.tween(iconP1, {'scale.x': HealthIcon.FNM_SCALING, 'scale.y': HealthIcon.FNM_SCALING}, FNM_ICON_BOP / 2,
							{ease: FlxEase.linear, onComplete: cleanupTween}));
						modchartTweens.push(FlxTween.tween(iconP2, {'scale.x': HealthIcon.FNM_SCALING, 'scale.y': HealthIcon.FNM_SCALING}, FNM_ICON_BOP / 2,
							{ease: FlxEase.linear, onComplete: cleanupTween}));
					}
				default:
					{
						if (beat % gfSpeed == 0)
						{
							var crochetTime:Float = Conductor.crochet / (crochetDiv / Math.max(gfSpeed, 1));
							var stretchBool:Bool = (beat % (gfSpeed * 2)) == 0;

							var stretchValueOpponent:Float = getStretchValue(!stretchBool);
							var stretchValuePlayer:Float = getStretchValue(stretchBool);

							var angleValue:Float = 15 * FlxMath.signOf(stretchValuePlayer);
							var scaleValue:Float = .4;

							var scaleDefault:Float = 1.1;

							iconP1.scale.set(scaleDefault, scaleDefault + (scaleValue * stretchValuePlayer));
							iconP2.scale.set(scaleDefault, scaleDefault + (scaleValue * stretchValueOpponent));

							modchartTweens.push(FlxTween.angle(iconP1, -angleValue, 0, crochetTime, {ease: FlxEase.quadOut, onComplete: cleanupTween}));
							modchartTweens.push(FlxTween.angle(iconP2, angleValue, 0, crochetTime, {ease: FlxEase.quadOut, onComplete: cleanupTween}));

							modchartTweens.push(FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, crochetTime,
								{ease: FlxEase.quadOut, onComplete: cleanupTween}));
							modchartTweens.push(FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, crochetTime,
								{ease: FlxEase.quadOut, onComplete: cleanupTween}));

							iconP1.updateHitbox();
							iconP2.updateHitbox();
						}
					}
			}
		}
	}

	private inline function getHealthIconOf(?icon:HealthIcon, ?character:Character):Dynamic
	{
		if (icon != null)
			return icon.getCharacter();
		if (character != null)
			return HealthIcon.getIconOf(character.curCharacter, isFNM, character == boyfriend);
		return null;
	}

	// DIALOGUE
	private function startDialogue(dialogueFile:DialogueFile, ?song:String):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (dialogueBoxShit != null)
			return;
		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;

			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');

			dialogueBoxShit = new DialogueBox(dialogueFile, song);
			dialogueBoxShit.scrollFactor.set();

			dialogueBoxShit.finishThing = function()
			{
				switch (endingSong)
				{
					default:
						startCountdown();
					case true:
						endSong();
				}
			}

			dialogueBoxShit.nextDialogueThing = startNextDialogue;
			dialogueBoxShit.cameras = [camHUD];

			add(dialogueBoxShit);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			switch (endingSong)
			{
				default:
					startCountdown();
				case true:
					endSong();
			}
		}
	}

	private function startVideo(name:String, skipTransIn:Bool = false)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		if (!#if sys FileSystem #else OpenFlAssets #end.exists(filepath))
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd(skipTransIn);
			return;
		}

		var bg:FlxSprite = null;
		if (!skipTransIn)
		{
			bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);

			bg.cameras = [camOther];
			bg.scrollFactor.set();
		}

		video = new VideoSprite();
		video.scrollFactor.set();

		video.canvasHeight = FlxG.height;
		video.canvasWidth = FlxG.width;

		video.cameras = [camOther];

		video.bitmap.canSkip = false;
		video.alpha = 0;

		video.bitmap.onPaused = function()
		{
			if (focused && !paused)
				video.bitmap.resume();
		}
		video.finishCallback = function()
		{
			if (bg != null)
			{
				modchartTweens.push(FlxTween.tween(bg, {alpha: 0}, 1 / 3, {
					ease: FlxEase.linear,
					onComplete: function(twn:FlxTween)
					{
						bg.kill();
						remove(bg, true);

						bg.destroy();
						bg = null;

						cleanupTween(twn);
					}
				}));
			}
			if (skipCutscene != null)
			{
				skipCutscene.kill();
				remove(skipCutscene, true);

				skipCutscene.destroy();
				skipCutscene = null;
			}
			startAndEnd(skipTransIn);
			return;
		}
		if (video != null)
		{
			skipCutscene = new FlxText(SKIP_PADDING, FlxG.height - SKIP_PADDING, FlxG.width,
				'press ACCEPT to skip').setFormat(Paths.font('comic.ttf'), SKIP_SIZE, 0xFFFF0000);
			skipCutscene.cameras = [camOther];

			skipCutscene.y -= skipCutscene.height;
			skipCutscene.alpha = .8;

			if (bg != null)
				add(bg);

			add(video);
			add(skipCutscene);

			video.playVideo(filepath, false, false);
			// video.bitmap.volume = Std.int(FlxG.sound.volume * 100) * CoolUtil.int(FlxG.sound.muted);

			FlxTween.tween(video, {alpha: 1}, 1 / 2, {ease: FlxEase.quadOut});
		}
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd(skipTransIn);

		return;
		#end
	}

	private inline function startNextDialogue()
		dialogueCount++;

	// CLEANERS
	#if VIDEOS_ALLOWED
	public function cleanupVideo(?video:VideoSprite)
	{
		if (modchartVideos.contains(video))
			modchartVideos.remove(video);
		if (video != null && video.alive && video.exists)
		{
			if (video.bitmap != null)
			{
				if (video.bitmap.canPause)
					video.bitmap.pause();
				if (video.bitmap.isPlaying)
				{
					video.bitmap.stop();
					video.bitmap.dispose();
				}
			}
			video.kill();

			var finish:Null<() -> Void> = video.finishCallback;
			if (finish != null)
			{
				video.finishCallback = null;
				finish();
			}
			remove(video, true);

			video.destroy();
			video = null;
		}
	}
	#end

	public function cleanupTween(?twn:FlxTween)
	{
		if (modchartTweens.contains(twn))
			modchartTweens.remove(twn);
		if (twn != null)
		{
			if (twn.active)
				twn.cancel();

			twn.active = false;
			twn.destroy();
		}
	}

	public function cleanupTimer(?tmr:FlxTimer)
	{
		if (modchartTimers.contains(tmr))
			modchartTimers.remove(tmr);
		if (tmr != null)
		{
			if (tmr.active)
				tmr.cancel();

			tmr.active = false;
			tmr.destroy();
		}
	}

	// HELPERS
	private inline static function preloadCharacter(name:String)
	{
		var character:Character = new Character(0, 0, name, false, true);
		var deathAnim:String = character.getDeathAnimation();

		var icon:HealthIcon = new HealthIcon(character.healthIcon, false, false);
		if (deathAnim != character.curCharacter)
		{
			trace('dead $deathAnim');
			switch (deathAnim)
			{
				case 'deadleman':
					Paths.image('he_died');
				default:
				{
					var death:Character = new Character(0, 0, deathAnim, character.isPlayer, true);
					FlxG.bitmap.add(death.graphic);

					death.kill();
					death.destroy();

					death = null;
				}
			}
		}

		FlxG.bitmap.add(character.graphic);
		FlxG.bitmap.add(icon.graphic);

		character.kill();
		icon.kill();

		character.destroy();
		icon.destroy();

		character = null;
		icon = null;
	}

	public static function cacheShitForSong(SONG:SwagSong)
	{
		CoolUtil.totalFuckingReset();
		var songName:String = Paths.formatToSongPath(SONG.song);
		// Ratings
		ratingsData = new Array();
		isFNM = switch (songName)
		{
			case 'farting-bars' | 'poop-time' | 'shagy':
				true;
			default:
				false;
		};

		preloadCharacter(SONG.player1);
		preloadCharacter(SONG.player2);

		PauseSubState.isFNM = isFNM;

		var rating:Rating = new Rating('funny');
		rating.hitWindow = ClientPrefs.getPref('funnyWindow');

		rating.counter = 'funnies';
		ratingsData.push(rating); // default rating

		var rating:Rating = new Rating('goog');
		rating.hitWindow = ClientPrefs.getPref('googWindow');

		rating.noteSplash = false;
		rating.counter = 'googs';

		rating.ratingMod = .7;
		rating.score = 200;

		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.hitWindow = ClientPrefs.getPref('badWindow');

		rating.noteSplash = false;
		rating.counter = 'bads';

		rating.ratingMod = .4;
		rating.score = 100;

		ratingsData.push(rating);
		var rating:Rating = new Rating('horsedog');

		rating.counter = 'horsedogs';
		rating.noteSplash = false;

		rating.ratingMod = 0;
		rating.score = 50;

		ratingsData.push(rating);
		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		switch (isFNM)
		{
			default:
				{
					Hitsound.play(true);
					Paths.image('combo', otherAssetsLibrary);

					var noteSplashCache:FlxSprite = new FlxSprite();

					noteSplashCache.frames = Paths.getSparrowAtlas(getNoteSplash());
					noteSplashCache.destroy();

					for (i in 0...10)
						Paths.image('num$i', otherAssetsLibrary);
					for (rating in ratingsData)
						Paths.image(rating.image, otherAssetsLibrary);
					for (i in 0...3)
						CoolUtil.precacheSound('missnote' + Std.string(i + 1));
				}
			case true:
				CoolUtil.precacheSound('fnm_missnote', 'fnm');
		}

		if (PauseSubState.songName != null)
		{
			CoolUtil.precacheMusic(PauseSubState.songName);
		}
		else
		{
			var pauseMusic:Null<String> = Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic'));
			if (pauseMusic != null && pauseMusic != 'none')
				CoolUtil.precacheMusic(pauseMusic);
		}
	}

	public function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;

		cancelMusicFadeTween();

		CustomFadeTransition.nextCamera = camOther;
		LoadingState.loadAndSwitchState(new ChartingState(), false, true);

		chartingMode = true;
		DiscordClient.changePresence("Chart Editor", null, null, true);
	}

	private inline function setupStageShit()
	{
		if (stageData == null)
		{
			// Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 1,

				boyfriend: [0, 0],
				girlfriend: [0, 0],
				opponent: [0, 0],

				hide_girlfriend: false,

				camera_boyfriend: defaultCameraOffset,
				camera_opponent: defaultCameraOffset,
				camera_girlfriend: defaultCameraOffset,

				scroll_boyfriend: defaultScrollFactor,
				scroll_opponent: defaultScrollFactor,
				scroll_girlfriend: defaultScrollFactor,

				camera_speed: 1
			};
		}
		if (!endingSong && cameraTwn == null)
			defaultCamZoom = stageData.defaultZoom;

		BF_X = stageData?.boyfriend[0] ?? 0.;
		BF_Y = stageData?.boyfriend[1] ?? 0.;

		GF_X = stageData?.girlfriend[0] ?? 0.;
		GF_Y = stageData?.girlfriend[1] ?? 0.;

		DAD_X = stageData?.opponent[0] ?? 0.;
		DAD_Y = stageData?.opponent[1] ?? 0.;

		cameraSpeed = stageData?.camera_speed ?? 1.;

		girlfriendCameraOffset = stageData.camera_girlfriend ?? defaultCameraOffset;
		boyfriendCameraOffset = stageData.camera_boyfriend ?? defaultCameraOffset;
		opponentCameraOffset = stageData.camera_opponent ?? defaultCameraOffset;

		girlfriendScrollFactor = stageData.scroll_girlfriend ?? defaultScrollFactor;
		boyfriendScrollFactor = stageData.scroll_boyfriend ?? defaultScrollFactor;
		opponentScrollFactor = stageData.scroll_opponent ?? defaultScrollFactor;

		boyfriendGroup.scrollFactor.set(boyfriendScrollFactor[0], boyfriendScrollFactor[1]);
		gfGroup.scrollFactor.set(girlfriendScrollFactor[0], girlfriendScrollFactor[1]);
		dadGroup.scrollFactor.set(opponentScrollFactor[0], opponentScrollFactor[1]);

		boyfriendGroup.setPosition(BF_X, BF_Y);
		dadGroup.setPosition(DAD_X, DAD_Y);
		gfGroup.setPosition(GF_X, GF_Y);
	}

	private inline function postStageShit()
	{
		if (trail != null)
		{
			trail.kill();
			dadGroup.remove(trail, true);

			trail.destroy();
			trail = null;
		}
		if (addTrail)
		{
			trail = new FlxTrail(dad, null, 4, 24, .3, .07);
			dadGroup.add(trail);
		}

		if (trioOpponent != null)
		{
			dadGroup.insert(0, trioOpponent);
			trioOpponent.setPosition(DAD_X + TRIO_X, DAD_Y + TRIO_Y);

			startCharacterPos(trioOpponent);
		}
		if (duoOpponent != null)
		{
			if (trioOpponent != null)
			{
				dadGroup.insert(1, duoOpponent);
			}
			else
			{
				dadGroup.add(duoOpponent);
			}

			duoOpponent.setPosition(DAD_X + DUO_X, DAD_Y + DUO_Y);
			startCharacterPos(duoOpponent);
		}

		switch (Type.getClass(curStage))
		{
			case Forest:
				{
					if (!ClientPrefs.getPref('middleScroll'))
					{
						shitFlipped = true;
						if (!cpuControlled && !ClientPrefs.getPref('hideHUD'))
						{
							var downScroll:Bool = ClientPrefs.getPref('downScroll');
							// 'yourz_' + (downScroll ? 'down' : 'up') + 'scroll'
							yourStrumline = new FlxSprite().loadGraphic(Paths.image(switch (downScroll)
							{
								case true:
									'yourz_downscroll';
								default:
									'yourz_upscroll';
							}));

							yourStrumline.screenCenter(X);
							var newY:Float = yourStrumline.height / (Math.PI / 2);

							yourStrumline.y = downScroll ? FlxG.height - yourStrumline.height - newY : newY;
							yourStrumline.x += yourStrumline.width / 3;

							yourStrumline.antialiasing = false;
							yourStrumline.cameras = [camHUD];

							yourStrumline.offset.y = -20;
							yourStrumline.alpha = 0;
						}
					}
				}
		}
	}

	private inline function checkForGirlfriend()
	{
		// TODO: maybe make this a bit better if people wanna use this func outside of funnying(HEAVY DOUBT)
		if (stageData.hide_girlfriend || isFNM)
		{
			if (gf != null)
			{
				gf.kill();
				gfGroup.remove(gf, true);

				gf.destroy();
				gf = null;
			}
		}
		else
		{
			var newGF:String = curStage?.gfVersion ?? 'gf';
			if (gf != null)
			{
				gf.setCharacter(newGF);
			}
			else
			{
				gf = new Character(0, 0, newGF);
			}

			gfGroup.add(gf);
			gf.setPosition(GF_X, GF_Y);

			startCharacterPos(gf);
		}
	}

	private inline function quickUpdatePresence(?startString:String = "", ?hasLength:Bool = true)
	{
		if (health > 0 && !paused && DiscordClient.isInitialized)
			DiscordClient.changePresence(detailsText, startString
				+ getFormattedSong(), getHealthIconOf(iconP2, dad), hasLength && Conductor.songPosition > 0,
				songLength
				- Conductor.songPosition
				- ClientPrefs.getPref('noteOffset'));
	}

	private inline static function getStretchValue(value:Bool):Float
		return value ? -1 : .5;

	private inline static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	// RATINGS
	private inline function recalculateRating(noZoom:Bool = false)
	{
		// Prevent divide by 0
		if (totalPlayed <= 0)
		{
			ratingName = '?';
		}
		else
		{
			var ratingStuff:Array<Dynamic> = ratingStuffMap.exists(barsAssets) ? ratingStuffMap.get(barsAssets) : defaultRatingStuff;
			// Rating Percent
			ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
			// Rating Name
			if (ratingPercent >= 1)
			{
				ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
			}
			else
			{
				for (i in 0...ratingStuff.length - 1)
				{
					if (ratingPercent < ratingStuff[i][1])
					{
						ratingName = ratingStuff[i][0];
						break;
					}
				}
			}
		}

		setRating();
		updateScore(noZoom);

		switch (curSong)
		{
			case 'relapse':
				{
					var application:Application = Lib.application;
					var applicationWindow:Window = application.window;

					if (applicationWindow != null)
					{
						var roll:String = FlxG.random.bool(1) ? ':3' : FlxG.random.getObject(relapseFaces);
						applicationWindow.title = roll + ' - $ratingFC';
					}
				}
		}
	}

	private function setRating()
	{
		// Rating FC
		ratingFC = "?";
		if (songMisses > 0)
		{
			if (songMisses >= 10)
			{
				ratingFC = switch (barsAssets)
				{
					case 'killgames':
						'Still a Game';
					case 'relapse':
						(songMisses > 50) ? '???' : '??';
					default:
						(songMisses > 50) ? 'kill yourself immediatly' : 'a rather large issue of skill';
				};
				return;
			}
			ratingFC = switch (barsAssets)
			{
				case 'killgames':
					'No Games.';
				case 'relapse':
					'?';
				default:
					"shit fart";
			};
			return;
		}

		if ((bads + horsedogs) > 0)
		{
			ratingFC = switch (barsAssets)
			{
				case 'killgames':
					'Possibly a Game';
				case 'relapse':
					'!';
				default:
					"borb combo";
			};
			return;
		}

		if (googs > 0)
		{
			ratingFC = switch (barsAssets)
			{
				case 'killgames':
					'Maybe a Game';
				case 'relapse':
					'!!';
				default:
					"googulus combo";
			};
			return;
		}
		if (funnies > 0)
		{
			ratingFC = switch (barsAssets)
			{
				case 'killgames':
					'Ain\'t No Game.';
				case 'relapse':
					'!!!';
				default:
					"shitfartcombo";
			};
			return;
		}
	}

	// MECHANICS
	private inline function killShuttlecock(force:Bool = false)
	{
		if ((destroyShuttleOnNextHit || force) && shuttlecock != null)
		{
			trace("KILL SHUTTLECOCK!");

			trace(destroyShuttleOnNextHit);
			trace(force);

			shuttlecock.kill();
			shuttlecock.destroy();

			shuttlecock = null;
		}
	}
}
