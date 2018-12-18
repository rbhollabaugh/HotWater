/* HotWater.pde */
/* 10/2009 RBH */
/* Arduino 17 IDE */
/* Updated code for Arduino 21  - added SPI.h include 10/15/2010 */
/* Arduino 22 1/20/2011 */
/* Uses downloaded libraries 'Bounce', 'MemoryFree', 'OneWire' */
/* CPU is Atmega328 */
/* 32k program flash - 2k SRAM - 1k EEPROM */
/* 8MHz internal clock - LowFuse=E2 HighFuse=DF ExtendedFuse=05 */

/* Must include Wprogram.h first to get Arduino datatypes */
#include "WProgram.h"
#include <SPI.h> /* Needed for Ethernet lib */
#include <OneWire.h>
#include <Wire.h>
#include <EEPROM.h>
#include <Bounce.h>
#include "HotWater.h"
#include "MemoryFree.h"
#include <Ethernet.h>
#include <avr/eeprom.h>

/* Menu is the data struct that holds the configurable parameters. */
/* Loaded into EEPROM for permanent storage. These numbers are all BYTES (max 255 and min 0). */
/* desc,min,max,dft,act*/
struct menu EEMEM Menu = 
{
    {"Wtr1Hs2Gg3 ", 1, 3, 1, 1},     /* Heat Water (1), House (2), Garage (3) */
    {"Auto1/Man0 ", 0, 1, 1, 1},     /* Auto mode or manual mode */
    {"Freeze     ", 0, 50,37, 37},   /* Degrees below freezing before turning pump on */
    {"UseTank1   ", 0, 1, 1, 1},     /* use 1 or don't use 0 this tank */
    {"UseTank2   ", 0, 1, 1, 1},     /* use 1 or don't use 0 this tank */
    {"MaxTankTemp", 120, 180, 170, 165}, /* max tank temp - applies to both tanks */
    {"TempDiffMax", 10, 24, 18, 18}, /* turn on temp diff between collector and tank */
    {"TempDiffMin", 3, 10, 5, 5},    /* min temp differential between collector and tank */
    {"HeatEnable ", 0, 2, 2, 2},     /* 1-house heat on. 0-house heat off. 2-auto - input from house thermostat */
    {"DumpTimeHr ", 0, 23, 16, 16},  /* hour time when to dump collector hot fluid to dump device - house or garage */
    {"DumpTimeMin", 0, 59, 15, 15},  /* minute for dump time */
    {"ZoneOffTime", 0, 30, 20, 20},  /* time in minutes to keep a zone valve open after the pump turns off */
    {"SensorErrTh", 0, 254, 20, 20}, /* sensor error cnt threshold before sounding the buzzer - 0 is off */
    {"EndSwtchSec", 10, 60, 35, 35}, /* number of seconds to wait for the zone valve end switch to close before setting error code */
    {"IPport     ", 1, 255, 6, 6},   /* port to listen on for connections. Ports can go way above 255 but not here (byte 2^8) */
    {"IPAddress1 ", 0, 255, 192, 192},
    {"IPAddress2 ", 0, 255, 168, 168},
    {"IPAddress3 ", 0, 255, 5, 5},
    {"IPAddress4 ", 0, 255, 30, 30},
    {"MACAddress1", 0, 255, 222, 222},
    {"MACAddress2", 0, 255, 222, 222},
    {"MACAddress3", 0, 255, 222, 222},
    {"MACAddress4", 0, 255, 222, 222},
    {"MACAddress5", 0, 255, 222, 222},
    {"MACAddress6", 0, 255, 222, 222},
    {"DftGateway1", 0, 255, 192, 192},
    {"DftGateway2", 0, 255, 168, 168},
    {"DftGateway3", 0, 255, 5, 5},
    {"DftGateway4", 0, 255, 1, 1},
    {"SubnetMask1", 0, 255, 255, 255},
    {"SubnetMask2", 0, 255, 255, 255},
    {"SubnetMask3", 0, 255, 255, 255},
    {"SubnetMask4", 0, 255, 0, 0}
};

struct screens Screens[NUM_SCREENS] = {
    {"TempDisp", TempDisplay},
    {"Config Param", ConfigParam},
    {"SensorConfig1", SensorConfig1},
    {"SensorConfig2", SensorConfig2},
    {"Manual", Manual},
    {"FreeRAMBytes", FreeRAM}
};

/* Temp sensor data structures */
/* SensorsEE is the sensor data that does not change. It's loaded into */
/* EEPROM using avrdude after Arduino uploads the program into flash memory. */
struct sensorsEE EEMEM SensorsEE =
{
    {0x28,0xD8,0xBD,0xBA,0x02,0x00,0x00,0x1D, "Collector"},
    {0x28,0x8D,0x67,0x9E,0x01,0x00,0x00,0xA1, "T1Top    "},
    {0x28,0x7E,0x55,0x9E,0x01,0x00,0x00,0x8D, "T1Bot    "},
    {0x28,0x56,0x4C,0x9E,0x01,0x00,0x00,0x15, "T2Top    "},
    {0x28,0x7E,0x58,0x9E,0x01,0x00,0x00,0x61, "T2Bot    "}
};
/* old sensor that is still out there */
//{0x28,0xE8,0x4C,0x9E,0x01,0x00,0x00,0x01, "Collector"},
/* Temp Sensor temp readings */
struct TempSensor TSdata[NUM_DS18B20];

/* Two One wire networks are set up in hardware. Was */
/* having trouble communicating with all sensors due to the */
/* collector sensor being so far away from the tank sensors. */
OneWire    ds1(DSTempSensors1Pin); /* the 4 tank sensors */
OneWire    ds2(DSTempSensors2Pin); /* the collector sensor */
boolean    ReadTempFlag = false;

boolean    ZoneValveEndSwitch = false;
byte       ZoneValveEndSwitchTimer = 0;
boolean    ZoneValveEndSwitchErrFlg = false;
int        ZoneTimerCnt = 0;
boolean    CollectorTooHotFlag = false;
byte       CollectorTooHotTimer = 0;
boolean    HeatEnabled = false;
char       *ErrorString = "";
byte       BackLightTimer = 0;
unsigned long LastServerReq = 0UL;
unsigned long LastWiznetReset = 0UL;

/* Vars for display */
/* Set in CalcHotWater */
char       *DispActiveZone = Space6; /* max 6 spaces */
char       *DispEnabledZone= Space6; /* max 6 spaces */
boolean    DumpFlag = false;

/* Had to declare these globally here. They were declared */
/* as static in CalcHotWater() but got compile error. */
byte MaxTankTemp1 = GetEEact(MAX_TANK_TEMP_LOC);
byte MaxTankTemp2 = GetEEact(MAX_TANK_TEMP_LOC);
byte TempDiff = GetEEact(TEMP_DIFF_MAX_LOC);

/* Dump Temp used in temp display func and Calc() */
int DumpTemp = GetEEact(MAX_TANK_TEMP_LOC) + GetEEact(TEMP_DIFF_MAX_LOC);

/* TurnOnTemp used in temp display func  and Calc() */
float  TurnOnTemp;
byte   CurScreenIdx = 0, MenuTimerCnt = 0;
byte   sec, min, hr, day, dow, month, yr;

Bounce dbBackSwitch = Bounce(BACKBUTTONPIN, 40);
Bounce dbUpSwitch = Bounce(UPBUTTONPIN, 40);
Bounce dbDnSwitch = Bounce(DNBUTTONPIN, 40);
Bounce dbSaveSwitch = Bounce(SAVEBUTTONPIN, 40);
Bounce dbHeatEnabled = Bounce(HeatEnabledPin, 30);
Bounce dbZoneValveEndSwitch = Bounce(ZoneValveEndSwitchPin, 30);

/* if 24 hrs go by w/o data request then 0 out the elapsed time */
/* counters in the ss array. */
unsigned long LastDataReqMillis;
Server server(GetEEact(IP_PORT_LOC));

void setup()
{
    /* /Reset Wiznet ethernet module. Otherwise, sometimes it does */
    /* not work after a power up. */
    pinMode(WizNetResetPin, OUTPUT);

    StartWiznet();
    
    Serial.begin(9600);
    delay(3000);          /* Need 3 secs for display to be ready */
    Serial.print(ClrScr);
    Serial.print("?*");   /*Display boot screen */
    
    pinMode(BACKBUTTONPIN, INPUT);
    digitalWrite(BACKBUTTONPIN, HIGH);
    pinMode(UPBUTTONPIN, INPUT);
    digitalWrite(UPBUTTONPIN, HIGH);
    pinMode(DNBUTTONPIN, INPUT);
    digitalWrite(DNBUTTONPIN, HIGH);
    pinMode(SAVEBUTTONPIN, INPUT);
    digitalWrite(SAVEBUTTONPIN, HIGH);
    pinMode(HeatEnabledPin, INPUT);
    digitalWrite(HeatEnabledPin, HIGH);
    pinMode(ZoneValveEndSwitchPin, INPUT);
    digitalWrite(ZoneValveEndSwitchPin, HIGH);
    
    Wire.begin(MASTER_ADDRESS);  /* Join I2C bus. This is the master. */
    BackLight(HIGH);
    delay(3000);
    Serial.print(ClrScr);
    
    memset(TSdata, 0, sizeof(TSdata));
    InitSlavePins();
    ZeroElapsedMillis();
    ZeroAvgTemps();
}

void loop()
{
    static byte    sensor_cnt = 0, level = 0, err_cnt;
    static boolean startflg = true;
    static boolean tempsgood = false;
    struct sensorEE ssEE;
    float temp;
    OneWire *owptr;
    byte ret;
    
    if(!CheckEEPROM())
        return;

    dbZoneValveEndSwitch.update();
    ZoneValveEndSwitch = !dbZoneValveEndSwitch.read();  /* active low */
    
    if(GetEEact(HEAT_ENABLED_LOC) == 2)
    {
        dbHeatEnabled.update();
        HeatEnabled = !dbHeatEnabled.read();  /* active low */
    }
    else
    {
        if(GetEEact(HEAT_ENABLED_LOC) == 0)
            HeatEnabled = true;
        else
            HeatEnabled = false;
    }
    /* level 0 = new screen w/just heading */
    /* level 1 = heading + parameter name  */
    /* level 2 = heading + parameter + parameter options */
    /* level 3 = all of above plus save button pressed after level 2 */
    /* save button advances to new levels except level 3 = save */
    /* back button goes back levels */

    if(dbUpSwitch.update())
        if(dbUpSwitch.read() == false) /* Active low. */
        {
            BackLight(HIGH);
            if(level == 0)
            {
                if(++CurScreenIdx == NUM_SCREENS)
                    CurScreenIdx = 1;
                SetupForNewScreen();
            }
            else
                (*Screens[CurScreenIdx].ScreenFunc)(level, UPBUTTONPIN);
        }
    if(dbDnSwitch.update())
        if(dbDnSwitch.read() == false) /* Active low. */
        {
            BackLight(HIGH);
            if(level == 0)
            {
                if(CurScreenIdx > 1)
                    CurScreenIdx--;
                else
                    CurScreenIdx = NUM_SCREENS-1;
                SetupForNewScreen();
            }
            else
                (*Screens[CurScreenIdx].ScreenFunc)(level, DNBUTTONPIN);
        }
    if(dbBackSwitch.update())
        if(dbBackSwitch.read() == false)
        {
            BackLight(HIGH);
            if(level > 0)
                level--;
            if(level == 0)
            {
                CurScreenIdx = 0;
                SetupForNewScreen();
            }
            (*Screens[CurScreenIdx].ScreenFunc)(level, BACKBUTTONPIN);
        }
    if(dbSaveSwitch.update())
        if(dbSaveSwitch.read() == false) /* Active low. */
        {   /* special level = 3 for SAVE when prev level is 2 */
            BackLight(HIGH);
            if(level < 3)
                level++;
            (*Screens[CurScreenIdx].ScreenFunc)(level, SAVEBUTTONPIN);
            if(level == 3)
                level = 2;
        }

    /* ReadTempFlag is true once every 200ms. Startflag is true when a temp conversion can */
    /* be done on the next sensor. You need to start a temp conversion and wait about 750ms */
    /* for the conversion to finish in the sensor. */
    /* startflag is true when the data is read from a sensor. */
    /* The next sensor is selected and command sent to start the conversion (A2D) */
    if(ReadTempFlag || startflg)
    {
        GetEEsensor(sensor_cnt, &ssEE);
        if(sensor_cnt == 0) /* collector sensor */
            owptr = &ds2;
        else
            owptr = &ds1;   /* 4 tank sensors */
        if(startflg)
        {
            StartTemp(owptr, ssEE.addr);
            err_cnt = 0;
            startflg = false;
        }
        else
        {
            /* GetTemp returns 0 if sensor not ready yet */
            /* 1 if a failure or 2 if OK */
            temp = 0.0;
            ret = GetTemp(owptr, ssEE.addr, &temp);
            if(ret == 2) /* OK */
            {
                TSdata[sensor_cnt].temp = temp;
                TSdata[sensor_cnt].avgsum += TSdata[sensor_cnt].temp;
                TSdata[sensor_cnt].avgcnt++;
                if(TSdata[sensor_cnt].avgcnt == 255)
                    ZeroAvgTemps();
                startflg = true;
                if(++sensor_cnt >= NUM_DS18B20)
                {
                    sensor_cnt = 0;
                    tempsgood = true;
                }
            }
            if(ret == 0 || ret == 1) /* sensor not done with temp A2D conversion yet(0) or failure (1) */
                err_cnt++;
            /* If it takes too long for the temp conversion or too many failures */
            if(err_cnt >= 10) /* forget this sensor and move on */
            {
                /* If Sensor error threshold is > 0 then check the error cnt. 0 means don't check */
                if(++TSdata[sensor_cnt].failcnt > GetEEact(SENSOR_ERR_TH_LOC) && GetEEact(SENSOR_ERR_TH_LOC) > 0)
                    ErrorString = "Sensor";
                if(TSdata[sensor_cnt].failcnt == 255)
                    TSdata[sensor_cnt].failcnt = 1;
                startflg = true;
                if(++sensor_cnt >= NUM_DS18B20)
                    sensor_cnt = 0;
            }
        }
    }

    /* When a temp is updated and the temp display screen is active */
    /* then update the display. */
    if(CurScreenIdx == 0)
    {
        if(startflg)
            (*Screens[CurScreenIdx].ScreenFunc)(NULL, NULL);
        level = 0; /* Need this here in case the menu times out */
    }
    if(tempsgood && startflg) /* startflg is true after a temp reading. */
    {
        CheckTooHot();
        if(!CollectorTooHotFlag && GetEEact(AUTO_MAN_LOC) == 1) /*auto*/
            CalcHotWater();
    }
    /* No need to call this all the time in loop() */
    /* So only chk when ReadTempFlag is true. */
    if(ReadTempFlag)
        ChkError();
    ProcessServerRequest();
    OneSecTimer();
}

/* There are two error conditions to check for. */
/* Beep the beeper and display error on bottom line */
/* of LCD display. */
void ChkError()
{
    if(*ErrorString)
    {
        SendToSlave(BUZZER_PIN, HIGH);
        BackLight(HIGH);
    }
    else
        if(GetEEact(AUTO_MAN_LOC) == 1) /*auto*/
            SendToSlave(BUZZER_PIN, LOW);
}

void FreeRAM(byte level, byte pin)
{
    MenuTimerCnt = MENU_ON_SECONDS;
    Serial.print(Line2);
    Serial.print(freeMemory());
}     
            
/* Manual() */
void Manual(byte level, byte pin)
{
    static byte ssidx = 0;
    static boolean displaystate;

    MenuTimerCnt = MENU_ON_SECONDS;
    
    if(level == 1)
    {
        if(pin == UPBUTTONPIN)
            if(++ssidx == NUM_SLAVE_PINS)
                ssidx = 0;
        if(pin == DNBUTTONPIN)
            if(ssidx > 0)
                ssidx--;
            else
                ssidx = NUM_SLAVE_PINS-1;
        Serial.print(Line2Clr);
        Serial.print(Line3Clr);
    }
    if(level == 2)
    {
        if(pin == SAVEBUTTONPIN)
            displaystate = ss[ssidx].state;
        if(pin == UPBUTTONPIN || pin == DNBUTTONPIN)
            displaystate = !displaystate;
        Serial.print("?x11?y2");Serial.print((int)displaystate);
    }    
    if(level == 3 && pin == SAVEBUTTONPIN)
    {
        Serial.print(Line3Clr);
        if(GetEEact(AUTO_MAN_LOC) == 0)
        {
            SendToSlave(ss[ssidx].pin, displaystate);
            Serial.print(Saved);
        }
        else
            Serial.print("Man Mode not Active");
    }
    Serial.print(Line1Clr);
    Serial.print(Line2);Serial.print(ss[ssidx].desc);
}

void SensorConfig1(byte level, byte pin)
{
    SensorConfig(&ds1, level, pin);
}

void SensorConfig2(byte level, byte pin)
{
    SensorConfig(&ds2, level, pin);
}
/***** SensorConfig *****/
void SensorConfig(OneWire *dsp, byte level, byte pin)
{
    struct sensorEE ssEE;
    static byte addr[8];
    static byte sensor_num;
    byte byte_cnt;
    boolean found;
    
    MenuTimerCnt = MENU_ON_SECONDS;

    if(level == 1) // && (pin == UPBUTTONPIN || pin == DNBUTTONPIN))
    {
        if(!dsp->search(addr))
        {
            dsp->reset_search();
            dsp->search(addr);
        }
        for(sensor_num=0; sensor_num<NUM_DS18B20; sensor_num++)
        {
            found=true;
            GetEEsensor(sensor_num, &ssEE);
            for(byte_cnt=0; byte_cnt < NUM_DS18B20_ADDRESS_BYTES; byte_cnt++)
            {
                if(ssEE.addr[byte_cnt] != addr[byte_cnt])
                    found = false;
            }
            if(found == true)
                break;
        }
        Serial.print(Line1Clr); // line 1 on LCD
        for(byte_cnt = 0; byte_cnt < NUM_DS18B20_ADDRESS_BYTES; byte_cnt++)
        {
            if(byte_cnt == 4)
                Serial.print(Line2Clr);
            Serial.print(addr[byte_cnt], HEX);
            Serial.print(" ");
        }
        Serial.print("?x12?y1");
        if(found)
        {
            Serial.print("  Used"); Serial.print(colon);
            Serial.print("?x11?y2");
            Serial.print(ssEE.location);
        }
        else
        {
            Serial.print("Not Used");
            Serial.print("?x11?y2");
            Serial.print("       ");
        }
        Serial.print(Line3Clr);
    }
    if(level == 2)
    {
        /* if we are using sensor array 1 then that's the tank sensors */
        /* only. Limit the choice of sensor options to just the */
        /* ctank sensors. if sensor array 2 then that's the collector only. */
        if(dsp == &ds1)
        {
            if(pin == SAVEBUTTONPIN) /* first time in level 2 */
                sensor_num = 1;
            if(pin == UPBUTTONPIN)
                if(++sensor_num == NUM_DS18B20)
                    sensor_num = 1;
            if(pin == DNBUTTONPIN)
                if(sensor_num > 1)
                    sensor_num--;
                else
                    sensor_num = NUM_DS18B20-1;
        }
        else
            sensor_num = 0;
        Serial.print(Line3Clr);
        Serial.print("New Loc: ");
        GetEEsensor(sensor_num, &ssEE);
        Serial.print(ssEE.location);
    }
    if(level == 3 && pin == SAVEBUTTONPIN)
    {
        GetEEsensor(sensor_num, &ssEE);
        for(byte_cnt=0; byte_cnt < NUM_DS18B20_ADDRESS_BYTES; byte_cnt++)
            ssEE.addr[byte_cnt] = addr[byte_cnt];
        WriteEEsensor(sensor_num, &ssEE);
        Serial.print(Line3Clr);
        Serial.print(Saved);
    }
}

/***** ConfigParam() *****/
void ConfigParam(byte level, byte pin)
{
    static byte   offset = 0;
    static byte   displayact;
    struct item   i;
    
    MenuTimerCnt = MENU_ON_SECONDS;

    if(level == 1)
    {
        if(pin == UPBUTTONPIN)
            if(++offset > (sizeof(struct menu)/sizeof(struct item))-1)
                offset = 0;
        if(pin == DNBUTTONPIN)
            if(offset == 0)
                offset = (sizeof(struct menu)/sizeof(struct item))-1;
            else
                offset--;
        Serial.print(Line3Clr);
    }
    GetEEitem(offset, &i);
    Serial.print(Line1Clr); Serial.print(i.desc);
    Serial.print(Line2Clr); Serial.print("Min Max Dft Act");
    Serial.print(Line3Clr);
    if(level == 2)
    {
        if(pin == SAVEBUTTONPIN)
            displayact = i.act;
        if(pin == UPBUTTONPIN)
            if(displayact < i.max)
                displayact++;
        if(pin == DNBUTTONPIN)
            if(displayact > i.min)
                displayact--;
        Serial.print((int)i.min);Serial.print("?x04?y3"); /* min */
        Serial.print((int)i.max);Serial.print("?x08?y3"); /* max */
        Serial.print((int)i.dft);Serial.print("?x12?y3"); /* dft */
        Serial.print((int)displayact);                    /* act */
    }    
    if(level == 3 && pin == SAVEBUTTONPIN)
    {
        i.act = displayact;
        WriteEEitem(offset, &i);
        Serial.print(Saved);
    }
}

/* OneSecTimer() */
/* This is called every time in the loop() function */
/* Sets and unsets flags for various timer variables and flags */
void OneSecTimer()
{
    static unsigned long    readflg_millis = 0UL;
    static unsigned long    sec_millis = 0UL;
    static unsigned long    minute_millis = 0UL;

    if(millis() - readflg_millis >= 200)
    {
        ReadTempFlag = true;
        GetDateDs1307(&sec, &min, &hr, &dow, &day, &month, &yr);
        readflg_millis = millis();
    }
    else
        ReadTempFlag = false;
        
    if(millis() - sec_millis >= 1000UL)
    {
        sec_millis = millis();
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

        if(millis() - LastDataReqMillis > 86400000UL)
            ZeroElapsedMillis();
        if(CollectorTooHotTimer > 0)
            CollectorTooHotTimer--;
    }

    /* Every minute */
    if(millis() - minute_millis >= 60000UL)
    {
        minute_millis = millis();
         /* Turn zone off if not used for x minutes */
        if(ZoneTimerCnt > 0)
            ZoneTimerCnt--;
        if(BackLightTimer == 1)
            BackLight(LOW);
        if(BackLightTimer > 0)
            BackLightTimer--;
        /* 6 minutes */
        if(LastServerReq > 0UL && millis() - LastServerReq >= 360000UL &&
                    millis() - LastWiznetReset >= 360000UL)
                StartWiznet();
        /* Reset the wiznet module - there is a problem where it needs */
        /* to be reset from time to time or it freezes and does not */
        /* accept any new connections. The forum on arduino.cc had discussed */
        /* that it may not be properly releasing connections so when it */
        /* gets to it's max of 4 connections the 5th one fails. */
        //if(min == 1 || min == 16 || min == 31 || min == 46)
         //   StartWiznet();
    }
}

/* Clear the LCD display; backlight on full; Print screen name on line 0 */
void SetupForNewScreen()
{
    MenuTimerCnt = MENU_ON_SECONDS;
    Serial.print(ClrScr);    /* clear the display */
    Serial.print(Line0); /* line 0 on LCD */
    Serial.print(Screens[CurScreenIdx].ScreenName); /* Screen name on 1st line*/
}

/* TempDisplay - Called from loop() */
void TempDisplay(byte level, byte pin)
{
    char strtemp[8];

    Serial.print(Line0);
    Serial.print(ftoa(TSdata[COLLECTOR_LOC].temp, strtemp, 5));
    Serial.print(ftoa(TSdata[T1TOP_LOC].temp, strtemp, 6));
    Serial.print(ftoa(TSdata[T2TOP_LOC].temp, strtemp, 6));
    if(ZoneValveEndSwitch)
        Serial.print(" ZV");
    else
        Serial.print("   ");
    
    Serial.print(Line1);
    Serial.print(ftoa(TurnOnTemp, strtemp, 5));
    Serial.print(ftoa((TSdata[T1TOP_LOC].temp + TSdata[T1BOT_LOC].temp)/2, strtemp, 6));
    Serial.print(ftoa((TSdata[T2TOP_LOC].temp + TSdata[T2BOT_LOC].temp)/2, strtemp, 6));
    if(DumpFlag)
        Serial.print(" DF");
    else
        Serial.print("   ");

    Serial.print(Line2);
    Serial.print(ftoa(DumpTemp, strtemp, 5));
    Serial.print(ftoa(TSdata[T1BOT_LOC].temp, strtemp, 6));
    Serial.print(ftoa(TSdata[T2BOT_LOC].temp, strtemp, 6));
    if(HeatEnabled)
        Serial.print(" HE");
    else
        Serial.print("   ");
    
    Serial.print(Line3);
    Serial.print(DispActiveZone);     /* Active Zone - 5 chars + 1 space = 6*/
    if(GetEEact(AUTO_MAN_LOC) == 0) /* manual */
            DispEnabledZone = "Manual";
    Serial.print(DispEnabledZone);    /* Enabled Zone - 5 chars + 1 space = 6 */
    if(*ErrorString)
        Serial.print(ErrorString);
    else
    {
        if(hr <= 9)
            Serial.print(Zero);
        Serial.print((int)hr);Serial.print(colon);
        if(min <= 9)
            Serial.print(Zero);
        Serial.print((int)min);Serial.print(colon);
        if(sec <= 9)
            Serial.print(Zero);
        Serial.print((int)sec);
    }
}

void BackLight(boolean state)
{
   /* if(state == HIGH)
    {
        if(BackLightTimer == 0)
        {
            Serial.print(BkLtHalf);
            delay(100);
        }
        BackLightTimer = BACK_LIGHT_TIMER_MIN;
    }
    else
    {
        BackLightTimer = 0;
        Serial.print(BkLtOff);
        delay(100);
    }*/
}

void pr_int(int i)
{
    Serial.print(Line3);
    Serial.print(i);
    //delay(500);
}

