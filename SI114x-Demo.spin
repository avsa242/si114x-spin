{
    --------------------------------------------
    Filename: SI114x-Demo.spin
    Author: Jesse Burt
    Description: Demo of the Si114x driver
    Copyright (c) 2020
    Started Feb 29, 2020
    Updated Nov 20, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 1_000_000                     ' max is 3_400_000
' --

    TEXT_COL    = 0
    DATA_COL    = TEXT_COL+30

    ROW         = 10

    R           = si#R                          ' read/write constants
    W           = si#W                          ' for UVCoefficients()

OBJ

    cfg     : "core.con.boardcfg.flip"
    int     : "string.integer"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    si      : "sensor.light.si114x.i2c"

PUB Main{}

    setup{}

    si.presetuvi{}

    repeat
        uvcalc{}

PUB UVCalc{} | uvi

    uvi := si.uvdata{}

    ser.position(TEXT_COL, ROW)
    ser.str(string("UV Index: "))
    ser.position(DATA_COL, ROW)
    decimal(uvi, 100)

PUB Decimal(scaled, divisor) | whole[4], part[4], places, tmp
' Display a fixed-point scaled up number in decimal-dot notation - scale it back down by divisor
'   e.g., Decimal (314159, 100000) would display 3.14159 on the termainl
'   scaled: Fixed-point scaled up number
'   divisor: Divide scaled-up number by this amount
    whole := scaled / divisor
    tmp := divisor
    places := 0

    repeat
        tmp /= 10
        places++
    until tmp == 1
    part := int.deczeroed(||(scaled // divisor), places)

    ser.dec(whole)
    ser.char(".")
    ser.str(part)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if si.startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.str(string("SI114x driver started (Si11"))
        ser.hex(si.deviceid{}, 2)
        ser.str(string(" rev "))
        ser.hex(si.revid{}, 2)
        ser.str(string(", sequencer rev "))
        ser.hex(si.seqid{}, 2)
        ser.strln(string(" found)"))
    else
        ser.strln(string("SI114x driver failed to start - halting"))
        time.MSleep (5)
        ser.Stop
        si.Stop

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
