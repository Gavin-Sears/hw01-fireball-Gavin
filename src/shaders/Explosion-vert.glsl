#version 300 es


uniform mat4 u_Model;

uniform mat4 u_ModelInvTr;

uniform mat4 u_ViewProj;

uniform float u_Time;       // time since start (seconds)

uniform float u_Energy;

uniform float u_Life;

uniform float u_Vitality;

uniform vec4 u_WorldRay;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec4 fs_Nor;
out vec4 fs_Col;
out vec4 fs_Pos;

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

    float a = random(i);
    float b = random(i + vec3(1.0, 0.0, 0.0));
    float c = random(i + vec3(1.0, 1.0, 0.0));
    float d = random(i + vec3(0.0, 1.0, 0.0));
    float e = random(i + vec3(1.0, 1.0, 1.0));
    float f = random(i + vec3(1.0, 0.0, 1.0));
    float g = random(i + vec3(0.0, 1.0, 1.0));
    float h = random(i + vec3(0.0, 0.0, 1.0));

    // These are interpolation terms for smoothing
    // ( discussed 9/8/2025 in class)
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

    mat3 rot = mat3(
        1., 0., 0.,
        0., cos(0.5), sin(0.5),
        0., -sin(0.5), cos(0.50)
    );

    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(_st);

        // "2.0" is the lacunarity, or the factor by which frequency is multiplied each octave
        _st = rot * _st * 2.0 + shift; 

        // Gain (factor by which amplitude is multiplied each octave)
        a *= 0.5;
    }
    return v;
}

float sinZeroToOne(in float theta)
{
    return (sin(theta) + 1.0) / 2.0;
}


// cosine based palette, 4 vec3 params
// taken from Inigo Quilez: https://iquilezles.org/articles/palettes/
vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.283185*(c*t+d) );
}

void main()
{
    fs_Pos = vs_Pos;

    float vitalitime = u_Time * u_Vitality;

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);

    // Start of fireball displacement
    // fractal brownian motion
    float d = fbm(vs_Pos.xyz * vec3(3.0, -5.0, 3.0) + vitalitime * 2.0);
    
    // gets more intense the higher we go
    float HeightTerm = (vs_Pos.y + 1.0) * 0.35 * max(sinZeroToOne((vs_Pos.y * 10.0) - (vitalitime * 4.0)), 0.94);

    // term that controls surface noise
    float noiseTerm = (d * 0.4) + 1.0;
    noiseTerm *= HeightTerm;

    // sending color corresponding to displacement,
    // mixes between dark bluish magenta, red, and yellow
    fs_Col = vec4(
        palette(
            pow(HeightTerm + (d * 0.4),1.5) / 2.0 + (u_Energy * 0.75) + 0.65,
            vec3(0.5, 0.5, 0.5),
            vec3(0.5, 0.5, 0.5),
            vec3(1.0, 1.0, 1.0),
            vec3(0.0, 0.33, 0.67)
        ), 
        1.0
    );
    
    float pulse = (sin(pow(HeightTerm, 2.0) * u_Vitality * 10.0 - vitalitime * 5.0) * 0.7 * pow(HeightTerm, 2.0) + 1.0);
    float flicker = (sin(pow(HeightTerm, 5.0) * u_Vitality * 50.0 - vitalitime * 17.0) * 0.1 * pow(HeightTerm, 2.0) + 1.0);

    // applying displacement
    vec4 newPos = vec4(
        vs_Pos.x * ((noiseTerm * 0.9) + 1.0) * 0.9 * pulse * flicker,
        vs_Pos.y + (pow(noiseTerm, 4.0) * 7.0) * u_Life, 
        vs_Pos.z * ((noiseTerm * 0.9) + 1.0) * 0.9 * pulse * flicker + sin(vitalitime * 1.5) * 0.3,
        1.0
    );

    vec4 modelposition = u_Model * newPos;
    gl_Position = u_ViewProj * modelposition + u_WorldRay;
}
