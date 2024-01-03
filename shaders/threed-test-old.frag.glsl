#version 450

// Interpolated values from the vertex shaders
in vec3 fragmentColor;
in vec2 vUV;

// Values that stay constant for the whole mesh.
uniform sampler2D myTextureSampler;

out vec4 fragColor;

void main() {
	// Output color = color of the texture at the specified UV
	// fragColor = texture(myTextureSampler, vUV);

    // Output color = mix of the texture and the fragColor
    fragColor = mix(texture(myTextureSampler, vUV), vec4(fragmentColor, 0.5), 0.5);
}
