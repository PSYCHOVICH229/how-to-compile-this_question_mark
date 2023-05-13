package states;

import meta.data.ClientPrefs;
import meta.Conductor;
import meta.data.Song.SwagSong;
import meta.Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;

class MusicBeatState extends FlxUIState
{
	public var curStep:Int = 0;
	public var curBeat:Int = 0;

	public var curDecStep:Float = 0;
	public var curDecBeat:Float = 0;

	public var curSection:Int = 0;
	public var stepsToDo:Int = 0;

	public static var camBeat:FlxCamera;
	public static var coolerTransition:Bool = false;

	override function create()
	{
		camBeat = FlxG.camera;

		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		if (!skip)
		{
			if (coolerTransition && !ClientPrefs.getPref('lowQuality'))
			{
				trace("do th cooler transition but OUT");

				coolerTransition = false;
				openSubState(new CoolerTransition(true));
			}
			else
			{
				coolerTransition = false;
				openSubState(new CustomFadeTransition(.7, true));
			}
		}
		FlxTransitionableState.skipNextTransOut = false;
	}

	override function update(elapsed:Float)
	{
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep > 0)
				stepHit();
			if (oldStep < curStep)
			{
				updateSection();
			}
			else
			{
				rollbackSection();
			}
		}
		super.update(elapsed);
	}

	private inline function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;

			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);

			sectionHit();
		}
	}

	private inline function rollbackSection():Void
	{
		if (curStep < 0)
			return;

		curSection = 0;
		stepsToDo = 0;

		if (PlayState.SONG != null)
		{
			for (i in 0...PlayState.SONG.notes.length)
			{
				if (PlayState.SONG.notes[i] != null)
				{
					stepsToDo += Math.round(getBeatsOnSection() * 4);
					if (stepsToDo > curStep)
						break;

					curSection++;
				}
			}
		}
	}

	private inline function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private inline function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = Conductor.getBPMFromSeconds(Conductor.songPosition);
		var shit:Float = ((Conductor.songPosition - ClientPrefs.getPref('noteOffset')) - lastChange.songTime) / lastChange.stepCrochet;

		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState)
	{
		// Custom made Trans in
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;

		if (!FlxTransitionableState.skipNextTransIn)
		{
			if (nextState == FlxG.state)
			{
				CustomFadeTransition.finishCallback = FlxG.resetState.bind();
			}
			else
			{
				CustomFadeTransition.finishCallback = FlxG.switchState.bind(nextState);
			}

			if (coolerTransition && !ClientPrefs.getPref('lowQuality'))
			{
				trace("do th cooler transition");
				leState.openSubState(new CoolerTransition(false));
			}
			else
			{
				leState.openSubState(new CustomFadeTransition(.6, false));
			}
			return;
		}

		FlxTransitionableState.skipNextTransIn = coolerTransition = false;
		FlxG.switchState(nextState);
	}

	public inline static function resetState()
		MusicBeatState.switchState(FlxG.state);

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// trace('Beat: ' + curBeat);
	}

	public function sectionHit():Void
	{
		// trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}

	private inline function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		var song:SwagSong = PlayState.SONG;

		if (song != null && song.notes[curSection] != null)
			val = song.notes[curSection].sectionBeats;
		return if (val != null) val else 4;
	}
}
