# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::R3;

my $pwd = `pwd`;
chomp $pwd;

if($pwd =~ m{^/home/travis}) {
    plan(skip_all => "fix me: https://github.com/iresty/lua-resty-libr3/issues/13");
} else {
    plan('no_plan');
}

run_tests();

__DATA__

=== TEST 1: create r3 object by `new`
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
        }
    }
--- request
GET /foo/idv/namev
--- no_error_log
[error]
--- response_body
foo: ["idv","namev"]
hit



=== TEST 2: insert rule
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

            collectgarbage()

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
