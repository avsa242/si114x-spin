# si114x-spin 
-------------

This is a P8X32A/Propeller driver object for the Silicon Labs Si114x (5, 6, 7) series UV/Proximity/Ambient light sensors.

## Salient Features

* I2C connection at up to 3.4MHz (tested at 400kHz)
* Read ambient light sensor (IR, Visible) raw data
* Read Auxiliary and UV data channels (UV index unverified)
* Flags indicating measurement overflow for IR and visible light sensors
* One-shot and continuous measurement modes
* Set IR and Visible light sensor gains
* Set custom UV index calibration coefficients

## Requirements

* 1 extra core/cog for the PASM I2C driver

## Compiler compatibility

- [x] OpenSpin (tested with 1.00.81)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* Doesn't support proximity sensor function
* Doesn't support interrupts
* Doesn't support alternate slave address usage/programming
* Doesn't support temp sensor/Vdd/Vss reading

## TODO

- [x] Verify reading of ambient light and IR measurements
- [ ] Verify reading of UV Index measurement
- [ ] Cleanup RAM parameter API
- [x] Implement measure rate
- [ ] Implement IR LED current setting
- [ ] Implement interrupt status methods
- [x] Implement methods to enable/disable individual data channels
- [ ] Implement alternate slave address support

