

#include <Wire.h>

int ledPin = 13;
int flag;

void setup()
{
    pinMode(ledPin, OUTPUT);
    flag = 0;
  Wire.begin(1);                // join i2c bus with address #1
  Wire.onReceive(receiveEvent); // register event
  Serial.begin(9600);           // start serial for output
}

void loop()
{
  delay(100);
}

// function that executes whenever data is received from master
// this function is registered as an event, see setup()
void receiveEvent(int howMany)
{
    Serial.println(howMany);
    if(flag == 1)
        flag = 0;
    else
        flag = 1;
    digitalWrite(ledPin, flag);
  while(1 < Wire.available()) // loop through all but the last
  {
    char c = Wire.receive(); // receive byte as a character
    Serial.print(c);         // print the character
  }
  int x = Wire.receive();    // receive byte as an integer
  Serial.println(x);         // print the integer
}
