
/* display strings for LCD */
char    *Line0 = "?x00?y0";
char    *Line1 = "?x00?y1";
char    *Line2 = "?x00?y2";
char    *Line3 = "?x00?y3";
char    *Line0Clr = "?x00?y0?l";
char    *Line1Clr = "?x00?y1?l";
char    *Line2Clr = "?x00?y2?l";
char    *Line3Clr = "?x00?y3?l";
char    *Saved = "Saved";
char    *ClrScr = "?f";
char    *BkLtHalf = "?B30";
char    colon = ':';
char    Zero = '0';

void setup()
{
    
    Serial.begin(9600);
    delay(100);
    Serial.print(ClrScr);
    Serial.print("?*");   /*Display boot screen */
    
    //Serial.print(BkLtHalf);    // backlight on
    delay(100);
    Serial.print("?c0");    // turn cursor off
    delay(2000);            /* 2 seconds is less than the 5 seconds in the */
                            /* master so the slave is ready to accept cmds */
    Serial.print(ClrScr);    // clear the LCD
    delay(100);
}

void loop()
{
    static int x=0;

    Serial.print(Line0Clr);
    Serial.print(x++);

    delay(500);
}
