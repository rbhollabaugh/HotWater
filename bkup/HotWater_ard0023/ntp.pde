/* ntp.pde rbh 2/2011 */
/* See http://tf.nist.gov/tf-cgi/servers.cgi for more info */

/* There is something in this function that is blocking when no */
/* wiznet ethernet module is installed. So best to turn NTP off in */
/* the EEPROM options. */
time_t ntp_get()
{
    if(Udp.available())
    {
        byte packetBuffer[NTP_PACKET_SIZE];

        /* read the packet into the buffer */
        Udp.readPacket(packetBuffer, NTP_PACKET_SIZE);

        /* The timestamp starts at byte 40 of the received packet and is */
        /* four bytes or two words long. First, extract the two words: */

        unsigned long highWord = word(packetBuffer[40], packetBuffer[41]);
        unsigned long lowWord = word(packetBuffer[42], packetBuffer[43]);  

        /* combine the four bytes (two words) into a long integer */
        /* this is NTP time (seconds since Jan 1 1900): */
        time_t secsSince1900 = highWord << 16 | lowWord;            

        /* Unix time starts on Jan 1 1970. In seconds, that's 2208988800 */
        /* seventyYears = 2208988800UL */
        NTPRequestPending = false;
        return(secsSince1900 - 2208988800UL);
    }
    return(0UL);
}

// send an NTP request to the time server at the given address 
void sendNTPpacket()
{
    byte packetBuffer[NTP_PACKET_SIZE];
    byte ntpip[NUM_IP_ADDRESS_BYTES];
    byte x;

    if(NTPRequestPending)
    {
        StartWiznet();
        NTPRequestPending = false;
    }
    for(x=0; x<NUM_IP_ADDRESS_BYTES; x++)
        ntpip[x] = GetEEact(NTP_IP_ADDRESS1_LOC+x);

    memset(packetBuffer, 0, NTP_PACKET_SIZE); 
    packetBuffer[0] = 0b11100011;   // LI, Version, Mode
    packetBuffer[1] = 0;     // Stratum, or type of clock
    packetBuffer[2] = 6;     // Polling Interval
    packetBuffer[3] = 0xEC;  // Peer Clock Precision
    // 8 bytes of zero for Root Delay & Root Dispersion
    packetBuffer[12]  = 49; 
    packetBuffer[13]  = 0x4E;
    packetBuffer[14]  = 49;
    packetBuffer[15]  = 52;

    /* Send a packet requesting a timestamp */
    /* NTP requests always use port 123 */
    Udp.sendPacket(packetBuffer, NTP_PACKET_SIZE, ntpip, 123);
    NTPRequestPending = true;
}

/* leap year calulator expects year argument as years offset from 1970 */
#define LEAP_YEAR(Y)     ( ((1970+Y)>0) && !((1970+Y)%4) && ( ((1970+Y)%100) || !((1970+Y)%400) ) )

static  const uint8_t monthDays[]={31,28,31,30,31,30,31,31,30,31,30,31};

/* Fill in the time struct using UnixTime seconds */
/* year is offset from 1970 */
void SetTime()
{
    byte year = 0, month, monthLength;
    byte beginDSTdayofmonth, endDSTdayofmonth;
    float res;
    time_t time, days = 0UL;
    byte monthDays[]={31,28,31,30,31,30,31,31,30,31,30,31};

    /* Adjust for Time zone(-5 here on the east coast) - hard coded */
    /* Adjust for DST */
    time = UnixTime - (5*3600) + (hwtime.isdst * 3600);
  
    hwtime.sec = time % 60;
    time /= 60; // now it is minutes
    hwtime.min = time % 60;
    time /= 60; // now it is hours
    hwtime.hour = time % 24;
    time /= 24; // now it is days
    hwtime.wday = ((time + 4) % 7) + 1;  // Sunday is day 1 
  
    while((unsigned)(days += (LEAP_YEAR(year) ? 366 : 365)) <= time)
        year++;
    hwtime.year = year; /* year is offset from 1970 so in 2011 it will be 41 */
  
    days -= LEAP_YEAR(year) ? 366 : 365;
    time  -= days; // now it is days in this year, starting at 0
  
    days=0;
    month=0;
    monthLength=0;

    for(month=0; month<12; month++)
    {
        if(month==1)// february
        {
            if(LEAP_YEAR(year))
                monthLength=29;
            else
                monthLength=28;
        }
        else
            monthLength = monthDays[month];
    
        if(time >= monthLength)
            time -= monthLength;
        else
            break;
    }
    hwtime.month = month + 1;  // jan is month 1  
    hwtime.mday = time + 1;     // day of month
    hwtime.year += 2000-30; /* now year is 2011 */
    /* Set dst flag for US */
    /* See http://www.webexhibits.org/daylightsaving/i.html */
    /* Valid for years 1900 to 2006: */
    /* Begin DST: Sunday April (2+6*y-y/4) mod 7+1 */
    /* End DST: Sunday October (31-(y*5/4+1) mod 7) */
    /* 2007 and after: */
    /* Begin DST: Sunday March    14 - (1 + y*5/4) mod 7 */
    /* End DST: Sunday November    7 - (1 + y*5/4) mod 7 */
    /* Need to use an intermediate variable to calculate the float */
    /* part of the equation. Then round up so when it gets truncated */
    /* by conversion to int in the modulus part it will work. */
    /* This is all because mod only works on int - not float */
    /* in Arduino math. */
    res = (1.0 + ((hwtime.year-2000.0)*5.0/4.0))+.5;
    beginDSTdayofmonth = 14-(int)res%7;
    endDSTdayofmonth = 7-(int)res%7;
    if((hwtime.month > 3 && hwtime.month < 11)
           || (hwtime.month == 3 && hwtime.mday >= beginDSTdayofmonth)
           || (hwtime.month == 11 && hwtime.mday < endDSTdayofmonth) )
       hwtime.isdst = 1;
}
