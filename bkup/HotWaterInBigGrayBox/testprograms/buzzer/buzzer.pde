

int buzzPin = 9;      // LED connected to digital pin 9
byte dutycycle;

void setup()
{
    pinMode(buzzPin, OUTPUT);
}

void loop()
{
    static unsigned long prev_millis = 0ul;
    
    if(millis() - prev_millis >= 500)
    {
        if(dutycycle == 0)
            dutycycle = 125;
        else
            dutycycle = 0;
        prev_millis = millis();
    }
    analogWrite(buzzPin, dutycycle); /* 0 - 255 */
}

