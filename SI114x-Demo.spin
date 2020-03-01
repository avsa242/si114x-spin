{
    --------------------------------------------
    Filename: SI114x-Demo.spin
    Author: Jesse Burt
    Description: Demo of the Si114x driver
    Copyright (c) 2020
    Started Feb 29, 2020
    Updated Mar 1, 2020
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

    TEXT_COL    = 0
    DATA_COL    = TEXT_COL+30
    BOOL        = 1
    BIN         = 2
    DEC         = 10
    HEX         = 16

OBJ

    cfg     : "core.con.boardcfg.flip"
    io      : "io"
    int     : "string.integer"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    si      : "sensor.light.si114x.i2c"

VAR

    byte _ser_cog, _si_cog, _row

PUB Main | opmode, tmp, uvi

    Setup

    si.Reset
    si.UVCoefficients(1, $00_01_6B_7B)
    si.AUXChan(FALSE)
    si.UVChan(TRUE)
    si.IRChan(FALSE)
    si.VisibleChan(FALSE)

    si.IRRange(si#HIGH)
    si.VisibleRange(si#HIGH)

    si.IRGain(1)                                        ' 1, 16, 64, 128 (gain factor)
    si.VisibleGain(1)                                   ' 1, 16, 64, 128 (gain factor)
    si.MeasureRate(8000)                                ' 31..2047969 (uSec delay between measurements)
    tmp := si.OpMode(si#CONT_PSALS)
                                                        ' ONE_PS, ONE_ALS, ONE_PSALS
                                                        ' CONT_PS, CONT_ALS, CONT_PSALS
                                                        ' ONE = One-shot measurement mode
                                                        ' CONT = Continuous measurement mode
                                                        ' PS = Proximity Sensor
                                                        ' ALS = Ambient Light Sensor

    Datum(3, string("Measure rate delay:"), si.MeasureRate(-2), 10, 0, string("uS"))

    repeat
        _row := 6
        case opmode := si.OpMode(-2)
            si#ONE_PS, si#ONE_ALS, si#ONE_PSALS:        ' One-shot mode
                si.OpMode(opmode)

            si#CONT_PS, si#CONT_ALS, si#CONT_PSALS, si#PAUSE_PS, si#PAUSE_ALS, si#PAUSE_PSALS:
                                                        ' Continuous-measurement mode
            OTHER:                                      ' Exception - should never reach this state
                ser.Position(TEXT_COL, 20)
                ser.str(string("Exception error: unable to determine sensor operation mode - halting"))
                Stop
                FlashLED(LED, 500)

        Datum(_row++, string("Status: "), si.Status, BIN, 3, 0)
        Datum(_row++, string("UV: "), uvi := si.UVData, HEX, 4, 0)
        Datum(_row++, string("IR: "), si.IRData, HEX, 4, 0)
        Datum(_row++, string("Visible: "), si.VisibleData, HEX, 4, 0)
        Datum(_row++, string("IR overflow?: "), si.IROverflow, BOOL, 0, 0)
        Datum(_row++, string("Visible overflow?: "), si.VisibleOverflow, BOOL, 0, 0)

        ser.Position(TEXT_COL, _row+=2)
        ser.Str(string("UV Index: "))
        ser.Position(DATA_COL, _row)
        Frac(uvi, 100)

    FlashLED (LED, 100)

PUB Datum(ypos, ptr_msg, data, data_base, digits, ptr_unit)
' Display annotated data
'   ypos: Terminal y-position/row to display data
'   ptr_msg: Pointer to annotation string
'   data: Datum to display
'   data_base: Number base used to display data (BIN/2, DEC/10, HEX/16)
'   digits: Number of digits used to display data
'   ptr_unit: Optional pointer to unit or other string text to postfix to row (e.g., uS). 0 to disable
    ser.Position(TEXT_COL, ypos)
    ser.Str(ptr_msg)

    ser.Position(DATA_COL, ypos)
    case data_base
        BOOL:
            case data
                0:
                    ser.str(string("FALSE"))
                OTHER:
                    ser.str(string("TRUE "))
        BIN:
            ser.Bin(data, digits)
        DEC:
            ser.Str(int.DecPadded(data, digits))
        HEX:
            ser.Hex(data, digits)
    if ptr_unit
        ser.str(ptr_unit)

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
    part := int.DecZeroed(||(scaled // divisor), places)

    ser.Dec (whole)
    ser.Char (".")
    ser.Str (part)

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
    if _si_cog := si.Startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.Str(string("SI114x driver started (Si11"))
        ser.Hex (si.DeviceID, 2)
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
