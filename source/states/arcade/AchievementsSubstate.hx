package states.arcade;

import meta.CoolUtil;
import meta.data.ClientPrefs;
import meta.Achievements;
import meta.Achievements.Achievement;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxCamera;

class AchievementObject extends FlxSpriteGroup
{
	private inline static final borderSize:Int = 4;

	private inline static final iconSize:Int = 64;
	private inline static final iconBorderSize:Int = iconSize + (borderSize * 2);

	public var achievementHeight:Int;
	public var achievementWidth:Int;

	override public function new(width:Int, height:Int, achievement:Array<Dynamic>)
	{
		super();

		achievementHeight = height;
		achievementWidth = width;

		var borderTwice:Int = borderSize * 2;

		var border:FlxSprite = new FlxSprite().makeGraphic(width + borderTwice, height + borderTwice, FlxColor.WHITE);
		var frame:FlxSprite = new FlxSprite().makeGraphic(width, height, FlxColor.BLACK);

		var iconHolder:FlxSprite = new FlxSprite(borderTwice + borderSize, borderTwice + borderSize).makeGraphic(iconSize, iconSize, FlxColor.BLACK);
		var iconBorder:FlxSprite = new FlxSprite().makeGraphic(iconBorderSize, iconBorderSize, FlxColor.WHITE);

		var unlocked:Bool = Achievements.isAchievementUnlocked(achievement[0]);
		var title:FlxText = new FlxText(iconHolder.x + iconHolder.width + borderTwice, 0, width - borderTwice - iconHolder.width,
			unlocked ? achievement[1] : '?').setFormat(Paths.font('comic.ttf'), 24, FlxColor.WHITE, LEFT);
		var description:FlxText = new FlxText(iconHolder.x - borderSize, iconHolder.y + iconHolder.height + borderTwice, width - borderTwice,
			(!achievement[4] || unlocked) ? achievement[2] : '?').setFormat(Paths.font('comic.ttf'), 20, FlxColor.WHITE, LEFT);

		iconHolder.alpha = .9;

		description.borderColor = FlxColor.BLACK;
		description.borderSize = borderSize;

		title.borderColor = FlxColor.BLACK;
		title.borderSize = borderSize;

		title.bold = true;
		title.y = iconHolder.y + ((iconHolder.height - title.height) / 2);

		iconBorder.setPosition(iconHolder.x + ((iconHolder.width - iconBorder.width) / 2), iconHolder.y + ((iconHolder.height - iconBorder.height) / 2));
		border.setPosition(-borderSize, -borderSize);

		add(border);
		add(frame);

		add(iconBorder);
		add(iconHolder);

		add(title);
		add(description);

		var icon:FlxGraphic = Paths.image('achievements/' + (unlocked ? achievement[0] : 'locked'));
		if (icon != null)
		{
			var sprite:FlxSprite = new FlxSprite().loadGraphic(icon);

			var iconHeight:Float = icon.height;
			var iconWidth:Float = icon.width;

			if (Math.max(iconWidth, iconHeight) > iconSize)
			{
				switch (iconWidth > iconHeight)
				{
					case true:
						sprite.setGraphicSize(iconSize);
					default:
						sprite.setGraphicSize(0, iconSize);
				}
			}

			sprite.updateHitbox();
			sprite.setPosition(iconHolder.x + ((iconHolder.width - sprite.width) / 2), iconHolder.y + ((iconHolder.height - sprite.height) / 2));

			sprite.antialiasing = ClientPrefs.getPref('globalAntialiasing');
			add(sprite);
		}
	}
}

class AchievementsSubstate extends ArcadeSubstate
{
	private inline static final borderPadding:Int = 8;
	private static var achievementSelected:Int = 0;

	private static var above:Bool = false;
	private static var padding:Float;

	private var interpolationTime:Float = 1 / 600 / 60;
	private var scrollBar:FlxSprite;

	private var achievementsList:FlxSpriteGroup;
	private var holdTime:Float = 0;

	override function new(camera:FlxCamera)
	{
		super(camera);

		var achievementHeight:Int = Std.int(mainCamera.width * .3);
		var achievementWidth:Int = Std.int(mainCamera.width * .9);

		var achievements:Array<Array<Dynamic>> = Achievements.achievements;
		padding = achievementHeight + (borderPadding * 3);

		achievementsList = new FlxSpriteGroup();
		achievementsList.cameras = [mainCamera];

		achievementsList.scrollFactor.set(1, 1);

		achievementsList.x = ((mainCamera.width - achievementWidth) / 2) - borderPadding;
		achievementsList.y = borderPadding;

		for (index in 0...achievements.length)
		{
			var achievement:AchievementObject = new AchievementObject(achievementWidth, achievementHeight, achievements[index]);

			achievement.y = padding * index;
			achievement.ID = index;

			achievementsList.add(achievement);
		}

		scrollBar = makeSprite(mainCamera.width - (borderPadding * 2),
			borderPadding).makeGraphic(borderPadding, Std.int(mainCamera.height * (2 / achievementsList.length)) - (borderPadding * 2), FlxColor.WHITE);

		scrollBar.scrollFactor.set();
		scrollBar.alpha = .5;

		updateSelection();

		add(scrollBar);
		add(achievementsList);

		mainCamera.scroll.y = getScroll();
	}

	override function update(elapsed:Float)
	{
		if (ArcadeState.stickVerticalPress != 0)
		{
			holdTime = 0;

			wrap(ArcadeState.stickVerticalPress);
			updateSelection();
		}
		if (ArcadeState.stickVertical != 0)
		{
			var checkLastHold:Int = Math.round(holdTime * 10);
			holdTime += elapsed;

			var checkNewHold:Int = Math.round(holdTime * 10);
			var holdDiff:Int = checkNewHold - checkLastHold;

			if (holdTime > .5 && holdDiff > 0)
			{
				wrap(-holdDiff * ArcadeState.stickVertical);
				updateSelection();

				FlxG.sound.play(Paths.sound('scrollMenu'), .2);
			}
		}
		else
		{
			// reset hold time if not HOLDING. Bitch
			holdTime = 0;
		}

		mainCamera.scroll.y = FlxMath.lerp(mainCamera.scroll.y, getScroll(), 1 - Math.pow(interpolationTime, elapsed));
		super.update(elapsed);
	}

	override function onAcceptRequest()
	{
		super.onAcceptRequest();
		#if debug
		var achievement:Achievement = Achievement.makeAchievement(Achievements.achievements[achievementSelected][0], ArcadeState.instance.camOther);
		if (achievement != null)
			add(achievement);
		#end
	}

	private inline function getScroll():Float
		return padding * Math.max(achievementSelected - (above ? 1 : 0), 0);

	private inline function wrap(delta:Int)
	{
		var newSelection:Int = CoolUtil.repeat(achievementSelected, delta, achievementsList.length);

		above = newSelection > achievementSelected;
		achievementSelected = newSelection;
	}

	private inline function updateSelection()
	{
		var len:Float = Math.max(achievementsList.length - 1, 1);
		scrollBar.y = FlxMath.lerp(borderPadding, mainCamera.height - scrollBar.height - borderPadding, achievementSelected / len);
		for (achievement in achievementsList.members)
			achievement.alpha = (achievement.ID == achievementSelected) ? 1 : .75;
	}

	public inline static function preload()
	{
		for (achievement in Achievements.achievements)
			Paths.image('achievements/' + achievement[0]);
	}
}
