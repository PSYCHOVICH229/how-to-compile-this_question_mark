package meta.data;

import openfl.Lib;
import lime.ui.Window;
import states.freeplay.FreeplayState;
import states.StoryMenuState;
#if GAMEJOLT_ALLOWED
import states.gamejolt.FlxGameJoltCustom;
#end
import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import meta.Controls;

class ClientPrefs
{
	// A map of every user-made preference
	public static final prefs:Map<String, Dynamic> = [
		// FUNNYING
		'freeplay' => [
			true,
			false,
			false
		], // Array<Bool>
		'hitsound' => 'Default', // String
		'scrollUnderlay' => 0, // WHY IS THIS NOT IN NATIVE PHYSICS	// Float
		'reducedMotion' => false, // Bool
		'flashWarning' => false, // Bool
		'subtitles' => true, // Bool
		'mechanics' => true, // Bool
		#if !web
		'fullscreen' => false, // Bool
		#end
		// UNLOCKABLES
		'visitedArcade' => false, // Bool
		'killgames' => false, // Bool
		'bendHard' => false, // Bool
		// GAMEJOLT
		#if GAMEJOLT_ALLOWED
		'gameJoltUsername' => FlxGameJoltCustom.NO_USERNAME, // String
		'gameJoltToken' => FlxGameJoltCustom.NO_TOKEN, // String
		#end
		// PHYSICS ENGINE
		'healthBarAlpha' => 1, // Float
		'hitsoundVolume' => 0, // Float
		'globalAntialiasing' => true, // Bool
		'controllerMode' => false, // Bool
		'opponentStrums' => true, // Bool
		'ghostTapping' => true, // Bool
		'lowQuality' => false, // Bool
		'shaders' => true, // Bool
		'noteSplashes' => true, // Bool
		'middleScroll' => false, // Bool
		'downScroll' => false, // Bool
		'scoreZoom' => true, // Bool
		'noReset' => false, // Bool
		'flashing' => true, // Bool
		'camZooms' => true, // Bool
		'hideHUD' => false, // Bool
		'showFPS' => false, // Bool
		'comboStacking' => true, // Bool
		'timeBarType' => 'time-left', // String
		'pauseMusic' => 'pulse', // String
		'noteOffset' => 0, // Int
		'framerate' => 60, // Int
		'comboOffset' => [0, 0, 0, 0, 0, 0], // Array<Int>
		// PRIVATE
		'ratingOffset' => 0, // Int

		'funnyWindow' => 45, // Int
		'googWindow' => 90, // Int
		'badWindow' => 135, // Int
		'safeFrames' => 10, // Int
		// CHARTING
		'chart_waveformVoices' => false, // Bool
		'chart_waveformInst' => false, // Bool

		'chart_vortex' => false, // Bool

		'chart_playSoundDad' => false, // Bool
		'chart_playSoundBf' => false, // Bool

		'chart_noAutoScroll' => false, // Bool
		'chart_metronome' => false, // Bool

		'mouseScrollingQuant' => false, // Bool
		'ignoreWarnings' => false, // Bool

		'autosave' => null // JSON
	];
	// For custom functions before the save data is loaded, for conversion and stuff
	public static final beforeFunctions:Map<String, (Dynamic) -> Dynamic> = [
		'customControls' => function(controls:Map<String, Array<FlxKey>>):Dynamic
		{
			trace('CHECK LEGACY FORMAT');
			trace(controls);

			var newControls:Dynamic = controls;
			for (key => mapping in keyBinds)
			{
				if (newControls.exists(key))
				{
					var poop:Array<Dynamic> = newControls.get(key);
					var isMapped:Bool = isControl(mapping);

					if (isMapped && isControl(poop) != isMapped)
					{
						trace('FUCK ! SHIT ! $key');
						newControls.set(key, [getKeyArray(poop), mapping[1]]);
					}
				}
			}
			return newControls;
		}
	];
	// For custom functions after the save data is loaded
	public static final loadFunctions:Map<String, (Dynamic) -> Void> = [
		'showFPS' => function(showFPS:Bool)
		{
			if (BALLFART.fpsVar != null)
				BALLFART.fpsVar.visible = showFPS;
		},
		#if !web
		'fullscreen' => function(fullscreen:Bool)
		{
			var window:Window = Lib.application.window;
			if (window != null)
				window.fullscreen = fullscreen;
			FlxG.fullscreen = fullscreen;
		},
		#end
		'framerate' => function(framerate:Int)
		{
			// trace('framerate $framerate');
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
		},
		'customControls' => function(controls:Map<String, Array<FlxKey>>)
		{
			trace('reload controls');
			reloadControls();
		}
	];
	// Flixel data to load, i.e 'muted' or 'volume'
	public static final flixelData:Map<String, String> = ['volume' => 'volume', 'mute' => 'muted'];
	// Maps like gameplaySettings
	public static final mapData:Map<String, Array<Dynamic>> = [
		// FlxG.save.data.*		Class, Map Name
		'achievementsUnlocked' => [Achievements, 'achievementsUnlocked'],
		'gameplaySettings' => [ClientPrefs, 'gameplaySettings'],
		'weekCompleted' => [StoryMenuState, 'weekCompleted'],
		'customControls' => [ClientPrefs, 'keyBinds'],
		'weekScores' => [Highscore, 'weekScores'],
		'songScores' => [Highscore, 'songScores'],
		'songRating' => [Highscore, 'songRating']
	];
	// For stuff that needs to be in the controls_v2 save
	public static final separateSaves:Array<String> = ['customControls' #if GAMEJOLT_ALLOWED, 'gameJoltUsername', 'gameJoltToken' #end];
	public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		'songspeed' => 1.0,
		'botplay' => false
	];
	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<Dynamic>> = [
		// Key Bind, Name for ControlsSubState
		'note_right' => [[D, RIGHT], NOTE_RIGHT],
		'note_down' => [[S, DOWN], NOTE_DOWN],
		'note_left' => [[A, LEFT], NOTE_LEFT],
		'note_up' => [[W, UP], NOTE_UP],
		'ui_right' => [[D, RIGHT], UI_RIGHT],
		'ui_down' => [[S, DOWN], UI_DOWN],
		'ui_left' => [[A, LEFT], UI_LEFT],
		'ui_up' => [[W, UP], UI_UP],
		'back' => [[BACKSPACE, ESCAPE], BACK],
		'accept' => [[SPACE, ENTER], ACCEPT],
		'pause' => [[ENTER, ESCAPE], PAUSE],
		'reset' => [[R], RESET],
		'hit' => [[SPACE], HIT],
		// OTHER SHIT
		'volume_down' => [NUMPADMINUS, MINUS],
		'volume_up' => [NUMPADPLUS, PLUS],
		'volume_mute' => [ZERO],
		'debug_1' => [SEVEN],
		'debug_2' => [EIGHT],
		'debug_3' => [ONE],
		'debug_4' => [TWO]
	];

	public static var defaultKeys:Map<String, Array<Dynamic>> = null;
	public inline static function saveSettings()
	{
		var mainSave:FlxSave = FlxG.save;
		for (setting => value in prefs)
		{
			// trace('saving $setting!');
			if (!separateSaves.contains(setting))
				Reflect.setProperty(mainSave.data, setting, value);
		}
		for (savedAs => map in mapData)
		{
			// trace('saving map $savedAs as ${map[1]}!');
			if (!separateSaves.contains(savedAs))
				Reflect.setProperty(mainSave.data, savedAs, Reflect.getProperty(map[0], map[1]));
		}
		mainSave.flush();

		var save:FlxSave = new FlxSave();
		save.bind(BALLFART.CONTROL_BIND); // Placing this in a separate save so that it can be manually deleted without removing your Score and stuff

		for (name in separateSaves)
		{
			// trace('saving $name in separate save!');
			if (prefs.exists(name))
			{
				Reflect.setProperty(save.data, name, prefs.get(name));
				continue;
			}
			if (mapData.exists(name))
			{
				var map:Array<Dynamic> = mapData.get(name);
				Reflect.setProperty(save.data, name, Reflect.getProperty(map[0], map[1]));
				continue;
			}
		}

		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public inline static function loadPrefs()
	{
		trace('LOADING PREFS');

		var save:Dynamic = FlxG.save.data;
		for (setting in prefs.keys())
		{
			var value:Dynamic = Reflect.getProperty(save, setting);
			if (value != null && !separateSaves.contains(setting))
			{
				// trace('loading $setting!');
				if (beforeFunctions.exists(setting))
					value = beforeFunctions.get(setting)(value);
				prefs.set(setting, value);
				if (loadFunctions.exists(setting))
					loadFunctions.get(setting)(value); // Call the load function
			}
		}
		// flixel automatically saves your volume!
		for (setting => name in flixelData)
		{
			// trace('loading flixel $setting!');

			var value:Dynamic = Reflect.getProperty(save, setting);
			if (value != null)
				Reflect.setProperty(FlxG.sound, name, value);
		}
		// This needs to be loaded differently
		for (savedAs => map in mapData)
		{
			var data:Map<Dynamic, Dynamic> = Reflect.getProperty(save, savedAs);
			if (data != null)
			{
				// trace('loading map $savedAs as ${map[1]}!');
				if (beforeFunctions.exists(savedAs))
					data = beforeFunctions.get(savedAs)(data);

				var loadTo:Map<Dynamic, Dynamic> = Reflect.getProperty(map[0], map[1]);
				for (key => value in data)
					loadTo.set(key, value);
				if (loadFunctions.exists(savedAs))
					loadFunctions.get(savedAs)(data); // Call the load function
			}
		}

		var save:FlxSave = new FlxSave();
		save.bind(BALLFART.CONTROL_BIND);
		if (save != null)
		{
			for (name in separateSaves)
			{
				var data:Dynamic = Reflect.getProperty(save.data, name);
				if (data != null)
				{
					// trace('loading $name in separate save!');
					if (prefs.exists(name))
					{
						if (beforeFunctions.exists(name))
							data = beforeFunctions.get(name)(data);
						prefs.set(name, data);
						continue;
					}
					if (mapData.exists(name))
					{
						var diabolical:Map<Dynamic, Dynamic> = data;
						var map:Array<Dynamic> = mapData.get(name);

						if (beforeFunctions.exists(name))
							diabolical = beforeFunctions.get(name)(data);
						// trace('loading map $name as ${map[1]}!');
						var loadTo:Map<Dynamic, Dynamic> = Reflect.getProperty(map[0], map[1]);
						for (key => value in diabolical)
							loadTo.set(key, value);
						if (loadFunctions.exists(name))
							loadFunctions.get(name)(diabolical); // Call the load function
						continue;
					}
				}
			}
		}
	}

	public static function onChangeSetting(theSettingInQuestion:String):Void
	{
		if (loadFunctions.exists(theSettingInQuestion))
			loadFunctions.get(theSettingInQuestion)(getPref(theSettingInQuestion));
	}

	public inline static function reloadControls()
	{
		PlayerSettings.controls.setKeyboardScheme(Solo);
		CoolUtil.toggleVolumeKeys(true);
	}

	public inline static function loadDefaultKeys()
		defaultKeys = keyBinds.copy();

	public inline static function isControl(arrayOf:Array<Dynamic>):Bool
		return Std.isOfType(arrayOf[1], Control);

	public inline static function getKeyArray(arrayOf:Dynamic):Array<FlxKey>
		return isControl(arrayOf) ? arrayOf[0] : arrayOf;

	public inline static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic
		return gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue;

	public inline static function getPref(name:String, ?defaultValue:Dynamic):Dynamic
	{
		if (prefs.exists(name))
			return prefs.get(name);
		return defaultValue;
	}

	public inline static function setKey(keyName:String, keys:Array<FlxKey>)
	{
		trace(keyName);
		if (keyBinds.exists(keyName))
		{
			trace('BINDING!');
			var currentKey:Array<Dynamic> = keyBinds.get(keyName);

			if (isControl(currentKey))
			{
				currentKey[0] = keys;
			}
			else
			{
				keyBinds.set(keyName, keys);
			}
		}
	}

	public inline static function copyKey(arrayToCopy:Array<Dynamic>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = getKeyArray(arrayToCopy).copy();
		var index:Int = 0;
		// Still need this for old save support
		while (index < copiedArray.length)
		{
			if (copiedArray[index] == NONE)
			{
				copiedArray.remove(NONE);
				index--;
			}
			index++;
		}
		return copiedArray;
	}
}
