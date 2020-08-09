//
//  MTIHighlightShadowFilter.metal
//  MetalPetal
//
//  Created by YuAo on 2020/8/9.
//

#include <metal_stdlib>
using namespace metal;

namespace metalpetalshadowhighlight {
    
    static float4 convertFromRGBToYIQ(float4 src) {
        float3 pix2;
        float4 pix = src;
        pix.xyz = sqrt(fmax(pix.xyz, 0.000000e+00f));
        pix2 = ((pix.x* float3(2.990000e-01f, 5.960000e-01f, 2.120000e-01f))+ (pix.y* float3(5.870000e-01f, -2.755000e-01f, -5.230000e-01f)))+ (pix.z* float3(1.140000e-01f, -3.210000e-01f, 3.110000e-01f));
        return float4(pix2, pix.w);
    }
    
    static float4 convertFromYIQToRGB(float4 src) {
        float4 color, pix;
        pix = src;
        color.xyz = ((pix.x* float3(1.000480e+00f, 9.998640e-01f, 9.994460e-01f))+ (pix.y* float3(9.555580e-01f, -2.715450e-01f, -1.108030e+00f)))+ (pix.z* float3(6.195490e-01f, -6.467860e-01f, 1.705420e+00f));
        color.xyz = fmax(color.xyz, float3(0.000000e+00f));
        color.xyz = color.xyz* color.xyz;
        color.w = pix.w;
        return color;
    }
    
    typedef struct {
        float4 position [[ position ]];
        float2 textureCoordinate;
    } MTIDefaultVertexOut;
    
    fragment float4 shadowHighlightAdjust(MTIDefaultVertexOut vertexIn [[stage_in]],
                                          texture2d<float, access::sample> sourceTexture [[texture(0)]],
                                          texture2d<float, access::sample> blurTexture [[texture(1)]],
                                          sampler sourceSampler [[sampler(0)]],
                                          sampler blurSampler [[sampler(1)]],
                                          constant float &shadow [[buffer(0)]],
                                          constant float &highlight [[buffer(1)]]) {
        float4 source = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
        float4 blur = blurTexture.sample(blurSampler, vertexIn.textureCoordinate);
        float4 sourceYIQ = convertFromRGBToYIQ(source);
        float4 blurYIQ = convertFromRGBToYIQ(blur);
        float highlights_sign_negated = copysign(1.0, -highlight);
        float shadows_sign = copysign(1.0f, shadow);
        //constexpr float whitepoint = 1.0;
        constexpr float compress = 0.5;
        constexpr float low_approximation = 0.01f;
        constexpr float shadowColor = 1.0;
        constexpr float highlightColor = 1.0;
        float tb0 = 1.0 - blurYIQ.x;
        if (tb0 < 1.0 - compress) {
            float highlights2 = highlight * highlight;
            float highlights_xform = min(1.0f - tb0 / (1.0f - compress), 1.0f);
            while (highlights2 > 0.0f) {
                float lref, href;
                float chunk, optrans;
                
                float la = sourceYIQ.x;
                float la_abs;
                float la_inverted = 1.0f - la;
                float la_inverted_abs;
                float lb = (tb0 - 0.5f) * highlights_sign_negated * sign(la_inverted) + 0.5f;
                
                la_abs = abs(la);
                lref = copysign(la_abs > low_approximation ? 1.0f / la_abs : 1.0f / low_approximation, la);
                
                la_inverted_abs = abs(la_inverted);
                href = copysign(la_inverted_abs > low_approximation ? 1.0f / la_inverted_abs : 1.0f / low_approximation, la_inverted);
                
                chunk = highlights2 > 1.0f ? 1.0f : highlights2;
                optrans = chunk * highlights_xform;
                highlights2 -= 1.0f;
                
                sourceYIQ.x = la * (1.0 - optrans) + (la > 0.5f ? 1.0f - (1.0f - 2.0f * (la - 0.5f)) * (1.0f - lb) : 2.0f * la * lb) * optrans;
                
                sourceYIQ.y = sourceYIQ.y * (1.0f - optrans)
                + sourceYIQ.y * (sourceYIQ.x * lref * (1.0f - highlightColor)
                                 + (1.0f - sourceYIQ.x) * href * highlightColor) * optrans;
                
                sourceYIQ.z = sourceYIQ.z * (1.0f - optrans)
                + sourceYIQ.z * (sourceYIQ.x * lref * (1.0f - highlightColor)
                                 + (1.0f - sourceYIQ.x) * href * highlightColor) * optrans;
            }
        }
        if (tb0 > compress) {
            float shadows2 = shadow * shadow;
            float shadows_xform = min(tb0 / (1.0f - compress) - compress / (1.0f - compress), 1.0f);
            
            while (shadows2 > 0.0f) {
                float lref, href;
                float chunk, optrans;
                
                float la = sourceYIQ.x;
                float la_abs;
                float la_inverted = 1.0f - la;
                float la_inverted_abs;
                float lb = (tb0 - 0.5f) * shadows_sign * sign(la_inverted) + 0.5f;
                
                la_abs = abs(la);
                lref = copysign(la_abs > low_approximation ? 1.0f / la_abs : 1.0f / low_approximation, la);
                
                la_inverted_abs = abs(la_inverted);
                href = copysign(la_inverted_abs > low_approximation ? 1.0f / la_inverted_abs : 1.0f / low_approximation,
                                la_inverted);
                
                chunk = shadows2 > 1.0f ? 1.0f : shadows2;
                optrans = chunk * shadows_xform;
                shadows2 -= 1.0f;
                
                sourceYIQ.x = la * (1.0 - optrans)
                + (la > 0.5f ? 1.0f - (1.0f - 2.0f * (la - 0.5f)) * (1.0f - lb) : 2.0f * la * lb) * optrans;
                
                sourceYIQ.y = sourceYIQ.y * (1.0f - optrans)
                + sourceYIQ.y * (sourceYIQ.x * lref * shadowColor
                                 + (1.0f - sourceYIQ.x) * href * (1.0f - shadowColor)) * optrans;
                
                sourceYIQ.z = sourceYIQ.z * (1.0f - optrans)
                + sourceYIQ.z * (sourceYIQ.x * lref * shadowColor
                                 + (1.0f - sourceYIQ.x) * href * (1.0f - shadowColor)) * optrans;
            }
        }
        return convertFromYIQToRGB(sourceYIQ);
    }
}
