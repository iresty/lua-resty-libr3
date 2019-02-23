lua-resty-r3
================

[libr3](https://github.com/c9s/r3) Lua-Openresty implementation.

**This repository is an experimental.**

## Install

### libr3

[See.](https://github.com/c9s/r3#install)

### lua-resty-r3

```
luarocks install https://raw.githubusercontent.com/toritori0318/lua-resty-r3/master/lua-resty-r3-dev-1.rockspec
```

## SYNOPSYS

### Pattern1

```lua
location / {
  content_by_lua '
    -- foo handler
    function foo(tokens, params)
      ngx.say("fooooooooooooooooooooooo")
      ngx.say("tokens:" .. table.concat(tokens, ","))
      for key, value in pairs(params) do
        ngx.say("param:" .. key .. "=" .. value)
      end
    end

    -- r3router
    local r3router = require "resty.r3";
    local r = r3router.new()
    -- routing
    r:get("/", function(tokens, params)
      ngx.say("hello r3!")
    end)
    r:get("/foo", foo)
    r:get("/foo/{id}/{name}", foo)
    r:post("/foo/{id}/{name}", foo)
    -- don\'t forget!
    r:compile()

    -- dispatcher
    local ok = r:dispatch_ngx()
    ---- or manual
    ---- local ok = r:dispatch("GET", "/foo/123/999", ngx.req.get_uri_args(), ngx.req.get_post_args())
    if ok then
      ngx.status = 200
    else
      ngx.status = 404
      ngx.print("Not found")
    end
  ';
}
```

### Pattern2

```lua
location / {
  content_by_lua '
    -- foo handler
    function foo(tokens, params)
      ngx.say("fooooooooooooooooooooooo")
      ngx.say("tokens:" .. table.concat(tokens, ","))
      for key, value in pairs(params) do
        ngx.say("param:" .. key .. "=" .. value)
      end
    end

    -- r3router
    local r3router = require "resty.r3";
    local r = r3router.new({
        {"GET",          "/",                function(t, p) ngx.say("hello r3!") end },
        {"GET",          "/foo",             foo},
        {{"GET","POST"}, "/foo/{id}/{name}", foo},
    })

    -- dispatcher
    local ok = r:dispatch_ngx()
    ---- or manual
    ---- local ok = r:dispatch("GET", "/foo/123/999", ngx.req.get_uri_args(), ngx.req.get_post_args())
    if ok then
      ngx.status = 200
    else
      ngx.status = 404
      ngx.print("Not found")
    end
  ';
}
```

## Docker Setup

```
cd /path/to/lua-resty-r3
docker run -p 89:80 -v "$(pwd)":/code -it toritori0318/lua-resty-r3 /opt/openresty/nginx/sbin/nginx
```
