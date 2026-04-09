import ./c52_shared_types_helper

const
  RAW_AUDIO_KIND* = "audio"
  audioHelper = "private-audio"

proc openAudio*(id: cint): SharedHandle =
  SharedHandle(id: id)

proc audioKind*(): string =
  RAW_AUDIO_KIND

proc internalAudioHelper*(): string =
  audioHelper
