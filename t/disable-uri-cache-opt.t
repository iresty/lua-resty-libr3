# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::R3 'no_plan';

run_tests();

__DATA__

=== TEST 1: no pattern
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
            local r = r3router.new(nil, {disable_path_cache_opt = true})

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



=== TEST 2: method dispatch2, specified a table to store the parameter
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
                },
                {
                    disable_path_cache_opt = true
                }
            )

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



=== TEST 3: multiple routes: same path, different method
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
            local r = r3router.new(nil, {disable_path_cache_opt=false})

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
