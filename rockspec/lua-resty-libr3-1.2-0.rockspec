package = "lua-resty-libr3"
version = "1.2-0"
source = {
    url = "git://github.com/iresty/lua-resty-libr3",
    tag = "v1.2",
}

description = {
    summary = "This is a libr3 implementation base on FFI for Lua-Openresty",
    homepage = "https://github.com/iresty/lua-resty-libr3",
    license = "Apache License 2.0",
    maintainer = "Yuansheng Wang <membphis@gmail.com>"
}

build = {
    type = "make",
    build_variables = {
            CFLAGS="$(CFLAGS)",
            LIBFLAG="$(LIBFLAG)",
            LUA_LIBDIR="$(LUA_LIBDIR)",
            LUA_BINDIR="$(LUA_BINDIR)",
            LUA_INCDIR="$(LUA_INCDIR)",
            LUA="$(LUA)",
        },
        install_variables = {
            INST_PREFIX="$(PREFIX)",
            INST_BINDIR="$(BINDIR)",
            INST_LIBDIR="$(LIBDIR)",
            INST_LUADIR="$(LUADIR)",
            INST_CONFDIR="$(CONFDIR)",
        },
}
