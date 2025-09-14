#version 300 es

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;

// These are the interpolated values out of the rasterizer
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

// This is a random function, taken from the same source
// as the noise function. Doesn't need much explanation.
// Changed it for 3D
float random (in vec3 _st) {
    return fract(sin(dot(_st.xyz,
                         vec3(12.9898,78.233,53.026)))*
        43758.5453123);
}

// This noise function is featured
// in the book of shaders section on Fractal Brownian Motion,
// but from shadertoy (https://www.shadertoy.com/view/4dS3Wd)
// I am going to add explanations for future use/tweaking, and
// modify this for 3D noise
float noise (in vec3 _st) {

    // Creating grid from points (similar to voronoi setup)
    vec3 i = floor(_st);
    // also getting fractional component for interpolation
    vec3 fc = fract(_st);

    // Four corners in 2D of a tile
    // (This is a setup for 2D linear interpolation,
    // as discussed on 9/8/2025 in class by Rui)

    // Eight corners in 3D of a cube
    // (This is a setup for 3D linear interpolation,
    // as discussed on 9/8/2025 in class by Rui)

    float a = random(i);
    float b = random(i + vec3(1.0, 0.0, 0.0));
    float c = random(i + vec3(1.0, 1.0, 0.0));
    float d = random(i + vec3(0.0, 1.0, 0.0));
    float e = random(i + vec3(1.0, 1.0, 1.0));
    float f = random(i + vec3(1.0, 0.0, 1.0));
    float g = random(i + vec3(0.0, 1.0, 1.0));
    float h = random(i + vec3(0.0, 0.0, 1.0));

    // These are interpolation terms for smoothing
    // (also discussed 9/8/2025 in class)
    vec3 u = fc * fc * (3.0 - 2.0 * fc);

    // 3D interpolation using the smoothed factor from before.
    // This can probably be vastly simplified similar to the 2D
    // version of the function

    return mix(
        mix(
            mix(a, b, u.x),     // segment 1
            mix(d, c, u.x),     // segment 2
            u.y
        ),                      // plane 1 (bottom)
        mix(
            mix(h, f, u.x),     // segment 3
            mix(g, e, u.x),     // segment 4
            u.y
        ),                      // plane 2
        u.z
    );
}

#define NUM_OCTAVES 5

// This is also from book of shaders,
// and is the FBM implementation.
// I changed it so that it works in three
// dimensions, but the 2D one is here: https://thebookofshaders.com/13/
float fbm ( in vec3 _st) {
    float v = 0.0;                      // final output
    float a = 0.5;                      // amplitude of wave
    vec3 shift = vec3(100.0);           // offset for wave

    // This matrix is used so we don't notice 
    // the self-similarity of FBM too much
    // Rotate to reduce axial bias
    mat3 rot = mat3(
        1., 0., 0.,
        0., cos(0.5), sin(0.5),
        0., -sin(0.5), cos(0.50)
    );

    // This is the main part of FBM.
    // We layer the Perlin noise from earlier
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(_st);

        // used to mix up noise and prevent easily distinguishable self-similarity
        // the "2.0" is the lacunarity, or the factor by which frequency is multiplied each octave
        _st = rot * _st * 2.0 + shift; 

        // Gain (factor by which amplitude is multiplied each octave)
        a *= 0.5;
    }
    return v;
}

void main()
{
    // My setup is going to be similar to the domain warping example from
    // book of shaders (but 3D)

    // distortion variable to plug into next fbm
    vec3 q = vec3(0.);
    q.x = fbm(fs_Pos.xyz + 0.3 * u_Time);
    q.y = fbm(fs_Pos.xyz + vec3(1.0));
    q.z = fbm(fs_Pos.xyz + 0.7 * u_Time);

    // coordinate distortion
    vec3 r = vec3(0.);
    r.x = fbm(fs_Pos.xyz + q + vec3(4.28, 7.41, 5.23) + 0.2 * u_Time);
    r.y = fbm(fs_Pos.xyz + q + vec3(9.35, 1.46, 8.35) + 0.12 * u_Time);
    r.z = fbm(fs_Pos.xyz + q + vec3(-3.0, 4.32, 4.91) + 0.4 * u_Time);

    // final color slider value
    float f = fbm(fs_Pos.xyz + r);

    // determine color using predefined values
    // (this section is the same as book of shaders, but with a new color palette)
    vec3 color = vec3(0.);

    // first two colors
    color = mix(vec3(u_Color.x * (229. / 255.), u_Color.y * (1.0), u_Color.z * (222. / 255.)),
                vec3(u_Color.x * (149. / 255.), u_Color.y * (144. / 255.), u_Color.z * (1.)),
                clamp((f*f)*4.0,0.0,1.0));  // smoothed using interpolation value

    // color #3
    color = mix(color,
                vec3(u_Color.x * (255. / 255.), u_Color.y * (2. / 255.), u_Color.z * (12. / 255.)),
                clamp(length(q),0.0,1.0));  // original distortion value is clamped to create solid portions

    // color #4
    color = mix(color,
                vec3(u_Color.x * (135. / 255.), u_Color.y * (0.), u_Color.z * (88. / 255.)),
                clamp(length(r.x),0.0,1.0));  // abs r.x for more solid sections

    // smoothing function used by book of shaders
    out_Col = vec4((f*f*f+.6*f*f+.5*f)*color,1.);
}
