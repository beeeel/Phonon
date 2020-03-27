function [] = func_execute_dscan(filebase,runno,lab,type,axis0,axis1,axisZ,origin,originZ,axisM,channel,a2dchannel,count,delay)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here




%%






%% Creating con file 

scanfilename=strcat(filebase,runno,'.con');

% Con file generation
if strcmp(type,'count')==1
    % single channel count with DC
    write_dcon_file_count(count,channel,a2dchannel,scanfilename,lab,delay);
elseif strcmp(type,'2D')==1
    % single channel 2D with DC
    write_dcon_file_2D(axis0,axis1,origin,channel,a2dchannel,scanfilename,lab);
elseif strcmp(type,'z')==1
    % piezo z scan with DC
    
    
    % Sorting Z ranges into a useful output and doing safety checks
    %(step .05 (volts) is equivalent to 1um , min step  is .005v~100nm, and the range goes from about 0 to 5v)
    
    %originZ=50;
    %axisZ = [-10 10  1];
    
    if originZ < 0
        originZ=50;
        disp('scan parameters: attemting to go below minimum Z origin, centering')
    elseif originZ > 100
        originZ=50;
        disp('scan parameters: attemting to go beyond maximum Z origin, centering')
    end
    
    for x=1:2
        
        originV=round(originZ*10)/10*0.05;
        
        axisV= [originV + (round((axisZ(1)*10))/10)*.05...
            originV + (round((axisZ(2)*10))/10)*.05...
            (round(abs(axisZ(3)*10))/10)*.05];
        
        
        if axisV(x) > 5
            axisV(x)= 5;
            disp('scan parameters: attemting to go beyond maximum Z range, setting to maximum')
        elseif axisV(x)< 0
            axisV(x)= 0;
            disp('scan parameters: attemting to go below minimum Z range, setting to minimum')
        end
    end
    
    
    if axisV(3) < 0.005
        axisV(3)=.005;
        disp('scan parameters: attemting to go below minimum Z step, setting to minimum')
    elseif axisV(3) > 0.5
        axisV(3)=.5;
        disp('scan parameters: attemting to go beyond maximum Z step, setting to maximum')
    end
    
    write_dcon_file_Z(axisV,channel,a2dchannel,scanfilename,lab);
    
elseif strcmp(type,'2D_count')==1
    % 2D scan with counts
    write_dcon_file_2D_count(axis0,axis1,origin,count,channel,a2dchannel,scanfilename,lab);
    
elseif strcmp(type,'3D')==1
    % 3D scan with piezo
    
    % Sorting Z ranges into a useful output and doing safety checks
    %(step .05 (volts) is equivalent to 1um , min step  is .005v~100nm, and the range goes from about 0 to 5v)
    
    %originZ=50;
    %axisZ = [-10 10  1];
    
    if originZ < 0
        originZ=50;
        disp('scan parameters: attemting to go below minimum Z origin, centering')
    elseif originZ > 100
        originZ=50;
        disp('scan parameters: attemting to go beyond maximum Z origin, centering')
    end
    
    for x=1:2
        
        originV=round(originZ*10)/10*0.05;
        
        axisV= [originV + (round((axisZ(1)*10))/10)*.05...
            originV + (round((axisZ(2)*10))/10)*.05...
            (round(abs(axisZ(3)*10))/10)*.05];
        
        
        if axisV(x) > 5
            axisV(x)= 5;
            disp('scan parameters: attemting to go beyond maximum Z range, setting to maximum')
        elseif axisV(x)< 0
            axisV(x)= 0;
            disp('scan parameters: attemting to go below minimum Z range, setting to minimum')
        end
    end
    
    
    if axisV(3) < 0.005
        axisV(3)=.005;
        disp('scan parameters: attemting to go below minimum Z step, setting to minimum')
    elseif axisV(3) > 0.5
        axisV(3)=.5;
        disp('scan parameters: attemting to go beyond maximum Z step, setting to maximum')
    end
    
    
    
    write_dcon_file_3D(axis0,axis1,axisV,origin,originZ,channel,a2dchannel,scanfilename,lab);
elseif strcmp(type,'2D_mirror')==1
    % 2D scan with mirror
    
    if axisM(1) < -5
        axisM(1)=0;
        disp('scan parameters: attemting to go below minimum Mirror range(-5V), setting to 0')
    elseif axisM(1) > 5
        axisM(1)=0;
        disp('scan parameters: attemting to go beyond maximum Mirror range(5V), setting to 0')
    end
    
    if axisM(2) < -5
        axisM(2)=0;
        disp('scan parameters: attemting to go below minimum Mirror range(-5V), setting to 0')
    elseif axisM(2) > 5
        axisM(2)=0;
        disp('scan parameters: attemting to go beyond maximum Mirror range(5V), setting to 0')
    end
    
    write_dcon_file_2D_mirror(axisM,channel,a2dchannel,scanfilename,lab);
elseif strcmp(type,'2D_fluo')
    write_dcon_file_2D_fluo(axis0, axis1, origin,count,channel,a2dchannel,scanfilename,lab);
else
    disp('Error : No match found for scan type, aborting')
    return
end
%% Execute
dscanline=strcat({'unset LD_LIBRARY_PATH ; /usr/local/bin/d_scan '},{scanfilename},{' >> '},{filebase},{runno},{'.log'});
% turn shutters on
func_turn_lasers(lab,'on');
disp('scan in progress...');
system(dscanline{1});
disp('scan finished.');
% turn shutters off
func_turn_lasers(lab,'off');

end

