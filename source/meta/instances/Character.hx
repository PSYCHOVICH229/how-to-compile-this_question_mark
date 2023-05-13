package meta.instances;

import meta.instances.notes.Note;
import meta.data.ClientPrefs;
import flixel.animation.FlxAnimation;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import haxe.Json;
import openfl.utils.Assets;

using StringTools;

typedef CharacterFile =
{
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;
	var flip_x:Bool;
	var playable:Null<Bool>;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
}

typedef AnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSprite
{
	public inline static final DEFAULT_CHARACTER:String = 'bf'; // In case a character is missing, it will use BF on its place

	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var playable:Bool = false;
	public var isPlayer:Bool = false;

	public var curCharacter:String = DEFAULT_CHARACTER;

	public var exSpikes:FlxSprite;
	public var lastNoteHit:Note;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;

	public var specialAnim:Bool = false;
	public var stunned:Bool = false;

	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';

	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var startedDeath:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public var hasMissAnimations:Bool = false;

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;

	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;

	public var healthColorArray:Array<Int> = [255, 0, 0];
	public var danced:Bool = false;

	private var settingCharacterUp:Bool = true;

	public var danceEveryNumBeats:Int = 2;

	public function new(x:Float, y:Float, ?character:String = DEFAULT_CHARACTER, ?isPlayer:Bool = false, ?debugMode:Bool = false)
	{
		super(x, y);

		this.isPlayer = isPlayer;
		this.debugMode = debugMode;

		// antialiasing = ClientPrefs.getPref('globalAntialiasing'); doesn't antialiasing already get set?
		if (character != null && character.length > 0)
			setCharacter(character);
	}

	override function update(elapsed:Float)
	{
		var curAnim:FlxAnimation = animation.curAnim;
		if (!debugMode && curAnim != null)
		{
			if (heyTimer > 0)
			{
				heyTimer -= elapsed;
				if (heyTimer <= 0)
				{
					if (specialAnim)
					{
						var curName:String = curAnim.name.toLowerCase();
						var stopAnimation:Bool = switch (curCharacter)
						{
							default: curName == 'hey' || curName == 'cheer';
							case 'exTricky': curName == 'hank';
						}

						if (stopAnimation)
						{
							specialAnim = false;
							curAnim.finish();

							dance(true);
						}
					}
					heyTimer = 0;
				}
			}
			else if (specialAnim && curAnim.finished)
			{
				specialAnim = false;
				dance(true);
			}

			var singing:Bool = curAnim.name.startsWith('sing');
			if (singing)
				holdTimer += elapsed;
			switch (isPlayer)
			{
				case true:
					{
						if (curAnim.name.endsWith('miss') && curAnim.finished)
							playAnim('idle', true, false, 10);
						if (curAnim.name == 'firstDeath' && curAnim.finished && startedDeath)
							playAnim('deathLoop');

						if (!singing)
							holdTimer = 0;
					}
				default:
					{
						if (holdTimer >= (Conductor.stepCrochet / 1000) * singDuration)
						{
							dance();
							holdTimer = 0;
						}
					}
			}

			var loopAnim:String = curAnim.name + '-loop';
			if (curAnim.finished && animation.getByName(loopAnim) != null)
				playAnim(loopAnim);
			if (exSpikes != null && exSpikes.animation.frameIndex >= 3 && curAnim.name.startsWith('singUP'))
				exSpikes.animation.pause();
		}
		super.update(elapsed);
	}

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(force:Bool = false)
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			switch (danceIdle)
			{
				case true:
					{
						danced = !danced;
						playAnim(danced ? 'danceRight$idleSuffix' : 'danceLeft$idleSuffix', force);

						return;
					}
				default:
					{
						var idleFormat:String = 'idle$idleSuffix';
						if (animation.getByName(idleFormat) != null)
							playAnim(idleFormat, force);
					}
			}
		}
	}

	public inline function getDeathAnimation():String
	{
		trace(curCharacter);
		return switch (curCharacter)
		{
			case 'shuttle-man-playable':
				'deadleman';
			case 'eggbob':
				'dead_bitch';

			case 'bobfriend-foursome':
				'bobfriend-playable';
			case 'bf-foursome':
				'bf-foursome-dead';

			case 'funnybf' | 'funnybf-guitar' | 'funnybf-playable':
				'funnybf-playable-old';
			default:
				curCharacter;
		}
	}
	public inline function playAnim(animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void
	{
		specialAnim = false;
		animation.play(animName, force, reversed, frame);

		var lowerName:String = animName.toLowerCase();
		if (exSpikes != null)
		{
			if (lowerName.startsWith('singup'))
			{
				// trace('spikes');

				exSpikes.visible = true;
				if (exSpikes.animation.finished || exSpikes.animation.curAnim == null)
					exSpikes.animation.play('spike');
			}
			else if (!exSpikes.animation.finished)
			{
				exSpikes.animation.resume();
				// trace('go back spikes');
				exSpikes.animation.finishCallback = function(pog:String)
				{
					// trace('finished');

					exSpikes.visible = false;
					exSpikes.animation.finishCallback = null;
				}
			}
		}

		if (animOffsets.exists(animName))
		{
			var daOffset:Array<Dynamic> = animOffsets.get(animName);
			offset.set(daOffset[0], daOffset[1]);
		}
		else
		{
			offset.set(0, 0);
		}

		if (curCharacter.startsWith('gf'))
		{
			danced = switch (lowerName)
			{
				case 'singright': false;
				case 'singleft': true;

				case 'singup' | 'singdown': !danced;
				default: danced;
			};
		}
	}

	public inline function setCharacter(?character:String = "bf")
	{
		animOffsets = new Map();

		var library:String = 'shared';
		curCharacter = character;

		var characterPath:String = 'characters/$curCharacter.json';
		var path:String = Paths.getPreloadPath(characterPath);

		if (!Assets.exists(path))
			path = Paths.getPreloadPath('characters/$DEFAULT_CHARACTER.json'); // If a character couldn't be found, change him to BF just to prevent a crash

		var rawJson:String = Assets.getText(path);
		var json:CharacterFile = cast Json.parse(rawJson);

		frames = if (Assets.exists(Paths.getPath('images/' + json.image + '.txt',
			TEXT))) Paths.getPackerAtlas(json.image, library); else Paths.getSparrowAtlas(json.image, library);
		imageFile = json.image;

		resetSize();
		resetFrameSize();

		scale.set(1, 1);
		if (json.scale != 1)
		{
			jsonScale = json.scale;

			setGraphicSize(Std.int(width * jsonScale));
			updateHitbox();
		}

		positionArray = json.position;
		cameraPosition = json.camera_position;

		singDuration = json.sing_duration;
		healthIcon = json.healthicon;

		flipX = json.flip_x;
		if (exSpikes != null)
		{
			exSpikes.kill();
			exSpikes.destroy();

			exSpikes = null;
		}
		switch (curCharacter)
		{
			// case 'your character name in case you want to hardcode them instead':
			case 'exTricky':
				{
					exSpikes = new FlxSprite(-250, -70);
					exSpikes.scrollFactor.set(.9, .9);

					exSpikes.frames = Paths.getSparrowAtlas('FloorSpikes', 'clown');
					exSpikes.visible = false;

					exSpikes.animation.addByPrefix('spike', 'Floor Spikes', 24, false);
				}
		}

		noAntialiasing = json.no_antialiasing;
		if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
			healthColorArray = json.healthbar_colors;

		antialiasing = !noAntialiasing && ClientPrefs.getPref('globalAntialiasing');
		animationsArray = json.animations;

		if (animationsArray != null && animationsArray.length > 0)
		{
			for (anim in animationsArray)
			{
				var animAnim:String = anim.anim;
				var animName:String = anim.name;

				var animLoop:Bool = anim.loop;
				var animFps:Int = anim.fps;

				var animIndices:Array<Int> = anim.indices;
				if (animIndices != null && animIndices.length > 0)
				{
					animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				}
				else
				{
					animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}

				if (anim.offsets != null && anim.offsets.length > 1)
					addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
			}
		}
		else
		{
			quickAnimAdd('idle', 'BF idle dance');
		}

		originalFlipX = flipX;
		if (animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss'))
			hasMissAnimations = true;

		recalculateDanceIdle();
		dance();

		playable = json.playable;
		if (isPlayer)
			flipX = !flipX;
		if (!debugMode)
		{
			if (json.playable != null)
			{
				if (isPlayer != playable)
					flipCharacter();
			}
			else if (isPlayer && !flipX)
				// characters without the playable value
				flipCharacter();
		}
		// Doesn't flip for BF, since his are already in the right place???
		// (!curCharacter.startsWith('bf'))
		// if (flipX != originalFlipX && !isPlayer && !debugMode) flipCharacter();
	}

	// cuh
	public function flipCharacter()
	{
		if (debugMode)
			return;
		trace('swap them');

		swapAnimations('singRIGHT', 'singLEFT');
		// IF THEY HAVE MISS ANIMATIONS??
		swapAnimations('singRIGHTmiss', 'singLEFTmiss');
	}

	public inline function swapAnimations(swapA:String, swapB:String)
	{
		var swapAnimationA:FlxAnimation = animation.getByName(swapA);
		var swapAnimationB:FlxAnimation = animation.getByName(swapB);

		if (swapAnimationA != null && swapAnimationB != null)
		{
			var oldOffsetA:Array<Dynamic> = animOffsets.get(swapA);
			var oldAnimA:Array<Int> = swapAnimationA.frames;

			animOffsets.set(swapA, animOffsets.get(swapB));
			animOffsets.set(swapB, oldOffsetA);

			swapAnimationA.frames = swapAnimationB.frames;
			swapAnimationB.frames = oldAnimA;
		}
	}

	public inline function recalculateDanceIdle()
	{
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = animation.getByName('danceLeft$idleSuffix') != null && animation.getByName('danceRight$idleSuffix') != null;

		if (settingCharacterUp)
		{
			danceEveryNumBeats = danceIdle ? 1 : 2;
		}
		else if (lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;

			if (danceIdle)
			{
				calc /= 2;
			}
			else
			{
				calc *= 2;
			}

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public inline function addOffset(name:String, x:Float = 0, y:Float = 0):Void
		animOffsets[name] = [x, y];

	public inline function quickAnimAdd(name:String, anim:String):Void
		animation.addByPrefix(name, anim, 24, false);
}
