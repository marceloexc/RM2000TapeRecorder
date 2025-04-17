// https://stackoverflow.com/a/79176991
#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 dotMatrix(float2 position, half4 color) {
	if (int(position.x) % 2 < 2 && int(position.y) % 4 < 2) {
		return color;
	} else {
		return half4(0, 0, 0, 0);
	}
}
