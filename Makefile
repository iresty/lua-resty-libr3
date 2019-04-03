OPENRESTY_PREFIX=/usr/local/openresty-debug

PREFIX ?=          /usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?=     $(PREFIX)/lualib/$(LUA_VERSION)
INSTALL ?= install

C_SO_NAME := libr3.so

CFLAGS := -O3 -g -Wall -fpic

LDFLAGS := -shared
# on Mac OS X, one should set instead:
# LDFLAGS := -bundle -undefined dynamic_lookup

MY_CFLAGS := $(CFLAGS) -DBUILDING_SO
MY_LDFLAGS := $(LDFLAGS) -fvisibility=hidden

OBJS := r3_resty.o
R3_FOLDER := r3
R3_CONGIGURE := r3/configure
R3_STATIC_LIB := r3/.libs/libr3.a

.PHONY: default
default: compile

### test:         Run test suite. Use test=... for specific tests
.PHONY: test
test: compile
	    TEST_NGINX_SLEEP=0.001 \
	    TEST_NGINX_LOG_LEVEL=info \
	    prove -j$(jobs) -r $(test)


### clean:        Remove generated files
.PHONY: clean
clean:
	cd r3 && make clean
	rm -f $(C_SO_NAME) $(OBJS) ${R3_CONGIGURE}

### compile:      Compile library
.PHONY: compile

compile: ${R3_FOLDER} ${R3_CONGIGURE} ${R3_STATIC_LIB} $(C_SO_NAME) 

${OBJS} : %.o : %.c
	$(CC) $(MY_CFLAGS) -c $<

${C_SO_NAME} : ${OBJS}
	$(CC) $(MY_LDFLAGS) $(OBJS) r3/.libs/libr3.a -o $@

${R3_FOLDER} :
	cd deps && tar -xvf r3-2.0.tar.gz && mv r3 ../

${R3_CONGIGURE} : 
	cd r3 && sh autogen.sh

${R3_STATIC_LIB} :
	cd r3 && sh configure && make
	

### install:      Install the library to runtime
.PHONY: install
install:
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)/resty/r3_easy
	$(INSTALL) lib/resty/r3_easy/*.lua $(DESTDIR)$(LUA_LIB_DIR)/resty/r3_easy/
	$(INSTALL) $(C_SO_NAME) $(DESTDIR)$(LUA_LIB_DIR)

### help:         Show Makefile rules
.PHONY: help
help:
	@echo Makefile rules:
	@echo
	@grep -E '^### [-A-Za-z0-9_]+:' Makefile | sed 's/###/   /'
