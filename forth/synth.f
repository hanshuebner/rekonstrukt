
hex
B060 constant frequency
B064 constant velocity
B065 constant attack
B066 constant decay
B067 constant sustain
B068 constant release
B069 constant waveform

decimal
: bing ( dfreq -- )
    frequency 2 + !
    frequency !
    128 velocity c!
    50 ms
    0 velocity c!
    100 ms
;

: pling ( -- )
    5 0 do
        1 i 3000 * bing
    1 +loop ;
