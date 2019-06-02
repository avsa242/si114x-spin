{
    --------------------------------------------
    Filename: core.con.si114x.spin
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
        PART_ID_RESP_1145       = $45
        PART_ID_RESP_1146       = $46
        PART_ID_RESP_1147       = $47

    REV_ID                      = $01
    SEQ_ID                      = $02
        SEQ_ID_RESP             = $08

    INT_CFG                     = $03
        FLD_INT_OE              = 0

    IRQ_ENABLE                  = $04
        FLD_ALS_IE              = 0
        FLD_PS1_IE              = 2
        FLD_PS2_IE              = 3
        FLD_PS3_IE              = 4

    HW_KEY                      = $07
        HW_KEY_EXPECTED         = $17

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
        CHIP_STAT_SLEEP         = %001
        CHIP_STAT_SUSPEND       = %010
        CHIP_STAT_RUNNING       = %100

    ANA_IN_KEY_0                = $3B
    ANA_IN_KEY_1                = $3C
    ANA_IN_KEY_2                = $3D
    ANA_IN_KEY_3                = $3E

' COMMAND register values
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

' RESPONSE register return values
    RSP_NO_ERROR                = %0000 << 4
    RSP_INVALID_SETTING         = %1000_0000
    RSP_PS1_ADC_OVERFLOW        = %1000_1000
    RSP_PS2_ADC_OVERFLOW        = %1000_1001
    RSP_PS3_ADC_OVERFLOW        = %1000_1010
    RSP_ALS_VIS_ADC_OVERFLOW    = %1000_1100
    RSP_ALS_IR_ADC_OVERFLOW     = %1000_1101
    RSP_AUX_ADC_OVERFLOW        = %1000_1110

' Sequencer RAM Parameters
    PARM_I2C_ADDR               = $00

    PARM_CHLIST                 = $01
    PARM_CHLIST_MASK            = $F7
        FLD_EN_PS1              = 0
        FLD_EN_PS2              = 1
        FLD_EN_PS3              = 2
        FLD_EN_ALS_VIS          = 4
        FLD_EN_ALS_IR           = 5
        FLD_EN_AUX              = 6
        FLD_EN_UV               = 7
        MASK_EN_PS1             = PARM_CHLIST_MASK ^ (1 << FLD_EN_PS1)
        MASK_EN_PS2             = PARM_CHLIST_MASK ^ (1 << FLD_EN_PS2)
        MASK_EN_PS3             = PARM_CHLIST_MASK ^ (1 << FLD_EN_PS3)
        MASK_EN_ALS_VIS         = PARM_CHLIST_MASK ^ (1 << FLD_EN_ALS_VIS)
        MASK_EN_ALS_IR          = PARM_CHLIST_MASK ^ (1 << FLD_EN_ALS_IR)
        MASK_EN_AUX             = PARM_CHLIST_MASK ^ (1 << FLD_EN_AUX)
        MASK_EN_UV              = PARM_CHLIST_MASK ^ (1 << FLD_EN_UV)


    PARM_PSLED12_SELECT         = $02
    PARM_PSLED12_SELECT_MASK    = $77
        FLD_PS1_LED             = 0
        FLD_PS2_LED             = 4
        BITS_PS1_LED            = %111
        BITS_PS2_LED            = %111
        MASK_PS1_LED            = PARM_PSLED12_SELECT_MASK ^ (BITS_PS1_LED << FLD_PS1_LED)
        MASK_PS2_LED            = PARM_PSLED12_SELECT_MASK ^ (BITS_PS2_LED << FLD_PS2_LED)

    PARM_PSLED3_SELECT          = $03
    PARM_PSLED3_SELECT_MASK     = $07
        FLD_PS3_LED             = 0
        BITS_PS3_LED            = %111

    PARM_PS_ENCODING            = $05
    PARM_PS_ENCODING_MASK       = $70
        FLD_PS1_ALIGN           = 4
        FLD_PS2_ALIGN           = 5
        FLD_PS3_ALIGN           = 6
        MASK_PS1_ALIGN          = PARM_PS_ENCODING_MASK ^ (1 << FLD_PS1_ALIGN)
        MASK_PS2_ALIGN          = PARM_PS_ENCODING_MASK ^ (1 << FLD_PS2_ALIGN)
        MASK_PS3_ALIGN          = PARM_PS_ENCODING_MASK ^ (1 << FLD_PS3_ALIGN)

    PARM_ALS_ENCODING           = $06
    PARM_ALS_ENCODING_MASK      = $30
        FLD_ALS_VIS_ALIGN       = 4
        FLD_ALS_IR_ALIGN        = 5
        MASK_ALS_VIS_ALIGN      = PARM_ALS_ENCODING_MASK ^ (1 << FLD_ALS_VIS_ALIGN)
        MASK_ALS_IR_ALIGN       = PARM_ALS_ENCODING_MASK ^ (1 << FLD_ALS_IR_ALIGN)

    PARM_PS1_ADCMUX             = $07
    PARM_PS2_ADCMUX             = $08
    PARM_PS3_ADCMUX             = $09

    PARM_PS_ADC_COUNTER         = $0A
    PARM_PS_ADC_COUNTER_MASK    = $70
        FLD_PS_ADC_REC          = 4
        BITS_PS_ADC_REC         = %111

    PARM_PS_ADC_GAIN            = $0B
    PARM_PS_ADC_GAIN_MASK       = $07
        FLD_PS_ADC_GAIN         = 0
        BITS_PS_ADC_GAIN        = %111

    PARM_PS_ADC_MISC            = $0C
    PARM_PS_ADC_MISC_MASK       = $22
        FLD_PS_ADC_MODE         = 2
        FLD_PS_RANGE            = 5
        MASK_PS_ADC_MODE        = PARM_PS_ADC_MISC_MASK ^ (1 << FLD_PS_ADC_MODE)
        MASK_PS_RANGE           = PARM_PS_ADC_MISC_MASK ^ (1 << FLD_PS_RANGE)

    PARM_ALS_IR_ADCMUX          = $0E

    PARM_AUX_ADCMUX             = $0F
        AUX_ADCMUX_TEMPERATURE  = $65
        AUX_ADCMUX_VDDVOLTAGE   = $75

    PARM_ALS_VIS_ADC_COUNTER    = $10
    PARM_ALS_VIS_ADC_COUNTER_MASK   = $70
            FLD_VIS_ADC_REC         = 4
            BITS_VIS_ADC_REC        = %111

    PARM_ALS_VIS_ADC_GAIN       = $11
    PARM_ALS_VIS_ADC_GAIN_MASK  = $07
        FLD_ALS_VIS_ADC_GAIN    = 0
        BITS_ALS_VIS_ADC_GAIN   = %111

    PARM_ALS_VIS_ADC_MISC       = $12
    PARM_ALS_VIS_ADC_MISC_MASK  = $20
        FLD_VIS_RANGE           = 5

    PARM_LED_REC                = $1C

    PARM_ALS_IR_ADC_COUNTER     = $1D
    PARM_ALS_IR_ADC_COUNTER_MASK    = $70
        FLD_IR_ADC_REC              = 4
        BITS_IR_ADC_REC             = %111

    PARM_ALS_IR_ADC_GAIN        = $1E
    PARM_ALS_IR_ADC_GAIN_MASK   = $07
        FLD_ALS_IR_ADC_GAIN     = 0
        BITS_ALS_IR_ADC_GAIN    = %111

    PARM_ALS_IR_ADC_MISC        = $1F
    PARM_ALS_IR_ADC_MISC_MASK   = $20
        FLD_IR_RANGE            = 5

PUB Null
'' This is not a top-level object
