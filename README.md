lua-resty-r3
================

[libr3](https://github.com/c9s/r3) Lua-Openresty implementation.

**This repository is an experimental.**

## Install

### libr3

[See.](https://github.com/c9s/r3#install)

### lua-resty-r3

```
luarocks install https://raw.githubusercontent.com/membphis/lua-resty-r3/master/lua-resty-r3.rockspec
```

## SYNOPSYS

```nginx
 location = /t {
     content_by_lua_block {
         -- r3 router
         local r3router = require "resty.r3";
         local r = r3router.new() 

         local encode_json = require("cjson.safe").encode

         function foo(params) -- foo handler
             ngx.say("foo: ", encode_json(params))
         end
         function bar(params)
             ngx.say("bar: ", encode_json(params))
         end 

         -- routing
         r:get("/foo", bar)
         r:get("/foo/{id}/{name}", foo)
         r:post("/foo/{id}/{name}", bar) 

         -- don't forget!
         r:compile() 

         -- dispatch
         local ok = r:dispatch(ngx.req.get_method(), "/foo/a/b")
         if ok then
             ngx.say("hit")
         else
             ngx.say("not hit")
         end
     }
 }
```
