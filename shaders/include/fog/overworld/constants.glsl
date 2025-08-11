#if !defined INCLUDE_FOG_OVERWORLD_CONSTANTS
#define INCLUDE_FOG_OVERWORLD_CONSTANTS

const uint  air_fog_min_step_count    = AIR_FOG_MIN_STEPS; // 25  8
const uint  air_fog_max_step_count    = AIR_FOG_MAX_STEPS; // 50  25
const float air_fog_step_count_growth = AIR_FOG_STEP_GROWTH; //  0.1
const float air_fog_volume_top        = AIR_FOG_VOLUME_TOP; // 320.0
const float air_fog_volume_bottom     = SEA_LEVEL - 24.0;
const vec2  air_fog_falloff_start     = vec2(AIR_FOG_RAYLEIGH_FALLOFF_START, AIR_FOG_MIE_FALLOFF_START) + SEA_LEVEL;
const vec2  air_fog_falloff_half_life = vec2(AIR_FOG_RAYLEIGH_FALLOFF_HALF_LIFE, AIR_FOG_MIE_FALLOFF_HALF_LIFE);

#endif // INCLUDE_FOG_OVERWORLD_CONSTANTS
