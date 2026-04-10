#ifndef BENCHFFI_H
#define BENCHFFI_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct benchffi_handle benchffi_handle;

typedef struct {
  int bias;
  unsigned int scale;
  const char *label;
} benchffi_config;

typedef struct {
  size_t count;
  long long total;
  double mean;
  unsigned long checksum;
} benchffi_snapshot;

typedef struct {
  int code;
  const char *message;
} benchffi_status;

#define BENCHFFI_STATUS_OK 0
#define BENCHFFI_STATUS_INVALID_ARGUMENT 1

benchffi_handle *benchffi_open(const benchffi_config *config);
void benchffi_close(benchffi_handle *handle);
benchffi_status benchffi_push_i32(benchffi_handle *handle, const int *values, size_t len);
benchffi_snapshot benchffi_snapshot_read(const benchffi_handle *handle);
const char *benchffi_label(const benchffi_handle *handle);

#ifdef __cplusplus
}
#endif

#endif
