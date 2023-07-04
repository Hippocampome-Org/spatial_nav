%{
  Combined plot of multiple neuron groups' spikes
%}

% params
Ts=500;%3000;%500; % start time to plot
Te=Ts+2000;%2500;%size(SPKste,1); % end time to plot
Ns=1; % starting index of spikes to plot
Ne=1600;%1764; % ending index of principle cell spikes to plot
Nei=833;%588; % ending index of interneuron spikes to plot
Nei_extra=1; % add additional inhibitory neuron count. E.g., when AxoAxon neuron have 1 more count then Bask and BaskMP
num_nrns=(Ne*3)+(Nei*3)+Nei_extra; % total neuron number
Pm=5; % plot marker size
N=Ne-Ns; % total principle cells
Ni=Nei-Ns; % total interneurons
Randomize=1; % randomize order of neurons in each neuron type group
ShowLegend=1;

clf; initOAT;

% read spikes
SRste = SpikeReader('../results/spk_MEC_LII_Stellate.dat');
SRaxa = SpikeReader('../results/spk_EC_LII_Axo_Axonic.dat');
SRbmu = SpikeReader('../results/spk_EC_LII_Basket_Multipolar.dat');
SRbas = SpikeReader('../results/spk_MEC_LII_Basket.dat');
SRpyr = SpikeReader('../results/spk_CA1_Pyramidal.dat');
SRmpy = SpikeReader('../results/spk_EC_LI_II_Multipolar_Pyramidal.dat');
SPKste = SRste.readSpikes(1);
SPKaxa = SRaxa.readSpikes(1);
SPKbmu = SRbmu.readSpikes(1);
SPKbas = SRbas.readSpikes(1);
SPKpyr = SRpyr.readSpikes(1);
SPKmpy = SRmpy.readSpikes(1);
if Randomize
    SPKste = SPKste(:, randperm(size(SPKste, 2)));
    SPKaxa = SPKaxa(:, randperm(size(SPKaxa, 2)));
    SPKbmu = SPKbmu(:, randperm(size(SPKbmu, 2)));
    SPKbas = SPKbas(:, randperm(size(SPKbas, 2)));
    SPKpyr = SPKpyr(:, randperm(size(SPKpyr, 2)));
    SPKmpy = SPKmpy(:, randperm(size(SPKmpy, 2)));
end

% filter spikes
[Yste,Xste]=retrieve_spikes(SPKste,Ts,Te,Ns,Ne);
[Yaxa,Xaxa]=retrieve_spikes(SPKaxa,Ts,Te,Ns,Nei+Nei_extra);
[Ybmu,Xbmu]=retrieve_spikes(SPKbmu,Ts,Te,Ns,Nei);
[Ybas,Xbas]=retrieve_spikes(SPKbas,Ts,Te,Ns,Nei);
[Ypyr,Xpyr]=retrieve_spikes(SPKpyr,Ts,Te,Ns,Ne);
[Ympy,Xmpy]=retrieve_spikes(SPKmpy,Ts,Te,Ns,Ne);

% plot
hold on
scatter(Yste,Xste,Pm,"filled");
scatter(Yaxa,Xaxa+N+Nei_extra,Pm,"filled");
scatter(Ybmu,Xbmu+(N+Ni)+Nei_extra,Pm,"filled");
scatter(Ybas,Xbas+(N+Ni*2)+Nei_extra,Pm,"filled");
scatter(Ympy,Xmpy+(N+Ni*3)+Nei_extra,Pm,"filled");
scatter(Ypyr,Xpyr+(N*2+Ni*3)+Nei_extra,Pm,"filled");
hold off
title("Spike Times", 'FontSize', 18);
axis('tight');
xlabel('Time', 'FontSize', 16);
ylabel('Neuron Number', 'FontSize', 16);
ylim([1,num_nrns]); % ensure plot makes space for all neurons even if they don't fire
if ShowLegend
    legend('MEC LII Stellate',['EC LII Axo',newline,'Axonic'],['EC LII Basket',newline,'Multipolar'],'MEC LII Basket',['EC LI II Multi-',newline,'poler Pyramidal'],'CA1 Pyramidal');
    legend('FontSize', 13);
end

function [Y,X]=retrieve_spikes(SPK,Ts,Te,Ns,Ne)
  X=[];Y=[];
  %randomized=randperm(Ne-Ns);
  for y=Ts:Te
    for x=Ns:Ne
    %for x=randomized
      if SPK(y,x)==1 X=[X;x]; Y=[Y;y]; end
    end
  end
end