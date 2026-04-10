#ifndef EVENTKIT_TYPES_H
#define EVENTKIT_TYPES_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct eventkit_session eventkit_session;

typedef int eventkit_code;

typedef void (*eventkit_sink_fn)(const char *topic, const unsigned char *payload,
                                 size_t len, void *userdata);

typedef struct {
  size_t topic_limit;
  const char *prefix;
} eventkit_config;

typedef struct {
  size_t emitted;
  size_t dropped;
} eventkit_stats;

typedef struct {
  eventkit_code code;
  const char *message;
} eventkit_result;

#define EVENTKIT_OK 0
#define EVENTKIT_NO_SINK 1
#define EVENTKIT_TOPIC_TOO_LONG 2
#define EVENTKIT_BAD_ARGUMENT 3

#ifdef __cplusplus
}
#endif

#endif
