package meta;

import flixel.FlxG;

class PlayerSettings
{
	public static var controls(get, null):Controls;

	public static function init():Void
	{
		get_controls();

		var numGamepads = FlxG.gamepads.numActiveGamepads;
		if (numGamepads > 0)
		{
			var gamepad = FlxG.gamepads.getByID(0);
			if (gamepad == null)
				throw 'Unexpected null gamepad. id:0';
		}
	}

	private static function get_controls():Controls
	{
		if (controls == null)
			return controls = new Controls('clientControls', Solo);
		return controls;
	}
}
