
GFORTH = c:/Programme/gforth/gforth.exe
TARGET = an601
PRODUCTS = $(TARGET).vhd $(TARGET).bin $(TARGET).bit

all:	$(PRODUCTS)

clean:
	rm -f $(PRODUCTS) *~

$(TARGET).bin:
	$(GFORTH) -p ../maisforth ../maisforth/meta601.f -e romimage -e bye

$(TARGET).mem: $(TARGET).bin
	perl ../tools/bin-to-mem.pl $(TARGET).bin

$(TARGET).bit:
	data2mem -bm maisforth_rom_bd.bmm -bt my_system09.bit -bd an601.mem -o b final.bit

$(TARGET).vhd: $(TARGET).bin
	perl ../tools/bin-to-ramb16.pl $(TARGET).bin