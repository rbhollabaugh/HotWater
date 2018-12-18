/* HotWater.h */

#define    NUM_SCREENS           6
#define    MENU_ON_SECONDS      30
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
#define    USE_TANK1_LOC     0
#define    USE_TANK2_LOC     1
#define    MAX_TANK_TEMP_LOC 2
#define    TEMP_DIFF_MAX_LOC 3
#define    TEMP_DIFF_MIN_LOC 4
#define    AUTO_MAN_LOC      5
#define    HEAT_ENABLED_LOC  6
#define    DUMP_TIME_HR_LOC  7
#define    DUMP_TIME_MIN_LOC 8
#define    ZONE_OFF_TIMER_LOC 9
#define    SENSOR_ERR_TH_LOC 10
#define    END_SWTCH_SEC_LOC 11
#define    IP_PORT_LOC      12
#define    IP_ADDRESS1_LOC  13
#define    MAC_ADDRESS1_LOC 17

/* Offsets into the SensorsEE struct in EEPROM */
#define    COLLECTOR_LOC  0
#define    T1TOP_LOC 1
#define    T1BOT_LOC 2
#define    T2TOP_LOC 3
#define    T2BOT_LOC 4

struct sensorEE {
    byte addr[NUM_DS18B20_ADDRESS_BYTES];
    char location[10];
};

struct sensorRAM {
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
    struct item UseTank1;
    struct item UseTank2;
    struct item MaxTankTemp;
    struct item TempDiffMax;
    struct item TempDiffMin;
    struct item AutoMan;
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
};

struct slave_status {
    byte    pin;
    boolean state;
    unsigned long elapsed_millis;
    char    *desc;
};

/* Button Inputs */
#define    BACKBUTTONPIN    3
#define    UPBUTTONPIN      4
#define    DNBUTTONPIN      5
#define    SAVEBUTTONPIN    6

/* Heat Enabled inputs */
#define    HeatEnabledPin  14

/* Zone Valve End Switches */
#define    ZoneValveEndSwitchPin 15
#define    WizNetResetPin 16

/* DS18B20 temp sensor input pin */
#define    DSTempSensors1Pin  7
#define    DSTempSensors2Pin  8

/* Slave Pin outputs */
#define    NUM_SLAVE_PINS 8
#define    PUMP_PIN 2
#define    PUMP_GARAGE_PIN 3
#define    ZONE_WATER_TANK1_PIN 4
#define    ZONE_WATER_TANK2_PIN 5
#define    ZONE_HOUSE_PIN 6
#define    ZONE_GARAGE_PIN 7
#define    ZONE_STIEBEL_PIN 8
#define    BUZZER_PIN 9
