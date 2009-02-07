setMode -bs
setMode -bs
setCable -port auto
Identify 
identifyMPM 
assignFile -p 1 -file "C:/hans/rekonstrukt/ise/my_system09.bit"
Program -p 1 
Program -p 1 
setMode -pff
setMode -pff
addConfigDevice  -name "my_system09.mcs" -path "C:\hans\rekonstrukt\ise\"
setSubmode -pffserial
addDesign -version 0 -name "00"
setMode -pff
addDeviceChain -index 0
setMode -pff
addDeviceChain -index 0
setAttribute -configdevice -attr compressed -value "FALSE"
setAttribute -configdevice -attr compressed -value "FALSE"
setAttribute -configdevice -attr autoSize -value "FALSE"
setAttribute -configdevice -attr fileFormat -value "mcs"
setAttribute -configdevice -attr fillValue -value "FF"
setAttribute -configdevice -attr swapBit -value "FALSE"
setAttribute -configdevice -attr dir -value "UP"
setAttribute -configdevice -attr multiboot -value "FALSE"
setAttribute -configdevice -attr multiboot -value "FALSE"
setAttribute -configdevice -attr spiSelected -value "FALSE"
setAttribute -configdevice -attr spiSelected -value "FALSE"
addPromDevice -p 1 -size 0 -name xcf04s
setMode -pff
setMode -pff
deletePromDevice -position 1
setCurrentDesign -version 0
deleteDesign -version 0
setCurrentDesign -version -1
setMode -pff
addConfigDevice -size 512 -name "my_system09.mcs" -path "C:\hans\rekonstrukt\ise\/"
setSubmode -pffserial
setAttribute -configdevice -attr dir -value "UP"
setAttribute -configdevice -attr flashDataWidth -value "8"
addPromDevice -p 1 -size 0 -name xcf04s
setMode -pff
setSubmode -pffserial
setAttribute -configdevice -attr dir -value "UP"
addDesign -version 0 -name "0000"
setMode -pff
addDeviceChain -index 0
setAttribute -design -attr name -value "0"
addDevice -p 1 -file "C:/hans/rekonstrukt/ise/my_system09.bit"
setMode -pff
setSubmode -pffserial
setAttribute -configdevice -attr fillValue -value "FF"
setAttribute -configdevice -attr fileFormat -value "mcs"
setAttribute -configdevice -attr dir -value "UP"
setAttribute -configdevice -attr path -value "C:\hans\rekonstrukt\ise\/"
setAttribute -configdevice -attr name -value "my_system09.mcs"
generate
setCurrentDesign -version 0
setMode -bs
setMode -bs
assignFile -p 2 -file "C:/hans/rekonstrukt/ise/my_system09.mcs"
setAttribute -position 2 -attr readnextdevice -value "(null)"
Program -p 2 -e -v 
saveProjectFile -file "C:\hans\rekonstrukt\ise/ise.ipf"
setMode -pff
setMode -pff
saveProjectFile -file "C:/hans/rekonstrukt/ise/ise.ipf"
setMode -bs
deleteDevice -position 3
deleteDevice -position 2
deleteDevice -position 1
setMode -pff
deletePromDevice -position 1
setCurrentDesign -version 0
deleteDevice -position 1
deleteDesign -version 0
setCurrentDesign -version -1
setMode -bs
