local r3router = require "resty.r3";

-- display time
function time(title, block)
  local st = os.clock()
  block()
  local ed = os.clock()

  ngx.say(title .. ": " .. ed-st.. " sec")
end

-- handler
function foo(tokens, params)
  --ngx.say("fooooooooooooooooooooooooooo")
  --ngx.say(tokens)
end

-- router
local r = r3router.new({
    {"GET",           "/",                           foo},
    {"GET",           "/foo/bar/baz/hoge/fuga/piyo", foo},
    {{"GET","POST"},  "/foo/{id}/{name}",            foo}
})

----------------------------------------------------------------------
-- bench 1
time("get /", function()
  for i=0, 10000000 do
    r:dispatch("GET", "/")
  end
end)

-- bench 2
time("get /foo/bar/baz/hoge/fuga/piyo", function()
  for i=0, 10000000 do
    r:dispatch("GET", "/foo/bar/baz/hoge/fuga/piyo")
  end
end)

-- bench 3
time("get /foo/{id}/{name}", function()
  for i=0, 10000000 do
    r:dispatch("GET", "/foo/123/999")
  end
end)
