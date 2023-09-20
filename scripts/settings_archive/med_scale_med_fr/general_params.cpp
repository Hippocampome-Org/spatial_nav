/*
	General parameters
*/

#define PI 3.14159265

struct P {
	double sim_time = 250000;//8485920;//8485920;//1440140;//1440140;//8553860;//131400;//8485920;//120000//29416*20;//60000*firing_bin;// sim run time in ms
	int timestep = 20; // timestep between movements. e.g., 20ms between each movement command
	int t = 0; // time
	static const int x_size = 40;//36;//42;//30;//26;
	static const int y_size = 40;//36;//42;//30;//26;
	static const int layer_size = x_size * y_size;
	static const int EC_LI_II_Multipolar_Pyramidal_Count = 1600;//1764;//900;
	static const int MEC_LII_Stellate_Count = 1600;//1764;//900;
	static const int EC_LII_Axo_Axonic_Count = 834;//834;//1200;//646;//534;//588;//300;
	static const int MEC_LII_Basket_Count = 833;//833;//1200;//645;//533;//588;//300;
	static const int EC_LII_Basket_Multipolar_Count = 833;//833;//1200;//645;//533;//588;//300;
	static const int layer_size_in = EC_LII_Axo_Axonic_Count+MEC_LII_Basket_Count+EC_LII_Basket_Multipolar_Count;
	static const int CA1_Pyramidal_Count = 1600;//1764;//900;
	static const int MEC_LII_Basket_Speed_Count = 1600;//1764;//900;
	static const int MEC_LII_Stellate_Speed_Count = 1600;//1764;//900;	
	int EC_LI_II_Multipolar_Pyramidal_Group, MEC_LII_Stellate_Group, EC_LII_Axo_Axonic_Group,
	MEC_LII_Basket_Group, EC_LII_Basket_Multipolar_Group, CA1_Pyramidal_Group, 
	MEC_LII_Basket_Speed_Group,	MEC_LII_Stellate_Speed_Group;	
	double pos[2] = {27.5,12.5};//{21,27};//{28.5,16.75};//{27.5,12.5};//{21,27};//{21,23};//{21,27};//{27.5,12.5};//{21,27};//{27.5,12.5};//{21,27};//{27.5,12.5};//{28.5,16.75};//{21,27};//{23.5,12.5};//{27.5,12.5};//{28.5,16.75};//{26.5,12.5};//{30,20};//{22,7.75};//{30,18};//{9,17};//{22,8}; // virtual animal position tracker. starting position: {x,y}
	double bpos[2] = {27.5,12.5};//{21,27};//{28.5,16.75};//{27.5,12.5};//{21,27};//{21,23};//{21,27};//{27.5,12.5};//{21,27};//{27.5,12.5};//{21,27};//{27.5,12.5};//{28.5,16.75};//{21,27};//{23.5,12.5};//{27.5,12.5};//{28.5,16.75};//{26.5,12.5};//{30,20};//{22,7.75};//{9,17}; // bump position tracker
	double dirs[4] = {0, 90, 180, 270};
	double mi = 0; // move list index
	vector<vector<int>> nrn_spk; // for total firing recording
	vector<vector<int>> in_nrn_spk; // for total firing recording
	vector<vector<double>> weights_in; // IN-GC weights
	vector<vector<float>> inec_weights;
	ostringstream pos_x;
	ostringstream pos_y;
	double gc_firing[layer_size]; // gc spiking amount
	double gc_firing_bin[layer_size]; // gc spiking amount in time bins
	string spikes_output_filepath = "output/spikes/spikes_recorded.csv";
	string in_spikes_output_filepath = "output/spikes/in_spikes_recorded.csv";
	string highres_pos_x_filepath = "output/spikes/highres_pos_x.csv";
	string highres_pos_y_filepath = "output/spikes/highres_pos_y.csv";
	ofstream spikes_output_file;
	ofstream in_spikes_output_file;
	ofstream highres_pos_x_file;
	ofstream highres_pos_y_file;

	// animal data parameters
	#define hopper_run 1 // import data differently if on hopper
	string anim_angles_csv = "./data/anim_angles.csv";
	string anim_speeds_csv = "./data/anim_speeds.csv";
	#define import_animal_data 1 // 1 for import and 0 for no import
	int animal_ts = 20; // timestep in ms
	vector<double> anim_angles;
	vector<double> anim_speeds;
	vector<int> speed_times;
	vector<double> angles;
	vector<double> speeds;
	int num_moves;
	int num_speeds;

	// animal move aug parameters
	int animal_aug_time = sim_time * 0.75; // when to start movement augs
	double percent_for_aug = 0.25; // percent of total envorinment locations to add as augmented moves
	bool print_aug_values = 0;
	vector<double> x_aug; // positions coordinates to travel to
	vector<double> y_aug;
	vector<int> locations_sortind; // binned firing locations sorted indices
	vector<int> locations_amounts; // amount of firing in indices
	int aug_i = 0; // aug target counter
	int aug_m = 0; // aug move counter

	// select movement trajectory
	bool run_path = 0; // use run_path function. This is auto enabled by functions that use it.
	bool run_path_onlypos = 0; // only generate movement positions not signaling with run_path function
	bool move_animal = 0; // use real animal movement positions with neural signaling
	bool move_animal_aug = 0; // augment animal movement
	bool move_animal_onlypos=0; // generate animal movement position but not signaling
	bool move_speed_change=0; // test series of speed changes
	bool move_fullspace = 1; // move through whole environment
	bool move_straight = 0;
	bool move_circles = 0;
	bool move_random = 0;
	bool move_ramp = 0;

	// common parameters that can vary per each run
	bool print_move = 0; // print each move's direction
	bool print_time = 1; // print time after processing
	bool print_in_weights = 0;
	bool print_gc_firing = 0;
	bool record_fire_vs_pos = 0; // write files for firing vs position plotting
	bool record_pos_track = 0; // write files for animal position tracking plotting
	bool record_pos_track_all = 0; // write files for animal positions with no past posit. clearing
	bool record_spikes_file = 0; // write file for grid cell spike times and neuron positions
	bool record_in_spikes_file = 0; // write file for interneuron spike times and neuron positions
	bool record_highrestraj = 1; // write files for high resolution trajectory locations
	#define spk_mon_additional 0 // additional spike monitors
	#define monitor_voltage 0 // turn voltage monitoring on or off 
	int rotation_mod = 0; // modify direction signaling to accomidate a rotated grid pattern
	double angle_rot = 0.0;//11;//10;//20;//20;//20;//15;//30;//20;//20;//0;//20;//32;//10;//-30;//-10;//-18;//0;//-16;//-15;//18;//20;//18;//18;//19;//20;//11;//+4.5;//+7; // angle in degrees of rotation offset to use in rotation_mod
	bool pc_active = 1; // pc signaling active. bc->pc->gc can still work even if this is disabled.
	bool pc_to_gc = 1; // place cells to grid cells signaling

	// values for synapse activites
	double base_ext = 300;//300;//200;//300;//550;//350;//550;//450;//750;//400;//500;//800;//530;//500;//450;//500;//500;//500;//450;//500;//450;//450;//375;//350;//350;//250;//250;//350;//250;//500;//2000;//160;//350;//650;//800;//550;//150;//150;//550;//1500;//550;//750;//950;//550;//200;//250; // baseline ext input speed level	
	double speed_signaling = .45;//0.275;//0.25;//2.0;//1.4;//0.25;//0.02;//10.0;//2.0;//0.5;//0.5;//5;//0.35;//1.0;//0.5;//.5; // setting for use of a constant virtual animal speed
	double fast_to_slow_ratio = 0.38/0.62;
	double dir_to_grc_g_fast = 33.082*1.1*0.3195;//.33;//.36;//.43;//.5;//.25;//33.082*1.1*.58;//.62;//.65;//.3;//.65;//0.58;//.35;//.13;//.25;//.2;//.22;//.22;//.25;//.29;//.29;//.275;//.29;//.3;//.24;//.36;//.3;//.2;//.31;//*.25;//.47;//.6;//.8;//.6;//.35;//.22;//.6;//.35;//.13;//.15;//.35;//.4;//.35;//.47;
	double dir_to_grc_g_slow = dir_to_grc_g_fast*fast_to_slow_ratio;
	double grc_to_in_g_fast = 0.8244568522+((1.952544646-0.8244568522)*0.2);//*0.5);//*1);//*0.4703810748);//*0.5);//*0.4703810748);//(1/0.8645));//3;//2;//1;//.8;//.36505;//.6;//.8;//.8;//1.0;//.9;//0.85;//0.8;//0.6;//0.8;//0.5;//0.8;//.36505;//0.45;//0.65;//0.55;//0.5;//0.6;//0.45;//.36505;//0.4;//.36505;//0.5;//.36505;//0.65;//0.8;//.36505;//0.5;//0.8;//0.5;//0.9;//0.8;//.36505; // range is perhaps *.36505 to *0.8645 (0.8244568522 to 1.952544646)
	double grc_to_in_g_slow = grc_to_in_g_fast*fast_to_slow_ratio;	
	double in_to_grc_g_fast = 0.6259622633+((1.786298271-0.6259622633)*0);//0.16);//1; // range is perhaps 0.6259622633 to 1.786298271
	double in_to_grc_g_slow = in_to_grc_g_fast*fast_to_slow_ratio;
	double dir_init_multi = 10;//1000;//100000;
	int move_delay = 20;//25;//50; // delay in speed that moves are commanded to occur
	double move_increment = 0.005;//0.002;//0.01;//0.018;//0.007;//0.018;//0.006;//0.005;//0.024;//0.018;//0.005;//0.018; // amount to move in position each move command
	vector<float> ext_dir;

	// interneuron connections
	int conn_offset = 0; // offset in neuron positions for connections
	int conn_dist = 3; // distance between neurons in connections
	int x_srt = 5;//10;//5; // offset for starting position of center-surround centroid in target layer size compared to full layer size
	int y_srt = 5;//10;//5; //layer_size_in
	float grc_to_in_wt = 1.0; // grc to interneurons weight
	int use_nowp = 0; // select to use some non-wrapping centroids
	int use_loww = 0; // select to use some low-weight centroids
	bool print_conn_stats = 0; // print connectivity statistics
	vector<double> in_conns; // count of grid cell to interneuron connections
	vector<double> gc_conns; // count of interneuron to grid cell connections
	#define use_saved_g_to_i_conns 1 // use prior saved grc to in connection list instead of computing new one
	#if use_saved_g_to_i_conns
		bool save_grc_to_in_conns = 0;
	#else
		bool save_grc_to_in_conns = 1; // write out file with grid cell to interneuron connections
	#endif
	vector<vector<int>> in_conns_binary; // binary flag for presence of grid cell to interneuron connections
	string grc_to_in_filepath = "./data/grc_to_in_conns.csv";
	ofstream grc_to_in_file;

	// speed
	bool auto_speed_control = 1;//0; // automatically adjust parameters to match speed selected
	bool speed_limit = 0; // speed limit on or off
	double max_speed = 17.5; // max movement speed
	double speed_conversion = 1;//0.2; // scale animal movement speed data
	double min_rand_speed = 0.25; // minimum speed for random speed generator. note: signal applied even when stopped.
	double max_rand_speed = 1.0; // maximum speed for random speed generator
	double move_rev_s = 1; // test movement in forward or reverse speeds
	double move_rev_a = 1; // test movement in forward or reverse angles
	int speed_setting = 0; // used for move_speed_change test movement
	double current_angle; // angle of movement the virtual movement is currently at
	//vector<double> prior_speeds{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	//vector<double> prior_angles{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

  	// plotting
  	static const int x_size_plot = 30; // size that will be used for plotting
	static const int y_size_plot = 30;
	double al_act_lvl = 5.0; // amount of activity level added for each visit with animal location non-all plot.
	double ala_act_lvl = 0.1; // amount of activity level added for each visit with animal location all plot.

	// place cell parameters
	double theta_freq = 125.0; // theta frequency in Hz
	double dist_thresh = 5;//7;//5; // distance threshold for only local connections	
	float pc_to_grc_g_fast = 71.14*0.13;//0.15;//0.25;//0.1;//71.14*.280;//.2;//.3;//.65;//.55;//0.40;//0.360;//0.280;//0.205;//0.120;//0.13;//0.12;//0.10;//0.11;//0.1;//0.12;//0.18;//0.14;//0.25;//0.14;//0.25;//0.14;//0.50;//0.25;//0.120;//0.180;//0.220;//0.180;//0.4;//0.180;//0.155;//0.180;
	float pc_to_grc_g_slow = pc_to_grc_g_fast*fast_to_slow_ratio;
	double pc_sig = 3.0;//2.5;//1.5;//2.2;//7;//2.5;//1.5;//2.0;//1.5;//2.5;//2;//1.5;//2;//1.5;//2;//1.5;//2;//1.2;//1.8;//1.6;//2;//4;//2;//1.2;//2;//2;//4;//2;//3;//3;//4;//2;//2;//1;//1.4;//1;//0.75; // sigma symbol; width of the place feild
	double pc_level = 130;//150;//250;//100;//280;//1000;//560;//280;//1000;//300;//2000;//650;//550;//400;//360;//280;//205;//120;//130;//120;//100;//110;//100;//120;//180;//140;//250;//140;//250;//140;//500;//250;//120;//180;//220;//180;//400;//180; // place cell firing level
	vector<float> pc_activity;

	// boundary cell parameters
	bool bc_to_pc = 0; // boundary cells to place cells signaling
	bool bc_to_gc = 0; // boundary cells to grid cells signaling
	double r_d = 1.0; // boundary cell active region width
	double bc_firing_scale = 0.1; // amount of boundary cell firing when activated
	double bc_pd = 5.0; // boundary cell prefered distance
	static const int b_num = 4.0; // number of borders
	double bc_distances[b_num];
	// response curve factors
	//double bc_level = 14.0 * 0.25; // level of bc firing
	double bc_a0 = 2.0; // boundary cell A_0 factor for response curve
	double bc_b = 0.25;
	double bc_sig0 = 0.0;
	double bc_y = 0.05;//0.25;
	double bc_a = 0.25;
	double bc_sig = 1.0;

	// speed cell parameters
	bool spin2in_active = 0; // inhibitory speed cells active.	
	bool spex2in_active = 0; // excitatory speed cells active.	
	double spdin2inwt = 20;//1;//2;//0.5;//10;//0.5;//10;
	double spdex2inwt = 10;//10;//50.0;//30.0;//100.0;//1.0;//1.65;//0.52;//0.5;
	double spdin2in_curr = 1;//1;//1.0;//1.0;//0;//1;//100;//10;
	double spdex2in_curr = 0.4;//0.32;//0.4;//0.35;//0.3;//0.0;//0.3;

	// noise parameters
	bool noise_active = 0; // activate noise
	double noise_rand_max = 100; // 0 - rand_max is range of random number gen
	double noise_scale = 0.001;//0.0015;//0.0001;//0.015;//0.01;//0.005; // scale to desired size for firing
	double noise_addit_freq = 0.0f; // additional spiking frequency added to base external input

	// neuron vs location parameters
	int selected_neuron = 465;//378;//372;//465;//372;//11;//465;//232;//465;//10;
	int selected_in_neuron = 100; // interneuron
	double grid_pattern_rot = -33.75;//0;//-40;//0;//-40;//0;//15;//0;//15;//-33.75;//0;//15.0;//-33.75;//0;//5;//0;//-33.75;//0;//-33.75;//-45;//-33.75;//-45;//0;//-45;//-22.5;//-45;//0;//15;//15;//-15; // angle value for rotation of grid pattern in plot
	double grid_pattern_scale = 1;//0.95;//1;//0.5;//1;//18/22.5; // rescale grid pattern for plot. smaller value makes larger rescale, e.g., 0.8 = 1.25x rescale. animal speed to bump speed conversion. <goal_top_bump_speed>/<goal_top_animal_speed>
	vector<int> locations_visited; // locations an animal visited
	double animal_location[x_size*y_size]; // location of animal
	double animal_location_all[x_size*y_size]; // location of animal

	// center-surround centroid positions
    // centroid (center of pixels) positions for each center-surround distribution (ring) via interneuron connections
	// vector<int> cent_x{0, -2,   2, -14, 14, 10, -10,   6, -6}; 
	// vector<int> cent_y{0, -10, 10,  -4,  4, -8,   8, -18, 18};
	vector<int> cent_x{0, -8,  8,    6, -6, -14, 14};
	vector<int> cent_y{0, -12, 12, -12, 12,   0,  0};
	// vector<int> cent_x{0, -20,  20}; 
    // vector<int> cent_y{0, -10, -10};
	// vector<int> cent_x{0, -20,  20}; 
    // vector<int> cent_y{0, -10,  -10};

	// centroids with no wrapping
	vector<int> cent_x_nowp{-8,  -8,  14, -14, 28, -28, 20,  20, 34, 34};
	vector<int> cent_y_nowp{12, -12,  0,   0,  0,   0, 12, -12, 12, -12};

	// low weight centroids
	vector<int> cent_x_loww{-6,   6,  14, -14};
	vector<int> cent_y_loww{12, -12,  0,   0};
};
