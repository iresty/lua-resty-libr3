# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::R3 'no_plan';

run_tests();

__DATA__

=== TEST 1: create r3 object by `new`
--- config
location /foo {
    content_by_lua_block {
        local function test()
            -- foo handler
            local function foo(params)
                ngx.say("foo: ", require("cjson").encode(params))
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new({
                {
                    path = [[/foo/{:\w+}/{:\w+}]],
                    host = "localhost",
                    handler = foo,
                }
            })

            r:compile()

            local ok = r:dispatch(ngx.var.uri,
                            {method = ngx.req.get_method(), host = "localhost"})

            collectgarbage()

            if ok then
                ngx.say("hit")
            else
                ngx.say("not hit")
            end
        end

        for i = 1, 20 do
            test()
        end
    }
}
--- request
GET /foo/idv/namev
--- no_error_log
[error]



=== TEST 2: insert route with method
--- config
location /foo {
    content_by_lua_block {
        local t = {}
        local function test()
            local function foo(params)
                t.foo = (t.foo or 0) + 1
            end

            local function bar(params)
                t.bar = (t.bar or 0) + 1
            end

            -- r3 router
            local r3router = require "resty.r3"
            local r = r3router.new()

            -- insert route
            r:get("/foo", bar)
            r:get("/foo/{id}/{name}", foo)
            r:post("/foo/{id}/{name}", bar)

            -- don't forget!
            r:compile()

            local ok = r:dispatch(ngx.var.uri, ngx.req.get_method())

            if ok then
                return "hit"
            end

            return "not hit"
        end

        for i=1,100 do
            local res = test()
            t[res] = (t[res] or 0) + 1
            collectgarbage()
        end
        ngx.say(require("cjson").encode(t))
    }
}
--- request
GET /foo/a/b
--- no_error_log
[error]
--- response_body
{"foo":100,"hit":100}
