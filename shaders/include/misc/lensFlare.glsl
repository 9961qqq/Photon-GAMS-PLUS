/*
Catman's lens flare from Seus Forum
https://www.sonicether.com/forum/viewtopic.php?f=4&t=175 (Original site, no longer available)
https://www.neocodex.us/forum/topic/126112-guide-add-lens-flare-to-seus-shader-pack/
*/

uniform vec3 sunPosition;
uniform mat4 gbufferProjection;
uniform float blindness;
uniform float viewWidth;
uniform float rainFactor;
uniform float aspectRatio;
uniform float isEyeInWater;
uniform sampler2D depthtex0;
uniform sampler2D colortex11;

flat in vec3 upVec, sunVec;
in float SdotU;

float GetLuminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void LensFlare(inout vec3 fragment_color) {
	
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	vec2 lightPos = pos1*0.5+0.5;

vec3 tempColor2 = vec3(0.0);
vec2 ntc2 = uv;
vec2 checkcoord = lightPos;

vec2 lensFlareCheckOffsets[4] = vec2[4](
    vec2( 1.0,0.0),
    vec2(-1.0,1.0),
    vec2( 0.0,1.0),
    vec2( 1.0,1.0)
);

float dither = bayer32(gl_FragCoord.xy);
float depthVisibility = 1.0;
float cloudVisibility = 1.0;
vec2 resolution = vec2(viewWidth, viewHeight);
vec2 cScale = 40.0 / resolution;
    for (int i = 0; i < 4; i++) {
        vec2 cOffset = (lensFlareCheckOffsets[i] - dither) * cScale;
        vec2 checkCoord1 = lightPos.xy + cOffset;
        vec2 checkCoord2 = lightPos.xy - cOffset;

        float zSample1 = texture2D(depthtex0, checkCoord1).r;
        float zSample2 = texture2D(depthtex0, checkCoord2).r;
        #ifdef CLOUDS_CUMULUS | CLOUDS_CUMULUS_CONGESTUS | CLOUDS_CUMULONIMBUS | CLOUDS_ALTOCUMULUS | CLOUDS_CIRRUS | CLOUDS_NOCTILUCENT
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

float sunmask = depthVisibility * clamp(cloudVisibility, LF_CLOUD_VISIBILITY, 1.0) * edgeMask * float(isEyeInWater <= 0.1 && blindness == 0.0);
      sunmask *= 1.0 - rainFactor;

if (sunmask > 0.02)
{
//Detect if sun is on edge of screen
float edgemaskx = clamp(distance(lightPos.x, 0.5f)*9.0f - 3.0f, 0.0f, 1.0f)*2.0;

//Darken Colors if the sun is visible
float centermask = 1.0 - clamp(distance(lightPos.xy, vec2(0.5, 0.5))*2.0, 0.0, 1.0);
      centermask = pow(centermask, 1.0);
      centermask *= sunmask;

float perceivedLuminance = GetLuminance(fragment_color);
float inverseResponse = 1.0 - smoothstep(0.1, 0.9, perceivedLuminance);
      inverseResponse = pow(inverseResponse, 0.5) * 2.0;

vec3 lenslc = vec3(1);

//Prevent sun/moon flare visible below the horizon at night/day
float moonVisibility = clamp01((SdotU + 0.1) * 5.0);
float sunVisibility = 1.0 - moonVisibility;

    #if LENS_FLARE_MODE == 2
        if (sunVec.z > 0.0) {
            lenslc = GetLuminance(lenslc) * vec3(0.1, 0.2, 0.3);
            lenslc *= sunVisibility;
        } else
    #endif
    {
        lenslc = normalize(sqrt(fragment_color))*inverseResponse;
        lenslc *= moonVisibility;
    }

lenslc.r *= (1.0 - centermask);
lenslc.g *= (1.0 - centermask);
lenslc.b *= (1.0 - centermask);
lenslc *= LENS_FLARE_INTENSITY;

//Adjust global flare settings
float flaremultR = 0.8*lenslc.r*LF_COLOR_R;
float flaremultG = 1.0*lenslc.g*LF_COLOR_G;
float flaremultB = 1.5*lenslc.b*LF_COLOR_B;

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

vec2 uv = (ntc2.xy);

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
vec2 flare_Red_scale = vec2(aspectRatio,1.0)*vec2(0.9*flarescale2);
const float flare_Red_pow = 4.25;
const float flare_Red_fill = 10.0;
vec2 flare_Red_pos = flare_Red_scale - lightPos*flare_Red_scale;

float flare_Red_ = distance(flare_Red_pos, ntc2*flare_Red_scale);
      flare_Red_ = 0.5 - flare_Red_;
      flare_Red_ = clamp(flare_Red_*flare_Red_fill, 0.0, 1.0)  ;
      flare_Red_ = sin(flare_Red_*1.57075);
      flare_Red_ = pow(flare_Red_, 1.1);
      flare_Red_ *= flare_Red_pow;
//subtract
vec2 flare_RedD_scale = vec2(aspectRatio,1.0)*vec2(0.58*flarescale2);
const float flare_RedD_pow = 8.0;
const float flare_RedD_fill = 1.4;

vec2 flare_RedD_pos = 0.9*flare_RedD_scale - lightPos*0.8*flare_RedD_scale;

float flare_RedD_ = distance(flare_RedD_pos, ntc2*flare_RedD_scale);
      flare_RedD_ = 0.5 - flare_RedD_;
      flare_RedD_ = clamp(flare_RedD_*flare_RedD_fill, 0.0, 1.0)  ;
      flare_RedD_ = sin(flare_RedD_*1.57075);
      flare_RedD_ = pow(flare_RedD_, 0.9);
      flare_RedD_ *= flare_RedD_pow;

flare_Red_ = clamp(flare_Red_ - flare_RedD_, 0.0, 10.0);
flare_Red_ *= sunmask;

tempColor.r += flare_Red_*0.55*flaremultR * tempColor2.r;

//Orange
vec2 flare_Orange_scale = vec2(aspectRatio,1.0)*vec2(0.86*flarescale2);
float flare_Orange_pow = 4.25f;
float flare_Orange_fill = 10.0;
vec2 flare_Orange_pos = flare_Orange_scale - lightPos*flare_Orange_scale;

float flare_Orange_ = distance(flare_Orange_pos, ntc2*flare_Orange_scale);
      flare_Orange_ = 0.5 - flare_Orange_;
      flare_Orange_ = clamp(flare_Orange_*flare_Orange_fill, 0.0, 1.0)  ;
      flare_Orange_ = sin(flare_Orange_*1.57075);
      flare_Orange_ = pow(flare_Orange_, 1.1);
      flare_Orange_ *= flare_Orange_pow;
//subtract
vec2 flare_OrangeD_scale = vec2(aspectRatio,1.0)*vec2(0.5446f*flarescale2);
const float flare_OrangeD_pow = 8.0;
const float flare_OrangeD_fill = 1.4;
vec2 flare_OrangeD_pos = 0.9*flare_OrangeD_scale - lightPos*0.8*flare_OrangeD_scale;

float flare_OrangeD_ = distance(flare_OrangeD_pos, ntc2*flare_OrangeD_scale);
      flare_OrangeD_ = 0.5 - flare_OrangeD_;
      flare_OrangeD_ = clamp(flare_OrangeD_*flare_OrangeD_fill, 0.0, 1.0);
      flare_OrangeD_ = sin(flare_OrangeD_*1.57075);
      flare_OrangeD_ = pow(flare_OrangeD_, 0.9);
      flare_OrangeD_ *= flare_OrangeD_pow;

flare_Orange_ = clamp(flare_Orange_ - flare_OrangeD_, 0.0, 10.0);
flare_Orange_ *= sunmask;

tempColor.rg += flare_Orange_*0.55*flaremultR * tempColor2.r;
							
//Green
vec2 flare_Green_scale = vec2(0.82f*flarescale2, 0.82f*flarescale2);
float flare_Green_pow = 4.25f;
float flare_Green_fill = 10.0;
float flare_Green_offset = -0.0;
vec2 flare_Green_pos = vec2(  ((1.0 - lightPos.x)*(flare_Green_offset + 1.0) - (flare_Green_offset*0.5))  *aspectRatio*flare_Green_scale.x,  ((1.0 - lightPos.y)*(flare_Green_offset + 1.0) - (flare_Green_offset*0.5))  *flare_Green_scale.y);

float flare_Green_ = distance(flare_Green_pos, vec2(ntc2.s*aspectRatio*flare_Green_scale.x, ntc2.t*flare_Green_scale.y));
      flare_Green_ = 0.5 - flare_Green_;
      flare_Green_ = clamp(flare_Green_*flare_Green_fill, 0.0, 1.0)  ;
      flare_Green_ = sin(flare_Green_*1.57075);
      flare_Green_ = pow(flare_Green_, 1.1);
      flare_Green_ *= flare_Green_pow;
//subtract
vec2 flare_GreenD_scale = vec2(0.5193f*flarescale2, 0.5193f*flarescale2);
float flare_GreenD_pow = 8.0;
float flare_GreenD_fill = 1.4;
float flare_GreenD_offset = -0.2;
vec2 flare_GreenD_pos = vec2(  ((1.0 - lightPos.x)*(flare_GreenD_offset + 1.0) - (flare_GreenD_offset*0.5))  *aspectRatio*flare_GreenD_scale.x,  ((1.0 - lightPos.y)*(flare_GreenD_offset + 1.0) - (flare_GreenD_offset*0.5))  *flare_GreenD_scale.y);

float flare_GreenD_ = distance(flare_GreenD_pos, vec2(ntc2.s*aspectRatio*flare_GreenD_scale.x, ntc2.t*flare_GreenD_scale.y));
      flare_GreenD_ = 0.5 - flare_GreenD_;
      flare_GreenD_ = clamp(flare_GreenD_*flare_GreenD_fill, 0.0, 1.0)  ;
      flare_GreenD_ = sin(flare_GreenD_*1.57075);
      flare_GreenD_ = pow(flare_GreenD_, 0.9);
      flare_GreenD_ *= flare_GreenD_pow;

flare_Green_ = clamp(flare_Green_ - flare_GreenD_, 0.0, 10.0);
flare_Green_ *= sunmask;

tempColor.g += flare_Green_*0.55f*flaremultG * tempColor2.r;

//Blue
vec2 flare_Blue_scale = vec2(0.78f*flarescale2, 0.78f*flarescale2);
float flare_Blue_pow = 4.25f;
float flare_Blue_fill = 10.0;
float flare_Blue_offset = -0.0;
vec2 flare_Blue_pos = vec2(  ((1.0 - lightPos.x)*(flare_Blue_offset + 1.0) - (flare_Blue_offset*0.5))  *aspectRatio*flare_Blue_scale.x,  ((1.0 - lightPos.y)*(flare_Blue_offset + 1.0) - (flare_Blue_offset*0.5))  *flare_Blue_scale.y);

float flare_Blue_ = distance(flare_Blue_pos, vec2(ntc2.s*aspectRatio*flare_Blue_scale.x, ntc2.t*flare_Blue_scale.y));
      flare_Blue_ = 0.5 - flare_Blue_;
      flare_Blue_ = clamp(flare_Blue_*flare_Blue_fill, 0.0, 1.0)  ;
      flare_Blue_ = sin(flare_Blue_*1.57075);
      flare_Blue_ = pow(flare_Blue_, 1.1);
      flare_Blue_ *= flare_Blue_pow;
//subtract
vec2 flare_BlueD_scale = vec2(0.494f*flarescale2, 0.494f*flarescale2);
float flare_BlueD_pow = 8.0;
float flare_BlueD_fill = 1.4;
float flare_BlueD_offset = -0.2;
vec2 flare_BlueD_pos = vec2(  ((1.0 - lightPos.x)*(flare_BlueD_offset + 1.0) - (flare_BlueD_offset*0.5))  *aspectRatio*flare_BlueD_scale.x,  ((1.0 - lightPos.y)*(flare_BlueD_offset + 1.0) - (flare_BlueD_offset*0.5))  *flare_BlueD_scale.y);

float flare_BlueD_ = distance(flare_BlueD_pos, vec2(ntc2.s*aspectRatio*flare_BlueD_scale.x, ntc2.t*flare_BlueD_scale.y));
      flare_BlueD_ = 0.5 - flare_BlueD_;
      flare_BlueD_ = clamp(flare_BlueD_*flare_BlueD_fill, 0.0, 1.0)  ;
      flare_BlueD_ = sin(flare_BlueD_*1.57075);
      flare_BlueD_ = pow(flare_BlueD_, 0.9);
      flare_BlueD_ *= flare_BlueD_pow;

flare_Blue_ = clamp(flare_Blue_ - flare_BlueD_, 0.0, 10.0);
flare_Blue_ *= sunmask;

tempColor.r += flare_Blue_*0.0*flaremultR * tempColor2.r;
tempColor.g += flare_Blue_*0.0*flaremultG * tempColor2.r;
tempColor.b += flare_Blue_*0.45f*flaremultB * tempColor2.r;
#endif

#ifdef LF_RAINBOW
//RAINBOW2
//Red2
vec2 flare_Red2_scale = vec2(0.9*flarescale3, 0.9*flarescale3);
float flare_Red2_pow = 4.25f;
float flare_Red2_fill = 10.0;
float flare_Red2_offset = -0.0;
vec2 flare_Red2_pos = vec2(  ((1.0 - lightPos.x)*(flare_Red2_offset + 1.0) - (flare_Red2_offset*0.5))  *aspectRatio*flare_Red2_scale.x,  ((1.0 - lightPos.y)*(flare_Red2_offset + 1.0) - (flare_Red2_offset*0.5))  *flare_Red2_scale.y);

float flare_Red2_ = distance(flare_Red2_pos, vec2(ntc2.s*aspectRatio*flare_Red2_scale.x, ntc2.t*flare_Red2_scale.y));
      flare_Red2_ = 0.5 - flare_Red2_;
      flare_Red2_ = clamp(flare_Red2_*flare_Red2_fill, 0.0, 1.0)  ;
      flare_Red2_ = sin(flare_Red2_*1.57075);
      flare_Red2_ = pow(flare_Red2_, 1.1);
      flare_Red2_ *= flare_Red2_pow;
//subtract
vec2 flare_Red2D_scale = vec2(0.58*flarescale3, 0.58*flarescale3);
float flare_Red2D_pow = 8.0;
float flare_Red2D_fill = 1.4;
float flare_Red2D_offset = -0.2;
vec2 flare_Red2D_pos = vec2(  ((1.0 - lightPos.x)*(flare_Red2D_offset + 1.0) - (flare_Red2D_offset*0.5))  *aspectRatio*flare_Red2D_scale.x,  ((1.0 - lightPos.y)*(flare_Red2D_offset + 1.0) - (flare_Red2D_offset*0.5))  *flare_Red2D_scale.y);

float flare_Red2D_ = distance(flare_Red2D_pos, vec2(ntc2.s*aspectRatio*flare_Red2D_scale.x, ntc2.t*flare_Red2D_scale.y));
      flare_Red2D_ = 0.5 - flare_Red2D_;
      flare_Red2D_ = clamp(flare_Red2D_*flare_Red2D_fill, 0.0, 1.0)  ;
      flare_Red2D_ = sin(flare_Red2D_*1.57075);
      flare_Red2D_ = pow(flare_Red2D_, 0.9);
      flare_Red2D_ *= flare_Red2D_pow;

flare_Red2_ = clamp(flare_Red2_ - flare_Red2D_, 0.0, 10.0);
flare_Red2_ *= sunmask;

tempColor3.r += flare_Red2_*10.0*flaremultR * (tempColor2.r / 16);
tempColor3.g += flare_Red2_*0.0*flaremultG * (tempColor2.r / 16);
tempColor3.b += flare_Red2_*0.0*flaremultB * (tempColor2.r / 16);

//Orange2
vec2 flare_Orange2_scale = vec2(0.86f*flarescale3, 0.86f*flarescale3);
float flare_Orange2_pow = 4.25f;
float flare_Orange2_fill = 10.0;
float flare_Orange2_offset = -0.0;
vec2 flare_Orange2_pos = vec2(  ((1.0 - lightPos.x)*(flare_Orange2_offset + 1.0) - (flare_Orange2_offset*0.5))  *aspectRatio*flare_Orange2_scale.x,  ((1.0 - lightPos.y)*(flare_Orange2_offset + 1.0) - (flare_Orange2_offset*0.5))  *flare_Orange2_scale.y);

float flare_Orange2_ = distance(flare_Orange2_pos, vec2(ntc2.s*aspectRatio*flare_Orange2_scale.x, ntc2.t*flare_Orange2_scale.y));
      flare_Orange2_ = 0.5 - flare_Orange2_;
      flare_Orange2_ = clamp(flare_Orange2_*flare_Orange2_fill, 0.0, 1.0)  ;
      flare_Orange2_ = sin(flare_Orange2_*1.57075);
      flare_Orange2_ = pow(flare_Orange2_, 1.1);
      flare_Orange2_ *= flare_Orange2_pow;
//subtract
vec2 flare_Orange2D_scale = vec2(0.5446f*flarescale3, 0.5446f*flarescale3);
float flare_Orange2D_pow = 8.0;
float flare_Orange2D_fill = 1.4;
float flare_Orange2D_offset = -0.2;
vec2 flare_Orange2D_pos = vec2(  ((1.0 - lightPos.x)*(flare_Orange2D_offset + 1.0) - (flare_Orange2D_offset*0.5))  *aspectRatio*flare_Orange2D_scale.x,  ((1.0 - lightPos.y)*(flare_Orange2D_offset + 1.0) - (flare_Orange2D_offset*0.5))  *flare_Orange2D_scale.y);

float flare_Orange2D_ = distance(flare_Orange2D_pos, vec2(ntc2.s*aspectRatio*flare_Orange2D_scale.x, ntc2.t*flare_Orange2D_scale.y));
      flare_Orange2D_ = 0.5 - flare_Orange2D_;
      flare_Orange2D_ = clamp(flare_Orange2D_*flare_Orange2D_fill, 0.0, 1.0)  ;
      flare_Orange2D_ = sin(flare_Orange2D_*1.57075);
      flare_Orange2D_ = pow(flare_Orange2D_, 0.9);
      flare_Orange2D_ *= flare_Orange2D_pow;

flare_Orange2_ = clamp(flare_Orange2_ - flare_Orange2D_, 0.0, 10.0);
flare_Orange2_ *= sunmask;

tempColor3.r += flare_Orange2_*10.0*flaremultR * (tempColor2.r / 16);
tempColor3.g += flare_Orange2_*5.0*flaremultG * (tempColor2.r / 16);
tempColor3.b += flare_Orange2_*0.0*flaremultB * (tempColor2.r / 16);

//Green2
vec2 flare_Green2_scale = vec2(0.82f*flarescale3, 0.82f*flarescale3);
float flare_Green2_pow = 4.25f;
float flare_Green2_fill = 10.0;
float flare_Green2_offset = -0.0;
vec2 flare_Green2_pos = vec2(  ((1.0 - lightPos.x)*(flare_Green2_offset + 1.0) - (flare_Green2_offset*0.5))  *aspectRatio*flare_Green2_scale.x,  ((1.0 - lightPos.y)*(flare_Green2_offset + 1.0) - (flare_Green2_offset*0.5))  *flare_Green2_scale.y);

float flare_Green2_ = distance(flare_Green2_pos, vec2(ntc2.s*aspectRatio*flare_Green2_scale.x, ntc2.t*flare_Green2_scale.y));
      flare_Green2_ = 0.5 - flare_Green2_;
      flare_Green2_ = clamp(flare_Green2_*flare_Green2_fill, 0.0, 1.0)  ;
      flare_Green2_ = sin(flare_Green2_*1.57075);
      flare_Green2_ = pow(flare_Green2_, 1.1);
      flare_Green2_ *= flare_Green2_pow;
//subtract
vec2 flare_Green2D_scale = vec2(0.5193f*flarescale3, 0.5193f*flarescale3);
float flare_Green2D_pow = 8.0;
float flare_Green2D_fill = 1.4;
float flare_Green2D_offset = -0.2;
vec2 flare_Green2D_pos = vec2(  ((1.0 - lightPos.x)*(flare_Green2D_offset + 1.0) - (flare_Green2D_offset*0.5))  *aspectRatio*flare_Green2D_scale.x,  ((1.0 - lightPos.y)*(flare_Green2D_offset + 1.0) - (flare_Green2D_offset*0.5))  *flare_Green2D_scale.y);

 float flare_Green2D_ = distance(flare_Green2D_pos, vec2(ntc2.s*aspectRatio*flare_Green2D_scale.x, ntc2.t*flare_Green2D_scale.y));
       flare_Green2D_ = 0.5 - flare_Green2D_;
       flare_Green2D_ = clamp(flare_Green2D_*flare_Green2D_fill, 0.0, 1.0)  ;
       flare_Green2D_ = sin(flare_Green2D_*1.57075);
       flare_Green2D_ = pow(flare_Green2D_, 0.9);
       flare_Green2D_ *= flare_Green2D_pow;

flare_Green2_ = clamp(flare_Green2_ - flare_Green2D_, 0.0, 10.0);
flare_Green2_ *= sunmask;

tempColor3.r += flare_Green2_*0.0*flaremultR * (tempColor2.r / 2);
tempColor3.g += flare_Green2_*1.0*flaremultG * (tempColor2.r / 2);
tempColor3.b += flare_Green2_*0.0*flaremultB * (tempColor2.r / 2);

//Blue2
vec2 flare_Blue2_scale = vec2(0.78f*flarescale3, 0.78f*flarescale3);
float flare_Blue2_pow = 4.25f;
float flare_Blue2_fill = 10.0;
float flare_Blue2_offset = -0.0;
vec2 flare_Blue2_pos = vec2(  ((1.0 - lightPos.x)*(flare_Blue2_offset + 1.0) - (flare_Blue2_offset*0.5))  *aspectRatio*flare_Blue2_scale.x,  ((1.0 - lightPos.y)*(flare_Blue2_offset + 1.0) - (flare_Blue2_offset*0.5))  *flare_Blue2_scale.y);

float flare_Blue2_ = distance(flare_Blue2_pos, vec2(ntc2.s*aspectRatio*flare_Blue2_scale.x, ntc2.t*flare_Blue2_scale.y));
      flare_Blue2_ = 0.5 - flare_Blue2_;
      flare_Blue2_ = clamp(flare_Blue2_*flare_Blue2_fill, 0.0, 1.0)  ;
      flare_Blue2_ = sin(flare_Blue2_*1.57075);

      flare_Blue2_ = pow(flare_Blue2_, 1.1);

      flare_Blue2_ *= flare_Blue2_pow;
//subtract
vec2 flare_Blue2D_scale = vec2(0.494f*flarescale3, 0.494f*flarescale3);
float flare_Blue2D_pow = 8.0;
float flare_Blue2D_fill = 1.4;
float flare_Blue2D_offset = -0.2;
vec2 flare_Blue2D_pos = vec2(  ((1.0 - lightPos.x)*(flare_Blue2D_offset + 1.0) - (flare_Blue2D_offset*0.5))  *aspectRatio*flare_Blue2D_scale.x,  ((1.0 - lightPos.y)*(flare_Blue2D_offset + 1.0) - (flare_Blue2D_offset*0.5))  *flare_Blue2D_scale.y);

float flare_Blue2D_ = distance(flare_Blue2D_pos, vec2(ntc2.s*aspectRatio*flare_Blue2D_scale.x, ntc2.t*flare_Blue2D_scale.y));
      flare_Blue2D_ = 0.5 - flare_Blue2D_;
      flare_Blue2D_ = clamp(flare_Blue2D_*flare_Blue2D_fill, 0.0, 1.0)  ;
      flare_Blue2D_ = sin(flare_Blue2D_*1.57075);
      flare_Blue2D_ = pow(flare_Blue2D_, 0.9);
      flare_Blue2D_ *= flare_Blue2D_pow;

flare_Blue2_ = clamp(flare_Blue2_ - flare_Blue2D_, 0.0, 10.0);
flare_Blue2_ *= sunmask;

tempColor3.r += flare_Blue2_*0.0*flaremultR * (tempColor2.r / 2);
tempColor3.g += flare_Blue2_*0.0*flaremultG * (tempColor2.r / 2);
tempColor3.b += flare_Blue2_*1.0*flaremultB * (tempColor2.r / 2);

fragment_color += (tempColor3 / 4.0);
fragment_color += (tempColor4 / 1.0);
fragment_color += (tempColor * 1.0);
#endif

//Far blue flare MAIN
vec2 flare3scale = vec2(2.0*flarescale, 2.0*flarescale);
float flare3pow = 0.7;
float flare3fill = 10.0;
float flare3offset = -0.5;
vec2 flare3pos = vec2(  ((1.0 - lightPos.x)*(flare3offset + 1.0) - (flare3offset*0.5))  *aspectRatio*flare3scale.x,  ((1.0 - lightPos.y)*(flare3offset + 1.0) - (flare3offset*0.5))  *flare3scale.y);

float flare3 = distance(flare3pos, vec2(ntc2.s*aspectRatio*flare3scale.x, ntc2.t*flare3scale.y));
      flare3 = 0.5 - flare3;
      flare3 = clamp(flare3*flare3fill, 0.0, 1.0)  ;
      flare3 = sin(flare3*1.57075);
      flare3 *= sunmask;
      flare3 = pow(flare3, 1.1);
      flare3 *= flare3pow;
//subtract from blue flare
vec2 flare3Bscale = vec2(1.4*flarescale, 1.4*flarescale);
float flare3Bpow = 1.0;
float flare3Bfill = 2.0;
float flare3Boffset = -0.65f;
vec2 flare3Bpos = vec2(  ((1.0 - lightPos.x)*(flare3Boffset + 1.0) - (flare3Boffset*0.5))  *aspectRatio*flare3Bscale.x,  ((1.0 - lightPos.y)*(flare3Boffset + 1.0) - (flare3Boffset*0.5))  *flare3Bscale.y);

float flare3B = distance(flare3Bpos, vec2(ntc2.s*aspectRatio*flare3Bscale.x, ntc2.t*flare3Bscale.y));
      flare3B = 0.5 - flare3B;
      flare3B = clamp(flare3B*flare3Bfill, 0.0, 1.0)  ;
      flare3B = sin(flare3B*1.57075);
      flare3B *= sunmask;
      flare3B = pow(flare3B, 0.9);
      flare3B *= flare3Bpow;

      flare3 = clamp(flare3 - flare3B, 0.0, 10.0);

fragment_color.r += flare3*0.5*flaremultR;
fragment_color.g += flare3*0.3*flaremultG;
fragment_color.b += flare3*0.0*flaremultB;

//Far blue flare MAIN 2
vec2 flare3Cscale = vec2(3.2*flarescale, 3.2*flarescale);
float flare3Cpow = 1.4;
float flare3Cfill = 10.0;
float flare3Coffset = -0.0;
vec2 flare3Cpos = vec2(  ((1.0 - lightPos.x)*(flare3Coffset + 1.0) - (flare3Coffset*0.5))  *aspectRatio*flare3Cscale.x,  ((1.0 - lightPos.y)*(flare3Coffset + 1.0) - (flare3Coffset*0.5))  *flare3Cscale.y);

float flare3C = distance(flare3Cpos, vec2(ntc2.s*aspectRatio*flare3Cscale.x, ntc2.t*flare3Cscale.y));
      flare3C = 0.5 - flare3C;
      flare3C = clamp(flare3C*flare3Cfill, 0.0, 1.0)  ;
      flare3C = sin(flare3C*1.57075);
      flare3C = pow(flare3C, 1.1);
      flare3C *= flare3Cpow;
//subtract from blue flare
vec2 flare3Dscale = vec2(2.1*flarescale, 2.1*flarescale);
float flare3Dpow = 2.7;
float flare3Dfill = 1.4;
float flare3Doffset = -0.05f;
vec2 flare3Dpos = vec2(  ((1.0 - lightPos.x)*(flare3Doffset + 1.0) - (flare3Doffset*0.5))  *aspectRatio*flare3Dscale.x,  ((1.0 - lightPos.y)*(flare3Doffset + 1.0) - (flare3Doffset*0.5))  *flare3Dscale.y);

float flare3D = distance(flare3Dpos, vec2(ntc2.s*aspectRatio*flare3Dscale.x, ntc2.t*flare3Dscale.y));
      flare3D = 0.5 - flare3D;
      flare3D = clamp(flare3D*flare3Dfill, 0.0, 1.0)  ;
      flare3D = sin(flare3D*1.57075);
      flare3D = pow(flare3D, 0.9);
      flare3D *= flare3Dpow;

flare3C = clamp(flare3C - flare3D, 0.0, 10.0);
flare3C *= sunmask;

fragment_color.r += flare3C*0.5*flaremultR;
fragment_color.g += flare3C*0.3*flaremultG;
fragment_color.b += flare3C*0.0*flaremultB;

//far small pink flare
vec2 flare4scale = vec2(4.5*flarescale, 4.5*flarescale);
float flare4pow = 0.3;
float flare4fill = 3.0;
float flare4offset = -0.1;
vec2 flare4pos = vec2(  ((1.0 - lightPos.x)*(flare4offset + 1.0) - (flare4offset*0.5))  *aspectRatio*flare4scale.x,  ((1.0 - lightPos.y)*(flare4offset + 1.0) - (flare4offset*0.5))  *flare4scale.y);

float flare4 = distance(flare4pos, vec2(ntc2.s*aspectRatio*flare4scale.x, ntc2.t*flare4scale.y));
      flare4 = 0.5 - flare4;
      flare4 = clamp(flare4*flare4fill, 0.0, 1.0)  ;
      flare4 = sin(flare4*1.57075);
      flare4 *= sunmask;
      flare4 = pow(flare4, 1.1);

      flare4 *= flare4pow;

      fragment_color.r += flare4*0.6*flaremultR;
      fragment_color.g += flare4*0.0*flaremultG;
      fragment_color.b += flare4*0.8*flaremultB;

//far small pink flare2
vec2 flare4Bscale = vec2(7.5*flarescale, 7.5*flarescale);
float flare4Bpow = 0.4;
float flare4Bfill = 2.0;
float flare4Boffset = 0.0;
vec2 flare4Bpos = vec2(  ((1.0 - lightPos.x)*(flare4Boffset + 1.0) - (flare4Boffset*0.5))  *aspectRatio*flare4Bscale.x,  ((1.0 - lightPos.y)*(flare4Boffset + 1.0) - (flare4Boffset*0.5))  *flare4Bscale.y);

float flare4B = distance(flare4Bpos, vec2(ntc2.s*aspectRatio*flare4Bscale.x, ntc2.t*flare4Bscale.y));
      flare4B = 0.5 - flare4B;
      flare4B = clamp(flare4B*flare4Bfill, 0.0, 1.0)  ;
      flare4B = sin(flare4B*1.57075);
      flare4B *= sunmask;
      flare4B = pow(flare4B, 1.1);

      flare4B *= flare4Bpow;

      fragment_color.r += flare4B*0.4*flaremultR;
      fragment_color.g += flare4B*0.0*flaremultG;
      fragment_color.b += flare4B*0.8*flaremultB;

//far small pink flare3
vec2 flare4Cscale = vec2(37.5*flarescale, 37.5*flarescale);
float flare4Cpow = 2.0;
float flare4Cfill = 2.0;
float flare4Coffset = -0.3;
vec2 flare4Cpos = vec2(  ((1.0 - lightPos.x)*(flare4Coffset + 1.0) - (flare4Coffset*0.5))  *aspectRatio*flare4Cscale.x,  ((1.0 - lightPos.y)*(flare4Coffset + 1.0) - (flare4Coffset*0.5))  *flare4Cscale.y);

float flare4C = distance(flare4Cpos, vec2(ntc2.s*aspectRatio*flare4Cscale.x, ntc2.t*flare4Cscale.y));
      flare4C = 0.5 - flare4C;
      flare4C = clamp(flare4C*flare4Cfill, 0.0, 1.0)  ;
      flare4C = sin(flare4C*1.57075);
      flare4C *= sunmask;
      flare4C = pow(flare4C, 1.1);

      flare4C *= flare4Cpow;

      fragment_color.r += flare4C*0.6*flaremultR;
      fragment_color.g += flare4C*0.3*flaremultG;
      fragment_color.b += flare4C*0.1*flaremultB;

//far small pink flare4
vec2 flare4Dscale = vec2(67.5*flarescale, 67.5*flarescale);
float flare4Dpow = 1.0;
float flare4Dfill = 2.0;
float flare4Doffset = -0.35f;
vec2 flare4Dpos = vec2(  ((1.0 - lightPos.x)*(flare4Doffset + 1.0) - (flare4Doffset*0.5))  *aspectRatio*flare4Dscale.x,  ((1.0 - lightPos.y)*(flare4Doffset + 1.0) - (flare4Doffset*0.5))  *flare4Dscale.y);

float flare4D = distance(flare4Dpos, vec2(ntc2.s*aspectRatio*flare4Dscale.x, ntc2.t*flare4Dscale.y));
      flare4D = 0.5 - flare4D;
      flare4D = clamp(flare4D*flare4Dfill, 0.0, 1.0)  ;
      flare4D = sin(flare4D*1.57075);
      flare4D *= sunmask;
      flare4D = pow(flare4D, 1.1);

      flare4D *= flare4Dpow;

      fragment_color.r += flare4D*0.2*flaremultR;
      fragment_color.g += flare4D*0.2*flaremultG;
      fragment_color.b += flare4D*0.2*flaremultB;

//far small pink flare5
vec2 flare4Escale = vec2(60.5*flarescale, 60.5*flarescale);
float flare4Epow = 1.0;
float flare4Efill = 3.0;
float flare4Eoffset = -0.3393f;
vec2 flare4Epos = vec2(  ((1.0 - lightPos.x)*(flare4Eoffset + 1.0) - (flare4Eoffset*0.5))  *aspectRatio*flare4Escale.x,  ((1.0 - lightPos.y)*(flare4Eoffset + 1.0) - (flare4Eoffset*0.5))  *flare4Escale.y);

float flare4E = distance(flare4Epos, vec2(ntc2.s*aspectRatio*flare4Escale.x, ntc2.t*flare4Escale.y));
      flare4E = 0.5 - flare4E;
      flare4E = clamp(flare4E*flare4Efill, 0.0, 1.0)  ;
      flare4E = sin(flare4E*1.57075);
      flare4E *= sunmask;
      flare4E = pow(flare4E, 1.1);

      flare4E *= flare4Epow;

      fragment_color.r += flare4E*0.2*flaremultR;
      fragment_color.g += flare4E*0.2*flaremultG;
      fragment_color.b += flare4E*0.0*flaremultB;

//close ring flare green
vec2 flare6Bscale = vec2(1.1*flarescale, 1.1*flarescale);
float flare6Bpow = 0.2;
float flare6Bfill = 5.0;
float flare6Boffset = -1.9;
vec2 flare6Bpos = vec2(  ((1.0 - lightPos.x)*(flare6Boffset + 1.0) - (flare6Boffset*0.5))  *aspectRatio*flare6Bscale.x,  ((1.0 - lightPos.y)*(flare6Boffset + 1.0) - (flare6Boffset*0.5))  *flare6Bscale.y);

float flare6B = distance(flare6Bpos, vec2(ntc2.s*aspectRatio*flare6Bscale.x, ntc2.t*flare6Bscale.y));
      flare6B = 0.5 - flare6B;
      flare6B = clamp(flare6B*flare6Bfill, 0.0, 1.0)  ;
      flare6B = pow(flare6B, 1.6);
      flare6B = sin(flare6B*3.1415);
      flare6B *= sunmask;
      flare6B *= flare6Bpow;

fragment_color.r += flare6B*1.0*flaremultR * (tempColor2.r);
fragment_color.g += flare6B*0.4*flaremultG * (tempColor2.r);
fragment_color.b += flare6B*0.0*flaremultB * (tempColor2.r);

//close ring flare blue
vec2 flare6Cscale = vec2(0.9*flarescale, 0.9*flarescale);
float flare6Cpow = 0.3;
float flare6Cfill = 5.0;
float flare6Coffset = -1.9;
vec2 flare6Cpos = vec2(  ((1.0 - lightPos.x)*(flare6Coffset + 1.0) - (flare6Coffset*0.5))  *aspectRatio*flare6Cscale.x,  ((1.0 - lightPos.y)*(flare6Coffset + 1.0) - (flare6Coffset*0.5))  *flare6Cscale.y);

float flare6C = distance(flare6Cpos, vec2(ntc2.s*aspectRatio*flare6Cscale.x, ntc2.t*flare6Cscale.y));
      flare6C = 0.5 - flare6C;
      flare6C = clamp(flare6C*flare6Cfill, 0.0, 1.0)  ;
      flare6C = pow(flare6C, 1.8);
      flare6C = sin(flare6C*3.1415);
      flare6C *= sunmask;
      flare6C *= flare6Cpow;

fragment_color.r += flare6C*0.5*flaremultR * (tempColor2.r);
fragment_color.g += flare6C*0.3*flaremultG * (tempColor2.r);
fragment_color.b += flare6C*0.0*flaremultB * (tempColor2.r);

#ifdef LF_CENTER_STRIP
//Anamorphic lens center
//Edge orange glow
vec2 flareEscale = vec2(0.2*flarescale, 5.0*flarescale);
float flareEpow = 1.0;
float flareEfill = 2.0;
vec2 flareEoffset = vec2(0.0);
vec2 flareEpos = vec2(lightPos.x*aspectRatio*flareEscale.x, lightPos.y*flareEscale.y);

float flareE = distance(flareEpos, vec2(ntc2.s*aspectRatio*flareEscale.x, ntc2.t*flareEscale.y));
      flareE = 0.5 - flareE;
      flareE = clamp(flareE*flareEfill, 0.0, 1.0)  ;
      flareE *= sunmask;
      flareE = pow(flareE, 1.4);

      flareE *= flareEpow;

    #if LENS_FLARE_MODE == 2
        if (sunVec.z > 0.0) {
      flareE = 0;
        } else
    #endif
    {
      fragment_color.r += flareE*1.0*flaremultR;
      fragment_color.g += flareE*0.6*flaremultG;
      fragment_color.b += flareE*0.0*flaremultB;
    }

//Red
vec2 flare_strip1_scale = vec2(0.5*flarescale, 15.0*flarescale);
float flare_strip1_pow = 0.25f;
float flare_strip1_fill = 2.0;
float flare_strip1_offset = 0.0;
vec2 flare_strip1_pos = vec2(lightPos.x*aspectRatio*flare_strip1_scale.x, lightPos.y*flare_strip1_scale.y);

float flare_strip1_ = distance(flare_strip1_pos, vec2(ntc2.s*aspectRatio*flare_strip1_scale.x, ntc2.t*flare_strip1_scale.y));
      flare_strip1_ = 0.5 - flare_strip1_;
      flare_strip1_ = clamp(flare_strip1_*flare_strip1_fill, 0.0, 1.0)  ;
      flare_strip1_ *= sunmask;
      flare_strip1_ = pow(flare_strip1_, 1.4);

      flare_strip1_ *= flare_strip1_pow;

    #if LENS_FLARE_MODE == 2
        if (sunVec.z > 0.0) {
      fragment_color.r += flare_strip1_*0.25f*sunVisibility;
      fragment_color.g += flare_strip1_*0.4f*sunVisibility;
      fragment_color.b += flare_strip1_*0.5*sunVisibility;
        } else
    #endif
    {
      fragment_color.r += flare_strip1_*0.14f*moonVisibility;
      fragment_color.g += flare_strip1_*0.13f*moonVisibility;
      fragment_color.b += flare_strip1_*0.0*moonVisibility;
    }

//Blue
vec2 flare_strip3_scale = vec2(0.4*flarescale, 35.0*flarescale);
float flare_strip3_pow = 0.25f;
float flare_strip3_fill = 2.0;
float flare_strip3_offset = 0.0;
vec2 flare_strip3_pos = vec2(lightPos.x*aspectRatio*flare_strip1_scale.x, lightPos.y*flare_strip1_scale.y);

float flare_strip3_ = distance(flare_strip1_pos, vec2(ntc2.s*aspectRatio*flare_strip1_scale.x, ntc2.t*flare_strip1_scale.y));
      flare_strip3_ = 0.5 - flare_strip1_;
      flare_strip3_ = clamp(flare_strip1_*flare_strip1_fill, 0.0, 1.0)  ;
      flare_strip3_ *= sunmask;
      flare_strip3_ = pow(flare_strip1_, 1.4);

      flare_strip3_ *= flare_strip1_pow;

      fragment_color.r += flare_strip3_*0.3f*flaremultR;
      fragment_color.g += flare_strip3_*0.7f*flaremultG;
      fragment_color.b += flare_strip3_*1.0*flaremultB;
#endif

//mid orange sweep
vec2 flare_extra3scale = vec2(32.0*flarescale, 32.0*flarescale);
float flare_extra3pow = 2.5;
float flare_extra3fill = 1.1;
float flare_extra3offset = -1.3;
vec2 flare_extra3pos = vec2(  ((1.0 - lightPos.x)*(flare_extra3offset + 1.0) - (flare_extra3offset*0.5))  *aspectRatio*flare_extra3scale.x,  ((1.0 - lightPos.y)*(flare_extra3offset + 1.0) - (flare_extra3offset*0.5))  *flare_extra3scale.y);

float flare_extra3 = distance(flare_extra3pos, vec2(ntc2.s*aspectRatio*flare_extra3scale.x, ntc2.t*flare_extra3scale.y));
      flare_extra3 = 0.5 - flare_extra3;
      flare_extra3 = clamp(flare_extra3*flare_extra3fill, 0.0, 1.0)  ;
      flare_extra3 = sin(flare_extra3*1.57075);
      flare_extra3 *= sunmask;
      flare_extra3 = pow(flare_extra3, 1.1);
      flare_extra3 *= flare_extra3pow;
//subtract
vec2 flare_extra3Bscale = vec2(5.1*flarescale, 5.1*flarescale);
float flare_extra3Bpow = 1.5;
float flare_extra3Bfill = 1.0;
float flare_extra3Boffset = -0.77f;
vec2 flare_extra3Bpos = vec2(  ((1.0 - lightPos.x)*(flare_extra3Boffset + 1.0) - (flare_extra3Boffset*0.5))  *aspectRatio*flare_extra3Bscale.x,  ((1.0 - lightPos.y)*(flare_extra3Boffset + 1.0) - (flare_extra3Boffset*0.5))  *flare_extra3Bscale.y);

float flare_extra3B = distance(flare_extra3Bpos, vec2(ntc2.s*aspectRatio*flare_extra3Bscale.x, ntc2.t*flare_extra3Bscale.y));
      flare_extra3B = 0.5 - flare_extra3B;
      flare_extra3B = clamp(flare_extra3B*flare_extra3Bfill, 0.0, 1.0)  ;
      flare_extra3B = sin(flare_extra3B*1.57075);
      flare_extra3B *= sunmask;
      flare_extra3B = pow(flare_extra3B, 0.9);
      flare_extra3B *= flare_extra3Bpow;

flare_extra3 = clamp(flare_extra3 - flare_extra3B, 0.0, 10.0);

fragment_color.r += flare_extra3*0.5*flaremultR;
fragment_color.g += flare_extra3*0.4*flaremultG;
fragment_color.b += flare_extra3*0.1*flaremultB;

//mid orange sweep
vec2 flare_extra4scale = vec2(35.0*flarescale, 35.0*flarescale);
float flare_extra4pow = 1.0;
float flare_extra4fill = 1.1;
float flare_extra4offset = -1.2;
vec2 flare_extra4pos = vec2(  ((1.0 - lightPos.x)*(flare_extra4offset + 1.0) - (flare_extra4offset*0.5))  *aspectRatio*flare_extra4scale.x,  ((1.0 - lightPos.y)*(flare_extra4offset + 1.0) - (flare_extra4offset*0.5))  *flare_extra4scale.y);

float flare_extra4 = distance(flare_extra4pos, vec2(ntc2.s*aspectRatio*flare_extra4scale.x, ntc2.t*flare_extra4scale.y));
      flare_extra4 = 0.5 - flare_extra4;
      flare_extra4 = clamp(flare_extra4*flare_extra4fill, 0.0, 1.0)  ;
      flare_extra4 = sin(flare_extra4*1.57075);
      flare_extra4 *= sunmask;
      flare_extra4 = pow(flare_extra4, 1.1);
      flare_extra4 *= flare_extra4pow;
//subtract
vec2 flare_extra4Bscale = vec2(5.1*flarescale, 5.1*flarescale);
float flare_extra4Bpow = 1.5;
float flare_extra4Bfill = 1.0;
float flare_extra4Boffset = -0.77f;
vec2 flare_extra4Bpos = vec2(  ((1.0 - lightPos.x)*(flare_extra4Boffset + 1.0) - (flare_extra4Boffset*0.5))  *aspectRatio*flare_extra4Bscale.x,  ((1.0 - lightPos.y)*(flare_extra4Boffset + 1.0) - (flare_extra4Boffset*0.5))  *flare_extra4Bscale.y);

float flare_extra4B = distance(flare_extra4Bpos, vec2(ntc2.s*aspectRatio*flare_extra4Bscale.x, ntc2.t*flare_extra4Bscale.y));
      flare_extra4B = 0.5 - flare_extra4B;
      flare_extra4B = clamp(flare_extra4B*flare_extra4Bfill, 0.0, 1.0)  ;
      flare_extra4B = sin(flare_extra4B*1.57075);
      flare_extra4B *= sunmask;
      flare_extra4B = pow(flare_extra4B, 0.9);
      flare_extra4B *= flare_extra4Bpow;

flare_extra4 = clamp(flare_extra4 - flare_extra4B, 0.0, 10.0);

fragment_color.r += flare_extra4*0.6*flaremultR;
fragment_color.g += flare_extra4*0.4*flaremultG;
fragment_color.b += flare_extra4*0.1*flaremultB;

//mid orange sweep
vec2 flare_extra5scale = vec2(25.0*flarescale, 25.0*flarescale);
float flare_extra5pow = 4.0;
float flare_extra5fill = 1.1;
float flare_extra5offset = -0.9;
vec2 flare_extra5pos = vec2(  ((1.0 - lightPos.x)*(flare_extra5offset + 1.0) - (flare_extra5offset*0.5))  *aspectRatio*flare_extra5scale.x,  ((1.0 - lightPos.y)*(flare_extra5offset + 1.0) - (flare_extra5offset*0.5))  *flare_extra5scale.y);

float flare_extra5 = distance(flare_extra5pos, vec2(ntc2.s*aspectRatio*flare_extra5scale.x, ntc2.t*flare_extra5scale.y));
      flare_extra5 = 0.5 - flare_extra5;
      flare_extra5 = clamp(flare_extra5*flare_extra5fill, 0.0, 1.0)  ;
      flare_extra5 = sin(flare_extra5*1.57075);
      flare_extra5 *= sunmask;
      flare_extra5 = pow(flare_extra5, 1.1);
      flare_extra5 *= flare_extra5pow;
//subtract
vec2 flare_extra5Bscale = vec2(5.1*flarescale, 5.1*flarescale);
float flare_extra5Bpow = 1.5;
float flare_extra5Bfill = 1.0;
float flare_extra5Boffset = -0.77f;
vec2 flare_extra5Bpos = vec2(  ((1.0 - lightPos.x)*(flare_extra5Boffset + 1.0) - (flare_extra5Boffset*0.5))  *aspectRatio*flare_extra5Bscale.x,  ((1.0 - lightPos.y)*(flare_extra5Boffset + 1.0) - (flare_extra5Boffset*0.5))  *flare_extra5Bscale.y);

float flare_extra5B = distance(flare_extra5Bpos, vec2(ntc2.s*aspectRatio*flare_extra5Bscale.x, ntc2.t*flare_extra5Bscale.y));
      flare_extra5B = 0.5 - flare_extra5B;
      flare_extra5B = clamp(flare_extra5B*flare_extra5Bfill, 0.0, 1.0)  ;
      flare_extra5B = sin(flare_extra5B*1.57075);
      flare_extra5B *= sunmask;
      flare_extra5B = pow(flare_extra5B, 0.9);
      flare_extra5B *= flare_extra5Bpow;

flare_extra5 = clamp(flare_extra5 - flare_extra5B, 0.0, 10.0);

fragment_color.r += flare_extra5*0.5*flaremultR;
fragment_color.g += flare_extra5*0.3*flaremultG;
fragment_color.b += flare_extra5*0.0*flaremultB;

//far red glow
vec2 flare7Bscale = vec2(0.2*flarescale, 0.2*flarescale);
float flare7Bpow = 0.1;
float flare7Bfill = 2.0;
float flare7Boffset = 2.9;
vec2 flare7Bpos = vec2(  ((1.0 - lightPos.x)*(flare7Boffset + 1.0) - (flare7Boffset*0.5))  *aspectRatio*flare7Bscale.x,  ((1.0 - lightPos.y)*(flare7Boffset + 1.0) - (flare7Boffset*0.5))  *flare7Bscale.y);

float flare7B = distance(flare7Bpos, vec2(ntc2.s*aspectRatio*flare7Bscale.x, ntc2.t*flare7Bscale.y));
      flare7B = 0.5 - flare7B;
      flare7B = clamp(flare7B*flare7Bfill, 0.0, 1.0)  ;
      flare7B = pow(flare7B, 1.9);
      flare7B = sin(flare7B*3.1415*0.5);
      flare7B *= sunmask;
      flare7B *= flare7Bpow;

fragment_color.r += flare7B*1.0*flaremultR;
fragment_color.g += flare7B*0.0*flaremultG;
fragment_color.b += flare7B*0.0*flaremultB;

#ifdef LF_EDGE_STRIP
//Anamorphic lens edge
//Edge blue strip 1
vec2 flare8scale = vec2(0.3*flarescale, 40.5*flarescale);
float flare8pow = 0.5;
float flare8fill = 12.0;
float flare8offset = 1.0;
vec2 flare8pos = vec2(  ((1.0 - lightPos.x)*(flare8offset + 1.0) - (flare8offset*0.5))  *aspectRatio*flare8scale.x,  ((lightPos.y)*(flare8offset + 1.0) - (flare8offset*0.5))  *flare8scale.y);

float flare8 = distance(flare8pos, vec2(ntc2.s*aspectRatio*flare8scale.x, ntc2.t*flare8scale.y));
      flare8 = 0.5 - flare8;
      flare8 = clamp(flare8*flare8fill, 0.0, 1.0)  ;
      flare8 *= sunmask;
      flare8 = pow(flare8, 1.4);
      flare8 *= flare8pow;
      flare8 *= edgemaskx;
      fragment_color.r += flare8*0.0*flaremultR;
      fragment_color.g += flare8*0.15*flaremultG;
      fragment_color.b += flare8*0.4*flaremultB;

//Edge blue strip 2
vec2 flare9scale = vec2(0.2*flarescale, 5.5*flarescale);
float flare9pow = 1.9;
float flare9fill = 2.0;
vec2 flare9offset = vec2(1.0, 0.0);
vec2 flare9pos = vec2(  ((1.0 - lightPos.x)*(flare9offset.x + 1.0) - (flare9offset.x*0.5))  *aspectRatio*flare9scale.x,  ((1.0 - lightPos.y)*(flare9offset.y + 1.0) - (flare9offset.y*0.5))  *flare9scale.y);

float flare9 = distance(flare9pos, vec2(ntc2.s*aspectRatio*flare9scale.x, ntc2.t*flare9scale.y));
      flare9 = 0.5 - flare9;
      flare9 = clamp(flare9*flare9fill, 0.0, 1.0)  ;
      flare9 *= sunmask;
      flare9 = pow(flare9, 1.4);
      flare9 *= flare9pow;
      flare9 *= edgemaskx;
	  
fragment_color.r += flare9*0.1*flaremultR;
fragment_color.g += flare9*0.2*flaremultG;
fragment_color.b += flare9*0.45*flaremultB;
#endif

//SMALL SWEEPS

//mid orange sweep
vec2 flare10scale = vec2(6.0*flarescale, 6.0*flarescale);
float flare10pow = 1.9;
float flare10fill = 1.1;
float flare10offset = -0.7;
vec2 flare10pos = vec2(  ((1.0 - lightPos.x)*(flare10offset + 1.0) - (flare10offset*0.5))  *aspectRatio*flare10scale.x,  ((1.0 - lightPos.y)*(flare10offset + 1.0) - (flare10offset*0.5))  *flare10scale.y);

float flare10 = distance(flare10pos, vec2(ntc2.s*aspectRatio*flare10scale.x, ntc2.t*flare10scale.y));
      flare10 = 0.5 - flare10;
      flare10 = clamp(flare10*flare10fill, 0.0, 1.0)  ;
      flare10 = sin(flare10*1.57075);
      flare10 *= sunmask;
      flare10 = pow(flare10, 1.1);
      flare10 *= flare10pow;
//subtract
vec2 flare10Bscale = vec2(5.1*flarescale, 5.1*flarescale);
float flare10Bpow = 1.5;
float flare10Bfill = 1.0;
float flare10Boffset = -0.77f;
vec2 flare10Bpos = vec2(  ((1.0 - lightPos.x)*(flare10Boffset + 1.0) - (flare10Boffset*0.5))  *aspectRatio*flare10Bscale.x,  ((1.0 - lightPos.y)*(flare10Boffset + 1.0) - (flare10Boffset*0.5))  *flare10Bscale.y);

float flare10B = distance(flare10Bpos, vec2(ntc2.s*aspectRatio*flare10Bscale.x, ntc2.t*flare10Bscale.y));
      flare10B = 0.5 - flare10B;
      flare10B = clamp(flare10B*flare10Bfill, 0.0, 1.0)  ;
      flare10B = sin(flare10B*1.57075);
      flare10B *= sunmask;
      flare10B = pow(flare10B, 0.9);
      flare10B *= flare10Bpow;

flare10 = clamp(flare10 - flare10B, 0.0, 10.0);

fragment_color.r += flare10*0.5*flaremultR;
fragment_color.g += flare10*0.3*flaremultG;
fragment_color.b += flare10*0.0*flaremultB;

//mid blue sweep
vec2 flare10Cscale = vec2(6.0*flarescale, 6.0*flarescale);
float flare10Cpow = 1.9;
float flare10Cfill = 1.1;
float flare10Coffset = -0.6;
vec2 flare10Cpos = vec2(  ((1.0 - lightPos.x)*(flare10Coffset + 1.0) - (flare10Coffset*0.5))  *aspectRatio*flare10Cscale.x,  ((1.0 - lightPos.y)*(flare10Coffset + 1.0) - (flare10Coffset*0.5))  *flare10Cscale.y);

float flare10C = distance(flare10Cpos, vec2(ntc2.s*aspectRatio*flare10Cscale.x, ntc2.t*flare10Cscale.y));
      flare10C = 0.5 - flare10C;
      flare10C = clamp(flare10C*flare10Cfill, 0.0, 1.0)  ;
      flare10C = sin(flare10C*1.57075);
      flare10C *= sunmask;
      flare10C = pow(flare10C, 1.1);
      flare10C *= flare10Cpow;
//subtract
vec2 flare10Dscale = vec2(5.1*flarescale, 5.1*flarescale);
float flare10Dpow = 1.5;
float flare10Dfill = 1.0;
float flare10Doffset = -0.67f;
vec2 flare10Dpos = vec2(  ((1.0 - lightPos.x)*(flare10Doffset + 1.0) - (flare10Doffset*0.5))  *aspectRatio*flare10Dscale.x,  ((1.0 - lightPos.y)*(flare10Doffset + 1.0) - (flare10Doffset*0.5))  *flare10Dscale.y);

float flare10D = distance(flare10Dpos, vec2(ntc2.s*aspectRatio*flare10Dscale.x, ntc2.t*flare10Dscale.y));
      flare10D = 0.5 - flare10D;
      flare10D = clamp(flare10D*flare10Dfill, 0.0, 1.0)  ;
      flare10D = sin(flare10D*1.57075);
      flare10D *= sunmask;
      flare10D = pow(flare10D, 0.9);
      flare10D *= flare10Dpow;

flare10C = clamp(flare10C - flare10D, 0.0, 10.0);

fragment_color.r += flare10C*0.5*flaremultR;
fragment_color.g += flare10C*0.3*flaremultG;
fragment_color.b += flare10C*0.0*flaremultB;

#ifdef LF_GLOWDOTS
//Pointy fuzzy glow dots
//RedGlow1
vec2 flare11scale = vec2(1.5*flarescale, 1.5*flarescale);
float flare11pow = 1.1;
float flare11fill = 2.0;
float flare11offset = -0.523f;
vec2 flare11pos = vec2(  ((1.0 - lightPos.x)*(flare11offset + 1.0) - (flare11offset*0.5))  *aspectRatio*flare11scale.x,  ((1.0 - lightPos.y)*(flare11offset + 1.0) - (flare11offset*0.5))  *flare11scale.y);

float flare11 = distance(flare11pos, vec2(ntc2.s*aspectRatio*flare11scale.x, ntc2.t*flare11scale.y));
      flare11 = 0.5 - flare11;
      flare11 = clamp(flare11*flare11fill, 0.0, 1.0)  ;
      flare11 = pow(flare11, 2.9);
      flare11 *= sunmask;

      flare11 *= flare11pow;

      fragment_color.r += flare11*0.5*flaremultR;
      fragment_color.g += flare11*0.1*flaremultG;
      fragment_color.b += flare11*0.0*flaremultB;

//PurpleGlow2
vec2 flare12scale = vec2(2.5*flarescale, 2.5*flarescale);
float flare12pow = 0.5;
float flare12fill = 2.0;
float flare12offset = -0.323f;
vec2 flare12pos = vec2(  ((1.0 - lightPos.x)*(flare12offset + 1.0) - (flare12offset*0.5))  *aspectRatio*flare12scale.x,  ((1.0 - lightPos.y)*(flare12offset + 1.0) - (flare12offset*0.5))  *flare12scale.y);

float flare12 = distance(flare12pos, vec2(ntc2.s*aspectRatio*flare12scale.x, ntc2.t*flare12scale.y));
      flare12 = 0.5 - flare12;
      flare12 = clamp(flare12*flare12fill, 0.0, 1.0)  ;
      flare12 = pow(flare12, 2.9);
      flare12 *= sunmask;

      flare12 *= flare12pow;

      fragment_color.r += flare12*0.35*flaremultR;
      fragment_color.g += flare12*0.15*flaremultG;
      fragment_color.b += flare12*0.0*flaremultB;

//BlueGlow3
vec2 flare13scale = vec2(1.0*flarescale, 1.0*flarescale);
float flare13pow = 1.5;
float flare13fill = 2.0;
float flare13offset = +0.138f;
vec2 flare13pos = vec2(  ((1.0 - lightPos.x)*(flare13offset + 1.0) - (flare13offset*0.5))  *aspectRatio*flare13scale.x,  ((1.0 - lightPos.y)*(flare13offset + 1.0) - (flare13offset*0.5))  *flare13scale.y);

float flare13 = distance(flare13pos, vec2(ntc2.s*aspectRatio*flare13scale.x, ntc2.t*flare13scale.y));
      flare13 = 0.5 - flare13;
      flare13 = clamp(flare13*flare13fill, 0.0, 1.0)  ;
      flare13 = pow(flare13, 2.9);
      flare13 *= sunmask;

      flare13 *= flare13pow;

      fragment_color.r += flare13*0.5*flaremultR;
      fragment_color.g += flare13*0.3*flaremultG;
      fragment_color.b += flare13*0.0*flaremultB;
#endif
   }
}