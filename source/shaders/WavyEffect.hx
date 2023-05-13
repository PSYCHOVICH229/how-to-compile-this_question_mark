package shaders;

import flixel.system.FlxAssets.FlxShader;
import shaders.Shaders.Effect;

class WavyEffect extends Effect
{
	public var shader(default, null):WavyShader = new WavyShader();
	public var amplitude(default, set):Float = 8;

	public function new():Void
	{
		shader.uAmplitude.value = [amplitude];
		shader.uTime.value = [0];
	}

	public function update(elapsed:Float)
		shader.uTime.value[0] += elapsed;

	private function set_amplitude(value:Float):Float
	{
		shader.uAmplitude.value = [value];
		return value;
	}
}

class WavyShader extends FlxShader
{
	@:glFragmentSource('
	#pragma header

	uniform float uAmplitude;
	uniform float uTime;

	const float frequency = 8.;
	void main()
	{
		vec2 uv = openfl_TextureCoordv;
		vec2 pulse = sin(uTime - frequency * uv);

		float dist = 2. * length(uv.y - .5);

		vec2 newCoord = uv + uAmplitude * vec2(0., pulse.x); // y-axis only;
		vec2 interpCoord = mix(newCoord, uv, dist);

		gl_FragColor = texture2D(bitmap, interpCoord);
	}
	')
	public function new()
	{
		super();
	}
}
