/* clock.pde */

/* 1) Sets the date and time on the ds1307 */
/* 2) Starts the clock */
/* 3) Sets hour mode to 24 hour clock */
void SetDateDs1307(byte second,        // 0-59
                   byte minute,        // 0-59
                   byte hour,          // 1-23
                   byte dayOfWeek,     // 1-7
                   byte dayOfMonth,    // 1-31
                   byte month,         // 1-12
                   byte year)          // 0-99
{
   Wire.beginTransmission(CLOCK_ADDRESS);
   Wire.send(0);
   Wire.send(DecToBcd(second));    /* 0 to bit 7 starts the clock */
   Wire.send(DecToBcd(minute));
   Wire.send(DecToBcd(hour));      /* If you want 12 hour am/pm you need to set */
                                   /* bit 6 (also need to change readDateDs1307) */
   Wire.send(DecToBcd(dayOfWeek));
   Wire.send(DecToBcd(dayOfMonth));
   Wire.send(DecToBcd(month));
   Wire.send(DecToBcd(year));
   Wire.endTransmission();
}

/* Gets the date and time from the ds1307 */
void GetDateDs1307(byte *second, byte *minute, byte *hour,
  byte *dayOfWeek, byte *dayOfMonth, byte *month, byte *year)
{
  Wire.beginTransmission(CLOCK_ADDRESS);
  Wire.send(0);    /* Reset the register pointer to the start of memory */
  Wire.endTransmission();
  Wire.requestFrom(CLOCK_ADDRESS, 7);

  /* A few of these need masks because certain bits are control bits */
  *second     = BcdToDec(Wire.receive() & 0x7f);
  *minute     = BcdToDec(Wire.receive());
  *hour       = BcdToDec(Wire.receive() & 0x3f);  /* Need to change this if 12 hour am/pm */
  *dayOfWeek  = BcdToDec(Wire.receive());
  *dayOfMonth = BcdToDec(Wire.receive());
  *month      = BcdToDec(Wire.receive());
  *year       = BcdToDec(Wire.receive());
}

/* Convert normal decimal numbers to binary coded decimal */
byte DecToBcd(byte val)
{
  return ( (val/10*16) + (val%10) );
}

/* Convert binary coded decimal to normal decimal numbers */
byte BcdToDec(byte val)
{
  return ( (val/16*10) + (val%16) );
}
