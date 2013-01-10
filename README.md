rekonstrukt is a Forth environment running on a CPU core in an FPGA.
It provides for a interactive ANS Forth environment running on the
target platform.  The Forth environment is bootstrapped using gforth,
so it can be cross compiled, too.

rekonstrukt is based on the Maisforth Forth environment written by
[Albert Nijhof](http://home.hccnet.nl/anij/index.html) and the
[System09](http://members.optushome.com.au/jekent/system09/index.html)
6809 compatible VHDL SoC written by John Kent.  Also included is the
usim mc6809 simulator written by Ray Bellis which can be used to
experiment with Maisforth on a PC.

The FPGA IP cores are written in VHDL and licensed under the GPL.  The
Forth software is licensed under the MIT license.  usim is licensed
under GPLv2.

The current version of rekonstrukt runs on the Xilinx/Diligent
[Spartan-3E Starter Kit](Spartan3EStarterKit).  A bitstream for this
board is
[available](http://rekonstrukt.googlecode.com/files/rekonstrukt-s3e-sk.bit).  
You'll need a serial console *configured at 19200 bps,
8n1*, connected to the female serial port.  Rekonstrukt has also been
ported to the
[http://www.xilinx.com/products/devkits/HW-SPAR3A-SK-UNI-G.htm Spartan
3A Starter Kit] and the [Avnet Spartan-3A Evaluation kit](http://www.em.avnet.com/spartan3a-evl).  
Please be sure to check out the
[Subversion log](http://code.google.com/p/rekonstrukt/updates/list) to
find which version to check out for a particular board.

You can [browse](http://code.google.com/p/rekonstrukt/source/browse/#svn/trunk)
 the source code or see
[instructions](http://code.google.com/p/rekonstrukt/source/checkout) on
how to check it out from the Subversion repository.  There are
[instructions](RebuildFromSource) how to rebuild Maisforth from source.

Please visit Albert Nijhof's [page](http://home.hccnet.nl/anij/index.htmlhome) 
for some tutorials on using ANS Forth, available in Dutch,
German and English.  There also are some [links](LinkS) to
documentation relevant to Maisforth.

Please don't hesitate to get in touch:  hans.huebner@gmail.com

# Top-Level Directory Structure #

This file documents the top level directory structure:

forth     Software written in Forth for Rekonstrukt.
ise       Xilinx ISE project directory
maisforth Source code for the Maisforth kernel
mkfiles   David Burnett's make library for Xilinx ISE
testbench VHDL test benches for some IP cores
tools     Various tools used to recompile Rekonstrukt
usim      Ray Brellis' MC6809 simulator written in C++
vhdl      VHDL sources for the Rekonstrukt hardware
