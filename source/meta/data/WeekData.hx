package meta.data;

import states.StoryMenuState;
import haxe.Json;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import states.PlayState;

using StringTools;

typedef WeekFile =
{
	// JSON variables
	var songs:Array<Dynamic>;

	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var freeplayColor:Array<Int>;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var difficulties:String;
}

class WeekData
{
	public static var weeksLoaded:Map<String, WeekData> = new Map();
	public static var weeksList:Array<String> = [];

	// JSON variables
	public var data:WeekFile;
	public var fileName:String;

	// clean code? FUCK YEAAAAAAAH
	public function new(weekFile:WeekFile, fileName:String)
	{
		this.data = weekFile;
		this.fileName = fileName;
	}

	public inline static function reloadWeekFiles(isStoryMode:Null<Bool> = false, list:Array<String>)
	{
		weeksList = [];
		weeksLoaded.clear();

		var directories:Array<String> = [Paths.getPreloadPath()];
		for (i in 0...list.length)
		{
			for (j in 0...directories.length)
			{
				var fileToCheck:String = directories[j] + 'weeks/' + list[i] + '.json';
				if (!weeksLoaded.exists(list[i]))
				{
					var week:WeekFile = getWeekFile(fileToCheck);
					if (week != null)
					{
						var weekFile:WeekData = new WeekData(week, list[i]);
						if (weekFile != null
							&& (isStoryMode == null
								|| (isStoryMode && !weekFile.data.hideStoryMode)
								|| (!isStoryMode && !weekFile.data.hideFreeplay)))
						{
							weeksLoaded.set(list[i], weekFile);
							weeksList.push(list[i]);
						}
					}
				}
			}
		}
	}

	private static function getWeekFile(path:String):WeekFile
	{
		if (OpenFlAssets.exists(path))
		{
			var rawJson:String = Assets.getText(path).trim();
			if (rawJson.length > 0)
				return cast Json.parse(rawJson);
		}
		return null;
	}

	// FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE
	// To use on PlayState.hx or Highscore stuff
	public inline static function getWeekFileName():String
		return weeksList[PlayState.storyWeek];

	// Used on LoadingState, nothing really too relevant
	public inline static function getCurrentWeek():WeekData
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);

	public inline static function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = weeksLoaded.get(name);
		return !leWeek.data.startUnlocked
			&& leWeek.data.weekBefore.length > 0
			&& (!StoryMenuState.weekCompleted.exists(leWeek.data.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.data.weekBefore));
	}
}
