# si114x-spin 
---------------

This is a P8X32A/Propeller driver object for the Silicon Labs Si114x (5, 6, 7) series UV/Proximity/Ambient light sensors.

## Salient Features

* I2C connection at up to 3.4MHz (tested at 400kHz)

## Requirements

* 1 extra core/cog for the PASM I2C driver

## Limitations

* Very early in development - may malfunction, or outright fail to build

## TODO

- [x] Verify reading of ambient light and IR measurements
- [ ] Verify reading of UV Index measurement
- [ ] Cleanup RAM parameter API
- [ ] Implement measure rate
- [ ] Implement IR LED current setting
- [ ] Implement interrupt status methods
- [ ] Implement methods to enable/disable individual data channels
- [ ] Implement alternate slave address support

