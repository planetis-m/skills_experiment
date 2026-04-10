#include "benchffi.h"

#include <stdlib.h>
#include <string.h>

struct benchffi_handle {
  int bias;
  unsigned int scale;
  char *label;
  size_t count;
  long long total;
  unsigned long checksum;
};

static benchffi_status benchffi_ok(void) {
  benchffi_status status;
  status.code = BENCHFFI_STATUS_OK;
  status.message = "ok";
  return status;
}

static benchffi_status benchffi_invalid(const char *message) {
  benchffi_status status;
  status.code = BENCHFFI_STATUS_INVALID_ARGUMENT;
  status.message = message;
  return status;
}

benchffi_handle *benchffi_open(const benchffi_config *config) {
  benchffi_handle *handle;
  size_t label_len;

  if (config == NULL || config->label == NULL || config->scale == 0) {
    return NULL;
  }

  handle = (benchffi_handle *)calloc(1, sizeof(*handle));
  if (handle == NULL) {
    return NULL;
  }

  handle->bias = config->bias;
  handle->scale = config->scale;
  label_len = strlen(config->label);
  handle->label = (char *)malloc(label_len + 1);
  if (handle->label == NULL) {
    free(handle);
    return NULL;
  }

  memcpy(handle->label, config->label, label_len + 1);
  return handle;
}

void benchffi_close(benchffi_handle *handle) {
  if (handle == NULL) {
    return;
  }

  free(handle->label);
  free(handle);
}

benchffi_status benchffi_push_i32(benchffi_handle *handle, const int *values, size_t len) {
  size_t i;

  if (handle == NULL || values == NULL || len == 0) {
    return benchffi_invalid("invalid arguments");
  }

  for (i = 0; i < len; ++i) {
    long long adjusted = ((long long)values[i] + (long long)handle->bias) * (long long)handle->scale;
    handle->total += adjusted;
    handle->checksum = handle->checksum * 131UL + (unsigned long)adjusted;
  }

  handle->count += len;
  return benchffi_ok();
}

benchffi_snapshot benchffi_snapshot_read(const benchffi_handle *handle) {
  benchffi_snapshot snapshot;

  snapshot.count = 0;
  snapshot.total = 0;
  snapshot.mean = 0.0;
  snapshot.checksum = 0;

  if (handle == NULL) {
    return snapshot;
  }

  snapshot.count = handle->count;
  snapshot.total = handle->total;
  snapshot.mean = handle->count == 0 ? 0.0 : (double)handle->total / (double)handle->count;
  snapshot.checksum = handle->checksum;
  return snapshot;
}

const char *benchffi_label(const benchffi_handle *handle) {
  if (handle == NULL || handle->label == NULL) {
    return "";
  }

  return handle->label;
}
