\ MIDI sequencer testing stuff

hex
B100 constant seq-data
B180 constant seq-notes
B188 constant seq-pattern
B189 constant seq-tempo
B18B constant seq-status
B18C constant seq-midi-channel

: clear-pattern ( n -- )
    seq-pattern c!
    seq-data 80 0 fill ;

: clear-all-patterns ( -- )
    10 0 do
        i clear-pattern
    loop ;

: bpm! ( bpm -- )
    \ bpm in fixed point, one fractional digit.  120.0 => 1200
    dm 24 *
    dm 600000000. rot
    du/mod rot drop drop
    seq-tempo ! ;

: init-seq ( -- )
    0 seq-status c!
    dm 1200 bpm!
    clear-all-patterns
    8 0 do
        i dup seq-notes + c!
    loop ;

: pause ( -- )
    0 seq-status c! ;

: start ( -- )
    1 seq-status c! ;

: pattern! ( pattern channel -- )
    \ pattern is a binary bit mask, 16 bits
    4 lshift seq-data +
    dup 10 + swap do
        dup 8000 and 0<> i c!
        1 lshift
    loop
    drop ;

: note! ( note-no channel -- )
    seq-notes + c! ;

init-seq
bn 1000100010001000 0 pattern!
bn 0000100000001000 1 pattern!
bn 0010001000100010 2 pattern!
start

\ rotary encoders
hex
: encode-tempo
    dm 1200
    begin
        B061 c@ 0= if
            B070 c@ dup if
                dup 80 and if
                    FF00 or
                then
                + dup .
                1B emit 5B emit 4B emit 0D emit
                dup bpm!
            else
                drop
            then
        then
    key? until
    key drop ;
