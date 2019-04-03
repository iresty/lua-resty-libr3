package = "lua-resty-r3"
version = "dev-1"
source = {
    url = "https://github.com/membphis/lua-resty-r3-easy/archive/master.tar.gz",
    dir = "lua-resty-r3-master"
}
description = {
    summary  = "lua-resty-r3-easy Lua-Openresty implementation",
    detailed = "lua-resty-r3-easy Lua-Openresty implementation",
    homepage = "https://github.com/membphis/lua-resty-r3-easy",
    license  = "MIT",
    maintainer = "membphis"
}
dependencies = {
    "lua >= 5.1"
}
build = {
    type = "builtin",
    modules = {
        ["resty-r3-easy"] = "lib/resty/r3.lua",
    }
}
