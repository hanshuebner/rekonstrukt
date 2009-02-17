vocabulary rekonstrukt
rekonstrukt definitions

hex
B044 constant sys-spi-base
sys-spi-base     constant sys-spi-lsb
sys-spi-base 1 + constant sys-spi-msb
sys-spi-base 2 + constant sys-spi-status
sys-spi-base 3 + constant sys-spi-config

\ serial flash routines

30 constant sf-address \ spi address mask

variable sf-buf 256 allot

: sf-initspi ( -- ) bn 0111 sys-spi-config c! ;
: sf-waitspi ( -- )
    begin
        sys-spi-status c@
    1 and 0= until
;
: sf-xfer ( c f -- r ) \ transfer c over spi f = deselect flag, r = result byte
    swap
    sys-spi-lsb c!
    if 3 else 1 then sf-address or sys-spi-status c!
    sf-waitspi
    sys-spi-lsb c@ ;
: sf-cmd ( cmd count -- )
    dup 0= if
        \ send command without data, deselect after transfer
        drop
        true sf-xfer drop
    else
        \ send command with data, keep selected after cmd byte has been sent
        swap false sf-xfer drop
        sf-buf swap
        1 swap do
            dup dup c@ false sf-xfer swap c!
            1+
        -1 +loop
        dup c@ true sf-xfer c!
    then ;

: sf-rdid ( -- )
    sf-initspi
    9F 14 sf-cmd
    sf-buf 14 dump
;

\ Block device driver for serial flash

\ Flash can be erase in units of a page, one page is larger than one
\ block (i.e. 64K vs 1K).  Writes to the flash must be distributed to
\ the whole device, as the number of write/erase cycles per cell is
\ limited.

\ We implement a directory scheme that works as follows:

\ One page of the device is designated the directory page.  For every
\ allocatable physical block, there is one two byte entry in the
\ directory page that indicates the logical block number to which
\ the physical block is allocated.  FFFF signifies an unused block.
\ To find the physical block number for a given logical block number,
\ the directory is sequentially scanned until an entry with the
\ required block number is found or FFFF is encountered.  When
\ FFFF has been encountered, the logical block has not previously
\ been allocated.
\ In order to write a logical block, the first unused (FFFF) entry
\ in the directory is overwritten with the logical block number.

\ Once the directory is completely filled, unused entries need to be
\ reclaimed.  This is done by copying all entries from the currently
\ active directory page to the secondary directory page and than erasing
\ the currently active directory page.

\ When starting, the primary and secondary directory page are scanned.
\ If both pages are empty, the primary page becomes the active page.
\ If one of them is empty, the non-empty page becomes the active page.
\ It is an error if none of the directory pages are empty.

\ Serial flash definitions, 16 MBit flash

decimal
32 constant pages     \ Number of pages
64 constant page-size \ Size of one page in 1K blocks

hex

variable active-page

\ sf-send - send byte to flash without deselecting
: sf-send ( c -- )
    false sf-xfer drop ;

: page-empty? ( n -- f )
    03 sf-send
    sf-send \ send page number
    0 sf-send 0 sf-send
    true
    FFFF 0 do
        0 false sf-xfer
        FF = 0= if
            drop false leave
        then
    loop
    0 true sf-xfer drop ;

: find-active-page ( -- )
    1 page-empty? if
        0 active-page !
    else
        0 page-empty? if
            1 active-page !
        else
            ." Internal error, both directory pages occupied "
        then
    then ;

\ Find current physical block number
: find-free-block ( -- b )
    03 sf-send
    active-page @ sf-send
    4 page-size *
    100 /mod sf-send sf-send
    FFFF
    pages page-size *
    2 page-size * .s do
        0 false sf-xfer 100 *
        0 false sf-xfer +
        FFFF = if
            drop i leave
        then
    loop
    0 true sf-send drop \ deselect
    dup FFFF = if
        ." no free block found "
    then ;
