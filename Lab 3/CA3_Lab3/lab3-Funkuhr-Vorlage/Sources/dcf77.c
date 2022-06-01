/*  Radio signal clock - DCF77 Module

    Computerarchitektur 3
    (C) 2018 J. Friedrich, W. Zimmermann Hochschule Esslingen

    Author:   W.Zimmermann, Jun  10, 2016
    Modified: -
*/

/*
; A C H T U N G:  D I E S E  S O F T W A R E  I S T  U N V O L L S T Ä N D I G
; Dieses Modul enthält nur Funktionsrahmen, die von Ihnen ausprogrammiert werden
; sollen.
*/

#ifndef _HCS12_SERIALMON
  #ifndef SIMULATOR 
    #define SIMULATOR 1
  #endif
#endif


#include <hidef.h>                                      // Common defines
#include <mc9s12dp256.h>                                // CPU specific defines
#include <stdio.h>

#include "dcf77.h"
#include "led.h"
#include "clock.h"
#include "lcd.h"

// Global variable holding the last DCF77 event
DCF77EVENT dcf77Event = NODCF77EVENT;

// Modul internal global variables
static int  dYear=0, dMonth=0, dWeekday=0, dDay=0; 
static char dHour=0, dMinute=0;                //dcf77 Date and time as integer values
static int  timeSignalLow=0, timeFallingEdge=0;
static char statePrevSignal=0, bitStateD = -1, parityBit = 0;

// Prototypes of functions simulation DCF77 signals, when testing without
// a DCF77 radio signal receiver
#ifdef SIMULATOR
    void initializePortSim(void);                   // Use instead of initializePort() for testing
    char readPortSim(void);                         // Use instead of readPort() for testing
#else
    void initializePort(void);
    char readPort(void);
#endif
// ****************************************************************************
// Initalize the hardware port on which the DCF77 signal is connected as input
// Parameter:   -
// Returns:     -
void initializePort(void)
{
    DDRH = 0; 
}

// ****************************************************************************
// Read the hardware port on which the DCF77 signal is connected as input
// Parameter:   -
// Returns:     0 if signal is Low, >0 if signal is High
char readPort(void)
{
    if((PTH&1) == 0){
    //direkt hier leds steuern, die zweite die signal anzeigt von dcf77
        return 0;  
    } else{
    //dann clearen
        return 1;  
    }
}

// ****************************************************************************
//  Initialize DCF77 module
//  Called once before using the module
void initDCF77(void)
{   setClock((char) dHour, (char) dMinute, 0);
    displayDate();

    initializePort();
}



// ****************************************************************************
//  Read and evaluate DCF77 signal and detect events
//  Must be called by user every 10ms
//  Parameter:  Current CPU time base in milliseconds
//  Returns:    DCF77 event, i.e. second pulse, 0 or 1 data bit or minute marker

DCF77EVENT sampleSignalDCF77(int currentTime)
{   DCF77EVENT e = NODCF77EVENT;
                                        
    if((readPortSim()) != statePrevSignal){                     //  No-Edge      
    static int timeOfLastSignal;
    if(currentTime - timeOfLastSignal <= 3000)
    {                                                                 //  No-Edge
        if((readPort()) != statePrevSignal)
        {                          
            int tempTime;                                            //  Positive-Edge
            if(statePrevSignal == 0)
            {                               
                clrLED(0x02);
                tempTime = currentTime - timeSignalLow;
                statePrevSignal = 1;
                if((tempTime >= 70) && (tempTime <= 130)){
                   //  Low for  70-130ms
                    e = VALIDZERO;                   
                } 
                else if((tempTime >= 170) && (tempTime <= 230)){  
                    //  Low for 170-230ms
                    e = VALIDONE;  
                } 
                else{
                    //  Low for any other timeperiod
                    e = INVALID;
                }
            } 
            else{                                                       //  Negative-Edge
                setLED(0x02);
                tempTime = currentTime - timeFallingEdge;
                statePrevSignal = 0;
                if((tempTime >= 900) && (tempTime <= 1100)){
                    // Last falling edge was 900-1100ms ago
                    e = VALIDSECOND;
                } 
                else if((tempTime >= 1900) && (tempTime <= 2100)){
                    // Last falling edge was 1900-2100ms ago
                    e = VALIDMINUTE;
                } 
                else{
                    // Last falling edge was any other timeperiod ago
                    e = INVALID;
                }
               
                timeSignalLow = timeFallingEdge = currentTime;
            }
         timeOfLastSignal = currentTime;   
        } 
    }
    else 
    {   // Longer than 3sec no SignalEdge
        e = INVALID;    
    }
   return e;
}

}

// ****************************************************************************
// Process the DCF77 events
// Contains the DCF77 state machine
// Parameter:   Result of sampleSignalDCF77 as parameter
// Returns:     -
void processEventsDCF77(DCF77EVENT e){
      if(e == VALIDMINUTE){

        if(bitStateD >0){
            setClock(dHour, dMinute, 0);
            setDate(dYear, dMonth, dWeekday, dDay);
            setLED(0x08);
        }

        bitStateD = 0;
        clrLED(0x04); 
      }
      else if(bitStateD >= 0){          // Waiting for signal start (VALIDMINUTE)
        if(e == VALIDSECOND){
            bitStateD++;          
        } 
        else if(e == INVALID){
            bitStateD = -1;
            setLED(0x04);
            clrLED(0x08);
        } 
    else{
          
      switch(bitStateD){
      //default für die ersten case fälle 
        if (bitStateD >=0 && bitStateD<19)    {
        }
        case 0:
        case 17:  
        case 18: 
        case 19: break; 
        case 20: //always 1 byte
             if(e == VALIDZERO){
             bitStateD = -1;
             setLED(0x04);               
             clrLED(0x08);
             }
            parityBit = 0;
            dMinute = 0;
            break;
        //Minuten
        case 21:
            if(e == VALIDONE){ 
            dMinute+=1;
            parityBit++; 
            }
            break; 
        case 22:
            if(e == VALIDONE){ 
            dMinute+=2;
            parityBit++; 
            }
            break; 
        case 23:
            if(e == VALIDONE){ 
            dMinute+=4;
            parityBit++; 
            }
            break;
         
        case 24:
            if(e == VALIDONE){ 
            dMinute+=8;
            parityBit++; 
            }
            break; 
        case 25:
            if(e == VALIDONE){     
            dMinute+=10;
            parityBit++; 
            }
            break; 
        case 26:
            if(e == VALIDONE){ 
            dMinute+=20;
            parityBit++; 
             }
            break; 
        case 27:
            if(e == VALIDONE){ 
            dMinute+=40;
            parityBit++; 
            }
            break; 
        case 28:
            if(((e == VALIDONE) && ((parityBit%2) == 0)) || ((e == VALIDZERO) && ((parityBit%2) == 1))){
                bitStateD = -1;
                setLED(0x04);
                clrLED(0x08);  
            } 
 
            else if ((dMinute < 0) || (dMinute > 59)){
                bitStateD = -1;
                setLED(0x04);
                clrLED(0x08);
            } else{
            }
            parityBit = 0;
            dHour = 0;
            break; 
        //hours
        case 29:
            if(e == VALIDONE){

            dHour+=1;
            parityBit++; 
            }
            break; ; 
        case 30:
            if(e == VALIDONE){

            dHour+=2;
            parityBit++; 
            }
            break;  
        case 31:
            if(e == VALIDONE){
            dHour+=4;
            parityBit++; 
            }
            break;  
        case 32:
            if(e == VALIDONE){

            dHour+=8;
            parityBit++; 
            }
            break;  
        case 33:
            if(e == VALIDONE){

            dHour+=10;
            parityBit++; 
            }
            break; 
        case 34:
            if(e == VALIDONE){

            dHour+=20;
            parityBit++; 
            }
            break; 
        case 35:
           if(((e == VALIDONE) && ((parityBit%2) == 0)) || ((e == VALIDZERO) && ((parityBit%2) == 1))){
                bitStateD = -1;
                setLED(0x04);
                clrLED(0x08);  
            } 
            else if((dHour < 0) || (dHour > 23)){
                bitStateD = -1;
                setLED(0x04);
                clrLED(0x08);
            }
            else{
            }
            parityBit = 0;
            dDay = 0;
            dWeekday = 0;
            dMonth = 0;
            dYear = 0;
            break;
         
        //days
        case 36:
         if(e == VALIDONE){
            dDay+=1;
            parityBit++; 
            break;  
         }
        case 37:
           if(e == VALIDONE){
            dDay+=2;
            parityBit++; 
            break; 
           }
        case 38:
             if(e == VALIDONE){
            dDay+=4;
            parityBit++; 
             }
            break; 
             
        case 39:
             if(e == VALIDONE){
            dDay+=8;
            parityBit++; 
             }
            break;
        case 40:
        if(e == VALIDONE){
            dDay+=10;
            parityBit++; 
        }
            break; 
        case 41:
        if(e == VALIDONE){
            dDay+=20;
            parityBit++; 
        if((dDay < 0) || (dDay > 31)){
             bitStateD= -1;
             setLED(0x04);
             clrLED(0x08);
        }
            
        break;
        //weekday
        case 42:
        if(e == VALIDONE){
            dWeekday+=1;
            parityBit++; 
        }break; 
        case 43:
         if(e == VALIDONE){
            dWeekday+=2;
            parityBit++; 
         }break; 
        case 44:
          if(e == VALIDONE){
            dWeekday+=4;
            parityBit++; 
          }break; 
        //month
        case 45:
           if(e == VALIDONE){
            dMonth+=1;
            parityBit++; 
           }break; 
        case 46:
            if(e == VALIDONE){
            dWeekday+=2;
            parityBit++; 
            }break;  
        case 47:
        if(e == VALIDONE){
            dWeekday+=4;
            parityBit++; 
        }break; 
        case 48:
         if(e == VALIDONE){
            dWeekday+=8;
            parityBit++; 
         }break; 
         
        case 49:
         if(e == VALIDONE){
            dWeekday+=10;
            parityBit++; 
         }
         if((dMonth < 0) || (dMonth > 12)){
              bitStateD = -1;
              setLED(0x04);
              clrLED(0x08);
          } 
         break; 
        //year
        case 50:
        if(e == VALIDONE){
            dYear+=1;
            parityBit++; 
        }break;  
        case 51:
        if(e == VALIDONE){
            dYear+=2;
            parityBit++; 
        }break; 
        case 52:
        if(e == VALIDONE){
            dYear+=4;
            parityBit++; 
        }break; 
        case 53:
         if(e == VALIDONE){
            dYear+=8;
            parityBit++; 
         }break;  
        case 54:
          if(e == VALIDONE){
            dYear+=10;
            parityBit++; 
            }break;  
        case 55:
            if(e == VALIDONE){
            dYear+=20;
            parityBit++; 
            }break; 
        case 56:
            if(e == VALIDONE){
            dYear+=40;
            parityBit++; 
            }break;  
        case 57:      
            if(e == VALIDONE){
            dYear+=80;
            parityBit++; 
            }break; 
        case 58:
        if(((e == VALIDONE) && ((parityBit%2) == 0)) || ((e == VALIDZERO) && ((parityBit%2) == 1))){
                      bitStateD = -1;                     
                      setLED(0x04);
                      clrLED(0x08);  
                  } 
                  else if((dYear < 0) || (dYear > 99)){
                      bitStateD = -1;
                      setLED(0x04);
                      clrLED(0x08);
                  } else{
                      dYear += 2000; 
                  }
                  parityBit= 0;
                  break;
              

                }
            }
      }
  }   
}