package states.substates;

import meta.PlayerSettings;
import states.options.Option;
import meta.instances.PrefCheckbox;
import meta.instances.Alphabet;
import meta.instances.AttachedText;
import meta.data.ClientPrefs;
import meta.CoolUtil;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

using StringTools;

class GameplayChangersSubstate extends MusicBeatSubstate
{
	private var curOption:GameplayOption = null;
	private var curSelected:Int = 0;

	private var optionsArray:Array<Dynamic> = [];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxGroup:FlxTypedGroup<PrefCheckbox>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	private var fucker:Bool = false;

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	private inline function getOptions()
	{
		var goption:GameplayOption = new GameplayOption('Scroll Type', 'scrolltype', 'string', 'multiplicative', ["multiplicative", "constant"]);
		optionsArray.push(goption);

		var option:GameplayOption = new GameplayOption('Scroll Speed', 'scrollspeed', 'float', 1);

		option.scrollSpeed = 2;
		option.minValue = .35;

		option.changeValue = .05;
		option.decimals = 2;

		if (goption.getValue() != "constant")
		{
			option.displayFormat = '%vX';
			option.maxValue = 3;
		}
		else
		{
			option.displayFormat = "%v";
			option.maxValue = 6;
		}
		optionsArray.push(option);
		if (!fucker)
		{
			var option:GameplayOption = new GameplayOption('Health Gain Multiplier', 'healthgain', 'float', 1);
			option.scrollSpeed = 2.5;

			option.minValue = 0;
			option.maxValue = 5;

			option.changeValue = .1;

			option.displayFormat = '%vX';
			optionsArray.push(option);

			var option:GameplayOption = new GameplayOption('Health Loss Multiplier', 'healthloss', 'float', 1);
			option.scrollSpeed = 2.5;

			option.minValue = .5;
			option.maxValue = 5;

			option.changeValue = .1;
			option.displayFormat = '%vX';

			optionsArray.push(option);
			optionsArray.push(new GameplayOption('Pussy Mode', 'botplay', 'bool', false));
		}
	}

	public function getOptionByName(name:String):Null<GameplayOption>
	{
		for (option in optionsArray)
		{
			if (option.id == name)
				return option;
		}
		return null;
	}

	public function new(fucker:Bool = false)
	{
		#if !debug
		this.fucker = fucker;
		#end
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = .6;
		add(bg);

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup();
		add(grpOptions);

		grpTexts = new FlxTypedGroup();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup();

		add(checkboxGroup);
		getOptions();

		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(200, 360, optionsArray[i].name, true);
			optionText.isMenuItem = true;

			optionText.scaleX = .8;
			optionText.scaleY = .8;

			optionText.targetY = i;
			grpOptions.add(optionText);

			if (optionsArray[i].type == 'bool')
			{
				optionText.x += 110;
				optionText.startPosition.x += 110;

				optionText.snapToPosition();

				var checkbox:PrefCheckbox = new PrefCheckbox(optionText.x - 105, optionText.y, optionsArray[i].getValue());
				checkbox.sprTracker = optionText;

				checkbox.offsetX -= 32;
				checkbox.offsetY = -120;

				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			}
			else
			{
				optionText.snapToPosition();
				var valueText:AttachedText = new AttachedText(Std.string(optionsArray[i].getValue()), optionText.width, -72, true, .8);

				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;

				valueText.ID = i;

				grpTexts.add(valueText);
				optionsArray[i].setChild(valueText);
			}
			updateTextFrom(optionsArray[i]);
		}

		changeSelection();
		reloadCheckboxes();
	}

	override function update(elapsed:Float)
	{
		var delta:Int = PlayerSettings.controls.diff(UI_DOWN, UI_UP, JUST_PRESSED, JUST_PRESSED);
		if (delta != 0)
			changeSelection(delta);

		if (PlayerSettings.controls.is(BACK))
		{
			close();

			ClientPrefs.saveSettings();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if (nextAccept <= 0)
		{
			var usesCheckbox = curOption.type == 'bool';
			if (usesCheckbox)
			{
				if (PlayerSettings.controls.is(ACCEPT))
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));

					curOption.setValue(curOption.getValue() == false);
					curOption.change();

					reloadCheckboxes();
				}
			}
			else if (PlayerSettings.controls.is(UI_LEFT, PRESSED) || PlayerSettings.controls.is(UI_RIGHT, PRESSED))
			{
				var pressed:Bool = PlayerSettings.controls.is(UI_LEFT, JUST_PRESSED) || PlayerSettings.controls.is(UI_RIGHT, JUST_PRESSED);
				if (holdTime > .5 || pressed)
				{
					if (pressed)
					{
						var add:Float = 0;
						if (curOption.type != 'string')
							add = curOption.changeValue * PlayerSettings.controls.diff(UI_RIGHT, UI_LEFT, PRESSED, PRESSED);

						switch (curOption.type)
						{
							case 'int' | 'float' | 'percent':
								{
									holdValue = FlxMath.bound(curOption.getValue() + add, curOption.minValue, curOption.maxValue);
									curOption.setValue(switch (curOption.type)
									{
										case 'float' | 'percent':
											FlxMath.roundDecimal(holdValue, curOption.decimals);
										default:
											Math.round(holdValue);
									});
								}
							case 'string':
								{
									var delta:Int = PlayerSettings.controls.diff(UI_RIGHT, UI_LEFT, JUST_PRESSED, JUST_PRESSED);
									var num:Int = curOption.curOption; // lol

									if (delta != 0)
										num = CoolUtil.repeat(num, delta, curOption.options.length);

									curOption.curOption = num;
									curOption.setValue(curOption.options[num]); // lol

									switch (curOption.id)
									{
										case 'scroll-type':
											{
												var coolOption:GameplayOption = getOptionByName("scroll-speed");
												if (coolOption != null)
												{
													var value:Dynamic = curOption.getValue();
													if (value == "constant")
													{
														coolOption.displayFormat = "%v";
														coolOption.maxValue = 6;
													}
													else
													{
														coolOption.displayFormat = "%vX";
														coolOption.maxValue = 3;

														if (value > coolOption.maxValue)
															coolOption.setValue(coolOption.maxValue);
													}
													updateTextFrom(coolOption);
												}
											}
									}
								}
						}

						updateTextFrom(curOption);
						curOption.change();

						FlxG.sound.play(Paths.sound('scrollMenu'));
					}
					else if (curOption.type != 'string')
					{
						holdValue = FlxMath.bound(holdValue
							+ (curOption.scrollSpeed * elapsed * PlayerSettings.controls.diff(UI_RIGHT, UI_LEFT, PRESSED, PRESSED)),
							curOption.minValue, curOption.maxValue);
						curOption.setValue(switch (curOption.type)
						{
							case 'float' | 'percent':
								FlxMath.roundDecimal(Math.round(holdValue / curOption.changeValue) * curOption.changeValue, curOption.decimals);
							default:
								Math.round(holdValue);
						});

						updateTextFrom(curOption);
						curOption.change();
					}
				}

				if (curOption.type != 'string')
					holdTime += elapsed;
			}
			else if (PlayerSettings.controls.is(UI_LEFT, JUST_RELEASED) || PlayerSettings.controls.is(UI_RIGHT, JUST_RELEASED))
			{
				clearHold();
			}

			if (PlayerSettings.controls.is(RESET))
			{
				for (i in 0...optionsArray.length)
				{
					var leOption:GameplayOption = optionsArray[i];
					leOption.setValue(leOption.defaultValue);

					if (leOption.type != 'bool')
					{
						if (leOption.type == 'string')
							leOption.curOption = leOption.options.indexOf(leOption.getValue());
						updateTextFrom(leOption);
					}
					switch (leOption.id)
					{
						case 'scroll-speed':
							{
								leOption.displayFormat = "%vX";
								leOption.maxValue = 3;

								if (leOption.getValue() > leOption.maxValue)
									leOption.setValue(leOption.maxValue);

								updateTextFrom(leOption);
							}
					}
					leOption.change();
				}

				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}
		if (nextAccept > 0)
			nextAccept -= 1;
		super.update(elapsed);
	}

	private inline function updateTextFrom(option:GameplayOption)
	{
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();

		if (option.type == 'percent')
			val *= 100;

		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	private inline function clearHold()
	{
		if (holdTime > .5)
			FlxG.sound.play(Paths.sound('scrollMenu'));
		holdTime = 0;
	}

	private inline function changeSelection(change:Int = 0)
	{
		curSelected = CoolUtil.repeat(curSelected, change, optionsArray.length);

		var bullShit:Int = 0;
		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = (item.targetY == 0) ? 1 : .6;
		}
		for (text in grpTexts)
			text.alpha = (text.ID == curSelected) ? 1 : .6;

		curOption = optionsArray[curSelected]; // shorter lol
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	private inline function reloadCheckboxes()
	{
		for (checkbox in checkboxGroup)
			checkbox.daValue = optionsArray[checkbox.ID].getValue() == true;
		ClientPrefs.saveSettings();
	}
}

class GameplayOption
{
	private var child:Alphabet;

	public var text(get, set):String;
	public var onChange:Void->Void = null; // Pressed enter (on Bool type options) or pressed/held left/right (on other types)

	public var type(get, default):String = 'bool'; // bool, int (or integer), float (or fl), percent, string (or str)

	// Bool will use checkboxes
	// Everything else will use a text
	public var scrollSpeed:Float = 50; // Only works on int/float, defines how fast it scrolls per second while holding left/right

	private var variable:String = null; // Variable from ClientPrefs.hx's gameplaySettings

	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; // Don't change this
	public var options:Array<String> = null; // Only used in string type
	public var changeValue:Dynamic = 1; // Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; // Only used in int/float/percent type
	public var maxValue:Dynamic = null; // Only used in int/float/percent type
	public var decimals:Int = 1; // Only used in float/percent type

	public var displayFormat:String = '%v'; // How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value

	public var name:String = 'unknown';
	public var id:String = 'unknown';

	public function new(name:String, variable:String, type:String = 'bool', defaultValue:Dynamic = Option.DEFAULT_VALUE, ?options:Array<String> = null)
	{
		this.name = name;

		this.id = Paths.formatToSongPath(name);
		this.type = Paths.formatToSongPath(type);

		this.variable = variable;

		this.defaultValue = defaultValue;
		this.options = options;

		if (defaultValue == Option.DEFAULT_VALUE)
		{
			switch (type)
			{
				case 'bool':
					defaultValue = false;
				case 'int' | 'float':
					defaultValue = 0;
				case 'percent':
					defaultValue = 1;
				case 'string':
					defaultValue = (options.length > 0) ? options[0] : '';
			}
		}
		if (getValue() == null)
			setValue(defaultValue);

		switch (type)
		{
			case 'string':
				{
					var num:Int = options.indexOf(getValue());
					if (num > -1)
						curOption = num;
				}
			case 'percent':
				{
					displayFormat = '%v%';
					changeValue = .01;

					minValue = 0;
					maxValue = 1;

					scrollSpeed = .5;
					decimals = 2;
				}
		}
	}

	public inline function change()
	{
		// nothing lol
		if (onChange != null)
			onChange();
	}

	public inline function getValue():Dynamic
		return ClientPrefs.gameplaySettings.get(variable);

	public inline function setValue(value:Dynamic)
		ClientPrefs.gameplaySettings.set(variable, value);

	public inline function setChild(child:Alphabet)
		this.child = child;

	private function get_text()
		return child?.text;

	private function set_text(newValue:String = '')
	{
		if (child != null)
			child.text = newValue;
		return null;
	}

	private function get_type()
	{
		return type = switch (type)
		{
			case 'int' | 'float' | 'percent' | 'string':
				type;
			case 'integer':
				'int';
			case 'str':
				'string';
			case 'fl':
				'float';

			default:
				'bool';
		};
	}
}
