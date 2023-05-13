package states.arcade;

import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import openfl.text.TextFormat;
import flixel.math.FlxRect;
import hscript.Expr.VarDecl;
import openfl.geom.Matrix;
import meta.CoolUtil;
import flixel.FlxG;
import openfl.display.BitmapData;
import openfl.Assets;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxCamera;

using StringTools;

class CreditIcon extends FlxSpriteGroup
{
	public inline static final iconSize:Int = 50;
	private inline static final iconBorder:Int = iconSize + 4;

	public var border:FlxSprite;
	public var icon:FlxSprite;

	public static function getCreditIcon(icon:String):FlxGraphic
	{
		return Paths.image('credits/$icon');
	}

	public inline function setBorder(enabled:Bool)
	{
		var scaled:Float = enabled ? 1.1 : 1;

		border.alpha = enabled ? 1 : .3;
		border.scale.set(scaled, scaled);
	}

	override public function new(x:Float = 0, y:Float = 0, ?graphic:FlxGraphic, ?enabled:Bool = false, ?borderColor:FlxColor = FlxColor.WHITE)
	{
		super(x, y);

		var iconHolder:FlxSprite = new FlxSprite().makeGraphic(iconSize, iconSize, FlxColor.BLACK);
		iconHolder.alpha = .8;

		border = new FlxSprite().makeGraphic(iconBorder, iconBorder, borderColor);
		// shitting myself
		icon = new FlxSprite();
		if (graphic != null)
			icon.loadGraphic(graphic);

		var height:Float = icon.height;
		var width:Float = icon.width;
		// just save the computations
		if (Math.max(width, height) > iconSize)
		{
			switch (width > height)
			{
				case true:
					icon.setGraphicSize(iconSize);
				default:
					icon.setGraphicSize(0, iconSize);
			}
		}
		icon.updateHitbox();

		icon.y = (iconSize - icon.height) / 2;
		icon.x = (iconSize - icon.width) / 2;

		border.y = (iconHolder.height - border.height) / 2;
		border.x = (iconHolder.width - border.width) / 2;

		add(border);

		add(iconHolder);
		add(icon);

		setBorder(enabled);
	}
}

class CreditsSubstate extends ArcadeSubstate
{
	private inline static final ORIGINAL_ARTISTS_COLOR:FlxColor = 0xFF7700FF;

	private inline static final SHUTTLE_TEAM_COLOR:FlxColor = 0xFF72FF47;
	private inline static final SCB_TEAM_COLOR:FlxColor = 0xFFFF50FF;

	private static var credits:Array<Array<Dynamic>> = [
		[
			'Pandemonium',
			['Pandemonium_Icon', 'Pandemonium_Icon_2.0'],
			'Director',
			// ok now LISTEN ok this is a HAXE thing not a ME thing FUCK YOU
			'funnying v2 has been one of my most ambitious and impressive projects i\'ve ever worked on. i truly could not thank the team enough for helping me envision this huge and dope ass project, alongside the outstanding support for the mod. i never would\'ve thought that this mod would reach this level, especially since it was first started when i barely knew how to use haxeflixel, but seeing as it has makes me feel like i can truly go above and beyond for the mods that i need to work on and finish.
thank you for all of your support, funnyers, and i hope that this mod didn\'t disappoint.',
			[
				'https://youtube.com/@Paracosm_Daemon',
				'https://twitter.com/Paracosm_Daemon',
				'https://roblox.com/users/3249138008/profile',
				'https://paracosm-daemon.newgrounds.com/',
				'https://gamejolt.com/@Paracosm_Daemon',
				'https://gamebanana.com/members/2074221'
			],
			0xFF6D2B82,
			[15, 85]
		],
		[
			'J',
			'J_Icon',
			'Head Artist, Lyrics',
			'this mod genuinely improved my life in many ways, i think id be lying if i said it wasn\'t worth spending so much time on a mod about a Funny Rapping Boyfriend, it started as a dumb joke with me and pandemonium, but it became a way larger scale project then i ever expected to, funny on, funnyers.',
			[
				'https://youtube.com/channel/UCUbzTC7u5sBT--ZR6zJ5m1A',
				'https://twitter.com/Fwuffy_J',
				'https://roblox.com/users/3513131884/profile',
				'https://fwuffyj.newgrounds.com/',
				'https://gamejolt.com/@Fwuffy_J',
				'https://gamebanana.com/members/2236584'
			],
			0xFF99FFC3
		],
		[
			'Top 10 Awesome',
			'Top_10_Awesome_Icon_2.0',
			'Head Composer, Lyrics',
			'mario',
			[
				'https://youtube.com/@Top10Awesome',
				'https://twitter.com/top10awesome3',
				'https://roblox.com/users/3282717266/profile',
				'https://10awesome.newgrounds.com/',
				'https://gamebanana.com/members/2045839'
			],
			0xFFFFD621
		],
		[
			'dum dum',
			'Dum_Dum_Icon',
			'Composer, Charter',
			'Fridy night funnying its goood mod but sometimes its evil and hard songs',
			[
				'https://youtube.com/@dum-dum',
				'https://twitter.com/troIl_face',
				'https://roblox.com/users/52732018/profile',
				'https://dumdum4347.newgrounds.com',
				'https://gamejolt.com/@dum-dum',
				'https://gamebanana.com/members/1796910'
			],
			0xFFF7D336
		],
		[
			'teeb',
			'Teeb_Icon',
			'Programmer, Mac Builds',
			'i maked the awesome macintosh build',
			[
				'https://www.youtube.com/channel/UC958YDdvjmK72mbPIuZ-ERA',
				'https://twitter.com/aperssonn'
			],
			0xFF565656
		],
		[
			'Tribirdie',
			['Tribirdie_Icon', 'SILLY_TRIBIRDIE_ICON'],
			'Wiki Creator',
			'the average vs cheeky fan',
			'https://www.youtube.com/@tribirdie1942',
			0xFFE83434,
			[99, 1]
		],
		[
			'Tony',
			'Tony_Icon',
			'Animator',
			'30.02300° N, 90.14174° W
I wonder what those coordinates lead to...',
			['https://www.youtube.com/@TonyNoki', 'https://twitter.com/Daily48189776',],
			0xFF24569B
		],
		[
			'Nejc',
			'Nejc_Icon',
			'Voice Actor',
			'sorry but 5-8pm is blocked off as my liquor store time',
			[
				'https://www.youtube.com/channel/UC7k10oo3NXdbrCqSDiSYHtQ',
				'https://twitter.com/@nephewnejc'
			],
			0xFF1E141E
		],
		[
			'orichi',
			['Orichi_Icon', 'mayz'],
			'Composer, Charter, Lyrics',
			'Okay As Much as the things i made for this mod sucked I At least had fun sitting in calls and watching this mod slowly finish- its nice to see how much everyones improved since development started! the other devs are really cool and fun people and i look up to them greatly. i hope everyone who plays this mod have just as much fun as i did :D',
			[
				'https://youtube.com/@orichi2242',
				'https://twitter.com/orichi__',
				'https://roblox.com/users/544840163/profile'
			],
			null,
			[96, 4]
		],
		[
			'joker',
			'Joker_Icon',
			'Composer',
			'i made intestinal failure, twice....',
			'https://twitter.com/JokerDaJokester'
		],
		[
			'Gelzazz',
			'Gelzazz_Icon',
			'Composer',
			'Don\'t bang the table, The Table: In all serious thanks for checking out this mod its made me find new friends and helped me through a very tough time. Its even helped my good friend GachaBlaze on a day she was sad by making her laugh. Thanks to everyone who played this mod it was truly a Funnying Forever, Gel out.',
			[
				'https://www.youtube.com/@Gelzazz',
				'https://twitter.com/Gelzazz',
				'https://www.roblox.com/users/3572584256/profile',
				'https://steamcommunity.com/id/Gelzazz',
				'https://gelzazz.newgrounds.com',
				'https://www.tumblr.com/gelzazz',
				'https://gamejolt.com/@Gelzazz',
				'https://gamebanana.com/members/1867886'
			]
		],
		[
			'Pigswipe',
			'Pigswipe_Icon',
			'Composer',
			'i made one song for this mod, added myself to the credits, and then stopped working on this lmfao. it was fun to make the song though, and to watch the development process for a larger fnf mod.',
			[
				'https://youtube.com/c/pigswipe',
				'https://twitter.com/pigswipe',
				'https://roblox.com/users/34795114/profile',
				'https://steamcommunity.com/id/pigswipe',
				'https://gamebanana.com/members/1675727'
			]
		],
		[
			'Shinolad',
			'Shinolad_Icon',
			'Charter',
			'i begged someone to be on this mod and it worked',
			['https://www.youtube.com/@Shinolad', 'https://twitter.com/ahonkingoose',]
		],
		[
			'Crasher0',
			['Crash_Icon', 'IMG_5365'],
			'Artist, Animator',
			'i want my cock sucked by a 54 year old stripper with 20 stds and crooked yellow teeth',
			'https://youtu.be/y5cS0Y6OYvg',
			null,
			[75, 25]
		],
		[
			'LayLasagna',
			'LayLasagna_Icon_3.0',
			'Artist',
			'Hherllo
Oh wai hold on
Let me think of something..
Live love yaoi!!! * heart emoji* stay funnying! Also follow my socials',
			[
				'https://www.youtube.com/@laylasagna735',
				'https://twitter.com/LayLasagna7',
				'https://www.instagram.com/laylasagna/',
				'https://trojanvirus.carrd.co/'
			]
		],
		[
			'Greene',
			'Greene_Icon',
			'Artist',
			'crumble mix',
			['https://www.youtube.com/@goingreene', 'https://twitter.com/pincegeen']
		],
		[
			'Gangster Spongebob',
			'Gangster_Spongebob_Icon',
			'Shuttle Man Director, Artist, Composer',
			'bestie this is your mixtape what do you think',
			'https://youtube.com/watch?v=a_l1S1iX5WY',
			SHUTTLE_TEAM_COLOR
		],
		[
			'Benju',
			'Benju_Icon_2.0',
			'Shuttle Man Director, Artist, Animator, Lyrics',
			'I am the haaaauuugh guy',
			[
				'https://youtube.com/c/BenjuKatchowee',
				'https://twitter.com/BenjuKatchowee',
				'https://roblox.com/users/120063677/profile',
				'https://benju-katchowee.newgrounds.com',
				'https://steamcommunity.com/id/BenjuKatchowee/',
				'https://gamejolt.com/@BenjuKatchowee',
				'https://gamebanana.com/members/1659758'
			],
			SHUTTLE_TEAM_COLOR
		],
		[
			'DragonFlame',
			'DragonFlame_Icon',
			'Shuttle Man Artist, Animator',
			'I Am Dragon Flame Forty Two And I Like Men!',
			[
				'https://www.youtube.com/channel/UC3Ce7EgfQAeXl5nyof6Bw6A',
				'https://twitter.com/FGTWT_',
				'https://gamejolt.com/@DragonFlame42',
				'https://gamebanana.com/mods/351482'
			],
			SHUTTLE_TEAM_COLOR
		],
		[
			'callie',
			'Callie_Icon',
			'Shuttle Man Programmer, Composer',
			'play bakers dozen and moshing :) and also shuttle man #BOOWENDY',
			[
				'https://youtube.com/channel/UCLVnszQQqqnnuK6NJRlzLXg',
				'https://twitter.com/calliecoolswag',
				'https://gamejolt.com/@eggvipers',
				'https://gamebanana.com/members/2610031'
			],
			SHUTTLE_TEAM_COLOR
		],
		[
			'VideoGabes',
			['VideoGabes_Icon', 'whistle'],
			'Creator of Sans Cuphead and Bendy',
			'Vs Mouse 1# fan',
			[
				'https://www.youtube.com/@SansCupheadandBendy',
				'https://twitter.com/VideoGabesA',
				'https://videogabes17.newgrounds.com/',
				'https://gamejolt.com/@VideoGabes'
			],
			SCB_TEAM_COLOR,
			[99, 1]
		],
		[
			'Joelx5',
			'Joel_Icon',
			'Original creator of Funny BF',
			'FUN, OR PAIN!',
			[
				'https://www.youtube.com/c/Joelx5Guy',
				'https://twitter.com/Joelbrunox5Sfw',
				'https://www.deviantart.com/joelbrunomanrique'
			],
			ORIGINAL_ARTISTS_COLOR
		],
		[
			'jaob',
			'Jaob_Icon',
			'Original creator of YouTooz BF',
			'yeehaw i\'m jaob and i made that youtooz boyfriend "drawing". i\'m very sorry for that. i make better stuff now check that out',
			['https://twitter.com/jaob_vg', 'https://www.instagram.com/fakeemp3'],
			ORIGINAL_ARTISTS_COLOR
		]
	];
	private static var linkRemappings:Map<String, String> = ['steamcommunity' => 'steam', 'youtu.be' => 'youtube', 'youtu' => 'youtube'];

	private inline static final creditRows:Int = 4;
	private inline static final iconPadding:Float = CreditIcon.iconSize + 20;

	private inline static final separatorWidth:Int = 4;
	private inline static final borderPadding:Float = separatorWidth * 2;

	private inline static final truncatedText:String = '..."';

	private inline static final socialLinkSize:Int = 50;
	private inline static final socialLinkPadding:Int = socialLinkSize + 10;

	private inline static final socialLinkIndexing:String = '://';
	private inline static final socialLinkAmount:Int = 3;

	private inline static final creditIconSize:Int = 150;

	private static var currentCredit:Int = 0;
	private static var currentRow:Int = getRows(currentCredit);

	private static var wasAbove:Bool = false;

	private var goofShit:FlxSound;

	private var checkingMoreDetails:Bool = false;
	private var moreDetails:FlxSpriteGroup;

	private var detailsWindow:FlxSprite;

	private var socialLinksGroup:FlxSpriteGroup;
	private var socialLinks:Array<String>;

	private var visitingSocialCooldown:Float = -1;
	private var socialLinkRange:FlxText;

	private var detailedDescriptionBar:FlxSprite;
	private var detailedDescription:FlxText;

	private var detailedDropdown:FlxSpriteGroup;
	private var scrollingRect:FlxRect;

	private var scrollBar:FlxSprite;

	private var scrollableLines:Int = 0;
	private var linesScrolled:Int = 0;

	private var currentLink:Int = 0;

	private var creditDescription:FlxText;
	private var creditText:FlxText;

	private var creditName:FlxText;

	private var creditBorder:FlxSprite;
	private var creditInline:FlxSprite;

	private var creditIcon:FlxSprite;
	private var creditIconGrid:FlxSpriteGroup;

	override function new(camera:FlxCamera)
	{
		// note to self always call super first or it will Shit itself
		super(camera);
		goofShit = FlxG.sound.list.add(new FlxSound());
		// CREDITS
		var separatorX:Float = mainCamera.width * .6;
		var sidebarX:Float = separatorX + separatorWidth;

		add(makeSprite(separatorX).makeGraphic(separatorWidth, mainCamera.height, FlxColor.WHITE));

		scrollBar = makeSprite(separatorX - borderPadding - separatorWidth,
			borderPadding).makeGraphic(separatorWidth * 2,
				Std.int((mainCamera.height - borderPadding) / Math.max(getRows(credits.length - 1) / Math.max(getMaximumRows(), 1), 1)), FlxColor.WHITE);
		scrollBar.cameras = [mainCamera];

		scrollBar.alpha = .5;

		creditIconGrid = new FlxSpriteGroup(borderPadding, borderPadding);
		creditIconGrid.antialiasing = false;

		creditIconGrid.cameras = [mainCamera];
		creditIconGrid.scrollFactor.set(1, 1);

		var descriptionWidth:Float = mainCamera.width - separatorX;
		var sidebarWidth:Float = descriptionWidth - separatorWidth;

		creditName = new FlxText(sidebarX, borderPadding, sidebarWidth).setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, CENTER);
		creditName.cameras = [mainCamera];

		creditInline = makeSprite(sidebarX + ((descriptionWidth - creditIconSize) / 2), 0).makeGraphic(creditIconSize, creditIconSize, FlxColor.BLACK, true);

		creditInline.alpha = .85;
		creditInline.cameras = [mainCamera];

		creditBorder = makeSprite().makeGraphic(creditIconSize + (separatorWidth * 2), creditIconSize + (separatorWidth * 2), FlxColor.WHITE, true);
		creditBorder.cameras = [mainCamera];

		creditIcon = makeSprite(0, borderPadding);
		creditIcon.cameras = [mainCamera];

		creditText = new FlxText(sidebarX, 0, sidebarWidth).setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, CENTER);
		creditText.cameras = [mainCamera];

		creditDescription = new FlxText(sidebarX, 0, sidebarWidth).setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, CENTER);
		creditDescription.cameras = [mainCamera];

		for (index in 0...credits.length)
		{
			var credit:Array<Dynamic> = credits[index];
			var creditIcon:FlxGraphic = getCorrectIcon(credit);

			var icon:CreditIcon = new CreditIcon(iconPadding * (index % creditRows), iconPadding * Std.int(index / creditRows), creditIcon,
				index == currentCredit, credit[5]);

			icon.cameras = [mainCamera];
			icon.ID = index;

			creditIconGrid.add(icon);
		}

		add(creditIconGrid);
		add(creditName);

		add(creditText);
		add(creditDescription);

		add(creditBorder);
		add(creditInline);

		add(creditIcon);
		add(scrollBar);
		// DETAILS
		moreDetails = new FlxSpriteGroup();

		moreDetails.cameras = [mainCamera];
		moreDetails.scrollFactor.set();

		var bg:FlxSprite = makeSprite().makeGraphic(Std.int(separatorX), mainCamera.height, FlxColor.GRAY);
		bg.alpha = .25;

		detailsWindow = makeSprite().makeGraphic(Std.int(separatorX * .9), Std.int(mainCamera.height * .9), FlxColor.BLACK, true);
		detailsWindow.alpha = .95;

		centerObject(detailsWindow, Y);
		detailsWindow.x = (separatorX - detailsWindow.width) / 2;

		var outline:FlxSprite = makeSprite().makeGraphic(Std.int(detailsWindow.width + borderPadding), Std.int(detailsWindow.height + borderPadding),
			FlxColor.WHITE, true);
		centerObject(outline, XY, detailsWindow);

		socialLinksGroup = new FlxSpriteGroup(0, detailsWindow.y + borderPadding);
		socialLinkRange = new FlxText(detailsWindow.x, 0, detailsWindow.width).setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, CENTER);

		detailedDescriptionBar = makeSprite(detailsWindow.x).makeGraphic(Std.int(detailsWindow.width), separatorWidth, FlxColor.WHITE, false);
		detailedDescription = new FlxText(detailsWindow.x, 0, detailsWindow.width).setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER);

		detailedDropdown = new FlxSpriteGroup(detailsWindow.x);
		var dropdownSeparator:FlxSprite = makeSprite().makeGraphic(Std.int(detailsWindow.width), separatorWidth, FlxColor.WHITE, true);

		dropdownSeparator.alpha = .8;
		detailedDropdown.add(dropdownSeparator);

		var dropdownBody:FlxSprite = makeSprite(0,
			separatorWidth).makeGraphic(Std.int(detailsWindow.width), detailedDescription.size * 2, FlxColor.BLACK, true);
		var dropdownText:FlxText = new FlxText(0, 0, detailsWindow.width,
			'v').setFormat(Paths.font('vcr.ttf'), detailedDescription.size, FlxColor.WHITE, CENTER);

		dropdownBody.alpha = .8;
		dropdownText.alpha = .75;

		dropdownText.bold = true;
		dropdownText.y = dropdownBody.y + ((dropdownBody.height - dropdownText.size) / 2);

		detailedDropdown.add(dropdownBody);
		detailedDropdown.add(dropdownText);

		detailedDropdown.y = detailsWindow.y + (detailsWindow.height - detailedDropdown.height);
		moreDetails.add(bg);

		moreDetails.add(outline);
		moreDetails.add(detailsWindow);

		moreDetails.add(socialLinksGroup);
		moreDetails.add(socialLinkRange);

		moreDetails.add(detailedDescriptionBar);
		moreDetails.add(detailedDescription);

		moreDetails.add(detailedDropdown);
		moreDetails.visible = checkingMoreDetails;

		add(moreDetails);

		var newRow:Int = getRows(currentCredit);
		var maximumRows:Int = getMaximumRows();

		updateShit(newRow, maximumRows, newRow < (wasAbove ? currentRow : (currentRow - maximumRows)));
		updateCredits();
	}

	override function update(elapsed:Float)
	{
		var horizontal:Int = ArcadeState.stickHorizontalPress;
		var vertical:Int = ArcadeState.stickVerticalPress;

		if (horizontal != 0 || vertical != 0)
		{
			switch (checkingMoreDetails)
			{
				case true:
					{
						if (socialLinks.length > 1 && horizontal != 0)
						{
							currentLink = CoolUtil.repeat(currentLink, horizontal, socialLinks.length);
							updateSocialLinks();
						}
						if (scrollableLines > 0 && vertical != 0)
						{
							var lastScrolled:Int = linesScrolled;
							linesScrolled = Std.int(FlxMath.bound(linesScrolled + vertical, 0, scrollableLines));
							if (linesScrolled != lastScrolled)
							{
								// i give up fuck this Stupid leading i just hardcoded it
								var offsetY:Float = linesScrolled * (detailedDescription.size - 2);
								// dont ask the text clips at the top for some reason
								if (linesScrolled > 0)
									offsetY += .5;

								detailedDescription.offset.y = scrollingRect.y = offsetY;
								detailedDescription.clipRect = scrollingRect;

								switch (linesScrolled < scrollableLines)
								{
									case true: detailedDropdown.revive();
									default: detailedDropdown.kill();
								}
							}
						}
					}
				default:
					{
						var len:Int = credits.length - 1;
						if (horizontal != 0)
						{
							// could probably be optimized but i suck ass at math so YAAAAAY!!!!!!!!!!!!
							var wrap:Int = CoolUtil.repeat(currentCredit, horizontal, credits.length);
							if (getRows(currentCredit) != getRows(wrap))
							{
								// Prevents incorrect repeating for rows with <= 1 cell
								wrap = currentCredit;

								var next:Int = currentCredit - horizontal;
								while (getRows(currentCredit) == getRows(CoolUtil.wrap(next, credits.length)))
								{
									wrap = next;
									next -= horizontal;
								}
							}
							currentCredit = wrap;
						}
						if (vertical != 0)
						{
							var delta:Int = vertical * creditRows;
							var diff:Int = currentCredit + delta;

							if (diff > len)
							{
								// repeats grid vertically but like the other way
								currentCredit %= creditRows;
							}
							else if (diff < 0)
							{
								// no fucking clue if this can be optimized
								// supposed to repeat grid vertically
								while ((currentCredit - delta) <= len)
									currentCredit -= delta;
							}
							else
							{
								currentCredit = CoolUtil.repeat(currentCredit, delta, credits.length);
							}

							var newRow:Int = getRows(currentCredit);
							var maximumRows:Int = getMaximumRows();
							// works i think
							var above:Bool = newRow < (wasAbove ? currentRow : (currentRow - maximumRows));
							if (above || (newRow > currentRow && newRow > maximumRows))
								updateShit(newRow, maximumRows, above);
						}

						creditIconGrid.forEach(function(icon:FlxSprite)
						{
							cast(icon, CreditIcon).setBorder(icon.ID == currentCredit);
						});
						updateCredits();
					}
			}
		}
		if (visitingSocialCooldown > 0)
			visitingSocialCooldown -= elapsed;
		super.update(elapsed);
	}

	override function onAcceptRequest():Void
	{
		super.onAcceptRequest();
		switch (checkingMoreDetails)
		{
			case true:
				{
					var link:String = socialLinks[currentLink];
					if (link != null && visitingSocialCooldown <= 0)
					{
						visitingSocialCooldown = 1 / 3;
						CoolUtil.browserLoad(link);
					}
				}
			default:
				{
					var credit:Array<Dynamic> = credits[currentCredit];
					var descriptionText:String = credit[3];

					var description:String = descriptionText ?? '?';
					if (goofShit != null)
					{
						switch (Paths.formatToSongPath(credit[0]))
						{
							case 'benju':
								{
									trace('haugh');
									goofShit.loadEmbedded(Paths.sound('arcade/haugh')).play(true);
								}
							case 'teeb':
								{
									trace('jack off');
									goofShit.loadEmbedded(Paths.sound('arcade/cant')).play(true);
								}
							case 'callie':
								{
									trace('quirky');
									goofShit.loadEmbedded(Paths.sound('arcade/quirky')).play(true);
								}
							case 'orichi':
								{
									trace('pedohile');
									goofShit.loadEmbedded(Paths.sound('arcade/retrofiles')).play(true);
								}
						}
					}

					currentLink = 0;
					linesScrolled = 0;

					updateSocialLinks();
					repositionDetails();

					detailedDescription.text = '"$description"\n\n<CANCEL to exit>';

					var maxLines:Int = getMaximumLines(detailedDescription, detailsWindow.height);
					var lineAmount:Int = detailedDescription.textField.numLines;

					scrollableLines = lineAmount - maxLines - 1;

					detailedDescription.clipRect = scrollingRect = new FlxRect(0, 0, detailsWindow.width,
						(maxLines * detailedDescription.size) + borderPadding);
					detailedDescription.offset.set();

					switch (scrollableLines > 0)
					{
						case true: detailedDropdown.revive();
						default: detailedDropdown.kill();
					}
					moreDetails.visible = checkingMoreDetails = true;
				}
		}
	}

	override function onCloseRequest():Bool
	{
		if (checkingMoreDetails)
		{
			if (goofShit?.playing)
				goofShit.stop();
			return moreDetails.visible = checkingMoreDetails = false;
		}
		return super.onCloseRequest();
	}

	private inline static function getMaximumLines(object:FlxText, height:Float):Int
		return Math.round((height - object.y) / object.size);

	private inline static function getRows(value:Int):Int
		return Std.int(value / creditRows);

	private inline function getMaximumRows():Int
		return Std.int((mainCamera.height - borderPadding) / iconPadding);

	private inline function updateShit(newRow:Int, maximumRows:Int, ?above:Bool = false)
	{
		wasAbove = above;

		currentRow = newRow;
		creditIconGrid.y = borderPadding - ((above ? newRow : Math.max(newRow - maximumRows, 0)) * iconPadding);

		scrollBar.y = FlxMath.lerp(borderPadding, mainCamera.height - scrollBar.height - borderPadding, newRow / Math.max(getRows(credits.length - 1), 1));
	}

	private inline function updateSocialLinks()
	{
		socialLinksGroup.forEach(function(link:FlxSprite)
		{
			link.kill();
			socialLinksGroup.remove(link, true);
			link.destroy();
		});
		socialLinksGroup.clear();

		var amountMin:Int = Std.int(Math.min(socialLinkAmount, socialLinks.length));
		var lessThan:Bool = amountMin <= 2;

		var halfAmount:Float = amountMin / 2;
		var floorAmount:Int = Math.floor(halfAmount);

		for (index in -floorAmount...Math.ceil(halfAmount))
		{
			var correctIndex:Int = index + floorAmount;
			var website:String = socialLinks[
				lessThan ? correctIndex : CoolUtil.repeat(currentLink, index, socialLinks.length)
			];

			if (website != null)
			{
				var selected:Bool = switch (lessThan)
				{
					case true:
						correctIndex == currentLink;
					default:
						index == 0;
				};

				var sub:String = website.substring(website.indexOf(socialLinkIndexing) + socialLinkIndexing.length, website.lastIndexOf('.'));
				var format:String = Paths.formatToSongPath(sub.substring(sub.indexOf('.') + 1));

				var name:String = linkRemappings.exists(format) ? linkRemappings.get(format) : format;
				var graphic:FlxGraphic = Paths.image('websites/$name');

				if (graphic != null)
				{
					var socialIcon:FlxSprite = makeSprite(socialLinkPadding * correctIndex).loadGraphic(graphic);

					var height:Float = graphic.height;
					var width:Float = graphic.width;

					var multiplier:Float = lessThan ? 1 : (1 - ((Math.abs(index) - 1) * .35));
					var scaled:Float = selected ? 1 : (.85 * multiplier);

					if (Math.max(width, height) > socialLinkSize)
					{
						switch (width > height)
						{
							case true:
								socialIcon.setGraphicSize(socialLinkSize);
							default:
								socialIcon.setGraphicSize(0, socialLinkSize);
						}
					}

					socialIcon.updateHitbox();
					socialIcon.scale.set(socialIcon.scale.x * scaled, socialIcon.scale.y * scaled);

					socialIcon.alpha = selected ? 1 : (.4 * multiplier);
					socialLinksGroup.add(socialIcon);
				}
			}
		}

		socialLinksGroup.x = detailsWindow.x + ((detailsWindow.width - socialLinksGroup.width) / 2);
		socialLinkRange.text = '<' + Std.int(Math.min(currentLink + 1, socialLinks.length)) + ' / ' + socialLinks.length + '>';
	}

	private inline function repositionDetails()
	{
		socialLinkRange.y = socialLinksGroup.y + (socialLinkSize * Math.min(socialLinks.length, 1)) /*socialLinkSize*/ + borderPadding;

		detailedDescriptionBar.y = socialLinkRange.y + socialLinkRange.size + borderPadding;
		detailedDescription.y = detailedDescriptionBar.y + borderPadding;
	}

	private inline function repositionCredits()
	{
		creditInline.y = creditName.y + creditName.height + borderPadding;

		creditBorder.x = creditInline.x - separatorWidth;
		creditBorder.y = creditInline.y - separatorWidth;

		creditText.y = creditInline.y + creditIconSize + borderPadding;
		creditDescription.y = creditText.y + creditText.height + separatorWidth;
	}

	private inline function getCorrectIcon(credit:Array<Dynamic>):Null<FlxGraphic>
	{
		var creditIcon:Dynamic = credit[1];
		if (creditIcon != null)
		{
			if (Std.isOfType(creditIcon, Array))
			{
				var creditIcons:Array<String> = creditIcon;
				creditIcon = FlxG.random.getObject(creditIcons, credit[6]);
			}
			return CreditIcon.getCreditIcon(creditIcon);
		}
		return null;
	}

	private inline function updateCredits():Void
	{
		var credit:Array<Dynamic> = credits[currentCredit];
		var color:Null<FlxColor> = credit[5];

		var description:String = credit[3];
		var links:Dynamic = credit[4];

		var name:String = credit[0];
		var text:String = credit[2];

		if (Std.isOfType(links, Array))
		{
			socialLinks = links;
		}
		else
		{
			socialLinks = [];
			if (links != null)
				socialLinks.push(links);
		}

		creditName.text = (name ?? '?') + '\n<ACCEPT for more>';
		creditText.text = text ?? '?';

		creditBorder.color = color ?? FlxColor.WHITE;
		repositionCredits();

		creditDescription.text = truncateText(creditDescription, description.trim());

		var graphic:FlxGraphic = getCorrectIcon(credit);
		if (graphic != null)
		{
			creditIcon.loadGraphic(graphic);

			var height:Float = graphic.height;
			var width:Float = graphic.width;

			if (Math.max(width, height) > creditIconSize)
			{
				switch (width > height)
				{
					case true:
						creditIcon.setGraphicSize(creditIconSize);
					default:
						creditIcon.setGraphicSize(0, creditIconSize);
				}
			}
			else
			{
				creditIcon.setGraphicSize(Std.int(width), Std.int(height));
			}
			creditIcon.updateHitbox();
		}
		else
		{
			creditIcon.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		}

		creditIcon.y = creditInline.y + ((creditIconSize - creditIcon.height) / 2);
		creditIcon.x = creditInline.x + ((creditIconSize - creditIcon.width) / 2);
	}

	private inline function truncateText(object:FlxText, ?text:String):String
	{
		if (text == null)
			return '?';

		var maximumLines:Int = getMaximumLines(object, mainCamera.height); // Math.round((mainCamera.height - object.y) / object.size);
		var trimmed:String = object.text = text;

		var truncated:String = '"$trimmed"';
		while (object.textField.numLines >= maximumLines)
		{
			truncated = truncatedText;
			object.text = trimmed = trimmed.substring(0, trimmed.lastIndexOf(' ')).trim();

			truncated = '"$trimmed$truncatedText';
		}
		return truncated;
	}

	public inline static function preload():Void
	{
		Paths.sound('haugh');
		Paths.sound('cant');

		for (credit in credits)
		{
			var icon:Dynamic = credit[1];
			if (icon != null)
			{
				if (Std.isOfType(icon, Array))
				{
					var icons:Array<String> = icon;
					for (iconChild in icons)
						CreditIcon.getCreditIcon(iconChild);
				}
				else
				{
					CreditIcon.getCreditIcon(icon);
				}
			}
		}
	}
}
