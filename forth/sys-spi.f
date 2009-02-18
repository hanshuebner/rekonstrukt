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

: sf-initspi ( -- ) bn 0111 sys-spi-config c! ;
: sf-deselect ( -- ) 2 sf-address or sys-spi-status c! ;
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

\ sf-send - send byte to flash without deselecting
: sf-send ( c -- )
    false sf-xfer drop ;

: sf-send-address ( page addr -- )
    swap sf-send
    100 /mod sf-send sf-send ;

: sf-start-reading ( page adr -- )
    03 sf-send
    sf-send-address ;

: sf-start-writing ( page adr -- )
    02 sf-send
    sf-send-address ;

: sf-read-next-word ( -- word )
    0 false sf-xfer 100 *
    0 false sf-xfer + ;

: sf-read-next-byte ( -- byte )
    0 false sf-xfer ;

: sf-rdid ( -- )
    9F sf-send
    sf-read-next-byte .
    sf-read-next-byte .
    sf-read-next-byte . cr
;

: .sf ( -- )
    05 sf-send sf-read-next-byte sf-deselect
    ." flash status: "
    dup 1 and if ." WIP " then
    dup 2 and if ." WEL " then
    dup 1C and 2 rshift ." BP:" . space
    80 and if ." SRWD " then
    cr ;

: sf-wait ( -- )
    05 sf-send
    begin
        sf-read-next-byte
    1 and 0= until
    sf-deselect ;

: sf-write-enable ( -- )
    06 sf-send sf-deselect ;

: sf-erase-page ( page -- )
    sf-write-enable
    D8 sf-send
    sf-send 0 sf-send 0 sf-send sf-deselect
    sf-wait ;

: sf-write-sector ( address length page flash-address -- )
    sf-write-enable
    sf-start-writing
    0 do
        dup c@ sf-send 1+
    loop
    drop
    sf-deselect
    sf-wait ;

sf-initspi

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

\ Number of data pages
30 constant data-page-count
\ Page addresses of primary and secondary directory page
31 constant primary-directory
30 constant secondary-directory
hex

variable active-directory-page

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

: ?internal-error ( f -- )
    true abort" Internal error, both directory pages occupied" ;

: find-active-directory-page ( -- )
    secondary-directory page-empty? if
        primary-directory active-directory-page !
    else
        primary-directory page-empty? 0= ?internal-error
        secondary-directory active-directory-page !
    then ;

: sf-directory-addr ( phys-block-no -- page addr )
    active-directory-page @ swap 1 lshift ;

: sf-open-directory ( -- )
    0 sf-directory-addr sf-start-reading ;

: scanning-directory ( -- end begin )
    data-page-count page-size *
    0 ;

\ Find physical block number - n is the logical block number to find, returns -1 if not found
: find-block ( log-block-no -- phys-block-no )
    sf-open-directory
    FFFF
    scanning-directory do
        sf-read-next-word
        2 pick = if
            drop i
        then
    loop
    sf-deselect
    swap drop ;

: ?no-free-block ( f -- )
    abort" no more free blocks" ;

\ Find free physical block
: find-free-block ( -- phys-block-no )
    sf-open-directory
    FFFF
    scanning-directory do
        sf-read-next-word
        FFFF = if
            drop i leave
        then
    loop
    sf-deselect
    dup FFFF = ?no-free-block ;

\ Show usage statistics
: .sf-stat ( -- )
    sf-open-directory
    0 0
    scanning-directory do
        sf-read-next-word
        dup FFFF = if
            1+
        else
            swap 1+ swap
        then
    loop
    sf-deselect
    ." free: " . ." in use: " . cr ;

: ?entry-in-use ( f -- )
    abort" can't overwrite directory entry that is in use" ;

: assign-block ( log-block-no phys-block-no -- )
    sf-write-enable
    sf-directory-addr sf-start-writing
    100 /mod sf-send sf-send sf-deselect sf-wait ;

variable updated
variable scr
variable block-buf 400 allot

: .block ( -- )
    block-buf 100 dump \ only print first 256 bytes
    ;

: sf-read-block
    sf-start-reading
    block-buf 400 + block-buf do
        sf-read-next-byte i c!
    loop
    sf-deselect ;

: block-to-flash ( physblock -- page addr )
    2 lshift 100 /mod swap 8 lshift ;

: block ( block -- addr )
    find-block
    dup FFFF = if
        drop
        block-buf 400 0 fill
    else
        block-to-flash sf-read-block
    then ;

: update ( -- )
    1 updated ! ;

\ : flush ( -- )
\    updated @ if
\        scr @
