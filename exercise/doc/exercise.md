### Take-home exercise

**Experiment 3** has introduced binary-coded decimal (BCD) counters, which are base 10 (modulo 10) counters and that are often used to display hours, minutes and seconds in a human readable format. Although base 5 does not have similar practical applications, it can be used to consolidate the understanding of hierachical modulo counters, which have broad applications in implementing generators for periodic signals or to design address generators in data-intensive applications.

In this take-home exercise modify the up/down counter from **experiment 5** as follows.

Only the two least significant 7-segment displays are used and they display the counter value in base 5. It is assumed that the range of values in unsigned decimal format is 0 to 24, which is the full range of values that can be represented in 2-digit base 5 format. To accomodate for this change, the counter circuit must be modified to update every second in 2-digit base 5 format within the range 00 to 44 (in base 5). Its functionality can be summarized in the following table:

|  unsigned decimal value |  base 5 representation in 2-digit base 5 format displayed on the two 7-segment displays | binary representation used to determine what gets displayed on the two 7-segment displays |
| --- | --- |   ---   |
|  0  |  00 | 000 000 |
| ... | ... |   ...   |
|  4  |  04 | 000 100 |
|  5  |  10 | 001 000 |
| ... | ... |   ...   |
|  9  |  14 | 001 100 |
|  10 |  20 | 010 000 |
| ... | ... |   ...   |
| ... | ... |   ...   |
|  24 |  44 | 100 100 |
 
As it can be observed in the last column from the above table, each of the two base 5 digits is represented on 3 bits (covering the range 000 to 100 in binary). Take note of the following clarifications: 

- The functionality of push-buttons 0, 1 and 2 should be exactly the same as specified for the in-lab **experiment 5**;
- When counting up and the maximum value (i.e., 44 in 2-digit base 5 format) has been reached, the counter should roll over to its minumum value (i.e., 00 in 2-digit base 5 format) and continue counting up until one of the above-mentioned push-buttons has been pressed (see their meaning in **experiment 5**);
- When counting down and the minimum value has been reached, the counter should roll over to its maximum value and continue counting down until one of the above-mentioned push-buttons has been pressed;
- On power-up assume the counter is active, its value is zero, and the counting direction us up.

In addition to the above, in this take-home exercise the green LEDs should be driven as follows:

- Green LED 8 is always lightened (logic one);
- Green LED 7 is lightened only if the number of switches from group 15 down to 0 that are in the high position (logic one) is an even number;
- Green LED 6 is lightened only if switches 15 down to 8 are all in the high position and if switches 7 down to 0 are all in the low position (logic zero);
- Green LED 5 is lightened only if at least one of the switches 15 down to 8 is in the low position;
- Green LED 4 is lightened only if at least one of the switches 7 down to 0 is in the high position;
- If switch 15 is in the high position green LEDs 3 down to 0 display the position (or index) of the least significant switch that is in the high position from the group of switches 15 down to 0;
- If switch 15 is in the low position green LEDs 3 down to 0 display the position (or index) of the least significant switch that is in the low position from the group of switches 15 down to 0;

Submit your sources and in your report write approx half-a-page (but not more than a full-page) that describes your reasoning. Your sources should follow the directory structure from the in-lab experiments (already set-up for you in the `exercise` folder); note, your report (in `.pdf`, `.txt` or `.md` format) should be included in the `exercise/doc` sub-folder. Note also, your design must pass compilation in Quartus before you simulate it and you write the report.

Your submission is due 14 hours before your next lab session. Late submissions will be penalized.

