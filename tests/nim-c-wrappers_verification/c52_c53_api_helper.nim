import ./c52_raw_audio_helper
import ./c52_raw_video_helper
import ./c52_shared_types_helper

export SharedHandle, openAudio, openVideo, audioKind, videoKind

proc openDefaultAudio*(): SharedHandle =
  openAudio(10)
