#if !defined INCLUDE_SKY_SKY
#define INCLUDE_SKY_SKY

#include "/include/utility/color.glsl"
#include "/include/utility/dithering.glsl"
#include "/include/utility/fast_math.glsl"
#include "/include/utility/random.glsl"

//----------------------------------------------------------------------------//
#if defined WORLD_OVERWORLD

#include "/include/lighting/colors/light_color.glsl"
#include "/include/lighting/colors/weather_color.glsl"
#include "/include/lighting/bsdf.glsl"
#include "/include/misc/lightning_flash.glsl"
#include "/include/sky/atmosphere.glsl"
#include "/include/sky/projection.glsl"
#include "/include/sky/rainbow.glsl"
#include "/include/sky/stars.glsl"
#include "/include/utility/geometry.glsl"
#include "/include/sky/shooting_stars.glsl"
#include "/include/sky/nebula.glsl"

const float sun_luminance  = SUN_LUMINANCE; // luminance of sun disk
const float moon_luminance = MOON_LUMINANCE * MOON_I; // luminance of moon disk

vec3 draw_sun(vec3 ray_dir) {
	float nu = dot(ray_dir, sun_dir);

	// Limb darkening model from http://www.physics.hmc.edu/faculty/esin/a101/limbdarkening.pdf
	const vec3 alpha = vec3(0.429, 0.522, 0.614);
	float center_to_edge = max0(sun_angular_radius - fast_acos(nu));
	vec3 limb_darkening = pow(vec3(1.0 - sqr(1.0 - center_to_edge)), 0.5 * alpha);

	return sun_luminance * sun_color * step(0.0, center_to_edge) * limb_darkening;
}

vec4 draw_moon(vec3 ray_dir){
		// Shader moon
	const float angle      = 0.7;
	const mat2  rot        = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));

 	const vec3  lit_color  = vec3(MOON_R, MOON_G <= 0.03 ? 0.0 : MOON_G - 0.03, MOON_B);
	const vec3  glow_color = vec3(MOON_R <= 0.05 ? 0.0 : MOON_R - 0.05, MOON_G, MOON_B);

 	// Cut out the moon disc.
	float MoV = dot(ray_dir, moon_dir);
	if (MoV < cos(moon_angular_radius)) {
		return vec4(0.0);
	}

 	// Find distance from center to edge.
	float dist = clamp01(fast_acos(MoV) / moon_angular_radius);

 	// Transform the coordinate space such that z is parallel to moon_dir
	vec3 tangent = moon_dir.y == 1.0
		? vec3(1.0, 0.0, 0.0)
		: normalize(cross(vec3(0.0, 1.0, 0.0), moon_dir));
	vec3 bitangent = normalize(cross(tangent, moon_dir));
	mat3 tbn = mat3(tangent, bitangent, moon_dir);

 	// Vector from ray dir to moon dir
	vec2 offset = ((ray_dir - sun_dir) * tbn).xy;
    offset = fract(offset + 0.5);

 	vec3 noise = texture(noisetex, 2.0 * offset).xyz;
	float moon_texture = pow1d5(noise.x) * 0.75 + 0.6 * cube(noise.y) - 0.1 * noise.z;

    // Find the distance to the moon if it were 1 unit away, and its normal.
    float moon_dist = intersect_sphere(-moon_dir, ray_dir, moon_angular_radius).x;
    vec3 moon_normal = normalize(ray_dir * moon_dist - moon_dir);

	// Get light direction which orbits around moon
	float light_angle = 0.125 * tau * float(moonPhase);
	vec3 left_dir = normalize(cross(vec3(0.0, 1.0, 0.0), ray_dir));
	vec3 light_dir = cos(light_angle) * -ray_dir + sin(light_angle) * left_dir;
    float moon_shadow = dampen(max0(dot(moon_normal, light_dir)));

 	float edge_glow = sqr(sqr(sqr(dist)));

 	vec3 color = max(
		moon_shadow * lit_color * (1.5 + 1.5 * edge_glow),
		glow_color * (0.1 + 0.06 * edge_glow)
	) * (0.5 + 0.5 * moon_texture);

 	color = moon_luminance * sqr(color);
	return vec4(color, 1.0);
}

#if defined GALAXY

#if defined GALAXY_GAMS
	//#if !defined PROGRAM_DEFERRED0

// Galaxy from old Photon-GAMS

vec3 draw_galaxy(vec3 ray_dir, out float galaxy_luminance) {
	//const float galaxy_intensity = GALAXY_INTENSITY;
	const vec3 galaxy_tint = vec3(GALAXY_TINT_R, GALAXY_TINT_G, GALAXY_TINT_B) * GALAXY_INTENSITY;
	// Check if it's night time
	if (sun_dir.y > -0.05) return vec3(0.0); // Return black if it's not night
	mat3 rot = (sunAngle < 0.5)
	? mat3(shadowModelViewInverse)
	: mat3(-shadowModelViewInverse[0].xyz, shadowModelViewInverse[1].xyz, -shadowModelViewInverse[2].xyz);
	ray_dir *= rot;
	// Convert ray direction to spherical coordinates
	float phi = atan(ray_dir.y, ray_dir.x);
	float theta = acos(ray_dir.z);
	// Map spherical coordinates to UV coordinates
	vec2 uv = vec2(phi / (2.0 * pi) + 0.5, theta / pi);

	vec3 galaxy = from_srgb(texture(colortex13, uv).rgb);

	// Fade in/out at twilight
	float night_factor = smoothstep(0.0, -0.1, sun_dir.y);

	return galaxy * galaxy_tint * night_factor;
}

	//#else
		//vec3 draw_galaxy(vec3 ray_dir, out float galaxy_luminance) {
		//return vec3(0.0);
		//}
	//#endif

#else

// GALAXY from Photon

vec3 draw_galaxy(vec3 ray_dir, out float galaxy_luminance) {
	const vec3 galaxy_tint = vec3(GALAXY_TINT_R, GALAXY_TINT_G, GALAXY_TINT_B) * GALAXY_INTENSITY;

	float galaxy_intensity = 0.05 + 1.0 * linear_step(-0.1, 0.25, -sun_dir.y);

	float lon = atan(ray_dir.x, ray_dir.z);
	float lat = fast_acos(-ray_dir.y);

	vec3 galaxy = texture(
		galaxy_sampler,
		vec2(lon * rcp(tau) + 0.5, lat * rcp(pi))
	).rgb;

	galaxy = srgb_eotf_inv(galaxy) * rec709_to_working_color;

	galaxy *= 2 * galaxy_intensity * galaxy_tint;

	galaxy_luminance = dot(galaxy, luminance_weights_rec709);

	galaxy = mix(
		vec3(galaxy_luminance),
		galaxy,
		2.0
	);

	return max0(galaxy);
}
#endif

#endif

vec3 adjust_night_atmosphere(vec3 atmosphere, vec3 ray_dir) {
	#ifdef BLACK_NIGHT_SKY
	float night_factor = smoothstep(0.1, -0.1, sun_dir.y);
	float height_fade = smoothstep(-0.1, 0.3, ray_dir.y);

	float blue_hour = linear_step(0.05, 1.0, exp(-190.0 * sqr(sun_dir.y + 0.09604)));
	vec3 blue_hour_tint = vec3(0.95, 0.80, 1.0);
	vec3 blue_hour_sky = mix(atmosphere, atmosphere * blue_hour_tint, blue_hour);

	vec3 night_sky = mix(atmosphere * 0.1, vec3(0.0), height_fade);
	vec3 blended_sky = mix(blue_hour_sky, night_sky, night_factor);

	return mix(atmosphere, blended_sky, smoothstep(0.2, -0.2, sun_dir.y));
	#else
	return atmosphere;
	#endif
}

vec4 get_clouds_and_aurora(vec3 ray_dir, vec3 clear_sky) {
#if defined PROGRAM_DEFERRED0
	ivec2 texel   = ivec2(gl_FragCoord.xy);
	      texel.x = texel.x % (sky_map_res.x - 4);

	float dither = interleaved_gradient_noise(vec2(texel));

	// Render clouds
	#ifndef BLOCKY_CLOUDS
	const vec3 air_viewer_pos = vec3(0.0, planet_radius, 0.0);
	CloudsResult result = draw_clouds(air_viewer_pos, ray_dir, clear_sky, -1.0, dither);

	// Lightning flash
	result.scattering.rgb += LIGHTNING_FLASH_UNIFORM * lightning_flash_intensity * result.scattering.a;
	#else
	CloudsResult result = clouds_not_hit;
	#endif

	// Render aurora
	vec3 aurora = draw_aurora(ray_dir, dither);

	return vec4(
		result.scattering.xyz + aurora * result.transmittance,
		result.transmittance
	);
#else
	return vec4(0.0, 0.0, 0.0, 1.0);
#endif
}

vec3 draw_sky(vec3 ray_dir, vec3 atmosphere) {
	vec3 sky = vec3(0.0);

#if defined SHADOW
	// Trick to make stars rotate with sun and moon
	mat3 rot = (sunAngle < 0.5)
		? mat3(shadowModelViewInverse)
		: mat3(-shadowModelViewInverse[0].xyz, shadowModelViewInverse[1].xyz, -shadowModelViewInverse[2].xyz);

	vec3 celestial_dir = ray_dir * rot;
#else 
	vec3 celestial_dir = ray_dir;
#endif

	// Galaxy
#ifdef GALAXY
	float galaxy_luminance;
	sky += draw_galaxy(celestial_dir, galaxy_luminance);
#else
	const float galaxy_luminance = 0.0;
#endif

	// Sun, moon and stars

#if defined PROGRAM_DEFERRED4
	vec3 skytextured_output = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0).rgb;
	/*vec4 vanilla_sky = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0);
	vec3 vanilla_sky_color = from_srgb(vanilla_sky.rgb);
	uint vanilla_sky_id = uint(255.0 * vanilla_sky.a);*/
	// Output of skytextured
	sky += texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0).rgb;

#ifdef STARS
	// Stars
	float stars_visibility = clamp01(1.0 - dot(skytextured_output, vec3(0.33) * 256.0));
	sky += draw_stars(celestial_dir, galaxy_luminance) * stars_visibility;
#endif

	// Nebula
	sky = draw_nebula(ray_dir, sky);

#ifdef END_SUN_EFFECT
	#ifndef VANILLA_SUN
		// Sun
		sky += draw_sun(ray_dir);
	#endif
#endif
#endif

#ifndef VANILLA_MOON
    // Shader moon
    vec4 moon = draw_moon(ray_dir);
    sky *= 1.0 - moon.a;
    sky += moon.rgb;
#endif

	// Sky gradient
	atmosphere = adjust_night_atmosphere(atmosphere, ray_dir);
	sky *= atmosphere_transmittance(ray_dir.y, planet_radius) * (1.0 - rainStrength);
	sky += atmosphere;

	// Rain
	vec3 rain_sky = get_weather_color() * (1.0 - exp2(-0.8 / clamp01(ray_dir.y)));
	sky = mix(sky, rain_sky, rainStrength * mix(1.0, 0.9, time_sunrise + time_sunset));

	// Clouds
	vec4 clouds = get_clouds_and_aurora(ray_dir, sky);
	sky *= clouds.a;   // transmittance
	sky += clouds.rgb; // scattering

	// Shooting stars
#if defined SHOOTING_STARS && !defined PROGRAM_DEFERRED0
	sky = DrawShootingStars(sky, ray_dir);
#endif

#if !defined PROGRAM_DEFERRED0
	// Fade lower part of sky into cave fog color when underground so that the sky isn't visible
	// beyond the render distance
	float underground_sky_fade = biome_cave * smoothstep(-0.1, 0.1, 0.4 - ray_dir.y);
	sky = mix(sky, vec3(0.0), underground_sky_fade);
#endif

	return sky;
}

vec3 draw_sky(vec3 ray_dir) {
	
	vec3 atmosphere = atmosphere_scattering(ray_dir, sun_color, sun_dir, moon_color, moon_dir, true);
	return draw_sky(ray_dir, atmosphere);
}

//----------------------------------------------------------------------------//
#elif defined WORLD_NETHER

vec3 draw_sky(vec3 ray_dir) {
	return ambient_color;
}

//----------------------------------------------------------------------------//
#elif defined WORLD_END

#include "/include/misc/end_lighting_fix.glsl"
#include "/include/sky/atmosphere.glsl"
#include "/include/sky/stars.glsl"

const float sun_solid_angle = cone_angle_to_solid_angle(sun_angular_radius);
const vec3 end_sun_color = vec3(END_SOLAR_FLARE_COLOR_R, END_SOLAR_FLARE_COLOR_G, END_SOLAR_FLARE_COLOR_B);

vec3 draw_sun(vec3 ray_dir) {
	float nu = dot(ray_dir, sun_dir);
	float r = fast_acos(nu);

	// Sun disk

	const vec3 alpha = vec3(0.6, 0.5, 0.4);
	float center_to_edge = max0(sun_angular_radius - r);
	vec3 limb_darkening = pow(vec3(1.0 - sqr(1.0 - center_to_edge)), 0.5 * alpha);
	vec3 sun_disk = vec3(r < sun_angular_radius);

    // Solar flare effect

#ifdef END_SOLAR_FLARE_ENABLED

	// Transform the coordinate space such that z is parallel to sun_dir
    vec3 tangent = sun_dir.y == 11.0 ? vec3(1.0, 0.0, 0.0) : normalize(cross(vec3(1.0, 0.0, 0.0), sun_dir));
    vec3 bitangent = normalize(cross(tangent, sun_dir));
    mat3 rot = mat3(tangent, bitangent, sun_dir);

	// Vector from ray dir to sun dir
    vec2 q = ((ray_dir - sun_dir) * rot).xy;

    float theta = fract(linear_step(-pi, pi, atan(q.y, q.x)) + 0.015 * frameTimeCounter - 0.33 * r);

    float flare = texture(noisetex, vec2(theta, r - END_SOLAR_FLARE_SPEED * frameTimeCounter)).x;
          flare = pow5(flare) * exp(END_SOLAR_FLARE_FALLOFF * (r - sun_angular_radius));
          flare = r < sun_angular_radius ? 0.0 : flare;

    return end_sun_color * rcp(sun_solid_angle) * max0(sun_disk + END_SOLAR_FLARE_INTENSITY * flare);
#else
    return end_sun_color * rcp(sun_solid_angle) * sun_disk;
#endif
}

vec3 draw_sky(vec3 ray_dir) {

	// Sky gradient

	float up_gradient = linear_step(0.0, 0.4, ray_dir.y) + linear_step(0.1, 0.8, -ray_dir.y);
	vec3 sky = ambient_color * mix(0.1, 0.04, up_gradient);
	float mie_phase = cornette_shanks_phase(dot(ray_dir, sun_dir), 0.6);
	sky += 0.1 * (ambient_color + 0.5 * end_sun_color) * mie_phase;

#if defined PROGRAM_DEFERRED4
	// Sun

	sky += draw_sun(ray_dir);

	// Stars

	vec3 stars_fade = exp2(-0.1 * max0(1.0 - ray_dir.y) / max(ambient_color, eps)) * linear_step(-0.2, 0.0, ray_dir.y);
	sky += draw_stars(ray_dir, 0.0).xzy * stars_fade;
#endif

	return sky;
}

//----------------------------------------------------------------------------//
#elif defined WORLD_SPACE

vec3 draw_space_moon(vec3 ray_dir, vec3 color) {
	float nu = dot(ray_dir, moon_dir);

	// Limb darkening model from http://www.physics.hmc.edu/faculty/esin/a101/limbdarkening.pdf
	float center_to_edge = max0(sun_angular_radius - fast_acos(nu));
	float limb_darkening = pow(1.0 - sqr(1.0 - center_to_edge), 0.25);

	return color * step(0.0, center_to_edge) * limb_darkening;
}

vec3 draw_sky(vec3 ray_dir) {
	vec3 sky = vec3(0.0);

	// Sun and stars

#if defined PROGRAM_DEFERRED4
	// Output of skytextured
	vec3 skytextured_output = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0).rgb;
	sky += texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0).rgb;

#ifdef STARS
	// Stars
	float stars_visibility = clamp01(1.0 - dot(skytextured_output, vec3(0.33) * 64.0));
	sky += draw_stars(celestial_dir, galaxy_luminance) * stars_visibility;
#endif

#ifndef VANILLA_SUN
	// Sun
	sky += draw_sun(ray_dir);
#endif

	return sky;
}

#endif

#endif // INCLUDE_SKY_SKY
