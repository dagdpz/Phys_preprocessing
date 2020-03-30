function settings=ph_get_preprocessing_settings(monkey_phys,executed)
if nargin<1
monkey_phys='TDT_brain_phys';
executed='executed';
end

folder=['Y:\Data\All_phys_preprocessing_log\' monkey_phys filesep ];
files=dir([folder executed '*']);
filenames={files.name};
settings=struct();
for f=1:numel(filenames)
   load([folder filenames{f}]);
   sessions=handles.sessions;
    for s=1:numel(sessions)
        sttng=struct();
        s_fname=[monkey_phys(1:3) '_' sessions{s}];
        if ~isfield(settings,s_fname)
            settings.(s_fname)=struct();
        end
        if handles.TODO.WCFromBB
            settings.(s_fname).WC=handles.WC;
        end
        if  handles.TODO.PLXFromWCFromBB
            versions_per_block=handles.plx_version_per_block.(s_fname);
            for b=1:numel(versions_per_block)
            settings.(s_fname).plx_version_per_block(b)=versions_per_block(b);
            settings.(s_fname).WC_per_sortcode.(['from_BB_blocks_' num2str(b) '_sortcode_' sprintf('%02d',versions_per_block(b)) ])=settings.(s_fname).WC; % last WC settings applied before plx creation
            end
        end
        if  handles.TODO.CombineTDTandMP 
            settings.(s_fname).LFP=handles.LFP;
        end
        
    end       
end





end