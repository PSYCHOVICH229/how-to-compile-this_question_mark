package meta;

import meta.data.ClientPrefs;
import states.MusicBeatState;
#if GAMEJOLT_ALLOWED
import states.gamejolt.GameJolt;
#end
import meta.Discord.DiscordClient;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup;
import flixel.FlxCamera;
import flixel.FlxG;

class Achievements extends MusicBeatState
{
	public static var achievementsUnlocked:Map<String, Bool> = [];
	// Icon name
	// Achievement name
	// Achievement description
	// Achievement ID (if using gamejolt)
	// (optional) Secret
	public static final achievements:Array<Array<Dynamic>> = [
		[
			'week1',
			'Gastrointestinal Disease',
			'FC the first week on ' + CoolUtil.defaultDifficulties[1] + ' or ' + CoolUtil.defaultDifficulties[2] + '.'
			#if GAMEJOLT_ALLOWED, 162818 #end
		],
		[
			'week2',
			'Funny Homosexuals',
			'FC the second week.'
			#if GAMEJOLT_ALLOWED, 162838 #end
		],
		[
			'unblammy',
			'Unblammy',
			'FC the third week.'
			#if GAMEJOLT_ALLOWED, 193458 #end
		],
		[
			'unbshuttlery',
			'Awesome Times Four',
			'FC the fourth week.'
			#if GAMEJOLT_ALLOWED, 193459 #end
		],
		[
			'badminton_champion',
			'Badminton Champion',
			'FC and hit every birdie pass on Hotshot.'
			#if GAMEJOLT_ALLOWED, 162788 #end
		],
		#if GAMEJOLT_ALLOWED ['game_joooj', 'GameJOOOOOOOOOJ', 'Log into your GameJolt account.', 162787], #end
		[
			'the_hard_bend',
			'The Hard Bend',
			'Find and complete Bend Hard.',
			#if GAMEJOLT_ALLOWED 169902 #else null #end,
			true
		],
		[
			'KILL_GAME',
			'Ain\'t No Game',
			'Find and complete KILLGAMES.',
			#if GAMEJOLT_ALLOWED 193460 #else null #end,
			true
		],
		[
			'benjuu',
			'Benju Mode',
			'Otherwise known as the FZone achievement.',
			#if GAMEJOLT_ALLOWED 187886, #end
			true
		],
		['WEED', '420', 'Nice.', #if GAMEJOLT_ALLOWED 167986 #else null #end, true]
	];

	public inline static function isAchievementUnlocked(achievement:String):Bool
		return #if debug true #else achievementsUnlocked.exists(achievement) && achievementsUnlocked.get(achievement) #end;

	public static function getAchievementIndex(achievement:String):Array<Dynamic>
	{
		for (index in achievements)
		{
			if (index[0] == achievement)
				return index;
		}
		return null;
	}

	public static function unlockAchievement(achievement:String)
	{
		if (isAchievementUnlocked(achievement))
			return;
		achievementsUnlocked.set(achievement, true);
		#if GAMEJOLT_ALLOWED
		GameJolt.unlockTrophy(achievement);
		#end
		ClientPrefs.saveSettings();
	}
}

class Achievement extends FlxSpriteGroup
{
	private static final bgColorNew:FlxColor = FlxColor.fromRGB(0, 0, 0, 200);

	public inline static final defaultSound:String = 'achievementUnlocked';
	public inline static final defaultVolume:Float = .5;

	private inline static final bgHeight:Int = 130;
	private inline static final bgWidth:Int = 400;

	private inline static final nameSize:Int = 24;
	private inline static final textSize:Int = 18;
	private inline static final iconSize:Int = 64;

	private inline static final outline:Int = 4;
	public static final padding:Float = 10;

	private inline static function cleanupTween(twn:FlxTween):Void
	{
		if (twn.active)
			twn.cancel();

		twn.active = false;
		twn.destroy();
	}

	private inline static function cleanupTimer(tmr:FlxTimer):Void
	{
		if (tmr.active)
			tmr.cancel();

		tmr.active = false;
		tmr.destroy();
	}

	public var onFinish(default, set):Void->Void = null;
	public var finished(default, set):Bool = false;

	public var bg:FlxSprite;

	private function set_onFinish(finish:Void->Void):Void->Void
	{
		if (finished && finish != null)
			finish();
		return this.onFinish = finish;
	}

	private function set_finished(value:Bool):Bool
	{
		if (value && onFinish != null)
			onFinish();
		return this.finished = value;
	}

	public static function makeAchievement(achievement:String, ?camera:FlxCamera, fake = false, ?sound:String, ?library:String, ?volume:Float = defaultVolume, yOffset:Float = 0):Null<Achievement>
	{
		#if !debug
		if (!fake)
		{
			if (Achievements.isAchievementUnlocked(achievement))
				return null;
			Achievements.unlockAchievement(achievement);
		}
		#end
		var index:Array<Dynamic> = Achievements.getAchievementIndex(achievement);
		if (index == null)
			return null;
		return new Achievement(achievement, index, camera, sound, library, volume, yOffset);
	}
	public function new(achievement:String, index:Array<Dynamic>, ?camera:FlxCamera, ?sound:String, ?library:String, ?volume:Float = defaultVolume, yOffset:Float = 0)
	{
		super();
		if (sound == null && library == null)
		{
			sound = switch (achievement)
			{
				case 'badminton_champion': 'cuh';
				case 'WEED': 'smoke_weed';

				default: defaultSound;
			}
		}

		var outlineDouble:Float = outline * 2;
		var outlineHalf:Float = outline / 2;

		var inlinePosition:Float = outlineHalf + outline;
		var borderPosition:Float = padding + outlineHalf;

		var icon:FlxSprite = new FlxSprite(padding + inlinePosition, padding + inlinePosition).loadGraphic(Paths.image('achievements/$achievement'));

		icon.setGraphicSize(iconSize, iconSize);
		icon.updateHitbox();

		var iconOutline:FlxSprite = new FlxSprite(borderPosition,
			borderPosition).makeGraphic(Std.int(iconSize + outlineDouble), Std.int(iconSize + outlineDouble), FlxColor.BLACK);

		var name:FlxText = new FlxText(icon.x + padding + iconSize + outlineHalf, icon.y + (nameSize / 2), bgWidth - ((padding * 2) + iconSize + outline),
			index[1]).setFormat(Paths.font('comic.ttf'), nameSize, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		var description:FlxText = new FlxText(padding, iconOutline.y + iconOutline.height + outline, bgWidth - (padding * 2),
			index[2]).setFormat(Paths.font('comic.ttf'), textSize, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);

		bg = new FlxSprite().makeGraphic(bgWidth, Std.int(bgHeight + description.height - (textSize * 2)), FlxColor.WHITE);

		description.bold = true;
		name.bold = true;

		description.antialiasing = false;
		iconOutline.antialiasing = false;
		icon.antialiasing = false;
		name.antialiasing = false;
		bg.antialiasing = false;
		// poop
		bg.cameras = icon.cameras = name.cameras = description.cameras = iconOutline.cameras = cameras = [camera ?? FlxG.camera];
		bg.color = FlxColor.GREEN;

		alpha = .5;

		add(bg);
		add(description);

		add(iconOutline);
		add(icon);

		add(name);
		setPosition(FlxG.width - bg.width - padding, -bg.height);

		if (volume > 0)
			FlxG.sound.play(Paths.sound(sound, library), volume);

		FlxTween.color(bg, .5, bg.color, bgColorNew, {onComplete: cleanupTween});
		FlxTween.tween(this, {alpha: .8, y: padding + yOffset}, 1, {
			ease: FlxEase.quartOut,
			onComplete: function(twn:FlxTween)
			{
				new FlxTimer().start(3, function(tmr:FlxTimer)
				{
					FlxTween.tween(this, {x: FlxG.width, alpha: 0}, 1, {
						ease: FlxEase.quartIn,
						onComplete: function(twn:FlxTween)
						{
							cleanupTween(twn);
							finished = true;
							destroy();
						}
					});
					cleanupTimer(tmr);
				});
				cleanupTween(twn);
			}
		});
	}
}
