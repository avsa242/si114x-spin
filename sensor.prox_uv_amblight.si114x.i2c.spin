{
    --------------------------------------------
    Filename: sensor.prox_uv_amblight.si114x.i2c.spin
    Author: Jesse Burt
    Description: Driver for the Silicon Labs Si114[5|6|7] series
        Proximity/UV/Amblient light sensor IC
    Copyright (c) 2019
    Started Jun 01, 2019
    Updated Jun 01, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 400_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

' Chip status
    CHIP_STAT_SLEEP         = core#CHIP_STAT_SLEEP
    CHIP_STAT_SUSPEND       = core#CHIP_STAT_SUSPEND
    CHIP_STAT_RUNNING       = core#CHIP_STAT_RUNNING

VAR


OBJ

    i2c : "com.i2c"
    core: "core.con.si114x.spin"
    time: "time"

PUB Null
''This is not a top-level object

PUB Start: okay                                                 'Default to "standard" Propeller I2C pins and 400kHz

    okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                time.MSleep (1)
                if i2c.present (SLAVE_WR)                       'Response from device?
                    if lookdown(PartID: core#PART_ID_RESP_1145, core#PART_ID_RESP_1146, core#PART_ID_RESP_1147)
                        HWKey
                        return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop
' Put any other housekeeping code here required/recommended by your device before shutting down
    i2c.terminate

PUB AUXChan(enabled) | tmp
' Enable the auxiliary source data channel
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    tmp := command (core#CMD_PARAM_QUERY, core#PARM_CHLIST, 0)
    case ||enabled
        0, 1:
            enabled := (||enabled) << core#FLD_EN_AUX
        OTHER:
            result := ((tmp >> core#FLD_EN_AUX) & %1) * TRUE
            return result

    tmp &= core#MASK_EN_AUX
    tmp := (tmp | enabled) & core#PARM_CHLIST_MASK
    command (core#CMD_PARAM_SET, core#PARM_CHLIST, tmp)

PUB HWKey
' Writes $17 to HW_KEY reg (per the Si114x datasheet, this must be written for proper operation)
    result := core#HW_KEY_EXPECTED
    writeReg (core#HW_KEY, 1, @result)

PUB IRChan(enabled) | tmp
' Enable the IR ambient light source data channel
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    tmp := command (core#CMD_PARAM_QUERY, core#PARM_CHLIST, 0)
    case ||enabled
        0, 1:
            enabled := (||enabled) << core#FLD_EN_ALS_IR
        OTHER:
            result := ((tmp >> core#FLD_EN_ALS_IR) & %1) * TRUE
            return result

    tmp &= core#MASK_EN_ALS_IR
    tmp := (tmp | enabled) & core#PARM_CHLIST_MASK
    command (core#CMD_PARAM_SET, core#PARM_CHLIST, tmp)

PUB IRLight
' Return data from infra-red light channel
    readReg (core#ALS_IR_DATA0, 2, @result)

PUB PartID
' Part ID of sensor
'   Returns:
'       $45: Si1145
'       $46: Si1146
'       $47: Si1147
    readReg (core#PART_ID, 1, @result)

PUB RevID
' Revision
'   Returns: $00
    readReg (core#REV_ID, 1, @result)

PUB Running
' Running status
'   Returns: TRUE if device is awake, FALSE otherwise
    readReg (core#CHIP_STAT, 1, @result)
    result := (result == core#CHIP_STAT_RUNNING)

PUB SeqID
' Sequencer revision
'   Returns: $08: Si114x-A10 (MAJOR_SEQ=1, MINOR_SEQ=0)
    readReg (core#SEQ_ID, 1, @result)

PUB Sleeping
' Sleeping status
'   Returns: TRUE if device is in its lowest power state, FALSE otherwise
    readReg (core#CHIP_STAT, 1, @result)
    result := (result == core#CHIP_STAT_SLEEP)

PUB Status
' Chip status
'   Returns:
'       CHIP_STAT_RUNNING (%100): Device is awake
'       CHIP_STAT_SUSPEND (%010): Device is in a low-power state, waiting for a measurement to complete
'       CHIP_STAT_SLEEP (%001): Device is in its lowest power state
    readReg (core#CHIP_STAT, 1, @result)

PUB Suspended
' Suspended status
'   Returns: TRUE if device is in a low-power state, waiting for a measurement to complete, FALSE otherwise
    readReg (core#CHIP_STAT, 1, @result)
    result := (result == core#CHIP_STAT_SUSPEND)

PUB UVChan(enabled) | tmp
' Enable the UV index source data channel
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    tmp := command (core#CMD_PARAM_QUERY, core#PARM_CHLIST, 0)
    case ||enabled
        0, 1:
            enabled := (||enabled) << core#FLD_EN_UV
        OTHER:
            result := ((tmp >> core#FLD_EN_UV) & %1) * TRUE
            return result

    tmp &= core#MASK_EN_UV
    tmp := (tmp | enabled) & core#PARM_CHLIST_MASK
    command (core#CMD_PARAM_SET, core#PARM_CHLIST, tmp)

PUB VisibleChan(enabled) | tmp
' Enable the visible ambient light source data channel
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    tmp := command (core#CMD_PARAM_QUERY, core#PARM_CHLIST, 0)
    case ||enabled
        0, 1:
            enabled := (||enabled) << core#FLD_EN_ALS_VIS
        OTHER:
            result := ((tmp >> core#FLD_EN_ALS_VIS) & %1) * TRUE
            return result

    tmp &= core#MASK_EN_ALS_VIS
    tmp := (tmp | enabled) & core#PARM_CHLIST_MASK
    command (core#CMD_PARAM_SET, core#PARM_CHLIST, tmp)

PUB VisibleLight
' Return data from visible light channel
    readReg (core#ALS_VIS_DATA0, 2, @result)

PUB command(cmd, param, args) | tmp

    case cmd
        core#CMD_PARAM_QUERY:
            cmd |= param
            tmp := core#CMD_NOP
            writeReg (core#COMMAND, 1, @tmp)
            readReg (core#RESPONSE, 1, @result)
            if result == $00
                writeReg (core#COMMAND, 1, @cmd)
            readReg (core#RESPONSE, 1, @result)
'            if result and not (result & $80)
            readReg (core#PARAM_RD, 1, @result)
            return

        core#CMD_PARAM_SET:
            cmd |= param
            tmp := core#CMD_NOP
            writeReg (core#PARAM_WR, 1, @args)
            writeReg (core#COMMAND, 1, @tmp)
            readReg (core#RESPONSE, 1, @result)
            if result == $00
                writeReg (core#COMMAND, 1, @cmd)
            readReg (core#RESPONSE, 1, @result)
'            if result and not (result & $80)
            readReg (core#RESPONSE, 1, @result)
            return

        core#CMD_NOP, core#CMD_RESET, core#CMD_BUSADDR, core#CMD_PS_FORCE, core#CMD_GET_CAL, core#CMD_ALS_FORCE, core#CMD_PSALS_FORCE,{
        }   core#CMD_PS_PAUSE, core#CMD_ALS_PAUSE, core#CMD_PSALS_PAUSE, core#CMD_PS_AUTO, core#CMD_ALS_AUTO, core#CMD_PSALS_AUTO:
            tmp := core#CMD_NOP
            writeReg (core#COMMAND, 1, @tmp)
            readReg (core#RESPONSE, 1, @result)
            if result == $00
                writeReg (core#COMMAND, 1, @cmd)
            readReg (core#RESPONSE, 1, @result)
            return

PUB readReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
'' Read nr_bytes from the slave device into the address stored in buff_addr
    case reg                                                    'Basic register validation
        $00, $01, $02, $03, $04, $07, $10, $13..$18, $20..$2E, $30:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg

            i2c.start
            i2c.wr_block (@cmd_packet, 2)

            i2c.start
            i2c.write (SLAVE_RD)
            i2c.rd_block (buff_addr, nr_bytes, TRUE)
            i2c.stop
        OTHER:
            return $DEADBEEF

PUB writeReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
'' Write nr_bytes to the slave device from the address stored in buff_addr
    case reg                                                    'Basic register validation
        $00, $03, $04, $07, $10, $13..$18, $20..$2E:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg

            i2c.start
            i2c.wr_block (@cmd_packet, 2)
            repeat tmp from 0 to nr_bytes-1
                i2c.write (byte[buff_addr][tmp])
            i2c.stop
        OTHER:
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
