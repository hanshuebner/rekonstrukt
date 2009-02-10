.PHONY: an601.bin an601.hex

GFORTH = gforth
TARGET = an601
PRODUCTS = $(TARGET).vhd $(TARGET).bin $(TARGET).bit $(TARGET).hex

all:	$(PRODUCTS)

clean:
	rm -f $(PRODUCTS) *~

$(TARGET).bin:
	cd ../maisforth && $(GFORTH) meta601.f -e 'romimage bye'
	cp ../maisforth/$(TARGET).bin .

$(TARGET).hex: $(TARGET).bin
	objcopy -I binary $(TARGET).bin -O ihex --adjust-vma 0xc000 $(TARGET).hex

$(TARGET).bit:
	-data2mem -bm maisforth_rom_bd.bmm -bt my_system09.bit -bd an601.mem -o b final.bit

$(TARGET).mem: $(TARGET).bin
	perl ../tools/bin-to-mem.pl $(TARGET).bin

$(TARGET).vhd: $(TARGET).bin
	perl ../tools/bin-to-ramb16.pl $(TARGET).bin
