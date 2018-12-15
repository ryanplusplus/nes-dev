mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))

nesasm := $(mkfile_dir)nesasm/nesasm

.PHONY: all
all: build/$(TARGET).nes

.PHONY: unconditional

$(nesasm):
	@echo Building nesasm...
	@$(MAKE) -C $(mkfile_dir)nesasm/source

build/$(TARGET).nes: unconditional $(nesasm)
	@echo Assembling and linking $@...
	@mkdir -p build
	@$(nesasm) $(TARGET).asm
	@mv $(TARGET).nes build/
	@mv $(TARGET).fns build/

.PHONY: run
run: build/$(TARGET).nes
	@echo Running in FCEUX...
	@fceux build/$(TARGET).nes

.PHONY: clean
clean:
	@echo Cleaning...
	@rm -rf build
