
int LedPin1 = 2;
int LedPin2 = 20;
int SwPin = 21;

void setup()
{
    pinMode(LedPin1, OUTPUT);
    pinMode(LedPin2, OUTPUT);
    pinMode(SwPin, INPUT);
    digitalWrite(SwPin, HIGH);
}

void loop()
{
    static unsigned long prev_millis = 0ul;
    static boolean state = LOW;
    
    if(millis() - prev_millis >= 500)
    {
        if(state == LOW)
            state = HIGH;
        else
            state = LOW;
        prev_millis = millis();
    }
    digitalWrite(LedPin1, state);
    digitalWrite(LedPin2, digitalRead(SwPin));
}

