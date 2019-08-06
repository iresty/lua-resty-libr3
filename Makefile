INST_PREFIX ?= /usr
INST_LIBDIR ?= $(INST_PREFIX)/lib/lua/5.1
INST_LUADIR ?= $(INST_PREFIX)/share/lua/5.1
INSTALL ?= install
UNAME ?= $(shell uname)
R3_CONFIGURE_OPT ?=

CFLAGS := -O3 -g -Wall -fpic

C_SO_NAME := libr3.so
LDFLAGS := -shared

BUILDER_IMAGE = lua-resty-libr3-builder

# on Mac OS X, one should set instead:
# for Mac OS X environment, use one of options
ifeq ($(UNAME),Darwin)
	LDFLAGS := -bundle -undefined dynamic_lookup
	C_SO_NAME := libr3.dylib
	R3_CONFIGURE_OPT := --host=x86_64
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
	prove -I../test-nginx/lib -I./ -r -s t/

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
	git clone -b 2.0.2-iresty https://github.com/iresty/r3.git

${R3_CONGIGURE} :
	cd $(R3_FOLDER) && ./autogen.sh

${R3_STATIC_LIB} :
	cd $(R3_FOLDER) && ./configure $(R3_CONFIGURE_OPT) && make


### install:      Install the library to runtime
.PHONY: install
install:
	$(INSTALL) -d $(INST_LUADIR)/resty/
	$(INSTALL) lib/resty/*.lua $(INST_LUADIR)/resty/
	$(INSTALL) $(C_SO_NAME) $(INST_LIBDIR)/

docker-builder:
	docker build -t $(BUILDER_IMAGE) .

### build-in-docker:	Build the package a in Docker image
build-in-docker: clean docker-builder
	docker run -v `pwd`:/app/ $(BUILDER_IMAGE):latest bash -c 'cd /app && make compile'

### test-in-docker:	Test the package in a Docker image
test-in-docker: clean docker-builder
	docker run -v `pwd`:/app/ $(BUILDER_IMAGE):latest bash -c 'cd /app && make test'

### help:         Show Makefile rules
.PHONY: help
help:
	@echo Makefile rules:
	@echo
	@grep -E '^### [-A-Za-z0-9_]+:' Makefile | sed 's/###/   /'
