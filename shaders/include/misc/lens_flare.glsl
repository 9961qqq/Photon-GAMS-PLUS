/*
Catman's lens flare from Seus Forum
https://www.sonicether.com/forum/viewtopic.php?f=4&t=175 (Original site, no longer available)
https://www.neocodex.us/forum/topic/126112-guide-add-lens-flare-to-seus-shader-pack/
*/

flat in vec3 upVec, sunVec;

float SdotU = dot(sunVec, upVec);

//Higher precision bayer pattern
float bayer64(vec2 a) { return 0.25 * bayer32(0.5 * a) + bayer2(a); }

float GetLuminance(vec3 color) {
    return dot(color, luminance_weights_rec709);
}

//--------------------FLARES--------------------//

//Rainbow
vec3 ComputeRainbowFlare(
    vec2 uv, vec2 lightPos, float aspectRatio,
    float scale, float powVal, float fill, float offset,
    float d_scale, float d_pow, float d_fill, float d_offset,
    float sunmask, float multR, float multG, float multB, float tempColor2r
) {
    vec2 flare_scale = vec2(aspectRatio, 1.0) * vec2(scale);
    vec2 flare_pos = flare_scale - lightPos * flare_scale;
    float flare = distance(flare_pos, uv * flare_scale);
    flare = 0.5 - flare;
    flare = clamp(flare * fill, 0.0, 1.0);
    flare = sin(flare * 1.57075);
    flare = pow(flare, 1.1);
    flare *= powVal;

    vec2 flareD_scale = vec2(aspectRatio, 1.0) * vec2(d_scale);
    vec2 flareD_pos = 0.9 * flareD_scale - lightPos * 0.8 * flareD_scale;
    float flareD = distance(flareD_pos, uv * flareD_scale);
    flareD = 0.5 - flareD;
    flareD = clamp(flareD * d_fill, 0.0, 1.0);
    flareD = sin(flareD * 1.57075);
    flareD = pow(flareD, 0.9);
    flareD *= d_pow;

    flare = clamp(flare - flareD, 0.0, 10.0);
    flare *= sunmask;

    return vec3(
        flare * multR * tempColor2r,
        flare * multG * tempColor2r,
        flare * multB * tempColor2r
    );
}

//far blue flare&far small pink flare
vec3 ComputeFarFlare(
    vec2 uv, vec2 lightPos, float aspectRatio,
    float scale, float powVal, float fill, float offset,
    float d_scale, float d_pow, float d_fill, float d_offset,
    float sunmask, float multR, float multG, float multB, float tempColor2r
) {
    vec2 flare_scale = vec2(scale * aspectRatio, scale);
    vec2 flare_pos = vec2(
        ((1.0 - lightPos.x) * (offset + 1.0) - (offset * 0.5)) * flare_scale.x,
        ((1.0 - lightPos.y) * (offset + 1.0) - (offset * 0.5)) * flare_scale.y
    );
    float flare = distance(flare_pos, vec2(uv.s * flare_scale.x, uv.t * flare_scale.y));
    flare = 0.5 - flare;
    flare = clamp(flare * fill, 0.0, 1.0);
    flare = sin(flare * 1.57075);
    flare = pow(flare, 1.1);
    flare *= powVal;

    vec2 flareD_scale = vec2(d_scale * aspectRatio, d_scale);
    vec2 flareD_pos = vec2(
        ((1.0 - lightPos.x) * (d_offset + 1.0) - (d_offset * 0.5)) * flareD_scale.x,
        ((1.0 - lightPos.y) * (d_offset + 1.0) - (d_offset * 0.5)) * flareD_scale.y
    );
    float flareD = distance(flareD_pos, vec2(uv.s * flareD_scale.x, uv.t * flareD_scale.y));
    flareD = 0.5 - flareD;
    flareD = clamp(flareD * d_fill, 0.0, 1.0);
    flareD = sin(flareD * 1.57075);
    flareD = pow(flareD, 0.9);
    flareD *= d_pow;

    flare = clamp(flare - flareD, 0.0, 10.0);
    flare *= sunmask;

    return vec3(
        flare * multR * tempColor2r,
        flare * multG * tempColor2r,
        flare * multB * tempColor2r
    );
}

//close ring flare
vec3 ComputeCloseRingFlare(
    vec2 uv, vec2 lightPos, float aspectRatio,
    float scale, float powVal, float fill, float offset, float powExp, float sinFreq,
    float sunmask, float multR, float multG, float multB, float tempColor2r
) {
    vec2 flare_scale = vec2(scale * aspectRatio, scale);
    vec2 flare_pos = vec2(
        ((1.0 - lightPos.x) * (offset + 1.0) - (offset * 0.5)) * flare_scale.x,
        ((1.0 - lightPos.y) * (offset + 1.0) - (offset * 0.5)) * flare_scale.y
    );
    float flare = distance(flare_pos, vec2(uv.s * flare_scale.x, uv.t * flare_scale.y));
    flare = 0.5 - flare;
    flare = clamp(flare * fill, 0.0, 1.0);
    flare = pow(flare, powExp);
    flare = sin(flare * sinFreq);
    flare *= sunmask;
    flare *= powVal;

    return vec3(
        flare * multR * tempColor2r,
        flare * multG * tempColor2r,
        flare * multB * tempColor2r
    );
}

//Anamorphic lens center
vec3 ComputeStripFlare(
    vec2 uv, vec2 lightPos, float aspectRatio,
    vec2 scale, float powExp, float fill, float flare_pow,
    float multR, float multG, float multB
) {
    vec2 flare_pos = vec2(lightPos.x * aspectRatio * scale.x, lightPos.y * scale.y);
    float flare = distance(flare_pos, vec2(uv.s * aspectRatio * scale.x, uv.t * scale.y));
    flare = 0.5 - flare;
    flare = clamp(flare * fill, 0.0, 1.0);
    flare = pow(flare, powExp);
    flare *= flare_pow;
    return vec3(
        flare * multR,
        flare * multG,
        flare * multB
    );
}

//X cross flare
vec3 ComputeXCrossFlare(
    vec2 uv, vec2 lightPos, float aspectRatio,
    vec2 scale, float powExp, float fill, float flare_pow,
    float multR, float multG, float multB
) {
    vec2 rel_uv = uv - lightPos;

    float angle1 = 3.1415926 / 3.5;
    vec2 rot1 = vec2(
        rel_uv.x * cos(angle1) - rel_uv.y * sin(angle1),
        rel_uv.x * sin(angle1) + rel_uv.y * cos(angle1)
    );

    float angle2 = -3.1415926 / 3.5;
    vec2 rot2 = vec2(
        rel_uv.x * cos(angle2) - rel_uv.y * sin(angle2),
        rel_uv.x * sin(angle2) + rel_uv.y * cos(angle2)
    );

    float flare1 = ComputeStripFlare(
        vec2(rot1.x + lightPos.x, rot1.y + lightPos.y), lightPos, aspectRatio,
        scale, powExp, fill, flare_pow, 1.0, 1.0, 1.0
    ).r;
    float flare2 = ComputeStripFlare(
        vec2(rot2.x + lightPos.x, rot2.y + lightPos.y), lightPos, aspectRatio,
        scale, powExp, fill, flare_pow, 1.0, 1.0, 1.0
    ).r;

    float xFlare = flare1 + flare2;

    return xFlare * vec3(multR, multG, multB);
}

//mid orange sweep
vec3 ComputeMidOrangeSweep(
    vec2 uv, vec2 lightPos, float aspectRatio,
    //main ring parameters
    float scale, float powVal, float fill, float offset, float powExp, float sinFreq,
    //subtract ring parameters
    float d_scale, float d_powVal, float d_fill, float d_offset, float d_powExp, float d_sinFreq,
    float sunmask, float multR, float multG, float multB
) {
    //main
    vec2 flare_scale = vec2(scale * aspectRatio, scale);
    vec2 flare_pos = vec2(
        ((1.0 - lightPos.x) * (offset + 1.0) - (offset * 0.5)) * flare_scale.x,
        ((1.0 - lightPos.y) * (offset + 1.0) - (offset * 0.5)) * flare_scale.y
    );
    float flare = distance(flare_pos, vec2(uv.s * flare_scale.x, uv.t * flare_scale.y));
    flare = 0.5 - flare;
    flare = clamp(flare * fill, 0.0, 1.0);
    flare = sin(flare * sinFreq);
    flare = pow(flare, powExp);
    flare *= powVal;

    //subtract
    vec2 flareD_scale = vec2(d_scale * aspectRatio, d_scale);
    vec2 flareD_pos = vec2(
        ((1.0 - lightPos.x) * (d_offset + 1.0) - (d_offset * 0.5)) * flareD_scale.x,
        ((1.0 - lightPos.y) * (d_offset + 1.0) - (d_offset * 0.5)) * flareD_scale.y
    );
    float flareD = distance(flareD_pos, vec2(uv.s * flareD_scale.x, uv.t * flareD_scale.y));
    flareD = 0.5 - flareD;
    flareD = clamp(flareD * d_fill, 0.0, 1.0);
    flareD = sin(flareD * d_sinFreq);
    flareD = pow(flareD, d_powExp);
    flareD *= d_powVal;

    //main - sub
    flare = clamp(flare - flareD, 0.0, 10.0);
    flare *= sunmask;

    return vec3(
        flare * multR,
        flare * multG,
        flare * multB
    );
}

//Anamorphic lens edge
vec3 ComputeEdgeStrip(
    vec2 uv, vec2 lightPos, float aspectRatio,
    vec2 scale, float powVal, float fill, vec2 offset, float powExp,
    float sunmask, float edgemaskx, float multR, float multG, float multB
) {
    vec2 flare_scale = vec2(scale.x * aspectRatio, scale.y);
    vec2 flare_pos = vec2(
        ((1.0 - lightPos.x) * (offset.x + 1.0) - (offset.x * 0.5)) * flare_scale.x,
        ((offset.y == 0.0 ? 1.0 - lightPos.y : lightPos.y) * (offset.y + 1.0) - (offset.y * 0.5)) * flare_scale.y
    );
    
    float flare = distance(flare_pos, vec2(uv.s * aspectRatio * flare_scale.x, uv.t * flare_scale.y));
    flare = 0.5 - flare;
    flare = clamp(flare * fill, 0.0, 1.0);
    flare *= sunmask;
    flare = pow(flare, powExp);
    flare *= powVal;
    flare *= edgemaskx;
    
    return vec3(
        flare * multR,
        flare * multG,
        flare * multB
    );
}

//SMALL SWEEPS
vec3 ComputeSmallSweep(
    vec2 uv, vec2 lightPos, float aspectRatio,
    //main ring parameters
    float scale, float powVal, float fill, float offset, float powExp,
    //subtract ring parameters
    float d_scale, float d_powVal, float d_fill, float d_offset, float d_powExp,
    float sunmask, float multR, float multG, float multB
) {
    //main
    vec2 flare_scale = vec2(scale * aspectRatio, scale);
    vec2 flare_pos = vec2(
        ((1.0 - lightPos.x) * (offset + 1.0) - (offset * 0.5)) * flare_scale.x,
        ((1.0 - lightPos.y) * (offset + 1.0) - (offset * 0.5)) * flare_scale.y
    );
    float flare = distance(flare_pos, vec2(uv.s * flare_scale.x, uv.t * flare_scale.y));
    flare = 0.5 - flare;
    flare = clamp(flare * fill, 0.0, 1.0);
    flare = sin(flare * 1.57075);
    flare *= sunmask;
    flare = pow(flare, powExp);
    flare *= powVal;

    //subtract
    vec2 flareD_scale = vec2(d_scale * aspectRatio, d_scale);
    vec2 flareD_pos = vec2(
        ((1.0 - lightPos.x) * (d_offset + 1.0) - (d_offset * 0.5)) * flareD_scale.x,
        ((1.0 - lightPos.y) * (d_offset + 1.0) - (d_offset * 0.5)) * flareD_scale.y
    );
    float flareD = distance(flareD_pos, vec2(uv.s * flareD_scale.x, uv.t * flareD_scale.y));
    flareD = 0.5 - flareD;
    flareD = clamp(flareD * d_fill, 0.0, 1.0);
    flareD = sin(flareD * 1.57075);
    flareD *= sunmask;
    flareD = pow(flareD, d_powExp);
    flareD *= d_powVal;

    //main - sub
    flare = clamp(flare - flareD, 0.0, 10.0);

    return vec3(
        flare * multR,
        flare * multG,
        flare * multB
    );
}

//pointy fuzzy glow dots
vec3 ComputeGlowDot(
    vec2 uv, vec2 lightPos, float aspectRatio,
    float scale, float powVal, float fill, float offset, float powExp,
    float sunmask, float multR, float multG, float multB
) {
    vec2 flare_scale = vec2(scale * aspectRatio, scale);
    vec2 flare_pos = vec2(
        ((1.0 - lightPos.x) * (offset + 1.0) - (offset * 0.5)) * flare_scale.x,
        ((1.0 - lightPos.y) * (offset + 1.0) - (offset * 0.5)) * flare_scale.y
    );
    float flare = distance(flare_pos, vec2(uv.s * flare_scale.x, uv.t * flare_scale.y));
    flare = 0.5 - flare;
    flare = clamp(flare * fill, 0.0, 1.0);
    flare = pow(flare, powExp);
    flare *= sunmask;
    flare *= powVal;
    return vec3(
        flare * multR,
        flare * multG,
        flare * multB
    );
}

//--------------------MAIN--------------------//

void LensFlare(inout vec3 scene_color) {
	
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	vec2 lightPos = pos1*0.5+0.5;

vec3 tempColor2 = vec3(0.0);
vec2 checkcoord = lightPos;

vec2 lensFlareCheckOffsets[4] = vec2[4](
    vec2( 1.0,0.0),
    vec2(-1.0,1.0),
    vec2( 0.0,1.0),
    vec2( 1.0,1.0)
);

//Higher precision dither to prevent noise
float dither = bayer64(gl_FragCoord.xy);
float depthVisibility = 1.0;
float cloudVisibility = 1.0;
vec2 resolution = vec2(viewWidth, viewHeight);
vec2 cScale = 20.0 / resolution * SUN_ANGULAR_RADIUS;
    for (int i = 0; i < 4; i++) {
        vec2 cOffset = (lensFlareCheckOffsets[i] - dither) * cScale;
        vec2 checkCoord1 = lightPos.xy + cOffset;
        vec2 checkCoord2 = lightPos.xy - cOffset;

        float zSample1 = texture2D(depthtex0, checkCoord1).r;
        float zSample2 = texture2D(depthtex0, checkCoord2).r;
        #ifdef CLOUDS_CUMULUS || CLOUDS_CUMULUS_CONGESTUS || CLOUDS_CUMULONIMBUS || CLOUDS_ALTOCUMULUS || CLOUDS_CIRRUS || CLOUDS_NOCTILUCENT
            float cloudLinearDepth1 = texture2D(colortex11, checkCoord1).r;
            float cloudLinearDepth2 = texture2D(colortex11, checkCoord2).r;
            zSample1 = max(zSample1, cloudLinearDepth1);
            zSample2 = max(zSample2, cloudLinearDepth2);
        if (zSample1 > 1.0)
            cloudVisibility -= 0.125;
        if (zSample2 > 1.0)
            cloudVisibility -= 0.125;
        #endif

        if (zSample1 < 1.0)
            depthVisibility -= 0.125;
        if (zSample2 < 1.0)
            depthVisibility -= 0.125;
    }

//Detect if sun is on edge of screen
float edgeMaskx = 1.0 - clamp(distance(lightPos.x, 0.5f)*9.0f - 4.5f, 0.0f, 1.0f);
float edgeMasky = 1.0 - clamp(distance(lightPos.y, 0.5f)*9.0f - 4.5f, 0.0f, 1.0f);
float edgeMask = edgeMaskx * edgeMasky;

float sunmask = depthVisibility * clamp(cloudVisibility, LF_CLOUD_VISIBILITY, 1.0) * edgeMask * float(isEyeInWater <= 0.1 && blindness == 0.0) * (1.0 - rainStrength);

if (sunmask > 0.02)
{
//Detect if sun is on edge of screen
float edgemaskx = clamp(distance(lightPos.x, 0.5f)*9.0f - 3.0f, 0.0f, 1.0f)*2.0;

//Darken Colors if the sun is visible
float centermask = 1.0 - clamp(distance(lightPos.xy, vec2(0.5, 0.5))*2.0, 0.0, 1.0);
      centermask = pow(centermask, 1.0);
      centermask *= sunmask;

float perceivedLuminance = GetLuminance(scene_color);
float inverseResponse = 1.0 - smoothstep(0.1, 0.9, perceivedLuminance);
      inverseResponse = pow(inverseResponse, 0.5) * 2.0;

vec3 lenslc = vec3(1);

//Prevent sun/moon flare visible below the horizon at night/day
float moonVisibility = pow(clamp(SdotU+0.15,0.0,0.15)/0.15,4.0);
float sunVisibility = 1.0 - moonVisibility;

#if LENS_FLARE_MODE == 2
      if (sunVec.z > 0.0) {
          lenslc = GetLuminance(lenslc) * vec3(0.1, 0.2, 0.3);
          lenslc *= sunVisibility;
      } else {
          lenslc = normalize(sqrt(scene_color))*inverseResponse;
          lenslc *= moonVisibility;
      }
#else
      if (sunVec.z > 0.0) {
          lenslc = vec3(0);
      } else {
          lenslc = normalize(sqrt(scene_color))*inverseResponse;
          lenslc *= moonVisibility;
      }
#endif

#ifdef WORLD_END
      lenslc = GetLuminance(lenslc) * vec3(0.4, 0.2, 1.0);
#endif

lenslc.r *= (1.0 - centermask);
lenslc.g *= (1.0 - centermask);
lenslc.b *= (1.0 - centermask);
lenslc *= LENS_FLARE_INTENSITY * 0.5;

//Adjust global flare settings
float flaremultR = 0.8*lenslc.r*LF_COLOR_R;
float flaremultG = 1.0*lenslc.g*LF_COLOR_G;
float flaremultB = 1.5*lenslc.b*LF_COLOR_B;

//float flarescale = mix(1.0, 1.0 * 0.1, (SUN_ANGULAR_RADIUS - 0.1) / (10.0 - 0.1));
float flarescale = 1.0;
const float flarescaleconst = 1.0;

/*
//Flare gets bigger at center of screen
flarescale *= (1.0 - centermask);
*/

//RAINBOW

//Lens

float flarescale2 = 1.1;
float flarescale3 = 2.0;
float flarescale4 = 1.5;

vec3 tempColor = vec3(0.0);
vec3 tempColor3 = vec3(0.0);
vec3 tempColor4 = vec3(0.0);

float PI = 3.141592;

float random = fract(sin(dot(sunPosition.xy, vec2(12.9898, 78.233)))* 43758.5453);
      random - 0.25;

if (random < 0.25){
    random = 0.25;
}

float c = 0.0;
float dx = uv.x - 0.5;
float dy = uv.y - 0.5;
      c = (atan(dy, dx) / PI + 1.0) * 1.0;
float t = (sin(random) + 1.0) * 1.0;
      c = tan(c * 720.0);
	  
vec4 tempColor2 = vec4(c, c, c, 1.0 );

if (tempColor2.r < 0.7){
    tempColor2.r = 0.7;
}
else if (tempColor2.r > 0.9){
         tempColor2.r = 0.9;
}
sin(tempColor2);

//(1-x)*(0.8)+0.1 = 0.8-0.8x-0.1 = 0.9-0.8x

#ifdef LF_BIG_RAINBOW
//Red
    tempColor += ComputeRainbowFlare(
        uv, lightPos, aspectRatio,
        0.9 * flarescale2, 4.25, 10.0, 0.0,
        0.58 * flarescale2, 8.0, 1.4, -0.2,
        sunmask, 0.55 * flaremultR, 0.0, 0.0, tempColor2.r
    );

//Orange
    tempColor += ComputeRainbowFlare(
        uv, lightPos, aspectRatio,
        0.86 * flarescale2, 4.25, 10.0, 0.0,
        0.5446 * flarescale2, 8.0, 1.4, -0.2,
        sunmask, 0.55 * flaremultR, 0.55 * flaremultR, 0.0, tempColor2.r
    );

//Green
    tempColor += ComputeRainbowFlare(
        uv, lightPos, aspectRatio,
        0.82 * flarescale2, 4.25, 10.0, -0.0,
        0.5193 * flarescale2, 8.0, 1.4, -0.2,
        sunmask, 0.0, 0.55 * flaremultG, 0.0, tempColor2.r
    );

//Blue
    tempColor += ComputeRainbowFlare(
        uv, lightPos, aspectRatio,
        0.78 * flarescale2, 4.25, 10.0, 0.0,
        0.4863 * flarescale2, 8.0, 1.4, -0.2,
        sunmask, 0.0, 0.0, 0.55 * flaremultB, tempColor2.r
    );
#endif

#ifdef LF_RAINBOW
//RAINBOW2
//Red2
tempColor3 += ComputeRainbowFlare(
    uv, lightPos, aspectRatio,
    0.9 * flarescale3, 4.25, 10.0, -0.0,
    0.58 * flarescale3, 8.0, 1.4, -0.2,
    sunmask, 10.0 * flaremultR, 0.0, 0.0, tempColor2.r / 16.0
);
//Orange2
tempColor3 += ComputeRainbowFlare(
    uv, lightPos, aspectRatio,
    0.86 * flarescale3, 4.25, 10.0, -0.0,
    0.5446 * flarescale3, 8.0, 1.4, -0.2,
    sunmask, 10.0 * flaremultR, 5.0 * flaremultG, 0.0, tempColor2.r / 16.0
);
//Green2
tempColor3 += ComputeRainbowFlare(
    uv, lightPos, aspectRatio,
    0.82 * flarescale3, 4.25, 10.0, -0.0,
    0.5193 * flarescale3, 8.0, 1.4, -0.2,
    sunmask, 0.0, 1.0 * flaremultG, 0.0, tempColor2.r / 2.0
);
//Blue2
tempColor3 += ComputeRainbowFlare(
    uv, lightPos, aspectRatio,
    0.78 * flarescale3, 4.25, 10.0, -0.0,
    0.494 * flarescale3, 8.0, 1.4, -0.2,
    sunmask, 0.0, 0.0, 1.0 * flaremultB, tempColor2.r / 2.0
);
#endif

scene_color += (tempColor3 / 4.0);
scene_color += (tempColor4 / 1.0);
scene_color += (tempColor * 1.0);


//Far blue flare MAIN
scene_color += ComputeFarFlare(
    uv, lightPos, aspectRatio,
    2.0 * flarescale, 0.7, 10.0, -0.5,
    1.4 * flarescale, 1.0, 2.0, -0.65,
    sunmask, 0.5 * flaremultR, 0.3 * flaremultG, 0.0 * flaremultB, 1.0
);

//Far blue flare MAIN 2
scene_color += ComputeFarFlare(
    uv, lightPos, aspectRatio,
    3.2 * flarescale, 1.4, 10.0, 0.0,
    2.1 * flarescale, 2.7, 1.4, -0.05,
    sunmask, 0.5 * flaremultR, 0.3 * flaremultG, 0.0 * flaremultB, 1.0
);

//far small pink flare
scene_color += ComputeFarFlare(
    uv, lightPos, aspectRatio,
    4.5 * flarescale, 0.3, 3.0, -0.1,
    0.0, 0.0, 1.0, 0.0,
    sunmask, 0.6 * flaremultR, 0.0 * flaremultG, 0.8 * flaremultB, 1.0
);

//far small pink flare2
scene_color += ComputeFarFlare(
    uv, lightPos, aspectRatio,
    7.5 * flarescale, 0.4, 2.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    sunmask, 0.4 * flaremultR, 0.0 * flaremultG, 0.8 * flaremultB, 1.0
);

//far small pink flare3
scene_color += ComputeFarFlare(
    uv, lightPos, aspectRatio,
    37.5 * flarescale, 2.0, 2.0, -0.3,
    0.0, 0.0, 1.0, 0.0,
    sunmask, 0.6 * flaremultR, 0.3 * flaremultG, 0.1 * flaremultB, 1.0
);

//far small pink flare4
scene_color += ComputeFarFlare(
    uv, lightPos, aspectRatio,
    67.5 * flarescale, 1.0, 2.0, -0.35,
    0.0, 0.0, 1.0, 0.0,
    sunmask, 0.2 * flaremultR, 0.2 * flaremultG, 0.2 * flaremultB, 1.0
);

//far small pink flare5
scene_color += ComputeFarFlare(
    uv, lightPos, aspectRatio,
    60.5 * flarescale, 1.0, 3.0, -0.3393,
    0.0, 0.0, 1.0, 0.0,
    sunmask, 0.2 * flaremultR, 0.2 * flaremultG, 0.0 * flaremultB, 1.0
);

//close ring flare green
scene_color += ComputeCloseRingFlare(
    uv, lightPos, aspectRatio,
    1.1 * flarescale, 0.2, 5.0, -1.9, 1.6, 3.1415,
    sunmask, 1.0 * flaremultR, 0.4 * flaremultG, 0.0 * flaremultB, tempColor2.r
);

//close ring flare blue
scene_color += ComputeCloseRingFlare(
    uv, lightPos, aspectRatio,
    0.9 * flarescale, 0.3, 5.0, -1.9, 1.8, 3.1415,
    sunmask, 0.5 * flaremultR, 0.3 * flaremultG, 0.0 * flaremultB, tempColor2.r
);

#ifdef LF_CENTER_STRIP
//Anamorphic lens center
// Edge orange glow
if (sunVec.z > 0.0) {
} else {
    scene_color += ComputeStripFlare(
        uv, lightPos, aspectRatio,
        vec2(0.2 * flarescale, 5.0 * flarescale), 1.4, 2.0, 1.0,
        1.0 * flaremultR * sunmask, 0.6 * flaremultG * sunmask, 0.0 * flaremultB * sunmask
    );
    #ifdef WORLD_END
    scene_color += ComputeStripFlare(
        uv, lightPos, aspectRatio,
        vec2(0.2 * flarescale, 5.0 * flarescale), 1.4, 2.0, 1.0,
        0.4 * flaremultR * sunmask, 0.2 * flaremultG * sunmask, 0.3 * flaremultB * sunmask
    );
    #endif
}

//Red strip
vec3 strip1 = ComputeStripFlare(
    uv, lightPos, aspectRatio,
    vec2(0.5 * flarescale, 15.0 * flarescale), 1.4, 2.0, 0.25,
    1.0, 1.0, 1.0
);

    #ifdef WORLD_END
    scene_color.r += strip1.r * 0.4 * sunVisibility * sunmask;
    scene_color.g += strip1.g * 0.2 * sunVisibility * sunmask;
    scene_color.b += strip1.b * 0.3 * sunVisibility * sunmask;
    #endif

#if LENS_FLARE_MODE == 2
    if (sunVec.z > 0.0) {
        scene_color.r += strip1.r * 0.25 * sunVisibility * sunmask;
        scene_color.g += strip1.g * 0.4 * sunVisibility * sunmask;
        scene_color.b += strip1.b * 0.5 * sunVisibility * sunmask;
    } else {
        scene_color.r += strip1.r * 0.14 * moonVisibility * sunmask;
        scene_color.g += strip1.g * 0.13 * moonVisibility * sunmask;
        scene_color.b += strip1.b * 0.0 * moonVisibility * sunmask;
}
#else
    if (sunVec.z > 0.0) {
} else {
        scene_color.r += strip1.r * 0.14 * moonVisibility * sunmask;
        scene_color.g += strip1.g * 0.13 * moonVisibility * sunmask;
        scene_color.b += strip1.b * 0.0 * moonVisibility * sunmask;
}
#endif

//Blue strip
scene_color.r += strip1.r * 0.1 * flaremultR * edgeMask;
scene_color.g += strip1.g * 0.2 * flaremultG * edgeMask;
scene_color.b += strip1.b * 0.45 * flaremultB * edgeMask;
#endif

#ifdef LF_XCROSS_STRIP
//X cross flare
vec3 Xcross = ComputeXCrossFlare(
    uv, lightPos, aspectRatio,
    vec2(1.2 * flarescale, 25.0 * flarescale),
    2.4, // powExp
    2.0, // fill
    0.25, // flare_pow
    1.0, 1.0, 1.0
);

#ifdef WORLD_END
scene_color.r += Xcross.r * 0.4 * sunmask;
scene_color.g += Xcross.g * 0.2 * sunmask;
scene_color.b += Xcross.b * 0.3 * sunmask;
#endif

#if LENS_FLARE_MODE == 2
    if (sunVec.z > 0.0) {
        scene_color.r += Xcross.r * 0.25 * sunVisibility * sunmask;
        scene_color.g += Xcross.g * 0.4 * sunVisibility * sunmask;
        scene_color.b += Xcross.b * 0.5 * sunVisibility * sunmask;
    } else {
        scene_color.r += Xcross.r * 0.14 * moonVisibility * sunmask;
        scene_color.g += Xcross.g * 0.13 * moonVisibility * sunmask;
        scene_color.b += Xcross.b * 0.0 * moonVisibility * sunmask;
}
#else
    if (sunVec.z > 0.0) {
    } else {
        scene_color.r += Xcross.r * 0.14 * moonVisibility * sunmask;
        scene_color.g += Xcross.g * 0.13 * moonVisibility * sunmask;
        scene_color.b += Xcross.b * 0.0 * moonVisibility * sunmask;
}
#endif

//mid orange sweep
scene_color += ComputeMidOrangeSweep(
    uv, lightPos, aspectRatio,
    32.0 * flarescale, 2.5, 1.1, -1.3, 1.1, 1.57075,
    5.1 * flarescale, 1.5, 1.0, -0.77, 0.9, 1.57075,
    sunmask, 0.5 * flaremultR, 0.4 * flaremultG, 0.1 * flaremultB
);

scene_color += ComputeMidOrangeSweep(
    uv, lightPos, aspectRatio,
    35.0 * flarescale, 1.0, 1.1, -1.2, 1.1, 1.57075,
    5.1 * flarescale, 1.5, 1.0, -0.77, 0.9, 1.57075,
    sunmask, 0.6 * flaremultR, 0.4 * flaremultG, 0.1 * flaremultB
);

scene_color += ComputeMidOrangeSweep(
    uv, lightPos, aspectRatio,
    25.0 * flarescale, 4.0, 1.1, -0.9, 1.1, 1.57075,
    5.1 * flarescale, 1.5, 1.0, -0.77, 0.9, 1.57075,
    sunmask, 0.5 * flaremultR, 0.3 * flaremultG, 0.0 * flaremultB
);

//far red glow
vec2 flare7Bscale = vec2(0.2*flarescale, 0.2*flarescale);
float flare7Bpow = 0.1;
float flare7Bfill = 2.0;
float flare7Boffset = 2.9;
vec2 flare7Bpos = vec2(  ((1.0 - lightPos.x)*(flare7Boffset + 1.0) - (flare7Boffset*0.5))  *aspectRatio*flare7Bscale.x,  ((1.0 - lightPos.y)*(flare7Boffset + 1.0) - (flare7Boffset*0.5))  *flare7Bscale.y);

float flare7B = distance(flare7Bpos, vec2(uv.s*aspectRatio*flare7Bscale.x, uv.t*flare7Bscale.y));
      flare7B = 0.5 - flare7B;
      flare7B = clamp(flare7B*flare7Bfill, 0.0, 1.0)  ;
      flare7B = pow(flare7B, 1.9);
      flare7B = sin(flare7B*3.1415*0.5);
      flare7B *= sunmask;
      flare7B *= flare7Bpow;

scene_color.r += flare7B*1.0*flaremultR;
scene_color.g += flare7B*0.0*flaremultG;
scene_color.b += flare7B*0.0*flaremultB;

#ifdef LF_EDGE_STRIP
//Anamorphic lens edge
//Edge blue strip 1
scene_color += ComputeEdgeStrip(
    uv, lightPos, aspectRatio,
    vec2(0.3 * flarescale, 40.5 * flarescale), 0.5, 12.0, vec2(1.0, 1.0), 1.4,
    sunmask, edgemaskx, 0.0 * flaremultR, 0.15 * flaremultG, 0.4 * flaremultB
);

//Edge blue strip 2
scene_color += ComputeEdgeStrip(
    uv, lightPos, aspectRatio,
    vec2(0.2 * flarescale, 5.5 * flarescale), 1.9, 2.0, vec2(1.0, 0.0), 1.4,
    sunmask, edgemaskx, 0.1 * flaremultR, 0.2 * flaremultG, 0.45 * flaremultB
);
#endif

//SMALL SWEEPS
//mid orange sweep
scene_color += ComputeSmallSweep(
    uv, lightPos, aspectRatio,
    6.0 * flarescale, 1.9, 1.1, -0.7, 1.1,
    5.1 * flarescale, 1.5, 1.0, -0.77, 0.9,
    sunmask, 0.5 * flaremultR, 0.3 * flaremultG, 0.0 * flaremultB
);

//mid blue sweep
scene_color += ComputeSmallSweep(
    uv, lightPos, aspectRatio,
    6.0 * flarescale, 1.9, 1.1, -0.6, 1.1,
    5.1 * flarescale, 1.5, 1.0, -0.67, 0.9,
    sunmask, 0.5 * flaremultR, 0.3 * flaremultG, 0.0 * flaremultB
);

#ifdef LF_GLOWDOTS
//Pointy fuzzy glow dots
//RedGlow1
scene_color += ComputeGlowDot(
    uv, lightPos, aspectRatio,
    1.5 * flarescale, 1.1, 2.0, -0.523, 2.9,
    sunmask, 0.5 * flaremultR, 0.1 * flaremultG, 0.0 * flaremultB
);

//PurpleGlow2
scene_color += ComputeGlowDot(
    uv, lightPos, aspectRatio,
    2.5 * flarescale, 0.5, 2.0, -0.323, 2.9,
    sunmask, 0.35 * flaremultR, 0.15 * flaremultG, 0.0 * flaremultB
);

//BlueGlow3
scene_color += ComputeGlowDot(
    uv, lightPos, aspectRatio,
    1.0 * flarescale, 1.5, 2.0, 0.138, 2.9,
    sunmask, 0.5 * flaremultR, 0.3 * flaremultG, 0.0 * flaremultB
);
#endif
   }
}