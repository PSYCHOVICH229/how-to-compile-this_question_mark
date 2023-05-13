package states.substates;

import states.options.OptionsState;
import states.options.BaseOptionsMenu;
import meta.PlayerSettings;
import states.freeplay.FreeplayState;
import meta.data.ClientPrefs;
import meta.CoolUtil;
import meta.data.Highscore;
import meta.data.Song;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import meta.instances.Alphabet;
import meta.Conductor;
import states.substates.pauses.*;

class PauseSubState extends MusicBeatSubstate
{
	private var grpMenuShit:FlxTypedGroup<Alphabet>;

	private var mainMenuItems:Array<String> = ['Resume', 'Restart Song', 'Options', 'Exit to Menu'];
	private var menuItems:Array<String>;

	private var difficultyChoices = [];
	private var curSelected:Int = 0;

	private var skipTimeText:FlxText;
	private var skipTimeTracker:Alphabet;

	private var curTime:Float = Math.max(0, Conductor.songPosition);

	private var holdTime:Float = 0;
	private var cantUnpause:Float = .1;

	// var botplayText:FlxText;
	public static var songName:String = null;
	public static var isFNM:Bool = false;

	public var pauseEffect:BasePause;
	public var pauseMusic:FlxSound;

	public var hadBotplayEnabled:Bool = false;

	public function new(x:Float, y:Float)
	{
		super();

		var instance:PlayState = PlayState.instance;
		hadBotplayEnabled = #if debug true #else instance?.cpuControlled ?? false #end;

		var num:Int = 0;
		if (CoolUtil.difficulties.length > 1)
		{
			mainMenuItems.insert(2, 'Change Difficulty'); // No need to change difficulty if there is only one!
			num++;
		}
		if (PlayState.chartingMode)
		{
			mainMenuItems.insert(2 + num, 'Leave Charting Mode');
			if (instance != null && !instance.startingSong)
			{
				mainMenuItems.insert(3 + num, 'Skip Time');
				num++;
			}

			mainMenuItems.insert(4 + num, 'End Song');
			mainMenuItems.insert(5 + num, 'Toggle Botplay');
		}
		else if (hadBotplayEnabled)
		{
			mainMenuItems.insert(1 + num, 'Toggle Botplay');
		}

		menuItems = mainMenuItems;
		for (difficulty in CoolUtil.difficulties)
			difficultyChoices.push(difficulty);

		difficultyChoices.push('BACK');
		pauseMusic = new FlxSound();

		if (songName != null)
		{
			pauseMusic.loadEmbedded(Paths.music(songName), true, true);
		}
		else
		{
			// this causes an error with old saves
			var path:String = Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic'));
			pauseEffect = isFNM ? new Default(this) : switch (path)
			{
				case 'shuttle-man': new ShuttleMan(this);
				case 'breakfast': new Breakfast(this);
				case 'scratch': new Scratch(this);
				case 'pulse': new Pulse(this);

				default: new Default(this);
			};
			if (path != null && path != 'none' && path.length > 0 && !isFNM)
				pauseMusic.loadEmbedded(Paths.music(path), true, true);
		}
		if (pauseEffect != null)
			add(pauseEffect);

		pauseMusic.volume = 0;
		pauseMusic.play(true);

		FlxG.sound.list.add(pauseMusic);
		if (!isFNM)
		{
			var levelInfo:FlxText = new FlxText(0, 0, FlxG.width,
				PlayState.SONG.song + '\n' + CoolUtil.difficultyString() + '\nhorse dogs: ' + PlayState.deathCounter, 32);
			levelInfo.scrollFactor.set();

			levelInfo.setFormat(Paths.font("comic.ttf"), 32, FlxColor.WHITE, RIGHT);
			levelInfo.updateHitbox();

			add(levelInfo);
			levelInfo.alpha = 0;

			levelInfo.x = FlxG.width - (levelInfo.width + 20);
			levelInfo.y = -levelInfo.height;

			FlxTween.tween(levelInfo, {alpha: 1, y: 0}, .4, {ease: FlxEase.quartInOut, startDelay: .2});
		}

		var chartingText:FlxText = new FlxText(0, 0, 0, "CHARTING MODE", 32);
		chartingText.scrollFactor.set();

		chartingText.setFormat(Paths.font("vcr.ttf"), 32);
		chartingText.updateHitbox();

		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.y = FlxG.height - (chartingText.height + 20);

		chartingText.visible = PlayState.chartingMode;
		add(chartingText);

		grpMenuShit = new FlxTypedGroup();

		add(grpMenuShit);
		regenMenu();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		pauseMusic.volume = Math.min(pauseMusic.volume + (.1 * elapsed), 1);
		updateSkipTextStuff();

		var verticalDelta:Int = PlayerSettings.controls.diff(UI_DOWN, UI_UP, JUST_PRESSED, JUST_PRESSED);
		var accepted = PlayerSettings.controls.is(ACCEPT);

		if (verticalDelta != 0)
			changeSelection(verticalDelta);

		var daSelected:String = menuItems[curSelected];
		switch (Paths.formatToSongPath(daSelected))
		{
			case 'skip-time':
				{
					var horziontalDelta:Int = PlayerSettings.controls.diff(UI_RIGHT, UI_LEFT, JUST_PRESSED, JUST_PRESSED);
					if (horziontalDelta != 0)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'), .4);

						curTime += horziontalDelta * 1000;
						holdTime = 0;
					}
					if (PlayerSettings.controls.is(UI_LEFT, PRESSED) || PlayerSettings.controls.is(UI_RIGHT, PRESSED))
					{
						holdTime += elapsed;
						if (holdTime > .5)
							curTime += 45000 * elapsed * (PlayerSettings.controls.is(UI_LEFT, PRESSED) ? -1 : 1);

						var length:Float = FlxG.sound.music.length;

						if (curTime >= length)
						{
							curTime %= length;
						}
						else if (curTime < 0)
						{
							curTime = Math.min((curTime % length) + length, length - 1000);
						}

						updateSkipTimeText();
					}
				}
		}

		if (accepted && (cantUnpause <= 0 || !ClientPrefs.getPref('controllerMode')))
		{
			if (menuItems == difficultyChoices)
			{
				if (menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected))
				{
					if (curSelected != PlayState.storyDifficulty)
					{
						var name:String = PlayState.SONG.song;
						var poop = CoolUtil.getDifficultyFilePath(curSelected); // Highscore.formatSong(name, curSelected);

						PlayState.SONG = Song.loadFromJson(poop, name);
						PlayState.storyDifficulty = curSelected;

						MusicBeatState.resetState();

						FlxG.sound.music.volume = 0;
						PlayState.mechanicsEnabled = ClientPrefs.getPref('mechanics');

						PlayState.changedDifficulty = true;
						PlayState.chartingMode = false;
					}
					return;
				}

				menuItems = mainMenuItems;
				regenMenu();
			}

			var instance:PlayState = PlayState.instance;
			switch (Paths.formatToSongPath(daSelected))
			{
				case "resume":
					{
						if (isFNM)
							FlxG.sound.play(Paths.sound('fnm_confirmMenu', 'fnm'), .4);
						close();
					}
				case 'change-difficulty':
					{
						menuItems = difficultyChoices;

						deleteSkipTimeText();
						regenMenu();
					}

				case "restart-song":
					restartSong();
				case "options":
					{
						trace('option menu');

						CustomFadeTransition.nextCamera = instance?.camOther;
						OptionsState.toPlayState = CustomFadeTransition.playTitleMusic = true;

						MusicBeatState.switchState(new OptionsState());
					}

				case "leave-charting-mode":
					{
						restartSong();
						PlayState.chartingMode = false;
					}
				case 'skip-time':
					{
						if (curTime < Conductor.songPosition)
						{
							PlayState.startOnTime = curTime;
							restartSong(true);
						}
						else
						{
							if (instance != null && curTime != Conductor.songPosition)
							{
								instance.clearNotesBefore(curTime);
								instance.setSongTime(curTime);
							}
							close();
						}
					}
				case "end-song":
					{
						PlayState.mechanicsEnabled = ClientPrefs.getPref('mechanics');
						close();

						if (instance != null)
							instance.finishSong(true);
					}
				case 'toggle-botplay':
					{
						if (instance != null)
						{
							ClientPrefs.gameplaySettings.set('botplay', instance.botplayTxt.visible = instance.cpuControlled = !instance.cpuControlled);
							ClientPrefs.saveSettings();

							PlayState.changedDifficulty = true;

							instance.botplayTxt.alpha = 1;
							instance.botplaySine = 0;
						}
					}
				case "exit-to-menu":
					{
						PlayState.mechanicsEnabled = ClientPrefs.getPref('mechanics');

						PlayState.seenCutscene = false;
						PlayState.deathCounter = 0;

						FlxTransitionableState.skipNextTransIn = false;

						CustomFadeTransition.nextCamera = instance?.camOther;
						CustomFadeTransition.playTitleMusic = MusicBeatState.coolerTransition = true;

						if (instance != null)
							instance.cancelMusicFadeTween();
						if (PlayState.isStoryMode)
						{
							MusicBeatState.switchState(new StoryMenuState());
						}
						else
						{
							FreeplayState.exitToFreeplay();
						}
						PlayState.changedDifficulty = PlayState.chartingMode = false;
					}
			}
		}
	}

	public inline static function restartSong(noTrans:Bool = false)
	{
		var instance:PlayState = PlayState.instance;
		if (instance != null)
		{
			var vocals:FlxSound = instance.vocals;
			instance.paused = true;

			if (vocals != null)
				vocals.volume = 0;
		}

		FlxG.sound.music.volume = 0;
		if (noTrans)
		{
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		}
		else
		{
			CustomFadeTransition.nextCamera = PlayState.instance?.camOther;
			MusicBeatState.resetState();
		}
	}

	override function destroy()
	{
		pauseMusic.destroy();
		if (pauseEffect != null)
		{
			remove(pauseEffect);
			pauseEffect.destroy();
		}
		super.destroy();
	}

	private inline function changeSelection(change:Int = 0):Void
	{
		curSelected = CoolUtil.repeat(curSelected, change, menuItems.length);
		FlxG.sound.play(Paths.sound(isFNM ? 'fnm_scrollMenu' : 'scrollMenu', isFNM ? 'fnm' : null), .4);

		var bullShit:Int = 0;
		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = .6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
				if (item == skipTimeTracker)
				{
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}
		}
	}

	private inline function regenMenu():Void
	{
		grpMenuShit.forEach(function(obj:Alphabet)
		{
			obj.kill();
			grpMenuShit.remove(obj);
			obj.destroy();
		});
		grpMenuShit.clear();
		for (i in 0...menuItems.length)
		{
			var item = new Alphabet(90, 320, menuItems[i], true /*!isFNM , isFNM (todo: add this back ??)*/);

			item.isMenuItem = true;
			item.targetY = i;

			grpMenuShit.add(item);
			if (Paths.formatToSongPath(menuItems[i]) == 'skip-time')
			{
				skipTimeText = new FlxText(0, 0, 0, '', 64);
				skipTimeText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

				skipTimeText.scrollFactor.set();
				skipTimeText.borderSize = 2;

				skipTimeTracker = item;
				add(skipTimeText);

				updateSkipTextStuff();
				updateSkipTimeText();
			}
		}
		curSelected = 0;
		changeSelection();
	}

	private inline function deleteSkipTimeText()
	{
		if (skipTimeText != null)
		{
			skipTimeText.kill();
			remove(skipTimeText, true);
			skipTimeText.destroy();
		}

		skipTimeText = null;
		skipTimeTracker = null;
	}

	private function updateSkipTextStuff()
	{
		if (skipTimeText != null && skipTimeTracker != null)
		{
			skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
			skipTimeText.y = skipTimeTracker.y;

			skipTimeText.visible = (skipTimeTracker.alpha >= 1);
		}
	}

	private inline function updateSkipTimeText()
	{
		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false)
			+ ' / '
			+ FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	}
}
