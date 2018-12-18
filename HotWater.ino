/* HotWater.ino */
/* 02/2011 RBH */
/* Arduino 1.0 */
/* Uses downloaded libraries 'Bounce', 'MemoryFree', 'OneWire', 'glcd' */
/* CPU is AT90USB1286  Teensy++ 2.0 - Used as configured from pjrc.com*/
/* 128k program flash - 8k SRAM - 4k EEPROM */
/* 16MHz external clock */
/* 4/1/2011 - GLCD.print(float, prec) does not work */
/* 4/42/15 - Changed to openGLCD 1.0rc2 from glcdv3 lib */
/*   DrawRoundRect() radius has changed */
/* arduino 1.6.3 */
/* ks0108 from pjrc does not work with 1.6.3 */
/* lib glcdv3 does not work with 1.6.3 and is no longer supported anyway */
/* openGLCD works with 1.6.3 changes needed in position of boxes in HotWater.h */
/* 8/30/15 Arduino 1.6.5 Teensyduino 1.24 */
/* 1/14/2016 Arduino 1.6.7 Teensyduino 1.27 */
/* 5/10/2016 Arduino 1.6.8 Teensyduino 1.28 */
/* 8/03/2016 Arduino 1.6.9 Teensyduino 1.29 */
/* Library Bounce to Bounce2, Create func defs as needed in the top of this file */
/* 12/20/2016 Arduino 1.6.13 Teensyduino 1.33 */
/* 12/20/2016 OpenGLCD 1.0rc3 */
/* 10/20/2017 Arduino 1.8.5 Teensyduino 1.40 */
/* 12/26/2917 Use MsTimer2 lib to increment UnixTime variable every second. More accurate than using */
/* Millis(). Note that timer2 makes PWM not usable on pins 1 and 24. */
/* 3/7/2018 - Arduino 1.8.5 with updated libs and Teensy 141 - Ethernet does not work - Teensy 140 works */
/* 5/16/2018 - Remove hardcoded ip address and do DHCP teensy 141 */

/* Solar hot water controller */
#define TEENSY_VERSION 144

#include <SPI.h>
#include <OneWire.h>
#include <EEPROM.h>
#include <Bounce2.h>
#include <openGLCD.h>
#include "HotWater.h"
#include "MemoryFree.h"
#include <Ethernet.h>
#include <MsTimer2.h>

byte mac[] = { 0xDE, 0xDE, 0xDE, 0xDE, 0xDE, 0xE0 };

/* Menu is the data struct that holds the configurable parameters. */
/* Loaded into EEPROM for permanent storage. These numbers are all BYTES */
/* (max 255 and min 0). */
/* desc,min,max,act*/
struct menu EEMEM Menu = 
{
    {"Wtr1Hs2Gg3 ", 1, 3, 1},     /* 0 Heat Water (1), House (2), Garage (3) */
    {"Freeze     ", 0, 50, 27},   /* 1 Degrees below freezing before pump on */
    {"UseTank1   ", 0, 1, 1},     /* 2 use 1 or don't use 0 this tank */
    {"UseTank2   ", 0, 1, 1},     /* 3 use 1 or don't use 0 this tank */
    {"MaxTankTemp", 120, 180, 155},/*4  max tank temp - applies to both tanks */
    {"TempDiffMax", 10, 24, 18},  /* 5 turn on temp diff between collectr & tnk */
    {"TempDiffMin", 3, 10, 5},    /* 6 min temp diff between collector and tank */
    {"HeatEnable ", 0, 2, 2},     /* 7 1-house heat on. 0-house heat off. */
                                  /*   2-auto - input from house thermostat */
    {"DumpTimeHr ", 0, 23, 16},   /* 8 hour when to dump collector to dump */
                                  /*   device - house or garage */
    {"DumpTimeMin", 0, 59, 15},   /* minute for dump time */
    {"ZoneOffTime", 0, 30, 20},   /* time in minutes to keep a zone valve */
                                  /* open after the pump turns off */
    {"SensorErrTh", 0, 254, 10},  /* sensor error cnt threshold before */
                                  /* sounding the buzzer - 0 is off */
    {"EndSwtchSec", 10, 60, 35},  /* number of seconds to wait for the zone */
                                  /* valve end switch to close before alarm */
    {"BeepEnable   ", 0, 1, 1},   /* Beep on or off */
    {"NTPTimeFlag  ", 0, 1, 0},   /* 1=get unixtime from NTP server; 0=no */
    {"IPport       ", 1, 255, 6}, /* port to listen on for connections. */
    {"NTPIPAddress1", 0, 255, 96},  /* Bridgewater NJ */
    {"NTPIPAddress2", 0, 255, 47},
    {"NTPIPAddress3", 0, 255, 67},
    {"NTPIPAddress4", 0, 255, 105}
};

/* desc, state, pin */
struct stat CurrStatus = 
{
    {"Manual    ", 0, 0},
    {"Tank1     ", 0, TANK1_PIN},
    {"Tank2     ", 0, TANK2_PIN},
    {"House     ", 0, HOUSE_PIN},
    {"Garage    ", 0, GARAGE_PIN},
    {"Pump      ", 0, PUMP_PIN},
    {"PumpGarage", 0, PUMP_GARAGE_PIN},
    {"Stiebel   ", 0, STIEBEL_PIN}
};
struct stat PrevStatus;

/* Function definitions to keep the linker happy. */
/* These ones in particular are used before the function is defined. */
/* Could be placed in a header file. */

void MainScreen(byte level, byte pin);
void ConfigParam(byte level, byte pin);
void Manual(byte level, byte pin);
void SensorConfig1(byte level, byte pin);
void SensorConfig2(byte level, byte pin);
void Information(byte level, byte pin); 
byte GetEEact(byte offset);
void UpdUnixTime();

/* If the order of screens changes in this array */
/* then change ConfigParam() */
struct screens Screens[NUM_SCREENS] = {
    {"MainScreen", MainScreen},
    {"Config Param", ConfigParam},
    {"Manual", Manual},
    {"SensorConfig1", SensorConfig1},
    {"SensorConfig2", SensorConfig2},
    {"Information", Information}
};

/* Temp sensor data structures */
/* SensorsEE is the sensor data that does not change. It's loaded into */
/* EEPROM using avrdude after Arduino uploads the program into flash memory. */

struct sensorsEE EEMEM SensorsEE =
{
    {{0x28,0xD8,0xBD,0xBA,0x02,0x00,0x00,0x1D}, "Collector"},
    {{0x28,0x8D,0x67,0x9E,0x01,0x00,0x00,0xA1}, "T1Top    "},
    {{0x28,0x7E,0x55,0x9E,0x01,0x00,0x00,0x8D}, "T1Bot    "},
    {{0x28,0x56,0x4C,0x9E,0x01,0x00,0x00,0x15}, "T2Top    "},
    {{0x28,0x7E,0x58,0x9E,0x01,0x00,0x00,0x61}, "T2Bot    "},
    {{0x28,0x6C,0xB0,0xBA,0x02,0x00,0x00,0x2A}, "Ambient  "}
};

/* Temp Sensor temperature readings */
struct TempSensor TSdata[NUM_DS18B20];
struct hist_item History[NUM_HISTORY_RECS];
struct message Msg[NUM_MSG];

OneWire    ds1(DSTEMP1_PIN);
OneWire    ds2(DSTEMP2_PIN);
boolean    ReadTempFlag = false;
boolean    BuzzerState = false;
boolean    BeepState = false;

boolean    ZoneValveEndSwitch = false;
byte       ZoneValveEndSwitchTimer = 0;
int        ZoneTimerCnt = 0;
boolean    CollectorTooHotFlag = false;
byte       CollectorTooHotTimer = 0;
boolean    HeatEnabled = false;
boolean    DumpFlag = false;

/* TurnOnTemp used in temp display func and Calc() */
float  TurnOnTemp;

/* The active zone valve pin. Global so calc and the screen func can get it */
byte ActiveZonePin;

byte     BackLightTimer = 0;
boolean  BallTimerFlag = false;

time_t UnixTime = 0UL;
struct mytime hwtime;
boolean UnixTimeIsGood = false;
boolean NTPRequestPending = false;
time_t UnixTimeTimeStamp = 0UL;

byte   CurScreenIdx = 0, MenuTimerCnt = 0;

Bounce dbBackSwitch = Bounce();
Bounce dbUpSwitch = Bounce();
Bounce dbDnSwitch = Bounce();
Bounce dbSaveSwitch = Bounce();
//Bounce dbHeatEnabled = Bounce();
Bounce dbZoneValveEndSwitch = Bounce();

EthernetServer server((int)GetEEact(IP_PORT_LOC));
EthernetUDP Udp;

void setup()
{
    byte sensorcnt, readingnum;

    pinMode(WIZRESET_PIN, OUTPUT);
    pinMode(BACKLIGHT_PIN, OUTPUT);
    pinMode(BUZZER_PIN, OUTPUT);
    pinMode(PUMP_PIN, OUTPUT);
    pinMode(PUMP_GARAGE_PIN, OUTPUT);
    pinMode(TANK1_PIN, OUTPUT);
    pinMode(TANK2_PIN, OUTPUT);
    pinMode(HOUSE_PIN, OUTPUT);
    pinMode(GARAGE_PIN, OUTPUT);
    pinMode(STIEBEL_PIN, OUTPUT);
    pinMode(LED_PIN, OUTPUT);

    pinMode(UPBUTTONPIN, INPUT_PULLUP);
    pinMode(DNBUTTONPIN, INPUT_PULLUP);
    pinMode(SAVEBUTTONPIN, INPUT_PULLUP);
    pinMode(BACKBUTTONPIN, INPUT_PULLUP);
    pinMode(HeatEnabledPin, INPUT_PULLUP);
    pinMode(ZoneValveEndSwitchPin, INPUT_PULLUP);

    dbBackSwitch.attach(BACKBUTTONPIN);
    dbBackSwitch.interval(10);
    
    dbUpSwitch.attach(UPBUTTONPIN);
    dbUpSwitch.interval(10);
    
    dbDnSwitch.attach(DNBUTTONPIN);
    dbDnSwitch.interval(10);
    
    dbSaveSwitch.attach(SAVEBUTTONPIN);
    dbSaveSwitch.interval(10);
    
    //dbHeatEnabled.attach(HeatEnabledPin);
    //dbHeatEnabled.interval(10);
    
    dbZoneValveEndSwitch.attach(ZoneValveEndSwitchPin);
    dbZoneValveEndSwitch.interval(10);
    
    GLCD.Init();
    GLCD.ClearScreen(); 
    GLCD.SelectFont(System5x7, BLACK);
    BackLight(BACKLIGHT_FULL);
    SetupForNewScreen();
    
    memset(TSdata, 0, sizeof(TSdata));
    memset(History, 0, sizeof(History));
    memset(Msg, 0, sizeof(Msg));
    memset(&PrevStatus, 0, sizeof(PrevStatus));
    StartWiznet();
    for(sensorcnt=0; sensorcnt < NUM_DS18B20; sensorcnt++)
        for(readingnum=0; readingnum < NUM_TEMP_READINGS; readingnum++)
            TSdata[sensorcnt].temp[readingnum] = 999;
    delay(100);
    if(GetEEact(NTP_TIME_FLAG_LOC))
        sendNTPpacket(); /* request NIST time */
    MsTimer2::set(1000, UpdUnixTime); /* 1000ms call UpdUnixTime() */
    MsTimer2::start();
}

void loop()
{
    static byte    sensor_cnt = 0, level = 0, err_cnt;
    static boolean startflg = true;
    static boolean tempsgood = false;
    struct sensorEE ssEE;
    OneWire *dsptr;
    float temp;
    byte ret;
    
    if(!CheckEEPROM())
        return;
    if(ReadTempFlag) /* no need to do these things w/every loop */
    {
        dbZoneValveEndSwitch.update();
        ZoneValveEndSwitch = !dbZoneValveEndSwitch.read();  /* active low */
        
        if(GetEEact(HEAT_ENABLED_LOC) == 2)
        {
          //dbHeatEnabled.update();
          //HeatEnabled = !dbHeatEnabled.read();  /* active low */
          if(analogRead(HeatEnabledPin) < 512)
              HeatEnabled = true;
          else
              HeatEnabled = false;
        }
        else
        {
            if(GetEEact(HEAT_ENABLED_LOC) == 0)
                HeatEnabled = true;
            else
                HeatEnabled = false;
        }
    }

    /* level 0 = new screen w/just heading */
    /* level 1 = heading + parameter name  */
    /* level 2 = heading + parameter + parameter options */
    /* level 3 = all of above plus save button pressed after level 2 */
    /* save button advances to new levels except level 3 = save */
    /* back button goes back levels */
    /* up and down buttons on level 0 inc and decrement the */
    /* thermostat temp setting */
    /* the back button on level 0 goes thru the screens */

    if(dbUpSwitch.update())
        if(dbUpSwitch.read() == false) /* Active low. */
        {
            BackLight(BACKLIGHT_FULL);
            (*Screens[CurScreenIdx].ScreenFunc)(level, UPBUTTONPIN);
        }
    if(dbDnSwitch.update())
        if(dbDnSwitch.read() == false) /* Active low. */
        {
            BackLight(BACKLIGHT_FULL);
            (*Screens[CurScreenIdx].ScreenFunc)(level, DNBUTTONPIN);
        }
    if(dbBackSwitch.update())
        if(dbBackSwitch.read() == false)
        {
            BackLight(BACKLIGHT_FULL);
            if(level == 0)
            {
                if(++CurScreenIdx == NUM_SCREENS)
                    CurScreenIdx = 0;
                SetupForNewScreen();
            }
            else
            {
                if(level > 0)
                    level--;
                if(level == 0)
                {
                    CurScreenIdx = 0;
                    SetupForNewScreen();
                }
                (*Screens[CurScreenIdx].ScreenFunc)(level, BACKBUTTONPIN);
            }
        }
    if(dbSaveSwitch.update())
        if(dbSaveSwitch.read() == false) /* Active low. */
        {   /* special level = 3 for SAVE when prev level is 2 */
            BackLight(BACKLIGHT_FULL);
            if(level < 3)
                level++;
            (*Screens[CurScreenIdx].ScreenFunc)(level, SAVEBUTTONPIN);
            if(level == 3)
                level = 2;
        }

    /* ReadTempFlag is true once every 200ms. Startflag is true when a temp */
    /* conversion can be done on the next sensor. You need to start a temp */
    /* conversion and wait about 750ms for the conversion to finish in the */
    /* sensor. startflag is true when the data is read from a sensor. */
    /* The next sensor is selected and command sent to start the conversion */
    if(ReadTempFlag || startflg)
    {
        GetEEsensor(sensor_cnt, &ssEE);
        if(sensor_cnt == COLLECTOR_LOC)
            dsptr = &ds1;
        else
            dsptr = &ds2;
        if(startflg)
        {
            StartTemp(dsptr, ssEE.addr);
            err_cnt = 0;
            startflg = false;
        }
        else
        {
            /* GetTemp returns 0 if sensor not ready yet */
            /* 1 if a failure or 2 if OK */
            temp = 0.0;
            ret = GetTemp(dsptr, ssEE.addr, &temp);
            if(ret == 2) /* OK */
            {
                byte readingcnt, totcnt=0;
                float tot = 0.0;

                for(readingcnt=0; readingcnt<NUM_TEMP_READINGS-1; readingcnt++)
                {
                    if(TSdata[sensor_cnt].temp[readingcnt] != 999)
                    {
                        tot += TSdata[sensor_cnt].temp[readingcnt];
                        totcnt++;
                    }
                    TSdata[sensor_cnt].temp[readingcnt] = 
                        TSdata[sensor_cnt].temp[readingcnt+1];
                }
                tot += temp;
                totcnt++;
                TSdata[sensor_cnt].temp[NUM_TEMP_READINGS-1] = temp;
                TSdata[sensor_cnt].avgtemp = tot/totcnt;

                startflg = true;
                if(++sensor_cnt >= NUM_DS18B20)
                {
                    sensor_cnt = 0;
                    tempsgood = true;
                }
            }
            /* sensor not done with temp A2D conversion yet(0) or failure (1) */
            if(ret == 0 || ret == 1)
                err_cnt++;
            /* If it takes too long for the temp conversion or too many failures */
            if(err_cnt >= 10) /* forget this sensor and move on */
            {
                if(++TSdata[sensor_cnt].failcnt == 255)
                    TSdata[sensor_cnt].failcnt = 1;
                if(TSdata[sensor_cnt].failcnt > GetEEact(SENSOR_ERR_TH_LOC) && GetEEact(SENSOR_ERR_TH_LOC) > 0)
                {
                    BuzzerState = true;
                    AddMsg("SensorFail", ssEE.location);
                }
                startflg = true;
                if(++sensor_cnt >= NUM_DS18B20)
                    sensor_cnt = 0;
            }
        }
    }

    /* When a temp is updated and the temp display screen is active */
    /* then update the display. */
    if(startflg)
    {
        (*Screens[0].ScreenFunc)((byte)NULL, (byte)NULL);
        if(MenuTimerCnt == 0)
            level = 0; /* Need this here in case the menu times out */
    }
 
    /* startflg is true after a temp reading. */
    if((tempsgood && startflg) || CurrStatus.Manual.state == 1)
    {
        CheckTooHot();
        if(!CollectorTooHotFlag && CurrStatus.Manual.state == 0)
            CalcHotWater();
        UpdateOutputs();
    }
    if(NTPRequestPending)
    {
        time_t ret;
        ret = ntp_get();
        if(ret > 0)
        {
            char t[MSG_LENGTH];
            UnixTime = ret;
            ltoa(ret, t, 10);
            AddMsg("Set Time", t);
            UnixTimeIsGood = true;
        }
    }
    ProcessServerRequest();
    OneSecTimer();
    if(BallTimerFlag && tempsgood)
        MoveBall();
}

/* Write the state of the outputs to the pins. If anything in the CurrStatus */
/* struct changes then make a history record and beep. */
void UpdateOutputs()
{
    byte offset, num_items;
    struct output *outptr;

    num_items = sizeof(struct stat)/sizeof(struct output);
    /* Skip over manual mode which is offset 0 */
    for(offset = 1; offset < num_items; offset++)
    {
        outptr = (struct output *)&CurrStatus + offset;
        digitalWrite(outptr->pin, outptr->state);
    }

    if(memcmp(&PrevStatus, &CurrStatus, sizeof(struct stat)) != 0)
    {
        SaveHistory();
        memcpy(&PrevStatus, &CurrStatus, sizeof(struct stat));
        BeepState = true;
    }
}

void UpdUnixTime()
{
  UnixTime++;
  SetTime(); /* fill the hwtime struct */
}

/* OneSecTimer() */
/* This is called every time in the loop() function */
/* Sets and unsets flags for various timer variables and flags */
void OneSecTimer()
{
    static unsigned long    readflg_millis = 0UL;
    static unsigned long    sec_millis = 0UL;
    static unsigned long    buzzer_millis = 0UL;
    static unsigned long    beep_millis = 0UL;
    static unsigned long    ball_millis = 0UL;
    unsigned long    cur_millis;
    static byte dutycycle = 0;
    int ret;

    cur_millis = millis();
    if(cur_millis - readflg_millis >= 200UL)
    {
        ReadTempFlag = true;
        readflg_millis = cur_millis;
    }
    else
        ReadTempFlag = false;
        
    if(cur_millis - ball_millis > 150UL)
    {
        BallTimerFlag = true;
        ball_millis = cur_millis;
    }
        
    /* every second */
    if(cur_millis - sec_millis >= 1000UL)
    {
        sec_millis = cur_millis;

        if(MenuTimerCnt > 0)
            MenuTimerCnt--;
        if(MenuTimerCnt == 1)
        {
            if(CurScreenIdx != 0)
            {
                CurScreenIdx = 0;
                SetupForNewScreen();
            }
        }
        /* Zone valve end switch should close in x minutes or failure */
        if(ZoneValveEndSwitchTimer > 0)
            ZoneValveEndSwitchTimer--;

        if(CollectorTooHotTimer > 0)
            CollectorTooHotTimer--;

        //UnixTime++;
        //SetTime(); /* fill the hwtime struct */
        
        /* Every 12 hours get the NTP time */
        if(UnixTime % 43200 == 0 && GetEEact(NTP_TIME_FLAG_LOC))
            sendNTPpacket(); /* request NIST time */
            
        /* Every 5 minutes make a history record */
        if(UnixTime % 300 == 0)
            SaveHistory();

        /* Every minute */
        if(UnixTime%60 == 0)
        {
            /* Turn zone off if not used for x minutes */
            if(ZoneTimerCnt > 0)
               ZoneTimerCnt--;

            if(BackLightTimer == 0)
                BackLight(BACKLIGHT_HALF);
            if(BackLightTimer > 0)
                BackLightTimer--;
            ret = Ethernet.maintain();
            
            if(ret == 1)
              AddMsg("Maintain", "1"); /* renew failed */
            if(ret == 3)
              AddMsg("Maintain", "3"); /* rebind failed */
        }
    }

    /* Now do the buzzer and beep */
    if(cur_millis - buzzer_millis >= 500)
    {
        if(dutycycle == 0 && BuzzerState)
            dutycycle = 125;
        else
            dutycycle = 0;
        buzzer_millis = cur_millis;
    }
    if(BeepState && !BuzzerState && dutycycle == 0 && GetEEact(BEEP_ENABLE_LOC) == 1)
    {
        dutycycle = 100;
        beep_millis = cur_millis;
    }
    if(cur_millis - beep_millis > 80ul && BeepState)
    {
        dutycycle = 0;
        BeepState = false;
    }
    analogWrite(BUZZER_PIN, dutycycle);
}

void SaveHistory()
{
    byte x;

    /* bump all recs to the front of the array */
    for(x=0; x<NUM_HISTORY_RECS-1; x++)
        memcpy(&History[x], &History[x+1], sizeof(struct hist_item));

    History[NUM_HISTORY_RECS-1].unixtime = UnixTime;
    memcpy(&History[NUM_HISTORY_RECS-1].TS, &TSdata, sizeof(TSdata));
    memcpy(&History[NUM_HISTORY_RECS-1].CS, &CurrStatus, sizeof(CurrStatus));
}
