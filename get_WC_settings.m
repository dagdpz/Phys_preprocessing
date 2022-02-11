function handles=get_WC_settings(handles)
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
handles.WC.int_factor = 1;                  % for potential interpolation for more datapoints to classify
handles.WC.interpolation ='n';              % Interpolationused or not
handles.WC.stdmax = 100;                    % Artifact rejection threshold in std

% FEATURE SELECTION
handles.WC.features = 'wavpcarawtime';      % features to be considered (in any order: wav(elets),pca,raw (datapoints),time,deriv(ates)
handles.WC.wavelet='haar';                  % choice of wavelet family for wavelet features
handles.WC.exclusioncrit = 'thr';           % this part is weird to me as well,
handles.WC.exclusionthr = 0.9;              % features are excluded, until no feature pairs are correlated more than exclusionthr  %def R^2 = 0.80
handles.WC.maxinputs = 9;                   % number of feature inputs to the clustering 
handles.WC.scales = 4;                      % scales for wavelet decomposition

% CLUSTERING 
handles.WC.num_temp = 18;                   % number of temperatures 
handles.WC.mintemp = 0;                     % minimum temperature
handles.WC.maxtemp = 0.18;                  % maximum temperature  
handles.WC.tempstep = 0.01;                 % temperature step
handles.WC.SWCycles = 100;                  % number of montecarlo iterations
handles.WC.KNearNeighb = 11;                % number of nearest neighbors
handles.WC.max_spikes2cluster = 40000;      % maximum number of spikes to cluster
handles.WC.min_clus_abs = 100;              % Minimum cluster size number of spikes
handles.WC.min_clus_rel = 0.005;            % Minimum cluster size as fraction of all spikes
handles.WC.max_nrclasses = 11;              % Maximum number of clsuters
handles.WC.template_sdnum = 5;              % max radius of cluster in std devs. for classifying rest
handles.WC.classify_space='features';       % for classifying rest only
handles.WC.classify_method= 'linear';       % for classifying rest only

% PLOTTING
handles.WC.temp_plot = 'log';               % temperature plot in log scale
handles.WC.max_spikes2plot = 1000;          % maximum number of spikes to plot.
handles.WC.max_nrclasses2plot = 8;          % not quite sure where this is used

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