local ffi          = require "ffi"
local ffi_cast     = ffi.cast
local ffi_cdef     = ffi.cdef
local string_len   = string.len
local string_upper = string.upper
local table_insert = table.insert
local unpack = unpack or table.unpack

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
                                    .. 'librestydomainsuffix.so'
    error(table.concat(tried_paths, '\r\n', 1, #tried_paths))
end


ffi_cdef[[
  void * easy_r3_create(int cap);
  void easy_r3_free(void * tree);

  void * easy_r3_insert(void *tree, int method, const char *path,
      int path_len, void *data, char **errstr);
  int easy_r3_compile(void *tree, char** errstr);

  void *easy_r3_match_entry_create(const char *path, int method);
  void *easy_r3_match_route(void *tree, void *entry);
  void *easy_r3_fetch_var_slugs(void *entry, void *slugs, int max_len);
  void *easy_r3_fetch_var_slugs(void *entry, void *slugs, int max_len);

  void match_entry_free(match_entry *entry);
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

----------------------------------------------------------------
-- new
----------------------------------------------------------------
function _M.new(routes)
    local self = setmetatable({
      tree = r3.r3_tree_create(10),
      match_data_index = 0,
      match_data = {},
    }, mt)

    if not routes then return self end

    -- register routes
    for _, route in ipairs(routes) do
      local method = route[1]
      local bit_methods
      if type(method) ~= "table" then
        bit_methods = _METHODS[method]

      else
        local methods = {}
        for _, m in ipairs(method) do
          table_insert(methods, _METHODS[m])
        end
        bit_methods = bit.bor(unpack(methods))
      end

      local path    = route[2]
      local handler = route[3]
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
    return r3.r3_tree_compile(self.tree, nil)
end

function _M.dump(self, level)
    level = level or 0
    return r3.r3_tree_dump(self.tree, level)
end

function _M.tree_free(self)
    return r3.r3_tree_free(self.tree)
end

function _M.match_entry_free(self, entry)
    return r3.match_entry_free(entry)
end

function _M.insert_route(self, method, path, block)
    if not method or not path or not block then return end

    self.match_data_index = self.match_data_index + 1
    self.match_data[self.match_data_index] = block
    local dataptr = ffi_cast('void *', ffi_cast('intptr_t', self.match_data_index))

    -- route * r3_tree_insert_routel_ex(node *tree, int method, const char *path, int path_len, void *data, char **errstr);
    r3.r3_tree_insert_routel_ex(self.tree, method, path, string_len(path), dataptr, nil)
end

function _M.match_route(self, method, route, ...)
    local block
    local stokens={}

    local entry = r3.match_entry_createl(route, string_len(route))
    entry.request_method = method;

    local node = r3.r3_tree_match_route(self.tree, entry)
    if node == nil then
      self:match_entry_free(entry);
      return false
    end

    ngx.log(ngx.ERR, "match_route 0003")

    -- get match data from index
    local i = tonumber(ffi_cast('intptr_t', ffi_cast('void *', node.data)))

    ngx.log(ngx.ERR, "match_route 0004 ", i)
    block = self.match_data[i]
    ngx.log(ngx.ERR, "match_route 0005 ", tostring(block))

    -- token proc
    -- ngx.log(ngx.ERR, "match_route 0006 ", type(entry.vars.tokens.size))
    -- if entry and entry.vars and entry.vars.len then
    --   for i=0, entry.vars.len-1 do
    --     local token = ffi_string(entry.vars.tokens[i])
    --     ngx.log(ngx.ERR, "match_route 0006 ", token)

    --     table_insert(stokens, token)
    --   end
    -- end

    -- free
    r3.match_entry_free(entry)

    -- execute block
    block(stokens, ...)
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

function _M.dispatch_ngx(self)
  ngx.log(ngx.ERR, "hello 0000")
  local method = string_upper(ngx.var.request_method)
  local path = ngx.var.uri
  local params = {}
  local body = ""

  ngx.log(ngx.ERR, "hello 0001")

  if method == "GET" then
    params = ngx.req.get_uri_args()

  elseif method == "POST" then
    ngx.req.read_body()
    params = ngx.req.get_post_args()

  else
    ngx.req.read_body()
    body = ngx.req.get_body_data()
  end

  ngx.log(ngx.ERR, "hello 0002")

  return self:match_route(_METHODS[method], path, params, body)
end

return _M
