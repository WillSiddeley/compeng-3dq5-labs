### Exercise 1

Modify the design from __experiment 3__ as follows. In the first and the second DP-RAMs there are two different arrays (called W and X respectively) of 8-bit signed integers. Each of these two arrays has 512 elements (initialized the same way as in the lab, i.e., using memory initialization files). Design the circuit that computes two arrays Y and Z defined as follows (for every _k_ from 0 to 255):

Y[_k_] = W[_k_+256] - X[_k_]

Z[_k_] = W[_k_] + X[_k_+256]

Y[_k_+256] = W[_k_] - X[_k_+256]

Z[_k_+256] = W[_k_+256] + X[_k_]

Each element Y[_i_] should overwrite the corresponding element W[_i_] in the first DP-RAM (for every _i_ from 0 to 511); likewise, each Z[_i_] should overwrite the X[_i_] in location _i_ in the second DP-RAM. As for the in-lab experiment, if the arithmetic overflow occurs, as a direct consequence of the additions/subtractions, it is not necessary to detect it, i.e., keep the 8 least significant bits of the result. The above calculations should be implemented in as few clock cycles as it can be facilitated by the two DP-RAMs.

For this exercise only, in your report you __MUST__ discuss your resource usage in terms of registers. You should relate your estimate to the register count from the compilation report in Quartus. You should also inspect the critical path either in the Timing Analyzer menu, as shown in the videos on circuit implementation and timing from **lab** 3, or by inpsecting the `.sta.rpt` file from the `syn/output_files` sub-folder, which contains the same info as displayed in the Timing Analyzer menu. Based on your specific design structure you should provide your interpretation for the critical path in your design. Finally, you should also provide your most reasonable explanation for the total number of logic elements reported by Quartus, nonetheless it is important to emphasize that you will not be explicitly assessed for this last explanation.

Submit your sources and in your report write approx half-a-page (but not more than full-page) that describes your reasoning. Your sources should follow the directory structure from the in-lab experiments (already set-up for you in the `exercise1` folder); note, your report (in `.pdf`, `.txt` or `.md` format) should be included in the `exercise1/doc` sub-folder. Note also, your design must pass compilation in Quartus before you simulate it and you write the report.

Your submission is due 14 hours before your next lab session. Late submissions will be penalized.

