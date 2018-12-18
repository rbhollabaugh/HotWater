/* CalcHotWater.pde */

/* This function gets called when startflg is true (when a temp reading is complete) from loop(). */
void CalcHotWater()
{
    byte     MaxTankTempMin;
    static byte PrevActiveZonePin=0, ActiveZonePin = 0, TimedZonePin = 0;
    float   TankTempAvg1, TankTempAvg2;
    boolean  UseTank1, UseTank2;
    static byte Tank1Tank2Diff = 10;
    static byte StiebelTemp = STIEBEL_TEMP_START;
    static unsigned long prev_millis = 0ul;

    /****** init variables ******/
    UseTank1 = (boolean)GetEEact(USE_TANK1_LOC);
    UseTank2 = (boolean)GetEEact(USE_TANK2_LOC);
    DumpFlag = false;
    if(prev_millis == 0ul)
        prev_millis = millis();
 
    MaxTankTempMin = GetEEact(MAX_TANK_TEMP_LOC) - 2;
    PrevActiveZonePin = ActiveZonePin;
    ActiveZonePin = 0;
    TankTempAvg1 = (Sdata[T1TOP_LOC].temp+Sdata[T1BOT_LOC].temp)/2;
    TankTempAvg2 = (Sdata[T2TOP_LOC].temp+Sdata[T2BOT_LOC].temp)/2;
    /* ************************* */
    if(Sdata[T1TOP_LOC].temp < StiebelTemp)
    {
       StiebelTemp = STIEBEL_TEMP_START + 1;
       SendToSlave(ZONE_STIEBEL_PIN, HIGH);
    }
    else
    {
       StiebelTemp = STIEBEL_TEMP_START;
       SendToSlave(ZONE_STIEBEL_PIN, LOW);
    }
    
    /* Tank1 has priority over Tank2. Bring each tank up to MaxTankTemp and */
    /* when both are up to temp then send hot glycol to either the house */
    /* radiator or the garage. At the end of the day dump hot glycol to house */
    /* radiator or garage. */

    if(UseTank1 == true && UseTank2 == true)
    {
        if(Sdata[T1TOP_LOC].temp <= MaxTankTemp1 && TankTempAvg1-TankTempAvg2 <= Tank1Tank2Diff)
        {
            UseTank2 = false;
            Tank1Tank2Diff = 20;
        }
        else
        {
            UseTank1 = false;
            Tank1Tank2Diff = 10;
            /* Set lower level of hysteresis here for tank1 because it does not get set in the */
            /* if UseTank1 section below when both tanks are InUse. */
            if(MaxTankTemp1 == GetEEact(MAX_TANK_TEMP_LOC) && Sdata[T1TOP_LOC].temp > GetEEact(MAX_TANK_TEMP_LOC))
                MaxTankTemp1 = MaxTankTempMin;
        }
    }

    if(UseTank1 == true)
    {
        DispUseTank = "Tank1 ";
        TurnOnTemp = Sdata[T1TOP_LOC].temp + TempDiff;
        if(Sdata[COLLECTOR_LOC].temp > TurnOnTemp)
        {
            TempDiff = GetEEact(TEMP_DIFF_MIN_LOC);
            if(Sdata[T1TOP_LOC].temp <= MaxTankTemp1)
            {
                ActiveZonePin = ZONE_WATER_TANK1_PIN;
                DumpFlag = false;
                MaxTankTemp1 = GetEEact(MAX_TANK_TEMP_LOC);
            }
            else
            {
                DumpFlag = true;
                DumpTemp = GetEEact(MAX_TANK_TEMP_LOC) + GetEEact(TEMP_DIFF_MAX_LOC);
                MaxTankTemp1 = MaxTankTempMin;
            }
        }
        else
            TempDiff = GetEEact(TEMP_DIFF_MAX_LOC);
    }

    if(UseTank2 == true)
    {
        DispUseTank = "Tank2 ";
        TurnOnTemp = Sdata[T2TOP_LOC].temp + TempDiff;
        if(Sdata[COLLECTOR_LOC].temp > TurnOnTemp)
        {
            TempDiff = GetEEact(TEMP_DIFF_MIN_LOC);
            if(Sdata[T2TOP_LOC].temp <= MaxTankTemp2)
            {
                ActiveZonePin = ZONE_WATER_TANK2_PIN;
                DumpFlag = false;
                MaxTankTemp2 = GetEEact(MAX_TANK_TEMP_LOC);
            }
            else
            {
                DumpFlag = true;
                DumpTemp = GetEEact(MAX_TANK_TEMP_LOC) + GetEEact(TEMP_DIFF_MAX_LOC);
                MaxTankTemp2 = MaxTankTempMin;
            }
        }
        else
            TempDiff = GetEEact(TEMP_DIFF_MAX_LOC);
    }
       

    if(UseTank1 == false && UseTank2 == false)
    {
        DispUseTank = "!Tank ";
        if(Sdata[COLLECTOR_LOC].temp > GetEEact(MAX_TANK_TEMP_LOC))
        {
           DumpTemp = GetEEact(MAX_TANK_TEMP_LOC);
           DumpFlag = true;;
        }
        else
          DumpFlag = false;
    }

    if((int)(hr*60)+min >= (int)(GetEEact(DUMP_TIME_HR_LOC)*60) + GetEEact(DUMP_TIME_MIN_LOC) && ActiveZonePin == 0)
    {
        DumpFlag = true;
        DumpTemp = 100;
        /* The idea is to start at a diff of 10 so most likely tank2 will be chosen */
        /* to start the day off. If it's a cloudy day then there is the chance we could */
        /* actually lose some heat inthe tank and best if it's from tank2. */
        Tank1Tank2Diff = 10; /* reset to 10 to get ready for the next day */
    }

    if(DumpFlag == true)
    {
        if(Sdata[COLLECTOR_LOC].temp >= DumpTemp)
        {
            if(HeatEnabled == true)
                ActiveZonePin = ZONE_HOUSE_PIN;
            else
                ActiveZonePin = ZONE_GARAGE_PIN;
        }
    }

    /* open and close the zone valves */
    /* elapsed_millis keeps count of the time this zone was open */
    /* it's incremented each time this func gets called. */
    /* The elapsed_millis get set to 0 when a ethernet request for data comes in. */
    /* Open zone valve */
    /* If one zone valve is closing and another is opening */
    if(PrevActiveZonePin > 0 && ActiveZonePin > 0 && PrevActiveZonePin != ActiveZonePin)
    {
        SendToSlave(PrevActiveZonePin, LOW);
        ss[FindSlaveIdx(PrevActiveZonePin)].elapsed_millis += millis() - prev_millis;
    }
    if(ActiveZonePin > 0)
    {
        if(TimedZonePin > 0 && TimedZonePin != ActiveZonePin)
            SendToSlave(TimedZonePin, LOW);
        SendToSlave(ActiveZonePin, HIGH);
        TimedZonePin = 0;
        DispActiveZone = ss[FindSlaveIdx(ActiveZonePin)].desc;
        if(PrevActiveZonePin == ActiveZonePin) /* if the zone valve just opened don't add millis */
            ss[FindSlaveIdx(ActiveZonePin)].elapsed_millis += millis() - prev_millis;
        ZoneValveEndSwitchTimer = GetEEact(END_SWTCH_SEC_LOC); /* counts down in OneSecTimer() */
    }
    else
        DispActiveZone = "      ";

    /* Zone valve is closing and no other valve is opening */
    if(PrevActiveZonePin > 0 && ActiveZonePin == 0)
    {
        ZoneTimerCnt = GetEEact(ZONE_OFF_TIMER_LOC); /* counts down in OneSecTimer(); keep open for 30 min */
        TimedZonePin = PrevActiveZonePin;
        ss[FindSlaveIdx(PrevActiveZonePin)].elapsed_millis += millis() - prev_millis;
    }
    if(TimedZonePin > 0 && ZoneTimerCnt == 0)
    {
        SendToSlave(TimedZonePin, LOW);
        TimedZonePin = 0;
    }
    
    /* Turn the pump on or off here based on the zone valves. */
    if(ActiveZonePin > 0)
    {
        if(ZoneValveEndSwitch == HIGH || ZoneValveEndSwitchTimer == 0)
        {
            SendToSlave(PUMP_PIN, HIGH);
            if(ActiveZonePin == PrevActiveZonePin || PrevActiveZonePin > 0)
               ss[FindSlaveIdx(PUMP_PIN)].elapsed_millis += millis() - prev_millis;
        }
    }
    else
    {
        SendToSlave(PUMP_PIN, LOW);
        if(PrevActiveZonePin > 0 && ActiveZonePin == 0)
            ss[FindSlaveIdx(PUMP_PIN)].elapsed_millis += millis() - prev_millis;
    }
        
    if(ActiveZonePin == ZONE_GARAGE_PIN )
    {
        SendToSlave(PUMP_GARAGE_PIN, HIGH);
        if(ActiveZonePin == PrevActiveZonePin)
               ss[FindSlaveIdx(PUMP_GARAGE_PIN)].elapsed_millis += millis() - prev_millis;
    }
    else
    {
        SendToSlave(PUMP_GARAGE_PIN, LOW);
        if(PrevActiveZonePin == PUMP_GARAGE_PIN)
            ss[FindSlaveIdx(PUMP_GARAGE_PIN)].elapsed_millis += millis() - prev_millis;
    }

    /* If end switch(es) are open (zone valve closed) and a zone is active */
    /* (valve should be open) and the Timer has counted down to 0 - */
    /* then there is a problem. A zone valve either did not open or */
    /* the zone valve end switch failed. */
    if(ZoneValveEndSwitch == LOW && ActiveZonePin > 0 && ZoneValveEndSwitchTimer == 0)
    {
        ErrorFlag = true;
        ErrorString = "ZoneValveFailed";
    }

    prev_millis = millis();
}  /* end of function */

/* Check if collector is too hot. Indicates a malfunction somewhere. */
/* Turn everything off and set flag. On next iteration check flag and */
/* open all valves and turn on all pumps. */
/* This will continue until flag is reset. */
void CheckTooHot()
{
    if(Sdata[COLLECTOR_LOC].temp >= (GetEEact(MAX_TANK_TEMP_LOC) + GetEEact(TEMP_DIFF_MAX_LOC) + 15))
    {
        if(CollectorTooHotFlag == false)
        {
            SendToSlave(PUMP_PIN, LOW);
            SendToSlave(PUMP_GARAGE_PIN, LOW);
            SendToSlave(ZONE_WATER_TANK1_PIN, LOW);
            SendToSlave(ZONE_WATER_TANK2_PIN, LOW);
            SendToSlave(ZONE_HOUSE_PIN, LOW);
            SendToSlave(ZONE_GARAGE_PIN, LOW);
            CollectorTooHotFlag = true;
            ErrorFlag = true;
            ErrorString = "CollectorTooHot";
        }
        else
        {
            SendToSlave(PUMP_PIN, HIGH);
            SendToSlave(PUMP_GARAGE_PIN, HIGH);
            SendToSlave(ZONE_WATER_TANK1_PIN, HIGH);
            SendToSlave(ZONE_WATER_TANK2_PIN, HIGH);
            SendToSlave(ZONE_HOUSE_PIN, HIGH);
            SendToSlave(ZONE_GARAGE_PIN, HIGH);
        }
    }
    else
       CollectorTooHotFlag = false;
}
