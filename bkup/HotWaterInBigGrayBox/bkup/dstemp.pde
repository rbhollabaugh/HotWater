/* Dallas/Maxim One Wire Temp sensors */
/* Adapted from http://www.arduino.cc/playground/Main/GetOneWireTemp */

#include <OneWire.h>

/* Tell the DS18B20 temp sensor to start the AtoD temp conversion. */
/* according to the man page a 12 bit AtoD conversion takes 750ms. */
/* Call StartTemp then wait at least 750ms before calling GetTemp(). */

void StartTemp(OneWire *dsp, byte *addr)
{
    dsp->reset();
    dsp->select(addr);
    dsp->write(0x44, 0);  /* start temp A2D conversion, 0 = separate 5V supply to the sensor - not parasitic */
}

/* This initiates a 'read time slot' and returns the status of the last command (0x44) */
/* Must call this after a 0x44 but before the attempt to read the temperature data. */
/* This way the device can be polled to see if the last command is done. */
/* returns 0 for not ready and 1 for ready */
int ConversionStatus(OneWire *dsp)
{
    return(dsp->read_bit());
}

/* GetTemp retrieves the 2 bytes temp data from the sensor that was addressed */
/* in StartTemp(). */
boolean GetTemp(OneWire *dsp, byte *addr, float *retnTemp)
{
    byte    data[9];
    int     x, raw;
    float  temp;

    if(dsp->reset())  /* Continue if sensor is actually there and responding. */
    {
        dsp->select(addr);    
        dsp->write(0xBE);    /* Read Scratchpad command that has temp data. */

        /* Get 9 bytes of data 0-tempLSB;1-tempMSB;2-Th reg(not used here) */
        /* 3-Tl reg(not used);4-config reg;5,6,7-reserved;8-CRC */

        for(x=0; x<9; x++)
            data[x] = dsp->read();

        if(OneWire::crc8(data, 8) != data[8])
            return false;
        raw=(data[1]<<8)+data[0]; /* Put the two bytes of the temp into an int*/
        temp = (float)raw * 0.0625; /* convert to celcius */
        *retnTemp = (temp*1.8)+32;       /* convert to fahrenheit */
        return true;
    }
    *retnTemp = 0.0;
    return false;
}

/* Convert the float temp to a string. */
/* Right justify the string by padding blanks on the left. */

char *ftoa(float val, char *str, byte len)
{
    int whole, frac;
    char fracstr[2], tmp[10];
    byte x = 0, i;
    
    memset(tmp, NULL, 10);
    if(val < 0.0)
    {
        tmp[x++] = '-';
        val *= -1;
    }
    whole = (int)val;
    frac = (val-(float)whole) * 10.0;

    itoa(whole, tmp+x, 10);
    itoa(frac, fracstr, 10);
    for(x=0; tmp[x] && x<10; x++);
    
    tmp[x++] = '.';
    tmp[x++] = fracstr[0];
    tmp[x] = '\0';
    
    for(i=0; i < len-x; i++)
        str[i] = ' ';
    for(x=0; tmp[x] && x<10; x++)
        str[i++] = tmp[x];
    if(i > 9)
        i = 9;
    str[i] = '\0';
    
    return(str);
}
