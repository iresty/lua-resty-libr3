local base = require "resty.core.base"
local str_buff = base.get_string_buf(256)
local buf_len_prt = base.get_size_ptr()
local new_tab = base.new_tab
local tonumber = tonumber

local ffi          = require "ffi"
local ffi_cast     = ffi.cast
local ffi_cdef     = ffi.cdef
local ffi_string   = ffi.string

local function load_shared_lib(so_name)
    local string_gmatch = string.gmatch
    local string_match = string.match
    local io_open = io.open
    local io_close = io.close
    local new_tab = require "table.new"

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

local r3, tried_paths = load_shared_lib("libr3.so")
if not r3 then
    tried_paths[#tried_paths + 1] = 'tried above paths but can not load '
                                    .. 'libr3.so'
    error(table.concat(tried_paths, '\r\n', 1, #tried_paths))
end


ffi_cdef[[
void *r3_create(int cap);
void r3_free(void * tree);

void *r3_insert(void *tree, int method, const char *path,
    int path_len, void *data, char **errstr);
int r3_compile(void *tree, char** errstr);

void *r3_match_entry_create(const char *path, int method);
void *r3_match_route(const void *tree, void *entry);
void *r3_match_route_fetch_idx(void *route);

int r3_match_entry_fetch_slugs(void *entry, size_t idx, char *val,
    size_t *val_len);
int r3_match_entry_fetch_tokens(void *entry, size_t idx, char *val,
    size_t *val_len);

void r3_match_entry_free(void *entry);
]]


local _M = { _VERSION = '0.01' }
local mt = { __index = _M }

local bit = require "bit"
local _METHOD_GET     = 2;
local _METHOD_POST    = bit.lshift(2,1);
local _METHOD_PUT     = bit.lshift(2,2);
local _METHOD_DELETE  = bit.lshift(2,3);
local _METHOD_PATCH   = bit.lshift(2,4);
local _METHOD_HEAD    = bit.lshift(2,5);
local _METHOD_OPTIONS = bit.lshift(2,6);

local _METHODS = {
  GET     = _METHOD_GET,
  POST    = _METHOD_POST,
  PUT     = _METHOD_PUT,
  DELETE  = _METHOD_DELETE,
  PATCH   = _METHOD_PATCH,
  HEAD    = _METHOD_HEAD,
  OPTIONS = _METHOD_OPTIONS,
}


function _M.new(routes)
    local route_n = routes and #routes or 10

    local self = setmetatable({
                                tree = r3.r3_create(route_n),
                                match_data_index = 0,
                                match_data = {},
                              }, mt)

    if not routes then return self end

    -- register routes
    for i = 1, route_n do
        local route = routes[i]

        local method  = route[1]
        local path    = route[2]
        local handler = route[3]

        local bit_methods
        if type(method) ~= "table" then
            bit_methods = _METHODS[method]

        else
            bit_methods = 0
            for _, m in ipairs(method) do
                bit_methods = bit.bor(bit_methods, _METHODS[m])
            end
        end

        -- register
        self:insert_route(bit_methods, path, handler)
    end

    -- compile
    if self.match_data_index > 0 then
      self:compile()
    end

    return self
end

function _M.compile(self)
    return r3.r3_compile(self.tree, nil)
end

function _M.tree_free(self)
    return r3.r3_free(self.tree)
end

function _M.r3_match_entry_free(self, entry)
    return r3.r3_match_entry_free(entry)
end

function _M.insert_route(self, method, path, block)
    if not method or not path or not block then return end

    self.match_data_index = self.match_data_index + 1
    self.match_data[self.match_data_index] = block
    local dataptr = ffi_cast('void *', ffi_cast('intptr_t', self.match_data_index))

    r3.r3_insert(self.tree, method, path, #path, dataptr, nil)
end

function _M.match_route(self, method, route, ...)
    local block
    local stokens={}

    local entry = r3.r3_match_entry_create(route, method)
    local match_route = r3.r3_match_route(self.tree, entry)
    if match_route == nil then
        self:r3_match_entry_free(entry);
        return false
    end

    local data_idx = r3.r3_match_route_fetch_idx(match_route)

    -- get match data from index
    local idx = tonumber(ffi_cast('intptr_t', ffi_cast('void *', data_idx)))
    block = self.match_data[idx]

    -- todo: fetch tokers and slugs information
    buf_len_prt[0] = 0
    local cnt = r3.r3_match_entry_fetch_slugs(entry, 0, nil, buf_len_prt)
    local params = new_tab(0, cnt)
    for i = 0, cnt - 1 do
        r3.r3_match_entry_fetch_slugs(entry, i, str_buff, buf_len_prt)
        local key = ffi_string(str_buff, buf_len_prt[0])

        r3.r3_match_entry_fetch_tokens(entry, i, str_buff, buf_len_prt)
        local val = ffi_string(str_buff, buf_len_prt[0])

        params[key] = val
    end

    -- free
    self:r3_match_entry_free(entry)

    -- execute block
    block(params, ...)
    return true
end

----------------------------------------------------------------
-- method
----------------------------------------------------------------
function _M.get(self, path, block)
    self:insert_route(_METHODS["GET"], path, block)
end


function _M.post(self, path, block)
    self:insert_route(_METHODS["POST"], path, block)
end


function _M.put(self, path, block)
    self:insert_route(_METHODS["PUT"], path, block)
end


function _M.delete(self, path, block)
    self:insert_route(_METHODS["DELETE"], path, block)
end

----------------------------------------------------------------
-- dispatcher
----------------------------------------------------------------
function _M.dispatch(self, method, path, ...)
    return self:match_route(_METHODS[method], path, ...)
end


return _M
