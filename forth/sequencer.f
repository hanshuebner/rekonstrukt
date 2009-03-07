\ MIDI sequencer testing stuff

hex
B100 constant seq-data
B180 constant seq-notes
B188 constant seq-pattern
B189 constant seq-tempo
B18B constant seq-status

: clear-pattern ( n -- )
    seq-pattern c!
    seq-data 80 0 fill ;

: clear-all-patterns ( -- )
    10 0 do
        i clear-pattern
    loop ;

: init-seq ( -- )
    0 seq-status c!
    4000 seq-tempo !
    clear-all-patterns
    8 0 do
        i dup seq-notes + c!
    loop ;

: pause ( -- )
    0 seq-status c! ;

: start ( -- )
    1 seq-status c! ;

: set-pattern ( pattern channel -- )
    \ pattern is a binary bit mask, 16 bits
    4 lshift seq-data +
    dup 10 + swap do
        dup 8000 and 0= i c!
        1 lshift
    loop
    drop ;

init-seq
bn 1000100010001000 0 set-pattern
bn 0000100000001000 1 set-pattern
bn 0010001000100010 2 set-pattern
