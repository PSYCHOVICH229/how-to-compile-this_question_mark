package states.substates.pauses;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import meta.data.ClientPrefs;

class Scratch extends BasePause
{
	private var sizeTween:FlxTween;
	private var cat:FlxSprite;

	public function new(instance:PauseSubState)
	{
		// yesss
		super(instance, 100);
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);

		cat = new FlxSprite().loadGraphic(Paths.image('pausemenu/FunnyScratchIdle'));
		cat.antialiasing = ClientPrefs.getPref('globalAntialiasing');

		cat.screenCenter(Y);
		cat.x = FlxG.width + cat.width;

		cat.scrollFactor.set();
		cat.alpha = 0;

		bg.scrollFactor.set();
		bg.alpha = 0;

		add(bg);
		add(cat);

		FlxTween.tween(cat, {alpha: 1, x: FlxG.width - (cat.width * (Math.PI / 2))}, 1, {ease: FlxEase.sineOut});
		FlxTween.tween(bg, {alpha: .975}, .6, {ease: FlxEase.linear});
	}

	override function beatHit()
	{
		super.beatHit();
		cat.scale.set(1.1, 1.1);

		sizeTween?.cancel();
		sizeTween?.destroy();

		sizeTween = null;
		sizeTween = FlxTween.tween(cat, {"scale.x": 1, "scale.y": 1}, crochet / 1000, {ease: FlxEase.linear});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	override function destroy()
	{
		cat.kill();
		remove(cat, true);

		cat.destroy();
		super.destroy();
	}
}
