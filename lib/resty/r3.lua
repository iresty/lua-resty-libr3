-- Copyright (C) Yuansheng Wang

local base        = require("resty.core.base")
local clear_tab   = require("table.clear")
local clone_tab   = require("table.clone")
local str_buff    = base.get_string_buf(256)
local buf_len_prt = base.get_size_ptr()
local new_tab     = base.new_tab
local find_str    = string.find
local tonumber    = tonumber
local ipairs      = ipairs
local ffi         = require "ffi"
local ffi_cast    = ffi.cast
local ffi_cdef    = ffi.cdef
local ffi_string  = ffi.string
local C           = ffi.C
local insert_tab  = table.insert
local string      = string
local io          = io
local package     = package
local getmetatable=getmetatable
local setmetatable=setmetatable
local ngx_log     = ngx.log
local ngx_ERR     = ngx.ERR
local type        = type
local error       = error
local newproxy    = _G.newproxy
local str_sub     = string.sub


local function load_shared_lib(so_name)
    local string_gmatch = string.gmatch
    local string_match = string.match
    local io_open = io.open
    local io_close = io.close

    local cpath = package.cpath
    local tried_paths = new_tab(32, 0)
    local i = 1

    for k, _ in string_gmatch(cpath, "[^;]+") do
        local fpath = string_match(k, "(.*/)")
        fpath = fpath .. so_name
        -- Don't get me wrong, the only way to know if a file exist is trying
        -- to open it.
        local f = io_open(fpath)
        if f ~= nil then
            io_close(f)
            return ffi.load(fpath)
        end
        tried_paths[i] = fpath
        i = i + 1
    end

    return nil, tried_paths
end


local lib_name = "libr3.so"
if ffi.os == "OSX" then
    lib_name = "libr3.dylib"
end


local r3, tried_paths = load_shared_lib(lib_name)
if not r3 then
    tried_paths[#tried_paths + 1] = 'tried above paths but can not load '
                                    .. lib_name
    error(table.concat(tried_paths, '\r\n', 1, #tried_paths))
end


ffi_cdef[[
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

int r3_match_entry_fetch_slugs(void *entry, size_t idx, char *val,
    size_t *val_len);
int r3_match_entry_fetch_tokens(void *entry, size_t idx, char *val,
    size_t *val_len);

void r3_match_entry_free(void *entry);

unsigned int inet_network(const char *cp);

void *ngx_create_pool(size_t size, void *log);
void ngx_destroy_pool(void *pool);
void *ngx_http_lua_pcre_malloc_init(void *pool);
void ngx_http_lua_pcre_malloc_done(void *old_pool);

extern void *ngx_cycle;

typedef struct {
    void            ****conf_ctx;
    void               *pool;
    void               *log;
} fake_ngx_cycle;

void *memcpy(void *dest, const void *src, size_t n);
]]


local fake_ngx_cycle = ffi.new("fake_ngx_cycle")
C.memcpy(fake_ngx_cycle, C.ngx_cycle, ffi.sizeof("fake_ngx_cycle"))


local _M = { _VERSION = '0.01' }


-- only work under lua51 or luajit
local function setmt__gc(t, mt)
    local prox = newproxy(true)
    getmetatable(prox).__gc = function() mt.__gc(t) end
    t[prox] = true
    return setmetatable(t, mt)
end


local function gc_free(self)
    -- if ngx.worker.exiting() then
    --     return
    -- end

    if self.pool then
        C.ngx_destroy_pool(self.pool)
        self.pool = nil
    end

    self:free()
end


local mt = { __index = _M, __gc = gc_free }


local bit = require "bit"
local _METHOD_GET     = 2
local _METHOD_POST    = bit.lshift(2,1)
local _METHOD_PUT     = bit.lshift(2,2)
local _METHOD_DELETE  = bit.lshift(2,3)
local _METHOD_PATCH   = bit.lshift(2,4)
local _METHOD_HEAD    = bit.lshift(2,5)
local _METHOD_OPTIONS = bit.lshift(2,6)


local _METHODS = {
  GET     = _METHOD_GET,
  POST    = _METHOD_POST,
  PUT     = _METHOD_PUT,
  DELETE  = _METHOD_DELETE,
  PATCH   = _METHOD_PATCH,
  HEAD    = _METHOD_HEAD,
  OPTIONS = _METHOD_OPTIONS,
}


local route_opts = {}
local function insert_route(self, opts)
    local method  = opts.method
    local path    = opts.path
    local host    = opts.host
    local handler = opts.handler
    local remote_addr = opts.remote_addr or "0.0.0.0"
    local remote_addr_bits = tonumber(opts.remote_addr_bits) or 0

    if type(path) ~= "string" then
        error("invalid argument path")
    end

    if type(handler) ~= "function" then
        error("invalid argument handler")
    end

    if not method or not path or not handler then
        return nil, "invalid argument of route"
    end

    insert_tab(self.cached_route_conf, clone_tab(opts))

    if not self.disable_path_cache_opt
       and not find_str(path, [[{]], 1, true) then
        local host_is_wildcard
        local host_wildcard
        if host and host:sub(1, 1) == '*' then
            host_is_wildcard = true
            host_wildcard = host:sub(2):reverse()
        end

        local path_cache = {
            bit_methods = method,
            host_is_wildcard = host_is_wildcard,
            host_wildcard = host_wildcard,
            host = host,
            remote_addr = r3.inet_network(remote_addr),
            remote_addr_bits = remote_addr_bits,
            handler = handler,
        }

        if not self.hash_path[path] then
            self.hash_path[path] = {path_cache}

        else
            insert_tab(self.hash_path[path], path_cache)
        end

        return true
    end

    self.match_data_index = self.match_data_index + 1
    self.match_data[self.match_data_index] = handler
    local dataptr = ffi_cast('void *',
                             ffi_cast('intptr_t', self.match_data_index))

    local r3_node = r3.r3_insert(self.tree, method, path, #path, dataptr, nil)
    local ret = r3.r3_route_set_attr(r3_node, host, remote_addr,
                                     remote_addr_bits)
    if ret == -1 then
        ngx_log(ngx_ERR, "failed to set the attribute for route")
    end

    insert_tab(self.r3_nodes, r3_node)
    return r3_node
end


function _M.new(routes, opts)
    local route_n = routes and #routes or 10
    local disable_path_cache_opt = opts and opts.disable_path_cache_opt

    local pool = C.ngx_create_pool(128, fake_ngx_cycle.log)     -- size: 128
    if not pool then
        error("failed to create single pool for r3 object")
    end

    local old_pool = C.ngx_http_lua_pcre_malloc_init(pool)

    local self = setmt__gc({
            pool = pool,
            old_pool = old_pool,
            tree = r3.r3_create(route_n),
            hash_path = new_tab(0, route_n),
            r3_nodes = new_tab(128, 0),
            match_data_index = 0,
            match_data = new_tab(route_n, 0),
            disable_path_cache_opt = disable_path_cache_opt,
            cached_route_conf = new_tab(128, 0),
        }, mt)

    if not routes then return self end

    -- register routes
    for i = 1, route_n do
        local route = routes[i]

        if type(route.path) ~= "string" then
            error("invalid argument path", 2)
        end

        if type(route.handler) ~= "function" then
            error("invalid argument handler", 2)
        end

        local method  = route.method
        local bit_methods
        if type(method) ~= "table" then
            bit_methods = method and _METHODS[method] or 0

        else
            bit_methods = 0
            for _, m in ipairs(method) do
                bit_methods = bit.bor(bit_methods, _METHODS[m])
            end
        end

        clear_tab(route_opts)
        route_opts.path    = route.path
        route_opts.handler = route.handler
        route_opts.method  = bit_methods
        route_opts.host    = route.host

        if route.remote_addr then
            local idx = find_str(route.remote_addr, "/", 1, true)
            if idx then
                route_opts.remote_addr  = str_sub(route.remote_addr, 1, idx - 1)
                route_opts.remote_addr_bits = str_sub(route.remote_addr,
                                                      idx + 1)

            else
                route_opts.remote_addr = route.remote_addr
                route_opts.remote_addr_bits = 32
            end
        end

        insert_route(self, route_opts)
    end

    return self
end


function _M.compile(self)
    local ret = r3.r3_compile(self.tree, nil)
    if self.old_pool then
        C.ngx_http_lua_pcre_malloc_done(self.old_pool)
        self.old_pool = nil
    end

    return ret
end


function _M.free(self)
    if not self.tree then
        return
    end

    r3.r3_free(self.tree)
    self.tree = nil

    for _, r3_node in ipairs(self.r3_nodes) do
        r3.r3_route_attribute_free(r3_node)
    end
end


local function match_route(self, path, opts, params, ...)
    local method = opts.method
    method = _METHODS[method] or 0

    local entry = r3.r3_match_entry_create(path, method, opts.host,
                                           opts.remote_addr)
    local matched_route = r3.r3_match_route(self.tree, entry)
    if matched_route == nil then
        r3.r3_match_entry_free(entry)
        return false
    end

    local data_idx = r3.r3_match_route_fetch_idx(matched_route)

    -- get match data from index
    local idx = tonumber(ffi_cast('intptr_t', ffi_cast('void *', data_idx)))
    local block = self.match_data[idx]

    if params then
        buf_len_prt[0] = 0
        local cnt = r3.r3_match_entry_fetch_slugs(entry, 0, nil, buf_len_prt)

        idx = 0
        for i = 0, cnt - 1 do
            r3.r3_match_entry_fetch_slugs(entry, i, str_buff, buf_len_prt)
            local key = ffi_string(str_buff, buf_len_prt[0])

            r3.r3_match_entry_fetch_tokens(entry, i, str_buff, buf_len_prt)
            local val = ffi_string(str_buff, buf_len_prt[0])

            if key == "" then
                idx = idx + 1
                params[idx] = val

            else
                params[key] = val
            end
        end
    end

    -- free
    r3.r3_match_entry_free(entry)

    -- execute block
    block(params, ...)
    return true
end

function _M.match_route(self, path, opts, ...)
    local params = new_tab(0, 4)
    return match_route(self, path, opts, params, ...)
end

----------------------------------------------------------------
-- method
----------------------------------------------------------------
for _, name in ipairs({"GET", "POST", "PUT", "DELETE", "PATCH", "HEAD",
                       "OPTIONS"}) do
    local l_name = string.lower(name)
    _M[l_name] = function (self, path, handler)
        if type(path) ~= "string" then
            error("invalid argument path")
        end

        if type(handler) ~= "function" then
            error("invalid argument handler")
        end

        clear_tab(route_opts)
        route_opts.method  = _METHODS[name]
        route_opts.path    = path
        route_opts.handler = handler
        return insert_route(self, route_opts)
    end
end


function _M.insert_route(self, path, handler, opts)
    -- method, path, handler
    if type(path) ~= "string" then
        error("invalid argument path", 2)
    end

    if type(handler) ~= "function" then
        error("invalid argument handler", 2)
    end

    if opts and type(handler) ~= "table" then
        error("invalid argument opts", 2)
    end

    local method
    local host
    local remote_addr
    local remote_addr_bits
    if opts then
        method = opts.method
        path   = opts.path
        host   = opts.host
        remote_addr      = opts.remote_addr
        remote_addr_bits = opts.remote_addr_bits
    end

    local bit_methods
    if type(method) ~= "table" then
        bit_methods = method and _METHODS[method] or 0

    else
        bit_methods = 0
        for _, m in ipairs(method) do
            bit_methods = bit.bor(bit_methods, _METHODS[m])
        end
    end

    clear_tab(route_opts)
    route_opts.path = path
    route_opts.handler = handler

    route_opts.method = bit_methods
    route_opts.host = host
    route_opts.remote_addr = remote_addr
    route_opts.remote_addr_bits = remote_addr_bits
    return insert_route(self, route_opts)
end


local function match_by_path_cache(route, params, opts, ...)
    local method = opts and opts.method
    if route.bit_methods ~= 0 and
        bit.band(route.bit_methods, _METHODS[method]) == 0 then
        return false
    end

    if route.host then
        if #route.host > #opts.host then
            return false
        end

        if route.host_is_wildcard then
            local i = opts.host:reverse():find(route.host_wildcard, 1, true)
            if i ~= 1 then
                return false
            end

        elseif route.host ~= opts.host then
            return false
        end
    end

    if route.remote_addr and route.remote_addr > 0 then
        local remote_addr_inet = r3.inet_network(opts.remote_addr)
        if bit.rshift(route.remote_addr, 32 - route.remote_addr_bits)
            ~= bit.rshift(remote_addr_inet, 32 - route.remote_addr_bits) then
            return false
        end
    end

    route.handler(params, ...)
    return true
end


local opts_method = {}
local function dispatch2(self, params, path, opts, ...)
    if not self.disable_path_cache_opt and self.hash_path[path] then
        for _, route in ipairs(self.hash_path[path]) do
            local ok = match_by_path_cache(route, params, opts, ...)
            if ok then
                return ok
            end
        end
    end

    return match_route(self, path, opts, params, ...)
end


function _M.dispatch2(self, params, path, method_or_opts, ...)
    if type(path) ~= "string" then
        error("invalid argument path", 2)
    end

    local opts = method_or_opts
    if not method_or_opts or type(method_or_opts) == "string" then
        clear_tab(opts_method)
        opts_method.method = method_or_opts
        opts = opts_method
    end

    local ok = dispatch2(self, params, path, opts, ...)
    return ok
end



function _M.dispatch(self, path, method_or_opts, ...)
    if type(path) ~= "string" then
        error("invalid argument path", 2)
    end

    -- use dispatch2 is better, avoid temporary table
    local opts = method_or_opts
    if not method_or_opts or type(method_or_opts) == "string" then
        clear_tab(opts_method)
        opts_method.method = method_or_opts
        opts = opts_method
    end

    local ok = dispatch2(self, {}, path, opts, ...)
    return ok
end


return _M
