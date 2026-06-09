shader_type canvas_item;

uniform vec4 source_body : source_color;
uniform vec4 source_shade : source_color;
uniform vec4 source_belly : source_color;
uniform vec4 source_nose : source_color;
uniform vec4 source_shadow : source_color;
uniform vec4 source_eye : source_color;

uniform vec4 target_body : source_color;
uniform vec4 target_shade : source_color;
uniform vec4 target_belly : source_color;
uniform vec4 target_nose : source_color;
uniform vec4 target_shadow : source_color;
uniform vec4 target_eye : source_color;

void fragment()
{
	vec4 color = texture(TEXTURE, UV);

	if (distance(color.rgb, source_body.rgb) < 0.01)
		color.rgb = target_body.rgb;

	else if (distance(color.rgb, source_shade.rgb) < 0.01)
		color.rgb = target_shade.rgb;

	else if (distance(color.rgb, source_belly.rgb) < 0.01)
		color.rgb = target_belly.rgb;

	else if (distance(color.rgb, source_nose.rgb) < 0.01)
		color.rgb = target_nose.rgb;

	else if (distance(color.rgb, source_shadow.rgb) < 0.01)
		color.rgb = target_shadow.rgb;

	else if (distance(color.rgb, source_eye.rgb) < 0.01)
		color.rgb = target_eye.rgb;

	COLOR = color;
}