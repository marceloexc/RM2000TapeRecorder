#include <SwiftUI/SwiftUI_Metal.h>
#include <metal_stdlib>
using namespace metal;

[[ stitchable ]]
half4 randomNoise(float2 position, half4 color, float time) {
  float value = fract(sin(dot(position + time, float2(12.9898, 78.233))) * 43758.5453);
  return half4(value, value, value, 1) * color.a;
}
