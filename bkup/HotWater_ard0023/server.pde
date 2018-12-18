/* server.pde */
/* 10/2009 RBH */
/* Check is there is a client request and process that request. */

void ProcessServerRequest()
{
    char    buf[50], c, *cmd, *opt, *p;
    boolean getflag = false;
    byte  cnt = 0, x=0, statcnt = 0;

    Client client = server.available();
    if (client)
    {
        digitalWrite(LED_PIN, HIGH); /* flash the teensy on-board led */
        if(client.connected())
        {
            boolean nlflag;
            memset(buf, NULL, sizeof(buf));
            
            AddMsg("Server", "Request");
            
            /* returns numbers of chars to read */
            cnt = client.available(); /* need to call this or does not work */
            /* read all incoming chars but only save up to the first newline */
            for(x=0, nlflag=false; x<cnt && client.available();x++)
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
                byte i;
                for(x=0; x<NUM_HISTORY_RECS;x++)
                {
                    client.print(History[x].unixtime);client.print(colon);
                    for(i=0;i<NUM_DS18B20;i++)
                    {
                        client.print(History[x].TS[i].avgtemp);
                        client.print(colon);
                    }
                    client.print((int)History[x].CS.Pump.state);client.print(colon);
                    client.print((int)History[x].CS.PumpGarage.state);client.print(colon);
                    client.print((int)History[x].CS.Tank1.state);client.print(colon);
                    client.print((int)History[x].CS.Tank2.state);client.print(colon);
                    client.print((int)History[x].CS.House.state);client.print(colon);
                    client.print((int)History[x].CS.Garage.state);client.print(colon);
                    client.print((int)History[x].CS.Stiebel.state);
                    client.println();
                }
            }
            if(getflag && strncmp(cmd, "ram", 3) == 0) /* get RAM bytes remaining */
            {
                client.println(freeMemory());
            }

            if(getflag && strncmp(cmd, "error", 5) == 0)
            {
                for(x=0; x<NUM_DS18B20; x++)
                    TSdata[x].failcnt = 0;
            }
            if(getflag && strncmp(cmd, "sensors", 7) == 0)
            {
                struct sensorEE ssEE;
                byte byte_cnt;
                for(x=0;x<NUM_DS18B20;x++)
                {
                    GetEEsensor(x, &ssEE);
                    client.print((int)x);              client.print(colon);
                    for(byte_cnt=0; byte_cnt < NUM_DS18B20_ADDRESS_BYTES; byte_cnt++)
                    {
                        client.print(ssEE.addr[byte_cnt], HEX);
                        if(byte_cnt < NUM_DS18B20_ADDRESS_BYTES-1)
                            client.print(' ');
                    }
                    client.print(colon);
                    client.print(ssEE.location);       client.print(colon);
                    client.print(TSdata[x].avgtemp);       client.print(colon);
                    client.println((int)TSdata[x].failcnt);
                }
            }
                    
            if(getflag && strncmp(cmd, "clockset", 8) == 0)
            {
                /* format - unsigned long (time_t) */
                /* -clockset=1234567890 */
                if(opt)
                {
                    UnixTime = (time_t)strtoul(opt, NULL, 0);
                    UnixTimeIsGood = true;
                }
                client.println();
            }
            if(getflag && strncmp(cmd, "clockread", 9) == 0)
            {
                client.print(UnixTime);
                client.println();
            }
            
            if(getflag && strncmp(cmd, "setparam", 8) == 0)
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
            if(getflag && strncmp(cmd, "getparam", 8) == 0)
            {
                struct item   i;
                    
                 for(x=0; x<sizeof(struct menu)/sizeof(struct item); x++)
                {
                    GetEEitem(x, &i);
                    client.print((int)x);    client.print(colon);
                    client.print(i.desc);    client.print(colon);
                    client.print((int)i.min);client.print(colon);
                    client.print((int)i.max);client.print(colon);
                    client.println((int)i.act);
                }
            }
        }
        /* Give the client web browser time to receive the data. */
        delay(1);
        client.flush();
        client.stop();
        digitalWrite(LED_PIN, LOW);
    }
}

void StartWiznet()
{
    byte ip[NUM_IP_ADDRESS_BYTES], mac[NUM_MAC_ADDRESS_BYTES];
    byte dftgateway[NUM_IP_ADDRESS_BYTES], subnetmask[NUM_IP_ADDRESS_BYTES];
    byte x;

    AddMsg("Wiznet", "Reset");
    for(x=0; x<NUM_IP_ADDRESS_BYTES; x++)
    {
        ip[x] = GetEEact(IP_ADDRESS1_LOC+x);
        dftgateway[x] = GetEEact(DFT_GATEWAY1_LOC+x);
        subnetmask[x] = GetEEact(SUBNET_MASK1_LOC+x);
    }
    for(x=0; x<NUM_MAC_ADDRESS_BYTES; x++)
        mac[x] = GetEEact(MAC_ADDRESS1_LOC+x);
    
    /* /Reset Wiznet ethernet module. Otherwise, sometimes it does */
    /* not work after a power up. */
    digitalWrite(WIZRESET_PIN, LOW);
    delay(1); /* Wiznet datasheet says 2us is all that is needed for a reset */
    digitalWrite(WIZRESET_PIN, HIGH);
    
    Ethernet.begin(mac, ip, dftgateway, subnetmask);
    server.begin();
    if(GetEEact(NTP_TIME_FLAG_LOC))
        Udp.begin(NTP_UDP_PORT);
}
