/*  Lab 2 - Main C file for Clock program

    Computerarchitektur 3
    (C) 2018 J. Friedrich, W. Zimmermann
    Hochschule Esslingen

    Author:  W.Zimmermann, July 19, 2017
*/

#include <hidef.h>                              // Common defines
#include <mc9s12dp256.h>                        // CPU specific defines

#pragma LINK_INFO DERIVATIVE "mc9s12dp256b"


// PLEASE NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!:
// Files lcd.asm and ticker.asm do contain SOFTWARE BUGS. Please overwrite them
// with the lcd.asm file, which you bug fixed in lab 1, and with file ticker.asm
// which you bug fixed in prep task 2.1 of this lab 2.
//
// To use decToASCII you must insert file decToASCII from the first lab into
// this project
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


// ****************************************************************************
// Function prototype(s)
// Note: Only void Fcn(void) assembler functions can be called from C directly.
//       For non-void functions a C wrapper function is required.

void initTicker(void);
void initLED(void);
void initClock(void);
void tickClock(void);
void timeToString(void);
void secsAdd(void);
void minsAdd(void);
void hrsAdd(void);
void initThermo(void) ;
void updateTemp(void);
void toggleMode(void);

// Prototypes and wrapper functions for dec2ASCII (from lab 1)
void decToASCII(void);

void decToASCII_Wrapper(char *txt, int val)
{   asm
    {  	
        LDX txt
        LDD val
        JSR decToASCII
    }
}

// Prototypes and wrapper functions for LCD driver (from lab 1)
void initLCD(void);
void writeLine(void);

void WriteLine_Wrapper(char *text, char line)
{   asm
    {	
        LDX  text
        LDAB line
        JSR  writeLine
    }
}


// ****************************************************************************         

// ****************************************************************************

void initLED_C(void)
{   DDRJ_DDRJ1  = 1;	  	// Port J.1 as output
    PTIJ_PTIJ1  = 0;		
    DDRB        = 0xFF;		// Port B as output
    PORTB       = 0x55;
}

// ****************************************************************************

#define DEBOUNCE_TIME 37500  // 200ms / 5,3333us

// Global variables
unsigned char clockEvent = 0;
unsigned char tenSecCounter = 0;
unsigned char counter = 0; 

// Set/Normal mode
extern char setMode;

// Buttons
unsigned int  btn2;
unsigned int  btn3;
unsigned int  btn4;
unsigned int  btn5;

// ****************************************************************************

void main(void) 
{   EnableInterrupts;                           // Global interrupt enable

    initLED_C();                    		        // Initialize the LEDs
    initLCD();                    	  	        // Initialize the LCD
    initClock();
    initThermo();
    DDRH = 0x00;                                // Port H as inputs

    WriteLine_Wrapper("@ IT SS22", 0);
    WriteLine_Wrapper("Initialisation...", 1);    

    initTicker();                               // Initialize the time ticker

    for(;;)                                     // Endless loop
    {
        if(clockEvent){
            if(PTH == 0x04){        
              btn2 = DEBOUNCE_TIME + TCNT;
              toggleMode();
            }
                        
            if(setMode){
              if(PTH == 0x08){                // Button 3 betätigt
                 btn3 = DEBOUNCE_TIME + TCNT;
                 secsAdd();
                 timeToString();
              } else if(PTH == 0x10){         // Button 4 betätigt
                 btn4 = DEBOUNCE_TIME + TCNT;
                 minsAdd();
                 timeToString();
              } else if(PTH == 0x20){         // Button 5 betätigt
                 btn5 = DEBOUNCE_TIME + TCNT;
                 hrsAdd();
                 timeToString();
              }
              PORTB = 0x80;              
            }
            
            clockEvent = 0;
            
            if(!setMode){
          	  tickClock();
        	  }

        	  updateTemp();
        	  counter++; 
        	  if(counter >= 20){
          	   counter=0; 
          	   WriteLine_Wrapper("@ IT SS22", 0);
        	  } else if (counter >= 10){
        	     WriteLine_Wrapper("Fesko und Moritz", 0);
        	  }
        } 
    }     
}


