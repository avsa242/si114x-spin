{
----------------------------------------------------------------------------------------------------
    Filename:       SI114x-UVIndexDemo.spin
    Description:    Demo of the Si114x driver
        * Display UV index
    Author:         Jesse Burt
    Started:        Jul 5, 2022
    Updated:        Nov 17, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    sensor: "sensor.light.si114x" | SCL=28, SDA=29, I2C_FREQ=100_000
    time:   "time"


PUB main()

    setup()

    sensor.preset_uvi()                         ' set up the sensor for UV-Index measurements
    sensor.als_data_rate(5_000)

    repeat
        repeat until sensor.als_data_rdy()
        ser.pos_xy(0, 3)
        ser.printf(@"UV Index: %2.2d.%02.2d", (sensor.uv_data() / 100), (sensor.uv_data() // 100))


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"SI114x driver started")
    else
        ser.strln(@"SI114x driver failed to start - halting")
        repeat


DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

