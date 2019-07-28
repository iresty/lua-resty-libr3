# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::R3 'no_plan';

run_tests();

__DATA__

=== TEST 1: host + uri
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
                    path = [[{domain:[^/]+}/foo/{id:\w+}/{name:\w+}]],
                    handler = foo,
                }
            })

            r:compile()

            for i, domain in ipairs({"localhost", "127.0.0.1", "foo.com", "www.foo.com"}) do
                local ok = r:dispatch(domain .. ngx.var.uri,
                                {method = ngx.req.get_method()})
                if ok then
                    ngx.say("hit")
                else
                    ngx.say("not hit")
                end
            end
        }
    }
--- request
GET /foo/idv/namev
--- no_error_log
[error]
--- response_body
foo: {"name":"namev","domain":"localhost","id":"idv"}
hit
foo: {"name":"namev","domain":"127.0.0.1","id":"idv"}
hit
foo: {"name":"namev","domain":"foo.com","id":"idv"}
hit
foo: {"name":"namev","domain":"www.foo.com","id":"idv"}
hit
