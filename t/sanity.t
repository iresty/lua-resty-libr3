# vim:set ft= ts=4 sw=4 et fdm=marker:

use Test::Nginx::Socket::Lua;

log_level('warn');

repeat_each(2);

plan tests => repeat_each() * (blocks() * 3);

our $HttpConfig = <<'_EOC_';
    lua_package_path 'lib/?.lua;;';
_EOC_

run_tests();

__DATA__

=== TEST 1: sanity
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            -- foo handler
            function foo(params)
                ngx.say("foo: ", require("cjson").encode(params))
            end

            -- r3router
            local r3router = require "resty.r3";
            local r = r3router.new()

            -- routing
            r:get("/", function(tokens, params)
            ngx.say("hello r3!")
            end)

            r:get("/foo", foo)
            r:get("/foo/{id}/{name}", foo)
            r:post("/foo/{id}/{name}", foo)

            -- don't forget!
            r:compile()

            local ok = r:dispatch("GET", "/foo/12/34", ngx.req.get_uri_args(), nil)
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
foo: {"name":"34","id":"12"}
hit
