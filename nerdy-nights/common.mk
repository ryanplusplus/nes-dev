mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))

cl65 := $(mkfile_dir)cc65/bin/cl65

.PHONY: all
all: build/$(TARGET).nes

$(cl65):
	@echo Building cc65...
	@$(MAKE) -C $(mkfile_dir)cc65

build/$(TARGET).nes: $(SOURCE) $(INCLUDE) $(DATA) $(cl65)
	@echo Assembling and linking $@...
	@mkdir -p build
	@$(cl65) -l build/$(TARGET).lst -g -t nes -C nes.cfg -m build/$(TARGET).map -Ln build/$(TARGET).lbl $(SOURCE) -o build/$(TARGET).nes
	@mv $(SOURCE:.asm=.o) build/

.PHONY: run
run: build/$(TARGET).nes
	@echo Running in FCEUX...
	@fceux build/$(TARGET).nes

.PHONY: clean
clean:
	@echo Cleaning...
	@rm -rf build
