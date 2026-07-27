AS = xa
ASFLAGS = -XMASM
TARGET = invaders64.prg
SRC = invaders_c64.asm

all: $(TARGET)

$(TARGET): $(SRC)
	$(AS) $(ASFLAGS) $(SRC) -o $(TARGET)

clean:
	rm -f $(TARGET)

run: $(TARGET)
	x64sc $(TARGET)
