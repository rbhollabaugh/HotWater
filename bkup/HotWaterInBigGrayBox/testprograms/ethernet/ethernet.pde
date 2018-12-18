#include <SPI.h>
#include <Ethernet.h>
#include "MemoryFree.h"

//#define WIZNETRESET_PIN 9
#define WIZNETRESET_PIN 24

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192, 168, 5, 40 };

Server server(80);

void setup()
{
    Serial.begin(9600);
    delay(100);
    Serial.print("?f");
    Serial.print("?*");      /* Display boot screen */

    Serial.print("?B30");    /* backlight on */
    delay(100);
    Serial.print("?c0");     /* turn cursor off */
    delay(1000);
    Serial.print("?f");      /* clear the LCD */
    Serial.print("?x00?y0");
    Serial.print("Ethernet Test");
    
    pinMode(WIZNETRESET_PIN, OUTPUT);
    digitalWrite(WIZNETRESET_PIN, LOW);
    delay(100);
    digitalWrite(WIZNETRESET_PIN, HIGH);
    delay(100);
    
    Ethernet.begin(mac, ip);
    server.begin();
}

void loop()
{
    char    *buf;
    boolean getflag = false, gettempsflag = false;
    byte  cnt = 0;
    int x = 0, freemem = 0;
    char c;
    
    Client client = server.available();
    if (client)
    {
        if(client.connected())
        {
            x=0;
            cnt = client.available();
            buf = (char*)calloc(cnt+1, sizeof(char));
            Serial.print("?x00?y3?l");
            Serial.print((int)cnt);
            Serial.print(" freemem=");
            Serial.print(freeMemory());
            for(x=0; x<cnt; x++)
            {
                buf[x] = client.read();
                client.print(buf[x]);
            }

            if(buf[0] == 'G' && buf[1] == 'E' && buf[2] == 'T')
                getflag = true;
            if(getflag && buf[4] == '/' && buf[5] == 't')
                gettempsflag = true;

            client.println("HTTP/1.1 200 OK");
            client.println("Content-Type: text/html");
            client.println();
            if(gettempsflag)
            {
                client.println("Temp Readings Here");
                client.println(freeMemory());
                client.println("<br />");
            }
            free(buf);
        }
        // give the web browser time to receive the data
        delay(1);
        client.stop();
    }
}
