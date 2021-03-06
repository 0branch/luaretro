# By Charles Childers and Marc Simpson
# Changed by Edrx
# (find-node "(make)Conditional Example")
# (find-node "(make)Conditional Syntax")
# (find-node "(make)Echoing")
# (find-node "(make)Flavors")

# (find-anggfile "RETRO/libretro.c" "NOMAIN")
# (find-gccnode "Link Options" "`-shared'")
# (find-angg ".zshrc" "lua")

# �.help�		(to "help")
# �.tarball�		(to "tarball")
# �.lua�		(to "lua")
# �.luarocks�		(to "luarocks")
# �.shared�		(to "shared")
# �.libretro.so�	(to "libretro.so")
# �.runluatest�		(to "runluatest")
# �.retro.so�		(to "retro.so")
# �.clean�		(to "clean")


# �help�  (to ".help")
# (find-dn4 "Makefile" "help")
# (find-sh "cd ~/RETRO/ && make")
default help:
	@echo "Usage:"
	@echo "  make runluatest   downloads & builds lua, runs the lua-ish test"


# �tarball�  (to ".tarball")
# (find-dn4 "Makefile" "tarball")
FILES = README VERSION Makefile \
	libretro.c retroImage \
	luaretro.c test.lua \
        retro-0.0.1-0.rockspec
tgz:
	(TZ=GMT date; date) | tee VERSION
	tar -cvzf luaretro.tgz $(FILES)


# �lua�  (to ".lua")
# Download and build lua5.1.
# From: (find-dn4 "Makefile" "lua")
wget      = wget
S         = $(PWD)/snarf
USRC      = $(PWD)/usrc

LUAURL    =    http://www.lua.org/ftp/lua-5.1.4.tar.gz
LUATGZ    = $(S)/http/www.lua.org/ftp/lua-5.1.4.tar.gz
LUATGZDIR = $(S)/http/www.lua.org/ftp/
LUASRC    = $(USRC)/lua-5.1.4
LUA51_    = $(LUASRC)/bin/lua
LUA51     = $(PWD)/lua51
LUAOS     = linux

luadownload: $(LUATGZ)
$(LUATGZ):
	mkdir -p $(LUATGZDIR)
	cd       $(LUATGZDIR) && \
	$(wget)  $(LUAURL)

cleanluabuild:
	rm -Rfv $(LUASRC)/

luabuild: $(LUA51_)
$(LUA51_): $(LUATGZ)
	rm -Rfv $(LUASRC)/
	mkdir -p $(USRC)/
	tar   -C $(USRC)/ -xvzf $(LUATGZ)
	cd $(LUASRC) && make $(LUAOS) local test

lua51 $(LUA51): $(LUA51_)
	cp -v $(LUA51_) $(LUA51)



# �luarocks�  (to ".luarocks")
# (find-es "lua5" "luarocks")
# http://luarocks.org/releases/
# http://luarocks.org/releases/luarocks-2.0.4.1.tar.gz
LUAROCKSURL    =    http://luarocks.org/releases/luarocks-2.0.4.1.tar.gz
LUAROCKSTGZ    = $(S)/http/luarocks.org/releases/luarocks-2.0.4.1.tar.gz
LUAROCKSTGZDIR = $(S)/http/luarocks.org/releases/
LUAROCKSSRC    = $(USRC)/luarocks-2.0.4.1
LUAROCKSDIR    = $(USRC)/luarocks
LUAROCKSBIN_   = $(LUAROCKSDIR)/bin/luarocks
LUAROCKSBIN    = $(PWD)/luarocks

luarocksdownload: $(LUAROCKSTGZ)
$(LUAROCKSTGZ):
	mkdir -p $(LUAROCKSTGZDIR)
	cd       $(LUAROCKSTGZDIR) && \
	$(wget)  $(LUAROCKSURL)

cleanluarocksbuild:
	rm -Rfv $(LUAROCKSSRC)/
	rm -Rfv $(LUAROCKSDIR)/

luarocksbuild: $(LUAROCKSBIN_)
$(LUAROCKSBIN_): lua51 $(LUAROCKSTGZ)
	rm -Rfv $(LUAROCKSSRC)/
	mkdir -p $(USRC)/
	tar   -C $(USRC)/ -xvzf $(LUAROCKSTGZ)
	cd $(LUAROCKSSRC) && ./configure --help
	cd $(LUAROCKSSRC) && ./configure --with-lua=$(LUASRC) --prefix=$(LUAROCKSDIR)
	cd $(LUAROCKSSRC) && make install
luarocks $(LUAROCKSBIN): $(LUAROCKSBIN_)
	cp -v $(LUAROCKSBIN_) $(LUAROCKSBIN)
rockmake: luarocks
	$(LUAROCKSBIN) make retro-0.0.1-0.rockspec
rockpack: luarocks
	$(LUAROCKSBIN) pack retro-0.0.1-0.rockspec

# (find-angg "peek/peek-0.0.1-0.rockspec")



# �shared�  (to ".shared")
# Marc's trick to make the option "LUAOS=macosx" also adjust how
# shared libraries are built
ifeq ($(LUAOS),macosx)
SHARED = -dynamiclib -Wl,-undefined,dynamic_lookup
else
SHARED = -shared
endif



# �libretro.so�  (to ".libretro.so")
# The original test by Charles and Marc, slightly changed.
# Here we build a .so ("libretro.so") and an executable ("test")
# thats loads the .so dynamically.
# (find-RETRO "libretro.c")
# (find-RETRO "test.c")
libretro.so: libretro.c
	gcc -g -O0 -Wall -fPIC -DNOMAIN $(SHARED) libretro.c -o libretro.so
test: test.c
	gcc -g -O0 -Wall -ldl test.c -o test

# �runluatest�  (to ".runluatest")
# �retro.so�  (to ".retro.so")
# Here we build a lua library ("retro.so") from libretro.c and
# luaretro.c, and we load it from lua.
# Note that the dependency "lua51" downloads and builds lua in the
# current directory.
# (find-RETRO "luaretro.c")
# (find-RETRO "test.lua")
libretro.o: libretro.c
	gcc -g -O0 -Wall -fPIC -DNOMAIN            -c libretro.c -o libretro.o
luaretro.o: lua51 luaretro.c
	gcc -g -O0 -Wall -fPIC -I$(LUASRC)/include -c luaretro.c -o luaretro.o
retro.so: lua51 libretro.o luaretro.o
	gcc $(SHARED) -o retro.so -L$(LUASRC)/lib -llua libretro.o luaretro.o
runluatest: lua51 retro.so
	$(LUA51) test.lua


# �clean�  (to ".clean")
clean:
	rm -fv libretro.so
	rm -fv libretro.o luaretro.o retro.so

# The "cleanlocal" targets don't delete anything outside the local dirs
cleanlocallua:
	rm -Rfv usr/lua-5.1.4/ lua51
cleanlocaldownloads:
	# ?
veryclean: clean cleanlocallua



# Local Variables:
# coding:               raw-text-unix
# ee-anchor-format:     "�%s�"
# End:
