/* screens.pde rbh 10/2010 */
/* All the display functions */

/* Collector */
void SensorConfig1(byte level, byte pin)
{
    SensorConfig(&ds1, level, pin);
}

/* The rest of the temp sensors */
void SensorConfig2(byte level, byte pin)
{
    SensorConfig(&ds2, level, pin);
}

void SensorConfig(OneWire *dsptr, byte level, byte pin)
{
    struct sensorEE ssEE;
    static byte addr[8];
    static byte sensor_num;
    byte byte_cnt;
    boolean found;

    MenuTimerCnt = MENU_ON_SECONDS;
    if(level == 1)
    {
        if(!dsptr->search(addr))
        {
            dsptr->reset_search();
            dsptr->search(addr);
        }
        for(sensor_num=0; sensor_num<NUM_DS18B20; sensor_num++)
        {
            found=true;
            GetEEsensor(sensor_num, &ssEE);
            for(byte_cnt=0; byte_cnt < NUM_DS18B20_ADDRESS_BYTES; byte_cnt++)
            {
                if(ssEE.addr[byte_cnt] != addr[byte_cnt])
                    found = false;
            }
            if(found == true)
                break;
        }
        GLCD.EraseTextLine(5);
        for(byte_cnt = 0; byte_cnt < NUM_DS18B20_ADDRESS_BYTES; byte_cnt++)
            GLCD.Printf("%x ", addr[byte_cnt]);
 
        GLCD.EraseTextLine(7);
        GLCD.EraseTextLine(6);
        if(found)
            GLCD.Printf("Used: %s", ssEE.location);
        else
        {
            GLCD.Puts("Not Used");
            GLCD.EraseTextLine(eraseTO_EOL);
        }
    }
    if(level == 2)
    {
        if(pin == SAVEBUTTONPIN) /* first time in level 2 */
            sensor_num = 1;
        if(pin == UPBUTTONPIN)
        {
            if(++sensor_num == NUM_DS18B20)
                sensor_num = 0;
        }
        if(pin == DNBUTTONPIN)
        {
            if(sensor_num > 0)
                sensor_num--;
            else
                sensor_num = NUM_DS18B20-1;
        }
        GLCD.EraseTextLine(7);
        GetEEsensor(sensor_num, &ssEE);
        GLCD.Printf("New Loc: %s", ssEE.location);
    }
    if(level == 3 && pin == SAVEBUTTONPIN)
    {
        GetEEsensor(sensor_num, &ssEE);
        for(byte_cnt=0; byte_cnt < NUM_DS18B20_ADDRESS_BYTES; byte_cnt++)
            ssEE.addr[byte_cnt] = addr[byte_cnt];
        WriteEEsensor(sensor_num, &ssEE);
        GLCD.EraseTextLine(5);
        GLCD.Puts("Saved");
    }
}

/***** ConfigParam() *****/
void ConfigParam(byte level, byte pin)
{
    static byte   offset = 0;
    static byte   displayact;
    struct item   i, *iptr;
    char   strtemp[6];
    byte   num_array_items;

    MenuTimerCnt = MENU_ON_SECONDS;
    num_array_items = sizeof(struct menu)/sizeof(struct item);

    if(level == 1)
    {
        if(pin == UPBUTTONPIN)
            if(++offset > num_array_items-1)
                offset = 0;
        if(pin == DNBUTTONPIN)
            if(offset == 0)
                offset = num_array_items-1;
            else
                offset--;
    }
    GetEEitem(offset, &i);
    
    GLCD.EraseTextLine(7);
    GLCD.EraseTextLine(5);
    GLCD.Puts(i.desc);
    GLCD.EraseTextLine(6);
    GLCD.CursorTo(2, 6);
    GLCD.Puts("Min Max Act");
    if(level == 2)
    {
        if(pin == SAVEBUTTONPIN)
            displayact = i.act;
        if(pin == UPBUTTONPIN)
            if(displayact < i.max)
                displayact++;
        if(pin == DNBUTTONPIN)
            if(displayact > i.min)
                displayact--;
        GLCD.CursorTo(2, 7);
        GLCD.Printf("%d", i.min);
        GLCD.CursorTo(6, 7);
        GLCD.Printf("%d", i.max);
        GLCD.CursorTo(10, 7);
        GLCD.Printf("%d", displayact);
    }    
    if(level == 3 && pin == SAVEBUTTONPIN)
    {
        i.act = displayact;
        WriteEEitem(offset, &i);
        if(offset == NTP_TIME_FLAG_LOC)
            StartWiznet();
        GLCD.CursorTo(15, 7);GLCD.Puts("Saved");
    }
}

/* Manual() */
void Manual(byte level, byte pin)
{
    static byte   offset = 0;
    static byte   displaystate;
    struct output   o, *optr;
    byte   num_items;

    MenuTimerCnt = MENU_ON_SECONDS;
    
    optr = (struct output *)&CurrStatus;
    num_items = sizeof(struct stat)/sizeof(struct output);

    if(level == 1)
    {
        if(pin == UPBUTTONPIN)
            if(++offset > num_items-1)
                offset = 0;
        if(pin == DNBUTTONPIN)
            if(offset == 0)
                offset = num_items-1;
            else
                offset--;
    }
    memcpy(&o, optr+offset, sizeof(struct output));

    GLCD.CursorTo(0, 6); /* col, row */
    GLCD.Puts(o.desc); GLCD.EraseTextLine();
    GLCD.EraseTextLine(7);
    if(level == 2)
    {
        if(pin == SAVEBUTTONPIN)
            displaystate = o.state;
        if(pin == UPBUTTONPIN)
            displaystate = 1;
        if(pin == DNBUTTONPIN)
            displaystate = 0;

        GLCD.CursorTo(strlen(o.desc), 6); /* col, row */
        GLCD.EraseTextLine();
        if(displaystate)
            GLCD.Puts("On");
        else
            GLCD.Puts("Off");
    }    
    if(level == 3 && pin == SAVEBUTTONPIN)
    {
        GLCD.CursorTo(0, 7); /* col, row */
        if(offset > 0 && CurrStatus.Manual.state == 0)
            GLCD.Puts("Not in manual mode");
        else
        {
            o.state = displaystate;
            optr = (struct output *)&CurrStatus + offset;
            optr->state = o.state;
            GLCD.Puts("Saved");
        }
    }
}

/* Clear the LCD display; backlight on full; Print screen name on line 0 */
void SetupForNewScreen()
{
    MenuTimerCnt = MENU_ON_SECONDS;
    if(CurScreenIdx == 0)
    {
        GLCD.DrawRoundRect(GARAGE_X_POS, ZONE_Y_POS, GARAGE_WIDTH, ZONE_HEIGHT, 5);  /* Garage */
        GLCD.DrawRoundRect(TANK1_X_POS, ZONE_Y_POS, TANK1_WIDTH, ZONE_HEIGHT, 5); /* x, y, width, height, radius */ /* Tank1 */
        GLCD.DrawRoundRect(TANK2_X_POS, ZONE_Y_POS, TANK2_WIDTH, ZONE_HEIGHT, 5); /* Tank2 */
        GLCD.DrawRoundRect(HOUSE_X_POS, ZONE_Y_POS, HOUSE_WIDTH, ZONE_HEIGHT, 5);  /* House */
        GLCD.DrawRoundRect(COLLECTOR_X_POS, ZONE_Y_POS, COLLECTOR_WIDTH, ZONE_HEIGHT, 5); /* Collector */
        
        GLCD.CursorToXY(GARAGE_X_POS+2, 13); /* x y */
        GLCD.PutChar('G');
        GLCD.CursorToXY(GARAGE_X_POS+2, 21); /* x y */
        GLCD.PutChar('A');
        GLCD.CursorToXY(GARAGE_X_POS+2, 29); /* x y */
        GLCD.PutChar('R');
    
        GLCD.CursorToXY(HOUSE_X_POS+2, 13); /* x y */
        GLCD.PutChar('H');
        GLCD.CursorToXY(HOUSE_X_POS+2, 21); /* x y */
        GLCD.PutChar('S');
        GLCD.CursorToXY(HOUSE_X_POS+2, 29); /* x y */
        GLCD.PutChar('E');
        
        GLCD.CursorToXY(TANK1_X_POS+2, 21); /* x y */
        GLCD.Puts("Tank1");
        GLCD.CursorToXY(TANK2_X_POS+2, 21); /* x y */
        GLCD.Puts("Tank2");
    }
    GLCD.SelectFont(System5x7, BLACK);
    GLCD.CursorTo(0, 5); /* col row */
    GLCD.EraseTextLine(5);
    GLCD.CursorTo(0, 6); /* col row */
    GLCD.EraseTextLine(6);
    GLCD.CursorTo(0, 7); /* col row */
    GLCD.EraseTextLine(7);

    if(CurScreenIdx > 0)
    {
        GLCD.CursorTo(5, 5); /* col row */
        GLCD.Puts(Screens[CurScreenIdx].ScreenName);
    }
}

/* MainScreen - Called from loop() */
/* X->  Ydown */
void MainScreen(byte level, byte pin)
{
    char     strtemp[8];
    
    GLCD.SelectFont(System5x7, BLACK);
    /* Tank1 temps */
    GLCD.CursorToXY(TANK1_X_POS+2, 13); /* x y */
    GLCD.Puts(ftoa(TSdata[T1TOP_LOC].avgtemp, strtemp, 5));
    GLCD.CursorToXY(TANK1_X_POS+2, 29); /* x y */
    GLCD.Puts(ftoa(TSdata[T1BOT_LOC].avgtemp, strtemp, 5));
    
    /* Tank2 temps */
    GLCD.CursorToXY(TANK2_X_POS+2, 13); /* x y */
    GLCD.Puts(ftoa(TSdata[T2TOP_LOC].avgtemp, strtemp, 5));
    GLCD.CursorToXY(TANK2_X_POS+2, 29); /* x y */
    GLCD.Puts(ftoa(TSdata[T2BOT_LOC].avgtemp, strtemp, 5));

    /* Collector */
    GLCD.CursorToXY(COLLECTOR_X_POS+2, 13); /* x y */
    GLCD.Puts(ftoa(TSdata[COLLECTOR_LOC].avgtemp, strtemp, 5));
    GLCD.CursorToXY(COLLECTOR_X_POS+2, 21); /* x y */
    if(CurrStatus.Pump.state == 0)
        GLCD.Puts(" On @");
    else
        GLCD.Puts("Off @");
    GLCD.CursorToXY(COLLECTOR_X_POS+2, 29); /* x y */
    GLCD.Puts(ftoa(TurnOnTemp, strtemp, 5));

    GLCD.DrawVLine(GARAGE_X_POS+GARAGE_WIDTH/2, 2, 7); /* x y height line to garage */
    GLCD.DrawVLine(TANK1_X_POS+TANK1_WIDTH/2, 2, 7); /* x y height line to tank1 */
    GLCD.DrawVLine(TANK2_X_POS+TANK2_WIDTH/2, 2, 7); /* x y height line to tank2 */
    GLCD.DrawVLine(HOUSE_X_POS+HOUSE_WIDTH/2, 2, 7); /* x y height line to house */
    GLCD.DrawVLine(COLLECTOR_X_POS+COLLECTOR_WIDTH/2, 2, 7); /* x y height line to collector */
    GLCD.DrawHLine(GARAGE_X_POS+GARAGE_WIDTH/2, 2, 
            (COLLECTOR_X_POS+COLLECTOR_WIDTH/2)-(GARAGE_X_POS+GARAGE_WIDTH/2)); /* x y width */
    if(CurScreenIdx == 0)
    {
        GLCD.CursorTo(0, 5); /* col, row */
        GLCD.Printf("ZV %s", ZoneValveEndSwitch ? "Opened" : "Closed");
        GLCD.CursorTo(0, 6); /* col, row */
        GLCD.Printf("%s %s", HeatEnabled ? "HE": "  ", DumpFlag ? "DF" : "  ");
        DisplayMsg();
        //if(GetEEact(NTP_TIME_FLAG_LOC))
        if(UnixTimeIsGood)
        {
            GLCD.CursorTo(0, 7);
            GLCD.Printf(" %02d/%02d/%d %02d:%02d:%02d", hwtime.month, hwtime.mday, hwtime.year,
                       hwtime.hour, hwtime.min, hwtime.sec);
        }
    }
}
    
void FreeRAM(byte level, byte pin)
{
    MenuTimerCnt = MENU_ON_SECONDS;
    GLCD.EraseTextLine(6);
    GLCD.PrintNumber((long)freeMemory());
}     

void BackLight(byte pwm_value)
{
    analogWrite(BACKLIGHT_PIN, pwm_value);
    if(pwm_value == BACKLIGHT_FULL)
        BackLightTimer = BACKLIGHT_TIMER_MIN;
}

/* Add a message to the array of message structures. */
/* Do not add a duplicate. */
/* Add it as close as possible to the top(0 element) of the array. */
/* Only the 0 element is displayed. */
/* The DelMsg() function decrements the display counter timer and */
/* removes the message when the cnt gets to 0. Then all other messages */
/* are moved up closer to the 0 element. */
/* The DelMsg() function is called from the MainScreen() function */
/* which is run every time a temp reading is updated. About every 800 ms. */
/* So the Msg.cnt controls the time the message is on the display */
/* cnt = 3 = 3*.8 = 2.4 secs */
void AddMsg(char *line1, char *line2)
{
    int x, idx = 0; /* byte did not work counting backwards */
    boolean found = false;

    for(x=NUM_MSG-1; x>=0; x--)
    {
        if(strncmp(Msg[x].line1, line1, MSG_LENGTH) == 0 && strncmp(Msg[x].line2, line2, MSG_LENGTH) == 0)
            found = true;
        if(Msg[x].cnt == 0)
            idx = x;
    }
    if(!found)
    {
        strncpy(Msg[idx].line1, line1, MSG_LENGTH);
        strncpy(Msg[idx].line2, line2, MSG_LENGTH);
        Msg[idx].line1[MSG_LENGTH] = NULL;
        Msg[idx].line2[MSG_LENGTH] = NULL;
        Msg[idx].cnt = 3;
    }
}

void DelMsg()
{
    if(Msg[0].cnt > 0)
        Msg[0].cnt--;
    if(Msg[0].cnt == 0)
    {
        byte x;
        for(x = 0; x < NUM_MSG-1; x++)
            memcpy(&Msg[x], &Msg[x+1], sizeof(struct message));

        Msg[NUM_MSG-1].line1[0] = NULL;
        Msg[NUM_MSG-1].line2[0] = NULL;
        Msg[NUM_MSG-1].cnt = 0;
    }
}

void DisplayMsg()
{
    GLCD.CursorTo(9, 5); /* col, row */
    GLCD.Printf("%12.12s", Msg[0].line1);
    GLCD.CursorTo(9, 6); /* col, row */
    GLCD.Printf("%12.12s", Msg[0].line2);
    DelMsg();
}

/* MoveBall() - make a ball move along the lines from collector to the active */
/* zone. If the pump is off then place the ball right above the active zone */
/* box. The arrays are made up of the 3 segments of each route from */
/* collector(1) across the top(2) and down to the zone (3). */

void MoveBall()
{
    static byte sgcnt, prevzonepin;
    static byte startx=0, starty=0, endx=0, endy=0;
    boolean revx=false, revy=false;
    byte   *sgptr;
    
    byte g[] = {
        COLLECTOR_X_POS+COLLECTOR_WIDTH/2, ZONE_Y_POS-3, COLLECTOR_X_POS+COLLECTOR_WIDTH/2, 2,
        COLLECTOR_X_POS+COLLECTOR_WIDTH/2, 2, GARAGE_X_POS+GARAGE_WIDTH/2, 2,
        GARAGE_X_POS+GARAGE_WIDTH/2, 2, GARAGE_X_POS+GARAGE_WIDTH/2, ZONE_Y_POS-3 };
    byte t1[] = {
        COLLECTOR_X_POS+COLLECTOR_WIDTH/2, ZONE_Y_POS-3, COLLECTOR_X_POS+COLLECTOR_WIDTH/2, 2,
        COLLECTOR_X_POS+COLLECTOR_WIDTH/2, 2, TANK1_X_POS+TANK1_WIDTH/2, 2,
        TANK1_X_POS+TANK1_WIDTH/2, 2, TANK1_X_POS+TANK1_WIDTH/2, ZONE_Y_POS-3 };
    byte t2[] = {
        COLLECTOR_X_POS+COLLECTOR_WIDTH/2, ZONE_Y_POS-3, COLLECTOR_X_POS+COLLECTOR_WIDTH/2, 2,
        COLLECTOR_X_POS+COLLECTOR_WIDTH/2, 2, TANK2_X_POS+TANK2_WIDTH/2, 2,
        TANK2_X_POS+TANK2_WIDTH/2, 2, TANK2_X_POS+TANK2_WIDTH/2, ZONE_Y_POS-3 };
    byte h[] = {
        COLLECTOR_X_POS+COLLECTOR_WIDTH/2, ZONE_Y_POS-3, COLLECTOR_X_POS+COLLECTOR_WIDTH/2, 2,
        COLLECTOR_X_POS+COLLECTOR_WIDTH/2, 2, HOUSE_X_POS+HOUSE_WIDTH/2, 2,
        HOUSE_X_POS+HOUSE_WIDTH/2, 2, HOUSE_X_POS+HOUSE_WIDTH/2, ZONE_Y_POS-3 };

    if(ActiveZonePin == GARAGE_PIN)
        sgptr = g;
    else if(ActiveZonePin == TANK1_PIN)
        sgptr = t1;
    else if(ActiveZonePin == TANK2_PIN)
        sgptr = t2;
    else if(ActiveZonePin == HOUSE_PIN)
        sgptr = h;
    else return;

    if(startx > 0) /* erase the last circle */
        GLCD.DrawCircle(startx, starty, 2, WHITE); /* x y radius */

    /* position the circle to right above the active zone box */
    /* if the pump is not running */
    if(CurrStatus.Pump.state == 0)
    {
        startx = sgptr[10];
        starty = sgptr[11];
    }
    else
    {
        if(prevzonepin != ActiveZonePin)
        {
            prevzonepin = ActiveZonePin;
            sgcnt = 0;
            startx = sgptr[(sgcnt*4)+0];
            starty = sgptr[(sgcnt*4)+1];
            endx = sgptr[(sgcnt*4)+2];
            endy = sgptr[(sgcnt*4)+3];
        }
        else
        {
            if(startx == endx && starty == endy)
            {
                if(++sgcnt > 2)
                    sgcnt = 0;
                startx = sgptr[(sgcnt*4)+0];
                starty = sgptr[(sgcnt*4)+1];
                endx = sgptr[(sgcnt*4)+2];
                endy = sgptr[(sgcnt*4)+3];
            }
            else
            {
                if(startx > endx)
                    revx = true;
                if(starty > endy)
                    revy = true;
                if(!revx && startx < endx)
                    if(startx + 2 > endx)
                        startx++;
                    else
                        startx += 2;
                if(revx && startx > endx)
                    if(startx - 2 < endx)
                        startx--;
                    else
                        startx -= 2;
                if(!revy && starty < endy)
                    if(starty + 2 > endy)
                        starty++;
                    else
                        starty += 2;
                if(revy && starty > endy)
                    if(starty - 2 > endy)
                        starty--;
                    else
                        starty -= 2;
            }
        }
    }
    GLCD.DrawCircle(startx, starty, 2, BLACK);
    BallTimerFlag = false;
}
