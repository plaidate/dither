# Dither — original 1-bit pixel/sprite games on a shared core.
#
#   make sprint            build games/sprint -> out/Sprint.pdx
#   make sprint-smoke      instrumented build -> out/SprintSmoke.pdx
#   make sprint-smoke SEED=4   same, with a different pinned RNG seed
#   make all               every game, release builds
#
# A build stages core/* + games/<g>/* into build/<g>/source (pdc wants one
# source root), writes smokeflag.lua, then runs pdc. Smoke builds pin the
# RNG: smokeflag.lua carries SMOKE_SEED and Kit.run seeds from it, so an
# autopilot run is reproducible and a seed-dependent failure is a real bug.

GAMES := sprint glim skimmer prowl beacon echo delve

OUT := out
SEED ?= 1

define TITLECASE
$(shell echo $(1) | awk '{print toupper(substr($$0,1,1)) substr($$0,2)}')
endef

all: $(GAMES)

define GAME_RULES
$(1): build/$(1)/source
	pdc build/$(1)/source $(OUT)/$(call TITLECASE,$(1)).pdx

$(1)-smoke: build/$(1)-smoke/source
	pdc build/$(1)-smoke/source $(OUT)/$(call TITLECASE,$(1))Smoke.pdx

build/$(1)/source: core/*.lua games/$(1)/*
	mkdir -p $$@ $(OUT)
	cp core/*.lua $$@/
	cp -r games/$(1)/* $$@/
	rm -f $$@/*.md $$@/screenshot*.png $$@/*.py $$@/expect.lua
	cp LICENSE $$@/
	echo 'SMOKE_BUILD = false' > $$@/smokeflag.lua

build/$(1)-smoke/source: core/*.lua games/$(1)/*
	mkdir -p $$@ $(OUT)
	cp core/*.lua $$@/
	cp -r games/$(1)/* $$@/
	rm -f $$@/*.md $$@/screenshot*.png $$@/*.py $$@/expect.lua
	cp LICENSE $$@/
	echo 'SMOKE_BUILD = true' > $$@/smokeflag.lua
	echo 'SMOKE_SEED = $(SEED)' >> $$@/smokeflag.lua
	echo 'SMOKE_SHOT_PATH = "$(CURDIR)/build/$(1)-shot.png"' >> $$@/smokeflag.lua

.PHONY: $(1) $(1)-smoke
endef

$(foreach g,$(GAMES),$(eval $(call GAME_RULES,$(g))))

clean:
	rm -rf build $(OUT)

.PHONY: all clean
