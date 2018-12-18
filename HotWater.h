/* HotWater.h rbh 02/2011 */

typedef unsigned long time_t; 
/* unsigned long will go to 4294967295 seconds */
/* which is Sun, 07 Feb 2106 06:28:15 GMT */

#define    NUM_SCREENS           6
#define    MENU_ON_SECONDS      30
#define    BACKLIGHT_TIMER_MIN   2
#define    NUM_DS18B20           6
#define    NUM_DS18B20_ADDRESS_BYTES  8
#define    NUM_IP_ADDRESS_BYTES  4
#define    NUM_MAC_ADDRESS_BYTES 6
#define    NUM_HISTORY_RECS     10
#define    NUM_TEMP_READINGS    10
#define    NUM_MSG              10 /* number of msg */
#define    MSG_LENGTH           11
#define    STIEBEL_TEMP_START  107

#define    NTP_PACKET_SIZE      48
#define    NTP_UDP_PORT         8888

/* Offsets into the Menu->item structure in EEPROM */
#define    WTR1HS2GG3_LOC      0
#define    FREEZE_LOC          1
#define    USE_TANK1_LOC       2
#define    USE_TANK2_LOC       3
#define    MAX_TANK_TEMP_LOC   4
#define    TEMP_DIFF_MAX_LOC   5
#define    TEMP_DIFF_MIN_LOC   6
#define    HEAT_ENABLED_LOC    7
#define    DUMP_TIME_HR_LOC    8
#define    DUMP_TIME_MIN_LOC   9
#define    ZONE_OFF_TIMER_LOC 10
#define    SENSOR_ERR_TH_LOC  11
#define    END_SWTCH_SEC_LOC  12
#define    BEEP_ENABLE_LOC    13
#define    NTP_TIME_FLAG_LOC  14
#define    IP_PORT_LOC        15
#define    NTP_IP_ADDRESS1_LOC 16

/* Offsets into the SensorsEE struct in EEPROM */
#define    COLLECTOR_LOC  0
#define    T1TOP_LOC      1
#define    T1BOT_LOC      2
#define    T2TOP_LOC      3
#define    T2BOT_LOC      4
#define    AMBIENT_LOC    5

char  colon = ':'; /* Used primarily in server.pde */

/* Definitions for the graphics on the display */
#define    GARAGE_WIDTH 10 //glcdv3 use 1 less for all widths
#define    TANK1_WIDTH  34 //33
#define    TANK2_WIDTH  34 //33
#define    HOUSE_WIDTH  10 //9
#define    COLLECTOR_WIDTH 35 //34

#define    GARAGE_X_POS 0
#define    TANK1_X_POS  GARAGE_WIDTH + 1  //glcdv3 use +2 instead of +1
#define    TANK2_X_POS  TANK1_X_POS+TANK1_WIDTH +1
#define    HOUSE_X_POS  TANK2_X_POS+TANK2_WIDTH +1
#define    COLLECTOR_X_POS  HOUSE_X_POS+HOUSE_WIDTH + 1

#define    ZONE_Y_POS   10
#define    ZONE_HEIGHT  29 //glcdv3 use 28
#define    COLLECTOR_HEIGHT ZONE_HEIGHT/2

/* PWM LCD backlight brightness */
#define    BACKLIGHT_OFF       0
#define    BACKLIGHT_HALF     70
#define    BACKLIGHT_FULL    255

struct TempSensor {
    float avgtemp;
    float temp[NUM_TEMP_READINGS];
    byte  failcnt;
};

struct sensorEE {
    byte addr[NUM_DS18B20_ADDRESS_BYTES];
    char location[10];
};

struct screens {
    const char *ScreenName;
    void (*ScreenFunc)(byte, byte);
};

/* Informational message displayed on the display */
struct message {
    char line1[MSG_LENGTH+1];
    char line2[MSG_LENGTH+1];
    int cnt;
};

struct sensorsEE {
    struct sensorEE Collector;
    struct sensorEE T1Top;
    struct sensorEE T1Bot;
    struct sensorEE T2Top;
    struct sensorEE T2Bot;
    struct sensorEE Ambient;
};

struct item {
    char desc[14];
    byte min;
    byte max;
    byte act;
};

struct output {
    char desc[11];
    byte state;
    byte pin;
};

/* The pumps must be after the zones in the structure. */
/* The loops in CalcHotWater depends on the zones being */
/* done before the pumps. */
/* Manual must be at the 0 position and Stiebel the last. */
struct stat {
    struct output Manual;
    struct output Tank1;
    struct output Tank2;
    struct output House;
    struct output Garage;
    struct output Pump;
    struct output PumpGarage;
    struct output Stiebel;
};

struct hist_item {
    time_t   unixtime;
    struct   TempSensor TS[NUM_DS18B20];
    struct   stat CS;
};
    
struct mytime {
    byte  sec;   /* Seconds [0,60] */
    byte  min;   /* Minutes [0,59] */
    byte  hour;  /* Hour [0,23]    */
    byte  mday;  /* Day of month [1,31] */
    byte  month; /* Month of year [1,12] */
    int   year;  /* Years since 1900     */
    byte  wday;  /* Day of week [1,7] Sunday =1 */
    byte  isdst; /* Daylight Savings flag */
};

struct menu {
    struct item Wtr1Hs2Gg3;
    struct item Freeze;
    struct item UseTank1;
    struct item UseTank2;
    struct item MaxTankTemp;
    struct item TempDiffMax;
    struct item TempDiffMin;
    struct item HeatEnable;
    struct item DumpTimeHr;
    struct item DumpTimeMin;
    struct item ZoneOffTimer;
    struct item SensorErrTh;
    struct item EndSwtchSec;
    struct item BeepEnable;
    struct item NTPTimeFlag;
    struct item IPport;
    struct item NTPIP1;
    struct item NTPIP2;
    struct item NTPIP3;
    struct item NTPIP4;
};

/* Pin Inputs */
#define    UPBUTTONPIN      2
#define    DNBUTTONPIN      3
#define    SAVEBUTTONPIN    4
#define    BACKBUTTONPIN    5
#define    HeatEnabledPin  38
#define    ZoneValveEndSwitchPin 1

/* Pin outputs */
#define    BACKLIGHT_PIN    0
#define    LED_PIN          6
#define    WIZRESET_PIN    24
#define    DSTEMP1_PIN     25 /* Collector Temp Sensor */
#define    DSTEMP2_PIN     26 /* Tank Sensors */
#define    BUZZER_PIN      27
#define    PUMP_PIN        45
#define    PUMP_GARAGE_PIN 44
#define    TANK1_PIN       43
#define    TANK2_PIN       42
#define    HOUSE_PIN       41
#define    GARAGE_PIN      40
#define    STIEBEL_PIN     39
