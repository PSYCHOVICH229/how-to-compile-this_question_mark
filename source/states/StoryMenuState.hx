package states;

import meta.PlayerSettings;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.effects.FlxFlicker;
import meta.Discord.DiscordClient;
import meta.instances.HealthIcon;
import states.substates.GameplayChangersSubstate;
import states.substates.ResetScoreSubState;
import meta.data.Song;
import meta.data.ClientPrefs;
import meta.data.Highscore;
import meta.CoolUtil;
import meta.data.WeekData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	public static var storyWeeks:Array<String> = ['tutorial', 'funny', 'trio', 'blam', 'shuttleman', 'week8'];
	public static var weekCompleted:Map<String, Bool> = new Map();

	private static var lastDifficultyName:String = '';

	private inline static final lockedText:String = '???';

	private inline static final backgroundHeight:Int = 432;
	private inline static final backgroundWidth:Int = 960;

	var scoreText:FlxText;
	var curDifficulty:Int = 1;

	var txtWeekTitle:FlxText;
	var bgSprite:FlxSprite;

	private static var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<FlxText>;
	var grpIcons:FlxTypedGroup<HealthIcon>;

	var grpLocks:FlxSpriteGroup;
	var bigAssLock:FlxSprite;

	var difficultySelectors:FlxSpriteGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	var separationLine:FlxSprite;
	var sideBar:FlxSprite;

	var loadedWeeks:Array<WeekData> = [];
	var padding:Float = 10;

	var selectedWeek:Bool = false;
	var stopSpamming:Bool = false;
	var movedBack:Bool = false;

	var tweenDifficulty:FlxTween;

	var intendedScore:Int = 0;
	var lerpScore:Int = 0;

	var txtTracklistSize:Int = 28;
	var tooLong:Int = 20;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true, storyWeeks);

		if (curWeek >= WeekData.weeksList.length)
			curWeek = 0;
		persistentUpdate = persistentDraw = true;

		var ui_tex:FlxAtlasFrames = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');

		var placeholder:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menume'));
		placeholder.antialiasing = globalAntialiasing;

		placeholder.setGraphicSize(backgroundWidth, backgroundHeight); // actual res
		placeholder.updateHitbox();

		bgSprite = new FlxSprite();
		bgSprite.antialiasing = globalAntialiasing;

		add(placeholder);
		add(bgSprite);

		sideBar = new FlxSprite().makeGraphic(Std.int(FlxG.width * .25), Std.int(FlxG.height * .6), FlxColor.BLACK);

		sideBar.x = FlxG.width - sideBar.width;
		sideBar.antialiasing = false;

		add(sideBar);
		difficultySelectors = new FlxSpriteGroup();

		leftArrow = new FlxSprite();
		leftArrow.frames = ui_tex;

		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");

		leftArrow.animation.play('idle');
		leftArrow.antialiasing = globalAntialiasing;

		leftArrow.setGraphicSize(Std.int(leftArrow.width * .5));
		leftArrow.updateHitbox();

		sprDifficulty = new FlxSprite(leftArrow.width + padding, 0);
		sprDifficulty.antialiasing = globalAntialiasing;

		rightArrow = new FlxSprite(sprDifficulty.x, 0);
		rightArrow.frames = ui_tex;

		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);

		rightArrow.animation.play('idle');
		rightArrow.antialiasing = globalAntialiasing;

		rightArrow.setGraphicSize(Std.int(rightArrow.width * .5));
		rightArrow.updateHitbox();

		difficultySelectors.add(leftArrow);
		difficultySelectors.add(sprDifficulty);
		difficultySelectors.add(rightArrow);

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		if (lastDifficultyName.length <= 0)
			lastDifficultyName = CoolUtil.defaultDifficulty;

		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		difficultySelectors.y = padding * 2;

		add(difficultySelectors);
		repositionDifficultySelectors();

		grpWeekText = new FlxTypedGroup();

		grpLocks = new FlxSpriteGroup();
		grpIcons = new FlxTypedGroup();

		separationLine = new FlxSprite().makeGraphic(Std.int(sideBar.width * .5), 2);

		separationLine.x = sideBar.x + ((sideBar.width - separationLine.width) / 2);
		separationLine.y = sideBar.y + sideBar.height - separationLine.height;

		separationLine.antialiasing = false;
		add(separationLine);

		var bottomBar:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, Std.int(FlxG.height - sideBar.height), FlxColor.BLACK);

		bottomBar.y = FlxG.height - bottomBar.height;
		bottomBar.antialiasing = false;

		add(bottomBar);

		scoreText = new FlxText(padding, bottomBar.y + padding, bottomBar.width, "SCORE", 32);
		scoreText.setFormat(Paths.font('vcr.ttf'), scoreText.size, FlxColor.WHITE, LEFT);

		txtWeekTitle = new FlxText(scoreText.x, scoreText.y + scoreText.height + padding, bottomBar.width - sideBar.width, "WEEK", scoreText.size);
		txtWeekTitle.setFormat(Paths.font('vcr.ttf'), scoreText.size, FlxColor.WHITE, LEFT);
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);

		var textHeight:Float = difficultySelectors.y + difficultySelectors.height + padding;
		var num:Int = 0;

		for (i in 0...WeekData.weeksList.length)
		{
			var loadedWeek:String = WeekData.weeksList[i];

			var weekFile:WeekData = WeekData.weeksLoaded.get(loadedWeek);
			var isLocked:Bool = #if debug false #else WeekData.weekIsLocked(loadedWeek) #end;

			if (#if debug true #else !weekFile.data.hiddenUntilUnlocked #end)
			{
				loadedWeeks.push(weekFile);
				var weekThing:FlxText = new FlxText(sideBar.x, textHeight, sideBar.width, isLocked ? lockedText : weekFile.data.weekName, 42);

				weekThing.setFormat(Paths.font('vcr.ttf'), weekThing.size, FlxColor.WHITE, CENTER);
				weekThing.y += weekThing.height * num;

				weekThing.antialiasing = globalAntialiasing;
				weekThing.updateHitbox();

				weekThing.ID = num;
				grpWeekText.add(weekThing);
				// Needs an offset thingie
				if (isLocked)
				{
					var lock:FlxSprite = new FlxSprite(0, weekThing.y);
					lock.frames = ui_tex;

					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');

					lock.antialiasing = globalAntialiasing;

					lock.setGraphicSize(Std.int(lock.width * .6));
					lock.updateHitbox();

					lock.x = weekThing.x + ((weekThing.width - lock.width) / 2);
					lock.alpha = .5;

					lock.ID = num;
					grpLocks.add(lock);
				}
				num++;
			}
		}

		txtTracklist = new FlxText(0, bottomBar.y + padding, 0, "TRACKS", txtTracklistSize);

		txtTracklist.setFormat(Paths.font('vcr.ttf'), txtTracklistSize, 0xFF1E1EFF, CENTER);
		txtTracklist.antialiasing = globalAntialiasing;

		bigAssLock = new FlxSprite(0, txtTracklist.y + txtTracklistSize + padding);
		bigAssLock.frames = ui_tex;

		bigAssLock.animation.addByPrefix('lock', 'lock');
		bigAssLock.animation.play('lock');

		bigAssLock.setGraphicSize(Std.int(bigAssLock.width * 2));
		bigAssLock.updateHitbox();

		bigAssLock.x = separationLine.x + ((separationLine.width - bigAssLock.width + padding) / 2);
		bigAssLock.visible = false;

		add(txtTracklist);
		add(scoreText);
		add(txtWeekTitle);

		add(grpLocks);
		add(grpWeekText);

		add(grpIcons);
		add(bigAssLock);

		changeWeek();
		changeDifficulty();

		super.create();
	}

	override function closeSubState()
	{
		persistentUpdate = true;
		changeWeek();

		super.closeSubState();
	}

	override function update(elapsed:Float)
	{
		FlxG.mouse.visible = false;
		// scoreText.setFormat('VCR OSD Mono', 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 30, 0, 1)));
		if (Math.abs(intendedScore - lerpScore) < 10)
			lerpScore = intendedScore;

		scoreText.text = 'WEEK SCORE: $lerpScore';

		// FlxG.watch.addQuick('font', scoreText.font);

		if (!movedBack && !selectedWeek)
		{
			var vertDelta:Int = PlayerSettings.controls.diff(UI_DOWN, UI_UP, JUST_PRESSED, JUST_PRESSED);
			var horDelta:Int = PlayerSettings.controls.diff(UI_RIGHT, UI_LEFT, JUST_PRESSED, JUST_PRESSED);

			var wheel:Int = -FlxG.mouse.wheel;
			if (wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), .4);

				changeWeek(wheel);
				changeDifficulty();
			}

			if (vertDelta != 0)
			{
				changeWeek(vertDelta);
				// yayaeyaa
				changeDifficulty();

				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (horDelta != 0)
				changeDifficulty(horDelta);

			rightArrow.animation.play(PlayerSettings.controls.is(UI_RIGHT, PRESSED) ? 'press' : 'idle');
			leftArrow.animation.play(PlayerSettings.controls.is(UI_LEFT, PRESSED) ? 'press' : 'idle');

			if (FlxG.keys.justPressed.CONTROL)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate(true));
			}
			else if (PlayerSettings.controls.is(RESET))
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
			}
			else if (PlayerSettings.controls.is(ACCEPT))
				selectWeek();
		}
		if (PlayerSettings.controls.is(BACK) && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			MusicBeatState.switchState(new MainMenuState());
		}
		super.update(elapsed);
	}

	private function selectWeek()
	{
		if (#if debug true #else !WeekData.weekIsLocked(loadedWeeks[curWeek].fileName) #end)
		{
			var formattedDiff:String = CoolUtil.getDifficultyFilePath(curDifficulty);
			if (formattedDiff == null)
				formattedDiff = '';
			if (!stopSpamming)
			{
				FlxG.sound.play(Paths.sound(switch (formattedDiff)
				{
					case '-cuh': 'cuh';
					default:
						{
							var text:FlxText = grpWeekText.members[curWeek];
							if (text != null)
							{
								switch (ClientPrefs.getPref('flashing'))
								{
									default: FlxTween.tween(text, {alpha: 0}, 2, {ease: FlxEase.linear});
									case true: FlxFlicker.flicker(text, 2, 1 / 8);
								}
							}
							'confirmMenu';
						}
				}));
				stopSpamming = true;
			}
			selectedWeek = true;

			PlayState.storyMisses = new Map();
			PlayState.storyPlaylist = [for (song in loadedWeeks[curWeek].data.songs) song[0]];

			PlayState.isStoryMode = true;
			PlayState.storyDifficulty = curDifficulty;

			PlayState.SONG = Song.loadFromJson(formattedDiff, Paths.formatToSongPath(PlayState.storyPlaylist[0]));
			PlayState.campaignScore = PlayState.campaignMisses = 0;

			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				MusicBeatState.coolerTransition = true;
				LoadingState.loadAndSwitchState(new PlayState(), true);
			});
			return;
		}
		FlxG.sound.play(Paths.sound('cancelMenu'));
	}

	private function repositionDifficultySelectors()
	{
		sprDifficulty.setGraphicSize(Std.int(sprDifficulty.width * .5));
		sprDifficulty.updateHitbox();

		leftArrow.x = sideBar.x + ((sideBar.width - (leftArrow.width + sprDifficulty.width + (padding * 2))) / 2) - (leftArrow.width / 2);

		sprDifficulty.x = leftArrow.x + leftArrow.width + padding;
		rightArrow.x = sprDifficulty.x + sprDifficulty.width + padding;
	}

	private function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty = CoolUtil.repeat(curDifficulty, change, CoolUtil.difficulties.length);

		var diff:String = CoolUtil.difficulties[curDifficulty];
		var newImage:FlxGraphic = Paths.image('menudifficulties/' + Paths.formatToSongPath(diff));

		if (sprDifficulty.graphic != newImage)
		{
			sprDifficulty.loadGraphic(newImage);
			repositionDifficultySelectors();

			sprDifficulty.alpha = 0;
			sprDifficulty.y = leftArrow.y - 15;

			tweenDifficulty?.cancel();
			tweenDifficulty = FlxTween.tween(sprDifficulty, {y: leftArrow.y + ((leftArrow.height - sprDifficulty.height) / 2), alpha: 1}, .07, {
				onComplete: function(twn:FlxTween)
				{
					twn.destroy();
					tweenDifficulty = null;
				}
			});
		}

		lastDifficultyName = diff;
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
	}

	private function changeWeek(change:Int = 0):Void
	{
		curWeek = CoolUtil.repeat(curWeek, change, loadedWeeks.length);
		var leWeek:WeekData = loadedWeeks[curWeek];

		var bullShit:Int = 0;
		var unlocked:Bool = #if debug true #else !WeekData.weekIsLocked(leWeek.fileName) #end;

		bigAssLock.visible = !unlocked;
		txtWeekTitle.text = unlocked ? leWeek.data.storyName : lockedText;

		grpIcons.forEach(function(item:HealthIcon)
		{
			item.kill();
			grpIcons.remove(item);
			item.destroy();
		});
		if (unlocked)
		{
			var songs:Array<Dynamic> = leWeek.data.songs;
			var ind:Int = 0;

			for (i in 0...songs.length)
			{
				var song:Array<Dynamic> = songs[i];
				if (song != null)
				{
					var icon:String = song[1];
					if (icon != null)
					{
						var last:HealthIcon = grpIcons.members[ind - 1];
						if (last == null || last.getCharacter() != icon)
						{
							var item:HealthIcon = new HealthIcon(icon);

							item.x = padding + ((item.width + padding) * ind);
							item.y = FlxG.height - item.height;

							item.ID = ind;

							grpIcons.add(item);
							ind++;
						}
					}
				}
			}
		}
		for (item in grpWeekText.members)
		{
			item.color = (bullShit - curWeek) == 0 ? (unlocked ? txtTracklist.color : FlxColor.RED) : FlxColor.WHITE;
			bullShit++;
		}

		bgSprite.visible = true;

		var assetName:String = leWeek.data.weekBackground;
		if (assetName == null || assetName.length < 1)
		{
			bgSprite.visible = false;
		}
		else
		{
			bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_$assetName'));

			bgSprite.setGraphicSize(backgroundWidth, backgroundHeight);
			bgSprite.updateHitbox();
		}

		bgSprite.color = unlocked ? FlxColor.WHITE : FlxColor.BLACK;

		PlayState.storyWeek = curWeek;
		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();

		var diffStr:Null<String> = WeekData.getCurrentWeek()?.data?.difficulties?.trim();
		difficultySelectors.visible = unlocked;
		if (diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;

			while (i > 0)
			{
				var diff:String = diffs[i];
				if (diff != null)
				{
					diff = diff.trim();
					if (diff.length <= 0)
						diffs.remove(diff);
				}
				i--;
			}
			if (diffs.length > 0 && diffs[0].length > 0)
				CoolUtil.difficulties = diffs;
		}
		curDifficulty = CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty) ? Math.round(Math.max(0,
			CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty))) : 0;

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		// trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if (newPos >= 0)
			curDifficulty = newPos;
		updateText();
	}

	private function updateText()
	{
		var leWeek:WeekData = loadedWeeks[curWeek];
		var stringThing:Array<String> = [];

		var longest:Int = 0;
		txtTracklist.text = 'TRACKS\n\n';

		if (#if debug true #else !WeekData.weekIsLocked(leWeek.fileName) #end)
		{
			var songs:Array<Dynamic> = leWeek.data.songs;
			for (i in 0...songs.length)
				stringThing.push(songs[i][0]);
			for (i in 0...stringThing.length)
			{
				var str:String = stringThing[i].trim();
				var len:Int = str.length;

				if (len > 0)
				{
					if (len > longest)
						longest = len;
					txtTracklist.text += str + '\n';
				}
			}
		}

		txtTracklist.size = Std.int(txtTracklistSize * FlxMath.bound(tooLong / longest, .8, 1));
		txtTracklist.updateHitbox();

		txtTracklist.x = separationLine.x + ((separationLine.width - txtTracklist.width) / 2);
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
	}
}
