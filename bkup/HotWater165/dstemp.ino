/* dstemp.ino 10/2009 rbh */
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
byte ConversionStatus(OneWire *dsp)
{
    return(dsp->read_bit());
}

/* GetTemp retrieves the 2 bytes temp data from the sensor that was addressed */
/* in StartTemp(). Returns 0 if sensor not ready, 1 if failed or 2 if OK */
byte GetTemp(OneWire *dsp, byte *addr, float *retnTemp)
{
    byte    data[9], ret = 0;
    int     x, raw;
    float  temp;
    
    if(ConversionStatus(dsp) == 0)
        return(0);
    if(dsp->reset())  /* Continue if sensor is actually there and responding. */
    {
        dsp->select(addr);    
        dsp->write(0xBE);    /* Read Scratchpad command that has temp data. */

        /* Get 9 bytes of data 0-tempLSB;1-tempMSB;2-Th reg(not used here) */
        /* 3-Tl reg(not used);4-config reg;5,6,7-reserved;8-CRC */

        for(x=0; x<9; x++)
            data[x] = dsp->read();

        if(OneWire::crc8(data, 8) != data[8])
            ret = 1;
        else
        {
            raw=(data[1]<<8)+data[0];   /* Put the two bytes of the temp into an int*/
            temp = (float)raw * 0.0625; /* convert to celcius */
            *retnTemp = (temp*1.8)+32;  /* convert to fahrenheit */
            ret = 2;
        }
    }
    return(ret);
}
