/* menu.pde */
/* 10/2009 Richard Hollabaugh */

#include <avr/eeprom.h>

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

/* desc,min,max,dft,act*/
struct menu EEMEM Menu = 
{
    {"UseTank1   ", 0, 1, 1, 1},
    {"UseTank2   ", 0, 1, 1, 1},
    {"MaxTankTemp", 160, 180, 170, 175},
    {"TempDiffMax", 15, 20, 18, 18},
    {"TempDiffMin", 3, 8, 5, 5},
    {"Auto1/Man0 ", 0, 1, 1, 1},
    {"HeatEnable ", 0, 2, 2, 2},
    {"IPAddress1 ", 0, 255, 192, 192},
    {"IPAddress2 ", 0, 255, 168, 168},
    {"IPAddress3 ", 0, 255, 5, 5},
    {"IPAddress4 ", 0, 255, 30, 30},
    {"MACAddress1", 0, 255, 222, 222},
    {"MACAddress2", 0, 255, 222, 222},
    {"MACAddress3", 0, 255, 222, 222},
    {"MACAddress4", 0, 255, 222, 222},
    {"MACAddress5", 0, 255, 222, 222},
    {"MACAddress6", 0, 255, 222, 222}
};

void setup()
{
    Serial.begin(9600);
    delay(100);
    Serial.print("?f");
    Serial.print("?*");   /*Display boot screen */
    
    Serial.print("?B30");    // backlight on
    delay(100);
    Serial.print("?c0");    // turn cursor off
    delay(2000);            
    Serial.print("?f");    // clear the LCD
    Serial.print("?x00?y0");
    Serial.print("EEPROM Test");
    delay(100);
}

void loop()
{
    byte act;
    struct item i, *iptr;
    static byte x = 0;

    iptr = (struct item *)&Menu;

    //eeprom_read_block((void*)&i, (const void *)iptr, sizeof(struct item));

    act = GetEEAct(x);
    Serial.print("?x00?y1?l");
    Serial.print("Offset=");Serial.print((int)x);Serial.print(" ");
    Serial.print((int)act);
    x++;
    if(x > 15)
        x = 0;

    delay(3000);
}

byte GetEEAct(byte offset)
{
    struct item i;

    GetEEItem(offset, &i);
    return(i.act);
}

void GetEEItem(byte offset, struct item *i)
{
    struct item *iptr;

    iptr = (struct item*)&Menu;
    iptr += offset;

    eeprom_read_block((void*)i, (const void *)iptr, sizeof(struct item));
}
/***********************************************/

    /*if(i.act < 254)
    {
        i.act++;
        eeprom_write_block ((void*)&i, (void *)iptr, sizeof(struct item));
    }*/

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
