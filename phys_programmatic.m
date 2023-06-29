% Script for programmatic usage of phys_gui_working functionality. Now it
% allows to run either waveclus preprocessing (both positive and negative 
% thresholds, 4 STD threshold for MUA, 6 STD threshold for SUA) or creation 
% of combined data with spikes and LFP.

% Put dates in numeric format YYYYMMDD below if you want to do waveclus
% preclustering for those sessions with currently upper threshold 6 STD and
% lower threshold 4 STD. Both positive and negative thresholds are used.
% Leave empty if you don't need wc preprocessing.
WC_dates = [20230622, 20230623];

% Also use an array of dates in numeric format YYYYMMDD to run combined
% with LFP.
% Leave empty if you don't need combined files.
combined_dates = []; % 20230601, 

for curr_WC_date = WC_dates
    
    % filter & waveclus data
    handles.user = 'LVasileva';
    handles.drive = 'Y:\';
    handles.monkey = 'Magnus';
    handles.monkey_phys = 'Magnus_phys';
    handles.dates = curr_WC_date;
    handles.threshold = 'both';
    handles.sessions = {num2str(curr_WC_date)};
    
    handles.TODO.SpikesFromWCdirectly = 0;
    handles.TODO.DisregardSpikes = 0;
    handles.TODO.UpdateSortcodeExcel = 0;
    handles.TODO.CreateExcelEntries = 0;
    handles.TODO.Assign_WC_waveforms_to_PLX = 0;
    handles.TODO.PLXFromWCFromBB = 0;
    handles.TODO.PLXFromRealignedSnippets = 0;
    handles.TODO.PLXFromSnippets = 0;
    handles.TODO.TDTSnippetsSortcodeFromPLX = 0;
    handles.TODO.DisregardLFP = 0;
    handles.TODO.WCFromBB = 1;
    handles.TODO.SynapseTankToOldFormat = 0;
    handles.TODO.CombineTDTandMP = 0;
    
    handles.RAM = 24;
    handles.dtyperead = 'single';
    handles.dtypewrite = 'single';
    handles.sys = 'TD';
    handles.rawname = '*.tdtch';
    handles.blockfile = 0;
    
    handles.WC.linenoisecancelation = 0;
    handles.WC.linenoisefrequ = 50;
    handles.WC.transform_factor = 0.2500;
    handles.WC.iniartremovel = 1;
    handles.WC.w_pre = 10;
    handles.WC.w_post = 22;
    handles.WC.ref = 1.0000e-03;
    handles.WC.int_factor = 1;
    handles.WC.interpolation = 'n';
    handles.WC.stdmax = 100;
    handles.WC.features = 'wavrawtimederiv';
    handles.WC.wavelet = 'haar';
    handles.WC.exclusioncrit = 'thr';
    handles.WC.exclusionthr = 0.9000;
    handles.WC.maxinputs = 9;
    handles.WC.scales = 4;
    handles.WC.num_temp = 18;
    handles.WC.mintemp = 0;
    handles.WC.maxtemp = 0.1800;
    handles.WC.tempstep = 0.0100;
    handles.WC.SWCycles = 100;
    handles.WC.KNearNeighb = 11;
    handles.WC.max_spikes2cluster = 40000;
    handles.WC.min_clus_abs = 100;
    handles.WC.min_clus_rel = 0.0050;
    handles.WC.max_nrclasses = 11;
    handles.WC.template_sdnum = 5;
    handles.WC.classify_space = 'features';
    handles.WC.classify_method = 'linear';
    handles.WC.temp_plot = 'log';
    handles.WC.max_spikes2plot = 1000;
    handles.WC.max_nrclasses2plot = 8;
    handles.WC.threshold = 'both';
    handles.WC.StdThrSU = 6;
    handles.WC.StdThrMU = 4;
    handles.WC.hp = 'but';
    handles.WC.hpcutoff = 333;
    handles.WC.lpcutoff = 5000;
    handles.WC.cell_tracking_distance_limit = 50;
    handles.WC.remove_ini = 1;
    
    phys_gui_execute(handles)

end

for curr_combined_date = combined_dates

    % create combined with fromWCdirectly, LFP, and spikes
    handles.user = 'LVasileva';
    handles.drive = 'Y:\';
    handles.monkey = 'Magnus';
    handles.monkey_phys = 'Magnus_phys';
    handles.dates = curr_combined_date;
    handles.threshold = 'neg';
    handles.sessions = {num2str(curr_combined_date)};
    
    handles.TODO.SpikesFromWCdirectly = 1;
    handles.TODO.DisregardSpikes = 0;
    handles.TODO.UpdateSortcodeExcel = 0;
    handles.TODO.CreateExcelEntries = 0;
    handles.TODO.Assign_WC_waveforms_to_PLX = 0;
    handles.TODO.PLXFromWCFromBB = 0;
    handles.TODO.PLXFromRealignedSnippets = 0;
    handles.TODO.PLXFromSnippets = 0;
    handles.TODO.TDTSnippetsSortcodeFromPLX = 0;
    handles.TODO.DisregardLFP = 0;
    handles.TODO.WCFromBB = 0;
    handles.TODO.SynapseTankToOldFormat = 0;
    handles.TODO.CombineTDTandMP = 1;
    
    handles.LFP.notch_filter1 = [49.9000 50.1000];
    handles.LFP.notch_filter2 = [99.9000 100.1000];
    handles.LFP.HP_filter = 1;
    handles.LFP.LP_bw_filter = 150;
    handles.LFP.LP_med_filter = 250;
    
    phys_gui_execute(handles)

end
