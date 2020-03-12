function DAG_update_phys_table(monkey)
dates=[20140101 20180101];
clean_data=0;

dag_drive_IP=DAG_get_server_IP;
DAG_user=getUserName;

protocolpath=['C' ':' filesep 'Users' filesep DAG_user filesep 'Dropbox' filesep 'DAG' filesep 'phys' filesep monkey '_dpz'];
% C:\Users\a.doming\Dropbox\DAG\phys\Linus_phys_dpz

if exist(protocolpath)~=7
    mkdir(protocolpath)
end

dir(protocolpath)


folder_with_session_days=strcat(dag_drive_IP, 'Data', filesep, [monkey '_combined_monkeypsych_TDT']);

[~, file_as_i_want_it_cell] = DAG_arrange_trials([monkey '_combined_monkeypsych_TDT'],folder_with_session_days, dates);
if isempty(file_as_i_want_it_cell)
    return;
end
files_for_input=file_as_i_want_it_cell(1:size(file_as_i_want_it_cell,1),1:2);

if clean_data
    MPA_clean_data(folder_with_session_days,dates)
end

Sel_all={'display',0,'runs_as_batches',1};
[out_comp,~,~]= monkeypsych_analyze_working(files_for_input,Sel_all);
         
for k=1:numel(out_comp)
    Input.Session(k)              = str2double(files_for_input{k,1}(end-7:end));
    Input.Run(k)                  = files_for_input{k,2};
    Input.N_Trials(k)             = numel(out_comp{k}.binary);
    IN                            = [out_comp{k}.states.state_abo]==-1 | [out_comp{k}.states.state_abo]>3;
    Input.initiated(k)            = sum(IN);
    Input.completed(k)            = sum([out_comp{k}.binary.completed]);    
    Input.hits(k)                 = sum([out_comp{k}.binary.success]);
    Input.hits_per_total(k)       = round(Input.hits(k)/Input.N_Trials(k)*100);
    Input.hits_per_initiated(k)   = round(Input.hits(k)/Input.initiated(k)*100);    
    Input.hits_per_completed(k)   = round(Input.hits(k)/Input.completed(k)*100);
    Input.Type{k,:}               = unique([out_comp{k}.task.type]);
    Input.Effector{k,:}           = unique([out_comp{k}.task.effector]);
    Input.Setup(k)                = unique([out_comp{k}.selected.setup]);
    Input.Reward_time{k,:}        = round(unique([out_comp{k}.task([out_comp{k}.task.reward_time]~=0).reward_time])*100)/100;
    
    if Input.Setup(k)==1
        voltage=reward_voltage(1); %11.6;
    elseif Input.Setup(k)==2
        voltage=reward_voltage(2); %11.3;
    elseif Input.Setup(k)==3
        voltage=reward_voltage(3); %11.3;
    elseif Input.Setup(k)==4
        voltage=reward_voltage(4); %11.3;
    else
        voltage=reward_voltage(5); %11.3;
    end
    Input.Reward_ml(k)                 = 0;
    valve_opening_times                = unique([out_comp{k}.task([out_comp{k}.task.reward_time]~=0).reward_time]);
    for rew_idx=1:numel(valve_opening_times)
        Amount_of_trials=sum([out_comp{k}.task([out_comp{k}.task.reward_time]~=0).reward_time]==valve_opening_times(rew_idx));
        ml_per_trial= DAG_get_ml_from_CalibrationInfo(CalibrationInfo,valve_opening_times(rew_idx),Input.Session(k),Input.Setup(k),voltage);
        Input.Reward_ml(k)=Input.Reward_ml(k)+Amount_of_trials*ml_per_trial;
    end
    Input.Reward_ml(k)                = round(Input.Reward_ml(k));
    Input.start_run(k)                = round(out_comp{k}.selected(1).run_start_time*100)/100;
    Input.end_run(k)                  = round(out_comp{k}.selected(end).run_end_time*100)/100;
    
    Input.choice_fraction(k)          = round(nanmean([out_comp{k}.binary.choice])*100);
    Input.left_chosen_base(k)         = round([out_comp{k}.counts.left_choice_percentage_successful_baseline]);  
    Input.left_chosen_stimulated(k)   = round([out_comp{k}.counts.left_choice_percentage_successful_microstim]);
    
   
    Input.reward_modulation_fraction{k,:}=round(nanmean([out_comp{k}.binary.reward_modulation])*100);
    Input.high_reward_chosen_fraction{k,:}=round(nansum([out_comp{k}.binary.reward_selected_large] & [out_comp{k}.binary.choice])...
         /(nansum([out_comp{k}.binary.reward_selected_large] & [out_comp{k}.binary.choice])+nansum([out_comp{k}.binary.reward_selected_small] & [out_comp{k}.binary.choice]))*100);
   
    Input.Sensor_L{k,:}=unique([out_comp{k}.binary.rest_sensor_1]);
    Input.Sensor_R{k,:}=unique([out_comp{k}.binary.rest_sensor_2]);
    Input.demanded_hand_fraction{k,:}=[round(nanmean([out_comp{k}.reaches.demanded_hand]==1)*100), round(nanmean([out_comp{k}.reaches.demanded_hand]==2)*100), round(nanmean([out_comp{k}.reaches.demanded_hand]==3)*100)];
    Input.reach_hand_fraction{k,:}=[round(nanmean([out_comp{k}.reaches(IN).reach_hand]==1)*100), round(nanmean([out_comp{k}.reaches(IN).reach_hand]==2)*100)];
    Input.R_hand_chosen_fraction{k,:}=round((nansum([out_comp{k}.reaches.demanded_hand]==3 & [out_comp{k}.reaches.reach_hand]==2))/nansum([out_comp{k}.reaches.demanded_hand]==3)*100);
    
    
    Input.x_positions{k,:}     = round(real(unique([out_comp{k}.saccades(~isnan(real([out_comp{k}.saccades.tar_pos]))).tar_pos, out_comp{k}.reaches(~isnan(real([out_comp{k}.reaches.tar_pos]))).tar_pos])));
    Input.y_positions{k,:}     = round(imag(unique([out_comp{k}.saccades(~isnan(real([out_comp{k}.saccades.tar_pos]))).tar_pos, out_comp{k}.reaches(~isnan(real([out_comp{k}.reaches.tar_pos]))).tar_pos])));
    Input.eye_fix_rad{k,:}     = unique([out_comp{k}.saccades(~isnan([out_comp{k}.saccades.fix_rad])).fix_rad]);
    Input.eye_fix_siz{k,:}     = unique([out_comp{k}.saccades(~isnan([out_comp{k}.saccades.fix_siz])).fix_siz]);
    Input.eye_tar_rad{k,:}     = unique([out_comp{k}.saccades(~isnan([out_comp{k}.saccades.tar_rad])).tar_rad]);
    Input.eye_tar_siz{k,:}     = unique([out_comp{k}.saccades(~isnan([out_comp{k}.saccades.tar_siz])).tar_siz]);
    Input.hnd_fix_rad{k,:}     = unique([out_comp{k}.reaches(~isnan([out_comp{k}.reaches.fix_rad])).fix_rad]);
    Input.hnd_fix_siz{k,:}     = unique([out_comp{k}.reaches(~isnan([out_comp{k}.reaches.fix_siz])).fix_siz]);
    Input.hnd_tar_rad{k,:}     = unique([out_comp{k}.reaches(~isnan([out_comp{k}.reaches.tar_rad])).tar_rad]);
    Input.hnd_tar_siz{k,:}     = unique([out_comp{k}.reaches(~isnan([out_comp{k}.reaches.tar_siz])).tar_siz]);
    
    Input.n_targets{k,:}      = unique([out_comp{k}.reaches(~isnan([out_comp{k}.reaches.n_targets])).n_targets, out_comp{k}.saccades(~isnan([out_comp{k}.saccades.n_targets])).n_targets]);
    Input.cue_x_pos{k,:}      = round(real(unique([out_comp{k}.saccades(~isnan(real([out_comp{k}.saccades.cue_pos]))).cue_pos, out_comp{k}.reaches(~isnan(real([out_comp{k}.reaches.cue_pos]))).cue_pos])));
    Input.cue_y_pos{k,:}      = round(imag(unique([out_comp{k}.saccades(~isnan(real([out_comp{k}.saccades.cue_pos]))).cue_pos, out_comp{k}.reaches(~isnan(real([out_comp{k}.reaches.cue_pos]))).cue_pos])));
    Input.convexities{k,:}    = unique([out_comp{k}.reaches(~isnan([out_comp{k}.reaches.selected_convexity])).selected_convexity, out_comp{k}.saccades(~isnan([out_comp{k}.saccades.selected_convexity])).selected_convexity]);
    Input.convex_sides{k,:}   = unique([out_comp{k}.reaches(isstr([out_comp{k}.reaches.selected_convex_sides])).selected_convex_sides, out_comp{k}.saccades(isstr([out_comp{k}.saccades.selected_convex_sides])).selected_convex_sides]);
    Input.targets_insp{k,:}   = numel([out_comp{k}.saccades([out_comp{k}.binary.completed]).targets_inspected])/sum([out_comp{k}.binary.completed]);
    
    Input.fix_acq_hnd{k,:}    =unique([out_comp{k}.timing.fix_time_to_acquire_hnd]); 
    Input.tar_acq_hnd{k,:}    =unique([out_comp{k}.timing.tar_time_to_acquire_hnd]); 
    Input.tar_inv_acq_hnd{k,:}=unique([out_comp{k}.timing.tar_inv_time_to_acquire_hnd]); 
    Input.fix_acq_eye{k,:}    =unique([out_comp{k}.timing.fix_time_to_acquire_eye]); 
    Input.tar_acq_eye{k,:}    =unique([out_comp{k}.timing.tar_time_to_acquire_eye]); 
    Input.tar_inv_acq_eye{k,:}=unique([out_comp{k}.timing.tar_inv_time_to_acquire_eye]); 
    
    Input.fix_hold{k,:}              =unique([out_comp{k}.timing.fix_time_hold]); 
    Input.fix_hold_var{k,:}          =unique([out_comp{k}.timing.fix_time_hold_var]); 
    Input.cue_hold{k,:}              =unique([out_comp{k}.timing.cue_time_hold]); 
    Input.cue_hold_var{k,:}          =unique([out_comp{k}.timing.cue_time_hold_var]); 
    Input.mem_hold{k,:}              =unique([out_comp{k}.timing.mem_time_hold]); 
    Input.mem_hold_var{k,:}          =unique([out_comp{k}.timing.mem_time_hold_var]); 
    
    Input.del_hold{k,:}              =unique([out_comp{k}.timing.del_time_hold]); 
    Input.del_hold_var{k,:}          =unique([out_comp{k}.timing.del_time_hold_var]); 
    
    Input.tar_inv_hold{k,:}          =unique([out_comp{k}.timing.tar_inv_time_hold]); 
    Input.tar_inv_hold_var{k,:}      =unique([out_comp{k}.timing.tar_inv_time_hold_var]); 
    Input.tar_hold{k,:}              =unique([out_comp{k}.timing.tar_time_hold]); 
    Input.tar_hold_var{k,:}          =unique([out_comp{k}.timing.tar_time_hold_var]);
    
    Input.ITI_success{k,:}                =unique([out_comp{k}.timing.ITI_success]); 
    Input.ITI_success_var{k,:}            =unique([out_comp{k}.timing.ITI_success_var]); 
    Input.ITI_fail{k,:}                   =unique([out_comp{k}.timing.ITI_fail]); 
    Input.ITI_fail_var{k,:}               =unique([out_comp{k}.timing.ITI_fail_var]); 
    Input.grace_time_eye{k,:}             =unique([out_comp{k}.timing.grace_time_eye]); 
    Input.grace_time_hand{k,:}            =unique([out_comp{k}.timing.grace_time_hand]); 
    
    
    Input.microstim_fraction(k) = round(nanmean([out_comp{k}.binary.microstim])*100);
    
    %% not necessarily correct....
    microstim_start_after_go_withnan  = unique([out_comp{k}.task([out_comp{k}.task.stim_state]==2 | ([out_comp{k}.task.stim_state]==3 & [out_comp{k}.task.type]==1) |[out_comp{k}.task.stim_state]==4 | [out_comp{k}.task.stim_state]==6 | [out_comp{k}.task.stim_state]==7 | [out_comp{k}.task.stim_state]==9).stim_start]);
    microstim_start_before_go_withnan = unique([out_comp{k}.task([out_comp{k}.binary.success] & (([out_comp{k}.task.stim_state]==3 & [out_comp{k}.task.type]~=1)| [out_comp{k}.task.stim_state]==5 | [out_comp{k}.task.stim_state]==10)).stim_to_state_end]);
    microstim_start_before_go_withnan = microstim_start_before_go_withnan(microstim_start_before_go_withnan<=0.2);
    Input.microstim_start{k,:}        = round([sort(microstim_start_before_go_withnan(~isnan(microstim_start_before_go_withnan)).*-1) microstim_start_after_go_withnan(~isnan(microstim_start_after_go_withnan))].*1000);
    microstim_states                  = unique([out_comp{k}.task.stim_state]);
    Input.microstim_state{k,:}        = microstim_states(~isnan(microstim_states));
          
    Input.Eye_RT_R_base_mean(k) =  round(nanmean([out_comp{k}.saccades([out_comp{k}.binary.eyetar_r] & [out_comp{k}.binary.success] & ~[out_comp{k}.binary.microstim]).lat])*1000);
    Input.Eye_RT_R_base_std(k)  =  round(nanstd([out_comp{k}.saccades([out_comp{k}.binary.eyetar_r] & [out_comp{k}.binary.success] & ~[out_comp{k}.binary.microstim]).lat])*1000);
    Input.Eye_RT_L_base_mean(k) =  round(nanmean([out_comp{k}.saccades([out_comp{k}.binary.eyetar_l] & [out_comp{k}.binary.success] & ~[out_comp{k}.binary.microstim]).lat])*1000);
    Input.Eye_RT_L_base_std(k)  =  round(nanstd([out_comp{k}.saccades([out_comp{k}.binary.eyetar_l] & [out_comp{k}.binary.success] & ~[out_comp{k}.binary.microstim]).lat])*1000);

    Input.Hnd_RT_R_base_mean(k) =  round(nanmean([out_comp{k}.reaches([out_comp{k}.binary.hndtar_r] & [out_comp{k}.binary.success] & ~[out_comp{k}.binary.microstim]).lat])*1000);
    Input.Hnd_RT_R_base_std(k)  =  round(nanstd([out_comp{k}.reaches([out_comp{k}.binary.hndtar_r] & [out_comp{k}.binary.success] & ~[out_comp{k}.binary.microstim]).lat])*1000);
    Input.Hnd_RT_L_base_mean(k) =  round(nanmean([out_comp{k}.reaches([out_comp{k}.binary.hndtar_l] & [out_comp{k}.binary.success] & ~[out_comp{k}.binary.microstim]).lat])*1000);
    Input.Hnd_RT_L_base_std(k)  =  round(nanstd([out_comp{k}.reaches([out_comp{k}.binary.hndtar_l] & [out_comp{k}.binary.success] & ~[out_comp{k}.binary.microstim]).lat])*1000);
    
    Input.Eye_RT_R_stim_mean(k) =  round(nanmean([out_comp{k}.saccades([out_comp{k}.binary.eyetar_r] & [out_comp{k}.binary.success] & [out_comp{k}.binary.microstim]).lat])*1000);
    Input.Eye_RT_R_stim_std(k)  =  round(nanstd([out_comp{k}.saccades([out_comp{k}.binary.eyetar_r] & [out_comp{k}.binary.success] & [out_comp{k}.binary.microstim]).lat])*1000);
    Input.Eye_RT_L_stim_mean(k) =  round(nanmean([out_comp{k}.saccades([out_comp{k}.binary.eyetar_l] & [out_comp{k}.binary.success] & [out_comp{k}.binary.microstim]).lat])*1000);
    Input.Eye_RT_L_stim_std(k)  =  round(nanstd([out_comp{k}.saccades([out_comp{k}.binary.eyetar_l] & [out_comp{k}.binary.success] & [out_comp{k}.binary.microstim]).lat])*1000);
 
    Input.Hnd_RT_R_stim_mean(k) =  round(nanmean([out_comp{k}.reaches([out_comp{k}.binary.hndtar_r] & [out_comp{k}.binary.success] & [out_comp{k}.binary.microstim]).lat])*1000);
    Input.Hnd_RT_R_stim_std(k)  =  round(nanstd([out_comp{k}.reaches([out_comp{k}.binary.hndtar_r] & [out_comp{k}.binary.success] & [out_comp{k}.binary.microstim]).lat])*1000);
    Input.Hnd_RT_L_stim_mean(k) =  round(nanmean([out_comp{k}.reaches([out_comp{k}.binary.hndtar_l] & [out_comp{k}.binary.success] & [out_comp{k}.binary.microstim]).lat])*1000);
    Input.Hnd_RT_L_stim_std(k)  =  round(nanstd([out_comp{k}.reaches([out_comp{k}.binary.hndtar_l] & [out_comp{k}.binary.success] & [out_comp{k}.binary.microstim]).lat])*1000);
 
    
    for title_idx=1:size(mastertable,2)
        title=mastertable{1,title_idx};
        if iscell(Input.(title)(k))
            mastertable(k+1,title_idx)=Input.(title)(k,:);
        else
            mastertable(k+1,title_idx)={Input.(title)(k)};            
        end
    end
    
end

mastertable_xls=mastertable;

for k=1:numel(mastertable)
    if isnan(mastertable{k})
        mastertable_xls{k}=[];        
    elseif isempty(mastertable{k})
        mastertable_xls{k}=[];           
    elseif ~ischar(mastertable{k}) && numel(mastertable{k})>1
        kommas=repmat({','},1,size(mastertable{k},2));
        restructured_cell=vertcat((strread(num2str(mastertable{k}),'%s'))',kommas);
        restructured_string=[restructured_cell{:}];
        restructured_string(end)=[];
        mastertable_xls{k}=restructured_string;
    end
end

[~, protocol_xls_file, current_folder]= DAG_most_recent_version(protocol_folder,[monkey '_protocol.xls']);
%% change code below using [dag_drive_IP, 'Protocols' filesep monkey] for the excel table
if isempty(protocol_xls_file)
    old_mastertable=mastertable_xls(1,:);
    data_old={};
    current_folder=[dag_drive_IP, 'Protocols' filesep monkey];
    logidx=false(size(mastertable_xls,1)-1,1);
    numindex=NaN(size(logidx));
else
    [data_old,~,old_mastertable]=xlsread([current_folder filesep protocol_xls_file],'Runs');
    [logidx,numindex]=DAG_find_row_indexes_logicals([mastertable_xls{2:end,1}],data_old);
end



numindex=numindex+1;
%insert_counter=0;
old_mastertable2=old_mastertable;
mastertable_xls2=cell(size(old_mastertable,1),size(mastertable_xls,2));
mastertable_xls2(1,:)=mastertable_xls(1,:);
old_mastertable2(1,:)=old_mastertable(1,:);
rows_to_update=[];
for idx=1:numel(logidx)
   if logidx(idx)
       mastertable_xls2(numindex(idx),:)=mastertable_xls(idx+1,:);
       rows_to_update=[rows_to_update numindex(idx)]; %%%
   else
       if isnan(numindex(idx))
            mastertable_xls2(end+1,:)=mastertable_xls(idx+1,:);
            old_mastertable2(end+1,:)=num2cell(zeros(1,size(old_mastertable,2))); 
            rows_to_update=[rows_to_update size(mastertable_xls2,1)];          
       else
            mastertable_xls2=[mastertable_xls2(1:numindex(idx)-1,:); mastertable_xls(idx+1,:);           mastertable_xls2(numindex(idx):end,:)];
            old_mastertable2=[old_mastertable2(1:numindex(idx)-1,:); num2cell(zeros(1,size(old_mastertable,2))); old_mastertable2(numindex(idx):end,:)];
            rows_to_update=[rows_to_update numindex(idx)]; %%%
            numindex=numindex+1;
            %insert_counter=insert_counter+1;
       end
   end
end
complete_mastertable=DAG_update_mastertable_cell(old_mastertable2,mastertable_xls2,rows_to_update);

for k=1:size(complete_mastertable,1)-1
    for h=1:size(complete_mastertable,2)
        if k>1 && all(isempty(complete_mastertable{k+1,h})) || all(isnan(complete_mastertable{k+1,h}))
            change_matrix(k+1,h)=false;
        elseif k>1 && ismatrix(complete_mastertable{k+1,h}) && (numel(complete_mastertable{k+1,h})~=numel(complete_mastertable{k,h}) || any(complete_mastertable{k+1,h}~=complete_mastertable{k,h}))
            change_matrix(k+1,h)=true;
        elseif k>1 && ischar(complete_mastertable{k+1,h}) && ~strcmp(complete_mastertable{k+1,h},complete_mastertable{k,h})
            change_matrix(k+1,h)=true;
        else
            change_matrix(k+1,h)=false;
        end
    end
end

chunksize=1000;
loop_N=ceil(size(complete_mastertable,1)/chunksize);
for k=1:loop_N
    startrowidx=1+(k-1)*chunksize;
    endrowidx=min(k*chunksize,size(complete_mastertable,1));
    xls_index_range=['A' num2str(1+(k-1)*chunksize) ':' DAG_index_to_xls_column(endrowidx,size(complete_mastertable,2))];
    
    xlswrite([current_folder filesep monkey '_protocol.xls'],complete_mastertable(startrowidx:endrowidx,:),'Runs',xls_index_range);
    xlswrite([current_folder filesep monkey '_protocol.xls'],complete_mastertable(startrowidx:endrowidx,:),'Mastertable',xls_index_range);
end

DAG_xlscolor([current_folder filesep monkey '_protocol.xls'],complete_mastertable, false(size(change_matrix)));
DAG_xlscolor([current_folder filesep monkey '_protocol.xls'],complete_mastertable, change_matrix);

% if ~isdir([current_folder filesep monkey]); mkdir(current_folder,monkey); end
%save([current_folder filesep monkey, '_prot_',num2str(dates(1)), '-', num2str(dates(2))],'mastertable')
%save([current_folder filesep monkey, '_output_',num2str(dates(1)), '-', num2str(dates(2))],'out_comp')

summarize_evaluation([current_folder filesep monkey '_protocol.xls']);
per_task_sheets([current_folder filesep monkey '_protocol.xls']);
% 
% xlswrite([monkey '_extracted_mastertable'],mastertable_xls,1);
% save(strcat(monkey, '_trialinfo_mastertable_',current_date),'mastertable')
end

function [logidx,numindex]=DAG_find_row_indexes_logicals(array_to_look_for,input_array)
current_date=0;
current_date_counter=0;
for k=1:length(array_to_look_for)
    if current_date~=array_to_look_for(k) %new date, restart counter
       current_date_counter=1; 
    end    
    logidx(k)=ismember(array_to_look_for(k),input_array(:,1)) && current_date_counter<sum(input_array(:,1)==array_to_look_for(k));
    if logidx(k)
        if current_date~=array_to_look_for(k) % find all runs run of new date
            current_date_numindex=find(input_array(:,1)==array_to_look_for(k));
        else                                  % increase date counter
            current_date_counter=current_date_counter+1;
        end
        numindex(k)=current_date_numindex(current_date_counter);
    else
        current_date_numindex=find(input_array(:,1)>array_to_look_for(k));
        if isempty(current_date_numindex) %% for appending dates
            numindex(k)=NaN;
        else
            numindex(k)=current_date_numindex(1); %% for squeezing in dates: IMPORTANT: only works in combination with logidx==0 !!
        end
    end
    current_date=array_to_look_for(k);
end
end

function summarize_evaluation(protocol_xls_file)
[data,~,mastertable]=xlsread(protocol_xls_file,'Runs');

for title_idx=1:size(mastertable,2)
   title= mastertable{1,title_idx};
   idx.(title)=DAG_find_column_index(mastertable(1,:),title);
end


    
Unique_sessions=unique(data(:,idx.Session));
Session_summary(1,:)=mastertable(1,1:16);
%% 'Session','Run','Trials','initiated','completed','hits','%hits/total','%hits/initiated','%hits/completed'

for session_counter=1:numel(Unique_sessions)
    session=Unique_sessions(session_counter);    
    log_session_idx=data(:,idx.Session)==session;
    Session_summary{session_counter+1,idx.hits}                             =sum(data(log_session_idx,idx.hits));
    Session_summary{session_counter+1,idx.Session}                          =session;
    Session_summary{session_counter+1,idx.Run}                              =sum(log_session_idx);
    Session_summary{session_counter+1,idx.N_Trials}                         =sum(data(log_session_idx,idx.N_Trials));
    Session_summary{session_counter+1,idx.initiated}                        =sum(data(log_session_idx,idx.initiated));
    Session_summary{session_counter+1,idx.completed}                        =sum(data(log_session_idx,idx.completed));    
    Session_summary{session_counter+1,idx.hits}                             =sum(data(log_session_idx,idx.hits));
    
    Session_summary{session_counter+1,idx.hits_per_total}                   =round(Session_summary{session_counter+1,idx.hits}/Session_summary{session_counter+1,idx.N_Trials}*100);
    Session_summary{session_counter+1,idx.hits_per_initiated}               =round(Session_summary{session_counter+1,idx.hits}/Session_summary{session_counter+1,idx.initiated}*100);
    Session_summary{session_counter+1,idx.hits_per_completed}               =round(Session_summary{session_counter+1,idx.hits}/Session_summary{session_counter+1,idx.completed}*100);
    rew_time=unique(data(log_session_idx,idx.Reward_time));
    Session_summary{session_counter+1,idx.Reward_time}                      =rew_time(~isnan(rew_time))';
    Session_summary{session_counter+1,idx.Reward_ml}                        =sum(data(log_session_idx,idx.Reward_ml));
    unique_type=unique(data(log_session_idx,idx.Type));
    unique_effector=unique(data(log_session_idx,idx.Effector));
    unique_Setup=unique(data(log_session_idx,idx.Setup));
    
    Session_summary{session_counter+1,idx.Type}                             =unique_type(~isnan(unique_type))';
    Session_summary{session_counter+1,idx.Effector}                         =unique_effector(~isnan(unique_effector))';
    Session_summary{session_counter+1,idx.Setup}                            =unique_Setup(~isnan(unique_Setup))';
    
    session_idx=find(log_session_idx);
    Session_summary{session_counter+1,idx.start_run}                        =data(session_idx(1),idx.start_run);
    Session_summary{session_counter+1,idx.end_run}                          =data(session_idx(end),idx.end_run);
    

end

for k=1:numel(Session_summary)
    if isnan(Session_summary{k})
        Session_summary{k}=[];
    elseif ~ischar(Session_summary{k}) && numel(Session_summary{k})>1
        kommas=repmat({','},1,size(Session_summary{k},2));
        restructured_cell=vertcat((strread(num2str(Session_summary{k}),'%s'))',kommas);
        restructured_string=[restructured_cell{:}];
        restructured_string(end)=[];
        Session_summary{k}=restructured_string;
    end
end

xlswrite(protocol_xls_file,Session_summary,'Sessions');
end

function per_task_sheets(protocol_xls_file)
[data,~,mastertable]=xlsread(protocol_xls_file,'Runs');

for title_idx=1:size(mastertable,2)
   title= mastertable{1,title_idx};
   idx.(title)=DAG_find_column_index(mastertable(1,:),title);
end
a=1;
type_effector=[data(:,idx.Type),data(:,idx.Effector)];
effectors=data(:,idx.Effector);
types=data(:,idx.Type);
unique_type_effectors=unique(type_effector,'rows');
%unique_type_effectors_nan=unique_type_effectors(any(isnan(unique_type_effectors),2),:);
unique_type_effectors=unique_type_effectors(~any(isnan(unique_type_effectors),2),:);
for idx_task_sheet=1:size(unique_type_effectors,1)
    sheetname=['ty_' num2str(unique_type_effectors(idx_task_sheet,1)) '_ef_' num2str(unique_type_effectors(idx_task_sheet,2))];
    type_idx    =data(:,idx.Type)==unique_type_effectors(idx_task_sheet,1);
    effector_idx=data(:,idx.Effector)==unique_type_effectors(idx_task_sheet,2);
    Task_table = [mastertable(1,:); mastertable([false; type_idx & effector_idx],:)];
    xlswrite(protocol_xls_file,Task_table,sheetname);
end

    type_idx    =isnan(data(:,idx.Type)) | isempty(data(:,idx.Type));
    effector_idx    =isnan(data(:,idx.Effector)) | isempty(data(:,idx.Effector));
    Task_table = [mastertable(1,:); mastertable([false; type_idx | effector_idx],:)];
    xlswrite(protocol_xls_file,Task_table,'teunknown');
end