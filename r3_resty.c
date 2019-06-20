#include <netinet/in.h>
#include <arpa/inet.h>
#include "r3_resty.h"


void *
r3_create(int cap)
{
    R3Node *tree = r3_tree_create(cap);
    return (void *)tree;
}


void
r3_free(void * tree)
{
    if (tree == NULL) {
        return;
    }

    r3_tree_free((R3Node *)tree);
}


void *
r3_insert(void *tree, int method, const char *path,
               int path_len, void *data, char **errstr)
{
    R3Node *r3_tree = (R3Node *)tree;

    R3Route *route = r3_tree_insert_routel_ex(r3_tree, method, path, path_len,
                                              data, errstr);
    return (void *)route;
}

int
r3_route_set_attr(void *router, const char *host, const char *remote_addr,
    int remote_addr_bits)
{
    R3Route *r3_router = (R3Route *)router;
    if (r3_router->host.base) {
        return -1;
    }

    if (host) {
        r3_router->host.len = strlen(host);
        char *host_buf = r3_mem_alloc(r3_router->host.len);
        memcpy(host_buf, host, r3_router->host.len);
        r3_router->host.base = host_buf;
    }

    if (remote_addr_bits == 0) {
        r3_router->remote_addr_v4_bits = 0;
        r3_router->remote_addr_v4 = 0;

    } else {
        r3_router->remote_addr_v4_bits = remote_addr_bits;
        r3_router->remote_addr_v4 = inet_network(remote_addr);
    }

    // fprintf(stderr, "addr: %u bits: %d\n", r3_router->remote_addr_v4,
    //         r3_router->remote_addr_v4_bits);
    return 0;
}

int
r3_route_attribute_free(void *router)
{
    R3Route *r3_router = (R3Route *)router;
    if (!r3_router->host.base) {
        return 0;
    }

    free((void *)r3_router->host.base);
    r3_router->host.base = NULL;
    r3_router->host.len = 0;
    return 0;
}


int
r3_compile(void *tree, char** errstr)
{
    return r3_tree_compile((R3Node *)tree, errstr);
}


void *
r3_match_entry_create(const char *path, int method, const char *host)
{
    match_entry             *entry;

    entry = match_entry_create(path);
    entry->request_method = method;

    if (host) {
        entry->host.base = host;
        entry->host.len = strlen(host);
    }

    return (void *) entry;
}


void *
r3_match_route(const void *tree, void *entry)
{
    R3Route                 *matched_route;

    matched_route = r3_tree_match_route((R3Node *)tree,
                                        (match_entry *)entry);
    return (void *)matched_route;
}


void *
r3_match_route_fetch_idx(void *route)
{
    R3Route                 *matched_route = route;

    if (matched_route == NULL) {
        return NULL;
    }

    return (void *)matched_route->data;
}


size_t
r3_match_entry_fetch_slugs(void *entry, size_t idx, char *val,
                                size_t *val_len)
{
    match_entry             *m_entry = entry;
    int                      i;

    if (val ==  NULL) {
        return m_entry->vars.slugs.size;
    }

    if (idx >= m_entry->vars.slugs.size) {
        return -1;
    }

    i = m_entry->vars.slugs.entries[idx].len;
    *val_len = i;

    sprintf(val, "%*.*s", i, i, m_entry->vars.slugs.entries[idx].base);
    return m_entry->vars.slugs.size;
}


size_t
r3_match_entry_fetch_tokens(void *entry, size_t idx, char *val,
                                 size_t *val_len)
{
    match_entry             *m_entry = entry;
    int                      i_len;

    if (val ==  NULL) {
        return m_entry->vars.tokens.size;
    }

    if (idx >= m_entry->vars.tokens.size) {
        return -1;
    }

    i_len = m_entry->vars.tokens.entries[idx].len;
    *val_len = i_len;

    sprintf(val, "%*.*s", i_len, i_len, m_entry->vars.tokens.entries[idx].base);
    return m_entry->vars.tokens.size;
}


void
r3_match_entry_free(void *entry)
{
    match_entry    *r3_entry = (match_entry *)entry;

    if (entry == NULL) {
        return;
    }

    match_entry_free(r3_entry);
    return;
}
