function DAG_create_PLX(Session_as_num,monkey_phys,threshold,recordingnames,processing_mode)

Session_as_str=num2str(Session_as_num);
drive=DAG_get_server_IP;
DBpath=DAG_get_Dropbox_path;
DBfolder=[DBpath filesep 'DAG' filesep 'phys' filesep monkey_phys '_dpz' filesep];

%% load electrode depths for selecting which electrodes are useful
% AND for defining which blocks should be concatinated per channel
run([DBfolder 'Electrode_depths_' monkey_phys(1:3)]);
channels_to_process=unique([channels{cell2mat(Session)==Session_as_num}]);

%% CREATE PLX FILE(S) from snippets
%handles.par.sr = 24414.0625; % can this one be taken from the files themselves?
handles.threshold=threshold;
handles.sortcodes_folder        = [drive 'Data' filesep 'Sortcodes' filesep monkey_phys filesep Session_as_str filesep];          % path of recordings
handles.tank_folder             = [drive 'Data' filesep 'TDTtanks'  filesep monkey_phys filesep Session_as_str filesep];
handles.WC_concatenation_folder = [handles.sortcodes_folder 'WC' filesep];
%tank = [drive '\Data\TDTtanks' filesep monkey filesep num2str(Session_as_num) '\'];          % path of recordings
handles.task_times=[];
if strcmp(processing_mode,'PLXFromRealignedSnippets') || strcmp(processing_mode,'PLXFromSnippets')
    for ii =1:length(recordingnames)
        
        block_char       =recordingnames{ii}(strfind(recordingnames{ii},'-')+1:end);
        recname     =['blocks_' block_char];
        disp(['Processing: ' recname]);
        
        %         state_information = TDTbin2mat_working([drive 'Data\TDTtanks' filesep monkey], num2str(tankname), recordingnames{ii}, 'EXCLUSIVELYREAD',{'SVal'},'SORTNAME', 'Plexsormanually');
        
        data = TDTbin2mat_working([handles.tank_folder recordingnames{ii}], 'EXCLUSIVELYREAD',{'eNeu','SVal'},'SORTNAME', 'Plexsormanually');
        snippets=data.snips.eNeu;
        state_information=data.epocs.SVal;
        %         offs=[];
        %         %% on and offs are in seconds!
        %         offs_temp=state_information.onset(state_information.data>18);
        %         ons=state_information.onset(state_information.data<2);
        %         for t=1:numel(ons)
        %             offs(t)=offs_temp(find(offs_temp>ons(t),1,'first')) + 0.06; % adding 60 ms so
        %         end
        %         handles.task_times_per_block{ii}=[ons offs']; %% here i expect an error at some point - dimension mismatch
        
        
        if strcmp(processing_mode,'PLXFromRealignedSnippets')
            folder      =['RA_' recordingnames{ii} filesep];
            plxfilename=[handles.sortcodes_folder Session_as_str '_realigned_' recname '.plx'];
            handles.realign_snippets=1;
        elseif  strcmp(processing_mode,'PLXFromSnippets')
            folder      =['SN_' recordingnames{ii} filesep];
            plxfilename=[handles.sortcodes_folder Session_as_str '_' recname '.plx'];
            handles.realign_snippets=0;
        end
        
        handles.foldername=[handles.sortcodes_folder folder];
        if ~exist(handles.foldername,'dir')
            mkdir(handles.sortcodes_folder,folder);
        end
        snippets.data=snippets.data*1000; %debugged 20180723
        
        %% not sure any more what was the reasoning behind it, but apparently we go TDT->WC3->SPK->PLX
        
        TDT2WC3_from_snippets(handles,snippets);
        
        SPK = WC32SPK(handles); %% foldername is now part of the handles...?
        SPK.int_factor = 1;
        SPK2PLX(SPK,plxfilename);
    end
end

%% CREATE PLX FILE(S) from WC --> slightly different because WC files are concatinated across blocks with the same electrode depth
if strcmp(processing_mode,'PLXFromWCFromBB')
    handles.threshold ='neg';
%     handles.main_folder=[drive 'Data\TDTtanks' filesep monkey filesep num2str(Session_as_num) filesep];
%     handles.WC_concatenation_folder=[handles.main_folder 'WC' filesep];
    blocks_in_this_session=[block{cell2mat(Session)==Session_as_num}];
    temp_handles=handles;
    load([handles.WC_concatenation_folder 'concatenation_info'])
    load([handles.WC_concatenation_folder 'settings'])
    if isfield(handles,'output')
        handles=rmfield(handles,'output');
    end
            
    handles=DAG_rmobjects_from_struct(handles,1);
    for fn=fieldnames(temp_handles)'
        handles.(fn{:})=  temp_handles.(fn{:});
    end
    
    %handles.sr=sr;
    for b=blocks_in_this_session
        recname=['blocks_' num2str(b)];
        handles.blocksamplesperchannel=blocksamplesperchannel;
        handles.wheretofindwhat=wheretofindwhat;
        handles.whattofindwhere=whattofindwhere;
        handles.block=b;
        handles.channels=channels_to_process;
        SPK = WC32SPK_concatenated(handles);
        %SPK.int_factor = 2;
        
        % rescaling by block and channel!
        for chan=unique(SPK.channelID)'
            idx=SPK.channelID==chan;
            wmax=prctile(max(SPK.waveforms(idx,:),[],2),97)*1.5;
            wmin=prctile(min(SPK.waveforms(idx,:),[],2),3)*1.5;
            wf_scale(b,chan)=max(abs([wmin wmax]));
            if wf_scale(b,chan) == 0
                wf_scale(b,chan) = 1;
            end
            SPK.waveforms(idx,:)=SPK.waveforms(idx,:)/wf_scale(b,chan);
        end
        plxfilename=[handles.sortcodes_folder Session_as_str '_from_BB_' recname '.plx'];
        SPK2PLX(SPK,plxfilename);
    end
    % save scales used
    save([handles.WC_concatenation_folder 'concatenation_info'],'wf_scale','-append')
end
end