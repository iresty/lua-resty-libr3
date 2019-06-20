# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::R3 'no_plan';

run_tests();

__DATA__

=== TEST 1: not match: 127.0.0.1 =~ no_remote_addr
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
                    remote_addr = "127.0.0.1",
                    handler = foo,
                }
            })

            r:compile()

            local ok = r:dispatch(ngx.var.uri, {
                    method = ngx.req.get_method()
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



=== TEST 2: match: 127.0.0.1 =~ 127.0.0.1
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
                    remote_addr = "127.0.0.1",
                    handler = foo,
                }
            })

            r:compile()

            local ok = r:dispatch(ngx.var.uri, {
                    method = ngx.req.get_method(),
                    remote_addr = "127.0.0.1",
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



=== TEST 3: match: 127.0.0.0/24 =~ 127.0.0.1
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
                    remote_addr = "127.0.0.0/24",
                    handler = foo,
                }
            })

            r:compile()

            local ok = r:dispatch(ngx.var.uri, {
                    method = ngx.req.get_method(),
                    remote_addr = "127.0.0.1",
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



=== TEST 4: not match: 127.0.0.0/24 =~ 127.0.1.1
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
                    remote_addr = "127.0.0.0/24",
                    handler = foo,
                }
            })

            r:compile()

            local ok = r:dispatch(ngx.var.uri, {
                    method = ngx.req.get_method(),
                    remote_addr = "127.0.1.1",
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
