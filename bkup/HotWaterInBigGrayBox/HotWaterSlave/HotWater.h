/* HotWater.h */

#define    NUM_SCREENS           6
#define    MENU_ON_SECONDS      30
#define    BACK_LIGHT_TIMER_MIN 10
#define    NUM_DS18B20           5
#define    NUM_DS18B20_ADDRESS_BYTES  8
#define    NUM_IP_ADDRESS_BYTES  4
#define    NUM_MAC_ADDRESS_BYTES 6
#define    STIEBEL_TEMP_START  107

/* I2C stuff */
#define    MASTER_ADDRESS 1
#define    SLAVE_ADDRESS 2
#define    CLOCK_ADDRESS 0x68   /* decimal 104 */

/* Offsets into the Menu->item structure in EEPROM */
#define    WTR1HS2GG3_LOC      0
#define    AUTO_MAN_LOC        1
#define    FREEZE_LOC          2
#define    USE_TANK1_LOC       3
#define    USE_TANK2_LOC       4
#define    MAX_TANK_TEMP_LOC   5
#define    TEMP_DIFF_MAX_LOC   6
#define    TEMP_DIFF_MIN_LOC   7
#define    HEAT_ENABLED_LOC    8
#define    DUMP_TIME_HR_LOC    9
#define    DUMP_TIME_MIN_LOC  10
#define    ZONE_OFF_TIMER_LOC 11
#define    SENSOR_ERR_TH_LOC  12
#define    END_SWTCH_SEC_LOC  13
#define    IP_PORT_LOC        14
#define    IP_ADDRESS1_LOC    15
#define    MAC_ADDRESS1_LOC   19
#define    DFT_GATEWAY1_LOC   23
#define    SUBNET_MASK1_LOC   27

/* Offsets into the SensorsEE struct in EEPROM */
#define    COLLECTOR_LOC  0
#define    T1TOP_LOC      1
#define    T1BOT_LOC      2
#define    T2TOP_LOC      3
#define    T2BOT_LOC      4

struct sensorEE {
    byte addr[NUM_DS18B20_ADDRESS_BYTES];
    char location[10];
};

struct TempSensor {
    float temp;
    float avgsum;
    byte  avgcnt; /* max of 255. each sensor is read every 5 seconds so get ~21minutes of reads */
    byte  failcnt;
};

struct screens {
    char *ScreenName;
    void (*ScreenFunc)(byte, byte);
};

struct sensorsEE {
    struct sensorEE Collector;
    struct sensorEE T1Top;
    struct sensorEE T1Bot;
    struct sensorEE T2Top;
    struct sensorEE T2Bot;
};

struct item {
    char desc[12];
    byte min;
    byte max;
    byte dft;
    byte act;
};

struct menu {
    struct item Wtr1Hs2Gg3;
    struct item AutoMan;
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
    struct item IPport;
    struct item IP1;
    struct item IP2;
    struct item IP3;
    struct item IP4;
    struct item MAC1;
    struct item MAC2;
    struct item MAC3;
    struct item MAC4;
    struct item MAC5;
    struct item MAC6;
    struct item DftGateway1;
    struct item DftGateway2;
    struct item DftGateway3;
    struct item DftGateway4;
    struct item SubnetMask1;
    struct item SubnetMask2;
    struct item SubnetMask3;
    struct item SubnetMask4;
};

struct slave_status {
    byte    pin;
    boolean state;
    unsigned long start_millis;
    unsigned long elapsed_millis;
    char    desc[7];
};

/* Button Inputs */
#define    BACKBUTTONPIN    5
#define    UPBUTTONPIN      6
#define    DNBUTTONPIN      7
#define    SAVEBUTTONPIN    8

/* Heat Enabled inputs */
#define    HeatEnabledPin   3

/* Zone Valve End Switches */
#define    ZoneValveEndSwitchPin 17
#define    WizNetResetPin         9

/* DS18B20 temp sensor input pin */
#define    DSTempSensors1Pin     4
#define    DSTempSensors2Pin     2 /* Collector temp sensor */

/* Slave Pin outputs */
#define    NUM_SLAVE_PINS        9
#define    PUMP_PIN             17
#define    PUMP_GARAGE_PIN      16
#define    ZONE_WATER_TANK1_PIN 15
#define    ZONE_WATER_TANK2_PIN 14
#define    ZONE_HOUSE_PIN       10
#define    ZONE_GARAGE_PIN       9
#define    ZONE_STIEBEL_PIN      8
#define    BUZZER_PIN            6
#define    TRANSFORMER_PIN       7

/* Tank1 Tank2 House and Garage desc show up on the LCD display */
/* They need to be 5 chars + 1 blank space at the end */
/* The other desc are only used in server.pde in the dump section. */
/* They are all used in the slave display if the display is connected */
struct slave_status ss[NUM_SLAVE_PINS] = {
    {PUMP_PIN, LOW, 0ul, 0ul, "Pump  "},
    {PUMP_GARAGE_PIN, LOW, 0ul, 0ul, "GrgPmp"},
    {ZONE_WATER_TANK1_PIN, LOW, 0ul, 0ul, "Tank1 "},
    {ZONE_WATER_TANK2_PIN, LOW, 0ul, 0ul, "Tank2 "},
    {ZONE_HOUSE_PIN, LOW, 0ul, 0ul, "House "},
    {ZONE_GARAGE_PIN, LOW, 0ul, 0ul, "Garag "},
    {ZONE_STIEBEL_PIN, LOW, 0ul, 0ul, "Stieb "},
    {TRANSFORMER_PIN, LOW, 0ul, 0ul, "Trans "},
    {BUZZER_PIN, LOW, 0ul, 0ul, "Buzzer"},
};
/* display strings for LCD */
char    *Line0 = "?x00?y0";
char    *Line1 = "?x00?y1";
char    *Line2 = "?x00?y2";
char    *Line3 = "?x00?y3";
char    *Line0Clr = "?x00?y0?l";
char    *Line1Clr = "?x00?y1?l";
char    *Line2Clr = "?x00?y2?l";
char    *Line3Clr = "?x00?y3?l";
char    *Saved = "Saved";
char    *ClrScr = "?f";
char    *BkLtHalf = "?B40";
char    *BkLtOff = "?B00";
char    colon = ':';
char    Zero = '0';
char    *Space6 = "      ";
