.PHONY: all
all: build/$(TARGET).nes

build/$(TARGET).nes: $(SOURCE) $(INCLUDE) $(DATA)
	@echo Assembling and linking $@...
	@mkdir -p build
	@cl65 -l -g -t nes -C nes.cfg -m build/$(TARGET).map -Ln build/$(TARGET).lbl $(SOURCE) -o build/$(TARGET).nes
	@mv $(SOURCE:.asm=.o) build/
	@mv $(SOURCE:.asm=.lst) build/

.PHONY: run
run: build/$(TARGET).nes
	@echo Running in FCEUX...
	@fceux build/$(TARGET).nes

.PHONY: clean
clean:
	@echo Cleaning...
	@rm -rf build
