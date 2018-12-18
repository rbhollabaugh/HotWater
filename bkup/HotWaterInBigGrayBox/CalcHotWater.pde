/* CalcHotWater.pde */

/* This function gets called when startflg is true (when a temp reading is complete) from loop(). */
void CalcHotWater()
{
    byte     MaxTankTempMin, ActiveZonePin, dumphr;
    static byte PrevActiveZonePin=0, TimedZonePin = 0, Tank1Tank2Diff = 10;
    static byte StiebelTemp = STIEBEL_TEMP_START;
    float    TankTempAvg1, TankTempAvg2;
    boolean  UseTank1, UseTank2;

    /****** init variables ******/
    UseTank1 = (boolean)GetEEact(USE_TANK1_LOC);
    UseTank2 = (boolean)GetEEact(USE_TANK2_LOC);
    DumpFlag = false;
    ActiveZonePin = 0;
 
    MaxTankTempMin = GetEEact(MAX_TANK_TEMP_LOC) - 2;
    TankTempAvg1 = (TSdata[T1TOP_LOC].temp+TSdata[T1BOT_LOC].temp)/2;
    TankTempAvg2 = (TSdata[T2TOP_LOC].temp+TSdata[T2BOT_LOC].temp)/2;
    /* ************************* */
    if(TSdata[T1TOP_LOC].temp < StiebelTemp)
    {
       StiebelTemp = STIEBEL_TEMP_START + 1;
       SendToSlave(ZONE_STIEBEL_PIN, HIGH);
    }
    else
    {
       StiebelTemp = STIEBEL_TEMP_START;
       SendToSlave(ZONE_STIEBEL_PIN, LOW);
    }
    /* Heating the house */
    if(GetEEact(WTR1HS2GG3_LOC) == 2)
    {
        UseTank1 = false;
        UseTank2 = false;
        DispEnabledZone = ss[FindSlaveIdx(ZONE_HOUSE_PIN)].desc;
        TurnOnTemp = 130 + TempDiff;
        if(TSdata[COLLECTOR_LOC].temp > TurnOnTemp)
        {
            TempDiff = GetEEact(TEMP_DIFF_MIN_LOC);
            ActiveZonePin = ZONE_HOUSE_PIN;
            DumpFlag = false;
        }
        else
            TempDiff = GetEEact(TEMP_DIFF_MAX_LOC);
    }
    if(GetEEact(WTR1HS2GG3_LOC) == 3)
    {
        UseTank1 = false;
        UseTank2 = false;
        DispEnabledZone = ss[FindSlaveIdx(ZONE_GARAGE_PIN)].desc;
        TurnOnTemp = 130 + TempDiff;
        if(TSdata[COLLECTOR_LOC].temp > TurnOnTemp)
        {
            TempDiff = GetEEact(TEMP_DIFF_MIN_LOC);
            ActiveZonePin = ZONE_GARAGE_PIN;
            DumpFlag = false;
        }
        else
            TempDiff = GetEEact(TEMP_DIFF_MAX_LOC);
    }
    /* Tank1 has priority over Tank2. Bring each tank up to MaxTankTemp and */
    /* when both are up to temp then send hot glycol to either the house */
    /* radiator or the garage. At the end of the day dump hot glycol to house */
    /* radiator or garage. */
    /* Usually by the morning the avg temps between the two tanks are far apart */
    /* Therefore setting Tank1Tank2Diff to the lower (10) before morning startup */
    /* will cause the follwong code to pick to start with Tank2. If it turns out to */
    /* be a cloudy day it's possible to lose a little heat in the tank and it's best */
    /* to lose from tank2 as tank1 feeds the house. */
    if(UseTank1 == true && UseTank2 == true)
    {
        if(TSdata[T1TOP_LOC].temp <= MaxTankTemp1 && TankTempAvg1-TankTempAvg2 <= Tank1Tank2Diff)
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
            if(MaxTankTemp1 == GetEEact(MAX_TANK_TEMP_LOC) && TSdata[T1TOP_LOC].temp > GetEEact(MAX_TANK_TEMP_LOC))
                MaxTankTemp1 = MaxTankTempMin;
        }
    }

    if(UseTank1 == true)
    {
        DispEnabledZone = ss[FindSlaveIdx(ZONE_WATER_TANK1_PIN)].desc;
        TurnOnTemp = TSdata[T1TOP_LOC].temp + TempDiff;
        if(TSdata[COLLECTOR_LOC].temp > TurnOnTemp)
        {
            TempDiff = GetEEact(TEMP_DIFF_MIN_LOC);
            if(TSdata[T1TOP_LOC].temp <= MaxTankTemp1)
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
        DispEnabledZone = ss[FindSlaveIdx(ZONE_WATER_TANK2_PIN)].desc;
        TurnOnTemp = TSdata[T2TOP_LOC].temp + TempDiff;
        if(TSdata[COLLECTOR_LOC].temp > TurnOnTemp)
        {
            TempDiff = GetEEact(TEMP_DIFF_MIN_LOC);
            if(TSdata[T2TOP_LOC].temp <= MaxTankTemp2)
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
       

    if(UseTank1 == false && UseTank2 == false && GetEEact(WTR1HS2GG3_LOC) == 1)
    {
        DispEnabledZone = "!Tank ";
        if(TSdata[COLLECTOR_LOC].temp > GetEEact(MAX_TANK_TEMP_LOC))
        {
           DumpTemp = GetEEact(MAX_TANK_TEMP_LOC);
           DumpFlag = true;;
        }
        else
           DumpFlag = false;
    }

    /* Start the dump 1 hr earlier than the param setting if heat is enabled. */
    /* This is because DST and the clock gets updated each day */
    /* If dump time is set to 16:15 then dump at 15:15. The sun does not shines on */
    /* the collectors after about 3PM during the winter. */
    dumphr = GetEEact(DUMP_TIME_HR_LOC);
    if(HeatEnabled && dumphr > 0)
        dumphr--;
    if((int)(hr*60)+min >= (int)(dumphr*60) + GetEEact(DUMP_TIME_MIN_LOC) && ActiveZonePin == 0)
    {
        DumpFlag = true;
        DumpTemp = 100;
        Tank1Tank2Diff = 10;
        /* The first time in here set diff to 10 and then the next time this func is called */
        /* it may chose to heat tank2 for a few minutes before it dumps */
        /* The idea is to start at a diff of 10 so most likely tank2 will be chosen */
        /* to start the day off. If it's a cloudy day then there is the chance we could */
        /* actually lose some heat in the tank and best if it's from tank2. */
        /* reset to 10 to get ready for the next day */
    }

    if(DumpFlag == true)
    {
        if(TSdata[COLLECTOR_LOC].temp >= DumpTemp)
        {
            if(HeatEnabled == true)
                ActiveZonePin = ZONE_HOUSE_PIN;
            else
                ActiveZonePin = ZONE_GARAGE_PIN;
        }
    }
    /* if Collector is so cold the anti freese might freeze then */
    /* take warmer water from the garage */
    /* The number stored in FREEZE EEPROM is the number of degrees */
    /* below freezing F */
    if(TSdata[COLLECTOR_LOC].temp <= (float)(32-GetEEact(FREEZE_LOC)))
    {
        DispEnabledZone = ss[FindSlaveIdx(ZONE_GARAGE_PIN)].desc;
        ActiveZonePin = ZONE_GARAGE_PIN;
    }

    /* Zone valve is off and no other valve is opening */
    if(PrevActiveZonePin > 0 && ActiveZonePin == 0)
    {
        byte ssidx;
        
        ssidx = FindSlaveIdx(PrevActiveZonePin);
        ZoneTimerCnt = GetEEact(ZONE_OFF_TIMER_LOC); /* counts down in OneSecTimer(); keep open for 30 min */
        TimedZonePin = PrevActiveZonePin;
        /* This elapsed time stuff gets done in the SendToSlave() function but */
        /* need to keep this valve open but finish the elapsed timing for now */
        ss[ssidx].elapsed_millis += millis() - ss[ssidx].start_millis;
        ss[ssidx].start_millis = millis();
    }
    if(TimedZonePin > 0 && ZoneTimerCnt == 0)
    {
        SendToSlave(TimedZonePin, LOW);
        TimedZonePin = 0;
    }
    if(ActiveZonePin > 0 || TimedZonePin > 0 || ss[FindSlaveIdx(ZONE_STIEBEL_PIN)].state == HIGH)
        SendToSlave(TRANSFORMER_PIN, HIGH);
    else
        SendToSlave(TRANSFORMER_PIN, LOW);
        
    /* open and close the zone valves */
    /* If one zone valve is closing and another is opening */
    if(PrevActiveZonePin > 0 && ActiveZonePin > 0 && PrevActiveZonePin != ActiveZonePin)
        SendToSlave(PrevActiveZonePin, LOW);
    if(ActiveZonePin > 0)
    {
        if(TimedZonePin > 0 && TimedZonePin != ActiveZonePin)
            SendToSlave(TimedZonePin, LOW);
        TimedZonePin = 0;
        ZoneTimerCnt = 0;
        /* The elapsed time stuff gets done in SendToSlave() but here we have */
        /* to reset the period start millis in case the timed zone re-starts */
        if(ActiveZonePin == TimedZonePin)
            ss[FindSlaveIdx(ActiveZonePin)].start_millis = millis();
        SendToSlave(ActiveZonePin, HIGH);
        DispActiveZone = ss[FindSlaveIdx(ActiveZonePin)].desc;
        if(PrevActiveZonePin != ActiveZonePin)
            ZoneValveEndSwitchTimer = GetEEact(END_SWTCH_SEC_LOC); /* counts down in OneSecTimer() */
    }
    else
        DispActiveZone = Space6;

    /* Turn the pump on or off here based on the zone valves. */
    if(ActiveZonePin > 0)
    {
        if(ZoneValveEndSwitch == HIGH || ZoneValveEndSwitchTimer == 0)
            SendToSlave(PUMP_PIN, HIGH);
        else /* added else 1/20/2011 to turn pump off when 1 zone valve is closing and another is opening */
            SendToSlave(PUMP_PIN, LOW);
    }
    else
        SendToSlave(PUMP_PIN, LOW);
        
    if(ActiveZonePin == ZONE_GARAGE_PIN )
        SendToSlave(PUMP_GARAGE_PIN, HIGH);
    else
        SendToSlave(PUMP_GARAGE_PIN, LOW);

    /* If end switch(es) are open (zone valve closed) and a zone is active */
    /* (valve should be open) and the Timer has counted down to 0 - */
    /* then there is a problem. A zone valve either did not open or */
    /* the zone valve end switch failed. */
    /* In case the xformer did not turn on try turning it off and back on. */
    if(ZoneValveEndSwitch == LOW && ActiveZonePin > 0 && ZoneValveEndSwitchTimer == 0)
    {
        SendToSlave(TRANSFORMER_PIN, LOW);
        ZoneValveEndSwitchTimer = GetEEact(END_SWTCH_SEC_LOC); /* counts down in OneSecTimer() */
        ErrorString = "ZoneValv";
    }
        
    PrevActiveZonePin = ActiveZonePin;
}  /* end of function */

/* Check if collector is too hot. Indicates a malfunction somewhere. */
/* Set flag. Set timer for 10 seconds. When the timer goes to 0 */
/* and the situation has not corrected itself then */
/* open all valves and turn on all pumps. */
/* This will continue until flag is reset. */
void CheckTooHot()
{
    byte x;
    
    if(TSdata[COLLECTOR_LOC].temp >= (GetEEact(MAX_TANK_TEMP_LOC) + GetEEact(TEMP_DIFF_MAX_LOC) + 15))
    {
        /* On afternoons sometimes the end of the collector with the sensor gets shaded */
        /* So when the pump turns on the hotter glycol gets to the sensor and can set off */
        /* the collector too hot flag. So wait 10 seconds annd check again. */
        if(CollectorTooHotFlag == false)
        {
            ZoneTimerCnt = 0;
            CollectorTooHotFlag = true;
            CollectorTooHotTimer = 10; /* set to 10 seconds. Counts down in timer func() */
        }
        else
        {
            if(CollectorTooHotTimer == 0)
            {
                ErrorString = "TooHot";
                for(x=0; x<NUM_SLAVE_PINS; x++)
                {
                    if(ss[x].pin == BUZZER_PIN)
                        continue;
                    SendToSlave(ss[x].pin, HIGH);
                }
            }
        }
    }
    else
    {
        /* if flag was set but now collector temp is lower */
        /* turn everything off and CalcHotWater() should take over */
        if(CollectorTooHotFlag)
        {
            for(x=0; x<NUM_SLAVE_PINS; x++)
            {
                if(ss[x].pin == BUZZER_PIN)
                    continue;
                SendToSlave(ss[x].pin, LOW);
            }
            CollectorTooHotFlag = false;
        }
    }
}
