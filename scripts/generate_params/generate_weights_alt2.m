% references: https://www.mathworks.com/matlabcentral/answers/180778-plotting-a-3d-gaussian-function-using-surf
% https://www.mathworks.com/help/symbolic/rotation-matrix-and-transformation-matrix.html
% https://www.mathworks.com/matlabcentral/answers/430093-rotation-about-a-point

% run options
sample_matrix = 1;
write_to_file = 0;
show_2d_plot = 0;
show_3d_plot = 0;
alt_weights = 0; % use alt synapse_weights matrix

% params
output_filename = "synapse_weights.cpp";
output_file = 0;
if write_to_file
	output_file = fopen(output_filename,'w');
end
grid_size = 90;
if alt_weights
    grid_size = 120;
end
grid_size_target = 30; % target grid size for neuron weights
total_nrns = (grid_size_target^2);%35;%(grid_size^2);% total neurons
if show_2d_plot
    total_nrns = 1;
end
iter = 17; % iterations to run cent-surr function. i.e., number of tiled cent-surr dist. along an axis. e.g., value 5 creates 5x5 cent-surr circles in the weights plot.
start_x_shift = (grid_size/2) - 42;%44;%- 44;%1;%28; -2 = 2 down
start_y_shift = (grid_size/2) - 39;%44;%- 44;%1;%-4;%28; +2 = 2 left
p1=.68;p2=2;p3=2;
p4=38; % center size
p5=p3;p6=p4;
p7=0.174;%0.15; % surround size
p8=.135;p9=2;p10=2;p11=2;p12=p4;p13=p11;p14=p11;p15=p12;
p16=0.9396;%0.81; % surround size
p17=0.0058;
p=[p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17];
tiling_fraction=0.33333333333*.239;%0.1;%0.33333333333;%1;%0.33;%0.5; % fraction of standard tiling distance between bumps
po=[show_3d_plot,write_to_file,sample_matrix,output_file,grid_size,iter,tiling_fraction, ...
    grid_size_target,start_x_shift,start_y_shift];
comb_syn_wts=[];
[X,Y] = meshgrid(1:1:grid_size);
Z=zeros(grid_size);

% plot
if show_3d_plot
	synapse_weights = nrn_syn_wts(start_x_shift,start_y_shift,p,po);
	[synapse_weights2, synapse_weights3]=stagger_weights(po,Rz,synapse_weights);
	[X,Y] = meshgrid(1:1:grid_size_target);
	Z = synapse_weights3;
	surf(X,Y,Z);
	shading interp
	axis tight
    view(2) % 2d plot instead of 3d
end

% write to file and create matrix
if write_to_file
    if alt_weights == 0
	    synapse_weights=nrn_syn_wts(start_x_shift,start_y_shift,p,po);
    end
	for i=0:(total_nrns-1)
		%synapse_weights2=stagger_weights(po,Rz,synapse_weights);
		synapse_weights2 = reshape(synapse_weights,grid_size,grid_size);
		synapse_weights3=shift_weights(po,i,synapse_weights2);
		synapse_weights4=crop_weights(po,synapse_weights3);
		comb_syn_wts=[comb_syn_wts; reshape(synapse_weights4,1,grid_size_target^2)];

		if (mod(i,grid_size_target*3)==0)
			fprintf("%.3g%% completed\n",i/total_nrns*100);
		end
	end
	disp("writing to file");
	fprintf(output_file,'static const vector<vector<double>> mex_hat{{');
	for i=0:(total_nrns-1)
		for j=1:length(comb_syn_wts)
			fprintf(output_file,'%f',comb_syn_wts(i+1,j));
			if j ~= length(comb_syn_wts)
				fprintf(output_file,',');
			end
		end
		if i ~= (total_nrns-1)
			fprintf(output_file,'},\n{');
		end	
		if (mod(i,grid_size_target*3)==0)
			fprintf("%.3g%% completed\n",i/total_nrns*100);
		end
	end
	fprintf(output_file,'}};');
    if show_2d_plot
        imagesc(reshape(comb_syn_wts(1,1:end),30,30));
    end
end
if sample_matrix
	po(2)=0; % turn off file writing for sample
    start_y_shift = start_y_shift + 4;
    start_x_shift = start_x_shift + 0;
    if alt_weights == 0
	    synapse_weights=nrn_syn_wts(start_x_shift,start_y_shift,p,po);
    end
	%synapse_weights2=stagger_weights(po,Rz,synapse_weights);
    synapse_weights2 = reshape(synapse_weights,grid_size,grid_size);
	synapse_weights3=shift_weights(po,1,synapse_weights2);
	synapse_weights4=crop_weights(po,synapse_weights3);
    imagesc(synapse_weights4);
end

if write_to_file
	fclose(output_file);
end
%{
function synapse_weights2=stagger_weights(po,Rz,synapse_weights)
	grid_size=po(5);grid_size_target=po(8);

	synapse_weights = reshape(synapse_weights,grid_size,grid_size);
    synapse_weights2 = zeros(grid_size);
    for y=1:grid_size
        for x=1:grid_size
            i=((y-1)*grid_size)+x;
            z=synapse_weights(i); 
            
        	synapse_weights2(i) = synapse_weights(i);
        end
    end
end
%}
function synapse_weights3=shift_weights(po,i,synapse_weights2)
	% apply pd-based shifting to synapse weights matrix

	grid_size=po(5);grid_size_target=po(8);synapse_weights3=zeros(grid_size);
	start_x_shift=po(9);start_y_shift=po(10);

	pdx = mod(i,grid_size_target);
	pdy = floor(i/grid_size_target);
	pd=get_pd(pdx,pdy);
	x_pd_bias = 0;
	y_pd_bias = 0;
	if pd=='u'
		y_pd_bias=2;
		%x_pd_bias=2;
	elseif pd=='d'
		y_pd_bias=-2;
		%x_pd_bias=-2;
	elseif pd=='l'
		x_pd_bias=2;
		%y_pd_bias=-2;
	elseif pd=='r'
		x_pd_bias=-2;
		%y_pd_bias=2;
	end
	y_shift=pdy+x_pd_bias; % x and y values are intentially flipped
	x_shift=pdx+y_pd_bias; % here for an orientation fix

	ti = (grid_size^2)-1;
	for i2=0:ti
		x = mod(i2,grid_size)+1;
		y = floor(i2/grid_size)+1;
		x2 = x + x_shift;
		y2 = y + y_shift;

		if x2 > ti
			x2 = x2 - ti;
		elseif x2 < 1
			x2 = x2 + ti;
		end
		if y2 > ti
			y2 = y2 - ti;
		elseif y2 < 1
			y2 = y2 + ti;
		end

		synapse_weights3(x2,y2)=synapse_weights2(x,y);
	end
end

function synapse_weights4=crop_weights(po,synapse_weights3)
	% apply rotation to synapse weights matrix

	grid_size=po(5);grid_size_target=po(8);synapse_weights4=zeros(grid_size_target);

    %% crop larger distribution into smaller target sized one
    target_offset = (grid_size-grid_size_target)/2;
    for y=1:grid_size_target
        for x=1:grid_size_target
        	x2 = target_offset + x;
        	y2 = target_offset + y;
        	synapse_weights4(x,y)=synapse_weights3(x2,y2);
        end
    end
end

function synapse_weights=nrn_syn_wts(x_shift,y_shift,p,po,synapse_weights);
	% generate all synapse weights for one neuron

   	grid_size=po(5);iter=po(6);synapse_weights=[];
	for y=1:grid_size
		for x=1:grid_size
			z=cent_surr_tile(x,y,x_shift,y_shift,p,po);
			synapse_weights = [synapse_weights,z];
		end
	end	
end

function z=cent_surr_tile(x,y,x_shift,y_shift,p,po)
	% tiles center-surround distributions
	% generate <inter> number of tiled center surround functions
	% for the synaptic weight distribution

	grid_size=po(5);grid_size_target=po(8);iter=po(6);tf=po(7);z=0;
	for i=0:(iter-1)
		for j=0:(iter-1)
            tv=(iter-1)/2; % tiling variable
			x_shift2 = (-(grid_size*tv*tf)+i*(grid_size*tf))+x_shift;
			y_shift2 = (-(grid_size*tv*tf)+j*(grid_size*tf))+y_shift;
			%{
			y_shift2 = y_shift2/2;
            %}
            if mod(i,2) ~= 0
				y_shift2 = y_shift2 + 3.5;%grid_size_target/3;
			end
			if mod(j,2) ~= 0
				%x_shift2 = x_shift2 + grid_size_target/4;
			end
			z=z+cent_surr(x,y,x_shift2,y_shift2,p);
			z_max = 0.00681312463724531;
			if z > z_max z = z_max; end
		end
	end
end

function z=cent_surr(x,y,x_shift,y_shift,p)
	% center-surround function
	x=(x-x_shift);
	y=(y-y_shift);
	%{
	p1=p(1);p2=p(2);p3=p(3);p4=p(4);p5=p(5);p6=p(6);p7=p(7);p8=p(8);p9=p(9);
	p10=p(10);p11=p(11);p12=p(12);p13=p(13);p14=p(14);p15=p(15);p16=p(16);p17=p(17);
	% difference of gaussians function creates the center-surround
	z=((p1/sqrt(p2*pi).*exp(-(x.^p3/p4) ...
		-(y.^p5/p6)))*p7-(p8/sqrt(p9*pi) ...
		.*exp(-(p10*x.^p11/p12)-(p13*y.^p14/p15)))*p16)-p17;
	%}
	b_low = 3.4;
	b_high = 4.4;
	if dist(x,y) >= b_low && dist(x,y) <= b_high
		z=0.00681312463724531;
	else
		z=0.0;
	end

	if z < 0
		z = 0; % negative values rectifier
	end
end

function d=dist(x,y)
	% compute euclidean distance of (x,y) from (0,0)
	x2=0;y2=0;
	d=sqrt(((x-x2)^2)+((y-y2)^2));
end

function pd = get_pd(x, y)
    % find neuron preferred direction
	if (mod(y,2) == 0)
		if (mod(x,2) == 0)
			pd = 'l';
		else 
			pd = 'r';
        end
    else
		if (mod(x,2) == 0)
			pd = 'u';
        else
			pd = 'd';	
        end
    end
end