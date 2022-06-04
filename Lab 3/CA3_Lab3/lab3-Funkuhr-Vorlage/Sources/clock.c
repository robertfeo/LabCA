/*  Radio signal clock - Free running clock

    Computerarchitektur 3
    (C) 2018 J. Friedrich, W. Zimmermann Hochschule Esslingen

    Author:   W.Zimmermann, Jun  10, 2016
    Modified: -
*/

#include <stdio.h>

#include "clock.h"
#include "lcd.h"
#include "led.h"
#include "dcf77.h"

// Defines
#define ONESEC  (1000/10)                       // 10ms ticks per second
#define MSEC200 (200/10)

// Global variable holding the last clock event
CLOCKEVENT clockEvent = NOCLOCKEVENT;


// Modul internal global variables
static char TimeZoneActive = 0;
static char hrs = 0, mins = 0, secs = 0;
static int  year=2021, month=1, weekday=7, day=1;
static int ticks = 0;
static int uptime = 0;

// Modul internal global constants
const char days[8][4] = { "Err", "Mon", "Tue", "Wed", "Thr", "Fri", "Sat", "Sun" };
const char timeZone[2][3] = { "DE", "US" };


// ****************************************************************************
//  Initialize clock module
//  Called once before using the module
void initClock(void)
{   
    displayTimeClock();
}

// ****************************************************************************
// This function is called periodically every 10ms by the ticker interrupt.
// Keep processing short in this function, run time must not exceed 10ms!
// Callback function, never called by user directly.
void tick10ms(void)
{   
    if (++ticks >= ONESEC)                      // Check if one second has elapsed
    {   
        clockEvent = SECONDTICK;                // ... if yes, set clock event
        ticks=0;
        setLED(0x01);                           // ... and turn on LED on port B.0 for 200msec
    } 
    else if (ticks == MSEC200)
    {   
        clrLED(0x01);
    }
    uptime = uptime + 10;                       // Update CPU time base

    dcf77Event = sampleSignalDCF77(uptime);     // Sample the DCF77 signal

    //--- Add code here, which shall be executed every 10ms -------------------
    // ???
    //--- End of user code
}

// ****************************************************************************
// schaltet die Timezone um mit einem BTN3 Signal
// Parameter:   -
// Returns:     -.
void toggleTimeZone(void) 
{
    if(TimeZoneActive)
    {
        TimeZoneActive = 0;
    } 
    else
    {
        TimeZoneActive = 1;
    }
}
// ****************************************************************************
// Process the clock events
// This function is called every second and will update the internal time values.
// Parameter:   clock event, normally SECONDTICK
// Returns:     -
void processEventsClock(CLOCKEVENT event)
{   if (event==NOCLOCKEVENT)
        return;

    if (++secs >= 60)
    {   
        secs = 0;
        if (++mins >= 60)
        {   
            mins = 0;
            if (++hrs >= 24)
            {   
                hrs = 0;
            }
        }
     }
     //globale variable setzen displayEvent
}
// ****************************************************************************
// Allow other modules, e.g. DCF77, so set the date
// Parameters:  year, month, weekday, day as integers
// Returns:     -
void setDate(int years, int months, int weekdays, int days)
{   
    year = years;
    month = months;
    day = days;
    weekday = weekdays;
}

// ****************************************************************************
// Allow other modules, e.g. DCF77, so set the time
// Parameters:  hours, minutes, seconds as integers
// Returns:     -
void setClock(char hours, char minutes, char seconds)
{   
    hrs  = hours;
    mins = minutes;
    secs = seconds;
    ticks = 0;
}

// ****************************************************************************
// Display the time derived from the clock module on the LCD display, line 0
// Parameter:   -
// Returns:     -
void displayTimeClock(void)
{   
    char uhrzeit[32] = "00:00:00";
    char tempH = hrs;
    if(TimeZoneActive){
      if(hrs<6){          
        tempH=24-hrs-6;
      } else{
        tempH=hrs-6;
      }
    }

    (void) sprintf(uhrzeit, "%s: %02d:%02d:%02d", timeZone[TimeZoneActive], tempH, mins, secs );
    writeLine(uhrzeit, 0);
}

// ***************************************************************************
// This function is called to get the CPU time base
// Parameters:  -
// Returns:     CPU time base in milliseconds
int time(void)
{   
    return uptime;
}

// ****************************************************************************
// Display the date derived from the DCF77 signal on the LCD display, line 1
// Parameter:   -
// Returns:     -
void displayDate(void)
{   
    char datum[32];
    (void) sprintf(datum, "%s %02d.%02d.%04d", days[weekday], day, month, year);
    writeLine(datum, 1);
}