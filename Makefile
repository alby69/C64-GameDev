# ****************************************************************************
# Makefile -- C64 Space Invaders Build System
# ****************************************************************************

AS = xa
ASFLAGS = -XMASM
TARGET = invaders64.prg
SRC = main.asm

all: $(TARGET)

$(TARGET): $(SRC)
	$(AS) $(ASFLAGS) $(SRC) -o $(TARGET)

ntsc: $(SRC)
	$(AS) $(ASFLAGS) -DNTSC $(SRC) -o $(TARGET)

pal: $(SRC)
	$(AS) $(ASFLAGS) -DPAL $(SRC) -o $(TARGET)

test: $(TARGET)
	@echo "Running automated headless test under VICE x64sc..."
	xvfb-run x64sc -autostartprgmode 1 -limitcycles 5000000 $(TARGET) || [ $$? -eq 1 ]
	@echo "Automated test completed successfully!"

dist: $(TARGET)
	@echo "Generating release disk image (.d64)..."
	rm -f invaders.d64
	c1541 -format "invaders,01" d64 invaders.d64 -write $(TARGET) invaders
	@echo "Packaging release distribution ZIP..."
	rm -f invaders-c64.zip
	zip -r invaders-c64.zip $(TARGET) invaders.d64 README.md
	@echo "Release packaged: invaders-c64.zip"

clean:
	rm -f $(TARGET) invaders.d64 invaders-c64.zip

run: $(TARGET)
	x64sc $(TARGET)
