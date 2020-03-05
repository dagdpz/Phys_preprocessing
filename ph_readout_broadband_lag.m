function lag=ph_readout_broadband_lag(table_num,table_string,session,block)
% Reads out broadband lag caused by TDT streamer bug from given tables or m-files (created by
% DAG_derive_TDT_streamer_broadband_lag)


idx_sess=DAG_find_column_index(table_string,'Session');
idx_block=DAG_find_column_index(table_string,'Block');
idx_lag=DAG_find_column_index(table_string,'lag_seconds');


row_idx=ismember(table_num(:,idx_sess),session) & ismember(table_string(2:end,idx_block),['Block-' num2str(block)]);
lag=table_num(row_idx,idx_lag);

if isempty(lag)
   lag=0; 
end


end


