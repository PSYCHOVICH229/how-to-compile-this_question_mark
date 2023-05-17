#if GAMEJOLT_ALLOWED
package states.gamejolt;

import meta.data.ClientPrefs;
import flixel.FlxCamera;
import states.gamejolt.FlxGameJoltCustom;
import meta.Achievements;

using StringTools;

class GameJolt
{
	private inline static final ACHIEVEMENT_ACQUIRED:String = 'achieved';
	public inline static function isLoggedIn():Bool
	{
		return
			(FlxGameJoltCustom.username != FlxGameJoltCustom.NO_USERNAME && FlxGameJoltCustom.usertoken != FlxGameJoltCustom.NO_TOKEN)
			&& (FlxGameJoltCustom.username.length > 0 && FlxGameJoltCustom.usertoken.length > 0);
	}
	public inline static function awardAchievement(?instance:Dynamic, ?camera:FlxCamera):Void
	{
		if (isLoggedIn() && instance != null)
		{
			var achievement:Achievement = Achievement.makeAchievement('game_joooj', camera);
			if (achievement != null)
				instance.add(achievement);
		}
	}

	public inline static function unlockTrophy(achievement:String):Void
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

	public static function loadAccount(?username:String, ?token:String, award:Bool = false, ?instance:Dynamic, ?camera:FlxCamera, ?callback:() -> Void):Void
	{
		if (isLoggedIn() || username == null || token == null)
			return;
		FlxGameJoltCustom.authUser(username, token, function(successful:Bool)
		{
			if (successful)
			{
				trace('logged in :3');
				if (award)
					awardAchievement(instance, camera);
				trace('sync unlocked gamejolt achievmeents !!!');

				final achievements:Array<Array<Dynamic>> = Achievements.achievements;
				final length:Int = achievements.length - 1;

				if (length > 0)
				{
					function recurse(index:Int)
					{
						inline function increment()
						{
							if (index < length)
								recurse(index + 1);
						}

						final achievement:Array<Dynamic> = achievements[index];
						if (achievement != null)
						{
							final trophy:Dynamic = achievement[3];
							final name:String = achievement[0];

							if (trophy != null)
							{
								trace('$name/$trophy');

								final unlocked:Bool = Achievements.isAchievementUnlocked(name);
								FlxGameJoltCustom.fetchTrophy(trophy, function(fetched:Map<String, String>)
								{
									if (fetched.get('success') == 'true')
									{
										// !fetched.exists('trophies') is only there because hidden achievements are fucked for some reason, hope this is fixed soon
										if (!fetched.exists('trophies') && (!fetched.exists(ACHIEVEMENT_ACQUIRED) || (fetched.get(ACHIEVEMENT_ACQUIRED) != 'false')))
										{
											trace('SYNCING INGAME UNLOCK $name/$trophy');
											if (!unlocked)
												Achievements.unlockAchievement(name);
											increment();
										}
										else if (unlocked)
										{
											trace('SYNCING GAMEJOLT TROPHY $name/$trophy');
											FlxGameJoltCustom.addTrophy(trophy, function(map:Map<String, String>)
											{
												trace('trophy unlocked: $map');
												increment();
											});
										}
										return;
									}
									increment();
								});
							}
						}
					}
					recurse(0);
				}

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
