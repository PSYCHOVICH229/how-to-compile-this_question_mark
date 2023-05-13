package meta.data;

import openfl.Assets;
import haxe.Json;

using StringTools;

typedef SwagSong =
{
	var song:String;

	var notes:Array<SwagSection>;
	var events:Null<Array<Dynamic>>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var player1:String;
	var player2:String;
	var validScore:Bool;
	@:optional var stage:Null<String>;
	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;
}

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;

	var typeOfSection:Int;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

class Song
{
	public inline static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);

		var jsonPath:String = Paths.json(formattedFolder, formattedSong, 'songs');
		if (!Assets.exists(jsonPath))
			jsonPath = Paths.json('$formattedFolder-$formattedSong', formattedSong, 'songs');

		var rawJson:String = Assets.getText(jsonPath).trim();
		rawJson = rawJson.substr(0, rawJson.lastIndexOf('}') + 1);

		var songJson:SwagSong = parseJSONshit(rawJson);
		if (jsonInput != 'events')
			StageData.loadDirectory(songJson);

		onLoadJson(songJson);
		return songJson;
	}

	private inline static function onLoadJson(songJson:Dynamic) // Convert old charts to newest format
	{
		if (songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];
				var i:Int = 0;

				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;

				while (i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if (note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);

						len = notes.length;
						continue;
					}
					i++;
				}
			}
		}
	}

	public inline static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		return swagShit;
	}
}
