shader_type canvas_item;
// Varredura do scanner: linhas finas, leve tom holográfico e um feixe que desce.

uniform vec4 tint : source_color = vec4(0.5, 0.9, 1.0, 1.0);
uniform float beam = -1.0;       // posição do feixe (0..1); negativo = sem feixe
uniform float intensity = 1.0;   // 0..1, reduzido no modo "reduzir movimento"

void fragment() {
	float lines = 0.5 + 0.5 * sin(UV.y * 900.0 + TIME * 6.0 * intensity);
	float glow = beam < 0.0 ? 0.0 : smoothstep(0.08, 0.0, abs(UV.y - beam));
	float vignette = smoothstep(0.9, 0.2, distance(UV, vec2(0.5)));
	float a = (0.05 + 0.07 * lines) * intensity + glow * 0.55 + (1.0 - vignette) * 0.12;
	COLOR = vec4(tint.rgb, a);
}
