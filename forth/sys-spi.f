hex
B044 constant sys-spi-base
sys-spi-base     constant sys-spi-lsb
sys-spi-base 1 + constant sys-spi-msb
sys-spi-base 2 + constant sys-spi-status
sys-spi-base 3 + constant sys-spi-config

\ serial flash routines

50 constant sf-address \ spi address mask

variable sf-buf 256 allot

: sf-initspi ( -- ) bn 0111 sys-spi-config c! ;
: sf-waitspi ( -- )
    begin
        sys-spi-status c@
    1 and 0= until
;
: sf-start-transfer ( c f -- r ) \ transfer c over spi f = deselect flag, r = result byte
    swap
    sys-spi-lsb c!
    if 3 else 1 then sf-address or sys-spi-status c!
    sf-waitspi
    sys-spi-lsb c@ ;
: sf-cmd ( cmd count -- )
    dup 0= if
        \ send command without data, deselect after transfer
        drop
        true sf-start-transfer drop
    else
        \ send command with data, keep selected after cmd byte has been sent
        swap false sf-start-transfer drop
        sf-buf swap
        2 swap do
            dup dup c@ false sf-start-transfer swap c!
            1+
        -1 +loop
        dup c@ true sf-start-transfer c!
    then ;

: sf-rdid ( -- )
    sf-initspi
    9F 14 sf-cmd
    sf-buf 14 dump
;
