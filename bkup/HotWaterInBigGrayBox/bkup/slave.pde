/* slave.pde */

void InitSlavePins()
{
    SendToSlave(PUMP_PIN, LOW);
    SendToSlave(PUMP_GARAGE_PIN, LOW);
    SendToSlave(ZONE_WATER_TANK1_PIN, LOW);
    SendToSlave(ZONE_WATER_TANK2_PIN, LOW);
    SendToSlave(ZONE_HOUSE_PIN, LOW);
    SendToSlave(ZONE_GARAGE_PIN, LOW);
    SendToSlave(BUZZER_PIN, LOW);
}

/* Send a command to the slave arduino to turn a pin on or off. */
/* One way communication. */
/* Keep an array of structures to mirror the state of the pins */
/* for use here on the master. */
/* The data is in the format:  slave pin number : high or low */
/* InitSlavePin() must be called first to initialize the array. */

void SendToSlave(byte pin, boolean newstate)
{
    byte ssidx;

    ssidx = FindSlaveIdx(pin);

    /* No need to do anything more if the state has not changed. */
    if(ss[ssidx].state == newstate)
        return;
    ss[ssidx].state = newstate;
    Wire.beginTransmission(SLAVE_ADDRESS);
    Wire.send(pin);
    Wire.send(colon);
    Wire.send(newstate);
    Wire.endTransmission();
    /* Need at least 100msec delay between */
    /* sending data or the second communication */
    /* does not work. */
    /* If anything is going on at the slave then increase */
    /* the delay  or chars get lost. Min 50ms is nothing */
    /* running on the slave. */
    delay(150);
}

/* Find the slave pin in the ss array of slave pins. */
/* Return index into the array. */
/* If not found then set it. */

byte FindSlaveIdx(byte pin)
{
    byte x;
    boolean found=false;

    for(x=0; x<NUM_SLAVE_PINS && ss[x].pin; x++)
        if(ss[x].pin == pin)
        {
            found = true;
            break;
        }
    if(found == false)
    {
        ErrorFlag = true;
        ErrorString = "Pin not found";
    }
    return(x);
}
