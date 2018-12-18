/* server.pde */
/* 10/2009 RBH */

void ProcessServerRequest()
{
    char    buf[50], c, *cmd, *opt, *p;
    boolean getflag = false;
    byte  cnt = 0, x=0;
    
    Client client = server.available();
    if (client)
    {
        if(client.connected())
        {
            boolean nlflag;
            cnt = client.available(); /* need to call this or does not work */
            /* read all incoming chars but only save up to the first newline */
            for(x=0, nlflag=false; x<cnt; x++)
            {
                c = client.read();
                if(c == '\n' && !nlflag)
                {
                    nlflag = true;
                    if(x >= 49)
                        buf[49] = NULL;
                    else
                        buf[x] = NULL;
                }
                if(nlflag == false && x < 50)
                    buf[x] = c;
                //client.print(c); /* echo back the incoming request */
            }
            buf[49] = NULL;
            getflag = false;cmd=NULL;p=NULL;
            if(strncmp("GET", buf, 3) == 0)
            {
                p = buf+5; /* pointer moves to command */
                cmd = p;
                getflag = true;
            }
            for(opt=NULL; *p; p++)
            {
                if(*p == '=')
                {
                    opt = p+1;
                    *p = NULL;
                }
                if(*p == ' ')
                    *p = NULL; /* NULL terminate the string */
            }
            /* Must send this back or Perl GET causes memory corruption */
            /* here on the CPU. */
            client.println("HTTP/1.1 200 OK");
            client.println("Content-Type: text/html");
            client.println();
            if(getflag && strcmp(cmd, "data") == 0)
            {
                if(PrintLogRecord(&client, colon) == false)
                    client.println(0);
                else
                {
                    ZeroAvgTemps();
                    ZeroElapsedMillis();
                }
            }
            if(getflag && strcmp(cmd, "ram") == 0) /* get RAM bytes remaining */
                client.println(freeMemory());

            /* Should be the first request for the day to start */
            if(getflag && strcmp(cmd, "zero") == 0)
            {
                ZeroElapsedMillis();
                ZeroAvgTemps();
                client.println(1);
            }
            if(getflag && strcmp(cmd, "error") == 0)
            {
                client.println((int)ErrorFlag);
                client.println(ErrorString);
                for(x=0; x<NUM_DS18B20; x++)
                    Sdata[x].failcnt = 0;
                ErrorFlag = false;
                ErrorString = "";
            }
            if(getflag && strcmp(cmd, "sensors") == 0)
            {
                struct sensorEE ssEE;
                for(x=0;x<NUM_DS18B20;x++)
                {
                    GetEEsensor(x, &ssEE);
                    client.print((int)x);              client.print(colon);
                    client.print(ssEE.location);       client.print(colon);
                    client.print(Sdata[x].temp);       client.print(colon);
                    client.print(Sdata[x].avgsum);     client.print(colon);
                    client.print((int)Sdata[x].avgcnt);client.print(colon);
                    client.println((int)Sdata[x].failcnt);
                }
            }
            if(getflag && strcmp(cmd, "dump") == 0)
            {
                struct item i;
                
                if(PrintLogRecord(&client, colon) == false)
                    client.println(0);

                client.print("TurnOnTemp");  client.print(colon);client.println(TurnOnTemp);
                client.print("ActiveZone");  client.print(colon);client.println(DispActiveZone);
                client.print("UseTank");     client.print(colon);client.println(DispUseTank);
                client.print("MaxTankTemp1");client.print(colon);client.println((int)MaxTankTemp1);
                client.print("MaxTankTemp2");client.print(colon);client.println((int)MaxTankTemp2);
                client.print("TempDiff");    client.print(colon);client.println((int)TempDiff);
                client.print("DumpTemp");    client.print(colon);client.println(DumpTemp);
                client.print("ZoneEndSw");   client.print(colon);client.println((int)ZoneValveEndSwitch);
                client.print("TooHotFlag");  client.print(colon);client.println((int)CollectorTooHotFlag);
                client.print("HeatEnabled"); client.print(colon);client.println((int)HeatEnabled);
                client.print("ErrFlg");      client.print(colon);client.println((int)ErrorFlag);
                client.print("ErrStr");      client.print(colon);client.println(ErrorString);
                
                for(x=0; x<NUM_SLAVE_PINS; x++)
                {
                    client.print((int)x);          client.print(colon);
                    client.print(ss[x].desc);      client.print(colon);
                    client.print((int)ss[x].pin);  client.print(colon);
                    client.print((int)ss[x].state);client.print(colon);
                    client.println(ss[x].elapsed_millis);
                }
                for(x=0; x<sizeof(struct menu)/sizeof(struct item); x++)
                {
                    GetEEitem(x, &i);
                    client.print((int)x);    client.print(colon);
                    client.print(i.desc);    client.print(colon);
                    client.print((int)i.min);client.print(colon);
                    client.print((int)i.max);client.print(colon);
                    client.print((int)i.dft);client.print(colon);
                    client.println((int)i.act);
                }
            }
                    
            if(getflag && strcmp(cmd, "clockset") == 0)
            {
                /* format - 23:41:14:11:01:09:1 */
                /* hr:min:sec:month:day:yr:dayofweek(1-7) */
                if(opt)
                {
                    //byte sec, min, hr, day, dow, month, yr;
                    char *start;
                    
                    for(p=opt, start=opt, x=0; *p; p++)
                    {
                        if(*p == colon)
                        {
                            *p = NULL;
                            if(x==0) hr = (byte)atoi(start);
                            if(x==1) min = (byte)atoi(start);
                            if(x==2) sec = (byte)atoi(start);
                            if(x==3) month = (byte)atoi(start);
                            if(x==4) day = (byte)atoi(start);
                            if(x==5) yr = (byte)atoi(start);
                            start = p+1;
                            x++;
                        }
                    }
                    /* x should always be 6 at this point. */
                    if(x==6) dow = (byte)atoi(start);
                    setDateDs1307(sec, min, hr, dow, day, month, yr);
                }
                client.println();
            }
            if(getflag && strcmp(cmd, "clockread") == 0)
            {
                //byte sec, min, hr, day, dow, month, yr;
                /* format - 23:41:14:11:01:09:0 */
                /* hr:min:sec:month:day:yr:dayofweek */
                client.print((int)hr); client.print(colon);
                client.print((int)min); client.print(colon);
                client.print((int)sec); client.print(colon);
                client.print((int)month); client.print(colon);
                client.print((int)day); client.print(colon);
                client.print((int)yr); client.print(colon);
                client.println((int)dow);
            }
        }
        /* Give the web browser time to receive the data. */
        delay(1);
        client.stop();
    }
}

void ZeroElapsedMillis()
{
    byte x;

    for(x=0; x<NUM_SLAVE_PINS; x++)
        ss[x].elapsed_millis = 0UL;
    LastDataReqMillis = millis();
}

void ZeroAvgTemps()
{
    byte x;

    for(x=0; x<NUM_DS18B20; x++)
    {
        Sdata[x].avgsum = Sdata[x].temp;
        Sdata[x].avgcnt = 1;
    }
}

/* Notice that the fraction of time the zone was on */
/* since the last data request is given. */
float CalcOnTimeFraction(byte pin)
{
    if(ss[FindSlaveIdx(pin)].elapsed_millis==0ul)
        return(0);
    else
        return((float)ss[FindSlaveIdx(pin)].elapsed_millis/
                  (float)(millis() - LastDataReqMillis) );
}

boolean PrintLogRecord(Client *client, char colon)
{
    if(Sdata[COLLECTOR_LOC].avgcnt > 0 && 
                   Sdata[T1TOP_LOC].avgcnt > 0 &&
                   Sdata[T1BOT_LOC].avgcnt > 0 &&
                   Sdata[T2TOP_LOC].avgcnt > 0 &&
                   Sdata[T2BOT_LOC].avgcnt > 0)
    {
        /* Calc the avg temp since the last request */
        client->print(Sdata[COLLECTOR_LOC].avgsum/Sdata[COLLECTOR_LOC].avgcnt);
        client->print(colon);
        client->print(Sdata[T1TOP_LOC].avgsum/Sdata[T1TOP_LOC].avgcnt);
        client->print(colon);
        client->print(Sdata[T1BOT_LOC].avgsum/Sdata[T1BOT_LOC].avgcnt);
        client->print(colon);
        client->print(Sdata[T2TOP_LOC].avgsum/Sdata[T2TOP_LOC].avgcnt);
        client->print(colon);
        client->print(Sdata[T2BOT_LOC].avgsum/Sdata[T2BOT_LOC].avgcnt);
        client->print(colon);
        
        /* Now do the pump and zone valves */
        client->print(CalcOnTimeFraction(PUMP_PIN));
        client->print(colon);
        client->print(CalcOnTimeFraction(ZONE_WATER_TANK1_PIN));
        client->print(colon);
        client->print(CalcOnTimeFraction(ZONE_WATER_TANK2_PIN));
        client->print(colon);
        client->print(CalcOnTimeFraction(ZONE_HOUSE_PIN));
        client->print(colon);
        client->println(CalcOnTimeFraction(ZONE_GARAGE_PIN));
        return(true);
    }
    else
        return(false);
}
