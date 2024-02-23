# make -p ist ein Freund
ifdef COMSPEC
SHELL := bash.exe
else
SHELL := bash
endif

# This should be uppercase if you don't want things to break
PROGNAME?=TYZZY
PLATFORM?=ti83p
SUBTYPE?=mirage

# Comment this out to disable debugging completely
DEBUG=1

# Comment this out if you don't want to include the GDB debugger
# This requires DEBUG
#GDB=1

GDBPROG=$(shell { which z88dk-gdb z88dk.z88dk-gdb 2>/dev/null || echo 'z88dk-gdb' ; } | head -1)
CC=$(shell { which zcc z88dk.zcc 2>/dev/null || echo 'zcc' ; } | head -1)
LD=$(CC)

BASE_CFLAGS=-Wall -compiler sccz80 -pragma-include src/pragma.h
BASE_CFLAGS_DEBUG=$(BASE_CFLAGS) -debug -O3 --opt-code-size
BASE_CFLAGS_RELEASE=$(BASE_CFLAGS) -O3 --opt-code-size

ifdef DEBUG
	ifdef GDB
LDFLAGS?=$(BASE_CFLAGS_DEBUG) -L$(GDB_PATH)/build -lgdb
LIBCFLAGS?=$(BASE_CFLAGS_RELEASE) -DGDB_ENABLED
	else
LDFLAGS?=$(BASE_CFLAGS_DEBUG)
	endif
CFLAGS?=$(BASE_CFLAGS_DEBUG)
else
CFLAGS?=$(BASE_CFLAGS_RELEASE)
LDFLAGS?=$(BASE_CFLAGS_RELEASE)
endif

LIBCFLAGS?=$(BASE_CFLAGS_RELEASE)

BUILD=build
ZCODE=$(BUILD)/zcode
# For building. Just the aas
COMPILEZCODE=$(ZCODE)/hhgg/HHGGaa.8xv $(ZCODE)/cloak/CLOAKaa.8xv $(ZCODE)/ziltest/ZILTESaa.8xv
# For testing. All files we want sent to the calculator
LOADZCODE=$(wildcard $(ZCODE)/hhgg/*.8xv) # These games are non-standard. Contain opcodes that don't work with ZDebug: $(wildcard $(ZCODE)/cloak/*.8xv) $(wildcard $(ZCODE)/ziltest/*.8xv)

BRIDGE_PATH=3rdparty/ticables-gdb-bridge
GDB_PATH=3rdparty/z88dk-gdbstub
TIKEYS=$(BRIDGE_PATH)/build/tikeys
TILP=tilp -n --calc=83p
WABBIT=WabbitEmu.exe
WABBIT_OPTS=-gdb-port "$${TIBRIDGE_PORT:-8998}"
MIRAGE=$(BUILD)/MIRAGEOS.8xk
NOSHELL=$(BUILD)/noshell.8xk
TILPCFG=$(HOME)/.tilp

wilder_card=$(wildcard $(1)/**/$(2)) $(wildcard $(1)/$(2))
ifdef COMSPEC
# This complex bullish is needed so we can build on Windows with backslashes in the paths,
# so the debugger works correctly.
realer_path=$(subst /,\,$(realpath $(1)))
else
realer_path=$(realpath $(1))
endif

define source_directory
$(eval $(1)=$(2))
$(eval $(1)_FILES=$(call wilder_card,$(2),*.asm) $(call wilder_card,$(2),*.c))
$(eval $(1)_OBJECT_FILES=$$(subst $(2)/,$$(BUILD)/$(2)/,$$(patsubst %.asm,%.o,$$(patsubst %.c,%.o,$$($(1)_FILES)))))
$(eval vpath %.c $(2))
$(eval vpath %.asm $(2))
endef

$(call source_directory,SRC,src)
$(call source_directory,TEST,tests)
$(call source_directory,LIB,lib)

.ONESHELL:

all: $(BUILD)/program.8xp

test: $(BUILD)/tests.8xp

install: $(BUILD)/program.8xp $(TILPCFG) $(TIKEYS)
	$(TIKEYS) --reset-ram
	$(TILP) "$<"

# This isn't done by default because we don't want to wear out the flash
install-noshell: $(NOSHELL)
	$(TILP) "$<"

debug-emu: $(BUILD)/program.map start-emu ./gdb_startup.txt
	sleep 8
	"$(GDBPROG)" -h 127.0.0.1 -p "$${TIBRIDGE_PORT:-8998}" -x "$<" --script ./gdb_startup.txt

$(BUILD)/program.map: $(BUILD)/program.8xp

start-emu: ./ti83plus.rom $(BUILD)/program.8xp $(BUILD)/program.startup.key $(COMPILEZCODE) $(MIRAGE)
	"$(WABBIT)" -replay-keys $(BUILD)/program.startup.key $(WABBIT_OPTS) $(filter %.rom %.8xk %.8xp,$^) $(LOADZCODE)

install-emu: ./ti83plus.rom $(BUILD)/program.8xp $(COMPILEZCODE) $(MIRAGE)
	"$(WABBIT)" $(WABBIT_OPTS) $(filter %.rom %.8xk %.8xp,$^) $(LOADZCODE)

$(TILPCFG): ./.tilp
	if [[ ! -e "$@" ]] ; then
		cp "$<" "$@"
	fi
	sed -i 's/auto_detect[[:space:]]*=[[:space:]]*1/auto_detect=0/g' "$@"

zcode-install: $(TIKEYS) $(COMPILEZCODE) $(TILPCFG)
	for each in $(LOADZCODE) ; do
		if "$<" --exists="$$(basename "$${each%.*}")" ; then
			echo "$$each already installed"
			continue
		fi

		$(TILP) "$$each"
	done

zcode: $(COMPILEZCODE)

$(ZCODE)/hhgg/HHGGaa.8xv: $(ZCODE)/hhgg.z3
	bash ./storypac8x.sh "$<"

$(ZCODE)/hhgg.z3: | $(ZCODE)
	curl -Lqo "$@" https://raw.githubusercontent.com/BYU-PCCL/z-machine-games/master/jericho-game-suite/hhgg.z3

$(ZCODE)/ziltest/ZILTESaa.8xv: $(ZCODE)/ziltest.z3
	bash ./storypac8x.sh "$<"

$(ZCODE)/ziltest.z3: | $(ZCODE)
	curl -Lqo "$@" https://raw.githubusercontent.com/jeffnyman/zifmia/master/zil/zil_test.z3

$(ZCODE)/cloak/CLOAKaa.8xv: $(ZCODE)/cloak.z3
	bash ./storypac8x.sh "$<"

$(ZCODE)/cloak.z3: | $(ZCODE)
	curl -Lqo "$@" https://raw.githubusercontent.com/jeffnyman/zifmia/master/zil/cloak.z3

$(ZCODE):
	@mkdir -p "$@"

start: $(TIKEYS) install
	"$<" --program=$(PROGNAME)

bridge: $(BRIDGE_PATH)/build/tibridge
	echo "<<<STARTED BRIDGE>>>"
	"$<" --port=$${TIBRIDGE_PORT:-8998} --log-level=trace 2>$(shell tty)

noshell-install: $(NOSHELL)
	$(TILP) "$<"

$(NOSHELL):
	curl -Lqo "$(dir $@)/noshell.zip" https://www.ticalc.org/pub/83plus/flash/shells/noshell.zip
	cd "$(dir $@)" && unzip "noshell.zip" noshell.8xk

$(MIRAGE):
	curl -Lqo "$(dir $@)/mirage.zip" https://www.ticalc.org/pub/83plus/flash/shells/mirageos.zip
	cd "$(dir $@)" && unzip "mirage.zip" MIRAGEOS.8xk

clean:
	find "$(BUILD)" -not -path "$(BUILD)" -not -path "$(ZCODE)*" -exec rm -rf '{}' '+'

distclean:
	rm -rf "$(BUILD)"

define 8xp_build
$$(BUILD)/$(1).8xp: $$(BUILD)/$(1).bin
	bash ./bashpac8x.sh --archive "$$<" "$(3)" > "$$@"

$$(BUILD)/$(1).bin: $$(BUILD)/$(1).bip
	cat header_bytes.bin "$$<" > "$$@"

# This gets loaded into OP1 to support execution from the debugger.
# Program Token (1B) - Name (8B) - RST $$28 - BCALL $$4e7c - RET
$$(BUILD)/$(1).startup.key: ./startup.key
	cp "$$<" "$$@"

$$(BUILD)/$(1).bip: $(4) src/pragma.h
	"$$(LD)" +$(PLATFORM) -subtype=$(2) $$(LDFLAGS) -o "$$@" $$(filter %.o,$$^)
endef

$(eval $(call 8xp_build,program,$(SUBTYPE),$(PROGNAME),$(SRC_OBJECT_FILES) $(LIB_OBJECT_FILES)))

# It's extremely important that the source file paths are absolute, otherwise the
# extension will have trouble mapping the paths.
define source_compile
	SRCPATH="$(call realer_path,$<)"
	SRCPATH=$${SRCPATH,}
	mkdir -p "$(dir $@)"
	if [ ! -z "$(filter $(LIB_FILES),$<)" ] ; then
		"$(CC)" +$(PLATFORM) $(LIBCFLAGS) $(1) -o "$@" "$$SRCPATH"
	else
		"$(CC)" +$(PLATFORM) $(CFLAGS) $(1) -o "$@" "$$SRCPATH"
	fi
endef

$(BUILD)/%.o: $(BUILD)/%.o.asm | $(BUILD)
	SRCPATH="$(call realer_path,$<)"
	SRCPATH=$${SRCPATH,}
	mkdir -p "$(dir $@)"
	if [ ! -z "$(filter $(LIB_OBJECT_FILES),$@)" ] ; then
		"$(CC)" +$(PLATFORM) $(LIBCFLAGS) -c -o "$@" "$$SRCPATH"
	else
		"$(CC)" +$(PLATFORM) $(CFLAGS) -c -o "$@" "$$SRCPATH"
	fi

CLINE_MATCHER=^[[:space:]]*[0-9]*[[:space:]]*C_LINE.*::[1-9][0-9]*::.*

.PRECIOUS: $(BUILD)/%.o.asm
$(BUILD)/%.o.asm: $(BUILD)/%.i.asm | $(BUILD)
# Inserts NOPs into the assembly so we have space to debug
# Only insert one nop group per block of C_LINEs (sometimes there's a lot)
# Only count C_LINEs which aren't at the top level 0
ifdef GDB
	sed -f <(
		nl -b a "$<" | tac | uniq -f1 -d |
			grep -o '$(CLINE_MATCHER)' |
			awk '{print $$1}' |
			while read LINE ; do
				NL=$$((LINE+1)) ;
				echo "$$NL"'i nop\nnop\nnop' ;
				echo "$${NL}"'{/$(CLINE_MATCHER)/d;}' ;
			done
	) "$<" > "$@"
else
	cp "$<" "$@"
endif

.PRECIOUS: $(BUILD)/%.i.asm
$(BUILD)/%.i.asm: %.asm | $(BUILD)
	mkdir -p "$(dir $@)"
	cp "$<" "$@"

.PRECIOUS: $(BUILD)/%.i.asm
$(BUILD)/%.i.asm: %.c | $(BUILD)
	$(call source_compile,-S)

$(BUILD): $(GDB_PATH)/build/gdb.lib
	@mkdir -p "$@"

$(GDB_PATH)/build/gdb.lib: $(GDB_PATH)
	$(MAKE) -C "$(GDB_PATH)"

$(BRIDGE_PATH)/build/tibridge: $(BRIDGE_PATH)/build/tikeys

$(BRIDGE_PATH)/build/tikeys: $(BRIDGE_PATH)/build/Makefile
	$(MAKE) -C "$(dir $<)"

$(BRIDGE_PATH)/build/Makefile: $(BRIDGE_PATH)/CMakeLists.txt | $(BRIDGE_PATH)/build
	cd $(BRIDGE_PATH)/build
	cmake ..

$(BRIDGE_PATH)/build:
	@mkdir -p "$@"

$(BRIDGE_PATH)/CMakeLists.txt: submodules

$(GDB_PATH): submodules

submodules:

vbshared: $(HOME)/vbshared/tyzzy.8xp $(HOME)/vbshared/ZILTESaa.8xv

$(HOME)/vbshared/tyzzy.8xp: $(BUILD)/program.8xp
	cp "$<" "$@"

$(HOME)/vbshared/ZILTESaa.8xv: $(COMPILEZCODE)
	for each in $(wildcard $(ZCODE)/*/*.8xv) ; do
		cp "$$each" "$(HOME)/vbshared/$$(basename "$$each")"
	done
