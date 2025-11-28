# Force npx, yarn, and so on to create their caches under this directory
npx	:= env HOME=$(PWD) npx

# git clone https://github.com/tsl0922/ttyd
# cd ttyd
# git reset --hard eccebc6
src	= ttyd
prefix	= /var/tmp/ttyd

MAKEFLAGS += --no-print-directory

.PHONY:	full-build clean-and-build
full-build clean-and-build:
	$(MAKE) clean-caches
	$(MAKE) clean
	$(MAKE) build-html
	$(MAKE) build-ttyd

.PHONY:	clean
clean:
	cd $(src) && rm -rf build
	cd $(src) && git reset --hard HEAD
	cd $(src) && git checkout .
	cd $(src) && git clean -fdx

.PHONY:	clean-caches
clean-caches:
	rm -rf .caches
	rm -rf .npm
	rm -rf .yarn

.PHONY:	clean-home
clean-home:
	cd $(HOME) && rm -rf .npm*		|| :
	cd $(HOME) && rm -rf .yarn*		|| :
	cd $(HOME) && rm -rf .cache/node*	|| :
	cd $(HOME) && rm -rf .cache/yarn*	|| :
	$(MAKE) check-home

.PHONY:	check-home
check-home:
	cd $(HOME) && find .??*	\
	\( -name '*yarn*'	\
	-o -name '*node*'	\
	-o -name '*npx*'	\
	-o -name '*corepack*'	\
	\) | grep -E -v '^[.](gradle/|cache/js-v8flags/)' || :

.PHONY:	build-html
build-html:
	rm -f $(src)/src/html.h
	$(MAKE) $(src)/src/html.h

# sudo apt install nodejs npm yarnpkg
$(src)/src/html.h:
	cd $(src)/html && $(npx) --yes corepack yarn set version 3.6.3	# or latest
	cd $(src)/html && $(npx) corepack yarn install
	$(MAKE) patch-html
	cd $(src)/html && $(npx) corepack yarn run build

.PHONY:	run-test-server
run-test-server:
	cd $(src)/html && $(npx) corepack yarn run start

.PHONY:	build-ttyd
build-ttyd:
	rm -f $(src)/build/ttyd
	$(MAKE) $(src)/build/ttyd

# sudo apt install build-essential cmake git libjson-c-dev libwebsockets-dev
$(src)/build/ttyd: $(src)/src/html.h
	cd $(src) && mkdir build
	$(MAKE) patch-ttyd
	cd $(src)/build && cmake .. -DCMAKE_INSTALL_PREFIX=$(prefix)
	cd $(src)/build && $(MAKE)

.PHONY:	install
install: $(src)/build/ttyd
	rm -f $(prefix)/bin/ttyd
	rmdir $(prefix)/bin			> /dev/null 2>&1 || :
	rm -f $(prefix)/share/man/man1/ttyd.1
	rmdir $(prefix)/share/man/man1		> /dev/null 2>&1 || :
	rmdir $(prefix)/share/man		> /dev/null 2>&1 || :
	rmdir $(prefix)/share			> /dev/null 2>&1 || :
	cd $(src)/build && $(MAKE) install

.PHONY:	patch-html
patch-html:
	set -ex; for i in ttyd-mod-scripts/patch-html-*; do $$i $(src); done

.PHONY:	patch-ttyd
patch-ttyd:
	set -ex; for i in ttyd-mod-scripts/patch-ttyd-*; do $$i $(src); done
