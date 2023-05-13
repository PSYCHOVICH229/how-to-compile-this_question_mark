package shaders;

import shaders.Shaders.Effect;
import flixel.system.FlxAssets.FlxShader;

class CRTDistortionEffect extends Effect
{
	public var shader(default, null):CRTDistortionShader = new CRTDistortionShader();
	public var distortionFactor(default, set):Float = 0;

	public function new():Void
		shader.uDistortionFactor.value = [distortionFactor];

	private function set_distortionFactor(v:Float):Float
	{
		distortionFactor = v;
		shader.uDistortionFactor.value = [distortionFactor];
		return v;
	}
}

class CRTDistortionShader extends FlxShader
{
	@:glFragmentSource('
	#pragma header
	uniform float uDistortionFactor;

	void main()
	{
		// Basic uv coords
		vec2 uv = openfl_TextureCoordv;

		// Calculate CRT TV distortion effect
		vec2 dist = .5 - uv;
		vec2 new;

		new.x = (uv.x - dist.y * dist.y * dist.x * uDistortionFactor / (openfl_TextureSize.x / openfl_TextureSize.y));
		new.y = (uv.y - dist.x * dist.x * dist.y * uDistortionFactor);
		// Output to screen
		gl_FragColor = ((new.x >= 0.0) && (new.x <= 1.0)) && ((new.y >= 0.0) && (new.y <= 1.0)) ? texture2D(bitmap, new) : vec4(vec3(0.0), 1.0);
	}
	')
	public function new()
	{
		super();
	}
}
