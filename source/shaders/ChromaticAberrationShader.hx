package shaders;

import shaders.Shaders.Effect;
import flixel.system.FlxAssets.FlxShader;

class ChromaticAberrationEffect extends Effect
{
	public var shader(default, null):ChromaticAberrationShader = new ChromaticAberrationShader();
	public var strength(default, set):Float = 0;

	public function new():Void
		shader.uStrength.value = [strength];

	private function set_strength(v:Float):Float
	{
		strength = v;
		shader.uStrength.value = [strength];

		return v;
	}
}

class ChromaticAberrationShader extends FlxShader
{
	@:glFragmentSource('
	#pragma header

	uniform float uStrength;
	void main()
	{
		vec2 uv = openfl_TextureCoordv;
		vec2 distFromCenter = uv - .5;
		// stronger aberration near the edges by raising to power 3
		vec2 aberrated = uStrength * pow(distFromCenter, vec2(3., 3.));

		vec4 col = texture2D(bitmap, uv);

		vec4 red = texture2D(bitmap, uv - aberrated);
		vec4 blue = texture2D(bitmap, uv + aberrated);

		gl_FragColor = vec4(
			red.r,
			col.g,
			blue.b,
			(red.a + col.a + blue.a) / 3.
		);
	}
	')
	public function new()
	{
		super();
	}
}
