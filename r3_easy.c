#include "r3/r3.h"
#include "r3_easy.h"


void *
easy_r3_create(int cap)
{
    R3Node *tree = r3_tree_create(cap);
    return (void *)tree;
}


void
easy_r3_free(void * tree)
{
    if (tree == NULL) {
        return;
    }

    r3_tree_free((R3Node *)tree);
}


void *
easy_r3_insert(void *tree, int method, const char *path,
               int path_len, void *data, char **errstr)
{
    R3Node *r3_tree = (R3Node *)tree;

    R3Route *router = r3_tree_insert_routel_ex(r3_tree, method, path, path_len,
                                               data, errstr);
    return (void *)router;
}


int
easy_r3_compile(void *tree, char** errstr)
{
    return r3_tree_compile((R3Node *)tree, errstr);
}


void *
easy_r3_match_entry_create(const char *path, int method)
{
    match_entry             *entry;

    entry = match_entry_create(path);
    entry->request_method = method;

    return (void *) entry;
}


void *
easy_r3_match_route(const void *tree, void *entry)
{
    R3Route                 *matched_route;

    matched_route = r3_tree_match_route((R3Node *)tree,
                                        (match_entry *)entry);
    return (void *)matched_route;
}


void *
easy_r3_match_route_fetch_idx(void *route)
{
    R3Route                 *matched_route = route;

    if (matched_route == NULL) {
        return NULL;
    }

    return (void *)matched_route->data;
}


size_t
easy_r3_match_entry_fetch_slugs(void *entry, size_t idx, char *val,
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
easy_r3_match_entry_fetch_tokens(void *entry, size_t idx, char *val,
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
easy_r3_match_entry_free(void *entry)
{
    if (entry == NULL)
        return;

    match_entry_free((match_entry *)entry);
    return;
}
