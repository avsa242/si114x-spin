{
    --------------------------------------------
    Filename: sensor.light.si114x.i2c.spin
    Author: Jesse Burt
    Description: Driver for the Silicon Labs Si114[5|6|7] series
        Proximity/UV/Amblient light sensor IC
    Copyright (c) 2020
    Started Jun 01, 2019
    Updated Nov 21, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR                = core#SLAVE_ADDR
    SLAVE_RD                = core#SLAVE_ADDR|1

    DEF_SCL                 = 28
    DEF_SDA                 = 29
    DEF_HZ                  = 100_000
    I2C_MAX_FREQ            = core#I2C_MAX_FREQ

' Chip status
    SLEEP                   = core#CHIP_STAT_SLEEP
    SUSP                    = core#CHIP_STAT_SUSPEND
    RUN                     = core#CHIP_STAT_RUNNING

' Operation modes
    ONE_PS                  = core#CMD_PS_FORCE
    ONE_ALS                 = core#CMD_ALS_FORCE
    ONE_PSALS               = core#CMD_PSALS_FORCE
    CONT_PS                 = core#CMD_PS_AUTO
    CONT_ALS                = core#CMD_ALS_AUTO
    CONT_PSALS              = core#CMD_PSALS_AUTO
    PAUSE_PS                = core#CMD_PS_PAUSE
    PAUSE_ALS               = core#CMD_ALS_PAUSE
    PAUSE_PSALS             = core#CMD_PSALS_PAUSE

' Visible/IR sensor measurement range
    NORMAL                  = $00
    HIGH                    = $20

' Read/write for UVCoeffecients()
    R                       = 0
    W                       = 1

VAR

    word _cal_data[6]
    byte _opmode

OBJ

    i2c : "com.i2c"
    core: "core.con.si114x.spin"
    time: "time"

PUB Null{}
' This is not a top-level object

PUB Start{}: okay
' Start using "standard" Propeller I2C pins, 100kHz
    okay := startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay
' Start using custom I2C pins and bus frequency
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx(SCL_PIN, SDA_PIN, I2C_HZ)
                time.msleep(25)
                if i2c.present(SLAVE_WR)        ' check device bus presence
                    if lookdown(deviceid{}: core#PART_ID_RESP_1145,{
                    } core#PART_ID_RESP_1146, core#PART_ID_RESP_1147)
                        reset{}
                        return okay

    return FALSE                                ' something above failed

PUB Stop{}

    i2c.terminate{}

PUB Defaults{}
' Factory default settings
    reset{}

PUB PresetALS{}
' Preset settings for ambient light sension mode
    reset{}                                     ' start with POR defaults
    opmode(CONT_ALS)

    auxchan(FALSE)
    uvchan(FALSE)
    irchan(TRUE)
    visiblechan(TRUE)

PUB PresetProx{}
' Preset settings for proximity sensor mode
    reset{}
    opmode(CONT_PS)

    ' XXX fill in

PUB PresetUVI{}
' Preset settings for measuring UV Index
    reset{}
    opmode(CONT_ALS)

    ' These are the factory default part-to-part variance coefficients.
    ' They are restored by calling Reset(), but show them here so the user
    '   doesn't have to look far for them.
    uvcoefficients(W, $00_01_6B_7B)

    auxchan(FALSE)
    uvchan(TRUE)
    irchan(FALSE)
    visiblechan(FALSE)

    irrange(HIGH)
    visiblerange(HIGH)

    irgain(1)
    visiblegain(1)

PUB AUXChan(state): curr_state
' Enable the auxiliary source data channel
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := command(core#CMD_PARAM_QUERY, core#CHLIST, 0)
    case ||(state)
        0, 1:
            state := ||(state) << core#EN_AUX
        other:
            return ((curr_state >> core#EN_AUX) & %1) == 1

    state := ((curr_state & core#EN_AUX_MASK) | state) & core#CHLIST_MASK
    command(core#CMD_PARAM_SET, core#CHLIST, state)

PUB CalData(cal_word)
' Return a word of calibration data
'   Valid values: 0..5
'   Any other value is ignored
    case cal_word
        0..5:
            return _cal_data[cal_word]
        other:
            return

PUB DeviceID{}: id
' Part ID of sensor
'   Returns:
'       $45: Si1145
'       $46: Si1146
'       $47: Si1147
    readreg(core#PART_ID, 1, @id)

PUB IRChan(state): curr_state
' Enable the IR ambient light source data channel
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := command(core#CMD_PARAM_QUERY, core#CHLIST, 0)
    case ||(state)
        0, 1:
            state := ||(state) << core#EN_ALS_IR
        other:
            return ((curr_state >> core#EN_ALS_IR) & %1) == 1

    state := ((curr_state & core#EN_ALS_IR_MASK) | state) & core#CHLIST_MASK
    command (core#CMD_PARAM_SET, core#CHLIST, state)

PUB IRData{}: ir_adc
' Return data from infra-red light channel
    readreg (core#ALS_IR_DATA0, 2, @ir_adc)

PUB IRGain(gain): curr_gain
' Gain factor of infra-red light sensor
'   Valid values: 1, 16, 64, 128
'   Any other value polls the chip and returns the current setting
    curr_gain := 0
    curr_gain := command(core#CMD_PARAM_QUERY, core#ALS_IR_ADC_GAIN, 0)
    case gain
        1: gain := %000
        16: gain := %100
        64: gain := %110
        128: gain := %111
        other:
            return lookupz(curr_gain & core#ALS_IR_ADCGAIN_BITS: 1, 0, 0, 0,{
            } 16, 0, 64, 128)

    command(core#CMD_PARAM_SET, core#ALS_IR_ADCGAIN, gain)
    gain <<= core#IR_ADC_REC
    ' Set the one's complement of the gain val
    ' to ADC recovery period, per datasheet
    command(core#CMD_PARAM_SET, core#ALS_IR_ADC_COUNTER, !gain)

PUB IROverflow{}: flag
' Flag indicating infra-red light data conversion has overflowed
'   Returns: TRUE (-1) if overflowed, FALSE (0) otherwise
    readreg (core#RESPONSE, 1, @flag)
    return (flag == core#ALS_IR_ADC_OVERFLOW)

PUB IRRange(range): curr_rng
' Set measurement range of infra-red light sensor
'   Valid values:
'       NORMAL ($00): Normal signal range/high sensitivity
'       HIGH ($20): High signal range (gain divided by 14.5)
    curr_rng := command(core#CMD_PARAM_QUERY, core#ALS_IR_ADC_MISC, 0)
    case range
        NORMAL, HIGH:
        other:
            return curr_rng

    range &= core#ALS_IR_ADC_MISC_MASK
    command(core#CMD_PARAM_SET, core#ALS_IR_ADC_MISC, range)

PUB MeasureRate(rate): curr_rate
' Set time duration between measurements, in microseconds
'   Valid values: 31..2047969 (rounded to nearest multiple of 31.25)
'   Any other value polls the chip and returns the current setting
    curr_rate := $0000
    readreg(core#MEAS_RATE0, 2, @curr_rate)
    case rate
        31..2047969:                            ' 31.25uS..2047968.75uS
            rate *= 1_00                        ' Scaling, to preseve accuracy
            rate /= 31_25
        other:
            return (curr_rate * 31_25) / 100

    writereg(core#MEAS_RATE0, 2, @rate)

PUB OpMode(mode): curr_mode
' Set operation mode
'   Valid values:
'       ONE_PS, ONE_ALS, ONE_PSALS: Force a single PS, ALS or PS+ALS measurement
'       CONT_PS, CONT_ALS, CONT_PSALS: Start continuous PS, ALS, or PS+ALS measurement
'       PAUSE_PS, PAUSE_ALS, PAUSE_PSALS: Pause a running continuous measurement
'   Valid values return response status from chip
'   Any other value returns the last setting (shadow register)
    case mode
        ONE_PS, ONE_ALS, ONE_PSALS, CONT_PS, CONT_ALS, CONT_PSALS, PAUSE_PS,{
        } PAUSE_ALS, PAUSE_PSALS:
            _opmode := mode
        other:
            return _opmode                      ' not readable from sensor;
                                                ' keep a local copy

    command(mode, 0, 0)

PUB ReadCalData{}
' Read calibration data into 6-word array
    command(core#CMD_GET_CAL, 0, 0)
    readreg(core#CAL_DATA, 12, @_cal_data)

PUB Reset{}
' Perform soft-reset
    command(core#CMD_RESET, 0, 0)
    time.msleep(10)
    hwkey{}
    time.msleep(10)
    opmode(ONE_PSALS)

PUB RevID{}: id
' Revision
'   Returns: $00
    readreg(core#REV_ID, 1, @id)

PUB Running{}: flag
' Flag indicating device is running/awake
'   Returns: TRUE (-1) if device is awake, FALSE (0) otherwise
    readreg(core#CHIP_STAT, 1, @flag)
    return (flag == core#CHIP_STAT_RUNNING)

PUB SeqID{}: seq_rev
' Sequencer revision
'   Returns known values:
'       $08: Si114x-A10 (MAJOR_SEQ=1, MINOR_SEQ=0)
    readreg(core#SEQ_ID, 1, @seq_rev)

PUB Sleeping{}: flag
' Flag indicating device is sleeping
'   Returns:    TRUE (-1) if device is in its lowest power state
'               FALSE (0) otherwise
    readreg(core#CHIP_STAT, 1, @flag)
    return (flag == core#CHIP_STAT_SLEEP)

PUB Status{}: curr_stat
' Chip status
'   Returns:
'       RUN (%100): Device is awake
'       SUSP (%010): Device is in a low-power state, waiting for a measurement to complete
'       SLEEP (%001): Device is in its lowest power state
    readreg(core#CHIP_STAT, 1, @curr_stat)

PUB Suspended{}: flag
' Suspended status
'   Returns:    TRUE (-1) if device is in a low-power state,
'               FALSE (0) otherwise
    readreg(core#CHIP_STAT, 1, @flag)
    return (flag == core#CHIP_STAT_SUSPEND)

PUB UVChan(state): curr_state
' Enable the UV index source data channel
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := command(core#CMD_PARAM_QUERY, core#CHLIST, 0)
    case ||(state)
        0, 1:
            state := ||(state) << core#EN_UV
        other:
            return ((curr_state >> core#EN_UV) & %1) == 1

    state := ((curr_state & core#EN_UV_MASK) | state) & core#CHLIST_MASK
    command(core#CMD_PARAM_SET, core#CHLIST, state)

PUB UVCoefficients(rw, coeffs): curr_coeffs
' Set coefficients used to calculate UV index readings
'   Valid values:
'       rw: READ (0), WRITE (1)
'   NOTE: Four 8-bit coefficients are used, packed into long 'coeffs'
'       UCOEF3_UCOEF2_UCOEF1_UCOEF0
    curr_coeffs := 0
    readreg(core#UCOEF0, 4, @curr_coeffs)
    case rw
        0:                                      ' Read
            return
        1:                                      ' Write
            writereg(core#UCOEF0, 4, @coeffs)

PUB UVData{}: uv_adc
' Return data from UV index channel
    readreg(core#AUX_DATA0, 2, @uv_adc)

PUB VisibleChan(state): curr_state
' Enable the visible ambient light source data channel
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := command(core#CMD_PARAM_QUERY, core#CHLIST, 0)
    case ||(state)
        0, 1:
            state := ||(state) << core#EN_ALS_VIS
        other:
            return ((curr_state >> core#EN_ALS_VIS) & %1) == 1

    state := ((curr_state & core#EN_ALS_VIS_MASK) | state) & core#CHLIST_MASK
    command(core#CMD_PARAM_SET, core#CHLIST, state)

PUB VisibleData{}: vis_adc
' Return data from visible light channel
    readreg(core#ALS_VIS_DATA0, 2, @vis_adc)

PUB VisibleGain(gain): curr_gain
' Gain factor of visible light sensor
'   Valid values: 1, 16, 64, 128
'   Any other value polls the chip and returns the current setting
    curr_gain := $00
    curr_gain := command(core#CMD_PARAM_QUERY, core#ALS_VIS_ADC_GAIN, 0)
    case gain
        1: gain := %000
        16: gain := %100
        64: gain := %110
        128: gain := %111
        other:
            return lookupz(curr_gain & core#ALS_VIS_ADCGAIN_BITS: 1, 0, 0, 0,{
            } 16, 0, 64, 128)

    command(core#CMD_PARAM_SET, core#ALS_VIS_ADCGAIN, gain)
    gain <<= core#VIS_ADC_REC
    ' Set the one's complement of the gain val
    ' to ADC recovery period, per datasheet
    command(core#CMD_PARAM_SET, core#ALS_VIS_ADC_COUNTER, !gain)

PUB VisibleOverflow{}: flag
' Flag indicating visible light data conversion has overflowed
'   Returns: TRUE (-1) if overflowed, FALSE (0) otherwise
    readreg(core#RESPONSE, 1, @flag)
    return (flag == core#ALS_VIS_ADC_OVERFLOW)

PUB VisibleRange(range): curr_rng
' Set measurement range of visible light sensor
'   Valid values:
'       NORMAL ($00): Normal signal range/high sensitivity
'       HIGH ($20): High signal range (gain divided by 14.5)
    curr_rng := 0
    curr_rng := command(core#CMD_PARAM_QUERY, core#ALS_VIS_ADC_MISC, 0)
    case range
        NORMAL, HIGH:
        other:
            return curr_rng

    command(core#CMD_PARAM_SET, core#ALS_VIS_ADC_MISC, range)

PRI command(cmd, param, args): resp | tmp
' Send command with parameters to device
    case cmd
        core#CMD_PARAM_QUERY:
            cmd |= param
            tmp := core#CMD_NOP                 ' first check the device isn't
            writereg(core#COMMAND, 1, @tmp)     '   in an error state, since it
            readreg(core#RESPONSE, 1, @resp)    '   won't process any commands
            if resp == core#NO_ERROR            '   if so
                writereg(core#COMMAND, 1, @cmd)
            readreg(core#RESPONSE, 1, @resp)    ' XXX review logic from here past
'            if resp and not (resp & $80)
            readreg(core#PARAM_RD, 1, @resp)
            return

        core#CMD_PARAM_SET:
            cmd |= param
            tmp := core#CMD_NOP
            writereg(core#PARAM_WR, 1, @args)
            writereg(core#COMMAND, 1, @tmp)
            readreg(core#RESPONSE, 1, @resp)
            if resp == core#NO_ERROR
                writereg (core#COMMAND, 1, @cmd)
            readreg(core#RESPONSE, 1, @resp)
'            if resp and not (resp & $80)
            readreg(core#RESPONSE, 1, @resp)
            return

        core#CMD_NOP, core#CMD_RESET, core#CMD_BUSADDR, core#CMD_PS_FORCE,{
        } core#CMD_GET_CAL, core#CMD_ALS_FORCE, core#CMD_PSALS_FORCE,{
        } core#CMD_PS_PAUSE, core#CMD_ALS_PAUSE, core#CMD_PSALS_PAUSE,{
        } core#CMD_PS_AUTO, core#CMD_ALS_AUTO, core#CMD_PSALS_AUTO:
            tmp := core#CMD_NOP
            writereg(core#COMMAND, 1, @tmp)
            readreg(core#RESPONSE, 1, @resp)
            if resp == core#NO_ERROR
                writereg(core#COMMAND, 1, @cmd)
            readreg(core#RESPONSE, 1, @resp)
            return

PRI hwKey{} | tmp
' Writes $17 to HW_KEY reg (per the Si114x datasheet, this must be written for proper operation)
    tmp := core#HW_KEY_EXPECTED
    writereg(core#HW_KEY, 1, @tmp)

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' validate register
        $00..$04, $07..$09, $10, $13..$18, $20..$2E, $30:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr

            i2c.start{}
            i2c.wr_block(@cmd_pkt, 2)

            i2c.start{}
            i2c.write(SLAVE_RD)
            i2c.rd_block(ptr_buff, nr_bytes, TRUE)
            i2c.stop{}
        other:
            return

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Write nr_bytes from ptr_buff to the device
    case reg_nr
        $03, $04, $07, $08, $09, $0F, $10, $13..$18, $20..$2E:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr

            i2c.start{}
            i2c.wr_block(@cmd_pkt, 2)
            repeat tmp from 0 to nr_bytes-1
                i2c.write(byte[ptr_buff][tmp])
            i2c.stop{}

        other:
            return


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
