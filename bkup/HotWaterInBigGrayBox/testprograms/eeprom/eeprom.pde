/* eeprom.pde */
/* 10/2009 Richard Hollabaugh */

#include <avr/eeprom.h>

char ee[20] EEMEM = "1234567890abcdefghi";

void setup()
{
    Serial.begin(9600);
    delay(100);
    Serial.print("?f");
    Serial.print("?*");   /*Display boot screen */
    
    //Serial.print("?B30");    // backlight on
    delay(100);
    Serial.print("?c0");    // turn cursor off
    delay(2000);            
    Serial.print("?f");    // clear the LCD
    Serial.print("?x00?y0");
    Serial.print("EEPROM Test");
}

void loop()
{
    byte eebyte;
    int x;

    for(x = 0; x < sizeof(ee); x++)
    {
        eebyte = eeprom_read_byte((unsigned char *)&ee + x);
        Serial.print("?x00?y1?l");
        Serial.print("x="); Serial.print(x);
        Serial.print("eebyte=");
        Serial.print((int)eebyte);
        delay(1000);
    }
}

/*
#include <avr/eeprom.h>

uint16_t EEMEM NonVolatileInt;
uint8_t  EEMEM NonVolatileString[10];

int main(void)
{
    uint8_t  SRAMchar;
    uint16_t SRAMint;
    uint8_t  SRAMstring[10];   

    SRAMchar = eeprom_read_byte(&NonVolatileChar);
    SRAMint  = eeprom_read_word(&NonVolatileInt);
    eeprom_read_block((void*)&SRAMstring, (const void*)&NonVolatileString, 10);
}
*/
