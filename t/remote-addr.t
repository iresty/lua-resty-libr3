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
                ngx.say("foo: ", require("ljson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {
                    path = [[/foo/{:\w+}/{:\w+}]],
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
                ngx.say("foo: ", require("ljson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {
                    path = [[/foo/{:\w+}/{:\w+}]],
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
                ngx.say("foo: ", require("ljson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {
                    path = [[/foo/{:\w+}/{:\w+}]],
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
                ngx.say("foo: ", require("ljson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {
                    path = [[/foo/{:\w+}/{:\w+}]],
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



=== TEST 5: static uri: 127.0.0.1 =~ 127.0.0.1
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("ljson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {
                    path = [[/foo/idv/namev]],
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
foo: []
hit



=== TEST 6: static uri: 127.0.0.0/24 =~ 127.0.0.33
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("ljson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {
                    path = [[/foo/idv/namev]],
                    remote_addr = "127.0.0.0/24",
                    handler = foo,
                }
            })

            r:compile()

            local ok = r:dispatch(ngx.var.uri, {
                    method = ngx.req.get_method(),
                    remote_addr = "127.0.0.33",
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
foo: []
hit



=== TEST 7: static uri: 127.0.0.0/24 =~ 127.0.1.33
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("ljson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {
                    path = [[/foo/idv/namev]],
                    remote_addr = "127.0.0.0/24",
                    handler = foo,
                }
            })

            r:compile()

            local ok = r:dispatch(ngx.var.uri, {
                    method = ngx.req.get_method(),
                    remote_addr = "127.0.1.33",
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



=== TEST 8: static uri: 127.0.0.1 =~ 127.0.0.2
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("ljson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {
                    path = [[/foo/idv/namev]],
                    remote_addr = "127.0.0.1",
                    handler = foo,
                }
            })

            r:compile()

            local ok = r:dispatch(ngx.var.uri, {
                    method = ngx.req.get_method(),
                    remote_addr = "127.0.0.2",
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



=== TEST 9: invalid ip address
--- config
    location /foo {
        content_by_lua_block {
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("ljson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {
                    path = [[/foo/{:\w+}/{:\w+}]],
                    remote_addr = "127.0.0.1a",
                    handler = foo,
                }
            })

            r:compile()
        }
    }
--- request
GET /foo/idv/namev
--- error_log
invalid ip address
--- error_code: 500
