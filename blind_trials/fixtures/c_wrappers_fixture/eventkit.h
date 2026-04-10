#ifndef EVENTKIT_H
#define EVENTKIT_H

#include "eventkit_types.h"

#ifdef __cplusplus
extern "C" {
#endif

eventkit_session *eventkit_open(const eventkit_config *config);
void eventkit_close(eventkit_session *session);
eventkit_result eventkit_install_sink(eventkit_session *session, eventkit_sink_fn sink,
                                      void *userdata);
eventkit_result eventkit_emit(eventkit_session *session, const char *topic,
                              const unsigned char *payload, size_t len);
eventkit_stats eventkit_snapshot(const eventkit_session *session);
const char *eventkit_last_error(const eventkit_session *session);

#ifdef __cplusplus
}
#endif

#endif
