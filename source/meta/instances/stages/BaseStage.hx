package meta.instances.stages;

import flixel.group.FlxSpriteGroup;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.FlxG;
import states.PlayState;

// default stage object shit YEAAAAHHh
class BaseStage extends FlxBasic
{
	public var gfVersion:String = 'gf';
	public var initData:String = '';

	public var parent:Dynamic;

	// keeps track of all added instances (easy cleanup lolz)
	private var _instances:FlxGroup;

	public function new(parent:Dynamic)
	{
		super();
		this.parent = parent;

		_instances = new FlxGroup();
		_instances.active = false;
	}

	public function add(object:FlxBasic)
	{
		_instances?.add(object);
		parent?.add(object);
	}

	public function remove(object:FlxBasic, splice:Bool = false)
	{
		if (_instances != null && _instances.members.contains(object))
			_instances.remove(object, splice);
		if (parent != null && parent.members.contains(object))
			parent.remove(object, splice);
	}

	public function insert(position:Int, object:FlxBasic)
	{
		_instances?.add(object);
		parent?.insert(position, object);
	}

	inline public function addToStage(object:FlxBasic, offset:Int = 0)
		insert(parent.members.indexOf(parent.stageGroup) + offset, object);

	inline public function addBehindGF(object:FlxBasic, offset:Int = 0)
		insert(parent.members.indexOf(parent.gfGroup) + offset, object);

	inline public function addBehindDad(object:FlxBasic, offset:Int = 0)
		insert(parent.members.indexOf(parent.dadGroup) + offset, object);

	inline public function addBehindBF(object:FlxBasic, offset:Int = 0)
		insert(parent.members.indexOf(parent.boyfriendGroup) + offset, object);

	public function onStageAdded()
	{
		// when the stage is added
		trace('stage added: ' + this);
	}

	public function onSongStart()
	{
		// when the song starts (obviously lol)
		if (PlayState.introSoundKey == null && FlxG.random.bool(#if debug 10 #else 1 #end))
			PlayState.introSoundKey = 'kys';
		// add stage shit at shtarert
	}

	private function sectionHit(section:Int):Void
	{
		// filler
	}

	private function beatHit(beat:Int):Void
	{
		// filler
	}

	private function stepHit(step:Int):Void
	{
		// filler
	}

	override function kill()
	{
		_instances?.kill();
		super.kill();
	}

	override function revive()
	{
		_instances?.revive();
		super.revive();
	}

	override function destroy()
	{
		_instances?.forEach(function(instance:FlxBasic)
		{
			if (instance != null)
			{
				_instances.remove(instance);
				if (parent.members.contains(instance))
					parent.remove(instance, true);
				instance.destroy();
			}
		});

		_instances?.clear();
		_instances?.destroy();

		_instances = null;
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		// stage update shit
		// only called by parent(?)
		// _instances.update(elapsed);
		super.update(elapsed);
	}
}
