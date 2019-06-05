INST_PREFIX ?= /usr
INST_LIBDIR ?= $(INST_PREFIX)/lib/lua/5.1
INST_LUADIR ?= $(INST_PREFIX)/share/lua/5.1
INSTALL ?= install
UNAME ?= $(shell uname)

CFLAGS := -O3 -g -Wall -fpic

C_SO_NAME := libr3.so
LDFLAGS := -shared

# on Mac OS X, one should set instead:
# for Mac OS X environment, use one of options
ifeq ($(UNAME),Darwin)
	LDFLAGS := -bundle -undefined dynamic_lookup
	C_SO_NAME := libr3.dylib
endif

MY_CFLAGS := $(CFLAGS) -DBUILDING_SO
MY_LDFLAGS := $(LDFLAGS) -fvisibility=hidden

OBJS := r3_resty.o
R3_FOLDER := r3
R3_CONGIGURE := $(R3_FOLDER)/configure
R3_STATIC_LIB := $(R3_FOLDER)/.libs/libr3.a

.PHONY: default
default: compile

### test:         Run test suite. Use test=... for specific tests
.PHONY: test
test: compile
	TEST_NGINX_LOG_LEVEL=info \
	prove -I../test-nginx/lib -r -s t/


### clean:        Remove generated files
.PHONY: clean
clean:
	rm -rf $(R3_FOLDER)
	rm -f $(C_SO_NAME) $(OBJS) ${R3_CONGIGURE}


### compile:      Compile library
.PHONY: compile

compile: ${R3_FOLDER} ${R3_CONGIGURE} ${R3_STATIC_LIB} $(C_SO_NAME)

${OBJS} : %.o : %.c
	$(CC) $(MY_CFLAGS) -c $<

${C_SO_NAME} : ${OBJS}
	$(CC) $(MY_LDFLAGS) $(OBJS) $(R3_FOLDER)/.libs/libr3.a -o $@

${R3_FOLDER} :
	cp -r deps/$(R3_FOLDER)-2.0 ./ && mv $(R3_FOLDER)-2.0 $(R3_FOLDER)

${R3_CONGIGURE} :
	cd $(R3_FOLDER) && ./autogen.sh

${R3_STATIC_LIB} :
	cd $(R3_FOLDER) && ./configure && make


### install:      Install the library to runtime
.PHONY: install
install:
	$(INSTALL) -d $(INST_LUADIR)/resty/
	$(INSTALL) lib/resty/*.lua $(INST_LUADIR)/resty/
	$(INSTALL) $(C_SO_NAME) $(INST_LIBDIR)/


### help:         Show Makefile rules
.PHONY: help
help:
	@echo Makefile rules:
	@echo
	@grep -E '^### [-A-Za-z0-9_]+:' Makefile | sed 's/###/   /'
