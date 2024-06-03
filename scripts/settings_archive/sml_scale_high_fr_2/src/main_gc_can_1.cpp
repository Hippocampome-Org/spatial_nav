/* * Copyright (c) 2016 Regents of the University of California. All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* 1. Redistributions of source code must retain the above copyright
*    notice, this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright
*    notice, this list of conditions and the following disclaimer in the
*    documentation and/or other materials provided with the distribution.
*
* 3. The names of its contributors may not be used to endorse or promote
*    products derived from this software without specific prior written
*    permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
* CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
* EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
* PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
* LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
* *********************************************************************************************** *
* CARLsim
* created by: (MDR) Micah Richert, (JN) Jayram M. Nageswaran
* maintained by:
* (MA) Mike Avery <averym@uci.edu>
* (MB) Michael Beyeler <mbeyeler@uci.edu>,
* (KDC) Kristofor Carlson <kdcarlso@uci.edu>
* (TSC) Ting-Shuo Chou <tingshuc@uci.edu>
* (HK) Hirak J Kashyap <kashyaph@uci.edu>
*
* CARLsim v1.0: JM, MDR
* CARLsim v2.0/v2.1/v2.2: JM, MDR, MA, MB, KDC
* CARLsim3: MB, KDC, TSC
* CARLsim4: TSC, HK
* CARLsim5: HK, JX, KC
*
* CARLsim available from http://socsci.uci.edu/~jkrichma/CARLsim/
* Ver 12/31/2016
*
*
* code added by Nate Sutton
* references:
* http://www.cplusplus.com/forum/general/34780/
* https://en.wikipedia.org/wiki/Gompertz_function
*/

// include CARLsim user interface
#include <carlsim.h>
#include <neuron_monitor_core.h>
#include <vector>
#include <spike_monitor.h>
#include <math.h> // for sqrt() and other functions
#include <string> // for to_string()
#include <cstring>
#include <sstream>
#include <iostream>
#include <fstream> // for file out
using namespace std;
#include "../data/ext_dir_initial.cpp"
#include "../data/ext_dir.cpp"
#include "../data/init_firings.cpp"
#include "../general_params.cpp"
#if supcomp_compat
	vector<vector<double>> mex_hat;
#else
	#if import_animal_data
		#include "../data/anim_angles.cpp"
		#include "../data/anim_speeds.cpp"
		#include "../data/synapse_weights.cpp"
	#endif
#endif
#if use_saved_g_to_i_conns
	vector<vector<int>> in_conns_list;
#endif
#include "../place_cells.cpp"
#include "../general_funct.cpp"
#include "../move_path.cpp"
//#include "boundary_cells.cpp"

int main() {
	// ---------------- CONFIG STATE -------------------
	// create a network on GPU
	struct P p;	
	int numGPUs = 1;
	int randSeed = 42;
	CARLsim sim("gc can", GPU_MODE, USER, numGPUs, randSeed);
	//CARLsim sim("gc can", CPU_MODE, USER);
	int n_num;
	#if supcomp_compat
		ParseCSV("./data/synapse_weights.csv", &mex_hat);
	#endif
	#if use_saved_g_to_i_conns
		vector<vector<int>> weights_in_temp3(p.layer_size, vector<int>(p.layer_size_in));
		in_conns_list = weights_in_temp3;
		for (int i = 0; i < p.layer_size; i++) {for (int j = 0; j < p.layer_size_in; j++) {in_conns_list[i][j]=0.0;}}
		ParseCSVInts("./data/grc_to_in_conns.csv", &in_conns_list);
	#endif
	std::vector<std::vector<float>> inec_weights;
	double noise_addit_freq = 0.0;
	if (p.noise_active) {noise_addit_freq = p.noise_addit_freq;}
	for (int i = 0; i < (p.x_size*p.y_size); i++) {
		p.animal_location_all[i] = 0.0; // initialize
	}
	// initialize matrix
	vector<vector<double>> weights_in_temp(p.layer_size_in, vector<double>(p.layer_size)); // set size
	p.weights_in = weights_in_temp;
	for (int i = 0; i < p.layer_size; i++) {
		for (int j = 0; j < p.layer_size; j++) {p.weights_in[i][j]=0.0;}
	}
	vector<vector<int>> weights_in_temp2(p.layer_size, vector<int>(p.layer_size_in));
	p.in_conns_binary = weights_in_temp2;
	for (int i = 0; i < p.layer_size; i++) {
		for (int j = 0; j < p.layer_size_in; j++) {p.in_conns_binary[i][j]=0.0;}
	}
	vector<float> temp_vector(p.layer_size); // set vector size
	p.ext_dir = temp_vector;
	p.pc_activity = temp_vector;
	for (int i = 0; i < p.layer_size; i++) {
		p.locations_visited.push_back(0);
		p.locations_sortind.push_back(0);
		p.locations_amounts.push_back(0);
		if (p.print_conn_stats) {p.in_conns.push_back(0);}
	}
	if (p.print_conn_stats) {for (int i = 0; i < p.layer_size_in; i++) {p.gc_conns.push_back(0);}}
	#if supcomp_compat
		#if import_animal_data
			vector<double> anim_angles = ParseCSV(p.anim_angles_csv);
			vector<double> anim_speeds = ParseCSV(p.anim_speeds_csv);
		#endif
	#endif

	#include "../generate_config_state.cpp" // include file that contains generation of groups and their properties
	sim.setIntegrationMethod(RUNGE_KUTTA4, 40);
	// ---------------- SETUP STATE -------------------
	// build the network
	sim.setupNetwork();
	setInitExtDir(&p); // Initial excitatory current to GCs
	sim.setExternalCurrent(EC_LI_II_Multipolar_Pyramidal, ext_dir_initial);
	//sim.setExternalCurrent(MEC_LII_Basket_Speed, ext_dir_initial);
	SpikeMonitor* SMexc = sim.setSpikeMonitor(MEC_LII_Stellate, "DEFAULT");
	#if spk_mon_additional
		SpikeMonitor* SMext = sim.setSpikeMonitor(EC_LI_II_Multipolar_Pyramidal, "DEFAULT");
		SpikeMonitor* SMbsk = sim.setSpikeMonitor(MEC_LII_Basket, "DEFAULT");
		SpikeMonitor* SMaxa = sim.setSpikeMonitor(EC_LII_Axo_Axonic, "DEFAULT");
		SpikeMonitor* SMbmu = sim.setSpikeMonitor(EC_LII_Basket_Multipolar, "DEFAULT");
		SpikeMonitor* SMpyr = sim.setSpikeMonitor(CA1_Pyramidal, "DEFAULT");
	#endif
	if (p.record_spikes_file && p.move_animal_onlypos==0) {p.spikes_output_file.open(p.spikes_output_filepath);}
	if (p.record_in_spikes_file && p.move_animal_onlypos==0) {p.in_spikes_output_file.open(p.in_spikes_output_filepath);}
	if (p.record_highrestraj) {p.highres_pos_x_file.open(p.highres_pos_x_filepath);}
	if (p.record_highrestraj) {p.highres_pos_y_file.open(p.highres_pos_y_filepath);}

	if (p.print_conn_stats) {
		vector<double> in_stats, gc_stats;
		get_stats(p.in_conns, &in_stats);
		get_stats(p.gc_conns, &gc_stats);
	    printf("GrC->IN Connections: avg=%.02f std=%.02f min=%.02f max=%.02f layer_size=%.02f min_i=%.02f max_i=%.02f\n\n",in_stats[0],in_stats[1],in_stats[2],in_stats[3],in_stats[4],in_stats[5],in_stats[6]);
	    printf("IN->GrC Connections: avg=%.02f std=%.02f min=%.02f max=%.02f layer_size=%.02f min_i=%.02f max_i=%.02f\n\n",gc_stats[0],gc_stats[1],gc_stats[2],gc_stats[3],gc_stats[4],gc_stats[5],gc_stats[6]);
	}
	if (p.save_grc_to_in_conns) {write_grc_to_in_file(&p);}

	// ---------------- RUN STATE -------------------
	SMexc->startRecording();
	SMexc->setPersistentData(true); // keep prior firing when recording is stopped and restarted
	#if spk_mon_additional
		SMext->startRecording(); SMext->setPersistentData(true);
		SMbsk->startRecording(); SMbsk->setPersistentData(true);
		SMaxa->startRecording(); SMaxa->setPersistentData(true);
		SMbmu->startRecording(); SMbmu->setPersistentData(true);
		SMpyr->startRecording(); SMpyr->setPersistentData(true);
	#endif
	for (int i = 0; i < p.layer_size; i++) {
		p.gc_firing[i] = init_firings[i]; // set initial firing
	}
	
	#if import_animal_data
		animal_data_vars(&sim, &p, &anim_angles, &anim_speeds);
	#endif	

	if (p.move_fullspace) {move_fullspace2(&sim, &p);p.run_path=1;}
	if (p.move_circles) {move_circles(&sim, &p);p.run_path=1;}

	for (int t=0; t<p.sim_time; t++) {	
		p.t = t;
		// Disable initial current to GCs settings
		if (t == 2) {
			//setExtDir(&p,270,0.04,0);
			//sim.setExternalCurrent(EC_LI_II_Multipolar_Pyramidal, p.ext_dir);
			//setExtDir(&p,270,0.04,1);
			//sim.setExternalCurrent(MEC_LII_Basket_Speed, p.ext_dir);
		}
		if (p.move_animal_onlypos==0 && p.run_path_onlypos==0) {sim.runNetwork(0,1,false);} // run for 1 ms, don't generate run stats
		if (p.record_fire_vs_pos || (p.record_spikes_file && p.move_animal_onlypos==0) || p.print_in_weights || p.print_gc_firing) {
			SMexc->stopRecording();
			p.nrn_spk = SMexc->getSpikeVector2D(); // store firing in vector
			SMexc->startRecording();
		}
		#if spk_mon_additional
			if (p.record_in_spikes_file && p.move_animal_onlypos==0) {
				SMbsk->stopRecording();
				p.in_nrn_spk = SMbsk->getSpikeVector2D(); // store firing in vector
				SMbsk->startRecording();
			}
		#endif
		if (p.move_animal_onlypos==0) {
			if (p.move_animal) {move_animal(&sim, &p, &anim_angles, &anim_speeds);}
			if (p.move_animal_aug) {move_animal_aug(&sim, &p);}
			else if (p.run_path) {
				if (p.run_path_onlypos) {run_path_onlypos(&p.angles, &p.speeds, &p.speed_times, p.num_moves, p.num_speeds, &sim, &p);}
				else {run_path(&p.angles, &p.speeds, &p.speed_times, p.num_moves, p.num_speeds, &sim, &p);}
			}
			if (p.move_speed_change) {move_speed_change(&sim, &p);}
			if (p.move_straight) {move_straight(&sim, &p);}
			if (p.move_random) {move_random(&sim, &p);}
			if (p.move_ramp) {move_ramp(&sim, &p);}
			if (false && p.t % 20 == 0) {printf("%d %f %f\n",p.t,anim_speeds[floor(((int) p.t)/20)],anim_angles[floor(((int) p.t)/20)]);}
		}
		#if import_animal_data
			if (p.move_animal_onlypos==1) {
				if (p.move_animal_aug && p.t < p.animal_aug_time) { // cut off if using aug
					  move_animal_onlypos(&sim, &p, &anim_angles, &anim_speeds);}
				else {move_animal_onlypos(&sim, &p, &anim_angles, &anim_speeds);} // no cut off
				if (p.move_animal_aug) {move_animal_aug(&sim, &p);} 
			}
		#endif
		PrintWeightsAndFiring(&p);
		RecordNeuronVsLocation(&sim, &p);
		if (p.record_highrestraj) {HighResTraj(&sim, &p);}
		if (p.record_pos_track) {RecordLocationPath(&p, "current");}
		if (p.record_pos_track_all) {RecordLocationPath(&p, "all");}
		if (p.print_time && ((t < 1000 && t % 100 == 0) || (t % 1000 == 0))) {printf("t: %dms\n",t);}
	}
	SMexc->stopRecording();
	printf("\n\n");
	SMexc->print(false); // print firing stats (but not the exact spike times)	
	#if spk_mon_additional
		SMext->stopRecording(); SMext->print(false);
		SMbsk->stopRecording(); SMbsk->print(false);
		SMaxa->stopRecording(); SMaxa->print(false);
		SMbmu->stopRecording(); SMbmu->print(false);
		SMpyr->stopRecording(); SMpyr->print(false);
	#endif
	if (p.record_spikes_file && p.move_animal_onlypos==0) {p.spikes_output_file.close();}
	if (p.record_in_spikes_file && p.move_animal_onlypos==0) {p.in_spikes_output_file.close();}
	if (p.record_highrestraj) {p.highres_pos_x_file.close();}
	if (p.record_highrestraj) {p.highres_pos_y_file.close();}

	return 0;
}
