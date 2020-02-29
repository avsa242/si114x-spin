{
    --------------------------------------------
    Filename: SI114x-Test.spin
    Author: Jesse Burt
    Description: Test of the Si114x driver
    Copyright (c) 2020
    Started Jun 01, 2019
    Updated Feb 29, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 400_000

OBJ

    cfg     : "core.con.boardcfg.flip"
    io      : "io"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    si      : "sensor.light.si114x.i2c"

VAR

    byte _ser_cog, _si_cog

PUB Main | tmp

    Setup

    repeat tmp from 0 to 5
        ser.Hex (si.CalData (tmp), 4)
        ser.Char (" ")

    ser.NewLine
    si.ReadCalData
    
    repeat tmp from 0 to 5
        ser.Hex (si.CalData (tmp), 4)
        ser.Char (" ")

    Stop
    FlashLED (LED, 100)

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
    if _si_cog := si.Startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.Str(string("SI114x driver started (Si11"))
        ser.Hex (si.PartID, 2)
        ser.Str (string(" rev "))
        ser.Hex (si.RevID, 2)
        ser.Str (string(", sequencer rev "))
        ser.Hex (si.SeqID, 2)
        ser.Str (string(" found)", ser#CR, ser#LF))
    else
        ser.Str(string("SI114x driver failed to start - halting", ser#CR, ser#LF))
        Stop
        FlashLED (LED, 500)

PUB Stop

    time.MSleep (5)
    ser.Stop
    si.Stop

#include "lib.utility.spin"

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
