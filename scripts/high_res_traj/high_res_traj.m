% create high-resolution trajectory and firing plot
close all;

if run_on_hopper==1
    curr_dir=pwd;
    %curr_dir=replace(curr_dir,"gc_can_1",strcat(fdr_prefix,int2str(local_run)));
    cd /home/nsutton2/git/OAT_CS4/
    initOAT
    cd(curr_dir)
    addpath /home/nsutton2/git/CMBHOME_github/ 
elseif use_hopper_data==1
    curr_dir="/home/nmsutton/Dropbox/CompNeuro/gmu/research/sim_project/code/gc_can_1/scripts/";
    cd(curr_dir);
    initOAT
    cd("high_res_traj");
    %new_prefix=fdr_prefix;
    %if fdr_prefix=="" new_prefix="gc_can_"; end
    %cd(strcat("/home/nsutton2/git/CARLsim6-feat-ca3net_5/projects/"+new_prefix+hopper_run+"/scripts/high_res_traj"));
    addpath /comp_neuro/Software/Github/CMBHOME_github/
else
    curr_dir=pwd;
    curr_dir=replace(curr_dir,"gc_can_1",strcat(fdr_prefix,int2str(local_run)));
    cd(curr_dir);
    cd ..
    initOAT
    cd(curr_dir);
    addpath /comp_neuro/Software/Github/CMBHOME_github/
end
angles_speeds = 0; % load angles and speeds or x,y position coordinates
preloaded_XsYs = 0; % use prior loaded Ys and Xs instead of reading them from files
preloaded_data = 0; % use all prior loaded data. This is Xs, Ys, and spikes.
output_XsYs_file = 0;
if ~exist('create_plot','var') create_plot = 1; end
timestep = 20;
orig_xy = 0; % use orig x,y animal positions with no wrapping around or carlsim x,y that wraps around a taurus  
plot_in_spikes = 0; % plot interneuron spikes
use_spk_reader = 1; % use CARLsim's spike reader rather than seperate spike times file
spk_bin_size = 10; % spike reader bin size. Note: small bin sizes may take long processing with large spike sets. 40min sim with bin size 1 can take 10min to create plot.
laptop_data = 0;
use_unwrapped_data = 0;
output_spikes_file = 1; % output file that can be used in rate map plot
plot_smooth_rm = 1; % plot smoothed rate map
if ~exist('save_traj_plot','var') save_traj_plot = 0; end % save traj plot to file
%if run_on_hopper==1 save_traj_plot = 1; end
if plot_in_spikes==1 plot_spikes=1; end
if plot_spikes==0 output_spikes_file = 0; end
if preloaded_spk_reader==0 spikes=[]; end

pi=3.1415926535897932384626433832795028841971;
lines = [];
if output_spikes_file==1
    recspk_file = fopen('highres_spikes.csv','w');
end
if output_XsYs_file==1
    Xs_file = fopen('anim_trajx.csv','w');
    Ys_file = fopen('anim_trajy.csv','w');
end

% load trajectory path
if preloaded_XsYs == 0 && preloaded_data == 0 && run_real_recordings == 0
    Xs = []; Ys = [];
    [Xs,Ys,animal_angles,animal_speeds]=loadTraj(angles_speeds, preloaded_XsYs, ...
        orig_xy, laptop_data, use_unwrapped_data, use_hopper_data, hopper_run, ...
        run_on_hopper, fdr_prefix, local_run, curr_dir);
end

if plot_spikes==1 && preloaded_data == 0 && run_real_recordings == 0
    spk_x = []; spk_y = [];
    [spk_t,spikes]=load_spk_times(use_hopper_data, hopper_run, plot_in_spikes, laptop_data, ...
        use_spk_reader, spk_bin_size, sel_nrn, preloaded_spk_reader, spikes, run_on_hopper, ...
        fdr_prefix, local_run, curr_dir);
end

if angles_speeds == 1 && preloaded_XsYs ~= 1
    x = 0; y = 0;
    %x = pos(1,1); % use pos from reformatted positions file used in moves_analysis.m
    %y = pos(2,1);
    for i=1:length(animal_speeds)
	    t=i*timestep; % in ms
	    a=animal_angles(i);
	    s=animal_speeds(i);
	    a=a/360*pi*2;
        [hor,ver]=hor_ver(a, s);
        x=x+hor;
	    y=y+ver;
	    %fprintf("%f %f\n",x2,y2);
	    Xs=[Xs;x];
	    Ys=[Ys;y];
        if mod(i,10000)==0
            fprintf("i:%d %.1f%% completed\n",i,i/length(animal_speeds)*100);
        end
    end
end

if restrict_time ~= 0
    if orig_xy
        x = Xs(1:floor(restrict_time/timestep));
        y = Ys(1:floor(restrict_time/timestep));
    else
        if angles_speeds
            x = Xs(1:floor(restrict_time/timestep));
            y = Ys(1:floor(restrict_time/timestep));            
        else
            Xs = Xs(1:restrict_time);
            Ys = Ys(1:restrict_time);
            x = Xs;
            y = Ys;
        end
    end
else
    x = Xs;
    y = Ys;
end

if plot_spikes==1 || output_spikes_file==1
    for i=1:length(spk_t)
        if restrict_time == 0 || spk_t(i) < restrict_time
            if orig_xy==1 || angles_speeds==1
                spk_x=[spk_x,x(floor(spk_t(i)/timestep))];
	            spk_y=[spk_y,y(floor(spk_t(i)/timestep))];
            elseif run_real_recordings == 1
                % variables already processed
            else 
                spk_x=[spk_x,x(spk_t(i))];
	            spk_y=[spk_y,y(spk_t(i))];
            end
            if output_spikes_file==1
                fprintf(recspk_file,"%f,%f,%f\n",spk_t(i),spk_x(i),spk_y(i));
            end
        end
    end
end

if output_XsYs_file==1
    for i=1:length(Xs)
        fprintf(Xs_file,'%.6f\n',Xs(i));
        fprintf(Ys_file,'%.6f\n',Ys(i));
        if mod(i,(length(Xs)/10))==0
            fprintf("%.6f%% completed\n",i/length(Xs));
        end 
    end
    fclose(Xs_file);
    fclose(Ys_file);   
end
if output_spikes_file==1
    fclose(recspk_file);
end

% plot
if create_plot==1
    plot_trajectory
end

if plot_smooth_rm==1
    cd ..
    heat_map=activity_image_phys_spc_smooth(run_on_hopper,use_hopper_data,fdr_prefix,...
        hopper_run,local_run,x,y,run_real_recordings,plot_subsect,grid_size,plot_size,save_plot);
    cd high_res_traj
end

function [hor,ver]=hor_ver(angle, speed)
    h = speed;
    if (angle < (pi/2)) 
		hor = sin(angle) * h;
		ver = sqrt(h^2-hor^2);
    elseif (angle >= (pi/2) && angle < pi) 
		hor = cos(angle-(pi/2)) * h;
		ver = sqrt(h^2-hor^2) * -1;
    elseif (angle >= pi && angle < (pi*1.5)) 
		hor = cos((pi*1.5)-angle) * h * -1;
		ver = sqrt(h^2-hor^2) * -1;
    elseif (angle >= (pi*1.5) && angle <= (pi*2)) 
		hor = cos(angle-(pi*1.5)) * h * -1;
		ver = sqrt(h^2-hor^2);
    end
end

function [Xs,Ys,animal_angles,animal_speeds]=loadTraj(angles_speeds, preloaded_XsYs, ...
    orig_xy, laptop_data, use_unwrapped_data, use_hopper_data, hopper_run, run_on_hopper, ...
    fdr_prefix, local_run, curr_dir)
    animal_angles = []; animal_speeds = []; Xs = []; Ys = [];

    if angles_speeds==1
        if preloaded_XsYs ~= 1
            animal_angles = readmatrix('/home/nmsutton/Dropbox/CompNeuro/gmu/research/sim_project/code/moves_analysis/src/output/anim_angles.csv');
            animal_speeds = readmatrix('/home/nmsutton/Dropbox/CompNeuro/gmu/research/sim_project/code/moves_analysis/src/output/anim_speeds.csv');
        end
    else
        if use_hopper_data==1
            Xs = readmatrix(strcat("/mnt/hopper_scratch/gc_sim/"+fdr_prefix+hopper_run+"/spikes/highres_pos_x.csv"));
            Ys = readmatrix(strcat("/mnt/hopper_scratch/gc_sim/"+fdr_prefix+hopper_run+"/spikes/highres_pos_y.csv"));
        elseif orig_xy == 0
            Xs = readmatrix(strcat(curr_dir,"/../../output/spikes/highres_pos_x.csv"));
            Ys = readmatrix(strcat(curr_dir,"/../../output/spikes/highres_pos_y.csv"));
            disp(strcat(curr_dir,"/../../output/spikes/highres_pos_x.csv"))
        else
            load /home/nmsutton/Dropbox/CompNeuro/gmu/research/sim_project/code/gc_can/scripts/high_res_traj/191108_S1_lightVSdarkness_cells11and12_scaleddown_Xs_40min.mat;
            load /home/nmsutton/Dropbox/CompNeuro/gmu/research/sim_project/code/gc_can/scripts/high_res_traj/191108_S1_lightVSdarkness_cells11and12_scaleddown_Ys_40min.mat;
        end
    end
end

function [spk_t,spikes]=load_spk_times(use_hopper_data, hopper_run, plot_in_spikes, laptop_data, ...
    use_spk_reader, spk_bin_size, sel_nrn, preloaded_spk_reader, spikes, run_on_hopper, ...
    fdr_prefix, local_run, curr_dir)
    if use_spk_reader==1
        if use_hopper_data==1
            if plot_in_spikes==0
                file_path="/mnt/hopper_scratch/gc_sim/"+fdr_prefix+hopper_run+"/results/spk_MEC_LII_Stellate.dat";            
            else
                file_path="/mnt/hopper_scratch/gc_sim/"+fdr_prefix+hopper_run+"/results/spk_MEC_LII_Basket.dat";                
            end
            %disp("hopper data");
            %disp(file_path);
        else
            if plot_in_spikes==0
                file_path = strcat(curr_dir,"/../../results/spk_MEC_LII_Stellate.dat");
            else
                file_path = strcat(curr_dir,"/../../results/spk_MEC_LII_Basket.dat");
            end
        end
        if str2num([string(preloaded_spk_reader)])==0 spk_data = SpikeReader(file_path, false, 'silent'); end
        if str2num([string(preloaded_spk_reader)])==0 spikes = spk_data.readSpikes(spk_bin_size); end
        spk_t=find(spikes(:,sel_nrn)~=0);
        spk_t=spk_t*spk_bin_size;
    else
        if run_on_hopper==1
            if plot_in_spikes==1
                file_path="/scratch/nsutton2/gc_sim/"+fdr_prefix+hopper_run+"/spikes/in_spikes_recorded.csv";
            else
                file_path="/scratch/nsutton2/gc_sim/"+fdr_prefix+hopper_run+"/spikes/spikes_recorded.csv";
            end
        elseif use_hopper_data==1
            if plot_in_spikes==1
                file_path="/mnt/hopper_scratch/nsutton2/gc_sim/"+fdr_prefix+hopper_run+"/spikes/in_spikes_recorded.csv";
            else
                file_path="/mnt/hopper_scratch/nsutton2/gc_sim/"+fdr_prefix+hopper_run+"/spikes/spikes_recorded.csv";
            end
        else
            if plot_in_spikes==1
                file_path=strcat(curr_dir,"/../../output/spikes/in_spikes_recorded.csv");
            else
                file_path=strcat(curr_dir,"/../../output/spikes/spikes_recorded.csv");
            end
        end
        spk_t = readmatrix(file_path);         
    end
end