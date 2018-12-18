/* CalcHotWater.pde 2/2010 rbh */
/* This function gets called when startflg is true. */
/* When a temp reading is complete from loop(). */

void CalcHotWater()
{
    byte    MaxTankTempMin, PumpPin, PumpGaragePin, dumphr;
    static byte MaxTankTemp1 = 0, MaxTankTemp2 = 0;
    static byte Tank1Tank2Diff = 10;
    static byte StiebelTemp = STIEBEL_TEMP_START;
    static byte TempDiff = 0;
    float    TankTempAvg1, TankTempAvg2;
    boolean  UseTank1, UseTank2;
    byte offset, num_items;
    struct output *outptr;

    /****** init variables ******/
    UseTank1 = (boolean)GetEEact(USE_TANK1_LOC);
    UseTank2 = (boolean)GetEEact(USE_TANK2_LOC);
    DumpFlag = false;
    PumpPin = 0;
    PumpGaragePin = 0;
    ActiveZonePin = 0;

    if(MaxTankTemp1 == 0) /* first time in func */
    {
        MaxTankTemp1 = GetEEact(MAX_TANK_TEMP_LOC);
        MaxTankTemp2 = MaxTankTemp1;
    }
    MaxTankTempMin = GetEEact(MAX_TANK_TEMP_LOC) - 2;
    if(TempDiff == 0)
        TempDiff = GetEEact(TEMP_DIFF_MAX_LOC);
    TankTempAvg1 = (TSdata[T1TOP_LOC].avgtemp+TSdata[T1BOT_LOC].avgtemp)/2;
    TankTempAvg2 = (TSdata[T2TOP_LOC].avgtemp+TSdata[T2BOT_LOC].avgtemp)/2;
    /* ************************* */
    if(TSdata[T1TOP_LOC].avgtemp < StiebelTemp)
    {
       StiebelTemp = STIEBEL_TEMP_START + 1;
       CurrStatus.Stiebel.state = 1;
    }
    else
    {
       StiebelTemp = STIEBEL_TEMP_START;
       CurrStatus.Stiebel.state = 0;
    }
    /* Heating the house */
    if(GetEEact(WTR1HS2GG3_LOC) == 2)
    {
        UseTank1 = false;
        UseTank2 = false;
        ActiveZonePin = HOUSE_PIN;
        TurnOnTemp = 140;
        if(TSdata[COLLECTOR_LOC].avgtemp > TurnOnTemp)
        {
            TempDiff = GetEEact(TEMP_DIFF_MIN_LOC);
            PumpPin = PUMP_PIN;
            DumpFlag = false;
        }
        else
        {
            PumpPin = 0;
            TempDiff = GetEEact(TEMP_DIFF_MAX_LOC);
        }
    }
    /* Heat the garage */
    if(GetEEact(WTR1HS2GG3_LOC) == 3)
    {
        UseTank1 = false;
        UseTank2 = false;
        ActiveZonePin = GARAGE_PIN;
        TurnOnTemp = 140;
        if(TSdata[COLLECTOR_LOC].avgtemp > TurnOnTemp)
        {
            TempDiff = GetEEact(TEMP_DIFF_MIN_LOC);
            PumpPin = PUMP_PIN;
            DumpFlag = false;
        }
        else
        {
            PumpPin = 0;
            TempDiff = GetEEact(TEMP_DIFF_MAX_LOC);
        }
    }
    /* Tank1 has priority over Tank2. Bring each tank up to MaxTankTemp and */
    /* when both are up to temp then send hot glycol to either the house */
    /* radiator or the garage. At the end of the day dump hot glycol to house */
    /* radiator or garage. */
    /* Usually by the morning the avg temps between the two tanks are far */
    /* apart. Therefore setting Tank1Tank2Diff to the lower (10) before */
    /* morning startup will cause the follwong code to pick to start with */
    /* Tank2. If it turns out to be a cloudy day it's possible to lose a */
    /* little heat in the tank and it's best to lose from tank2 as tank1 */
    /* feeds the house. */
    if(UseTank1 == true && UseTank2 == true)
    {
        if(TSdata[T1TOP_LOC].avgtemp <= MaxTankTemp1 && TankTempAvg1-TankTempAvg2 <= Tank1Tank2Diff)
        {
            UseTank2 = false;
            Tank1Tank2Diff = 20;
        }
        else
        {
            UseTank1 = false;
            Tank1Tank2Diff = 10;
            /* Set lower level of hysteresis here for tank1 because it does */
            /* not get set in the if UseTank1 section below when both tanks */
            /* are InUse. */
            if(MaxTankTemp1 == GetEEact(MAX_TANK_TEMP_LOC) && TSdata[T1TOP_LOC].avgtemp > GetEEact(MAX_TANK_TEMP_LOC))
                MaxTankTemp1 = MaxTankTempMin;
        }
    }

    if(UseTank1 == true)
    {
        ActiveZonePin = TANK1_PIN;
        TurnOnTemp = TSdata[T1TOP_LOC].avgtemp + TempDiff;
        if(TSdata[COLLECTOR_LOC].avgtemp > TurnOnTemp)
        {
            TempDiff = GetEEact(TEMP_DIFF_MIN_LOC);
            if(TSdata[T1TOP_LOC].avgtemp <= MaxTankTemp1)
            {
                PumpPin = PUMP_PIN;
                DumpFlag = false;
                MaxTankTemp1 = GetEEact(MAX_TANK_TEMP_LOC);
            }
            else
            {
                DumpFlag = true;
                PumpPin = 0;
                TurnOnTemp = GetEEact(MAX_TANK_TEMP_LOC) + GetEEact(TEMP_DIFF_MAX_LOC);
                MaxTankTemp1 = MaxTankTempMin;
            }
        }
        else
        {
            PumpPin = 0;
            TempDiff = GetEEact(TEMP_DIFF_MAX_LOC);
        }
    }

    if(UseTank2 == true)
    {
        ActiveZonePin = TANK2_PIN;
        TurnOnTemp = TSdata[T2TOP_LOC].avgtemp + TempDiff;
        if(TSdata[COLLECTOR_LOC].avgtemp > TurnOnTemp)
        {
            TempDiff = GetEEact(TEMP_DIFF_MIN_LOC);
            if(TSdata[T2TOP_LOC].avgtemp <= MaxTankTemp2)
            {
                PumpPin = PUMP_PIN;
                DumpFlag = false;
                MaxTankTemp2 = GetEEact(MAX_TANK_TEMP_LOC);
            }
            else
            {
                PumpPin = 0;
                DumpFlag = true;
                TurnOnTemp = GetEEact(MAX_TANK_TEMP_LOC) + GetEEact(TEMP_DIFF_MAX_LOC);
                MaxTankTemp2 = MaxTankTempMin;
            }
        }
        else
        {
            PumpPin = 0;
            TempDiff = GetEEact(TEMP_DIFF_MAX_LOC);
        }
    }

    if(UseTank1 == false && UseTank2 == false && GetEEact(WTR1HS2GG3_LOC) == 1)
    {
        if(TSdata[COLLECTOR_LOC].avgtemp > GetEEact(MAX_TANK_TEMP_LOC))
        {
           TurnOnTemp = GetEEact(MAX_TANK_TEMP_LOC);
           DumpFlag = true;;
        }
        else
           DumpFlag = false;
    }

    /* Start the dump 1 hr earlier than the param setting if heat is enabled. */
    /* This is because DST and the clock gets updated each day */
    /* If dump time is set to 16:15 then dump at 15:15. The sun does not */
    /* shine on the collectors after about 3PM during the winter. */

    dumphr = GetEEact(DUMP_TIME_HR_LOC);
    if(HeatEnabled && dumphr > 0)
        dumphr--;
    if((int)(hwtime.hour*60)+hwtime.min >= (int)(dumphr*60) + GetEEact(DUMP_TIME_MIN_LOC) && 
            PumpPin == 0 && UnixTimeIsGood) //GetEEact(NTP_TIME_FLAG_LOC) )
    {
        DumpFlag = true;
        TurnOnTemp = TSdata[AMBIENT_LOC].avgtemp;
        
        if(HeatEnabled == false)
            TurnOnTemp += 10.0;
            
        Tank1Tank2Diff = 10;
        /* The first time in here set diff to 10 and then the next time this */
        /* func is called it may chose to heat tank2 for a few minutes before */
        /* it dumps. The idea is to start at a diff of 10 so most likely */
        /* tank2 will be chosen to start the day off. If it's a cloudy day */
        /* then there is the chance we could actually lose some heat in the */
        /* tank and best if it's from tank2. Reset to 10 to get ready for the */
        /* next day. */
    }

    if(DumpFlag == true)
    {
        if(HeatEnabled == true)
            ActiveZonePin = HOUSE_PIN;
        else
            ActiveZonePin = GARAGE_PIN;

        if(TSdata[COLLECTOR_LOC].avgtemp >= TurnOnTemp)
        {
            PumpPin = PUMP_PIN;
            if(ActiveZonePin == GARAGE_PIN)
                PumpGaragePin = PUMP_GARAGE_PIN;
        }
        else
        {
            PumpPin = 0;
            PumpGaragePin = 0;
        }
    }
    /* if Collector is so cold the anti freeze might freeze then */
    /* take warmer water from the garage */
    /* The number stored in FREEZE EEPROM is the number of degrees */
    /* below freezing F */
    if(TSdata[COLLECTOR_LOC].avgtemp <= (float)(32-GetEEact(FREEZE_LOC)))
    {
        ActiveZonePin = GARAGE_PIN;
        PumpPin = PUMP_PIN;
        PumpGaragePin = PUMP_GARAGE_PIN;
    }

    num_items = sizeof(struct stat)/sizeof(struct output);
    /* Skip over the manual setting(0) and Stiebel (last one)*/
    /* Update the CurrStatus struct */
    for(offset = 1; offset < num_items-1; offset++)
    {
        outptr = (struct output *)&CurrStatus + offset;
        if(outptr->pin == ActiveZonePin)
        {
            if(PumpPin == PUMP_PIN)
            {
                if(outptr->state == 0)
                    ZoneValveEndSwitchTimer = GetEEact(END_SWTCH_SEC_LOC);
                outptr->state = 1;
                if(ZoneValveEndSwitch == false && ZoneValveEndSwitchTimer==0)
                {
                    AddMsg("ZoneValve", "Failed");
                    BeepState = true;
                }
            }
            else
                if(ZoneTimerCnt == 0)
                    outptr->state = 0;
            AddMsg("ActiveZone", outptr->desc);
            continue;
        }

        if(outptr->pin == PUMP_PIN)
        {
            if( PumpPin > 0 && (ZoneValveEndSwitch == true || ZoneValveEndSwitchTimer ==0) )
            {
                ZoneTimerCnt = GetEEact(ZONE_OFF_TIMER_LOC);
                outptr->state = 1;
            }
            else
            {
                //if(outptr->state == 1)
                 //   ZoneTimerCnt = GetEEact(ZONE_OFF_TIMER_LOC);
                outptr->state = 0;
            }
            continue;
        }
        if(outptr->pin == PUMP_GARAGE_PIN)
        {
            if(PumpGaragePin > 0 && (ZoneValveEndSwitch == true || ZoneValveEndSwitchTimer ==0) )
                outptr->state = 1;
            else
                outptr->state = 0;
            continue;
        }
        /* If we get here then turn it off */
        outptr->state = 0;
    }
}

/* Check if collector is too hot. Indicates a malfunction somewhere. */
/* Set flag. Set timer for 10 seconds. When the timer goes to 0 */
/* and the situation has not corrected itself then */
/* open all valves and turn on all pumps. */
/* This will continue until flag is reset. */
void CheckTooHot()
{
    byte offset, num_items;
    struct output *outptr;
    
    num_items = sizeof(struct stat)/sizeof(struct output);
    
    if(TSdata[COLLECTOR_LOC].avgtemp >= (GetEEact(MAX_TANK_TEMP_LOC) + GetEEact(TEMP_DIFF_MAX_LOC) + 15))
    {
        /* On afternoons sometimes the end of the collector with the sensor  */
        /* gets shaded. So when the pump turns on the hotter glycol gets to */
        /* the sensor and can set off the collector too hot flag. So wait 10  */
        /* seconds and check again. */
        if(CollectorTooHotFlag == false)
        {
            ZoneTimerCnt = 0;
            CollectorTooHotFlag = true;
            CollectorTooHotTimer = 10; /* Counts down in timer func() */
        }
        else
        {
            if(CollectorTooHotTimer == 0)
            {
                AddMsg("Collector", "Too Hot");
                BuzzerState = true;
                for(offset = 1; offset < num_items-1; offset++)
                {
                    outptr = (struct output *)&CurrStatus + offset;
                    outptr->state = 1;
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
            for(offset = 1; offset < num_items-1; offset++)
            {
                outptr = (struct output *)&CurrStatus + offset;
                outptr->state = 0;
            }
            CollectorTooHotFlag = false;
        }
    }
}
