shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float glow_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	COLOR *= tint_color;
	if (glow_strength > 0.0) {
		float pulse = (sin(TIME * 4.0) * 0.5 + 0.5) * glow_strength;
		COLOR.rgb += pulse;
	}
}
