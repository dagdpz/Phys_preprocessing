function settings=ph_get_preprocessing_settings(monkey_phys,executed)
% This function is used to carry over waveclus settings used to generate
% given plx file that is about to get read in as sortcode information to create a TDT trial structure
% NOTE: The settings are read from preprocessing logs, and the WC settings
% used to create the given plx file are assumed to be the latest WC
% settings applied before creation of this specific plx file (in
% ph_combine_MP_and_TDT_data)

if nargin<1
    monkey_phys='TDT_brain_phys';
    executed='executed';
end
drive=DAG_get_server_IP;
folder=[drive 'Data' filesep 'All_phys_preprocessing_log' filesep monkey_phys filesep ];
files=dir([folder executed '*']);
filenames={files.name};
settings=struct();
for f=1:numel(filenames)
    load([folder filenames{f}]);
    sessions=handles.sessions;
    for s=1:numel(sessions)
        s_fname=[monkey_phys(1:3) '_' sessions{s}];
        if ~isfield(settings,s_fname)
            settings.(s_fname)=struct();
        end
        if handles.TODO.WCFromBB
            settings.(s_fname).WC=handles.WC;
            settings.(s_fname).WC_filename=filenames{f};
        end
        if  handles.TODO.PLXFromWCFromBB 
        %% if there was an error creating WC across several sessions, settings.(s_fname).WC can be not defined because there is no executed log file for this session with handles.TODO.WCFromBB
        %% in this specific case, take attempted ones into consideration
            versions_per_block=handles.plx_version_per_block.(s_fname);
            for b=1:numel(versions_per_block)
                settings.(s_fname).plx_version_per_block(b)=versions_per_block(b);
                settings.(s_fname).WC_per_sortcode.(['from_BB_blocks_' num2str(b) '_sortcode_' sprintf('%02d',versions_per_block(b)) ])=settings.(s_fname).WC; 
                settings.(s_fname).plx_filename=filenames{f};
            end
        end
        if  handles.TODO.CombineTDTandMP
            settings.(s_fname).LFP=handles.LFP;
            settings.(s_fname).LFP.filename=filenames{f};
        end
    end
end
end