function ph_simulate_history(monkey,dateback)
% this function was used to create the initial preprocessing logs and
% should not be needed any more. Basically, it pretends that some
% preprocessing was performed way in the past (f.e. in the year 1000) given
% certain default settings that are defined later on here
% notes (!)  indicates these defaults are different from current defaults
%       (!!) indicates confusion of LP and HP
% monkey='Cornelius';
% dateback='10000000';

dbpath=DAG_get_Dropbox_path;
drive=DAG_get_server_IP;
base_folder=[drive 'Data' filesep 'All_phys_preprocessing_log' filesep];
foldername=[base_folder monkey '_phys' filesep];
if ~exist(foldername,'dir')
    mkdir(base_folder,[monkey '_phys']);
end

%% defaults
handles.RAM = 24;                           % SYSTEM MEMORY in GB
handles.dtyperead = 'single';               % Data TYPE             
handles.dtypewrite = handles.dtyperead;
handles.sys = 'TD';                         % RECORDING SYSTEM
handles.rawname = '*.tdtch';                % RAW DATAFILES NAME
handles.blockfile=0;                        % not used?

% % ARRAY CONFIGURATION -> relevant for arraynoisecancellation, currently not used
% handles.numArray = 6;
% handles.numchan = 64;                                                       % Channels per Array
% handles.arraynoisecancelation = 0;
%
% FILTERING: LINE NOISE
handles.WC.linenoisecancelation = 0;        % 1 for yes; 0 for no
handles.WC.linenoisefrequ = 50;             % Line noise frequency
handles.WC.transform_factor = 0.25;         % microVolts per bit for higher accuracy when saved as int16 after filtering;
handles.WC.iniartremovel = 1;               % ignore first 40 samples

% DETECTION
handles.WC.w_pre = 10;                      % N samples for snippet before threshold crossing
handles.WC.w_post = 22;                     % N samples for snipept after threshold crossing
handles.WC.ref = 0.001;                     % 'Refractory period' in seconds
handles.WC.int_factor = 2;                  % (!) for potential interpolation for more datapoints to classify
handles.WC.interpolation ='y';              % (!) Interpolationused or not
handles.WC.stdmax = 100;                    % Artifact rejection threshold in std

% FEATURE SELECTION
handles.WC.features = 'wavpcaraw';          % (!) features to be considered (in any order: wav(elets),pca,raw (datapoints),time,deriv(ates)
handles.WC.wavelet='haar';                  % choice of wavelet family for wavelet features
handles.WC.exclusioncrit = 'thr';           % this part is weird to me as well,
handles.WC.exclusionthr = 0.8;              % (!) features are excluded, until no feature pairs are correlated more than exclusionthr  %def R^2 = 0.80
handles.WC.maxinputs = 11;                  % (!) number of feature inputs to the clustering 
handles.WC.scales = 4;                      % scales for wavelet decomposition

% CLUSTERING 
handles.WC.num_temp = 18;                   % number of temperatures 
handles.WC.mintemp = 0;                     % minimum temperature
handles.WC.maxtemp = 0.18;                  % maximum temperature  
handles.WC.tempstep = 0.01;                 % temperature step
handles.WC.SWCycles = 100;                  % number of montecarlo iterations
handles.WC.KNearNeighb = 11;                % number of nearest neighbors
handles.WC.max_spikes2cluster = 40000;      % maximum number of spikes to cluster
handles.WC.min_clus_abs = 10;               % (!) Minimum cluster size number of spikes
handles.WC.min_clus_rel = 0.005;            % Minimum cluster size as fraction of all spikes
handles.WC.max_nrclasses = 8;               % (!) Maximum number of clsuters
handles.WC.template_sdnum = 5;              % max radius of cluster in std devs. for classifying rest
handles.WC.classify_space='features';       % (!) for classifying rest only
handles.WC.classify_method= 'linear';       % for classifying rest only

% PLOTTING
handles.WC.temp_plot = 'log';               % temperature plot in log scale
handles.WC.max_spikes2plot = 1000;          % maximum number of spikes to plot.
handles.WC.max_nrclasses2plot = 8;          % not quite sure where this is used


%% inputs
handles.WC.threshold ='neg';
handles.WC.StdThrSU = 5;                   % (!)
handles.WC.StdThrMU = 5;                   % (!)
handles.WC.hp ='but';
handles.WC.hpcutoff =333;                  % (!!) mistake here?? -swap lp and hp
handles.WC.lpcutoff =5000;                 % (!!) mistake here??
handles.WC.cell_tracking_distance_limit=50;
handles.WC.remove_ini=1;

handles.LFP.notch_filter1 = [49.9 50.1];
handles.LFP.notch_filter2 = [49.9 50.1];
handles.LFP.HP_filter     = 1;
handles.LFP.LP_bw_filter  = 250;
handles.LFP.LP_med_filter = 150;


%% define sessions for this monkey
Sessions=dir([drive 'Data' filesep monkey '_phys_combined_monkeypsych_TDT']);
Sessions={Sessions([Sessions.isdir]).name};

%% load sortcode excel
[~,~,sortcode_excel]=xlsread([dbpath 'DAG' filesep 'phys' filesep monkey '_phys_dpz' filesep monkey(1:3) '_plx_files.xlsx'],'in_use');
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