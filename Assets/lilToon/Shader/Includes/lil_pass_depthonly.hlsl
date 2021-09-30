#ifndef LIL_PASS_DEPTHONLY_INCLUDED
#define LIL_PASS_DEPTHONLY_INCLUDED

#include "Includes/lil_pipeline.hlsl"

//------------------------------------------------------------------------------------------------------------------------------
// Structure
#define LIL_V2F_POSITION_CS
#if defined(LIL_V2F_FORCE_UV0) || (LIL_RENDER > 0)
    #define LIL_V2F_TEXCOORD0
#endif
#if defined(LIL_V2F_FORCE_POSITION_OS) || ((LIL_RENDER > 0) && !defined(LIL_LITE) && !defined(LIL_FUR) && defined(LIL_FEATURE_DISSOLVE))
    #define LIL_V2F_POSITION_OS
#endif
#if defined(LIL_V2F_FORCE_NORMAL) || defined(WRITE_NORMAL_BUFFER)
    #define LIL_V2F_NORMAL_WS
#endif
#if defined(LIL_FUR)
    #define LIL_V2F_FURLAYER
#endif

struct v2f
{
    float4 positionCS   : SV_POSITION;
    #if defined(LIL_V2F_TEXCOORD0)
        float2 uv       : TEXCOORD0;
    #endif
    #if defined(LIL_V2F_POSITION_OS)
        float3 positionOS   : TEXCOORD1;
    #endif
    #if defined(LIL_V2F_NORMAL_WS)
        float3 normalWS         : TEXCOORD2;
    #endif
    #if defined(LIL_FUR)
        float furLayer          : TEXCOORD3;
    #endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

#if defined(LIL_FUR)
    #define LIL_V2G_TEXCOORD0
    #define LIL_V2G_POSITION_WS
    #if defined(LIL_V2G_FORCE_NORMAL_WS) || defined(WRITE_NORMAL_BUFFER)
        #define LIL_V2G_NORMAL_WS
    #endif
    #define LIL_V2G_FURVECTOR

    struct v2g
    {
        float3 positionWS   : TEXCOORD0;
        float2 uv           : TEXCOORD1;
        float3 furVector        : TEXCOORD2;
        #if defined(LIL_V2G_NORMAL_WS)
            float3 normalWS         : TEXCOORD3;
        #endif
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };
#elif defined(LIL_ONEPASS_OUTLINE)
    struct v2g
    {
        v2f base;
        float4 positionCSOL : TEXCOORD3;
    };
#endif

//------------------------------------------------------------------------------------------------------------------------------
// Shader
#if defined(LIL_FUR)
    #include "Includes/lil_common_vert_fur.hlsl"
#else
    #include "Includes/lil_common_vert.hlsl"
#endif
#include "Includes/lil_common_frag.hlsl"

#if defined(LIL_CUSTOM_V2F)
void frag(LIL_CUSTOM_V2F inputCustom
#else
void frag(v2f input
#endif
    LIL_VFACE(facing)
    #if defined(SCENESELECTIONPASS) || defined(SCENEPICKINGPASS) || !defined(LIL_HDRP)
    , out float4 outColor : SV_Target0
    #else
        #ifdef WRITE_MSAA_DEPTH
        , out float4 depthColor : SV_Target0
            #ifdef WRITE_NORMAL_BUFFER
            , out float4 outNormalBuffer : SV_Target1
            #endif
        #else
            #ifdef WRITE_NORMAL_BUFFER
            , out float4 outNormalBuffer : SV_Target0
            #endif
        #endif
    #endif
)
{
    #if defined(LIL_CUSTOM_V2F)
        v2f input = inputCustom.base;
    #endif
    LIL_VFACE_FALLBACK(facing);
    LIL_SETUP_INSTANCE_ID(input);
    LIL_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    #include "Includes/lil_common_frag_alpha.hlsl"

    #if !defined(LIL_HDRP)
        outColor = 0;
    #elif defined(SCENESELECTIONPASS)
        outColor = float4(_ObjectId, _PassValue, 1.0, 1.0);
    #elif defined(SCENEPICKINGPASS)
        outColor = _SelectionID;
    #else
        #ifdef WRITE_MSAA_DEPTH
            depthColor = input.positionCS.z;
            #ifdef _ALPHATOMASK_ON
                #if LIL_RENDER > 0
                    depthColor.a = saturate((alpha - _Cutoff) / max(fwidth(alpha), 0.0001) + 0.5);
                #else
                    depthColor.a = 1.0;
                #endif
            #endif
        #endif

        #if defined(WRITE_NORMAL_BUFFER)
            float3 normalDirection = normalize(input.normalWS);
            normalDirection = facing < (_FlipNormal-1.0) ? -normalDirection : normalDirection;

            const float seamThreshold = 1.0 / 1024.0;
            normalDirection.z = CopySign(max(seamThreshold, abs(normalDirection.z)), normalDirection.z);
            float2 octNormalWS = PackNormalOctQuadEncode(normalDirection);
            float3 packNormalWS = PackFloat2To888(saturate(octNormalWS * 0.5 + 0.5));
            outNormalBuffer = float4(packNormalWS, 1.0);
        #endif
    #endif
}

#if defined(LIL_TESSELLATION)
    #include "Includes/lil_tessellation.hlsl"
#endif

#endif