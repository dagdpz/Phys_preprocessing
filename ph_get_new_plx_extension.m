function plx_extension_per_block=ph_get_new_plx_extension(folder,version)

folder_content=dir([folder '*.plx']);
folder_content=folder_content(~[folder_content.isdir]);
filenames={folder_content.name};
switch version
    case 'PLXFromWCFromBB'
        plxversion='from_BB';
        filenames=filenames(cellfun(@(x) ~isempty(strfind(x,plxversion)),filenames));
    case 'PLXFromSnippets'
        plxversion='realigned';
        filenames=filenames(cellfun(@(x) ~isempty(strfind(x,plxversion)),filenames));
    case 'PLXFromRealignedSnippets'
        plxversion='';
        filenames=filenames(cellfun(@(x) isempty(strfind(x,'from_BB')) && isempty(strfind(x,'realigned')),filenames));
end
filenames=filenames(cellfun(@(x) ~isempty(strfind(x,'-')),filenames));
for f=1:numel(filenames)
    underscore_indexes=strfind(filenames{f},'_');
    blocks(f)= str2double(filenames{f}(underscore_indexes(end)+1:end-7));
    extensions(f)= str2double(filenames{f}(strfind(filenames{f},'-')+1:end-4));
end

unique_blocks=unique(blocks);
for b=unique_blocks
    ex=max(extensions(blocks==unique_blocks(b)))+1;
    plx_extension_per_block(b)=ex;
end
end
