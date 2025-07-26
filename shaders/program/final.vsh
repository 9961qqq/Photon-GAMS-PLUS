/*
--------------------------------------------------------------------------------

  Photon Shader by SixthSurge

  program/program/final.glsl:
  CAS, dithering, debug views

--------------------------------------------------------------------------------
*/

#include "/include/global.glsl"

#ifdef LENS_FLARE
uniform mat4 gbufferModelView;
uniform vec3 sunPosition;
#endif

out vec2 uv;

#ifdef LENS_FLARE
flat out vec3 upVec, sunVec;
#endif

void main() {
	uv = gl_MultiTexCoord0.xy;

#ifdef LENS_FLARE
  upVec = normalize(gbufferModelView[1].xyz);
  sunVec = normalize(sunPosition);
#endif

	gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0.0, 1.0);
}