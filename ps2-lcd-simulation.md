# Emulating board events

In addition to the conventions used for switches and push-buttons that were introduced for the sequential circuits from __lab 1__, in this lab we also have board events for the PS/2 keys defined in the `board_events.txt` file. Below are a few key points about the custom format used to define the interactions with a PS/2 keyboard in our custom simulation environment:

* events for PS/2 keys have a `PS` prefix; a specific key is identified through a single letter; for example `PSA` means PS/2 key 'A' was pressed;
* To simplify the parser used by the testbench to control the simulation, in addition to the alphanumerical keys ('A' to 'Z' and '0' to '9'), *only* four additional keys are supported: `PS_` means the Space key was pressed, `PS(` and `PS)` are for left-shift and right-shift respectively and  `PS!` is for Enter; note also, the alphabet keys are identified **only** through upper-case letters ('A', 'B', ..., 'Z');
* The additional arguments for the PS/2 key events in the `board_events.txt` file have the same meaning as for push-buttons, i.e., the time the key was pressed, in terms of microseconds (us) relative to the start of simulation, and the duration the key was kept pressed (also in terms of us).

Consider the following example for `board_events.txt`:

```bash
SW16 300
PB0 8 5
PSA 500 10
SW0 5
PS_ 200 21
...
```
Based on the sequence of events from the above file, the following will occur.

```bash
- switch 0 toggles at 5 us
- push-button 0 pressed at 8 us
- push-button 0 released at 13 us
- PS/2 key space pressed at 200 us
- PS/2 key space released at 221 us
- switch 16 toggles at 300 us
- PS/2 key 'A' pressed at 500 us
- PS/2 key 'A' released at 510 us
...
```
A few additional points are worth making:

* A pulse on the PS2 clock line that is driven by an external hardware keyboard is in the range of approx 100 us. In order to save simulation time, we set the duration of this pulse to 80 nanoseconds (ns) in our simulation environment;
* For real-life keyboards, if a key is kept pressed, the same make code is resent at a pre-defined rate; this feature is **not** supported in our custom simulation environment; rather, the make code is sent only once and, after the key is released, the two bytes of the break code are sent from the testbench to the design; since the time needed to send one byte (assuming a PS2 clock of 80 ns) is just below one microsecond, the total amount of time that should pass before the next key is pressed should be the duration while the key is pressed **plus** the two microseconds needed to send the break-code; it is also important to note that the testbench will probably break if overlapping PS/2 events are specified - in simpler words, for the simulation to make sense you should wait for the time needed for the break code of the previously pressed key to be sent before pressing another key!

* Although in `board_events.txt` we define *only* input events, it is worth making a note about the LCD controller; the external character LCD display can accept a new command every approx five milliseconds (ms); this would obviously place too much burden on simulation time and therefore in our simulation environment we reduce the delay between instructions to only a couple of hundred ns;
