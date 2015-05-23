xCore 200 eXplorerKit - Demo Webapp
===================================

Application for demonstrating the integrated possibilities of the xCore 200 eXplorerKit. 

- Live streaming and Graphing of Accelerometer readings
- Toggling onboard RGB and Green LEDs via the web interface
- View status of onboard Pushbuttons

Makes use of AJAX calls to the integrated webserver for status updates. Graphing of Accelerometer readings using SmoothieCharts Javascript Library.

Uses Xmos provided libraries: 
.............................

lib_ethernet lib_otpinfo lib_xtcp lib_webserver lib_i2c


Tile Usage:
...........

Constraint check for tile[0]:
  Cores available:            8,   used:          4 .  OKAY
  Timers available:          10,   used:          4 .  OKAY
  Chanends available:        32,   used:          9 .  OKAY
  Memory available:       262144,   used:      117476 .  OKAY
  Stack: 4940, Code: 34948, Data: 77588

Constraint check for tile[1]:
  Cores available:            8,   used:          8 .  OKAY
  Timers available:          10,   used:          8 .  OKAY
  Chanends available:        32,   used:         22 .  OKAY
  Memory available:       262144,   used:      110524 .  OKAY
  Stack: 78276, Code: 22588, Data: 9660


