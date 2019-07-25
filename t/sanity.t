# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::R3 'no_plan';

run_tests();

__DATA__

=== TEST 1: sanity
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("cjson").encode(params))
            end
            local function bar(params)
                ngx.say("bar: ", require("cjson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new()

            -- insert route
            r:get("/", function(params)
                ngx.say("hello r3!")
            end)

            r:get("/foo", bar)
            r:get("/foo/{id}/{name}", foo)
            r:post("/foo/{id}/{name}", bar)

            -- don't forget!
            r:compile()

            local ok = r:dispatch(ngx.var.uri, ngx.req.get_method())
            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end
        }
    }
--- request
GET /foo/a/b
--- no_error_log
[error]
--- response_body
foo: {"name":"b","id":"a"}
hit



=== TEST 2: anonymous variable
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("cjson").encode(params))
            end
            local function bar(params)
                ngx.say("bar: ", require("cjson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new()

            -- insert route
            r:get("/", function(params)
                ngx.say("hello r3!")
            end)

            r:get("/foo", bar)
            r:get([[/foo/{:\w+}/{:\w+}]], foo)

            r:compile()

            local ok = r:dispatch(ngx.var.uri, ngx.req.get_method())
            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end
        }
    }
--- request
GET /foo/idv/namev
--- no_error_log
[error]
--- response_body
foo: ["idv","namev"]
hit



=== TEST 3: create r3 object with arguments
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("cjson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {method = {"GET"}, path = [[/foo/{:\w+}/{:\w+}]], handler = foo}
            })

            r:compile()

            local ok = r:dispatch(ngx.var.uri, ngx.req.get_method())
            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end
        }
    }
--- request
GET /foo/idv/namev
--- no_error_log
[error]
--- response_body
foo: ["idv","namev"]
hit



=== TEST 4: create r3 object with arguments
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("cjson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {path = [[/foo/{:\w+}/{:\w+}]], handler = foo}
            })

            -- don't forget!
            r:compile()

            local ok = r:dispatch(ngx.var.uri, ngx.req.get_method())
            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end
        }
    }
--- request
GET /foo/idv/namev
--- no_error_log
[error]
--- response_body
foo: ["idv","namev"]
hit



=== TEST 5: insert router
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("cjson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new()

            r:insert_route([[/foo/{:\w+}/{:\w+}]], foo)

            -- don't forget!
            r:compile()

            local ok = r:dispatch(ngx.var.uri, ngx.req.get_method())
            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end
        }
    }
--- request
GET /foo/idv/namev
--- no_error_log
[error]
--- response_body
foo: ["idv","namev"]
hit



=== TEST 6: free
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("cjson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new()

            r:free()
            r:free()  -- double free

            ngx.say("all done")
        }
    }
--- request
GET /foo/idv/namev
--- no_error_log
[error]
--- response_body
all done



=== TEST 7: no pattern
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("cjson").encode(params))
            end
            local function bar(params)
                ngx.say("bar: ", require("cjson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new()

            -- insert route
            r:get("/foo", foo)
            r:get("/bar", bar)

            r:compile()

            local ok = r:dispatch(ngx.var.uri, ngx.req.get_method())
            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end

            ok = r:dispatch("/bar", ngx.req.get_method())
            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end
        }
    }
--- request
GET /foo
--- no_error_log
[error]
--- response_body
foo: {}
hit
bar: {}
hit



=== TEST 8: method dispatch2, specified a table to store the parameter
--- config
    location /t {
        content_by_lua_block {
            -- foo handler
            local bar_param_tab
            local function bar(params)
                bar_param_tab = params
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {method = {"GET"}, path = "/bar", handler = bar}
            })

            r:compile()

            local param_tab = {}
            local ok = r:dispatch2(param_tab, "/bar", ngx.req.get_method())
            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end

            ngx.say("passed parameter table: ", param_tab == bar_param_tab)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
hit
passed parameter table: true



=== TEST 9: multiple routes: same uri, different method
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function post(params)
                ngx.say("post: ", require("cjson").encode(params))
            end
            local function get(params)
                ngx.say("get: ", require("cjson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new()

            -- insert route
            r:post("/foo", post)
            r:get("/foo", get)

            r:compile()

            local ok = r:dispatch("/foo", "GET")
            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end

            ok = r:dispatch("/foo", "POST")
            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end

            ok = r:dispatch("/foo", "PUT")
            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end
        }
    }
--- request
GET /foo
--- no_error_log
[error]
--- response_body
get: {}
hit
post: {}
hit
not hit



=== TEST 10: no method in dispatch
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("cjson").encode(params))
            end
            local function bar(params)
                ngx.say("bar: ", require("cjson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new()

            -- insert route
            r:get("/", function(params)
                ngx.say("hello r3!")
            end)

            r:get("/foo", bar)
            r:get("/foo/{id}/{name}", foo)
            r:post("/foo/{id}/{name}", bar)

            -- don't forget!
            r:compile()

            local ok = r:dispatch(ngx.var.uri)
            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end

            local ok = r:dispatch2(nil, ngx.var.uri)
            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end
        }
    }
--- request
GET /foo/a/b
--- no_error_log
[error]
--- response_body
foo: {"name":"b","id":"a"}
hit
foo: null
hit



=== TEST 11: dispatch: invalid path
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("cjson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new()

            r:get("/foo", foo)

            -- don't forget!
            r:compile()

            r:dispatch(nil)
        }
    }
--- request
GET /foo/a/b
--- error_code: 500
--- error_log
invalid argument path



=== TEST 12: dispatch: invalid path
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("cjson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new()

            r:get("/foo", foo)

            -- don't forget!
            r:compile()

            r:dispatch2({}, nil)
        }
    }
--- request
GET /foo/a/b
--- error_code: 500
--- error_log
invalid argument path



=== TEST 13: new: invalid path
--- config
    location /foo {
        content_by_lua_block {
            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {method = {"GET"}, path = nil, handler = foo}
            })

            r:get("/foo", bar)
        }
    }
--- request
GET /foo/a/b
--- error_code: 500
--- error_log
invalid argument path



=== TEST 14: insert route: invalid path
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("cjson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {method = {"GET"}, path = "/foo", handler = foo}
            })

            r:get(nil, bar)
        }
    }
--- request
GET /foo/a/b
--- error_code: 500
--- error_log
invalid argument path



=== TEST 15: new: invalid hanlder
--- config
    location /foo {
        content_by_lua_block {
            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {method = {"GET"}, path = "/foo", handler = nil}
            })

            r:get("/foo", bar)
        }
    }
--- request
GET /foo/a/b
--- error_code: 500
--- error_log
invalid argument handler



=== TEST 16: new: invalid hanlder
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("cjson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {method = {"GET"}, path = "/foo", handler = foo}
            })

            r:get("/foo", nil)
        }
    }
--- request
GET /foo/a/b
--- error_code: 500
--- error_log
invalid argument handler



=== TEST 17: any uri
--- config
    location /foo {
        content_by_lua_block {
            local function bar(params)
                ngx.say("bar: ", require("cjson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new()

            -- insert route
            r:get("{:.*}", function(params)
                ngx.say("hello r3!")
            end)

            r:get("/foo", bar)

            -- don't forget!
            r:compile()

            for i = 1, 3 do
                local ok = r:dispatch(ngx.var.uri, ngx.req.get_method())
                if ok then
                    ngx.say("hit")
                else
                    ngx.say("not hit")
                end
            end

            local ok = r:dispatch("/", ngx.req.get_method())
            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end
        }
    }
--- request
GET /foo/a/b
--- no_error_log
[error]
--- response_body
hello r3!
hit
hello r3!
hit
hello r3!
hit
hello r3!
hit



=== TEST 18: use `/foo{:/?}` both to match `/foo` and `/foo/`
--- config
    location /t {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("cjson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new()

            -- insert route
            r:get("/foo{:/?}", foo)

            -- don't forget!
            r:compile()

            local ok = r:dispatch("/foo", ngx.req.get_method())
            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end

            ok = r:dispatch("/foo/", ngx.req.get_method())
            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
foo: [""]
hit
foo: ["\/"]
hit
