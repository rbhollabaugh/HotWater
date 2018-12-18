##!pdksh
# data
# ram
# zero
# error
# sensors
# clockset
# clockread
# format for clock set and read
#        23:41:14:11:01:09:1
#        hr:min:sec:month:day:yr:dayofweek
# The command 'web.sh -clockset' produces this string to the web server
#        GET /clockset=01:25:25:11:01:09:1 HTTP/1.1

TMPFILE=$0$$
trap 'rm $TMPFILE' 0 1 2

IP="http://192.168.5.30:6"

if test $# -eq 0
then
	echo "Use: $0 -dump -data -ram -zero -error -sensors -clockset -clockread -param=EEMEMidx:value"
	exit
fi

while test $# -gt 0
do
	arg=$1
	case $1 in
		-clockset) cmd=${arg#-}$(date "+=%X:%m:%d:%y:")
			dow=$(date "+%w")
			let dow=$dow+1
			cmd="${cmd}${dow}"
		;;
		*) cmd=${arg#-};;
	esac
	shift
done 

perl -MLWP::Simple -e "getprint '$IP/$cmd'" > $TMPFILE

case $cmd in
	dump)
	echo "Desc:Min:Max:Dft:Actual"
	;;
esac
cat $TMPFILE
#cp $TMPFILE xx

####**** This struct has changed since it was copied here *****
#/* Menu is the data struct that holds the configurable parameters. */
#/* Loaded into EEPROM. These numbers are all BYTES (max 255). */
#/* desc,min,max,dft,act*/
#struct menu EEMEM Menu = 
#{
#    {"Wtr1Hs2Gg3 ", 1, 3, 1, 1},     /* Heat Water (1), House (2), Garage (3)*/
#    {"Auto1/Man0 ", 0, 1, 1, 1},     /* Auto mode or manual mode */
#    {"UseTank1   ", 0, 1, 1, 1},     /* use 1 or don't use 0 this tank */
#    {"UseTank2   ", 0, 1, 1, 1},     /* use 1 or don't use 0 this tank */
#    {"MaxTankTemp", 140, 180, 170, 170}, /* max tank temp - both tanks */
#    {"TempDiffMax", 15, 20, 18, 18}, /* turn on temp diff between coll & tank*/
#    {"TempDiffMin", 3, 8, 5, 5},     /* min temp diff between coll and tank */
#    {"HeatEnable ", 0, 2, 2, 2},     /* 1-house heat on. 0-house heat off. 2-auto - input from house thermostat */
#    {"DumpTimeHr ", 0, 23, 16, 16},  /* hr time to dump collector to dump dev*/
#    {"DumpTimeMin", 0, 59, 15, 15},  /* minute for dump time */
#    {"ZoneOffTime", 0, 30, 20, 15},  /* minutes to keep a zone valve open after the pump turns off */
#    {"SensorErrTh", 0, 254, 20, 0},  /* sensor error cnt threshold before sounding the buzzer - 0 is off */
#    {"EndSwtchSec", 3, 10, 5, 5},    /* number of seconds to wait for the zone valve end switch to close before setting error code */
#    {"IPport     ", 1, 255, 80, 80}, /* port to listen on */
#    {"IPAddress1 ", 0, 255, 192, 192},
#    {"IPAddress2 ", 0, 255, 168, 168},
#    {"IPAddress3 ", 0, 255, 5, 5},
#    {"IPAddress4 ", 0, 255, 30, 30},
#    {"MACAddress1", 0, 255, 222, 222},
#    {"MACAddress2", 0, 255, 222, 222},
#    {"MACAddress3", 0, 255, 222, 222},
#    {"MACAddress4", 0, 255, 222, 222},
#    {"MACAddress5", 0, 255, 222, 222},
#    {"MACAddress6", 0, 255, 222, 222}
#};
