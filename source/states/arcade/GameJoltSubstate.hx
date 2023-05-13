#if GAMEJOLT_ALLOWED
package states.arcade;

import openfl.display.Application;
import sys.io.Process;
import openfl.Lib;
import states.gamejolt.FlxGameJoltCustom;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import flixel.addons.ui.FlxInputText;
import states.gamejolt.GameJolt;
import flixel.text.FlxText;
import meta.CoolUtil;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.addons.ui.FlxUIInputText;
import meta.data.ClientPrefs;
import flixel.FlxSprite;
import flixel.FlxCamera;

using StringTools;

class GameJoltButton extends FlxSpriteGroup
{
	public inline static final boxFontSize:Int = 24;
	public inline static final boxWidth:Int = 240;

	public var background:FlxSprite;
	public var border:FlxSprite;

	public var label:FlxText;

	override public function new(?x:Float = 0, ?y:Float = 0, ?text:String, ?width:Int = boxWidth, ?height:Int = boxFontSize)
	{
		super(x, y);

		scrollFactor.set();
		background = new FlxSprite().makeGraphic(width, height, GameJoltSubstate.BACKGROUND_COLOR);

		label = new FlxText(0, 0, background.width, text).setFormat(Paths.font('vcr.ttf'), Std.int(Math.min(boxFontSize, height)), FlxColor.WHITE, CENTER);
		border = new FlxSprite(-GameJoltSubstate.BORDER_SIZE,
			-GameJoltSubstate.BORDER_SIZE).makeGraphic(width + GameJoltSubstate.DOUBLE_BORDER, height + GameJoltSubstate.DOUBLE_BORDER, FlxColor.WHITE);

		add(border);
		add(background);

		add(label);
	}

	public function select(selected:Bool = false)
	{
		border.color = selected ? GameJoltSubstate.BORDER_SELECTED_COLOR : GameJoltSubstate.BORDER_COLOR;
		background.alpha = selected ? 1 : .75;
	}
}

class GameJoltCheckbox extends FlxSpriteGroup
{
	public inline static final boxFontSize:Int = 16;
	public inline static final boxSize:Int = 24;

	public var background:FlxSprite;
	public var border:FlxSprite;

	public var label:FlxText;

	public var value(default, set):Bool;
	public var onChange:(Bool) -> Void;

	override public function new(?x:Float = 0, ?y:Float = 0, ?value:Bool = true, ?onChange:(Bool) -> Void)
	{
		super(x, y);

		scrollFactor.set();
		background = new FlxSprite().makeGraphic(boxSize, boxSize, GameJoltSubstate.BACKGROUND_COLOR);

		border = new FlxSprite(-GameJoltSubstate.BORDER_SIZE,
			-GameJoltSubstate.BORDER_SIZE).makeGraphic(boxSize + GameJoltSubstate.DOUBLE_BORDER, boxSize + GameJoltSubstate.DOUBLE_BORDER, FlxColor.WHITE);
		label = new FlxText(0, 0, background.width, 'X').setFormat(null, boxFontSize, FlxColor.WHITE, CENTER);

		label.bold = true;
		label.setPosition(background.x + ((background.width - label.width) / 2), background.y + ((background.height - label.height) / 2));

		this.onChange = onChange;
		this.value = value;

		add(border);
		add(background);

		add(label);
	}

	private function set_value(value:Bool):Bool
	{
		if (onChange != null)
			onChange(value);
		return this.value = label.visible = value;
	}

	public function select(selected:Bool = false)
	{
		border.color = selected ? GameJoltSubstate.BORDER_SELECTED_COLOR : GameJoltSubstate.BORDER_COLOR;
		background.alpha = selected ? 1 : .75;
	}
}

class GameJoltInputText extends FlxSpriteGroup
{
	private inline static final boxFontSize:Int = 24;
	private inline static final boxWidth:Int = 320;

	public var input:FlxUIInputText;
	public var border:FlxSprite;

	override public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);

		scrollFactor.set();
		input = new FlxUIInputText(0, 0, boxWidth, null, boxFontSize, FlxColor.WHITE, GameJoltSubstate.BACKGROUND_COLOR);

		input.setFormat(Paths.font('vcr.ttf'), boxFontSize, FlxColor.WHITE, LEFT);
		input.useReturnToUnfocus = false;

		border = new FlxSprite(-GameJoltSubstate.BORDER_SIZE,
			-GameJoltSubstate.BORDER_SIZE).makeGraphic(boxWidth + GameJoltSubstate.DOUBLE_BORDER, Std.int(input.height) + GameJoltSubstate.DOUBLE_BORDER,
				FlxColor.WHITE);

		add(border);
		add(input);
	}

	public function select(selected:Bool = false)
	{
		border.color = selected ? GameJoltSubstate.BORDER_SELECTED_COLOR : GameJoltSubstate.BORDER_COLOR;
		input.backgroundSprite.alpha = selected ? 1 : .75;
	}
}

class GameJoltSubstate extends ArcadeSubstate
{
	public inline static final BACKGROUND_COLOR:FlxColor = 0xFF000000;

	public inline static final BORDER_SELECTED_COLOR:FlxColor = FlxColor.LIME;
	public inline static final BORDER_COLOR:FlxColor = FlxColor.WHITE;

	public inline static final BORDER_SIZE:Int = 4;
	public inline static final DOUBLE_BORDER:Int = BORDER_SIZE * 2; // shut pu

	private inline static final PROFILE_PICTURE_SIZE:Int = 60;
	public inline static final padding:Float = 4;

	private static var hidingToken:Bool = true;
	public static var selectedShit:Int = 0;

	private var usernameInput:GameJoltInputText;
	private var tokenInput:GameJoltInputText;

	private var tokenCheckbox:GameJoltCheckbox;
	private var tokenTutorial:GameJoltButton;

	private var logoutButton:GameJoltButton;
	private var loginButton:GameJoltButton;

	private var checks:Array<GameJoltCheckbox>;
	private var boxes:Array<GameJoltInputText>;

	private var profileGroup:FlxSpriteGroup;

	private var profilePicture:FlxSprite;
	private var profileBorder:FlxSprite;

	private var inputs:Array<Dynamic>;

	private var inputsSunk:Bool = false;
	private var holdingKeys:Bool = false;

	override function new(camera:FlxCamera)
	{
		super(camera);

		checks = new Array();
		boxes = new Array();

		inputs = new Array();
		profileGroup = new FlxSpriteGroup(DOUBLE_BORDER + (padding * 2), mainCamera.height * .55);

		profileGroup.scrollFactor.set();
		profileGroup.cameras = [mainCamera];

		profileBorder = new FlxSprite(-BORDER_SIZE,
			-BORDER_SIZE).makeGraphic(PROFILE_PICTURE_SIZE + DOUBLE_BORDER, PROFILE_PICTURE_SIZE + DOUBLE_BORDER, FlxColor.WHITE);
		profilePicture = new FlxSprite().loadGraphic(Paths.image('defaultGameJoltIcon'));

		profileGroup.add(profileBorder);
		profileGroup.add(profilePicture);

		var usernameTitle:FlxText = new FlxText(0, padding, 0, 'USERNAME').setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE);

		usernameTitle.scrollFactor.set();
		usernameTitle.cameras = [mainCamera];

		usernameInput = new GameJoltInputText(0, usernameTitle.y + usernameTitle.height + padding);

		usernameInput.input.customFilterPattern = ~/[^a-zA-Z0-9_\-]*/g;
		usernameInput.input.filterMode = FlxInputText.CUSTOM_FILTER;

		usernameInput.cameras = [mainCamera];
		var tokenTitle:FlxText = new FlxText(0, usernameInput.y + usernameInput.height + padding, 0,
			'TOKEN').setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE);

		tokenTitle.scrollFactor.set();
		tokenTitle.cameras = [mainCamera];

		tokenInput = new GameJoltInputText(0, tokenTitle.y + tokenTitle.height + padding);
		tokenInput.cameras = [mainCamera];

		usernameInput.input.maxLength = tokenInput.input.maxLength = 30;
		tokenTutorial = new GameJoltButton(0, tokenInput.y + tokenInput.height + (padding * 2), 'TUTORIAL', 150, 16);

		tokenTutorial.scrollFactor.set();
		tokenTutorial.cameras = [mainCamera];

		var checkboxTitle:FlxText = new FlxText(0, tokenTutorial.y + tokenTutorial.height + padding, 0,
			'HIDE TOKEN').setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE);

		checkboxTitle.scrollFactor.set();
		checkboxTitle.cameras = [mainCamera];

		tokenCheckbox = new GameJoltCheckbox(0, checkboxTitle.y + checkboxTitle.height + padding, hidingToken, function(value:Bool)
		{
			var text:String = tokenInput.input.text;

			tokenInput.input.text = '';
			tokenInput.input.passwordMode = hidingToken = value;

			tokenInput.input.text = text;
		});
		tokenCheckbox.cameras = [mainCamera];

		logoutButton = new GameJoltButton(0, mainCamera.height - GameJoltButton.boxFontSize - padding, 'LOGOUT');
		logoutButton.cameras = [mainCamera];

		loginButton = new GameJoltButton(0, logoutButton.y - logoutButton.height - padding, 'LOGIN');
		loginButton.cameras = [mainCamera];

		centerObject(checkboxTitle, X);
		centerObject(usernameTitle, X);
		centerObject(tokenTitle, X);

		checkboxTitle.centerOrigin();
		usernameTitle.centerOrigin();
		tokenTitle.centerOrigin();

		centerObject(usernameInput, X);

		centerObject(tokenInput, X);
		centerObject(tokenTutorial, X);

		centerObject(tokenCheckbox, X);

		centerObject(logoutButton, X);
		centerObject(loginButton, X);
		// ARRAYS
		boxes.push(usernameInput);
		boxes.push(tokenInput);

		checks.push(tokenCheckbox);

		inputs.push(usernameInput);
		inputs.push(tokenInput);

		inputs.push(tokenTutorial);
		inputs.push(tokenCheckbox);

		inputs.push(loginButton);
		inputs.push(logoutButton);

		updateAvatar();
		updateSelection();
		// BOX TITLES
		add(usernameTitle);
		add(tokenTitle);

		add(checkboxTitle);
		// INPUT BOXES
		add(usernameInput);
		add(tokenInput);
		// CHECK BOXES
		add(tokenCheckbox);
		// BUTTONS
		add(tokenTutorial);

		add(logoutButton);
		add(loginButton);
		// OTHER SHIT
		add(profileGroup);
		switch (GameJolt.isLoggedIn())
		{
			default:
				GameJolt.loadAccount(ClientPrefs.getPref('gameJoltUsername'), ClientPrefs.getPref('gameJoltToken'), true, ArcadeState.instance,
					ArcadeState.instance.camOther, fetchAvatar);
			case true:
				{
					usernameInput.input.text = ClientPrefs.getPref('gameJoltUsername');
					tokenInput.input.text = ClientPrefs.getPref('gameJoltToken');

					GameJolt.awardAchievement(ArcadeState.instance, ArcadeState.instance.camOther);
					fetchAvatar();
				}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		FlxG.mouse.enabled = FlxG.mouse.visible = false;

		if (inputsSunk)
		{
			// g et go
			var currentlyPressing:Bool = pressingKeys();
			if (currentlyPressing && !holdingKeys)
			{
				CoolUtil.toggleVolumeKeys(true);
				for (box in boxes)
					box.input.hasFocus = false;
				inputsSunk = false;
			}
			holdingKeys = currentlyPressing;
		}
		if (!inputsSunk)
		{
			if (ArcadeState.stickVerticalPress != 0)
			{
				selectedShit = CoolUtil.repeat(selectedShit, ArcadeState.stickVerticalPress, inputs.length);
				updateSelection();
			}
		}
		ArcadeState.instance.focused = !inputsSunk;
	}

	override function onCloseRequest():Bool
	{
		trace('input');

		super.onCloseRequest();
		if (!inputsSunk)
			return ArcadeState.instance.focused = true;
		return false;
	}

	override function onAcceptRequest():Void
	{
		var input:Dynamic = inputs[selectedShit];
		if (boxes.contains(input) && !inputsSunk)
		{
			holdingKeys = pressingKeys();
			cast(input, GameJoltInputText).input.hasFocus = inputsSunk = true;

			CoolUtil.toggleVolumeKeys(false);
		}
		else if (checks.contains(input))
		{
			if (input == tokenCheckbox)
			{
				var checkbox:GameJoltCheckbox = cast(input, GameJoltCheckbox);
				checkbox.value = !checkbox.value;
			}
		}
		else
		{
			if (input == loginButton)
			{
				if (!GameJolt.isLoggedIn())
				{
					var raw:String = usernameInput.input.text.trim();
					var mention:Dynamic = raw.indexOf('@');

					var username:String = raw.substring(mention + 1).toLowerCase();
					var token:String = tokenInput.input.text.trim();

					if (username.length > 0 && token.length > 0)
					{
						trace('auth user');
						GameJolt.loadAccount(username, token, true, ArcadeState.instance, ArcadeState.instance.camOther, fetchAvatar);
					}
				}
			}
			else if (input == logoutButton)
			{
				if (GameJolt.isLoggedIn())
				{
					trace('log out!');
					FlxGameJoltCustom.resetUser(null, null);

					ClientPrefs.prefs.set('gameJoltUsername', FlxGameJoltCustom.NO_USERNAME);
					ClientPrefs.prefs.set('gameJoltToken', FlxGameJoltCustom.NO_TOKEN);

					ClientPrefs.saveSettings();

					var application:Application = Lib.application;
					try
					{
						#if macos
						var proc:Process = new Process('open', ['-n', '../..']);
						trace(proc);
						#else
						var meta:Map<String, String> = application.meta;
						if (meta?.exists('file'))
						{
							var file:String = meta.get('file');
							#if windows
							var proc:Process = new Process('./$file.exe', []);
							trace(proc);
							#else
							// uhh... fucking linux
							Thread.create(() ->
							{
								var proc:Int = Sys.command('./$file', ['<&-', '>&-', '2>&-', 'disown']);
								trace(proc);
							});
							#end
						}
						#end
					}
					catch (error:Dynamic)
					{
						trace('ERROR WHILE TRYING TO RELAUNCH GAMEJOLT SHIT!!!');
						trace(error);

						for (window in application.windows)
							window.close();
					}
					return Sys.exit(0);
				}
			}
			else if (input == tokenTutorial)
			{
				CoolUtil.browserLoad('https://gamejolt.com/help/tokens');
			}
		}
		return super.onAcceptRequest();
	}

	private inline function updateSelection()
	{
		for (index in 0...inputs.length)
		{
			var input:Dynamic = inputs[index];
			var selected:Bool = index == selectedShit;

			if (boxes.contains(input))
			{
				cast(input, GameJoltInputText).select(selected);
				continue;
			}
			else if (checks.contains(input))
			{
				cast(input, GameJoltCheckbox).select(selected);
				continue;
			}
			cast(input, GameJoltButton).select(selected);
		}
	}

	private inline static function pressingKeys():Bool
		return FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE;

	private inline function fetchAvatar():Void
	{
		if (GameJolt.isLoggedIn())
		{
			trace('fetch avatar');
			FlxGameJoltCustom.fetchAvatarImage(function(bitmap:BitmapData)
			{
				if (bitmap != null && profilePicture != null)
				{
					trace('avatar fetched, APPLY THAT BITCH!');
					var avatarGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, null, false);

					profilePicture.antialiasing = ClientPrefs.getPref('globalAntialiasing');
					profilePicture.loadGraphic(avatarGraphic);
					// have to do this because just incase the user's profile picture is the default one,
					// it's apparently like 10 million times fucking larger ??
					updateAvatar();
				}
			});
		}
	}

	private inline function updateAvatar():Void
	{
		if (profilePicture != null)
		{
			profilePicture.setGraphicSize(60);
			profilePicture.updateHitbox();

			trace('now applied, get the dominant color');
			profileBorder.color = CoolUtil.dominantColor(profilePicture);
		}
	}
}
#end
