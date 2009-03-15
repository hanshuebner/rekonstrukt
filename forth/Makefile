TARGET		= s3esk
BITSTREAM	= ../ise/my_system09.bit
PRODUCTS	= $(TARGET).bin $(TARGET).mem $(TARGET).vhd
SOURCES		= s3esk.f sequencer.f
MAISFORTH_HEX	= ../maisforth/an601.hex

all: $(PRODUCTS)

$(TARGET).bin: $(SOURCES) $(MAISFORTH_HEX)
	../usim/usim.exe -q -d $(TARGET).bin $(patsubst %,-f %,$(SOURCES)) -e dump-core $(MAISFORTH_HEX)

clean:
	rm $(PRODUCTS)

$(TARGET).mem: $(TARGET).bin
	perl ../tools/bin-to-mem.pl -o 0x0000 $(TARGET).bin

$(TARGET).vhd: $(TARGET).bin
	perl ../tools/bin-to-ramb16.pl $(TARGET).bin
