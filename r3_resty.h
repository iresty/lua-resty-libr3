#ifndef LUA_RESTY_R3_RESTY_H
#define LUA_RESTY_R3_RESTY_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdio.h>
#include <ctype.h>
#include "r3/include/r3.h"


#ifdef BUILDING_SO
    #ifndef __APPLE__
        #define LSH_EXPORT __attribute__ ((visibility ("protected")))
    #else
        /* OSX does not support protect-visibility */
        #define LSH_EXPORT __attribute__ ((visibility ("default")))
    #endif
#else
    #define LSH_EXPORT
#endif

/* **************************************************************************
 *
 *              Export Functions
 *
 * **************************************************************************
 */

void *r3_create(int cap);
void r3_free(void * tree);

void *r3_insert(void *tree, int method, const char *path,
    int path_len, void *data, char **errstr);
int r3_compile(void *tree, char** errstr);

int r3_route_set_attr(void *router, const char *host, const char *remote_addr,
    int remote_addr_bits);

int r3_route_attribute_free(void *router);


void *r3_match_entry_create(const char *path, int method, const char *host,
    const char *remote_addr);
void *r3_match_route(const void *tree, void *entry);

void *r3_match_route_fetch_idx(void *route);
size_t r3_match_entry_fetch_slugs(void *entry, size_t idx, char *val,
    size_t *val_len);
size_t r3_match_entry_fetch_tokens(void *entry, size_t idx, char *val,
    size_t *val_len);

void r3_match_entry_free(void *entry);

#ifdef __cplusplus
}
#endif

#endif
