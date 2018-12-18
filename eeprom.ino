/* eeprom.ino rbh 10/2009 */
/* modified from hotwater for thermo 10/2010 */

boolean CheckEEPROM()
{
    if(EEPROM.read(0) == 255)
    {
        GLCD.ClearScreen(); 
        GLCD.SelectFont(System5x7, BLACK);
        GLCD.CursorTo(2, 1); /* col, row */
        GLCD.print("EEPROM not");
        GLCD.CursorTo(2, 3); /* col, row */
        GLCD.print("initialized");
        delay(1000);
        return(false);
    }
    return(true);
}

byte GetEEact(byte offset)
{
    struct item i;

    GetEEitem(offset, &i);
    return(i.act);
}

void GetEEitem(byte offset, struct item *i)
{
    struct item *iptr;

    iptr = (struct item*)&Menu;
    iptr += offset;

    eeprom_read_block((void*)i, (const void *)iptr, sizeof(struct item));
}

void WriteEEitem(byte offset, struct item *i)
{
    struct item *iptr;

    iptr = (struct item*)&Menu;
    iptr += offset;

    eeprom_write_block((const void*)i, (void *)iptr, sizeof(struct item));
    delay(5);
}

void GetEEsensor(byte offset, struct sensorEE *s)
{
    struct sensorEE *sptr;

    sptr = (struct sensorEE*)&SensorsEE;
    sptr += offset;

    eeprom_read_block((void*)s, (const void *)sptr, sizeof(struct sensorEE));
}

void WriteEEsensor(byte offset, struct sensorEE *s)
{
    struct sensorEE *sptr;

    sptr = (struct sensorEE*)&SensorsEE;
    sptr += offset;

    eeprom_write_block((const void*)s, (void *)sptr, sizeof(struct sensorEE));
    delay(5);
}
