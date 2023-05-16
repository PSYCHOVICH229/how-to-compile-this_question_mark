package states.freeplay;

import flixel.tweens.FlxEase;
import openfl.Assets;
import flixel.input.keyboard.FlxKey;
import meta.InputFormatter;
import flixel.group.FlxSpriteGroup;
import meta.PlayerSettings;
import meta.Discord.DiscordClient;
import meta.data.WeekData;
import meta.data.Song;
import meta.data.Highscore;
import meta.CoolUtil;
import meta.data.ClientPrefs;
import states.substates.GameplayChangersSubstate;
import states.substates.ResetScoreSubState;
import meta.instances.Alphabet;
import meta.instances.HealthIcon;
import states.editors.ChartingState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

using StringTools;

class ListState extends MusicBeatState
{
	private inline static final ICON_RESOLUTION:Int = 420;

	private var songs:Array<SongMetadata> = [];
	public static var weeks:Array<String>;

	public static var selectedMenu:Int = 0;
	public static var curSelected:Int = 0;

	private var curDifficulty:Int = -1;

	private static var lastDifficultyName:String = '';
	private var openModKeys:Array<FlxKey>;

	private var scoreBG:FlxSprite;
	private var scoreText:FlxText;
	private var diffText:FlxText;
	private var lerpScore:Int = 0;
	private var lerpRating:Float = 0;
	private var intendedScore:Int = 0;
	private var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<HealthIcon> = [];

	private var modLinkGroup:FlxSpriteGroup;

	private var modIcon:FlxSprite;
	private var modLink:FlxText;

	private var bg:FlxSprite;
	private var intendedColor:Int;

	private var modLinkTween:FlxTween;
	private var colorTween:FlxTween;

	private var holdTime:Float = 0;
	override function create()
	{
		persistentUpdate = true;
		PlayState.isStoryMode = false;

		DiscordClient.changePresence("In the Menus", null);
		WeekData.reloadWeekFiles(false, weeks);

		openModKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		for (i in 0...WeekData.weeksList.length)
		{
			var week:String = weeks[i];
			if (WeekData.weeksLoaded.exists(week) #if !debug && !weekIsLocked(week) #end)
			{
				var leWeek:WeekData = WeekData.weeksLoaded.get(week);

				var leSongs:Array<String> = [];
				var leChars:Array<String> = [];

				var songs:Array<Dynamic> = leWeek.data.songs;
				for (song in songs)
				{
					leSongs.push(song[0]);
					leChars.push(song[1]);
				}
				for (song in songs)
				{
					var colors:Array<Int> = song[2];
					if (colors == null || colors.length < 3)
						colors = [255, 255, 255];
					addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
				}
			}
		}

		bg = new FlxSprite().loadGraphic(Paths.image('menume'));
		bg.antialiasing = ClientPrefs.getPref('globalAntialiasing');

		add(bg);

		bg.screenCenter();
		grpSongs = new FlxTypedGroup();

		add(grpSongs);
		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);

			songText.isMenuItem = true;
			songText.targetY = i - curSelected;

			grpSongs.add(songText);

			var maxWidth = 980;
			if (songText.width > maxWidth)
				songText.scaleX = maxWidth / songText.width;

			songText.snapToPosition();

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;
			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);
		}

		scoreText = new FlxText(FlxG.width * .7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = .6;

		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;

		add(diffText);
		add(scoreText);

		if (curSelected >= songs.length)
			curSelected = 0;

		bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		if (lastDifficultyName.length <= 0)
			lastDifficultyName = CoolUtil.defaultDifficulty;

		var modLinkKeys:Array<Dynamic> = ClientPrefs.keyBinds.get("debug_2");

		modLinkGroup = new FlxSpriteGroup();
		modLink = new FlxText(0, 0, ICON_RESOLUTION, "press KEY 2 (" + InputFormatter.getKeyName(modLinkKeys[0] ?? modLinkKeys[1]) + ") to open mod page").setFormat(Paths.font('comic.ttf'), 24, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.WHITE);

		modLink.borderQuality = 2;
		modLink.borderSize = 2;

		modIcon = new FlxSprite();

		modLinkGroup.add(modIcon);
		modLinkGroup.add(modLink);

		modLink.screenCenter(Y);
		modLink.y += (ICON_RESOLUTION * .5);

		add(modLinkGroup);

		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		modLinkGroup.visible = modLink.visible = modIcon.visible = false;

		changeSelection(0, false);
		changeDiff();

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = .6;

		add(textBG);

		var leText:String = "CTRL to open the gameplay changers menu / RESET to reset your score and accuracy";
		var size:Int = 18;

		var text:FlxText = new FlxText(textBG.x, textBG.y - 2, FlxG.width, leText, size).setFormat(Paths.font("comic.ttf"), size, FlxColor.WHITE, CENTER);
		text.scrollFactor.set();

		add(text);
		super.create();
	}

	override function update(elapsed:Float)
	{
		FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + (.5 * elapsed), .7);

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, FlxMath.bound(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= .01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if (ratingSplit.length < 2)
			ratingSplit.push(''); // No decimals, add an empty space
		while (ratingSplit[1].length < 2)
			ratingSplit[1] += '0'; // Less than 2 decimals in it, add decimals then

		scoreText.text = 'PERSONAL BEST: $lerpScore (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		var upP:Bool = PlayerSettings.controls.is(UI_UP, JUST_PRESSED);
		var downP:Bool = PlayerSettings.controls.is(UI_DOWN, JUST_PRESSED);

		var accepted:Bool = PlayerSettings.controls.is(ACCEPT);

		var ctrl:Bool = FlxG.keys.justPressed.CONTROL;
		var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

		if (songs.length > 1)
		{
			var delta:Int = (CoolUtil.delta(downP, upP)) * shiftMult;
			if (delta != 0)
			{
				changeSelection(delta);
				holdTime = 0;
			}

			if (PlayerSettings.controls.is(UI_DOWN, PRESSED) || PlayerSettings.controls.is(UI_UP, PRESSED))
			{
				var checkLastHold:Int = Math.round(holdTime * 10);
				holdTime += elapsed;

				var checkNewHold:Int = Math.round(holdTime * 10);
				var holdDiff:Int = checkNewHold - checkLastHold;

				if (holdTime > .5 && holdDiff > 0)
				{
					var holdDelta:Int = PlayerSettings.controls.diff(UI_DOWN, UI_UP, PRESSED, PRESSED);
					if (holdDelta != 0)
						changeSelection(holdDiff * shiftMult * holdDelta);
				}
			}
			else
			{
				holdTime = 0;
			}
			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), .2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
			}
		}

		var delta:Int = PlayerSettings.controls.diff(UI_RIGHT, UI_LEFT, JUST_PRESSED, JUST_PRESSED);
		if (delta != 0)
		{
			changeDiff(delta);
		}
		else if (upP || downP)
		{
			changeDiff();
		}

		if (PlayerSettings.controls.is(BACK))
		{
			persistentUpdate = false;

			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new FreeplayState());
		}

		if (ctrl)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if (accepted)
		{
			persistentUpdate = false;

			var songOriginal:String = songs[curSelected].songName;
			var songLowercase:String = Paths.formatToSongPath(songOriginal);

			var poop:String = Paths.formatToSongPath(CoolUtil.getDifficultyFilePath(curDifficulty));
			switch (poop)
			{
				case 'cuh':
					FlxG.sound.play(Paths.sound('cuh'));
			}

			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;

			PlayState.storyDifficulty = curDifficulty;
			trace('CURRENT WEEK: ' + WeekData.getWeekFileName());

			colorTween?.cancel();
			colorTween?.destroy();

			colorTween = null;

			var completed:Bool = false;
			for (week => data in WeekData.weeksLoaded)
			{
				for (song in data.data.songs)
				{
					if (song[0] == songOriginal)
					{
						if (StoryMenuState.weekCompleted.exists(week) || data.data.hideStoryMode)
							completed = true;
						break;
					}
				}
			}

			if (FlxG.keys.pressed.SHIFT #if !debug && completed #end)
			{
				FlxG.sound.music.volume = 0;
				LoadingState.loadAndSwitchState(new ChartingState(), false, true);
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));

				MusicBeatState.coolerTransition = true;
				LoadingState.loadAndSwitchState(new PlayState(), true, false);
			}
		}
		else if (PlayerSettings.controls.is(RESET))
		{
			persistentUpdate = false;

			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		else if (FlxG.keys.anyJustPressed(openModKeys))
		{
			var songPath:String = Paths.formatToSongPath(songs[curSelected].songName);
			var modTextPath:String = 'songs:' + Paths.getPath('songs/$songPath/mod/link.txt', TEXT);

			if (Assets.exists(modTextPath, TEXT))
				CoolUtil.browserLoad(Assets.getText(modTextPath));
		}
		super.update(elapsed);
	}

	override function closeSubState()
	{
		persistentUpdate = true;
		super.closeSubState();
	}

	public inline function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));

	private inline function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.data.startUnlocked
			&& leWeek.data.weekBefore.length > 0
			&& (!StoryMenuState.weekCompleted.exists(leWeek.data.weekBefore)
				|| !StoryMenuState.weekCompleted.get(leWeek.data.weekBefore)));
	}

	private function changeDiff(change:Int = 0)
	{
		curDifficulty = CoolUtil.repeat(curDifficulty, change, CoolUtil.difficulties.length);
		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		var selectedSongName:String = songs[curSelected].songName;

		intendedScore = Highscore.getScore(selectedSongName, curDifficulty);
		intendedRating = Highscore.getRating(selectedSongName, curDifficulty);

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = '< ' + CoolUtil.difficultyString() + ' >';

		positionHighscore();
	}

	private function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), .4);

		curSelected = CoolUtil.repeat(curSelected, change, songs.length);
		var curSong:SongMetadata = songs[curSelected];

		var songName:String = curSong.songName;
		var songPath:String = Paths.formatToSongPath(songName);

		var modIconPath:String = 'songs:' + Paths.getPath('songs/$songPath/mod/icon.png', IMAGE);

		var modTextVisible:Bool = Assets.exists('songs:' + Paths.getPath('songs/$songPath/mod/link.txt', TEXT), TEXT);
		var modIconVisible:Bool = Assets.exists(modIconPath, IMAGE);

		if (modLinkTween != null)
		{
			modLinkTween.cancel();
			modLinkTween.destroy();

			modLinkTween = null;
		}
		modLinkGroup.visible = modTextVisible || modIconVisible;

		modIcon.visible = modIconVisible;
		modLink.visible = modTextVisible;

		if (modIconVisible)
		{
			modIcon.loadGraphic(Paths.returnGraphic(modIconPath));
			switch (modIcon.width > modIcon.height)
			{
				case true:
					modIcon.setGraphicSize(ICON_RESOLUTION);
				default:
					modIcon.setGraphicSize(0, ICON_RESOLUTION);
			}
			modIcon.updateHitbox();

			modIcon.x = modLink.x + ((modLink.width - modIcon.width) / 2);
			modIcon.y = (modLink.y - modIcon.height) - 4;
		}
		if (modTextVisible || modIconVisible)
		{
			modLinkGroup.x = FlxG.width + (ICON_RESOLUTION * .5);
			modLinkTween = FlxTween.tween(modLinkGroup, { x: FlxG.width - (ICON_RESOLUTION + (ICON_RESOLUTION / 8)) }, .5, { ease: FlxEase.quintOut, onComplete: function(twn:FlxTween) {
				twn.destroy();
				modLinkTween = null;
			} });
		}

		var newColor:Int = curSong.color;
		if (newColor != intendedColor)
		{
			colorTween?.cancel();
			colorTween?.destroy();

			colorTween = null;

			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween)
				{
					colorTween = null;
					twn.destroy();
				}
			});
		}

		intendedScore = Highscore.getScore(songPath, curDifficulty);
		intendedRating = Highscore.getRating(songPath, curDifficulty);

		var bullShit:Int = 0;
		for (i in 0...iconArray.length)
			iconArray[i].alpha = i == curSelected ? 1 : .6;

		grpSongs.forEachAlive(function(item:Alphabet) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = item.targetY == 0 ? 1 : .6;
		});

		PlayState.storyWeek = songs[curSelected].week;
		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();

		var diffStr:String = WeekData.getCurrentWeek()?.data?.difficulties?.trim();
		if (diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var index:Int = diffs.length;

			while (index-- >= 0)
			{
				if (diffs[index] != null)
				{
					diffs[index] = diffs[index].trim();
					if (diffs[index].length < 1)
						diffs.remove(diffs[index]);
				}
			}
			if (diffs.length > 0 && diffs[0].length > 0)
				CoolUtil.difficulties = diffs;
		}
		curDifficulty = CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty) ? Std.int(Math.max(0,
			CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty))) : 0;

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		if (newPos > -1)
			curDifficulty = newPos;
		changeDiff();
		FreeplayState.panels[selectedMenu][2] = curSelected;
	}

	private inline function positionHighscore()
	{
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);

		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}
}

class SongMetadata
{
	public var songCharacter:String = "";

	public var songName:String = "";
	public var folder:String = "";

	public var color:Int = -7179779;
	public var week:Int = 0;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;

		this.songCharacter = songCharacter;
		this.color = color;
	}
}
