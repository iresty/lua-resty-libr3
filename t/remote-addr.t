# vim:set ft= ts=4 sw=4 et fdm=marker:

use Test::Nginx::Socket::Lua 'no_plan';

log_level('info');
repeat_each(2);

our $HttpConfig = <<'_EOC_';
    lua_package_path 'lib/?.lua;;';
    lua_package_cpath './?.so;;';
_EOC_

run_tests();

__DATA__

=== TEST 1: missing remote address
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
--- ONLY
