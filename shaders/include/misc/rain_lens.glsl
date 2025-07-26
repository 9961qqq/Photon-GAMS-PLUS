// Sitting By The Window by Kris_Katur on Shadertoy
// https://www.shadertoy.com/view/slfSzS

// shader derived from Heartfelt - by Martijn Steinrucken aka BigWings - 2017
// https://www.shadertoy.com/view/ltffzl
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

vec3 N13(float p) {
   //  from DAVE HOSKINS
   vec3 p3 = fract(vec3(p) * vec3(0.1031,0.11369,0.13787));
        p3 += dot(p3, p3.yzx + 19.19);
   return fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

vec4 N14(float t) {
	return fract(sin(t*vec4(123., 1024., 1456., 264.))*vec4(6547., 345., 8799., 1564.));
}
float N(float t) {
    return fract(sin(t*12345.564)*7658.76);
}

float Saw(float b, float t) {
	return smoothstep(0.0, b, t)*smoothstep(1.0, b, t);
}

vec2 Drops(vec2 uv, float t) {
    
    vec2 UV = uv;
    
    // DEFINE GRID
    uv.y += t*0.8;
    vec2 a = vec2(6.0, 1.0);
    vec2 grid = a*2.0;
    vec2 id = floor(uv*grid);
    
    // RANDOM SHIFT Y
    float colShift = N(id.x); 
    uv.y += colShift;
    
    // DEFINE SPACES
    id = floor(uv*grid);
    vec3 n = N13(id.x*35.2+id.y*2376.1);
    vec2 st = fract(uv*grid)-vec2(0.5, 0.0);
    
    // POSITION DROPS
    //clamp(2*x,0,2)+clamp(1-x*.5, -1.5, .5)+1.5-2
    float x = n.x-0.5;
    
    float y = UV.y*20.0;
    
    float distort = sin(y+sin(y));
    x += distort*(0.5-abs(x))*(n.z-0.5);
    x *= 0.7;
    float ti = fract(t+n.z);
    y = (Saw(0.85, ti)-0.5)*0.9+0.5;
    vec2 p = vec2(x, y);
    
    // DROPS
    float d = length((st-p)*a.yx); 
    
    float Drop = smoothstep(RAINDROP_SIZE, 0.0, d);
    
    
    float r = sqrt(smoothstep(1.0, y, st.y));
    float cd = abs(st.x-x);
    
    // TRAILS
    float trail = smoothstep((RAINDROP_SIZE*0.5+0.03)*r, (RAINDROP_SIZE*.5-0.05)*r, cd);
    float trailFront = smoothstep(-0.02, 0.02, st.y-y);
    trail *= trailFront;
    
    
    // DROPLETS
    y = UV.y;
    y += N(id.x);
    float trail2 = smoothstep(RAINDROP_SIZE*r, 0.0, cd);
    float droplets = max(0.0, (sin(y*(1.0-y)*120.0)-st.y))*trail2*trailFront*n.z;
    y = fract(y*10.0)+(st.y-0.5);
    float dd = length(st-vec2(x, y));
    droplets = smoothstep(RAINDROP_SIZE*N(id.x), 0.0, dd);
    float m = Drop+droplets*r*trailFront;
    
    return vec2(m, trail);
}

float StaticDrops(vec2 uv, float t) {
	uv *= 30.0;
    
    vec2 id = floor(uv);
    uv = fract(uv)-0.5;
    vec3 n = N13(id.x*107.45+id.y*3543.654);
    vec2 p = (n.xy-0.5)*0.5;
    float d = length(uv-p);
    
    float fade = Saw(0.025, fract(t+n.z));
    float c = smoothstep(STATIC_SIZE, 0.0, d)*fract(n.z*10.0)*fade;

    return c;
}

vec2 Rain(vec2 uv, float t) {
    float s = StaticDrops(uv, t); 
    vec2 r1 = Drops(uv, t);
    vec2 r2 = Drops(uv*1.8, t);
    
    float c = s+r1.x+r2.x;
    
    c = smoothstep(0.3, 1.0, c);
    
    return vec2(c, max(r1.y, r2.y));
}

void RainLens(inout vec3 color) {
    vec2 resolution = vec2(viewWidth, viewHeight);
    vec2 fragCoord = gl_FragCoord.xy;

    vec2 uv = (fragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    vec2 UV = fragCoord.xy / resolution.xy;

    float t = frameTimeCounter * RAINDROP_SPEED;
    
    vec2 c = Rain(uv, t);
    vec2 e = vec2(0.001, 0.0);
    float cx = Rain(uv + e, t).x;
    float cy = Rain(uv + e.yx, t).x;
    vec2 n = vec2(cx - c.x, cy - c.x);

    vec2 bgCoord = vec2(UV.x, UV.y);
    vec3 tex = texture2D(colortex0, bgCoord + n).rgb;

    vec3 bg = texture2D(colortex0, vec2(uv.x, 1.0 - uv.y)).rgb;
    c.y = clamp01(c.y);
    
    vec3 rain_col = bg * (1.0 - c.y);
    rain_col = c.y * (tex - 0.005) + 0.005;
	rain_col += c.x * vec3(0.05);

    float rain_factor = 0.5 * rainStrength * clamp((eyeBrightnessSmooth.y-220)/15.0,0.0,1.0) * biome_may_rain * RAIN_LENS_INTENSITY;

    color += rain_col * rain_factor;
}