package meta.data;

import meta.instances.stages.*;
import meta.data.Song;
import haxe.Json;
import openfl.utils.Assets;

using StringTools;

typedef StageFile =
{
	var directory:String;
	var defaultZoom:Float;

	var boyfriend:Array<Dynamic>;
	var girlfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;
	var hide_girlfriend:Bool;
	var camera_boyfriend:Array<Float>;
	var camera_opponent:Array<Float>;
	var camera_girlfriend:Array<Float>;
	var scroll_boyfriend:Array<Float>;
	var scroll_opponent:Array<Float>;
	var scroll_girlfriend:Array<Float>;
	var camera_speed:Null<Float>;
}

class StageData
{
	public static var forceNextDirectory:String = null;

	public static function getStageClass(curStage:Null<String>):Dynamic
	{
		return switch (Paths.formatToSongPath(curStage))
		{
			case 'compressedstage': CompressedStage;

			case 'grass': Grass;
			case 'hell': Hell;

			case 'plains': Plains;

			case 'blam': Blam;
			case 'sewer': Sewer;

			case 'park': Park;
			case 'park-front': ParkFront;

			case 'carnival': Carnival;

			case 'relapse': Relapse;
			case 'week8': Week8;

			case 'banana': Banana;
			case 'squidgame': Squidgame;

			case 'mspaint': MSPaint;
			case 'kong': Kong;

			case 'forest': Forest;
			case 'fartingbear': Fartingbear;

			case 'shaggy': Shaggy;
			case 'cyborg': Cyborg;

			case 'auditorhell': AuditorHell;
			case 'bendhard': BendHard;

			case 'lobby': Lobby;
			case 'candygame': Candy;
			case 'field': Field;

			case 'opposition': Opposition;
			case 'screwed': Screwed;
			// this goes for indiecross too btw
			default: Stage;
		};
	}

	public static function getStage(curSong:String):Null<String>
	{
		return switch (Paths.formatToSongPath(curSong))
		{
			case 'tutorial': 'compressedstage';

			case 'gastric-bypass' | 'roided' | 'untitled': 'grass';
			case 'pyromania': 'hell';

			case 'cervix' | 'intestinal-failure' | 'funny-duo' | 'abrasive': 'plains';
			case 'relapse': 'relapse';

			case 'murked-up' | 'blamger': 'blam';
			case 'qico': 'sewer';

			case 'hotshot' | 'plot-armor': 'park';
			case 'funny-foreplay' | 'foursome': 'carnival';

			case 'tablebanger': 'week8';

			case 'banana': 'banana';
			case 'squidgames': 'squidgame';

			case 'braindead': 'mspaint';
			case 'the-kong': 'kong';

			case 'foolish': 'indiecross';
			case 'tampon': 'forest';

			case 'farting-bars': 'fartingbear';
			case 'shagy': 'shaggy';

			case 'expurgation': 'auditorhell';
			case 'poop-time': 'cyborg';

			case 'bend-hard': 'bendhard';
			case 'killgames': 'lobby';

			case 'opposition': 'opposition';
			case 'screwed': 'screwed';

			default: null;
		};
	}

	public inline static function loadDirectory(SONG:SwagSong):Void
	{
		var stageFile:StageFile = getStageFile(SONG?.stage ?? getStage(SONG.song));
		forceNextDirectory = stageFile?.directory ?? ''; // preventing crashes
	}

	public inline static function getStageFile(stage:Null<String>):Null<StageFile>
	{
		if (stage == null)
			return null;

		var path:String = Paths.getPreloadPath('stages/' + Paths.formatToSongPath(stage) + '.json');
		return Assets.exists(path) ? cast Json.parse(Assets.getText(path)) : null;
	}
}
