# Emulating board events

The first three labs in this course should normally be concerned **only** with design synthesis and troubleshooting on the physical board. If there is a need to perform these labs in simulation (as it is the case in the days of the *Covid-19* publich health crisis), a custom simulation framework has been developed to facilitate the emulation of board events. This requires quite a few custom files, such as the testbench files from the `tb` sub-folder and the `board_events.txt` file in the `data` sub-folder. The `tb` sub-folder should **not** be changed at this time of the course. However, the meaning of `board_events.txt` is critical for interacting with the testbench and controlling the simulation, and therefore it is described in this document.

The first two experiments from this lab are concerned **only** with combinational circuits. Hence, there is no need to introduce the concept of time in the `board_events.txt` file. Since the 18 switches are the only inputs to the design, they are assumed to be toggled in the same order as they are listed. For example, assuming all the switches are initially in the low position, in the example below, switch 7 is toggled first, then switch 4 is toggled next, followed by switch 10 ...

```bash
SW7
SW4
SW10
...
```
In our custom framework for board simulation, each switch event is assumed to have occurred one microsecond (us) apart. Therefore, the simulation transcript for the above list of events will show:
 
```bash
#     1.00us: switches = 000000000010000000
#     2.00us: switches = 000000000010010000
#     3.00us: switches = 000000010010010000
...
```

The third experiment from this lab is not concerned with an implementation on the DE2-115 board. Hence, there is no need to compile the design in `Quartus` or to use a `board_events.txt` file for emulating the board behaviour. The purpose of this experiment is solely to deepen the understanding of the functionality of hierarchical modulo counters.

For the last two experiments, since we start working with sequential circuits, both the relative time of occurence and the duration of events matter. Therefore, in addition to a boart input indentfier (a switch or a push-button, and its correspnding index), there will be also one or two additional arguments in the corresponding entry in the `board_events.txt` file. For both switches and push-buttons the first argument is the relative time of the event occurrence (in us) since the simulation has started; for switches, this argument states when the switch has been toggled; for push-buttons this argument states when it was pressed. For push-buttons **only**, the second argument states the duration for how long the push-button has been pressed (in us); consequently, after this duration (relative to the time when the push-button has been pressed), another event will be recorded for the release of the push-button.

Another important point is that, since the event timing has been captured with additional arguments, the order of the events in the 
`board_events.txt` file does not matter. Rather it is the first argument after the input identifier that determines when the switch has been toggled or when the push-button has been pressed (the second argument for push-buttons will be also used to determine when the push-button has been released). Consider the following example:

```bash
SW16 1000
PB0 8 5
SW0 5
PB0 200 10
...
```  
In the above example, switch 16 has been toggled at 1000 us (after the simulation has started); push-button 0 has been pressed at 8 us and then released at 13 us; switch 0 has been toggled at 5 us; push-button 0 has been pressed again at 200 us and released at 210 us. Hence, there will be six events in the following order:

```bash
- switch 0 toggles at 5 us
- push-button 0 pressed at 8 us
- push-button 0 released at 13 us
- push-button 0 pressed at 200 us
- push-button 0 released at 210 us
- switch 16 toggles at 1000 us
...
```  

As a final point, it is **CRITICAL** to emphasize that for the first three labs, the time scales of the events that occur in simulation cannot match the time scales of the events that occur in real-time on the physical board. Consider the following example. One full second (1s) of real-time behaviour has 50 million clock pulses (assuming our 20 ns clock pulse). To debug a counter that rolls over after a minute, it would take 60 * 50 million = 3 billion clock cycles of simulation. This is clearly an overkill in terms of CPU runtime needed for simulation. Therefore, the following adjustments have been made for clock dividers in **simulation only** for the last two experiments.

* For the 1Hz counter, 1s of real-time behaviour will be equivalent to 500 clock pulses of 20 ns each (hence 10 us) in simulation.  

* For the 1KHz counter, used for de-bouncing, 1ms of real-time behaviour will be equivalent to 50 clock pulses of 20 ns each (hence 1 us) in simulation. 

The above adjustments, which create a discrepancy between the physical design and the model used in simulation, are **CRITICAL** to manage the CPU runtime needed for simulation. For example, the last two experiments are set-up to run 10ms in simulation, which amounts for a total of 500,000 clock pulses. With the above assumption (500 clock pulses in simulation represent 1s of real-time), we are able to simulate a 1Hz counter for 1000 seconds of real-time operation. Note, however, these simplifying assumptions cannot be generalized for any design (naturally); rather they are a good fit for the types of clock dividers used in this type of experiments.


