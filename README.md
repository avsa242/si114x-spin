# si114x-spin 
-------------

This is a P8X32A/Propeller driver object for the Silicon Labs Si114x (5, 6, 7) series UV/Proximity/Ambient light sensors.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or ~~[p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P)~~. Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 3.4MHz (tested at 400kHz)
* Read ambient light sensor (IR, Visible) raw data
* Read Auxiliary and UV data channels (UV index unverified)
* Flags indicating measurement overflow for IR and visible light sensors
* One-shot and continuous measurement modes
* Set IR and Visible light sensor gains
* Set custom UV index calibration coefficients

## Requirements

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM I2C driver

~~P2/SPIN2:~~
* ~~p2-spin-standard-library~~

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* ~~P2/SPIN2: FastSpin (tested with 5.0.0)~~ _(not yet implemented)_
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* Doesn't support proximity sensor function
* Doesn't support interrupts
* Doesn't support alternate slave address usage/programming
* Doesn't support temp sensor/Vdd/Vss reading (not currently planned)

## TODO

- [x] Verify reading of ambient light and IR measurements
- [ ] Verify reading of UV Index measurement
- [ ] Cleanup RAM parameter API
- [x] Implement measure rate
- [ ] Implement IR LED current setting
- [ ] Implement interrupt status methods
- [x] Implement methods to enable/disable individual data channels
- [ ] Implement alternate slave address support
- [ ] Update API for consistency with other drivers
- [ ] Port to P2/SPIN2
