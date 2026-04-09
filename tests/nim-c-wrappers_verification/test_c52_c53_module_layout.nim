# Test C52, C53: central shared-types module plus selective re-exported API surface.
import ./c52_c53_api_helper

let audio = openDefaultAudio()
let video = openVideo(20)

doAssert audio.id == 10
doAssert video.id == 20
doAssert audioKind() == "audio"
doAssert videoKind() == "video"

echo "C52_C53: PASS"
