/* HotWaterSlave.pde */
/* 10/2009 Richard Hollabaugh */
/* Target cpu is Atmel Atmega168-20PU or 168V-10PU */
/* Fuses: Low - 0xe2; High - 0xdd; extended - 0x7 */
/* 8MHz */
/* Arduino22 1/20/2011 */

#include "WProgram.h"
#include <OneWire.h>
#include <Wire.h>
#include "HotWater.h"
#include "MemoryFree.h"

boolean buzzer_state = false;
boolean beep = false;

void setup()
{
    byte x;

    Serial.begin(9600);
    delay(3000);          /* Need 3 secs for lcd to be ready for first cmd */
    Serial.print(ClrScr);
    Serial.print("?*");   /*Display boot screen */

    Wire.begin(SLAVE_ADDRESS);    /* join i2c bus with address */
    Wire.onReceive(ReceiveEvent); /* register event */

    delay(2000);            /* 2 seconds is less than the 5 seconds in the */
                            /* master so the slave is ready to accept cmds */
    Serial.print(ClrScr);    // clear the LCD
    delay(100);
    for(x = 0; x < NUM_SLAVE_PINS; x++)
    {
        ss[x].state = LOW;
        pinMode(ss[x].pin, OUTPUT);
        digitalWrite(ss[x].pin, LOW);
        UpdateDisplay(ss[x].pin, x);
    }
}

void loop()
{
    static byte dutycycle = 0;
    static unsigned long prev_millis = 0ul;
    static unsigned long beep_millis = 0ul;
    
    if(millis() - prev_millis >= 500)
    {
        if(dutycycle == 0 && buzzer_state)
            dutycycle = 125;
        else
            dutycycle = 0;
        prev_millis = millis();
    }
    if(beep && !buzzer_state && dutycycle == 0)
    {
        dutycycle = 100;
        beep_millis = millis();
    }
    if(millis() - beep_millis > 60ul && beep)
    {
        dutycycle = 0;
        beep = false;
    }
    analogWrite(BUZZER_PIN, dutycycle);
}

/* function that executes whenever data is received from master */
/* format of packet from master: PIN_NUMBER:STATE */
void ReceiveEvent(int numbytes)
{
    byte pin, state, cnt, idx;
    char colon;
    
    cnt = Wire.available();  /* ret num bytes available */

    pin = Wire.receive();
    colon = Wire.receive();
    state = Wire.receive();
    
    if(pin == BUZZER_PIN)
        buzzer_state = state;
    else
        digitalWrite(pin, state);
        
     if(pin == PUMP_PIN)
         beep = true;
        
    idx = FindSlaveIdx(pin); 
    ss[idx].state = state;
    UpdateDisplay(pin, idx);
}

/* Find the slave pin in the ss array of slave pins. */
/* Return index into the array. */
/* If not found then set it. */

byte FindSlaveIdx(byte pin)
{
    byte x;

    for(x=0; x<NUM_SLAVE_PINS && ss[x].pin; x++)
        if(ss[x].pin == pin)
            return(x);
}

void UpdateDisplay(byte pin, byte idx)
{
    
    if(pin == BUZZER_PIN)
        return;

    switch(pin)
    {
        case PUMP_PIN:
            Serial.print(Line0);break;
        case PUMP_GARAGE_PIN:
            Serial.print("?x10?y0");break;
        case ZONE_WATER_TANK1_PIN:
            Serial.print(Line1);break;
        case ZONE_WATER_TANK2_PIN:
            Serial.print("?x10?y1");break;
        case ZONE_HOUSE_PIN:
            Serial.print(Line2);break;
        case ZONE_GARAGE_PIN:
            Serial.print("?x10?y2");break;
        case ZONE_STIEBEL_PIN:
            Serial.print(Line3);break;
        case TRANSFORMER_PIN:
            Serial.print("?x10?y3");break;
    }
    Serial.print(ss[idx].desc); Serial.print(colon);Serial.print((int)ss[idx].state);
}
