package meta;

import meta.data.ClientPrefs;
import flixel.input.FlxInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionSet;
import flixel.input.keyboard.FlxKey;

// i simplified the genuine fuck outta this shit lmfao
enum Control
{
	UI_RIGHT;
	UI_DOWN;
	UI_LEFT;
	UI_UP;

	NOTE_RIGHT;
	NOTE_DOWN;
	NOTE_LEFT;
	NOTE_UP;
	RESET;
	PAUSE;
	ACCEPT;
	BACK;
	HIT;
}

enum KeyboardScheme
{
	Solo;
	None;
}

private class ControlSet
{
	private var _actions:Map<FlxInputState, FlxActionDigital>;
	private var _firstAction:FlxActionDigital;

	private static var _stateSuffixes:Map<FlxInputState, String> = [JUST_RELEASED => '-released', JUST_PRESSED => '-pressed'];

	public function new(action:Control, actions:Array<FlxInputState>)
	{
		_actions = new Map();
		for (state in actions)
		{
			var actionName:String = action.getName();
			if (_stateSuffixes.exists(state))
				actionName += _stateSuffixes.get(state);

			var thisAction:FlxActionDigital = new FlxActionDigital(actionName);
			if (_firstAction == null)
				_firstAction = thisAction;
			_actions.set(state, thisAction);
		}
	}

	public inline function is(?state:FlxInputState):Bool
	{
		if (state != null)
			return _actions.exists(state) && _actions.get(state).check();
		return _firstAction?.check() ?? false;
	}
}

/**
 * A list of actions that a player would invoke via some input device.
 * Uses FlxActions to funnel various inputs to a single action.
 */
class Controls extends FlxActionSet
{
	public var keyboardScheme = KeyboardScheme.None;
	public var input:Map<Control, ControlSet>;

	public function new(name:String, scheme = None)
	{
		super(name);
		input = new Map();
		// MAPS CONTROLS AND SHIT LOL!!!!!!!!
		for (control => actions in [
			// UI
			UI_RIGHT => [PRESSED, JUST_PRESSED, JUST_RELEASED],
			UI_DOWN => [PRESSED, JUST_PRESSED, JUST_RELEASED],
			UI_LEFT => [PRESSED, JUST_PRESSED, JUST_RELEASED],
			UI_UP => [PRESSED, JUST_PRESSED, JUST_RELEASED],
			// NOTES
			NOTE_RIGHT => [PRESSED, JUST_RELEASED, JUST_PRESSED],
			NOTE_DOWN => [PRESSED, JUST_PRESSED, JUST_RELEASED],
			NOTE_LEFT => [PRESSED, JUST_PRESSED, JUST_RELEASED],
			NOTE_UP => [PRESSED, JUST_PRESSED, JUST_RELEASED],
			// BUTTONS
			BACK => [JUST_PRESSED, PRESSED],

			ACCEPT => [JUST_PRESSED],
			PAUSE => [JUST_PRESSED],

			RESET => [JUST_PRESSED],
			HIT => [JUST_PRESSED]
		])
		{
			input.set(control, new ControlSet(control, actions));
		}
		// REST OF DA SHIT
		for (set in input.iterator())
		{
			@:privateAccess
			for (action in set._actions.iterator())
				add(action);
		}
		setKeyboardScheme(scheme, false);
	}

	public inline function is(control:Control, ?state:FlxInputState):Bool
	{
		if (input.exists(control))
			return input.get(control).is(state);
		return false;
	}

	public inline function diff(controlA:Control, controlB:Control, ?stateA:FlxInputState, ?stateB:FlxInputState):Int
		return CoolUtil.delta(is(controlA, stateA), is(controlB, stateB));

	/**
	 * Calls a function passing each action bound by the specified control
	 * @param control
	 * @param func
	 * @return ->Void)
	 */
	private inline function forEachBound(control:Control, func:FlxActionDigital->FlxInputState->Void)
	{
		var scran:ControlSet = input.get(control);
		if (scran != null)
		{
			@:privateAccess
			for (state => action in scran._actions)
				func(action, state);
		}
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public inline function bindKeys(control:Control, keys:Array<FlxKey>)
	{
		var copyKeys:Array<FlxKey> = keys.copy();
		for (i in 0...copyKeys.length)
		{
			if (i == NONE)
				copyKeys.remove(i);
		}
		inline forEachBound(control, (action, state) -> addKeys(action, copyKeys, state));
	}

	private inline static function addKeys(action:FlxActionDigital, keys:Array<FlxKey>, state:FlxInputState)
	{
		for (key in keys)
			if (key != NONE)
				action.addKey(key, state);
	}

	public inline function setKeyboardScheme(scheme:KeyboardScheme, ?reset:Bool = true)
	{
		if (reset)
			removeKeyboard();
		keyboardScheme = scheme;
		switch (scheme)
		{
			default:
				// do fucking nthing
				return;
			case Solo:
				{
					for (mapping in ClientPrefs.keyBinds.iterator())
					{
						if (ClientPrefs.isControl(mapping))
							inline bindKeys(mapping[1], mapping[0]);
					}
				}
		}
	}

	private inline function removeKeyboard()
	{
		for (action in this.digitalActions)
		{
			var index = action.inputs.length;
			while (index-- > 0)
			{
				var input = action.inputs[index];
				if (input.device == KEYBOARD)
					action.remove(input);
			}
		}
	}
}
