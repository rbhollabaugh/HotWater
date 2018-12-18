
// Demonstrates use of the Wire library
// Writes data to an I2C/TWI slave device

#include <Wire.h>

int ledPin = 13;
int flag;

void setup()
{
    pinMode(ledPin, OUTPUT);
    flag = 0;
  Wire.begin(); // join i2c bus (address optional for master)
}

byte x = 0;

void loop()
{
  Wire.beginTransmission(1); // transmit to device #4
  Wire.send("Receiver 1 ");        // sends five bytes
  Wire.send(x);              // sends one byte  
  Wire.endTransmission();    // stop transmitting
  
  Wire.beginTransmission(2); // transmit to device #4
  Wire.send("Receiver 2 ");        // sends five bytes
  Wire.send(x);              // sends one byte  
  Wire.endTransmission();    // stop transmitting
  
  if(flag == 1)
        flag = 0;
    else
        flag = 1;
    digitalWrite(ledPin, flag);

  x++;
  delay(1000);
}
