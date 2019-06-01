{
    --------------------------------------------
    Filename: SI1145-Test.spin
    Author:
    Description:
    Copyright (c) 2019
    Started Jun 01, 2019
    Updated Jun 01, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    si      : "sensor.prox_uv_amblight.si1145.i2c"

VAR

    byte _ser_cog, _si_cog

PUB Main

    Setup
    ser.Hex (si.PartID, 8)
    ser.NewLine

    ser.Hex (si.RevID, 8)
    ser.NewLine

    ser.Hex (si.SeqID, 8)
    ser.NewLine
    Stop
    Flash (LED, 100)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if _si_cog := si.Start
        ser.Str(string("SI114x driver started", ser#NL))
    else
        ser.Str(string("SI114x driver failed to start - halting", ser#NL))
        Stop
        Flash (LED, 500)

PUB Stop

    time.MSleep (5)
    ser.Stop
    si.Stop

PUB Flash(pin, delay_ms)

    dira[pin] := 1
    repeat
        !outa[pin]
        time.MSleep (delay_ms)

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
