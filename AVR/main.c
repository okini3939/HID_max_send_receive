/* Teensy RawHID example
 * http://www.pjrc.com/teensy/rawhid.html
 * Copyright (c) 2009 PJRC.COM, LLC
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above description, website URL and copyright notice and this permission
 * notice shall be included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


/*
	Easy code for testing only .. test to maximum byte send to MCU from MCU..

	this sample code use 1472bytes flash and 68bytes ram.


*/
/*
 * ATmega32U4 16MHz
 * EXTENDED = 0xCB
 * HIGH = 0xD8
 * LOW = 0xFF
 */


#include <avr/io.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>
#include <util/delay.h>

#include "usb_rawhid.h"


void xputc (char c) {
	while (!(UCSR1A & _BV(UDRE1)));
	UDR1 = c;
}

char xgetc () {
	if (!(UCSR1A & _BV(RXC1))) {
		return 0;
	}
	return UDR1;
}

void initUart () {
	UCSR1A = _BV(U2X1);                         // importantly U2X1 = 0
	UCSR1C = _BV(UCSZ11) | _BV(UCSZ10); // no parity, 8 data bits, 1 stop bit
	UBRR1  = 16;    // 115200bps
	UCSR1B = _BV(RXEN1)|_BV(TXEN1);                         // interrupts enabled in here if you like
	xputc('H');
	xputc('e');
	xputc('l');
	xputc('l');
	xputc('o');
	xputc('\r');
	xputc('\n');
}


int main(void)
{

	DDRC |= (1<<7); // led

	initUart();
	sei();

	SU = 0;

	// Initialize the USB, and then wait for the host to set configuration.
	// If the Teensy is powered without a PC connected to the USB port,
	// this will wait forever.
	usb_init();
	while (!usb_configured()) /* wait */ ;

	// Wait an extra second for the PC's operating system to load drivers
	// and do whatever it does to actually be ready for input
	_delay_ms(500);

	int i;
	char c;
	while (1) {
		if (usb_configured()) {
			PORTC |= (1<<7); // led on
		} else {
			PORTC &= ~(1<<7); // led off
		}

		c = xgetc();
		if (c) {
			PORTC &= ~(1<<7); // led off
			for (i = 0; i < RAWHID_TX_SIZE; i++) {
				buffer[i]= c + (i & 0x1f);
			}
			usb_rawhid_send(buffer, 8); // send buffer 8 - timeout..
		}

		if (SU) {
			PORTC &= ~(1<<7); // led off
			SU = 0;
			for (i = 0; i < RAWHID_TX_SIZE; i ++) {
				if (buffer[i] == 0) break;
				xputc(buffer[i]);
				buffer[i] = buffer[i] + 1;
			}
			usb_rawhid_send(buffer, 8); // send buffer 8 - timeout..
		}
	}
}



 
