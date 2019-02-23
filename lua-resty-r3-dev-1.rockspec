package = "lua-resty-r3"
version = "dev-1"
source = {
    url = "https://github.com/toritori0318/lua-resty-r3/archive/master.tar.gz",
    dir = "lua-resty-r3-master"
}
description = {
    summary = "libr3 Lua-Openresty implementation",
    detailed = [[libr3 Lua-Openresty implementation.]],
    homepage = "https://github.com/toritori0318/lua-resty-r3",
    license = "MIT",
    maintainer = "toritori0318"
}
dependencies = {
    "lua >= 5.1"
}
build = {
    type = "builtin",
    modules = {
        ["resty.r3"] = "lib/resty/r3.lua",
    }
}
