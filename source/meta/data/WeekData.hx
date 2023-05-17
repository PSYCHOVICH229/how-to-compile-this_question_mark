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
	var weekName:String;

	var storyName:String;
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
	public final data:WeekFile;
	public final fileName:String;

	// clean code? FUCK YEAAAAAAAH
	public function new(weekFile:WeekFile, fileName:String)
	{
		this.data = weekFile;
		this.fileName = fileName;
	}

	public inline static function reloadWeekFiles(isStoryMode:Bool = false, list:Array<String>)
	{
		weeksList = [];
		weeksLoaded.clear();

		for (index in 0...list.length)
		{
			final week:String = list[index];
			if (!weeksLoaded.exists(week))
			{
				final meta:WeekFile = getWeekFile(week);
				if (meta != null)
				{
					final file:WeekData = new WeekData(meta, week);
					if (if (isStoryMode) !file.data.hideStoryMode else !file.data.hideFreeplay)
					{
						weeksLoaded.set(week, file);
						weeksList.push(week);
					}
				}
			}
		}
	}
	public static function getWeekFile(week:String):Null<WeekFile>
	{
		final path:String = Paths.getPreloadPath('weeks/$week.json');
		if (OpenFlAssets.exists(path))
		{
			var json:String = Assets.getText(path).trim();
			if (json.length > 0)
				return cast Json.parse(json);
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
