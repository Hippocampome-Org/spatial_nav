This experiment is meant to recreate the real cell from the
Schopenhauer mouse at tetrode 5 and cell 1.
That real cell had a grid scroe of 0.257698 and
mean firing rate of 4.339480.

This experiment produces results with its cell #547
that has a grid score of 0.316587 and
maen firing rate of 4.339100.

The physical space plots compared between the real and
simulated cell are decently similar. More work can be
done if wanted to improve on the simulated cells similarity
with its physical space appearance and connected
firing rate results but this is a reasonable starting place
for a recreation.

It is important to note that this simulated cell uses
the variable speed_conversion = 0.73 (general_params.cpp)
and resolution_converter = 1.37 with plot_shift = 4
(gridscore_sim_run_local.m). 1.37 ~= 1/0.73.