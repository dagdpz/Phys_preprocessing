function ph_simulate_history(monkey,dateback)
monkey='Cornelius';
dateback='10000000';

dbfolder=['C:\Users\lschneider\Dropbox\'];
base_folder=['Y:\Data\All_phys_preprocessing_log\'];
foldername=[base_folder monkey '_phys' filesep];
if ~exist(foldername,'dir')
    mkdir(base_folder,[monkey '_phys']);
end
%% defaults

handles.RAM = 24;   % SYSTEM MEMORY in GB
handles.dtyperead = 'single';         % Data TYPE                                          % Default for BR, TD
handles.dtypewrite = handles.dtyperead;

%FOR?
handles.sys = 'TD'; % RECORDING SYSTEM
handles.rawname = '*.tdtch';% RAW DATAFILES NAME
handles.blockfile=0; % ????

% FILTERING: LINE NOISE
handles.WC.linenoisecancelation = 0;                                           % 1 for yes; 0 for no
handles.WC.linenoisefrequ = 50;
handles.WC.transform_factor = 0.25;                                        % microVolts per bit for higher accuracy when saved as int16 after filtering; Default for BR
handles.WC.iniartremovel = 1;               % first 40 samples

% DETECTION
handles.WC.w_pre = 10;
handles.WC.w_post = 22;
handles.WC.ref = 0.001;
handles.WC.int_factor = 2;
handles.WC.interpolation ='y';
handles.WC.stdmax = 100;

% FEATURE SELECTION
%handles.WC.features = 'wavpcarawderiv';    %choice of spike features: wav: wavelet decomposition; pca: principle component analyses; raw: raw waveforms; deriv: first derivative of the raw waveforms
handles.WC.features = 'wavpcaraw';
handles.WC.wavelet='haar';                 %choice of wavelet family for wavelet features
handles.WC.exclusioncrit = 'thr';          % this part is weird to me as well,
handles.WC.exclusionthr = 0.8;             % features are excluded, until no feature pairs are correlated more than exclusionthr  %def R^2 = 0.80
handles.WC.maxinputs = 11;   %15 %17, 15              %number of inputs to the clustering def. 11
handles.WC.scales = 4;                     %scales for wavelet decomposition


% CLUSTERING - first 4 dont make sense, one is not needed
handles.WC.num_temp = 18;                  %number of temperatures; def 25
handles.WC.mintemp = 0;                    %minimum temperature
handles.WC.maxtemp = 0.18;                 %maximum temperature def 0.25
handles.WC.tempstep = 0.01;                %temperature step

handles.WC.SWCycles = 100;  % def. 1000    %number of montecarlo iterations
handles.WC.KNearNeighb = 11;               %number of nearest neighbors

%handles.WC.chunk=5;                        %length of pieces into which file has to be splitted
handles.WC.max_spikes2cluster = 40000;     % maximum number of spikes to cluster, if more take only this amount of randomly chosen spikes, others are set into cluster 0
% check! should be: %maximum
% number of spikes used for
% clustering, rest is forced by
% `????
% handles.stab = 0.8;                      %stability condition for selecting the temperature

%For clustering, clear definition difficult
handles.WC.min_clus_abs = 10;
handles.WC.min_clus_rel = 0.005;          %Default: 0.005% alternative: 0.0035
handles.WC.max_nrclasses = 8;
handles.WC.template_sdnum = 5;             % max radius of cluster in std devs. for classifying rest

handles.WC.classify_space='spikeshapesfeatures'; %% for classifying rest only?
handles.WC.classify_method= 'linear'; %% for classifying rest only?

% PLOTTING
handles.WC.temp_plot = 'log';              % temperature plot in log scale
handles.WC.max_spikes2plot = 1000;         %maximum number of spikes to plot.
handles.WC.max_nrclasses2plot = 8;


%% inputs
handles.WC.threshold ='neg';
handles.WC.StdThrSU = 5;
handles.WC.StdThrMU = 5;
handles.WC.hp ='but';
handles.WC.hpcutoff =333;
handles.WC.lpcutoff =5000;
handles.WC.cell_tracking_distance_limit=50;
handles.WC.remove_ini=1;

handles.LFP.notch_filter1 = [49.9 50.1];
handles.LFP.notch_filter2 = [49.9 50.1];
handles.LFP.HP_filter     = 1;
handles.LFP.LP_bw_filter  = 250;
handles.LFP.LP_med_filter = 150;
    

%% define sessions for this monkey
Sessions=dir(['Y:\Data\' monkey '_phys_combined_monkeypsych_TDT']);
Sessions={Sessions([Sessions.isdir]).name};

%% load sortcode excel
[~,~,sortcode_excel]=xlsread([dbfolder 'DAG' filesep 'phys' filesep monkey '_phys_dpz' filesep monkey(1:3) '_plx_files.xlsx'],'in_use');
for k=1:size(sortcode_excel,2)
    title=sortcode_excel{1,k};
    idx.(title)=k;
end
excel_sessions=sortcode_excel(2:end,idx.Date);
excel_blocks=sortcode_excel(2:end,idx.Block);
excel_sorttype=sortcode_excel(2:end,idx.Sorttype);
excel_Plx_file=sortcode_excel(2:end,idx.Plx_file_extension);

excel_sessions=cellfun(@(x) num2str(x),excel_sessions,'UniformOutput',false);
handles.TODO.WCFromBB=1;
handles.TODO.CombineTDTandMP=1;
handles.TODO.DISREGARDLFP                = 0; %not best solution?
handles.TODO.DISREGARDSPIKES             = 0; %not best solution either -> this is limited to data with plx files(?)
unique_sorttypes=unique(excel_sorttype);

for ex={'attempted','executed'}
filename=[foldername ex{:} '__' dateback '-'];
counter=0; % alternatively load in highest existing file HHMM?
for T=1:numel(unique_sorttypes)
    
    handles.TODO.PLXFromWCFromBB=0;
    handles.TODO.PLXFromSnippets=0;
    handles.TODO.PLXFromRealignedSnippets=0;
    sorttype=unique_sorttypes{T};
    ses=unique(excel_sessions(ismember(excel_sorttype,{sorttype})));
    ses=intersect(ses,Sessions);
    handles.sessions=ses;
    handles.dates= sort(str2num(cell2mat(handles.sessions)));
    
    switch sorttype
        case 'from_BB'
            handles.TODO.PLXFromWCFromBB=1;
            handles.TODO.PLXFromSnippets=0;
            handles.TODO.PLXFromRealignedSnippets=0;
        case 'Snippets'  
            handles.TODO.PLXFromWCFromBB=0;
            handles.TODO.PLXFromSnippets=1;
            handles.TODO.PLXFromRealignedSnippets=0;
        case 'realigned'
            handles.TODO.PLXFromWCFromBB=0;
            handles.TODO.PLXFromSnippets=0;
            handles.TODO.PLXFromRealignedSnippets=1;
    end
    
    %% simulate next plx file?
    for s=1:numel(ses)
        versions=[excel_Plx_file{ismember(excel_sessions,ses(s))}];
        handles.plx_version_per_block.([monkey(1:3) '_' ses{s}])=versions;
    end
    
    counter=counter+1;
    save([filename sprintf('%04d',counter)],'handles')
end
end
end