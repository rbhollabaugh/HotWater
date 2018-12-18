#!ksh
#ee.sh

# -n = nowrite
# -v = verbose
# -u = unsafe operation - set fuse bits
# -D = disable automatic flash erase
# -F = Over ride invalic signature check

EEFILE=./applet/menu.cpp.eep
PP=$(echo $AVR|sed "s/\/cygdrive\/c/c:/")
CPU=m168
#CPU=m328p

avrdude -C$PP/hardware/tools/avr/etc/avrdude.conf -v -p$CPU -cusbtiny -b57600 -Ueeprom:w:$EEFILE:i


#c:winavrbinavrdude -v -F -p ATmega8 -c avr910 -P com4 -U eeprom:w:<yourfile>.eep:i
