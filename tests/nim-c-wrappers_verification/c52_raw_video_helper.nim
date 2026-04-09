import ./c52_shared_types_helper

const RAW_VIDEO_KIND = "video"

proc openVideo*(id: cint): SharedHandle =
  SharedHandle(id: id)

proc videoKind*(): string =
  RAW_VIDEO_KIND
