package states;

import meta.data.StageData;
import meta.data.Song.SwagSong;
import meta.data.ClientPrefs;
import meta.CoolUtil;
import meta.instances.HealthIcon;
import meta.instances.Character;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import haxe.io.Path;
import lime.app.Future;
import lime.app.Promise;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets as LimeAssets;
import openfl.utils.Assets;

class LoadingState extends MusicBeatState
{
	public inline static final DEFAULT_LIBRARY:String = 'shared';
	inline static var MIN_TIME = 1;

	// Browsers will load create(), you can make your song load a custom directory there
	// If you're compiling to desktop (or something that doesn't use NO_PRELOAD_ALL), search for getNextState instead
	// I'd recommend doing it on both actually lol
	// TO DO: Make this easier
	private var target:FlxState;
	private var stopMusic:Bool = false;

	private var directory:String;
	private var callbacks:MultiCallback;

	private var useCallbacks:Bool = true;
	private var targetShit:Float = 0;

	private var numRemaining:Int = 0;
	private var numLength:Int = 0;

	private var funkay:FlxSprite;
	private var loadBar:FlxSprite;

	public function new(target:FlxState, stopMusic:Bool = false, directory:String = DEFAULT_LIBRARY)
	{
		super();

		this.stopMusic = stopMusic;
		this.directory = directory;
		this.target = target;
	}

	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xffcaff4d);
		var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');

		bg.antialiasing = false;

		add(bg);
		funkay = new FlxSprite().loadGraphic(Paths.getPath('images/awesome.png', IMAGE));

		funkay.setGraphicSize(0, Std.int(FlxG.height * .8));
		funkay.updateHitbox();

		funkay.scrollFactor.set();
		funkay.screenCenter();

		funkay.antialiasing = globalAntialiasing;
		funkay.alpha = 0;

		add(funkay);
		loadBar = new FlxSprite(0, FlxG.height - 20).makeGraphic(FlxG.width, 10, 0xffff16d2);

		loadBar.scale.x = 0;
		loadBar.screenCenter(X);

		loadBar.antialiasing = globalAntialiasing;

		add(loadBar);
		initSongsManifest().onComplete(function(lib)
		{
			callbacks = new MultiCallback(onLoad);
			var introComplete:() -> Void = callbacks.add("introComplete");

			checkLibrary(DEFAULT_LIBRARY);
			if (directory != null && directory.length > 0 && directory != DEFAULT_LIBRARY)
				checkLibrary(directory);

			var fadeTime = .5;
			FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true);
			new FlxTimer().start(fadeTime + MIN_TIME, function(_) introComplete());
		});
	}

	private function checkLoadSong(path:String)
	{
		if (!Assets.cache.hasSound(path))
		{
			var callback:() -> Void = callbacks.add('song:$path');
			Assets.loadSound(path).onComplete(function(_)
			{
				callback();
			});
		}
	}

	private function checkLibrary(library:String)
	{
		trace(Assets.hasLibrary(library));
		if (Assets.getLibrary(library) == null)
		{
			@:privateAccess
			if (!LimeAssets.libraryPaths.exists(library))
				throw 'Missing library: $library';

			var callback = callbacks.add('library:$library');
			Assets.loadLibrary(library).onComplete(function(_)
			{
				callback();
			});
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (funkay != null)
			funkay.alpha = Math.min(funkay.alpha + (elapsed * 2), 1);

		targetShit = FlxMath.remapToRange(((useCallbacks && callbacks.length > 0)
			|| numLength > 0) ? ((useCallbacks ? callbacks.numRemaining : numRemaining) / (useCallbacks ? callbacks.length : numLength)) : 0,
			1, 0, 0, 1);
		if (loadBar != null)
			loadBar.scale.x += .5 * (targetShit - loadBar.scale.x);
	}

	private function onLoad()
	{
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music?.stop();

		#if PRELOAD_ALL
		var song:SwagSong = PlayState.SONG;
		if (song != null)
		{
			trace('cache the song in loadingstate :3');

			useCallbacks = false;
			numRemaining = numLength = 1;

			PlayState.cacheShitForSong(song);
			numRemaining = 0;
		}
		#end
		MusicBeatState.switchState(target);
	}

	public inline static function loadAndSwitchState(target:FlxState, stopMusic:Bool = false, skipLoadingScreen:Bool = false)
		MusicBeatState.switchState(getNextState(target, stopMusic, skipLoadingScreen));

	private static function getNextState(target:FlxState, stopMusic:Bool = false, skipLoadingScreen:Bool = false):FlxState
	{
		var directory:String = DEFAULT_LIBRARY;
		var weekDir:String = StageData.forceNextDirectory;

		StageData.forceNextDirectory = null;
		if (weekDir != null && weekDir.length > 0)
			directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to $directory');

		var song:SwagSong = PlayState.SONG;
		#if NO_PRELOAD_ALL
		var loaded:Bool = false;
		if (song != null)
		{
			loaded = isSoundLoaded(Paths.inst(song.song))
				&& (!song.needsVoices || isSoundLoaded(Paths.voices(song.song)))
				&& isLibraryLoaded(DEFAULT_LIBRARY)
				&& isLibraryLoaded(directory);
		}

		if (!loaded)
			return new LoadingState(target, stopMusic, directory);
		#end

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music?.fadeOut(.6, 0);
		return #if PRELOAD_ALL (song != null
			&& !skipLoadingScreen
			&& (!MusicBeatState.coolerTransition || ClientPrefs.getPref('lowQuality'))) ? new LoadingState(target, stopMusic,
				directory) : target #else target #end;
	}

	#if NO_PRELOAD_ALL
	private inline static function isSoundLoaded(path:String):Bool
		return Assets.cache.hasSound(path);

	private inline static function isLibraryLoaded(library:String):Bool
		return Assets.getLibrary(library) != null;
	#end

	override function destroy()
	{
		super.destroy();
		callbacks = null;
	}

	private static function initSongsManifest()
	{
		var id = "songs";
		var promise = new Promise<AssetLibrary>();

		var library = LimeAssets.getLibrary(id);
		if (library != null)
			return Future.withValue(library);

		var path = id;
		var rootPath = null;

		@:privateAccess
		var libraryPaths = LimeAssets.libraryPaths;
		if (libraryPaths.exists(id))
		{
			path = libraryPaths[id];
			rootPath = Path.directory(path);
		}
		else
		{
			if (StringTools.endsWith(path, ".bundle"))
			{
				rootPath = path;
				path += "/library.json";
			}
			else
			{
				rootPath = Path.directory(path);
			}
			@:privateAccess
			path = LimeAssets.__cacheBreak(path);
		}

		AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest)
		{
			if (manifest == null)
			{
				promise.error("Cannot parse asset manifest for library \"" + id + "\"");
				return;
			}

			var library = AssetLibrary.fromManifest(manifest);
			if (library == null)
			{
				promise.error("Cannot open library \"" + id + "\"");
			}
			else
			{
				@:privateAccess
				LimeAssets.libraries.set(id, library);

				library.onChange.add(LimeAssets.onChange.dispatch);
				promise.completeWith(Future.withValue(library));
			}
		}).onError(function(_)
		{
				promise.error("There is no asset library with an ID of \"" + id + "\"");
		});

		return promise.future;
	}
}

class MultiCallback
{
	public var callback:Void->Void;
	public var logId:String = null;
	public var length(default, null) = 0;
	public var numRemaining(default, null) = 0;

	private var unfired:Map<String, Void->Void> = new Map();
	private var fired:Array<String> = new Array();

	public function new(callback:Void->Void, logId:String = null)
	{
		this.callback = callback;
		this.logId = logId;
	}

	public function add(id = "untitled")
	{
		id = '$length:$id';

		length++;
		numRemaining++;

		var func:Void->Void = null;
		func = function()
		{
			if (unfired.exists(id))
			{
				unfired.remove(id);
				fired.push(id);

				numRemaining--;
				if (logId != null)
					log('fired $id, $numRemaining remaining');

				if (numRemaining == 0)
				{
					if (logId != null)
						log('all callbacks fired');
					callback();
				}
			}
			else
				log('already fired $id');
		}
		unfired[id] = func;
		return func;
	}

	private inline function log(msg):Void
	{
		if (logId != null)
			trace('$logId: $msg');
	}

	public function getFired()
		return fired.copy();

	public function getUnfired()
		return [for (id in unfired.keys()) id];
}
