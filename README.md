Name
====
This is Lua-Openresty implementation library base on FFI for [libr3](https://github.com/c9s/r3).

[![Build Status](https://travis-ci.org/iresty/lua-resty-libr3.svg?branch=master)](https://travis-ci.org/iresty/lua-resty-libr3)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/iresty/lua-resty-libr3/blob/master/LICENSE)

Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Synopsys](#synopsys)
* [Methods](#methods)
    * [new](#new)
    * [add_router](#add_router)
    * [compile](#compile)
    * [dispatch](#dispatch)
    * [dispatch2](#dispatch2)
* [Install](#install)

Status
======

**This repository is an experimental.**

Synopsys
========

```lua
 location / {
     content_by_lua_block {
         -- r3 router
         local r3 = require("resty.r3").new();
         local encode_json = require("cjson.safe").encode

         function foo(params) -- foo handler
             ngx.say("foo: ", encode_json(params))
         end

         -- routing
         r3:get("/foo/{id}/{name}", foo)

         -- don't forget!!!
         r3:compile()

         -- dispatch
         local ok = r3:dispatch(ngx.req.get_method(), "/foo/a/b")
         if not ok then
             ngx.exit(404)
         end
     }
 }
```

[Back to TOC](#table-of-contents)

Methods
=======

new
---

`syntax: r3, err = r3router:new()`

Creates a r3 object. In case of failures, returns `nil` and a string describing the error.

`syntax: r3, err = r3router:new(routes)`

The routes is a array table, like `{ {...}, {...}, {...} }`.

    * methods: It's an array table, we can put one or more method names together. Here is the valid method name: "GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS".
    * uri: Client request uri.
    * handler: Lua callback function.

Example:

```lua
-- foo handler
function foo(params)
    ngx.say("foo: ", require("cjson").encode(params))
end

local r3route = require "resty.r3"
local r3 = r3route.new({
        {
            method = {"GET"},
            uri = [[/foo/{:\w+}/{:\w+}, host = "foo.com"]],
            handler = foo
        }
    })
```

[Back to TOC](#table-of-contents)


add_router
----------

We can add a router by specifying a lowercase method name.

Valid method name list: `get`, `post`, `put`, `delete`, `patch`, `head`, `options`.

```lua
-- route
local function foo(params)
    ngx.say("foo")
end

r3:get("/a", foo)
r3:post("/b", foo)
r3:put("/c", foo)
r3:delete("/d", foo)
```

`syntax: r3, err = r3:insert_route(uri, callback)`
`syntax: r3, err = r3:insert_route(method, uri, callback)`
`syntax: r3, err = r3:insert_route({uri=..., method=..., host=...}, callback)`

The option can be a Lua table.

* `method`: It's an array table, we can put one or more method names together.
* `uri`: Client request uri.
* `host`: Client request host name.
* `callback`: Lua callback function.

```lua
-- route
local function foo(params)
    ngx.say("foo")
end

r3:insert_route("/a", foo)
r3:insert_route({"GET", "POST"}, "/a", foo)
r3:insert_route({method = {"GET"}, uri = "/a"}, foo)
```

[Back to TOC](#table-of-contents)

compile
-------

`syntax: r3:compile()`

It compiles our route paths into a prefix tree (trie). You must compile after adding all routes, otherwise it may fail to match.

[Back to TOC](#table-of-contents)


dispatch
--------

`syntax: ok = r3:dispatch(uri, method)`
`syntax: ok = r3:dispatch(uri, opts)`

* `method`: method name of client request.
* `opts`: a Lua tale
    * `method`: method name of client request.
    * `host`: host name of client request.

Dispatchs the path to the controller by `method`, `uri` and `host`.

```lua
local ok = r3:dispatch(ngx.req.get_method(), ngx.var.uri)
```

[Back to TOC](#table-of-contents)

dispatch2
---------

`syntax: ok = r3:dispatch2(param_tab, uri, method)`
`syntax: ok = r3:dispatch2(param_tab, uri, opts)`

Basically the same as `dispatch`, support for passing in a `table` object to
store parsing parameters, makes it easier to reuse lua table.

[Back to TOC](#table-of-contents)

Install
=======

### Dependent library

```shell
# ubuntu
sudo apt-get install check libpcre3 libpcre3-dev build-essential libtool \
    automake autoconf pkg-config
```

### Compile and install

```
sudo make install
```
