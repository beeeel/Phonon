function [varargout] = ExposureLimits2(Wavelength, Class, Time, Alpha, varargin)
% [AEL, MPEEye, MPESkin] = ExposureLimits2(Wavelength, Class, Time, Alpha, ...
%   Arguments for all beams:       [Power, BeamWidth...
%   Arguments for lenses:           NA, Transmission, ImmersionN, FocalLength (for cylindrical), Divergence (for cylindrical)...
%   Arguments for pulsed lasers:    CalculatePulsed, PulseRate, PulseDuration, ...
%   Misc arguments:                 PlotIrradiance, SkinLimits, PlotDiffuse])
%
% Caculate Maximum Permissible Exposure and Accessible Exposure Limits for
% given laser wavelength (nm), class, exposure time (s), and angular
% subtense (mrad). AELs are from BS EN 60825-1:2014 tables 3 to 8, MPEs are
% from tables A.1 to A.6
%
% Optional inputs as name-value pairs, e.g.: ..."NA",0.75,...
%
% Currently this code only considers condition 3:  applied to determine
% irradiation relevant for the unaided eye, for low power magnifiers and
% for scanning beams. 
% This is acceptable as Table 10 footnote a states: Condition 1 is not
% applied for classification of laser products intended for use exclusively
% indoors and where intrabeam viewing with telescopic optics such as
% binocular telescopes is not reasonably foreseeable.
%
% This code also only accurately applies condition 3 to wavelengths < 4000
% nm
%
% Section 4.3 e) 3): "where intentional long-term viewing is inherent in
% the design or function of the laser product" - Since this is for
% assessing labs, it is assumed this statement is false
%
% Radiation of multiple wavelengths: 
% This may not be strictly accurate for ASOPS two-laser systems: if the
% wavelengths have additive effects, the limits become more complex
% (Section 4.3 b) depending on whether their effects are additive or not.
%
% Extended sources:
% This does not have all tables defined for extended sources. You can
% extend it, or ask me to. (william.hardiman@nottingham.ac.uk)
%
%% How to use:
% To find Accessible Emission Limit (in W): 
% ExposureLimits2(Wavelength (nm), Class, Time (s), Alpha (mrad))
%
% To plot safe distance for an objective with 0.5 NA:
% ExposureLimits2(Wavelength (nm), 1, Time (s), Alpha (mrad), 'NA', 0.5, 'Power', P (number in W), 'Transmission', T (Number between 0 and 1))
%
% For 100fs pulsed lasers with repetition rate 80MHz:
% ExposureLimits2(Wavelength(nm), 1, 10^4, Alpha (mrad),
% 'CalculatePulsed', true, 'PulseDuration', 1e-13, 'PulseRate', 8e7)
% 
% To be given limits for use in scripts:
% AEL = ExposureLimits2(Wavelength(nm),Class,Time(s),Alpha(mrad));
% [AEL, MPEEye, MPESkin] = ExposureLimits2(Wavelength(nm),Class,Time(s),Alpha(mrad));



%%
% Handle inputs
p = ParseInputs();

% Get correction factors and breakpoints
[C1, C2, C3, C4, C5, C6, C7, T1, T2, TimeBase,Npulse] = GetFactorsAndBreakpoints(); %#ok<ASGLU>

%%
% Get the AEL and MPEs
% Declaration of where values are coming from
StrTable = 'Take %s values from BS EN 60825-1:2014 Table %s for time %g s and wavelength %g nm\n';
if nargout == 3
    AEL = UseAELTable();
    [MPEEye, MPESkin] = UseMPETable();
    varargout = {AEL, MPEEye, MPESkin};
    if p.Results.SkinLimits
        PLim = MPESkin;
    elseif p.Results.PlotIrradiance
        PLim = MPEEye;
    else
        PLim = AEL;
    end
elseif p.Results.PlotIrradiance
    PLim = UseMPETable('Eye');
elseif p.Results.SkinLimits
    PLim = UseMPETable('Skin');
else
    PLim = UseAELTable();
end

% Assign outputs
if nargout == 0
    varargout = {};
elseif nargout == 1
    varargout = {PLim};
end

%% Plot some graphs
if ~isnan(p.Results.Power)
    if ~isnan(p.Results.NA)
        FoVAngle = asin(p.Results.NA./p.Results.ImmersionN);
        figure
        PlotExposureVDist(FoVAngle, p.Results.Transmission);
    end
    if p.Results.PlotDiffuse
        FoVAngle = pi/2;
        figure
        PlotExposureVDist(FoVAngle);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    function PlotExposureVDist(FoVAngle, varargin)
        %% Draw a plot of incident power against distance
        % Can factor in transmission of lens if given it
        if length(varargin) == 1
            Transmission = varargin{1};
        elseif length(varargin) > 1
            error('Too many nargins to PlotExposureVDist');
        else
            Transmission = 1;
        end
        Dist = linspace(0, 2, 1000);
        % Power at pupil is total power * solid angle of pupil / solid angle of
        % illumination. Irradiance is that, divided by area of pupil
        PowerPupil = LensPower;
        SafeIDX = find(PowerPupil<PLim, 1);
        semilogy(Dist, PowerPupil)
        hold on
        plot([0, 2], [PLim, PLim],':r')
        
        if isempty(SafeIDX)
            str = 'Laser too powerful for given class';
        else
            str = ['Safe distance = ' num2str(round(Dist(SafeIDX),3,'significant')) 'm'];
        end
        
        xlabel(['Distance (m) [' str ']'])
        
        if p.Results.PlotIrradiance
            ylabel(['Radiant exposure (W m^{-2}) [MPE = ' num2str(PLim,3) 'W m^{-2}]'])
            strLeg = 'Radiance';
            strTitle = '$\frac{\Omega_{pupil}}{\Omega_{illum}} \times P_{laser} \times (A_{pupil})^{-1}';
            strCase = 'Irradiance';
            Units = 'W m^{-2}';
        else
            ylabel(['Incident Power (W) [AEL = ' num2str(PLim,3) 'W]'])
            strLeg = 'Power';
            strTitle = '$\frac{\Omega_{pupil}}{\Omega_{FoV}} \times P_{laser}';
            strCase = 'Incident power';
            Units = 'W';
        end
        if FoVAngle < pi/2
            strTitle = [strTitle '\times T_{objective}$'];
            strName = [strCase ' for NA = ' num2str(p.Results.NA)];
            strLabel = sprintf('transmitted %g%% through NA %g %s lens',100 * Transmission, p.Results.NA, p.Results.LensType);
        else
            strTitle = [strTitle '$'];
            strName = [strCase ' for diffuse reflection'];
            strLabel = 'diffusely reflected';
        end
        strLabel = [sprintf('%g W laser ',p.Results.Power) strLabel];
        strLabel2 = sprintf('\n%s at 100mm: %g ', strCase, round(PowerPupil(find(Dist>0.1,1)),3,'significant'));
        annotation('textbox',[.15 .5 .3 .3] ,'String',[strLabel strLabel2 Units],'FitBoxToText','on');
        
        title(strTitle, 'Interpreter','latex','FontSize',22)
        set(gcf,'Name',strName);
        strLeg2 = sprintf('AEL for class %s',Class);
        legend(strLeg, strLeg2,'Location','southwest')
        
        function IncidentPower = LensPower()
            % Illumination area depends on the type of lens - for lenses
            % symmetric about optical axis, this is simple.
            switch p.Results.LensType
                case 'objective'
                    IncidentPower = (p.Results.Power * Transmission * (1 - cos(atan(3.5e-3./Dist)))./(1-cos(FoVAngle)));
                case 'cylindrical'
                    IncidentPower = (p.Results.Power * Transmission * (pi * (3.5e-3).^2))./(2.*abs(Dist-p.Results.FocalLength).*tan(FoVAngle).*(2.*Dist.*tan(p.Results.Divergence) + p.Results.BeamWidth));
            end
            % Convert to irrandiance if PlotIrradiance. Otherwise divide by 1.
            IncidentPower = IncidentPower ./ (~p.Results.PlotIrradiance + p.Results.PlotIrradiance * pi * (3.5e-3).^2);
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function AEL = UseAELTable()
        %% AEL - define a table then look up values from it
        
        % First select the class, then small or extended source
        switch Class
            case '1'
                if C6 == 1
                    % Define the table to read from: The column and row values,
                    % which table number it is in the BS document, and then the
                    % contents of the table
                    XVals = [1e-13, 1e-11, 1e-9, 1e-7, 5e-6, 1.3e-5, 1e-3, 0.35, 10, 1e2, 1e3, 3e4+1];
                    YVals = [180, 302.5, 315, 400, 450, 500, 700, 1050, 1400, 1500, 1800, 2600, 4e3, 1e6];
                    BSTable = '3';
                    AELTable = zeros(length(YVals)-1,length(XVals)-1);
                    
                    AELTable(3,:) = [repmat(2.4e4,1,2), repmat(7.9e-7*C1,1,6), repmat(7.9e-3,1,2), 7.9e-6];
                    AELTable(4:5,9:11) = [repmat(3.9e-3,2,1) repmat(3.9e-5*C3,2,2)];
                    AELTable(4:6,1:8) = [repmat(3.8e-8,3,1),repmat(7.7e-8,3,3),repmat(7e-4*Time^0.75,3,4)];
                    AELTable(7,1:8) = [3.8e-8,repmat(7.7e-8 * C4,1,3), repmat(7e-4 * (Time^0.75) * C4,1,4)];
                    AELTable(8,6:8) = 3.5e-3 * (Time^0.75) * C7;
                    AELTable(6:8,9:11) = [repmat(3.9e-4,1,3); repmat(3.9e-4 * C4 * C7,2,3)];
                    
                    UnitsTable = [repmat("W/m^2",1,2), repmat("J/m^2",1,9);...
                        repmat("W",2,2) repmat("J",2,6) [repmat("J",1,3); "J" "J" "W"];...
                        repmat("J",5,8) [["J"; ("×" + string(C3) + "J and × 0.1 W")] repmat("W",2,2);...
                        repmat("W",3,3)]; repmat("W",4,2) repmat("J",4,6) repmat("W",4,3);...
                        repmat("W/m^2",1,2) repmat("J/m^2",1,6), repmat("W/m^2",1,3)];
                else
                    XVals = [1e-11, 5e-6, 1.3e-5, 10, 1e2, 1e4, 3e4];
                    YVals = [400, 700, 1050, 1400];
                    BSTable = '4';
                    AELTable = zeros(length(YVals)-1,length(XVals)-1);
                    AELTable(3,5:7) = 3.5e-3 * C6 * C7 * ((Time <= T2) * Time^0.75 + (Time > T2) * T2^-0.25);
                end
            case '2'
                if (Wavelength < 400) || (Wavelength >= 700)
                    error('Class 2 does not apply outside of wavelength range 400nm to 700nm')
                end
            case '3R'
                if C6 == 1
                    XVals = [1e-13, 1e-11, 1e-9, 1e-7, 5e-6, 1.3e-5, 1e-3, 0.35, 10, 1e3, 3e4+1];
                    YVals = [180, 302.5, 315, 400, 700, 1050, 1400, 1500, 1800, 2600, 4e3, 1e6];
                    BSTable = '6';
                    AELTable = zeros(length(YVals)-1,length(XVals)-1);
                    
                    AELTable(3,:) = [1.2e5, 1.2e5, repmat(4e-6*C1,1,6),4e-2,4e-5];
                    AELTable(4,:) = [1.9e-7,repmat(3.8e-7,1,3),repmat((Time < 0.25)*3.5e-3*Time^0.75 + (Time >= 0.25) * 5e-3,1,3),repmat(5e-3,1,3)];
                    AELTable(5,1:8) = [1.9e-7,repmat(3.8e-8*C4,1,3),repmat(3.5e-4*(Time^0.75)*C4,1,4)];
                    AELTable(5:6,9:10) = 2e-3*C4*C7;
                    
                    UnitsTable = ["W/m^2", "W/m^2", repmat("J/m^2",1,8);...
                        repmat("W",2,2),repmat("J",2,7),["J";"W"];...
                        repmat("J",1,4),repmat("Dual limits apply",1,3),repmat("W",1,3);...
                        repmat("J",2,8),repmat("W",2,2); repmat("W",4,1),repmat("J",4,7)...
                        repmat("W",4,2); "W/m^2", "W/m^2", repmat("J/m^2",1,7),"W/m^2" ];
                    UnitsTable(4,5:7) = char('J' * (Time < 0.25) + 'W' * (Time >= 0.25));
                else
                    disp('In UseAELTable: Table not defined yet')
                    error('Will''s a lazy bugger and hasn''t programed this case yet!')
                end
            case '3B'
                if C6 == 1
                    XVals = [1e-90, 1e-9, 0.25, 3e4+1];
                    YVals = [180, 302.5, 315, 400, 700, 1050, 1400, 1e6];
                    BSTable = '6';
                    AELTable = zeros(length(YVals)-1,length(XVals)-1);
                    
                    AELTable = [3.8e5, 3.8e-4, 1.5e-3; 1.25e4*C2, 1.25e-5 * C2, 5e-5*C2;...
                        1.25e8, 0.125, 0.5; 3e7, (Time < 0.06) * 0.03 + (Time >=0.06) * 0.5,...
                        0.5; 3e7*C4, (Time < 0.06*C4) * 0.03 * C4 + (Time >=0.06*C4) * 0.5, 0.5;...
                        1.5e8, 1.5e-1,0.5; 1.25e8,1/8,0.5;];
                    
                    UnitsTable = [repmat("W",7,1) repmat("J",7,1), repmat("W",7,1)];
                    UnitsTable(4,2) = char('J' * (Time< 0.06) + 'W' * (Time>=0.06));
                    UnitsTable(5,2) = char('J' * (Time < 0.06 * C4) + 'W' * (Time >= 0.06*C4));
                else
                    disp('In UseAELTable: Table not defined yet')
                    error('Will''s a lazy bugger and hasn''t programed this case yet!')
                end
            otherwise
                error('Will''s a lazy bugger and hasn''t programed this case yet!')
        end
        
        % Wavelength limit check
        if Wavelength < YVals(1)
            error('Wavelength too short for defined table')
        elseif Wavelength > YVals(end)
            error('Wavelength too long for defined table')
        end
        
        % Time limit check
        if Time < XVals(1)
            Time = XVals(1);
            fprintf('Time too short, setting to %g\n',Time)
        elseif Time > XVals(end)
            Time = XVals(end);
            fprintf('Time too long, setting to %g\n',Time)
        end
        
        % Continuous or pulsed
        if ~p.Results.CalculatePulsed
            fprintf(StrTable,'AEL', BSTable, Time, Wavelength)
            [AEL, Units] = AELLookup(Time);
            fprintf('%s\n%%\t\tAEL = %.2e %s\t\t%%\n%s\n\n',repmat('%',1,49),AEL, Units,repmat('%',1,49))
            if AEL == 0
                disp('AEL table incomplete')
                error('Will''s a lazy bugger and hasn''t programed this case yet!')
            end
        else
            % Rule 4.3) Compare the AEL for a single pulse, and for the
            % average over the time base
            [AELsingle, AELsingleUnits] = AELLookup(p.Results.PulseDuration);
            [AELt, AELtUnits] = AELLookup(TimeBase);
            
            % Condition 4.3 f) 3) is not assessed against photochemical
            % limits or for class 3B
            Cond43f3 = ~strcmp(Class,"3B") && (Wavelength >= 400 && Wavelength < 1e6);
            if Cond43f3; AELspTrain = AELsingle * C5; else; AELspTrain = []; end
            
            if p.Results.Power / p.Results.PulseRate >= AELsingle
                warning('Energy in one pulse exceeds AEL (single) - 4.3 f) 1)')
            end
            if p.Results.Power >= AELt
                warning('Laser average power exceeds AEL (T) - 4.3 f) 2)')
            end
            if p.Results.Power / p.Results.PulseRate >= AELspTrain
                warning('Energy in one pulse exceeds AEL (sp train) - 4.3 f) 3)')
            end
            
            % This should actually check units and compare as appropriate
            if strcmp(AELtUnits,'W')
                AELtComp = AELt/p.Results.PulseRate;
            else
                warning('Will is not sure that the time-average limit is compared correctly')
            end
            
            if ~strcmp(AELsingleUnits,'J')
                warning('Will is not sure that the single-pulse or pulse train limit is compared correctly')
            end
            
            % The applicable AEL is the most restrictive AEL
            AEL = min([AELtComp,AELsingle,AELspTrain]);
            
            switch AEL
                case AELt/p.Results.PulseRate
                    [AEL, Units] = AELLookup(TimeBase);
                    fprintf('AEL taken from average power over time base of %g s\n',TimeBase)
                case AELsingle
                    [~, Units] = AELLookup(p.Results.PulseDuration);
                    fprintf('AEL taken from limit for single pulse of %g s\n',...
                        p.Results.PulseDuration);
                case AELspTrain
                    [~, Units] = AELLookup(p.Results.PulseDuration);
                    % The units of AELspTrain are the same as the units of
                    % AELsingle, which is AEL for duration of 1 pulse.
                    fprintf('AEL taken from pulse train of duration %.2e s\n',...
                        Npulse * p.Results.PulseRate);
            end
            fprintf(StrTable,'AEL', BSTable, Time, Wavelength) %#ok<*CTPCT,*PRTCAL>
            fprintf('%s\n%%\t\tAEL = %.2e %s\t\t%%\n%s\n\n',repmat('%',1,49),AEL, Units,repmat('%',1,49))
            if AEL == 0
                disp('AEL table incomplete')
                error('Will''s a lazy bugger and hasn''t programed this case yet!')
            end
        end
        
        if  Time >= 10 && Time < 100 && Wavelength >= 450 && Wavelength < 500
            warning('Two limits apply to this AEL: one in J and one in W')
        end
        
        % Perform table lookup using wavelength and given time to find
        % row and column for appropriate limit
        function [AEL, varargout] = AELLookup(Time)
            AEL = AELTable(find(YVals<=Wavelength,1,'last'),find(XVals<=Time,1,'last'));
            if nargout == 2
                varargout = {UnitsTable(find(YVals<=Wavelength,1,'last'),find(XVals<=Time,1,'last'))};
            end
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [varargout] = UseMPETable(varargin)
        %% Lookup MPE for skin or eye or both from appendix A.
        % Can return one MPE if asked, or two if no input arguments
        warning('No units are programmed for MPE lookups - it could be J/m^2 or W/m^2!')
        if nargin == 0
            Skin = true;
            Eye = true;
        elseif nargin == 1
            switch varargin{:}
                case 'Skin'
                    Skin = true;
                    Eye = false;
                case 'Eye'
                    Skin = false;
                    Eye = true;
                otherwise
                    error('Miscall to UseMPETable - input argument should be ''Eye'' or ''Skin''')
            end
        elseif nargin > 1
            error('Miscall to UseMPETable - either 0 or 1 input arguments')
        end
        varargout = cell(0);
        if Eye
            % AEL for eye - First select the class, then extended or small source
            if C6 == 1
                % Define the table to read from: The column and row values,
                % which table number it is in the BS document, and then the
                % contents of the table
                XVals = [1e-13 1e-11, 1e-9, 1e-7, 5e-6, 1.3e-5, 1e-3, 10, 1e2, 3e4];
                YVals = [180, 302.5, 315, 400, 450, 500, 700, 1050, 1400, 1500, 1800, 2600, 1e6];
                BSTable = 'A.1';
                MPEEyeTable = zeros(length(YVals)-1,length(XVals)-1);
                MPEEyeTable(7:8,8:9) = 10 * C4 * C7;
                
                UnitsTable = repmat(string(['Check table ' BSTable ' for units']),length(YVals)-1,length(XVals)-1);
            else
                XVals = [1e-13, 1e-11, 5e-6, 1.3e-5, 10, 1e2, 1e4, 3e4];
                YVals = [400, 700, 1050, 1400];
                BSTable = 'A.2';
                MPEEyeTable = zeros(length(YVals)-1,length(XVals)-1);
                MPEEyeTable(3,5:7) = 90 * C6 * C7 * ((Time <= T2) * Time^0.75 + (Time > T2) * T2^-0.25);
                
                UnitsTable = repmat(string(['Check table ' BSTable ' for units']),length(YVals)-1,length(XVals)-1);
            end
            
            fprintf(StrTable,'MPE for eye', BSTable, Time, Wavelength)
            MPE = MPELookup(Time,'eye');
            varargout = [varargout, MPE];
            if MPE == 0
                disp('MPE for eye table incomplete')
                error('Will''s a lazy bugger and hasn''t programed this case yet!')
            end
        end
        if Skin
            XVals = [1e-9 1e-8 1e-3 10 1e3 3e4];
            YVals = [180 302.5 315 400 700 1400 1500 1800 2600 1e6];
            BSTable = 'A.5';
            MPESkinTable = zeros(length(YVals)-1,length(XVals));
            MPESkinTable(5,3:4) = 1.1e4 * C4 * Time^0.25;
            MPESkinTable(5,5:6) = 2000 * C4;
            
            UnitsTable = repmat(string(['Check table ' BSTable ' for units']),length(YVals)-1,length(XVals));

            fprintf(StrTable,'MPE for skin',BSTable, Time, Wavelength)
            MPE = MPELookup(Time,'skin');
            varargout = [varargout, MPE];
            if MPE == 0
                disp('MPE for skin table incomplete')
                error('Will''s a lazy bugger and hasn''t programed this case yet!')
            end
        end
        
        % Perform an MPE lookup from the appropriate table
        function [MPE, varargout] = MPELookup(Time, Limit)
            if Wavelength < YVals(1)
                error('Wavelength too short for defined table')
            elseif Wavelength > YVals(end)
                error('Wavelength too long for defined table')
            elseif Time < XVals(1)
                Time = XVals(1);
                fprintf('Time too short, setting to %g\n',Time)
            elseif Time > XVals(end)
                Time = XVals(end);
                fprintf('Time too long, setting to %g\n',Time)
            end
            switch Limit
                case 'eye'
                    MPE = MPEEyeTable(find(YVals<=Wavelength,1,'last'),find(XVals<=Time,1,'last'));
                    Units = UnitsTable(find(YVals<=Wavelength,1,'last'),find(XVals<=Time,1,'last'));
                case 'skin'
                    MPE = MPESkinTable(find(YVals<=Wavelength,1,'last'),find(XVals<=Time,1,'last'));
                    Units = UnitsTable(find(YVals<=Wavelength,1,'last'),find(XVals<=Time,1,'last'));
            end
            fprintf('%s\n%%\t\tAEL = %.2e %s\t\t%%\n%s\n\n',repmat('%',1,49),MPE, Units,repmat('%',1,49))
            if nargout == 2
                varargout{1} = {Units};
            end
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function p = ParseInputs()
        %% Handle inputs and do something half sensible
        Class = num2str(Class); % If Class is given as numeric, convert to string. If it's a string, nothing happens
        if Alpha > 1.5; warning('True AELs may be higher than AELs estimated here. See BS EN 60825-1:2014 section 5.4.1 b)'); end
        
        p = inputParser;
        
        %% Compulsory (generic class information)
        addRequired(p,'Wavelength',@(x)validateattributes(x,{'numeric'},...
            {'nonempty','>',180,'<',1e6}))
        addRequired(p,'Class',...
            @(x)strcmp(x,validatestring(x,["1","2","3R","3B","4"])))
        addRequired(p,'Time',@(x)validateattributes(x,{'numeric'},...
            {'nonempty','positive'}))
        addRequired(p,'Alpha',@(x)validateattributes(x,{'numeric'},...
            {'nonempty','positive','<=',1000*pi}))
        %% For all beams
        addParameter(p,'Power',NaN,@(x)validateattributes(x,...
            {'numeric'},{'nonempty','positive'}))
        addParameter(p,'BeamWidth',NaN,@(x)validateattributes(x,{'numeric'},...
            {'nonempty','positive'}))
        %% For all lenses
        addParameter(p,'LensType','objective',...
            @(x)strcmp(x,validatestring(x,["objective","cylindrical"])))
        addParameter(p,'NA',NaN,@(x)validateattributes(x,{'numeric'},...
            {'nonempty','positive','<',2}))
        addParameter(p,'Transmission',1,@(x)validateattributes(x,{'numeric'},...
            {'nonempty','positive','<=',1}))
        addParameter(p,'ImmersionN',1,@(x)validateattributes(x,{'numeric'},...
            {'nonempty','positive','<',2}))
        %% For cylindrical lenses
        addParameter(p,'FocalLength',NaN,@(x)validateattributes(x,{'numeric'},...
            {'nonempty','nonnegative'}))
        addParameter(p,'Divergence',NaN,@(x)validateattributes(x,{'numeric'},...
            {'nonempty','positive','<=',pi/2}))
        %% For pulsed
        addParameter(p,'CalculatePulsed',false,@(x)validateattributes(x,{'logical'},...
            {'nonempty'}))
        addParameter(p,'PulseRate',NaN,@(x)validateattributes(x,{'numeric'},...
            {'nonempty','positive'}))
        addParameter(p,'PulseDuration',NaN,@(x)validateattributes(x,{'numeric'},...
            {'nonempty','positive'}))
        %% Misc
        addParameter(p,'PlotIrradiance',false,@(x)validateattributes(x,{'logical'},...
            {'nonempty'}))
        addParameter(p,'SkinLimits',false,@(x)validateattributes(x,{'logical'},...
            {'nonempty'}))
        addParameter(p,'PlotDiffuse',false,@(x)validateattributes(x,{'logical'},...
            {'nonempty'}))
        
        parse(p,Wavelength, Class, Time, Alpha,varargin{:})
        
        if p.Results.ImmersionN < p.Results.NA
            error('NA must be lower than refractive index of immersion media')
        end
        
        if (p.Results.PlotIrradiance || p.Results.SkinLimits) && p.Results.CalculatePulsed
            error('Pulse lasers do not have defined MPEs: Only AELs. Repeat without PlotIrradiance and SkinLimits')
        end
       
        if strcmp(p.Results.LensType,'cylindrical')
            CheckVars('BeamWidth','FocalLength','Divergence')
        end
        if p.Results.CalculatePulsed
            CheckVars('PulseRate','PulseDuration')
        end
        if p.Results.BeamWidth >= 1
            warning('Large value for BeamWidth - values should be in metres')
        end
        
        
        function CheckVars(varargin)
            stop = false;
            for var = varargin
                if sum(strcmp(var{:},p.UsingDefaults))
                    warning('Value required for %s',var{:})
                    stop = true;
                end
            end
            if stop
                error('Please repeat with required variables')
            end
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [C1, C2, C3, C4, C5, C6, C7, T1, T2, TimeBase, Npulse] = GetFactorsAndBreakpoints()
        %% Define breakpoints and correction factors from BS EN 60825-1:2014 Table 9
        % These are only used in calculations for  wavelength regions specified,
        % but many are defined below over a broader spectral region - this doesn't
        % matter.
        
        % 4.3 e) Time bases
        rule1 = (sum(strcmp(Class, {'2','2M','3R'})) && Wavelength >= 400 && Wavelength < 700);
        TimeBase = ...
             0.25 *  rule1 ...
            + 100 * (Wavelength > 400 && ~ rule1)...
            + 3e4 * (Wavelength <= 400);
        
        T1 = 10^(0.8*(Wavelength-295))*1e-15;
        T2 = (Alpha <= 1.5) * 10 + (Alpha > 100) * 100 + ...
            ((Alpha > 1.5) && (Alpha <= 100)) * 10 * 10^((Alpha - 1.5)/98.5);
        
        Ti = ((Wavelength >= 400) && (Wavelength < 1050)) * 5e-6 + ...
            ((Wavelength >= 1050) && (Wavelength < 1400)) * 13e-6 + ...
            ((Wavelength >= 1400) && (Wavelength < 1500)) * 1e-3 + ...
            ((Wavelength >= 1500) && (Wavelength < 1800)) * 10 + ...
            ((Wavelength >= 1800) && (Wavelength < 2600)) * 1e-3 + ...
            ((Wavelength >= 2600) && (Wavelength <= 1e6)) * 1e-7;
        
        Npulse = (Ti + (Ti == 0) * min(TimeBase, T2)) * p.Results.PulseRate;
        
        if Time < 625e-6
            AlphaMax = 5;
        elseif Time <= 0.25
            AlphaMax = 200 * Time^(0.5);
        else
            AlphaMax = 100;
        end
        
        C1 = 5.6e3 * Time^0.25;
        C2 = (Wavelength < 302.5) * 30 + (Wavelength >= 302.5) * 10^(0.2*(Wavelength-295));
        C3 = (Wavelength < 450) * 1 + (Wavelength >= 450) * 10^(0.02*(Wavelength-450));
        C4 = (Wavelength < 1050) * 10^(0.002*(Wavelength-700)) + (Wavelength >= 1050) * 5;
        % C5 only applies to pulsed lasers - it's disgusting to calculate
        C5 = CalculateC5();
        C6 = ((Wavelength < 400) || (Wavelength >= 1400) || (Alpha <= 1.5)) * 1 + ...
            ((Wavelength >= 400) && (Wavelength < 1400) && (Alpha > 1.5) && (Alpha <= AlphaMax)) * Alpha/1.5 + ...
            ((Wavelength >= 400) && (Wavelength < 1400) && (Alpha > AlphaMax)) * AlphaMax/1.5;
        C7 = (Wavelength < 1150) * 1 + ...
            ((Wavelength >= 1150) && (Wavelength < 1200)) * 10^(0.018*(Wavelength-1150)) + ...
            (Wavelength >= 1200) * (8 + 10^(0.04 * (Wavelength - 1250)));
        
        function C5 = CalculateC5()
            %% Calculate value of C5: There are conditions defined in tables 9 and 2, and section 4.3 f)3)
            if p.Results.PulseDuration <= Ti
                isOne = (TimeBase <= 0.25 || Npulse <= 600);
                C5 = isOne + ~isOne * min(5 * Npulse^-0.25, 0.4);
            elseif (Wavelength < 400) || (Wavelength >= 1400) || ...
                    ((p.Results.PulseDuration <= Ti) && ((TimeBase <= 0.25) || Npulse <= 600)) ||...
                    ((p.Results.PulseDuration > Ti) && (Alpha >= 5))
                C5 = 1;
            elseif (p.Results.PulseDuration <= Ti) && (TimeBase > 0.25) && (Npulse > 600)
                C5 = max(5 * Npulse^(-0.25), 0.4);
            elseif (p.Results.PulseDuration > Ti)
                % This bit is hard to read, but is encompasses the
                % information in section 4.3 f) 3).
                C5 = ((Alpha > 5) && (Alpha <= AlphaMax)) * ...
                    ((Npulse <= 40) * Npulse^(-0.25) + (Npulse > 40) * 0.4) + ...
                    (Alpha > AlphaMax) * ((Alpha <= 100) * ...
                    ((Npulse <= 625) * Npulse^(-0.25) + (Npulse > 625) * 0.2) + (Alpha > 100) * 1);
            else
                C5 = NaN;
            end
        end
    end
end
