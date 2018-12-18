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
            
            LastServerReq = millis();
            memset(buf, NULL, sizeof(buf));
            cnt = client.available(); /* need to call this or does not work */
            /* read all incoming chars but only save up to the first newline */
            for(x=0, nlflag=false; x<cnt && client.available(); x++)
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
            for(opt=NULL; getflag && *p; p++)
            {
                if(*p == '=')
                {
                    opt = p+1;
                    *p = NULL;
                }
                if(*p == ' ')
                    *p = NULL; /* NULL terminate the string */
            }
            client.println("HTTP/1.1 200 OK");
            client.println("Content-Type: text/html");
            client.println();
            if(getflag && strncmp(cmd, "data", 4) == 0)
            {
                if(PrintLogRecord(&client, colon) == false)
                    client.println(0);
                else
                {
                    ZeroAvgTemps();
                    ZeroElapsedMillis();
                }
            }
            if(getflag && strncmp(cmd, "ram", 3) == 0) /* get RAM bytes remaining */
            {
                client.println(freeMemory());
            }

            /* Should be the first request for the day to start */
            if(getflag && strncmp(cmd, "zero", 4) == 0)
            {
                ZeroElapsedMillis();
                ZeroAvgTemps();
                client.println(1);
            }
            if(getflag && strncmp(cmd, "error", 5) == 0)
            {
                client.println(ErrorString);
                for(x=0; x<NUM_DS18B20; x++)
                    TSdata[x].failcnt = 0;
                ErrorString = "";
                CollectorTooHotFlag = false;
            }
            if(getflag && strncmp(cmd, "sensors", 7) == 0)
            {
                struct sensorEE ssEE;
                for(x=0;x<NUM_DS18B20;x++)
                {
                    GetEEsensor(x, &ssEE);
                    client.print((int)x);              client.print(colon);
                    client.print(ssEE.location);       client.print(colon);
                    client.print(TSdata[x].temp);       client.print(colon);
                    client.print(TSdata[x].avgsum);     client.print(colon);
                    client.print((int)TSdata[x].avgcnt);client.print(colon);
                    client.println((int)TSdata[x].failcnt);
                }
            }
            if(getflag && strncmp(cmd, "dump", 4) == 0)
            {
                struct item i;
                
                if(PrintLogRecord(&client, colon) == false)
                    client.println(0);

                client.print("TurnOnTemp");  client.print(colon);client.println(TurnOnTemp);
                client.print("ActiveZone");  client.print(colon);client.println(DispActiveZone);
                client.print("EnabledZone"); client.print(colon);client.println(DispEnabledZone);
                client.print("MaxTankTemp1");client.print(colon);client.println((int)MaxTankTemp1);
                client.print("MaxTankTemp2");client.print(colon);client.println((int)MaxTankTemp2);
                client.print("TempDiff");    client.print(colon);client.println((int)TempDiff);
                client.print("DumpTemp");    client.print(colon);client.println(DumpTemp);
                client.print("ZoneEndSw");   client.print(colon);client.println((int)ZoneValveEndSwitch);
                client.print("TooHotFlag");  client.print(colon);client.println((int)CollectorTooHotFlag);
                client.print("HeatEnabled"); client.print(colon);client.println((int)HeatEnabled);
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
                    
            if(getflag && strncmp(cmd, "clockset", 8) == 0)
            {
                /* format - 23:41:14:11:01:09:1 */
                /* hr:min:sec:month:day:yr:dayofweek(1-7) */
                if(opt)
                {
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
                    SetDateDs1307(sec, min, hr, dow, day, month, yr);
                }
                client.println();
            }
            if(getflag && strncmp(cmd, "clockread", 9) == 0)
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
            
            if(getflag && strncmp(cmd, "param", 5) == 0)
            {   /* format - param=IndexIntoEEMEMarray:value */
                byte ret = 0;
                byte EEMEMidx, value;
                struct item   i;
                    
                for(p=opt; *p && opt; p++)
                {
                    if(*p == colon)
                    {
                        *p = NULL;
                        EEMEMidx = (byte)atoi(opt);
                        value = (byte)atoi(p+1);
                        GetEEitem(EEMEMidx, &i);
                        if(value >= i.min && value <= i.max)
                        {
                            i.act = value;
                            WriteEEitem(EEMEMidx, &i);
                            ret = 1;
                        }
                    }
                }
                client.println((int)ret);
            }
        }
        /* Give the web browser time to receive the data. */
        delay(1);
        client.flush();
        client.stop();
    }
}

void ZeroElapsedMillis()
{
    byte x;

    LastDataReqMillis = millis();
    for(x=0; x<NUM_SLAVE_PINS; x++)
    {
        ss[x].elapsed_millis = 0ul;
        ss[x].start_millis = LastDataReqMillis;
    }
}

void ZeroAvgTemps()
{
    byte x;

    for(x=0; x<NUM_DS18B20; x++)
    {
        if(TSdata[x].avgcnt >= 1)
        {
            TSdata[x].avgsum = TSdata[x].temp;
            TSdata[x].avgcnt = 1;
        }
        else
        {
            TSdata[x].avgsum = 0;
            TSdata[x].avgcnt = 0;
        }
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
    if(TSdata[COLLECTOR_LOC].avgcnt > 0 && 
                   TSdata[T1TOP_LOC].avgcnt > 0 &&
                   TSdata[T1BOT_LOC].avgcnt > 0 &&
                   TSdata[T2TOP_LOC].avgcnt > 0 &&
                   TSdata[T2BOT_LOC].avgcnt > 0)
    {
        /* Calc the avg temp since the last request */
        client->print(TSdata[COLLECTOR_LOC].avgsum/TSdata[COLLECTOR_LOC].avgcnt);
        client->print(colon);
        client->print(TSdata[T1TOP_LOC].avgsum/TSdata[T1TOP_LOC].avgcnt);
        client->print(colon);
        client->print(TSdata[T1BOT_LOC].avgsum/TSdata[T1BOT_LOC].avgcnt);
        client->print(colon);
        client->print(TSdata[T2TOP_LOC].avgsum/TSdata[T2TOP_LOC].avgcnt);
        client->print(colon);
        client->print(TSdata[T2BOT_LOC].avgsum/TSdata[T2BOT_LOC].avgcnt);
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

/* See http://www.arduino.cc/cgi-bin/yabb2/YaBB.pl?num=1238295170/30 */
/* for a possible solution to the Wiznet module hanging after 4 connections */
/* are made. For now I'm going to call this func every 15 minutes */
/* as the arduino forum solution entails changing the Server.cpp library code */
void StartWiznet()
{
    byte ip[NUM_IP_ADDRESS_BYTES], mac[NUM_MAC_ADDRESS_BYTES], dftgateway[NUM_IP_ADDRESS_BYTES], subnetmask[NUM_IP_ADDRESS_BYTES];
    byte x;

    LastWiznetReset = millis();
    for(x=0;x<NUM_IP_ADDRESS_BYTES;x++)
    {
        ip[x] = GetEEact(IP_ADDRESS1_LOC+x);
        dftgateway[x] = GetEEact(DFT_GATEWAY1_LOC+x);
        subnetmask[x] = GetEEact(SUBNET_MASK1_LOC+x);
    }
    for(x=0;x<NUM_MAC_ADDRESS_BYTES;x++)
        mac[x] = GetEEact(MAC_ADDRESS1_LOC+x);

    /* /Reset Wiznet ethernet module. Otherwise, sometimes it does */
    /* not work after a power up. */
    digitalWrite(WizNetResetPin, LOW);
    delay(1);
    digitalWrite(WizNetResetPin, HIGH);
    
    Ethernet.begin(mac, ip, dftgateway, subnetmask);
    server.begin();
}
