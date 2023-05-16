#if GAMEJOLT_ALLOWED
package states.gamejolt;

import meta.data.ClientPrefs;
import flixel.FlxCamera;
import states.gamejolt.FlxGameJoltCustom;
import meta.Achievements;

using StringTools;

class GameJolt
{
	public static function isLoggedIn():Bool
	{
		return FlxGameJoltCustom.username != FlxGameJoltCustom.NO_USERNAME && FlxGameJoltCustom.usertoken != FlxGameJoltCustom.NO_TOKEN;
	}

	public static function awardAchievement(?instance:Dynamic, ?camera:FlxCamera):Void
	{
		if (isLoggedIn() && instance != null)
		{
			var achievement:Achievement = Achievement.makeAchievement('game_joooj', camera);
			if (achievement != null)
				instance.add(achievement);
		}
	}

	public static function unlockTrophy(achievement:String):Void
	{
		if (isLoggedIn())
		{
			var index:Array<Dynamic> = Achievements.getAchievementIndex(achievement);
			if (index != null)
			{
				var trophy:Dynamic = index[3];
				if (trophy != null)
				{
					trace('found $achievement as id $trophy');
					FlxGameJoltCustom.addTrophy(trophy, function(map:Map<String, String>)
					{
						trace('trophy added: $map');
					});
				}
			}
		}
	}

	public static function loadAccount(username:String, token:String, award:Bool = false, ?instance:Dynamic, ?camera:FlxCamera, ?callback:() -> Void):Void
	{
		if (isLoggedIn())
			return;
		FlxGameJoltCustom.authUser(username, token, function(successful:Bool)
		{
			if (successful)
			{
				trace('logged in :3');
				if (award)
					awardAchievement(instance, camera);

				// #if !debug
				trace('sync game achievements !!');
				for (name => unlocked in Achievements.achievementsUnlocked)
				{
					if (unlocked)
					{
						trace('unlock gamejolt achievement $name');
						unlockTrophy(name);
					}
				}
				// #end
				trace('sync unlocked gamejolt achievmeents !!!');
				var achievements:Array<Array<Dynamic>> = Achievements.achievements;

				var length:Int = achievements.length - 1;
				var iterator:Int = 0;

				function iterate()
				{
					var achievement:Array<Dynamic> = achievements[iterator];
					if (achievement != null)
					{
						FlxGameJoltCustom.fetchTrophy(achievement[3], function(fetched:Map<String, String>)
						{
							if (fetched.get('success') == 'true' && (fetched.exists('achieved') && fetched.get('achieved') == 'true'))
							{
								var name:String = achievement[0];

								trace('SYNCING $name');
								Achievements.unlockAchievement(name);
							}
							if (iterator < length)
							{
								iterator++;
								iterate();
							}
						});
					}
				}
				iterate();

				ClientPrefs.prefs.set('gameJoltUsername', FlxGameJoltCustom.username);
				ClientPrefs.prefs.set('gameJoltToken', FlxGameJoltCustom.usertoken);

				ClientPrefs.saveSettings();
				if (callback != null)
					callback();
			}
		});
	}
}
#end
