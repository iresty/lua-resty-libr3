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
    * [insert_route](#insert_route)
    * [add router](#add-router)
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
         local ok = r3:dispatch("/foo/a/b", ngx.req.get_method())
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

The routes is a array table, like `{ {...}, {...}, {...} }`, Each element in the array is a route, which is a hash table.

The attributes of each element may contain these:
* `path`: client request uri.
* `handler`: Lua callback function.
* `host`: optional, client request host, not only supports normal domain name, but also supports wildcard name, both `foo.com` and `*.foo.com` are valid.
* `remote_addr`: optional, client remote address like `192.168.1.100`, and we can use CIDR format, eg `192.168.1.0/24`.
* `methods`: optional, It's an array table, we can put one or more method names together. Here is the valid method name: "GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS".


Example:

```lua
-- foo handler
function foo(params)
    ngx.say("foo: ", require("cjson").encode(params))
end

local r3route = require "resty.r3"
local r3 = r3route.new({
        {
            path = [[/foo/{:\w+}/{:\w+}"]],
            method = {"GET"},
            handler = foo
        },
        {
            path = [[/bar/{:\w+}/{:\w+}]],
            host = "*.bar.com",
            handler = foo
        },
        {
            path = [[/alice/{:\w+}/{:\w+}]],
            remote_addr = "192.168.1.0/24",
            handler = foo
        },
        {
            path = [[/bob/{:\w+}/{:\w+}]],
            method = {"GET"},
            host = "*.bob.com",
            remote_addr = "192.168.1.0/24",
            handler = foo
        },
    })
```

[Back to TOC](#table-of-contents)

insert_route
------------

`syntax: r3, err = r3:insert_route(path, callback, opts)`

* `path`: Client request uri.
* `callback`: Lua callback function.

`opts` is optional argument, it is a Lua table.
* `method`: It's an array table, we can put one or more method names together.
* `host`: optional, client request host, not only supports normal domain name, but also supports wildcard name, both `foo.com` and `*.foo.com` are valid.
* `remote_addr`: optional, client remote address like `192.168.1.100`, and we can use CIDR format, eg `192.168.1.0/24`.


```lua
-- route
local function foo(params)
    ngx.say("foo")
end

local r3route = require "resty.r3"
local r3 = r3route.new()

r3:insert_route("/a", foo)
r3:insert_route("/b", foo, {method = {"GET"}})
```

add router
----------

BTW, we can add a router by specifying a lowercase method name.

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

[Back to TOC](#table-of-contents)

compile
-------

`syntax: r3:compile()`

It compiles our route paths into a prefix tree (trie). You must compile after adding all routes, otherwise it may fail to match.

[Back to TOC](#table-of-contents)


dispatch
--------

`syntax: ok = r3:dispatch(path, method)`

* `path`: client request uri.
* `method`: method name of client request.

`syntax: ok = r3:dispatch(path, opts)`

* `path`: client request uri.
* `opts`: a Lua tale
    * `method`: optional, method name of client request.
    * `host`: optional, client request host, not only supports normal domain name, but also supports wildcard name, both `foo.com` and `*.foo.com` are valid.
    * `remote_addr`: optional, client remote address like `192.168.1.100`, and we can use CIDR format, eg `192.168.1.0/24`.

Dispatchs the path to the controller by `method`, `path` and `host`.

```lua
local ok = r3:dispatch(ngx.var.uri, ngx.req.get_method())
```

[Back to TOC](#table-of-contents)

dispatch2
---------

`syntax: ok = r3:dispatch2(param_tab, path, method)`

`syntax: ok = r3:dispatch2(param_tab, path, opts)`

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
