{
    --------------------------------------------
    Filename: core.con.si1145.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2019
    Started Jun 01, 2019
    Updated Jun 01, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    I2C_MAX_FREQ                = 3_400_000
    SLAVE_ADDR                  = $60 << 1

' Register definitions
    PART_ID                     = $00
    REV_ID                      = $01
    SEQ_ID                      = $02

    INT_CFG                     = $03
        FLD_INT_OE              = 0

    IRQ_ENABLE                  = $04
        FLD_ALS_IE              = 0
        FLD_PS1_IE              = 2
        FLD_PS2_IE              = 3
        FLD_PS3_IE              = 4

    HW_KEY                      = $07
    MEAS_RATE0                  = $08
    MEAS_RATE1                  = $09
    PS_LED21                    = $0F
        FLD_LED1_I              = 0
        FLD_LED2_I              = 4
        BITS_LED1_LI            = %1111
        BITS_LED2_LI            = %1111

    PS_LED3                     = $10
        FLD_LED3_I              = 0
        BITS_LED3_I             = %1111

    UCOEF0                      = $13
    UCOEF1                      = $14
    UCOEF2                      = $15
    UCOEF3                      = $16

    PARAM_WR                    = $17
    COMMAND                     = $18
    RESPONSE                    = $20

    IRQ_STATUS                  = $21
        FLD_ALS_INT             = 0
        FLD_PS1_INT             = 2
        FLD_PS2_INT             = 3
        FLD_PS3_INT             = 4
        FLD_CMD_INT             = 5
        BITS_ALS_INT            = %11

    ALS_VIS_DATA0               = $22
    ALS_VIS_DATA1               = $23

    ALS_IR_DATA0                = $24
    ALS_IR_DATA1                = $25

    PS1_DATA0                   = $26
    PS1_DATA1                   = $27

    PS2_DATA0                   = $28
    PS2_DATA1                   = $29

    PS3_DATA0                   = $2A
    PS3_DATA1                   = $2B

    AUX_DATA0                   = $2C
    AUX_DATA1                   = $2D

    PARAM_RD                    = $2E

    CHIP_STAT                   = $30

    ANA_IN_KEY_0                = $3B
    ANA_IN_KEY_1                = $3C
    ANA_IN_KEY_2                = $3D
    ANA_IN_KEY_3                = $3E

    CMD_PARAM_QUERY             = %100 << 5
    CMD_PARAM_SET               = %101 << 5
    CMD_NOP                     = %000_00000
    CMD_RESET                   = %000_00001
    CMD_BUSADDR                 = %000_00010
    CMD_PS_FORCE                = %000_00101
    CMD_GET_CAL                 = %0001_0010
    CMD_ALS_FORCE               = %000_00110
    CMD_PSALS_FORCE             = %000_00111
    CMD_PS_PAUSE                = %000_01001
    CMD_ALS_PAUSE               = %000_01010
    CMD_PSALS_PAUSE             = %000_01011
    CMD_PS_AUTO                 = %000_01101
    CMD_ALS_AUTO                = %000_01110
    CMD_PSALS_AUTO              = %000_01111

    RSP_NO_ERROR                = %0000 << 4
    RSP_INVALID_SETTING         = %1000_0000
    RSP_PS1_ADC_OVERFLOW        = %1000_1000
    RSP_PS2_ADC_OVERFLOW        = %1000_1001
    RSP_PS3_ADC_OVERFLOW        = %1000_1010
    RSP_ALS_VIS_ADC_OVERFLOW    = %1000_1100
    RSP_ALS_IR_ADC_OVERFLOW     = %1000_1101
    RSP_AUX_ADC_OVERFLOW        = %1000_1110

PUB Null
'' This is not a top-level object
