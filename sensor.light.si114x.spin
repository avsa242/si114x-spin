{
----------------------------------------------------------------------------------------------------
    Filename:       sensor.light.si114x.spin
    Description:    Driver for the Silicon Labs Si114[5|6|7] Proximity/UV/Amblient light sensor
    Author:         Jesse Burt
    Started:        Jun 1, 2019
    Updated:        Nov 26, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    { default I/O configuration - these can be overridden by the parent object }
    SCL             = 28
    SDA             = 29
    I2C_FREQ        = 100_000

    { Chip status }
    SLEEP           = core.CHIP_STAT_SLEEP
    SUSP            = core.CHIP_STAT_SUSPEND
    RUN             = core.CHIP_STAT_RUNNING

    { Operation modes }
    ONE_PS          = core.CMD_PS_FORCE
    ONE_ALS         = core.CMD_ALS_FORCE
    ONE_PSALS       = core.CMD_PSALS_FORCE
    CONT_PS         = core.CMD_PS_AUTO
    CONT_ALS        = core.CMD_ALS_AUTO
    CONT_PSALS      = core.CMD_PSALS_AUTO
    PAUSE_PS        = core.CMD_PS_PAUSE
    PAUSE_ALS       = core.CMD_ALS_PAUSE
    PAUSE_PSALS     = core.CMD_PSALS_PAUSE

    { Visible/IR/Proximity sensor measurement range }
    NORMAL          = $00
    HIGH            = $20

    { Read/write for uv_coeffs() }
    R               = 0
    W               = 1

    { Default dark sensor values }
    IR_DARK_DEF     = 250
    VIS_DARK_DEF    = 260

    { Lux calculation coefficients }
    VIS_COEFF       = 5_4100
    IR_COEFF        = 0_0800
    VIS_CPL         = 0_3190
    IR_CPL          = 8_4600
    CORR_FACT       = 0_0800


    SLAVE_WR        = core.SLAVE_ADDR
    SLAVE_RD        = core.SLAVE_ADDR|1
    I2C_MAX_FREQ    = core.I2C_MAX_FREQ


VAR

    word _cal_data[6]
    word _ir_dark, _vis_dark
    word _model
    byte _opmode


OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef SI114X_I2C_BC
    i2c:    "com.i2c.nocog"                     ' SPIN I2C engine
#else
    i2c:    "com.i2c"                           ' PASM I2C engine
#endif
    core:   "core.con.si114x"                   ' HW-specific constants
    time:   "time"                              ' time delay methods
    u64:    "math.unsigned64"                   ' unsigned 64-bit math


PUB null()
' This is not a top-level object


PUB start(): status
' Start using default I/O settings
    return startx(SCL, SDA, I2C_FREQ)


PUB startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom I2C pins and bus frequency
    if ( lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) )
        if ( status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ) )
            time.usleep(core.T_POR)
            if ( lookdown(dev_id(): core.PART_ID_RESP_1145, ...
                                    core.PART_ID_RESP_1146, ...
                                    core.PART_ID_RESP_1147) )
                reset()
                return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE


PUB stop()
' Stop I2C engine and clear cached data
    i2c.deinit()
    wordfill(@_cal_data, 0, 8)
    _opmode := 0


PUB defaults()
' Factory default settings
    reset()


PUB preset_als()
' Preset settings for ambient light sensing mode
    reset()                                     ' start with POR defaults
    opmode(CONT_ALS)
    als_data_rate(32_000_000)
    aux_chan_ena(FALSE)
    uv_chan_ena(FALSE)
    ir_chan_ena(TRUE)
    white_chan_ena(TRUE)
    int_mask(core.INTSRC_ALS)


PUB preset_prox()
' Preset settings for proximity sensor mode
    reset()
    uv_chan_ena(false)
    ir_chan_ena(true)
    white_chan_ena(false)
    prox_chan_ena(CH_PS1)
    ir_led1_current(22)
    set_prox_adc_input(1, ADC_LARGE_IR)
    prox_adc_gain(1)
    prox_adc_measure_delay(511)
    prox_adc_range(NORMAL)
    prox_adc_mode(PS_ADC_PROX)
    als_ir_adc_input(ADC_SMALL_IR)
    ir_gain(1)
    ir_range(HIGH)
    white_gain(1)
    white_range(HIGH)
    als_data_rate(125_490)
    opmode(CONT_PSALS)


PUB preset_uvi()
' Preset settings for measuring UV Index
    reset()
    opmode(CONT_ALS)
    als_data_rate(32_000_000)
    ' These are the factory default part-to-part variance coefficients.
    ' They are restored by calling reset(), but show them here so the user
    '   doesn't have to look far for them.
    uv_set_coeffs($00_01_6B_7B)

    aux_chan_ena(TRUE)
    uv_chan_ena(TRUE)
    ir_chan_ena(FALSE)
    white_chan_ena(FALSE)

    ir_range(HIGH)
    white_range(HIGH)

    ir_gain(1)
    white_gain(1)

    int_mask(core.INTSRC_ALS)


PUB als_data_rate(rate=-2): c
' Set measurement data rate, in milli-Hz
'   Valid values: 489..32_000_000 (= 0.489Hz .. 32kHz)
'   Any other value polls the chip and returns the current setting
    case rate
        489..32_000_000:
            rate := (32_000_000 / rate)
            writereg(core.MEAS_RATE0, rate, 2)
        other:
            c := 0
            c := readreg(core.MEAS_RATE0, 2)
            return (32_000_000 / c)


PUB als_data_rdy(): flag
' Flag indicating ALS data is ready
'   Returns: TRUE (-1) or FALSE (0)
    flag := ( (interrupt() & core.ALS_INT_BITS) <> 0 )
    if ( flag )
        int_clear(core.INTSRC_ALS)


pub als_ir_adc_input(i=-2): c
' Set ADC input used for IR measurements
'   i:
'       ADC_SMALL_IR ($00): small IR photodiode
'       ADC_LARGE_IR ($03): large IR photodiode
'   Returns:    current setting if i is out of range
    case i
        ADC_SMALL_IR, ADC_LARGE_IR:
            param_set(core.ALS_IR_ADCMUX, i)
        other:
            return param_query(core.ALS_IR_ADCMUX)


PUB aux_chan_ena(state=-2): curr_state
' Enable the auxiliary source data channel
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := param_query(core.CHLIST)
    case ||(state)
        0, 1:
            state := (curr_state & core.EN_AUX_MASK) | ( ||(state) << core.EN_AUX )
            param_set(core.CHLIST, state)
        other:
            return (((curr_state >> core.EN_AUX) & 1) == 1)


PUB cal_data(idx): cal_word
' Return a word of calibration data
'   Valid values: 0..5
'   Any other value is ignored
    case idx
        0..5:
            return _cal_data[idx]
        other:
            return


PUB dev_id(): id
' Part ID of sensor
'   Returns:
'       $45: Si1145
'       $46: Si1146
'       $47: Si1147
    _model := id := readreg(core.PART_ID)


PUB int_clear(cm)
' Clear interrupts
'   Bits: 5..0 (set a bit to clear the interrupt)
'       5: command interrupt
'       4: proximity sensor ch3 interrupt
'       3: proximity sensor ch2 interrupt
'       2: proximity sensor ch1 interrupt
'       0: ALS or UV measurement is ready
    writereg(core.IRQ_STATUS, cm & core.IRQ_STATUS_MASK)


PUB interrupt(): s
' Interrupt source(s)
'   Returns: interrupt mask
'   Bits: 5..0 (set a bit to clear the interrupt)
'       5: command interrupt
'       4: proximity sensor ch3 interrupt
'       3: proximity sensor ch2 interrupt
'       2: proximity sensor ch1 interrupt
'       0: ALS or UV measurement is ready
    return readreg(core.IRQ_STATUS)


PUB int_mask(m=-2): cm
' Set interrupt mask
'   Bits: 4..0 (set a bit to assert INT pin when interrupt occurs)
'       4: proximity sensor ch3 interrupt
'       3: proximity sensor ch2 interrupt
'       2: proximity sensor ch1 interrupt
'       0: ALS or UV measurement is ready
'   Any other value polls the chip and returns the current setting
    case m
        %00000000..%11111111:
            writereg(core.IRQ_ENABLE, m & core.IRQ_ENABLE_MASK)
        other:
            return readreg(core.IRQ_ENABLE)


PUB ir_chan_ena(state=-2): curr_state
' Enable the IR ambient light source data channel
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := param_query(core.CHLIST)
    case ||(state)
        0, 1:
            state := (curr_state & core.EN_ALS_IR_MASK) | ( ||(state) << core.EN_ALS_IR )
            param_set(core.CHLIST, state)
        other:
            return (((curr_state >> core.EN_ALS_IR) & 1) == 1)


PUB ir_bias(val=-2): curr_val
' Set IR sensor dark value (ADC word)
'   Valid values: 0..65535
'   Any other value returns the current setting
    if ( lookdown(val: 0..65535) )
        _ir_dark := val
    else
        return _ir_dark


PUB ir_data(): a
' Return data from infra-red light channel
    return readreg(core.ALS_IR_DATA0, 2)


PUB ir_gain(gain=-2): curr_gain
' Gain factor of infra-red light sensor
'   Valid values: 1, 16, 64, 128
'   Any other value polls the chip and returns the current setting
    curr_gain := param_query(core.ALS_IR_ADC_GAIN)
    case gain
        1, 16, 64, 128:
            gain := >|(gain)-1
            param_set(core.ALS_IR_ADCGAIN, gain)
            gain <<= core.IR_ADC_REC
            ' Set the one's complement of the gain val
            ' to ADC recovery period, per datasheet
            param_set(core.ALS_IR_ADC_COUNTER, !gain)
        other:
            return |<(curr_gain & core.ALS_IR_ADCGAIN_BITS)


PUB ir_led1_current(i=-2): c
' Set IR LED1 current
'   i:          LED current limit in milliamperes
'   Returns:    current setting if i is out of range
    c := readreg(core.PS_LED21)
    case i
        0, 6, 11, 22, 45, 67, 90, 112, 135, 157, 180, 202, 224, 269, 314, 359:
            i := lookdownz(i: 0, 6, 11, 22, 45, 67, 90, 112, 135, 157, 180, 202, 224, 269, 314, 359)
            i := (c & core.LED1_I_MASK) | i
            writereg(core.PS_LED21, i)
        other:
            c := c & core.LED1_I_BITS
            return lookupz(c: 0, 6, 11, 22, 45, 67, 90, 112, 135, 157, 180, 202, 224, 269, 314, 359)

PUB ir_led2_current(i=-2): c
' Set IR LED2 current (Si1146 and Si1147 only)
'   i:          LED current limit in milliamperes
'   Returns:    current setting if i is out of range
    c := readreg(core.PS_LED21)
    case i
        0, 6, 11, 22, 45, 67, 90, 112, 135, 157, 180, 202, 224, 269, 314, 359:
            c := (c & core.LED2_I_MASK)
            if ( (_model == $46) or (_model == $47) )
                ' this LED output is only supported on the Si1146 and 1147
                c |= lookdownz(i:   0, 6, 11, 22, 45, 67, 90, 112, 135, 157, 180, 202, 224, 269, ...
                                    314, 359) << core.LED2_I
            elseif (_model == $45)
                ' must be set to 0 on the Si1145
                'i |= 0
            else
                ' invalid model; driver not started yet or bad communication: do nothing
                return
            writereg(core.PS_LED21, c)
        other:
            c := (c >> core.LED2_I) & core.LED2_I_BITS
            return lookupz(c: 0, 6, 11, 22, 45, 67, 90, 112, 135, 157, 180, 202, 224, 269, 314, 359)


PUB ir_led3_current(i=-2): c
' Set IR LED3 current (Si1147 only)
'   i:          LED current limit in milliamperes
'   Returns:    current setting if i is out of range
    c := readreg(core.PS_LED3)
    case i
        0, 6, 11, 22, 45, 67, 90, 112, 135, 157, 180, 202, 224, 269, 314, 359:
            c := (c & core.LED3_I_MASK)
            if ( _model == $47 )
                ' this LED output is only supported on the Si1147
                c |= lookdownz(i:   0, 6, 11, 22, 45, 67, 90, 112, 135, 157, 180, 202, 224, 269, ...
                                    314, 359)
            elseif ( (_model == $45) or (_model == $46) )
                ' must be set to 0 on the Si1145 and 1146
                'i |= 0
            else
                ' invalid model; driver not started yet or bad communication: do nothing
                return
            writereg(core.PS_LED3, c)
        other:
            c := c & core.LED3_I_BITS
            return lookupz(c: 0, 6, 11, 22, 45, 67, 90, 112, 135, 157, 180, 202, 224, 269, 314, 359)


PUB ir_overflow(): f
' Flag indicating infra-red light data conversion has overflowed
'   Returns: TRUE (-1) if overflowed, FALSE (0) otherwise
    return ( readreg(core.RESPONSE) == core.ALS_IR_ADC_OVERFLOW )


PUB ir_range(r=-2): c
' Set measurement range of infra-red light sensor
'   Valid values:
'       NORMAL ($00): Normal signal range/high sensitivity
'       HIGH ($20): High signal range (gain divided by 14.5)
    c := param_query(core.ALS_IR_ADC_MISC)
    case r
        NORMAL, HIGH:
            r := (c & core.IR_RANGE_MASK) | r
            param_set(core.ALS_IR_ADC_MISC, r)
        other:
            return c


PUB lux(): lx | vis, ir, lux1, lux2
' Calculate illuminance, in tenths of a lux (1000 = 100.0 lx)
    vis := ir := 0
    { average 50 samples }
    repeat 50
        opmode(ONE_ALS)
        vis += white_data()
        ir += ir_data()
    vis /= 50
    ir /= 50

    lux1 := u64.multdiv( (vis - _vis_dark), VIS_COEFF, 1000)
    lux2 := u64.multdiv( (ir - _ir_dark), IR_COEFF, 1000)
    return (0 #> (lux1 - lux2))                 ' clamp to min of 0


PUB opmode(mode=-2): curr_mode
' Set operation mode
'   Valid values:
'       ONE_PS, ONE_ALS, ONE_PSALS: Force a single PS, ALS or PS+ALS measurement
'       CONT_PS, CONT_ALS, CONT_PSALS: Start continuous PS, ALS, or PS+ALS measurement
'       PAUSE_PS, PAUSE_ALS, PAUSE_PSALS: Pause a running continuous measurement
'   Valid values return response status from chip
'   Any other value returns the last setting (shadow register)
    case mode
        ONE_PS, ONE_ALS, ONE_PSALS, CONT_PS, CONT_ALS, CONT_PSALS, PAUSE_PS, PAUSE_ALS, PAUSE_PSALS:
            _opmode := mode
            command(mode)
        other:
            return _opmode                      ' not readable from sensor;
                                                ' keep a local copy


PUB power_state(): s
' Chip status
'   Returns:
'       RUN (%100): Device is awake
'       SUSP (%010): Device is in a low-power state, waiting for a measurement to complete
'       SLEEP (%001): Device is in its lowest power state
    return readreg(core.CHIP_STAT)


pub prox_adc_gain(g=-2): c
' Set PS ADC gain factor
'   g:  1..128, in powers of 2
'   CAUTION: setting this value greater than 32 is not recommended without contacting
'       Silicon Labs (reference datasheet rev 1.4, p.54, 'PS_ADC_GAIN @ 0x0B')
    case g
        1, 2, 4, 8, 16, 32, 64, 128:
            g := (>|(g)-1)                        ' log2(g)
            param_set(core.PS_ADC_GAIN, g)
        other:
            return |<( param_query(core.PS_ADC_GAIN) )


PUB prox_adc_input(ch=1): m
' Get currently set input for PS ADC channel
'   ch:         channel (1..3; default: 1)
'   Returns:    currently set ADC input/mode (see set_ps_adc_input() )
    if ( (ch < 1) or (ch > 3) )
        return -1                               ' invalid channel

    return param_query(core.PS1_ADCMUX+(ch-1))


pub prox_adc_measure_delay(d=-2): c
' Set recovery period for ADC before taking PS measurement
'   d:          ADC clocks (1, 7, 15, 31, 63, 127, 255, 511; default: 511)
'   Returns:    current value if ct is out of range
    case d
        1, 7, 15, 31, 63, 127, 255, 511:
            d := lookdownz(d: 1, 7, 15, 31, 63, 127, 255, 511) << core.PS_ADC_REC
            param_set(core.PS_ADC_COUNTER, d)
        other:
            return (param_query(core.PS_ADC_COUNTER) >> core.PS_ADC_REC) & core.PS_ADC_REC_BITS


CON

    PS_ADC_RAW  = 0
    PS_ADC_PROX = 1

PUB prox_adc_mode(m=-2): c
' Set proximity sensor ADC mode
'   m:
'       PS_ADC_RAW (0):     raw ADC measurement mode
'       PS_ADC_PROX (1):    proximity measurement mode
'   Returns:    currently set mode if m is out of range
    c := param_query(core.PS_ADC_MISC)
    case m
        PS_ADC_RAW, PS_ADC_PROX:
            m := (c & core.PS_ADC_MODE_MASK) | (m << core.PS_ADC_MODE)
            param_set(core.PS_ADC_MISC, m)
        other:
            return ( (c >> core.PS_ADC_MODE) & 1)


pub prox_adc_range(r=-2): c
' Set proximity sensor ADC measurement range
'   r:
'       NORMAL ($00):   normal signal range
'       HIGH ($20):     high signal range (gain is divided by 14.5)
'   Returns:            current value if r is out of range
    c := param_query(core.PS_ADC_MISC)
    case r
        NORMAL, HIGH:
            r := (c & core.PS_RANGE_MASK) | r
            param_set(core.PS_ADC_MISC, r)
        other:
            return (c >> core.PS_RANGE) & 1


con

    CH_PS1  = %001
    CH_PS2  = %010
    CH_PS3  = %100

pub prox_chan_ena(ch=-2): c
' Set proximity sensor channel mask
'   ch:         channel bitmask
'       b2..0:
'           2: PS3
'           1: PS2
'           0: PS1
'   Returns:    current bitmask if ch is out of range
    c := param_query(core.CHLIST)
    case ch
        %000..%111:
            ch := ((c & core.EN_PS_MASK) | ch)
            param_set(core.CHLIST, ch)
        other:
            return (c & core.EN_PS_BITS)


PUB prox_data = prox1_data
PUB prox1_data(): p
' Read PS1 ADC channel
'   Returns: u16 ADC word
    return readreg(core.PS1_DATA0, 2)


PUB prox2_data(): p
' Read PS2 ADC channel
'   Returns: u16 ADC word
    return readreg(core.PS2_DATA0, 2)


PUB prox3_data(): p
' Read PS3 ADC channel
'   Returns: u16 ADC word
    return readreg(core.PS3_DATA0, 2)


PUB rd_cal_data()
' Read calibration data into 6-word array
    wordfill(@_cal_data, 0, 6)
    command(core.CMD_GET_CAL)
    i2c.start()
    i2c.write(SLAVE_WR)
    i2c.write(core.CAL_DATA)

    i2c.start()
    i2c.write(SLAVE_RD)
    i2c.rdblock_lsbf(@_cal_data, 12, i2c.NAK)
    i2c.stop()


PUB reset()
' Perform soft-reset
    command(core.CMD_RESET)
    time.msleep(10)
    writereg(core.HW_KEY, core.HW_KEY_EXPECTED)
    time.msleep(10)
    ir_bias(IR_DARK_DEF)
    white_bias(VIS_DARK_DEF)


PUB rev_id(): id
' Revision
'   Returns: $00
    return readreg(core.REV_ID)


PUB running(): f
' Flag indicating device is running/awake
'   Returns: TRUE (-1) if device is awake, FALSE (0) otherwise
    return ( readreg(core.CHIP_STAT) == core.CHIP_STAT_RUNNING )


PUB seq_id(): r
' Sequencer revision
'   Returns known values:
'       $08: Si114x-A10 (MAJOR_SEQ=1, MINOR_SEQ=0)
    return readreg(core.SEQ_ID)


con

    ' set_ps_adc_input() modes
    ADC_SMALL_IR    = $00
    ADC_VIS_PHOTO   = $02
    ADC_LARGE_IR    = $03
    ADC_NO_PHOTO    = $06
    ADC_GND         = $25
    ADC_TEMP        = $65
    ADC_VDD         = $75

PUB set_prox_adc_input(ch, i)
' Select ADC input for PS channel
'   ch:     channel (1..3)
'   i:      input:
'       ADC_SMALL_IR ($00):     small IR photodiode
'       ADC_VIS_PHOTO ($02):    visible photodiode (subtract ADC_NO_PHOTO measurement from this
'                               measurement
'       ADC_LARGE_IR ($03):     large IR photodiode (default)
'       ADC_NO_PHOTO ($06):     no photodiode (typically used as a reference for reading ambient
'                               IR or visible light)
'       ADC_GND ($25):          ground voltage (typically used as a reference for electrical
'                               measurements)
'       ADC_TEMP ($65):         temperature (relative measurements recommended; subtract ADC_GND
'                               measurement from this reading
'       ADC_VDD ($75):          Vdd voltage (a separate ADC_GND measurement should be done to use
'                               as the reference
'   NOTE: only inputs ADC_SMALL_IR and ADC_LARGE_IR are valid when using the proximity detection
'       functionality
    if ( (ch < 1) or (ch > 3) )
        return                                  ' invalid channel

    case i
        ADC_SMALL_IR, ADC_VIS_PHOTO, ADC_LARGE_IR, ADC_NO_PHOTO, ADC_GND, ADC_TEMP, ADC_VDD:
            param_set(core.PS1_ADCMUX+(ch-1), i)
        other:
            return                              ' invalid mode


PUB sleeping(): flag
' Flag indicating device is sleeping
'   Returns:    TRUE (-1) if device is in its lowest power state
'               FALSE (0) otherwise
    return ( readreg(core.CHIP_STAT) == core.CHIP_STAT_SLEEP )


PUB suspended(): flag
' Suspended status
'   Returns:    TRUE (-1) if device is in a low-power state,
'               FALSE (0) otherwise
    return ( readreg(core.CHIP_STAT) == core.CHIP_STAT_SUSPEND )


PUB uv_chan_ena(state=-2): curr_state
' Enable the UV index source data channel
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := param_query(core.CHLIST)
    case ||(state)
        0, 1:
            state := ||(state) << core.EN_UV
            state := ((curr_state & core.EN_UV_MASK) | state)
            param_set(core.CHLIST, state)
        other:
            return (((curr_state >> core.EN_UV) & 1) == 1)


PUB uv_coeffs(): c
' Get coefficients used to calculate UV index readings
'   NOTE: Four 8-bit coefficients are used, packed into long 'coeffs'
'       UCOEF3_UCOEF2_UCOEF1_UCOEF0
    return readreg(core.UCOEF0, 4)


PUB uv_set_coeffs(c)
' Set coefficients used to calculate UV index readings
'   Valid values:
'       rw: READ (0), WRITE (1)
'   NOTE: Four 8-bit coefficients are used, packed into long 'coeffs'
'       UCOEF3_UCOEF2_UCOEF1_UCOEF0
    writereg(core.UCOEF0, c, 4)


PUB uv_data(): a
' Return data from UV index channel
    return readreg(core.AUX_DATA0, 2)


PUB white_bias(val=-2): curr_val
' Set white/visible sensor bias/dark value (ADC word)
'   Valid values: 0..65535
'   Any other value returns the current setting
    if ( lookdown(val: 0..65535) )
        _vis_dark := val
    else
        return _vis_dark


PUB white_chan_ena(state=-2): curr_state
' Enable the white/visible ambient light source data channel
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := param_query(core.CHLIST)
    case ||(state)
        0, 1:
            state := ||(state) << core.EN_ALS_VIS
            state := ((curr_state & core.EN_ALS_VIS_MASK) | state)
            param_set(core.CHLIST, state)
        other:
            return (((curr_state >> core.EN_ALS_VIS) & 1) == 1)


PUB white_data(): a
' Return data from white/visible light channel
    return readreg(core.ALS_VIS_DATA0, 2)


PUB white_gain(gain=-2): curr_gain
' Gain factor of white/visible light sensor
'   Valid values: 1, 16, 64, 128
'   Any other value polls the chip and returns the current setting
    curr_gain := param_query(core.ALS_VIS_ADC_GAIN)
    case gain
        1, 16, 64, 128:
            gain := >|(gain)-1
            param_set(core.ALS_VIS_ADCGAIN, gain)
            gain <<= core.VIS_ADC_REC
            ' Set the one's complement of the gain val
            ' to ADC recovery period, per datasheet
            param_set(core.ALS_VIS_ADC_COUNTER, !gain)
        other:
            return |<(curr_gain & core.ALS_VIS_ADCGAIN_BITS)


PUB white_overflow(): flag
' Flag indicating white/visible light data conversion has overflowed
'   Returns: TRUE (-1) if overflowed, FALSE (0) otherwise
    return ( readreg(core.RESPONSE) == core.ALS_VIS_ADC_OVERFLOW )


PUB white_range(range=-2): curr_rng
' Set measurement range of white/visible light sensor
'   Valid values:
'       NORMAL ($00): Normal signal range/high sensitivity
'       HIGH ($20): High signal range (gain divided by 14.5)
    case range
        NORMAL, HIGH:
            param_set(core.ALS_VIS_ADC_MISC, range)
        other:
            return param_query(core.ALS_VIS_ADC_MISC)


PRI clr_resp(): r
' Clear response register
'   Returns: response, after clearing
    writereg(core.COMMAND, core.CMD_NOP)
    return readreg(core.RESPONSE)


PRI command(cmd): r
' Send command with parameters to device
    r := 0
    case cmd
        core.CMD_NOP, core.CMD_RESET, core.CMD_BUSADDR, core.CMD_PS_FORCE, core.CMD_GET_CAL, ...
        core.CMD_ALS_FORCE, core.CMD_PSALS_FORCE, core.CMD_PS_PAUSE, core.CMD_ALS_PAUSE, ...
        core.CMD_PSALS_PAUSE, core.CMD_PS_AUTO, core.CMD_ALS_AUTO, core.CMD_PSALS_AUTO:
            repeat
            until ( clr_resp() == core.NO_ERROR )
            writereg(core.COMMAND, cmd)
            if ( cmd == core.CMD_RESET )        ' no response when resetting
                time.msleep(1)                  ' also must wait min. 1ms
                return
            return readreg(core.RESPONSE)       ' XXX device NAK on bus if cmd was reset...must wait?


PRI param_query(p): v
' Query a parameter for the current value
'   p:          parameter
'   Returns:    current value
    repeat
    until ( clr_resp() == core.NO_ERROR )

    writereg(core.COMMAND, core.CMD_PARAM_QUERY | p)

    repeat
        v := readreg(core.RESPONSE)
    while (v == 0)

    return readreg(core.PARAM_RD)


PRI param_set(p, v): r
' Set a parameter value
'   p:          parameter
'   v:          value
'   Returns:    status response
    writereg(core.PARAM_WR, v)

    repeat
    until ( clr_resp() == core.NO_ERROR )

    writereg(core.COMMAND, core.CMD_PARAM_SET | p)

    repeat
        r := readreg(core.RESPONSE)
    while (r == 0)

    return

PRI readreg(reg_nr, len=1): v | cmd_pkt
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' validate register
        $00..$04, $07..$09, $10, $13..$18, $20..$2E, $30:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            v := 0
            i2c.start()
            i2c.wrblock_lsbf(@cmd_pkt, 2)

            i2c.start()
            i2c.write(SLAVE_RD)
            i2c.rdblock_lsbf(@v, len, i2c.NAK)
            i2c.stop()
        other:
            return


PRI writereg(reg_nr, val, len=1) | cmd_pkt
' Write nr_bytes from ptr_buff to the device
    case reg_nr
        $03, $04, $07, $08, $09, $0F, $10, $13..$18, $20..$2E:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr

            i2c.start()
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wrblock_lsbf(@val, len)
            i2c.stop()
        other:
            return


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

