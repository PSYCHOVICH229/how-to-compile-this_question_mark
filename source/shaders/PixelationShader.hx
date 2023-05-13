package shaders;

import shaders.Shaders.Effect;
import flixel.system.FlxAssets.FlxShader;

class PixelationEffect extends Effect
{
	public var shader(default, null):PixelationShader = new PixelationShader();
	public var size(default, set):Float = 1;

	public function new():Void
		shader.uPixelSize.value = [size];

	private function set_size(v:Float):Float
	{
		size = v;
		shader.uPixelSize.value = [size];

		return v;
	}
}

class PixelationShader extends FlxShader
{
	@:glFragmentSource('
	#pragma header

	uniform float uPixelSize;
	void main()
	{
		// Normalized pixel coordinates (from 0 to 1)
		vec2 uv = openfl_TextureCoordv;

		vec2 cellSize = (1. / openfl_TextureSize.xy) * uPixelSize;
		vec2 uvSize = uv / cellSize;
		// Output to screen
		gl_FragColor = texture2D(bitmap, vec2(cellSize.x * floor(uvSize.x), cellSize.y * floor(uvSize.y)));
	}
	')
	public function new()
	{
		super();
	}
}
