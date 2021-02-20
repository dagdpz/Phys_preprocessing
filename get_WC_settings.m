function handles=get_WC_settings(handles)
%% defaults
handles.RAM = 24;   % SYSTEM MEMORY in GB
handles.dtyperead = 'single';         % Data TYPE                                          % Default for BR, TD
handles.dtypewrite = handles.dtyperead;

%FOR?
handles.sys = 'TD'; % RECORDING SYSTEM
handles.rawname = '*.tdtch';% RAW DATAFILES NAME
handles.blockfile=0; % ????

% % ARRAY CONFIGURATION -> relevant for arraynoisecancellation
% handles.numArray = 6;
% handles.numchan = 64;                                                       % Channels per Array
% handles.arraynoisecancelation = 0;
%
% FILTERING: LINE NOISE
handles.WC.linenoisecancelation = 0;                                           % 1 for yes; 0 for no
handles.WC.linenoisefrequ = 50;
handles.WC.transform_factor = 0.25;                                        % microVolts per bit for higher accuracy when saved as int16 after filtering; Default for BR
handles.WC.iniartremovel = 1;               % first 40 samples

% DETECTION
handles.WC.w_pre = 10;
handles.WC.w_post = 22;
handles.WC.ref = 0.001;
handles.WC.int_factor = 1;
handles.WC.interpolation ='n';
handles.WC.stdmax = 100;

% FEATURE SELECTION
handles.WC.features = 'wavpcarawtime'; %'wavpcarawderiv'
handles.WC.wavelet='haar';                 %choice of wavelet family for wavelet features
handles.WC.exclusioncrit = 'thr';          % this part is weird to me as well,
handles.WC.exclusionthr = 0.9;             % features are excluded, until no feature pairs are correlated more than exclusionthr  %def R^2 = 0.80
handles.WC.maxinputs = 9;   %15 %17, 15    % number of inputs to the clustering def. 11
handles.WC.scales = 4;                     % scales for wavelet decomposition

% CLUSTERING - first 4 dont make sense, one is not needed
handles.WC.num_temp = 18;                   % number of temperatures; def 25
handles.WC.mintemp = 0;                     % minimum temperature
handles.WC.maxtemp = 0.18;                  % maximum temperature def 0.25
handles.WC.tempstep = 0.01;                 % temperature step
handles.WC.SWCycles = 100;  % def. 1000     % number of montecarlo iterations
handles.WC.KNearNeighb = 11;                % number of nearest neighbors

handles.WC.max_spikes2cluster = 40000;      % maximum number of spikes to cluster, if more take only this amount of randomly chosen spikes, others are set into cluster 0

%For clustering, clear definition difficult
handles.WC.min_clus_abs = 100;
handles.WC.min_clus_rel = 0.005;%0.0025;          %Default: 0.005% alternative: 0.0035
handles.WC.max_nrclasses = 11;
handles.WC.template_sdnum = 5;              % max radius of cluster in std devs. for classifying rest

handles.WC.classify_space='features';       % for classifying rest only
handles.WC.classify_method= 'linear';       % for classifying rest only

% PLOTTING
handles.WC.temp_plot = 'log';              % temperature plot in log scale
handles.WC.max_spikes2plot = 1000;         % maximum number of spikes to plot.
handles.WC.max_nrclasses2plot = 8;         %%???????????????????????????


%% inputs (overwritten in phys_gui_working)
handles.WC.threshold ='neg';
handles.WC.StdThrSU = 6;
handles.WC.StdThrMU = 3;
handles.WC.hp = 'bw';
handles.WC.hpcutoff =1000;
handles.WC.lpcutoff =333;
handles.WC.cell_tracking_distance_limit=50; %micrometers
handles.WC.remove_ini=1;


end