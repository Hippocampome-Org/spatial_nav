run("/home/nmsutton/Dropbox/CompNeuro/gmu/research/sim_project/code/gc_can/scripts/initOAT.m");
addpath /comp_neuro/Software/Github/CMBHOME_github/
load("example_data/example_spk_x.mat")
load("example_data/example_spk_y.mat")
spikes = [];
display_plot=0;
save_plot=1;
grid_size=30;
shuffles=1000;
binside = 3;
std_smooth_kernel = 3.333;
shuffle_1 = 1;
shuffle_2 = 0;

if display_plot == 0 fig = figure('visible','off'); else fig = figure; end
for i=1:shuffles
    % heat map
    heat_map = create_heat_map(shuffle_1, shuffle_2, spk_x, spk_y, grid_size, std_smooth_kernel, binside, i);
    % gridscores
    [HDgridScore,gridness3Score] = create_gridscores(heat_map);
    % plot
    create_plot(heat_map, HDgridScore, gridness3Score, fig, save_plot, i);
end

function [spk_x spk_y] = shuffle(spk_x, spk_y)
	% shuffle
    r = randi([1 length(spk_x)],1,1);
	xr = randi([1 100*30],1,1)*.01;
	yr = randi([1 100*30],1,1)*.01;
	spk_x(r) = xr;
	spk_y(r) = yr;
end

function heat_map = shuffle2(heat_map)
	% shuffle
	r1 = randi([1 length(heat_map)^2],1,1);
	r2 = randi([1 length(heat_map)^2],1,1);
	temp = heat_map(r1);
	heat_map(r1) = heat_map(r2);
	heat_map(r2) = temp;
end

function heat_map = create_heat_map(shuffle_1, shuffle_2, spk_x, spk_y, grid_size, std_smooth_kernel, binside, i)
    import CMBHOME.Utils.*
    if shuffle_1 
	    for j=1:i [spk_x spk_y] = shuffle(spk_x, spk_y); end 
    end
    spike_x = spk_y';
    spike_y = spk_x';
    heat_map = zeros(1,grid_size*grid_size);
    xdim = linspace(0,grid_size-1,grid_size);%xdim * 30/360;
    ydim2 = linspace(0,grid_size-1,grid_size);%ydim2 * 30/360;
    heat_map = hist3([spike_x, spike_y], 'Edges', {xdim, ydim2});
    if shuffle_2 
	    for j=1:i heat_map = shuffle3(heat_map); end 
    end
    heat_map = SmoothMat(heat_map, [5*std_smooth_kernel/binside, 5*std_smooth_kernel/binside], std_smooth_kernel/binside); % smooth the spikes and occupancy with a 5x5 bin gaussian with std=1
end

function [HDgridScore,gridness3Score] = create_gridscores(heat_map)
    m = []; % empty matrix
    cd ..
    [HDgridScore,gridness3Score]=get_HDGridScore(m,m,m,heat_map);
    %fprintf("%f,%f\n",HDgridScore,gridness3Score);
    %gridness_file = fopen('../param_explore/output/gridness_score.txt','at'); % append file
    %c = clock;
    %hr = mod(c(4),12);
    %output_time = sprintf("%.0f-%.0f-%.0f_%.0f-%.0f-%.0f",hr,c(5),c(6),c(2),c(3),c(1));
    %fprintf(gridness_file,"%s,%f,%f\n",output_time,HDgridScore,gridness3Score);
    %fclose(gridness_file);
    cd test_scores/
end

function create_plot(heat_map, HDgridScore, gridness3Score, fig, save_plot, i)
    imagesc(heat_map);
    axis('tight')
    xlabel('animal position on x axis') 
    ylabel('animal position on y axis')
    cb = colorbar;
    ax = gca;
    ax.YDir = 'normal'; % have y-axis 0 on bottom left
    %caxis([0 25])
    caption = sprintf('HolgerGridScore = %.5f; Gridness3Score = %.5f', HDgridScore, gridness3Score);
    title(caption, 'FontSize', 11);
    %set(fig, 'units', 'inches', 'position', [0 50 5.31 4.444]);
    set(fig, 'units', 'inches', 'position', [0 50 5.29 4.3]);
    if save_plot
	    c = clock;
	    hr = mod(c(4),12);
	    %output_filename = sprintf("ratemap_%.0f-%.0f-%.0f_%.0f-%.0f-%.0f.png",hr,c(5),c(6),c(2),c(3),c(1));
        output_filename = sprintf("plots/ratemap_%04d.png",i);
	    exportgraphics(gcf,output_filename,'Resolution',300)
    end
    if mod(i,100)==0 fprintf("i: %d\n",i); end
end