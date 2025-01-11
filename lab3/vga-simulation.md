# Emulating board events

In addition to the event conventions used for switches,  push-buttons and PS/2 keys that were introduced in __lab 1__ and __lab 2__, so far we have monitored green/red LEDs, 7-segment displays and the character LCD. In this lab we also monitor also the behaviour of the VGA output frame-by-frame. Below are a few important points. 
 
* We use `ppm` files to capture each video frame during simulation. The `ppm` format has a simple 15 byte header (assuming the resolutions and color depths that are supported), followed by R, G, B data for each pixel starting from the top-left corner and moving horizontally to the top-right corner before moving to the next line; and so on line-by-line until the end of the frame.

* Depending on how long the simulation runs, each frame is stored in a `ppm` file in the `data` sub-folder. If multiple frames are simulated, they are labeled `frame0.ppm`, `frame1.ppm`, ... If a frame was not completed during simulation, the corresopnding `ppm` file will be corrupted and hence it should be ignored.

* For timing simulation in __experiment 3__ you should first synthesize the design in Quartus. The Verilog output file (with extension `.vo`), which contains the content of the SRAM cell in every single LUT, I/O cell, ... will be stored in the sub-folder `syn/simulation/modelsim` together with the standard delay output file (with extension `.sdo`). These files will be used by Modelsim to run the timing simulation of the synthesized netlist. This simulation can done by running the `timing.do` file from the `sim` sub-folder.

While the timescales for the events on switches, PS/2 keys, ..., have been adapted to speed-up the simulation, the video frames are simulated on the same timescale as they happen in real-time.