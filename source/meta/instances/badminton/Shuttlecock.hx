package meta.instances.badminton;

import meta.data.ClientPrefs;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;

class Shuttlecock extends FlxSprite
{
	public inline static final hitSound:String = 'hitShuttle';
	public inline static final hitLibrary:String = 'shuttleman';

	public inline static final missSound:String = 'missShuttle';
	public inline static final missLibrary:String = hitLibrary;

	public var lastPoint:Float = 0;
	// The distance between the shuttle and the opponent
	public var curveAlpha:Float = 0;
	public var nextBeat:Float = 0;

	public var characterFrom:Character;
	public var characterTo:Character;

	public var racquetMap:Map<Character, Racquet>;

	public var splashes:FlxTypedGroup<ShuttleSplash>;
	public var racquets:FlxTypedGroup<Racquet>;

	private var hitVolumeRange:Float = .05;
	private var hitVolume:Float = .5;

	private var up:Float = 750;

	public function new(characterFrom:Character, characterTo:Character, flipped:Bool = false)
	{
		var start:Character = flipped ? characterTo : characterFrom;
		super(start.x, start.y);
		// the image is the wrong way
		this.characterFrom = characterFrom;
		this.characterTo = characterTo;

		flipX = !flipped;
		antialiasing = false;

		scrollFactor.set(1, 1);

		splashes = new FlxTypedGroup(4);
		racquets = new FlxTypedGroup();

		racquetMap = new Map();

		appendToMap(characterFrom);
		appendToMap(characterTo);

		CoolUtil.precacheSound(hitSound, hitLibrary);
		CoolUtil.precacheSound(missSound, missLibrary);

		loadGraphic(Paths.image('badminton/shuttle'));
	}

	override function update(elapsed:Float)
	{
		// shut up
		var flipFrom:Dynamic = flipX ? characterFrom : characterTo;
		var flipTo:Dynamic = flipX ? characterTo : characterFrom;

		var fromPoint:FlxPoint = getPoint(flipFrom);
		var toPoint:FlxPoint = getPoint(flipTo);

		var alphaInterpolation:Float = FlxMath.lerp(lastPoint, 1, curveAlpha);

		var newY:Float = getQuadBezier(fromPoint.y, ((fromPoint.y + toPoint.y) / 2) - up, toPoint.y, alphaInterpolation);
		var newX:Float = getQuadBezier(fromPoint.x, (fromPoint.x + toPoint.x) / 2, toPoint.x, alphaInterpolation);

		this.setPosition(newX, newY);
		// Make it be angled up/down depending on how far along the bezier curve it is
		angle = Math.sin((FlxMath.bound(curveAlpha, 0, 1) - .5) * Math.PI) * 75 * (flipX ? 1 : -1);
		super.update(elapsed);
	}

	override function destroy()
	{
		splashes.destroy();
		racquets.destroy();

		racquetMap.clear();
		super.destroy();
	}

	public inline function miss()
		FlxG.sound.play(Paths.sound(missSound, missLibrary)).setPosition(x, y);

	public inline function hit()
	{
		if (!ClientPrefs.getPref('lowQuality'))
		{
			var splash:ShuttleSplash = splashes.recycle(ShuttleSplash); // new FlxSprite(this.x, this.y);

			splashes.add(splash);
			splash.splash(x - (splash.width / 2), y - (splash.height / 2));
		}
		FlxG.sound.play(Paths.sound(hitSound, hitLibrary), hitVolume + FlxG.random.float(-hitVolumeRange, hitVolumeRange)).setPosition(x, y);
	}

	public inline function playAnimation(char:Character)
	{
		if (racquetMap.exists(char))
		{
			racquetMap.get(char).swing();
		}
		else
		{
			char.playAnim('hit', true);
			char.specialAnim = true;
		}
	}

	public inline function appendToMap(char:Character)
	{
		if (!char.animOffsets.exists('hit'))
		{
			var racquet:Racquet = new Racquet(char);

			racquetMap.set(char, racquet);
			racquets.add(racquet);
		}
	}

	public inline function calculateOffset(char:Character):FlxPoint
	{
		var charOffset:FlxPoint = switch (char.curCharacter)
		{
			// case 'bf-racquet': new FlxPoint(-125, -100);
			default: null;
		}

		var midpoint:FlxPoint = char.getMidpoint();
		return charOffset != null ? midpoint.add(charOffset.x * (char.flipX ? -1 : 1), charOffset.y) : midpoint;
	}

	public inline function getPoint(char:Character)
		return racquetMap.exists(char) ? racquetMap.get(char).getRacquetPosition() : calculateOffset(char);

	private inline function getQuadBezier(start:Float, intermediate:Float, end:Float, alpha:Float):Float
	{
		var difference:Float = 1 - alpha;

		var pointA:Float = start * (difference * difference);
		var pointB:Float = intermediate * difference * alpha * 2;
		var pointC:Float = end * (alpha * alpha);

		return pointA + pointB + pointC;
	}
}
