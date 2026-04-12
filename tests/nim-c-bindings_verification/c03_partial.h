#include <stdlib.h>

struct OpaqueOnly;

struct PartialStruct {
    int x;
    int y;
};

static inline struct PartialStruct *c03_new_partial_struct(int x, int y) {
    struct PartialStruct *p =
        (struct PartialStruct *)malloc(sizeof(struct PartialStruct));
    if (p == NULL) {
        return NULL;
    }
    p->x = x;
    p->y = y;
    return p;
}

static inline int c03_sum_partial_struct(const struct PartialStruct *p) {
    return p->x + p->y;
}

static inline int c03_is_null_opaque(const struct OpaqueOnly *p) {
    return p == NULL;
}

static inline void c03_free_partial_struct(struct PartialStruct *p) {
    free(p);
}
