package = "lua-resty-libr3"
version = "0.1-0"
source = {
   url = "git://github.com/iresty/lua-resty-libr3",
   tag = "v0.1",
}

description = {
   summary = "This is a libr3 implementation library base on FFI for Lua-Openresty",
   homepage = "https://github.com/iresty/lua-resty-libr3",
   license = "Apache License 2.0",
   maintainer = "Yuansheng Wang <membphis@gmail.com>"
}

dependencies = {
   "lua = 5.1",
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
