% references: https://www.mathworks.com/matlabcentral/answers/180778-plotting-a-3d-gaussian-function-using-surf
% https://www.mathworks.com/help/symbolic/rotation-matrix-and-transformation-matrix.html
% https://www.mathworks.com/matlabcentral/answers/430093-rotation-about-a-point

% run options
sample_matrix = 0;
write_to_csv = 1; % needed for running on supercomputer
write_to_cpp = 0; % alternative file for running locally (not supercomputer)
show_2d_plot = 1;
show_3d_plot = 0;
alt_weights = 0; % use alt synapse_weights matrix

% params
csv_filename = "synapse_weights.csv";
cpp_filename = "synapse_weights.cpp";
output_cpp = 0; output_csv = 0; % these are always init as 0
if write_to_csv output_csv = fopen(csv_filename,'w'); end
if write_to_cpp output_cpp = fopen(cpp_filename,'w'); end
grid_size_target = 40;%42;%40;%36;%42; % target grid size for neuron weights
total_nrns = (grid_size_target^2);%35;%(grid_size^2);% total neurons
if show_2d_plot total_nrns = 3; end
grid_size = grid_size_target*3;%90;
%if alt_weights
%    grid_size = 120;
%end
iter = 13; % iterations to run cent-surr function. i.e., number of tiled cent-surr dist. along an axis. e.g., value 5 creates 5x5 cent-surr circles in the weights plot.
start_x_shift = (grid_size/2) - 19;%20;%19;%17;%44;%20;%50;%44;%- 44;%1;%28; -2 = 2 down
start_y_shift = (grid_size/2) - 19;%20;%19;%17;%44;%20;%50;%44;%- 44;%1;%-4;%28; +2 = 2 left
highval = 0.00681312463724531;
highval_thres = 0.004;
filter_highval = 1;%1; % filter values to convert into high val.
r_s=20/42;%25/42;%20/42;%0.8*1.1;%0.8*1.4;%1.1;%1.2;%1.4;%1.5;%0.73;%1.1;%(36/42);%1;%(42/30); % ring scale
p1=20;%20;%.68;
p2=2;p3=2;
% center size
p4=r_s*180;%200;%190;%160;%130;%90;%r_s*52;%35;%45;%52;%40;%70;%130;%38;%*2.5*1.3;%.55;%.7;%4;%2;%2;%2.5;%2;%*1.4;%1.344;%*2.7*(14/20);%1.4;%*.5; 
% center size
p8=r_s*210;%230;%220;%190;%160;%70;%r_s*.135*1.02;%r_s*.135*1.07;%1;%.87;%.135*.9;%1;%.97;%.99;%.11;%.13;%.12;%.14;%.12;%.22;%.2;%.25;%.135; 
% surround size
p7=r_s*0.5;%.3;%0.15;%r_s*0.19;%0.18;%0.19;%0.183;%0.19;%0.2;%0.2;%*1.1*.97;%1.04;%1.05;%1.15;%1;%4;%.7;%.9;%.7;%0.174*1.4;%*2.4*(14/20);%1.4;%*.75;%0.15; 
% surround size
p16=r_s*0.3;%0.3;%1.08*.95*r_s;%1.08*1.03;%1.03;%.95;%1;%.97;%.99;%0.81;%*1.1*.97;%1.04;%1.05;%1.15;%1;%4;%.7;%.9;%.7;%0.9396*1.4*.9;%*3*(14/20);%1.4;%*.75;%0.81; 
p5=p3;p6=p4;p9=2;p10=2;p11=2;p12=p4;p13=p11;p14=p11;p15=p12;p17=0.0058;
p=[p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17];
tiling_fraction=0.33333333333*1;%(126/120);%1;%(42/30);%1.05;%*1.04;%0.1;%0.33333333333;%1;%0.33;%0.5; % fraction of standard tiling distance between bumps
po=[show_3d_plot,write_to_cpp,sample_matrix,output_cpp,grid_size,iter,tiling_fraction, ...
    grid_size_target,start_x_shift,start_y_shift];
comb_syn_wts=[];
[X,Y] = meshgrid(1:1:grid_size);
Z=zeros(grid_size);
% rotation variables
a=0;%125; % angle
a=a/360 * pi*2; % convert to radians
Rz = [cos(a) -sin(a) 0; sin(a) cos(a) 0; 0 0 1]; % rotate along Z axis. See references for other axis code if wanted.

% plot
if show_3d_plot
	synapse_weights = nrn_syn_wts(start_x_shift,start_y_shift,filter_highval,highval,highval_thres,p,po);
	[synapse_weights2, synapse_weights3]=rotate_weights(po,Rz,synapse_weights);
	[X,Y] = meshgrid(1:1:grid_size_target);
	Z = synapse_weights3;
	surf(X,Y,Z);
	shading interp
	axis tight
    view(2) % 2d plot instead of 3d
end

% write to file and create matrix
if write_to_csv || write_to_cpp
    if alt_weights == 0
	    synapse_weights=nrn_syn_wts(start_x_shift,start_y_shift,filter_highval,highval,highval_thres,p,po);
    end
	for i=0:(total_nrns-1)
		synapse_weights2=rotate_weights(po,Rz,synapse_weights);
		synapse_weights3=shift_weights(po,i,synapse_weights2);
		synapse_weights4=crop_weights(po,synapse_weights3);
		comb_syn_wts=[comb_syn_wts; reshape(synapse_weights4,1,grid_size_target^2)];

		if (mod(i,grid_size_target*3)==0)
			fprintf("%.3g%% completed\n",i/total_nrns*100);
		end
	end
	disp("writing to file");
	if output_cpp fprintf(output_cpp,'static const vector<vector<double>> mex_hat{{'); end
	for i=0:(total_nrns-1)
		for j=1:length(comb_syn_wts)
			if output_cpp fprintf(output_cpp,'%f',comb_syn_wts(i+1,j)); end
            if output_csv fprintf(output_csv,'%f',comb_syn_wts(i+1,j)); end
			if j ~= length(comb_syn_wts)
				if output_cpp fprintf(output_cpp,','); end
                if output_csv fprintf(output_csv,','); end
			end
		end
		if i ~= (total_nrns-1)
			if output_cpp fprintf(output_cpp,'},\n{'); end
            if output_csv fprintf(output_csv,'\n'); end
		end	
		if (mod(i,grid_size_target*3)==0)
			fprintf("%.3g%% completed\n",i/total_nrns*100);
		end
	end
	if output_cpp fprintf(output_cpp,'}};'); end
    if show_2d_plot
        imagesc(reshape(comb_syn_wts(1,1:end),grid_size_target,grid_size_target));
    end
end
if sample_matrix
	po(2)=0; % turn off file writing for sample
    start_y_shift = start_y_shift + 4;
    start_x_shift = start_x_shift - 1;
    if alt_weights == 0
	    synapse_weights=nrn_syn_wts(start_x_shift,start_y_shift,filter_highval,highval,highval_thres,p,po);
    end
	synapse_weights2=rotate_weights(po,Rz,synapse_weights);
	synapse_weights3=shift_weights(po,1,synapse_weights2);
	synapse_weights4=crop_weights(po,synapse_weights3);
    imagesc(synapse_weights4);
end

if write_to_csv fclose(output_csv); end
if write_to_cpp fclose(output_cpp); end

function synapse_weights2=rotate_weights(po,Rz,synapse_weights)
	% apply rotation to synapse weights matrix

	grid_size=po(5);grid_size_target=po(8);

	% create rotation
	synapse_weights = reshape(synapse_weights,grid_size,grid_size);
    synapse_weights2 = zeros(grid_size);
    for y=1:grid_size
        for x=1:grid_size
            i=((y-1)*grid_size)+x;
            z=synapse_weights(i); 
            center_of_rot=grid_size/2;
            r_x_shift = x - center_of_rot;
            r_y_shift = y - center_of_rot;         
            rv = Rz*[r_x_shift;r_y_shift;z];
            rv(1)=rv(1)+center_of_rot;
            rv(2)=rv(2)+center_of_rot;
            X(i)=rv(1);Y(i)=rv(2);Z(i)=rv(3);
            %fprintf("x:%d y:%d\n",floor(rv(1))+1,floor(rv(2)));
            %{
            if floor(rv(1)) > 0 && floor(rv(1)) <= grid_size && ...
               floor(rv(2)) > 0 && floor(rv(2)) <= grid_size
            	synapse_weights2(x,y)=synapse_weights(floor(rv(1)),floor(rv(2)));
            end
            %}
        	%% convert fractions to whole number indicies and values
        	%% split values across indicies according to their fractions
        	
       	    x_max=ceil(rv(1));
       	    x_min=floor(rv(1));
       	    y_max=ceil(rv(2));
       	    y_min=floor(rv(2));
        	for x2=1:2
        		for y2=1:2
	        		if x_min > 0 && x_max <= grid_size && ...
	               	   y_min > 0 && y_max <= grid_size
	               	   if x2==1 && y2 ==1
	               	   	 synapse_weights2(x_min,y_min)= ...
	               	   	 synapse_weights2(x_min,y_min)+rv(3)*.5* ...
	               	   	 (1-mod(rv(1),1)+1-mod(rv(2),1))/2;
	               	   end
	               	   if x2==2 && y2 ==1
	               	   	 synapse_weights2(x_max,y_min)= ...
	               	   	 synapse_weights2(x_max,y_min)+rv(3)*.5* ...
	               	   	 (mod(rv(1),1)+1-mod(rv(2),1))/2;
	               	   end
	               	   if x2==1 && y2 ==2
	               	   	 synapse_weights2(x_min,y_max)= ...
	               	   	 synapse_weights2(x_min,y_max)+rv(3)*.5* ...
	               	   	 (1-mod(rv(1),1)+mod(rv(2),1))/2;
	               	   end
	               	   if x2==2 && y2 ==2
	               	   	 synapse_weights2(x_max,y_max)= ...
	               	   	 synapse_weights2(x_max,y_max)+rv(3)*.5* ...
	               	   	 (mod(rv(1),1)+mod(rv(2),1))/2;
	               	   end
	               	end
	            end
        	end
        	
        end
    end
end

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
		%y_pd_bias=1;
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

function synapse_weights=nrn_syn_wts(x_shift,y_shift,filter_highval,highval,highval_thres,p,po,synapse_weights);
	% generate all synapse weights for one neuron

   	grid_size=po(5);iter=po(6);synapse_weights=[];
	for y=1:grid_size
		for x=1:grid_size
			z=cent_surr_tile(x,y,x_shift,y_shift,filter_highval,highval,highval_thres,p,po);
			synapse_weights = [synapse_weights,z];
		end
	end	
end

function z=cent_surr_tile(x,y,x_shift,y_shift,filter_highval,highval,highval_thres,p,po)
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
            
			if mod(j,2) ~= 0
				x_shift2 = x_shift2 + grid_size_target/4;
			end
            %}
			z=z+cent_surr(x,y,x_shift2,y_shift2,filter_highval,highval,highval_thres,p);
		end
	end
end

function z=cent_surr(x,y,x_shift,y_shift,filter_highval,highval,highval_thres,p)
	% center-surround function
	x=(x-x_shift);
	y=(y-y_shift);
	p1=p(1);p2=p(2);p3=p(3);p4=p(4);p5=p(5);p6=p(6);p7=p(7);p8=p(8);p9=p(9);
	p10=p(10);p11=p(11);p12=p(12);p13=p(13);p14=p(14);p15=p(15);p16=p(16);p17=p(17);
	% difference of gaussians function creates the center-surround
	z=((p1/sqrt(p2*pi).*exp(-(x.^p3/p4) ...
		-(y.^p5/p6)))*p7-(p8/sqrt(p9*pi) ...
		.*exp(-(p10*x.^p11/p12)-(p13*y.^p14/p15)))*p16)-p17;
    z=z*.035;
    %highval_thres = .006;
    lowval_thres = .002;%.001;%.003;
    %{
    if filter_highval && z >= highval_thres
            z = highval;
        elseif filter_highval && z < highval_thres
            z = 0;
    end
    %}
    %{
    if z >= highval_thres
        %z = highval;
    end
    %}
    if z < lowval_thres
        z = 0;
    end
    %}
    if z < 0
        z = 0;
    end
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