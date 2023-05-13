package meta;

using StringTools;

#if DISCORD_ALLOWED
import Sys.sleep;
import sys.thread.Thread;
import discord_rpc.DiscordRpc;
#end

class DiscordClient
{
	private inline static final LARGE_TEXT:String = "dead family(eaf myil(dead child dead family DEAFD FAMILY DEAD FAMILY)ORPHANGAGEd)I burnt down anfdead";
	public static var isInitialized:Bool = false;
	#if DISCORD_ALLOWED
	private static var curPresence:DiscordPresenceOptions;
	#end

	public function new()
	{
		#if DISCORD_ALLOWED
		trace("Discord Client starting...");
		DiscordRpc.start({
			clientID: "936804088807571457",
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});
		trace("Discord Client started.");
		while (isInitialized)
		{
			if (curPresence != null)
			{
				DiscordRpc.presence(curPresence);
				curPresence = null;
			}
			DiscordRpc.process();
			sleep(1);
		}
		DiscordRpc.shutdown();
		#end
	}

	public static function shutdown()
	{
		#if DISCORD_ALLOWED
		DiscordRpc.shutdown();
		#end
	}

	private static function onReady()
	{
		#if DISCORD_ALLOWED
		DiscordRpc.presence({
			details: #if NO_LEAKS 'NO LEAKS' #else "In the Menus" #end,
			largeImageKey: #if NO_LEAKS 'dread' #else 'iconog' #end,
			largeImageText: #if NO_LEAKS 'NO FUNNYING LEAKS', state: 'I WILL GUT YOU', smallImageKey: 'torture',
			smallImageText: 'FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU' #else LARGE_TEXT #end
		});
		#end
	}

	private static function onError(_code:Int, _message:String)
	{
		trace('Error! $_code : $_message');
	}

	private static function onDisconnected(_code:Int, _message:String)
	{
		trace('Disconnected! $_code : $_message');
	}

	public static function initialize()
	{
		#if DISCORD_ALLOWED
		var daemon:Thread = sys.thread.Thread.create(() ->
		{
			new DiscordClient();
		});
		isInitialized = true;

		trace("Discord Client initialized");
		trace(daemon);
		#end
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float)
	{
		#if DISCORD_ALLOWED
		#if NO_LEAKS
		// im gonna make this awesome tlayter
		#else
		var startTimestamp:Float = hasStartTimestamp ? Date.now().getTime() : 0;
		if (endTimestamp > 0 && hasStartTimestamp)
			endTimestamp = startTimestamp + endTimestamp;

		curPresence = {
			details: details,
			state: state,
			largeImageKey: 'iconog',
			largeImageText: LARGE_TEXT,
			smallImageKey: smallImageKey,
			// Obtained times are in milliseconds so they are divided so Discord can use it
			startTimestamp: hasStartTimestamp ? Std.int(startTimestamp / 1000) : null,
			endTimestamp: hasStartTimestamp ? Std.int(endTimestamp / 1000) : null
		};
		#end
		#end
	}
}
