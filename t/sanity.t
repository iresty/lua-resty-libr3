# vim:set ft= ts=4 sw=4 et fdm=marker:

use Test::Nginx::Socket::Lua 'no_plan';

log_level('warn');
repeat_each(5);

our $HttpConfig = <<'_EOC_';
    lua_package_path 'lib/?.lua;;';
_EOC_

run_tests();

__DATA__

=== TEST 1: sanity
--- http_config eval: $::HttpConfig
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
--- http_config eval: $::HttpConfig
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
--- http_config eval: $::HttpConfig
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
                {method = {"GET"}, uri = [[/foo/{:\w+}/{:\w+}]], handler = foo}
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



=== TEST 4: create r3 object with arguments (no method)
--- http_config eval: $::HttpConfig
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
                {uri = [[/foo/{:\w+}/{:\w+}]], handler = foo}
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
--- http_config eval: $::HttpConfig
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
--- http_config eval: $::HttpConfig
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
--- http_config eval: $::HttpConfig
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
--- http_config eval: $::HttpConfig
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
                {method = {"GET"}, uri = "/bar", handler = bar}
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
