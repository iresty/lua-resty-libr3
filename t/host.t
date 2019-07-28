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
                ngx.say("foo: ", require("ljson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {
                    path = [[/foo/{:\w+}/{:\w+}]],
                    host = "localhost",
                    handler = foo,
                },
                {
                    method = {"GET", "POST"},
                    path = [[/bar/{:\w+}/{:\w+}]],
                    host = "localhost",
                    handler = foo,
                }
            })

            r:compile()

            local ok = r:dispatch(ngx.var.uri,
                            {method = ngx.req.get_method(), host = "localhost"})

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



=== TEST 2: not match (host is different)
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
                    host = "not_found_host",
                    handler = foo,
                }
            })

            r:compile()
            local ok = r:dispatch(ngx.var.uri,
                            {method = ngx.req.get_method(), host = "localhost"})

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



=== TEST 3: not match (host is different)
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
                    host = "localhost",
                    handler = foo,
                }
            })

            r:compile()

            local ok = r:dispatch(ngx.var.uri,
                            {method = ngx.req.get_method(),
                             host = "not_found_host"})
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
