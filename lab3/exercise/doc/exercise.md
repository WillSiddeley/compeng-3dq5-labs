### Exercise

Afer the changes to __experiment 4__ have been applied, provide support for the following spec. You must display the characters for the first 31 keys that were pressed on the PS/2 keyboard. Note, however, we assume only keys A, B, C, D, E and F are monitored; consequently, if a PS/2 key that is not listed above has been pressed, you should display space. Assume also the 31 character message is displayed on the same character row (you can choose an arbitrary position where to display it so long as the full message is visible). More importantly, your design must identify the monitored key (i.e., one of the keys from A to F) that has been pressed __most__ times and display an extra message, as clarified through the examples below. Note, in the case that two or more keys have been pressed an equal number of times, the character that is ahead in alphabetical order takes precedence. The following examples are used to clarify the problem statement:

_Example 1_ - Assume the following 31 keys have been pressed (leftmost key was pressed first):

`A0BCDEF1A2BC1DE3AXBYCDEFA4B5ABA`

Then the 31 character message to be displayed is:

`A BCDEF A BC DE A B CDEFA B ABA`

Note above that characters associated with the keys that are not monitored do not need to be displayed; rather you should display space (i.e., ` `) instead. 

The following message should also be displayed in an arbitrary position on the screen (the starting character row does not matter so long as the message is visible).

`KEY A PRESSED  6 TIMES`

_Example 2_ - For the remaining examples, we will ignore the specific details of the 31 character message itself and we will focus only on what should displayed for the most pressed key. If in the 31 character message character A appears 7 times, B appears 12 times and C appears 12 times then display the following:

`KEY B PRESSED 12 TIMES`

Note, in the above example keys B and C are tied in the number of times they have been pressed, hence B takes precedence because of the alphabetical order. Note also, as you can see from the example above, in case a key has been pressed more than 9 times, then the value associated with the number of times it has been pressed should be displayed in binary-coded decimal (BCD) format.

_Example 3_ - If none of the monitored keys have been pressed then display:

`NO MONITORED KEYS PRESSED`

In simulation you should schedule the PS/2 key events such that the registers that hold the history of the keystrokes are updated __ONLY__ during the vertical blanking interval. Hence, the messages to be displayed for a frame should be decided before the end of the vertical blanking interval. To make the simulation faster, it is recommended that all the 31 keystrokes are scheduled in `board_events.txt` before the end of the first vertical blanking period. Hence, only one full frame needs to be simulated to produce the `.ppm` file in the `exercise/data` sub-folder.

In your report you __MUST__ discuss your resource usage in terms of registers. You should relate your estimate to the register count from the compilation report in Quartus.

Submit your sources and in your report write approx half-a-page (but not more than a full-page) that describes your reasoning. Your sources should follow the directory structure from the in-lab experiments (already set-up for you in the `exercise` folder); note, your report (in `.pdf`, `.txt` or `.md` format) should be included in the `exercise/doc` sub-folder. Note also, your design must pass compilation in Quartus before you simulate it and you write the report.

Your submission is due 14 hours before your next lab session. Late submissions will be penalized.

