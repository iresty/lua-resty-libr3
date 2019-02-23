local router = require "resty.r3_apitools";

-- display time
function time(title, block)
  local st = os.clock()
  block()
  local ed = os.clock()

  ngx.say(title .. ": " .. ed-st.. " sec")
end

-- handler
function foo(params)
  --ngx.say("fooooooooooooooooooooooooooo")
  --ngx.say(tokens)
end

-- router
local r = router.new()
r:match("GET", "/", foo)
r:match("GET", "/foo/bar/baz/hoge/fuga/piyo", foo)
r:match("GET", "/foo/:id/:name", foo)


----------------------------------------------------------------------
-- bench 1
time("get /", function()
  for i=0, 10000000 do
    r:execute("GET", "/")
  end
end)

-- bench 2
time("get /foo/bar/baz/hoge/fuga/piyo", function()
  for i=0, 10000000 do
    r:execute("GET", "/foo/bar/baz/hoge/fuga/piyo")
  end
end)

-- bench 3
time("get /foo/{id}/{name}", function()
  for i=0, 10000000 do
    r:execute("GET", "/foo/123/999")
  end
end)

