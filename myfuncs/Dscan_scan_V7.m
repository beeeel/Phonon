clear
addpath /home/share/matlab/Dscan

%% SCAN PARAMETERS AND STUFF

filebase='newcon';          % Filebase for exp data and optional run number

count=15;                   % Number of counts for count types
delay=0;

pictures='no';              % 'yes' for picture before and after  !!! NOT WORKING YET FOR THE BIG LAB!!!

channel='F1';               % Which aquisition channel from scope   
a2dchannel=0;               % Which aquisition channel from A2D   
lab='ASOPS';                % 'ASOPS' or  'PLU' for correct scope IP

axis0=[-10 10 5];           %  In mum, this is for 2D scan type and for z axis 
axis1=[0 0 5];           %  In mum, this is for 2D scan type and for z axis 

origin={[0, 0],...  %%  As many as needed. 
                };   %  In mm, as displayed by apt control from the terminal

    
axisZ=[-15 15 1];           %  used for z types, piezo must be centered before starting!
originZ=50;                            %  negative means objective getting away from sample    
                            %  use "focus_control" on a terminal to centre piezo while setting up
                            %  max range +/-50mum with minimum step of 100nm

axisM=[-0.1 0.1 .01];       %  Scanning mirror voltages range= +/-5v                            
probe_restore=0;            %  restore probe, set to 0 if using auto_overlap or scanning with stage!                
                            
type='2D_fluo';            % '2D' for imaging, 'count' for single point, 'z' for z scanning,
                            %  '2D_count' for dwelling samples, '3D' for z scanning. '2D_mirror' for probe scanning

autofocus='no';            % Recomended if more than 1 origin.                             
     
%% check number of scans
if strcmp(type,'2D')==1; N=size(origin,2); else N=1;end
%% multiple scans
for x=1:N                           
%%  auto focus
if x>1 ; 
    if strcmp(autofocus,'yes')==1; 
        func_execute_move(axis0,axis1,origin{x},'corner'); 
        func_auto_focus; 
    end
    func_execute_move(axis0,axis1,origin{x},'origin'); 
end
%% take picture before
if strcmp(pictures,'yes')==1; func_take_andor_picture(lab,'before',filebase,num2str(x)); end
%% Execute  d_scan 
func_execute_dscan(filebase,num2str(x),lab,type,axis0,axis1,axisZ,origin{x},originZ,axisM,channel,a2dchannel,count,delay);
%% take picture after first scan
if strcmp(pictures,'yes')==1; func_take_andor_picture(lab,'after',filebase,num2str(x)); end
%% Restore probe 
if probe_restore==1; system('set_outputs 0 0 | set_outputs 1 0'); end
%% The end

end
