{
    --------------------------------------------
    Filename: SI114x-Test.spin
    Author: Jesse Burt
    Description: Test for the Si114x driver
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
    si      : "sensor.prox_uv_amblight.si114x.i2c"

VAR

    byte _ser_cog, _si_cog

PUB Main | tmp

    Setup

    
    si.VisibleChan (FALSE)
    tmp := si.IRChan (-2)
    ser.Hex (tmp, 8)
    ser.NewLine

    tmp := si.IRChan (TRUE)
    ser.Hex (tmp, 8)
    ser.NewLine

    tmp := si.IRChan (-2)
    ser.Hex (tmp, 8)
    ser.NewLine

    repeat
        tmp := si.command ( %000_00110, 0, 0)
    
        ser.Position (0, 6)
        ser.Hex ( si.VisibleLight, 8)
        ser.NewLine
        ser.Hex ( si.IRLight, 8)
        time.MSleep (250)
    Stop
    Flash (LED, 100)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if _si_cog := si.Start
        ser.Str(string("SI114x driver started (Si11"))
        ser.Hex (si.PartID, 2)
        ser.Str (string(" rev "))
        ser.Hex (si.RevID, 2)
        ser.Str (string(", sequencer rev "))
        ser.Hex (si.SeqID, 2)
        ser.Str (string(" found)", ser#NL))
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
