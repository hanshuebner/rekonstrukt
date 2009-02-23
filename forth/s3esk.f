\ Software for the Spartan-3E Starter Kit

hex
B020 constant vdu
vdu constant vdu-char
vdu 1 + constant vdu-color
vdu 2 + constant vdu-hcursor
vdu 3 + constant vdu-vcursor
vdu 4 + constant vdu-voffset

decimal

: vdu-save ( -- h v ) vdu-hcursor c@ vdu-vcursor c@ ;
: vdu-restore ( h v -- ) vdu-vcursor c! vdu-hcursor c! ;
: vdu-cr ( -- ) 0 vdu-hcursor c! ;
: vdu-clreol ( -- )
    vdu-hcursor c@
    dup 80 swap - 0 do
        bl vdu-char c!
        1 vdu-hcursor c+!
    loop
    vdu-hcursor c! ;
: vdu-lf ( -- )
    vdu-vcursor c@
    dup 24 = if
        drop vdu-voffset c@ 1+ 25 mod vdu-voffset c!
        vdu-save vdu-cr vdu-clreol vdu-restore
    else
        1+ 25 mod vdu-vcursor c!
    then ;
: vdu-clreos ( -- )
    vdu-save
    vdu-clreol
    25 vdu-vcursor c@ - 0 do
        vdu-cr vdu-lf vdu-clreol
    loop
    vdu-restore ;
: vdu-home ( -- )
    0 0 vdu-restore ;
: vdu-emit ( c -- )
    dup 10 = if \ linefeed
        vdu-lf drop exit
    then
    dup 13 = if \ return
        vdu-cr drop exit
    then
    dup 8 = if \ backspace
        vdu-hcursor c@ if -1 vdu-hcursor c+! then
        drop exit
    then
    vdu-char c!
    vdu-hcursor @ 80 = if
        vdu-cr
        vdu-lf
    else
        1 vdu-hcursor c+!
    then ;
: cls vdu-home vdu-clreos ;

: to-vdu ['] vdu-emit 'emit ! ;
: to-uart [ inside ] ['] uart-emit [ forth ] 'emit ! ;

hex
B030 constant leds
B031 constant switches
B032 constant rotary
B033 constant lcd
55 leds c!

decimal
: poll-keys
    begin
        switches c@ .
        32 emit
        rotary c@ .
        cr
    key? until
    key drop ;

hex
: send-lcd ( bb -- )
    dup lcd c!
    dup 10 or lcd c!
    lcd c! ;

: lcd-command ( bb -- )
    10 /mod
    send-lcd
    send-lcd ;

: lcd-data ( bb -- )
    10 /mod
    40 or send-lcd
    40 or send-lcd ;

: lcd-init ( -- )
    200 ms
    03 send-lcd
    200 ms
    03 send-lcd
    200 ms
    03 send-lcd
    200 ms
    02 send-lcd
    28 lcd-command \ function set
    06 lcd-command \ entry mode set
    0C lcd-command \ display on/off
    01 lcd-command \ clear screen
    30 ms ;

: lcd-string ( adr count -- )
    0 do
        dup c@ lcd-data 1+
    loop
    drop ;

: lcd-line ( line-no -- )
    40 * 80 or lcd-command ;

: banner ( -- )
    lcd-init
    0 lcd-line " Maisforth an601 " lcd-string ;

banner
    
decimal
: up ( -- )
    1
    8 0 do
        dup leds c!
        2 *
        1000 ms
    loop
    drop ;

: down ( -- )
    128
    8 0 do
        dup leds c!
        2 /
        1000 ms
    loop
    drop ;

: updown ( -- )
    begin
        up
        down
        key?
    until
    key drop ;

\ assembler tests

hex
code set-leds
    B030 # ldx
    reg d puls
    x ) stb
    next
end-code

hex
B040 constant spi-lsb
B041 constant spi-msb
B042 constant spi-status
B043 constant spi-config

FF spi-config c!

hex
: spi-send
    100 /mod
    spi-msb c!
    spi-lsb c!
    3 spi-status c! ;

: spi-test
    begin
        FFFF 0 do
            i spi-send
        loop
        key?
    until
    key drop ;

: matrix-init
    C00 spi-send \ shutdown
    A0F spi-send \ intensity
    900 spi-send \ no decode
    B07 spi-send \ scan all digits
    100 spi-send \ clear digit 1
    200 spi-send \ clear digit 2
    300 spi-send \ clear digit 3
    400 spi-send \ clear digit 4
    500 spi-send \ clear digit 5
    600 spi-send \ clear digit 6
    700 spi-send \ clear digit 7
    800 spi-send \ clear digit 8
    C01 spi-send \ exit shutdown
;

: light-show
    8 0 do
        5 0 do
            i 1 + 100 * dup
            1 j lshift +
            spi-send
            600 ms
            spi-send
        loop
    loop ;

: big-lights
    begin
        light-show
    key? until
    key drop ;

\ misc stuff
decimal
: at-xy ( y x -- )
    swap
    27 emit
    91 emit
    s>d d.string type
    59 emit
    s>d d.string type
    72 emit ;
