G21 ; millimeters
G90 ; absolute positioning
M5 ; laser off
G0 X50 Y25 F3000
M3 S300
G2 X0 Y25 I-25 J0 F800
G2 X50 Y25 I25 J0
M5
G0 X0 Y0
