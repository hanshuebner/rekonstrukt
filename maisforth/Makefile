GFORTH = gforth
TARGET = an601
BITSTREAM = ../ise/my_system09.bit
BMM = ../vhdl/maisforth_rom_bd.bmm
PRODUCTS = $(TARGET).vhd $(TARGET).bin $(TARGET).hex $(TARGET).bit $(TARGET).mem
MAISFORTH_BUILD = build: `date '+%F %T%z'` svn: `svnversion . | sed -e 's/.*://'`

all:	$(PRODUCTS)

clean:
	rm -f $(PRODUCTS) *~

$(TARGET).bin: meta601.f cras601.f targ601.f
	env MAISFORTH_BUILD="[$(MAISFORTH_BUILD)]" $(GFORTH) meta601.f -e 'romimage bye'

$(TARGET).hex: $(TARGET).bin
	objcopy -I binary $(TARGET).bin -O ihex --adjust-vma 0xc000 $(TARGET).hex

$(TARGET).bit: $(TARGET).mem
	-data2mem -bm $(BMM) -bt $(BITSTREAM) -bd an601.mem -o b $(TARGET).bit

$(TARGET).mem: $(TARGET).bin
	perl ../tools/bin-to-mem.pl $(TARGET).bin

$(TARGET).vhd: $(TARGET).bin
	perl ../tools/bin-to-ramb16.pl $(TARGET).bin
