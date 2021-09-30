#ifndef LIL_PASS_META_INCLUDED
#define LIL_PASS_META_INCLUDED

#define LIL_WITHOUT_ANIMATION
#include "Includes/lil_pipeline.hlsl"

#if defined(LIL_HDRP)
    CBUFFER_START(UnityMetaPass)
        bool4 unity_MetaVertexControl;
        bool4 unity_MetaFragmentControl;
        int unity_VisualizationMode;
    CBUFFER_END

    float unity_OneOverOutputBoost;
    float unity_MaxOutputValue;
    float unity_UseLinearSpace;
#endif

//------------------------------------------------------------------------------------------------------------------------------
// Structure
/*
#define LIL_V2F_POSITION_CS
#define LIL_V2F_TEXCOORD0
#define LIL_V2F_VIZUV
#define LIL_V2F_LIGHTCOORD

struct v2f
{
    float4 positionCS   : SV_POSITION;
    float2 uv           : TEXCOORD0;
    #if defined(EDITOR_VISUALIZATION) && !defined(LIL_HDRP)
        float2 vizUV        : TEXCOORD1;
        float4 lightCoord   : TEXCOORD2;
    #endif
    LIL_VERTEX_INPUT_INSTANCE_ID
    LIL_VERTEX_OUTPUT_STEREO
};
*/

// Match the main path for customization
#define LIL_V2F_POSITION_CS
#define LIL_V2F_TEXCOORD0
#if defined(LIL_V2F_FORCE_TEXCOORD1)
    #define LIL_V2F_TEXCOORD1
#endif
#if defined(LIL_V2F_FORCE_POSITION_OS)
    #define LIL_V2F_POSITION_OS
#endif
#if defined(LIL_V2F_FORCE_POSITION_WS)
    #define LIL_V2F_POSITION_WS
#endif
#if defined(LIL_V2F_FORCE_POSITION_SS)
    #define LIL_V2F_POSITION_SS
#endif
#if defined(LIL_V2F_FORCE_NORMAL)
    #define LIL_V2F_NORMAL_WS
#endif
#if defined(LIL_V2F_FORCE_TANGENT)
    #define LIL_V2F_TANGENT_WS
#endif
#if defined(LIL_V2F_FORCE_BITANGENT)
    #define LIL_V2F_BITANGENT_WS
#endif
#define LIL_V2F_VIZUV
#define LIL_V2F_LIGHTCOORD

struct v2f
{
    float4 positionCS       : SV_POSITION;
    float2 uv               : TEXCOORD0;
    #if defined(EDITOR_VISUALIZATION) && !defined(LIL_HDRP)
        float2 vizUV        : TEXCOORD1;
        float4 lightCoord   : TEXCOORD2;
    #endif
    #if defined(LIL_V2F_TEXCOORD1)
        float2 uv1          : TEXCOORD3;
    #endif
    #if defined(LIL_V2F_POSITION_OS)
        float3 positionOS       : TEXCOORD4;
    #endif
    #if defined(LIL_V2F_POSITION_WS)
        float3 positionWS       : TEXCOORD5;
    #endif
    #if defined(LIL_V2F_NORMAL_WS)
        float3 normalWS         : TEXCOORD6;
    #endif
    #if defined(LIL_V2F_TANGENT_WS)
        float4 tangentWS        : TEXCOORD7;
    #endif
    #if defined(LIL_V2F_BITANGENT_WS)
        float3 bitangentWS      : TEXCOORD8;
    #endif
    #if defined(LIL_V2F_POSITION_SS)
        float4 positionSS       : TEXCOORD9;
    #endif
    LIL_VERTEX_INPUT_INSTANCE_ID
    LIL_VERTEX_OUTPUT_STEREO
};

//------------------------------------------------------------------------------------------------------------------------------
// Shader
#include "Includes/lil_common_vert.hlsl"
#include "Includes/lil_common_frag.hlsl"

#if defined(LIL_CUSTOM_V2F)
float4 frag(LIL_CUSTOM_V2F inputCustom) : SV_Target
{
    v2f input = inputCustom.base;
#else
float4 frag(v2f input) : SV_Target
{
#endif
    BEFORE_ANIMATE_MAIN_UV
    OVERRIDE_ANIMATE_MAIN_UV

    float4 col = 1.0;
    BEFORE_MAIN
    OVERRIDE_MAIN
    float3 albedo = col.rgb;
    float3 invLighting = 1.0;
    float2 parallaxOffset = 0.0;
    float audioLinkValue = 1.0;
    #if defined(LIL_LITE)
        float4 triMask = 1.0;
        triMask = LIL_SAMPLE_2D(_TriMask, sampler_MainTex, uvMain);
    #endif

    #ifndef LIL_FUR
        BEFORE_EMISSION_1ST
        #if defined(LIL_FEATURE_EMISSION_1ST) || defined(LIL_LITE)
            OVERRIDE_EMISSION_1ST
        #endif
        #if !defined(LIL_LITE)
            BEFORE_EMISSION_1ST
            #if defined(LIL_FEATURE_EMISSION_2ND)
                OVERRIDE_EMISSION_2ND
            #endif
        #endif
    #endif

    #if defined(LIL_HDRP)
        if(!unity_MetaFragmentControl.y) col.rgb = clamp(pow(abs(albedo), saturate(unity_OneOverOutputBoost)), 0, unity_MaxOutputValue);
        return col;
    #else
        MetaInput metaInput;
        LIL_INITIALIZE_STRUCT(MetaInput, metaInput);
        metaInput.Albedo = albedo;
        metaInput.Emission = col.rgb;
        #ifdef EDITOR_VISUALIZATION
            metaInput.VizUV = input.vizUV;
            metaInput.LightCoord = input.lightCoord;
        #endif

        return MetaFragment(metaInput);
    #endif
}

#endif