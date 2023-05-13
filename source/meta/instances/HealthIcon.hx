package meta.instances;

import flixel.math.FlxMath;
import flixel.FlxG;
import meta.data.ClientPrefs;
import flixel.graphics.FlxGraphic;
import states.PlayState;
import flixel.animation.FlxAnimation;
import flixel.FlxSprite;

using StringTools;

class HealthIcon extends FlxSprite
{
	public inline static final FNM_SCALING:Float = .65;

	public inline static final winningIconFrame:Int = 0;
	public inline static final neutralIconFrame:Int = 1;
	public inline static final losingIconFrame:Int = 2;

	public var sprTracker:FlxSprite;

	private var iconOffsets:Array<Float> = [0, 0];
	private var isPlayer:Bool = false;

	private var isFNM:Bool = false;
	private var char:String = '';

	private var frameCount:Int = -1;
	private var thisFrame:Int = -1;

	public function new(char:String = 'bf', isPlayer:Bool = false, isFNM:Bool = false)
	{
		super();

		this.isPlayer = isPlayer;
		this.isFNM = isFNM;

		changeIcon(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.set(iconOffsets[0], iconOffsets[1]);
	}

	public inline function setFrameOnPercentage(percent:Float)
	{
		var LOSING_PERCENT:Float = PlayState.LOSING_PERCENT;
		setFrame(switch (frameCount)
		{
			default: if (percent <= LOSING_PERCENT) losingIconFrame else if (percent < (100 - LOSING_PERCENT)) neutralIconFrame else winningIconFrame;
			case 1 | 0: 0;
		});
	}

	public inline function setFrame(newFrame:Int)
	{
		var curAnim:FlxAnimation = animation.curAnim;
		if (curAnim != null)
			curAnim.curFrame = Std.int(FlxMath.bound(newFrame - (3 - frameCount), 0, frameCount));
		thisFrame = newFrame;
	}

	public inline function changeIcon(char:String)
	{
		if (this.char != char)
		{
			this.char = char;
			switch (char)
			{
				case 'funnybf-relapse':
					{
						if (FlxG.random.bool(1))
							char = 'relapse_icon';
					}
			}

			var file:Dynamic = getIconOf(char, isFNM, isPlayer);

			var cell:Int = Std.int(file.height);
			var frameCount:Int = Std.int(file.width / cell);

			if (thisFrame < 0)
				thisFrame = Std.int(Math.max(frameCount - 2, 0));
			this.frameCount = frameCount;

			loadGraphic(file, true, Std.int(file.width / frameCount), cell);
			if (isFNM)
				setGraphicSize(Std.int(width * FNM_SCALING));

			iconOffsets[0] = iconOffsets[1] = (width - cell) / frameCount;
			updateHitbox();

			animation.add(char, [ for (i in 0...frameCount) i ], 0, false, isPlayer && !isFNM);
			animation.play(char, true, false, thisFrame);

			setAntiAliasing();
			setFrame(thisFrame);
		}
	}

	public inline static function getIconOf(char:String, ?fnm:Bool = false, ?isPlayer:Bool = false):Dynamic
	{
		return switch (fnm)
		{
			default: Paths.image(getFirstExisting(['icons/$char', 'icons/icon-$char', 'icons/face', 'icons/icon-face']));
			case true: Paths.image('fnm_' + (isPlayer ? 'player' : 'enemy'), 'fnm');
		};
	}

	public inline function getCharacter():String
		return char;

	private static function getFirstExisting(names:Array<String>):Null<String>
	{
		for (name in names)
		{
			if (Paths.fileExists('images/$name.png', IMAGE))
				// trace('$name found at index $i');
				return name;
		}
		return null;
	}
	private inline function setAntiAliasing()
	{
		antialiasing = ClientPrefs.getPref('globalAntialiasing') && (isFNM || switch (char) {
			case 'good' | 'epic' | 'kong' | 'mbest' | 'tricky' | 'beatbox' | 'blockhead' | 'bf-compressed' | 'gf-compressed': true;
			default: false;
		});
	}
}
