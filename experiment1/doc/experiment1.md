### Experiment 1

The purpose of this exercise is to get you familiarized with the Quartus environment and the DE2-115 board. You will find in the **experiment1/rtl** subfolder the design file for the hardware module *experiment1* whose ports are illustrated in Figure 1. For this design we will use 18 input switches, 9 green light emitting diodes (LEDs) and 18 red LEDs.

| ![](design-ports.png) |
|:--:|
|**Figure 1** - Design ports for circuit from *experiment 1*|
<a name="design-ports"></a>

* create a project with device EP4CE115F29C7 from the Cyclone IV family
* select SystemVerilog-2005 as the specification language
* compile the design
* create the pin assignments using the table shown below
* re-compile the design and program the FPGA device

|  Physical Pin |  Design Port | Physical Pin |  Design Port | Physical Pin |  Design Port |
|---|---|---|---|---|---|
| PIN_AB28 | SWITCH\_I[0] | PIN_E21 | LED\_GREEN_O[0] | PIN_G19 | LED\_RED_O[0] |
| PIN_AC28 |	SWITCH\_I[1] | PIN_E22 | LED\_GREEN_O[1] | PIN_F19 | LED\_RED_O[1] |
| PIN_AC27 | SWITCH\_I[2] | PIN_E25 | LED\_GREEN_O[2] | PIN_E19 | LED_RED_O[2] |
| PIN_AD27 | SWITCH\_I[3] | PIN_E24 | LED\_GREEN_O[3] | PIN_F21 | LED\_RED_O[3] |
| PIN_AB27 | SWITCH\_I[4] | PIN_H21 | LED\_GREEN_O[4] | PIN_F18 | LED\_RED_O[4] |
| PIN_AC26 | SWITCH\_I[5] | PIN_G20 | LED\_GREEN_O[5] | PIN_E18 | LED\_RED_O[5] |
| PIN_AD26 | SWITCH\_I[6] | PIN_G22 | LED\_GREEN_O[6] | PIN_J19 | LED\_RED_O[6] |
| PIN_AB26 | SWITCH\_I[7] | PIN_G21 | LED\_GREEN_O[7] | PIN_H19 | LED\_RED_O[7] |
| PIN_AC25 | SWITCH\_I[8] | PIN_F17 | LED\_GREEN_O[8] | PIN_J17 | LED\_RED_O[8] |
| PIN_AB25 | SWITCH\_I[9] | | | PIN_G17 | LED\_RED_O[9] |
| PIN_AC24 | SWITCH\_I[10] | | | PIN_J15 | LED\_RED_O[10] |
| PIN_AB24 | SWITCH\_I[11] | | | PIN_H16 | LED\_RED_O[11] |
| PIN_AB23 | SWITCH\_I[12] | | | PIN_J16 | LED\_RED_O[12] |
| PIN_AA24 | SWITCH\_I[13] | | | PIN_H17 | LED\_RED_O[13] |
| PIN_AA23 | SWITCH\_I[14] | | | PIN_F15 | LED\_RED_O[14] |
| PIN_AA22 | SWITCH\_I[15] | | | PIN_G15 | LED\_RED_O[15] |
| PIN_Y24  | SWITCH\_I[16] | | | PIN_G16 | LED\_RED_O[16] |
| PIN_Y23  | SWITCH\_I[17] | | | PIN_H15 | LED\_RED_O[17] |

You have to perform the following tasks in the lab for this experiment:

* check if the logic functions for signals NOT, AND2, OR2, AND3 and OR3 work correctly
* create the logic functions for NAND4 and NOR4 between input switches 8 to 11
* create a logic function AND\_OR that has both AND/OR operations using switches 4 to 7 (for the AND\_OR function, the first two and the last two inputs are ANDed and then the results are ORed)
* create a logic function AND\_XOR that has both AND/XOR operations using switches 0 to 3 (for the AND\_XOR function, the first two and the last two inputs are ANDed and then the results are XORed)
