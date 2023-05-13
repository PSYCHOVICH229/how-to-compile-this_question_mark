package states.arcade;

import meta.data.ClientPrefs;
import states.substates.MusicBeatSubstate;
import flixel.util.FlxAxes;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;

class ArcadeSubstate extends MusicBeatSubstate
{
	var mainCamera:FlxCamera;

	override function new(camera:FlxCamera)
	{
		mainCamera = camera;
		super();
	}

	// helper function because im lazy as shit
	private inline function makeSprite(x:Float = 0, y:Float = 0, antialiasing:Bool = true, scrollX:Float = 0, scrollY:Float = 0):FlxSprite
	{
		var sprite:FlxSprite = new FlxSprite(x, y);
		sprite.antialiasing = antialiasing && ClientPrefs.getPref('globalAntialiasing');

		sprite.scrollFactor.set(scrollX, scrollY);
		sprite.cameras = [mainCamera];

		return sprite;
	}

	private inline function centerObject(object:FlxObject, ?axes:FlxAxes = XY, ?relative:FlxObject)
	{
		if (axes.x)
			object.x = (relative?.x ?? 0.) + ((relative?.width ?? cast(mainCamera.width, Float)) - object.width) / 2;
		if (axes.y)
			object.y = (relative?.y ?? 0.) + ((relative?.height ?? cast(mainCamera.height, Float)) - object.height) / 2;
	}

	public function onCloseRequest():Bool
	{
		trace('CLOSING ARCADE SUBSTATE');
		return true;
	}

	public function onAcceptRequest():Void
	{
		trace('ACCEPTED ARCADE INPUT');
	}
}
