/* temps.pde */
/* 10/2009 RBH */
/* test out reading a ds18B20 temp sensor */

#include "WProgram.h"
#include <OneWire.h>
//#include "HotWater.h"

#define DSTempSensors1Pin 7
#define DSTempSensors2Pin 8
#define NUM_SENSOR_ARRAYS 2
#define NUM_SENSORS 4

struct sensor {
    byte  addr[8];
    char location[10];
    float temp;
    float avgsum;
    byte  avgcnt;
    byte  failcnt;
    boolean present;
};

struct ow_sensor_array {
    OneWire *ow_ptr;
    struct sensor sensors[NUM_SENSORS];
};

struct ow_sensor_array owArray[2];

boolean ReadTempFlag = false;

OneWire    ds1(DSTempSensors2Pin);
OneWire    ds2(DSTempSensors1Pin);

void setup()
{
    Serial.begin(9600);

    //LCDInit();
    Serial.print("?f");    /* clear screen */
    Serial.print("?*");    /* display boot screen */
    Serial.print("?B30");    // B30 is 50% backlight on Bff is 100%
    delay(200);
    Serial.print("?c0");    // turn cursor off
    delay(5000);
    Serial.print("?f");
    
    memset(owArray, NULL, sizeof(owArray));

    owArray[0].ow_ptr = &ds1;
    owArray[1].ow_ptr = &ds2;
    SensorSearch();
    Serial.print("?f");
}

void loop()
{
    static boolean startflg = true;
    char strtemp[10];
    int ret, x;
    byte ow_cnt;
    int r;
    static byte sensor_cnt = 0;

    if(ReadTempFlag || startflg)
    {
        if(sensor_cnt == 0)
            ow_cnt = 0;
        else
            ow_cnt = 1;
        if(startflg)
        {
            if(owArray[ow_cnt].sensors[sensor_cnt].present)
                StartTemp(owArray[ow_cnt].ow_ptr, owArray[ow_cnt].sensors[sensor_cnt].addr);
            startflg = false;
        }
        else
        {
            if(owArray[ow_cnt].sensors[sensor_cnt].present)
            {
                Serial.print("?x00?y3?l");
                for(x=0, r=0; x<=20&& r==0; x++)
                {
                    r=ConversionStatus(owArray[ow_cnt].ow_ptr);
                    //Serial.print(x);
                    Serial.print((int)r);
                    delay(100);
                }
                ret=GetTemp(owArray[ow_cnt].ow_ptr, owArray[ow_cnt].sensors[sensor_cnt].addr, &(owArray[ow_cnt].sensors[sensor_cnt].temp));
            
                Serial.print("?x00?y0?l");Serial.print("OneWireArray# "); Serial.print((int)ow_cnt);
                Serial.print("?x00?y1?l"); Serial.print("Sensor# "); Serial.print((int)sensor_cnt);
                Serial.print("?x00?y2?l");Serial.print(owArray[ow_cnt].sensors[sensor_cnt].temp);
                //Serial.print("?x00?y3?l");Serial.print(" ret="); Serial.print(ret);Serial.print(" "); Serial.print(x);
            }
            startflg = true; 
            if(++sensor_cnt >= NUM_SENSORS)
                sensor_cnt = 0;
        }
    }
  /*  if(startflg)
    {
        byte o, s;
        Serial.print("?f");
        for(o = 0; o < NUM_SENSOR_ARRAYS; o++)
        {
            for(s=0; s<NUM_SENSORS ; s++)
            {
                if(!owArray[o].sensors[s].present)
                    continue;
                Serial.print("?x00?y0?l");Serial.print("OneWireArray# "); Serial.print((int)o);
                Serial.print("?x00?y1?l"); Serial.print("Sensor# "); Serial.print((int)s);
                Serial.print("?x00?y2?l");
                Serial.print(owArray[o].sensors[s].temp);
                delay(2000);
            }
        }
    }*/
    OneSecTimer();
}


void SensorSearch()
{
    byte byte_cnt;
    byte sensor_cnt=0, ow_cnt;

    for(ow_cnt=0; ow_cnt<NUM_SENSOR_ARRAYS; ow_cnt++)
    {
        sensor_cnt = 0;
        owArray[ow_cnt].ow_ptr->reset_search();
        while(owArray[ow_cnt].ow_ptr->search(owArray[ow_cnt].sensors[sensor_cnt].addr) && sensor_cnt < NUM_SENSORS)
        {
            owArray[ow_cnt].sensors[sensor_cnt].present = true;
            Serial.print("?x00?y0?l");Serial.print("OneWireArray# "); Serial.print((int)ow_cnt);
            Serial.print("?x00?y1?l"); Serial.print("Sensor# "); Serial.print((int)sensor_cnt);
            Serial.print("?x00?y2?l");
            for(byte_cnt = 0; byte_cnt < 8; byte_cnt++)
            {
                if(byte_cnt == 4)
                    Serial.print("?x00?y3?l");
                Serial.print(owArray[ow_cnt].sensors[sensor_cnt].addr[byte_cnt], HEX);
                Serial.print(" ");
            }
	    delay(1000);
            sensor_cnt++;
        }
    }
}

void OneSecTimer()
{
    static unsigned long    prev_millis = 0UL;

    if(millis() - prev_millis >= 500UL)
    {
        prev_millis = millis();
        ReadTempFlag = true;
    }
    else
        ReadTempFlag = false;
}
