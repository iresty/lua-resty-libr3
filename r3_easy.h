#ifndef LUA_RESTY_R3_EASY_H
#define LUA_RESTY_R3_EASY_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdio.h>
#include <ctype.h>


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

void *easy_r3_create(int cap);
void easy_r3_free(void * tree);

void *easy_r3_insert(void *tree, int method, const char *path,
    int path_len, void *data, char **errstr);
int easy_r3_compile(void *tree, char** errstr);

void *easy_r3_match_entry_create(const char *path, int method);
void *easy_r3_match_route(const void *tree, void *entry);

void easy_r3_match_entry_free(void *entry);

#ifdef __cplusplus
}
#endif

#endif
