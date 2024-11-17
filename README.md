# si114x-spin 
-------------

This is a P8X32A/Propeller driver object for the Silicon Labs Si114x (5, 6, 7) series UV/Proximity/Ambient light sensors.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.


## Salient Features

* I2C connection at up to 3.4MHz (tested at 400kHz)
* Read ambient light sensor (IR, Visible) raw data
* Read Auxiliary and UV data channels (UV index unverified)
* Flags indicating measurement overflow for IR and visible light sensors
* One-shot and continuous measurement modes
* Set IR and Visible light sensor gains
* Set custom UV index calibration coefficients
* Measure illuminance, in lux
* Proximity sensing


## Requirements

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM I2C engine

P2/SPIN2:
* p2-spin-standard-library


## Compiler Compatibility

| Processor | Language | Compiler               | Backend      | Status                |
|-----------|----------|------------------------|--------------|-----------------------|
| P1        | SPIN1    | FlexSpin (6.9.4)       | Bytecode     | OK                    |
| P1        | SPIN1    | FlexSpin (6.9.4)       | Native/PASM  | OK                    |
| P2        | SPIN2    | FlexSpin (6.9.4)       | NuCode       | OK                    |
| P2        | SPIN2    | FlexSpin (6.9.4)       | Native/PASM2 | OK                    |

(other versions or toolchains not listed are __not supported__, and _may or may not_ work)


## Hardware compatibility

* Tested with Adafruit Si1145 (P/N 1777; EOL)


## Limitations

* Very early in development - may malfunction, or outright fail to build
* Doesn't support alternate slave address usage/programming
* Doesn't support temp sensor/Vdd/Vss reading (not currently planned)
* Measurement calibration/correction/calculation unverified
* Silicon Labs has obsoleted the Si11xx series

