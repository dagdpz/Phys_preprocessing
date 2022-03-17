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