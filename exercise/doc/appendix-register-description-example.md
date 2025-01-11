### Appendix - register description example

| Module (instance) |  Register name | Bits | Description |
| --- | --- |   ---   | --- |
| PB\_controller (PB\_unit) | debounce\_shift\_reg[0] | 10 | shift register used for debouncing the push-button 0 |
| PB\_controller (PB\_unit) |  clock\_1kHz\_div\_count | 16 | clock division counter needed to reduce the sample rate for the push-buttons from 50 MHz down to 1 KHz |
| ... | ... | ... | ... |
| VGA\_controller (VGA\_unit) | H\_Cont | 10 | column counter - keeps track of the pixel position within a line |
| VGA\_controller (VGA\_unit) | V\_Cont | 10 | line counter - keeps track of the line position within a frame |
| ... | ... | ... | ... |
| Top-level experiment 1 | SRAM\_address | 18 | Address register used for accessing the external memory (i.e., the external SRAM organized as 2<sup>18</sup> x 16) |
| Top-level experiment 1 | VGA\_sram\_data [2] | 16 | Buffer register - holds the Red/Green data for the even pixels before it is ready to be transferred to the VGA controller |
| Top-level experiment 1 | state | 4 | State register used by the FSM that coordinates the data transfers to/from the external SRAM and to the VGA controller |
| ... | ... | ... | ... |

The above illustrative example for register description is based on the reference code for **experiment 1**.
