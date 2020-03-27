%TXT=file2text(FILENAME);
%
%Puts the text in the file FILENAME into an Nx1
%cell array, where N is the number of strings in the file

function txt=file2text(filename);
fid=fopen(filename);
C=textscan(fid,'%s');
fclose(fid);
txt=C{1};

