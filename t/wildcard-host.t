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

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {
                    uri = [[/foo/{:\w+}/{:\w+}]],
                    host = "*.foo.com",
                    handler = foo,
                }
            })

            r:compile()

            local ok = r:dispatch(ngx.var.uri, {
                                method = ngx.req.get_method(),
                                host = "www.foo.com"
                            })

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



=== TEST 2: not match
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
                {
                    uri = [[/foo/{:\w+}/{:\w+}]],
                    host = "*.foo.com",
                    handler = foo,
                }
            })

            r:compile()
            local ok = r:dispatch(ngx.var.uri,{
                                method = ngx.req.get_method(),
                                host = "foo.com"
                            })

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
not hit



=== TEST 3: multiple route
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
            local r = r3router.new({
                {
                    uri = [[/foo/{:\w+}/{:\w+}]],
                    host = "*.bar.com",
                    handler = bar,
                },
                {
                    uri = [[/bar/{:\w+}/{:\w+}]],
                    host = "*.foo.com",
                    handler = bar,
                },
                {
                    uri = [[/foo/{:\w+}/{:\w+}]],
                    host = "*.foo.com",
                    handler = foo,
                }
            })

            r:compile()
            local ok = r:dispatch(ngx.var.uri,{
                                method = ngx.req.get_method(),
                                host = "a.b.foo.com"
                            })

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



=== TEST 4: uri hash cache
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
                {
                    uri = [[/foo/idv/namev]],
                    host = "*.foo.com",
                    handler = foo,
                }
            })

            r:compile()

            local ok = r:dispatch(ngx.var.uri, {
                                method = ngx.req.get_method(),
                                host = "www.foo.com"
                            })

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
foo: {}
hit
