#include "eventkit.h"

#include <stdlib.h>
#include <string.h>

struct eventkit_session {
  size_t topic_limit;
  char *prefix;
  eventkit_sink_fn sink;
  void *userdata;
  size_t emitted;
  size_t dropped;
  char last_error[96];
};

static eventkit_result eventkit_ok(void) {
  eventkit_result result;
  result.code = EVENTKIT_OK;
  result.message = "ok";
  return result;
}

static eventkit_result eventkit_fail(eventkit_session *session, eventkit_code code,
                                     const char *message) {
  eventkit_result result;
  result.code = code;

  if (session != NULL) {
    size_t len = strlen(message);
    if (len >= sizeof(session->last_error)) {
      len = sizeof(session->last_error) - 1;
    }
    memcpy(session->last_error, message, len);
    session->last_error[len] = '\0';
    result.message = session->last_error;
  } else {
    result.message = message;
  }

  return result;
}

eventkit_session *eventkit_open(const eventkit_config *config) {
  eventkit_session *session;
  size_t prefix_len;

  if (config == NULL || config->prefix == NULL || config->topic_limit == 0) {
    return NULL;
  }

  session = (eventkit_session *)calloc(1, sizeof(*session));
  if (session == NULL) {
    return NULL;
  }

  prefix_len = strlen(config->prefix);
  session->prefix = (char *)malloc(prefix_len + 1);
  if (session->prefix == NULL) {
    free(session);
    return NULL;
  }

  memcpy(session->prefix, config->prefix, prefix_len + 1);
  session->topic_limit = config->topic_limit;
  session->last_error[0] = '\0';
  return session;
}

void eventkit_close(eventkit_session *session) {
  if (session == NULL) {
    return;
  }

  free(session->prefix);
  free(session);
}

eventkit_result eventkit_install_sink(eventkit_session *session, eventkit_sink_fn sink,
                                      void *userdata) {
  if (session == NULL || sink == NULL) {
    return eventkit_fail(session, EVENTKIT_BAD_ARGUMENT, "invalid sink");
  }

  session->sink = sink;
  session->userdata = userdata;
  return eventkit_ok();
}

eventkit_result eventkit_emit(eventkit_session *session, const char *topic,
                              const unsigned char *payload, size_t len) {
  char *full_topic;
  size_t prefix_len;
  size_t topic_len;

  if (session == NULL || topic == NULL || payload == NULL) {
    return eventkit_fail(session, EVENTKIT_BAD_ARGUMENT, "invalid emit arguments");
  }

  if (session->sink == NULL) {
    session->dropped += 1;
    return eventkit_fail(session, EVENTKIT_NO_SINK, "no sink installed");
  }

  topic_len = strlen(topic);
  if (topic_len > session->topic_limit) {
    session->dropped += 1;
    return eventkit_fail(session, EVENTKIT_TOPIC_TOO_LONG, "topic too long");
  }

  prefix_len = strlen(session->prefix);
  full_topic = (char *)malloc(prefix_len + 1 + topic_len + 1);
  if (full_topic == NULL) {
    session->dropped += 1;
    return eventkit_fail(session, EVENTKIT_BAD_ARGUMENT, "allocation failed");
  }

  memcpy(full_topic, session->prefix, prefix_len);
  full_topic[prefix_len] = '/';
  memcpy(full_topic + prefix_len + 1, topic, topic_len + 1);

  session->sink(full_topic, payload, len, session->userdata);
  session->emitted += 1;
  free(full_topic);
  return eventkit_ok();
}

eventkit_stats eventkit_snapshot(const eventkit_session *session) {
  eventkit_stats stats;
  stats.emitted = 0;
  stats.dropped = 0;

  if (session == NULL) {
    return stats;
  }

  stats.emitted = session->emitted;
  stats.dropped = session->dropped;
  return stats;
}

const char *eventkit_last_error(const eventkit_session *session) {
  if (session == NULL || session->last_error[0] == '\0') {
    return "";
  }

  return session->last_error;
}
