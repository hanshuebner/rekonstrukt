
hex
B060 constant velocity
B061 constant frequency
B063 constant attack
B064 constant decay
B065 constant sustain
B066 constant release

decimal
: bing ( freq -- )
    frequency !
    128 velocity c!
    200 ms
    0 velocity c! ;

: pling ( -- )
    300 0 do
        i bing
    10 +loop ;
