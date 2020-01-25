function [out, ITER, ITEROUTP] = fcnOBJECTIVE(z, N_chord, N_dihe, N_prop_max, Vars_prop, max_tip_speed, min_tip_speed, home_dir)

cd(home_dir);

fp2 = fopen('dvhistory.txt','at');
fprintf(fp2,'%g ', z);
fprintf(fp2,'\n');
fclose(fp2);

% Temporary filenames
temp_name = regexprep(tempname('/'), {'/', '\'}, '');
matname = ['aux_files/z_', temp_name, '.mat'];
if nargin > 0
    save(matname, 'z', 'N_chord', 'N_dihe', 'N_prop_max', 'Vars_prop');
end

% Constant propeller values
rotor.hub = [0 0 0];
rotor.dir = 1;
rotor.collective = 0;
rotor.axis = [-1 0 0];
rotor.m = 1;
rotor.blades = 3;
rotor.airfoil = 'MH-117';
rotor.diam = z(N_chord+N_dihe + 1)./100;
rotor.rpm = z(N_chord+N_dihe + 2);
airfoil_data = load('airfoils/MH-117.mat');

% Double checking propeller tip speed
tip_speed = (rotor.diam*pi)/(60/rotor.rpm);
max_prop_rpm = 60*(max_tip_speed/(pi*rotor.diam));
min_prop_rpm = 60*(min_tip_speed/(pi*rotor.diam));
if tip_speed > max_tip_speed
    rotor.rpm = max_prop_rpm;
elseif tip_speed < min_tip_speed
    rotor.rpm = min_prop_rpm;
end

%% Preliminary steps
% Formating wing geometry
wing_geom(:,2) = [0; cumsum(repmat(482/(N_chord-1),N_chord-1, 1))]; % Chord stations
wing_geom(:,1) = (22.6/482).*wing_geom(:,2);
wing_geom(:,5) = ((-4/482).*wing_geom(:,2) + 5).*0; % No more twist
if N_dihe > 0
    wing_geom(:,3) = z(N_chord+1:N_chord+N_dihe)';
else
    wing_geom(:,3) = wing_geom(:,5).*0; % no dihedral
end
wing_geom(:,4) = z(1:N_chord)';
wing_geom(:,1:4) = wing_geom(:,1:4)./100; % cm to m

% Number of props ON THE HALF SPAN
le_location = 22.6/482;
for i = 1:N_prop_max
    prop_y(i) = z(N_chord+N_dihe + 2 + (i-1)*Vars_prop + 1);
    prop_x(i) = (prop_y(i).*le_location) - (0.25*rotor.diam*100);
    prop_z(i) = (interp1(wing_geom(:,2), wing_geom(:,3), prop_y(i)./100,'linear','extrap').*100) + z((N_chord+N_dihe + 2 + (i-1)*Vars_prop) + 2);
end
N_prop = sum(prop_y <= 484);

% Define flight speed and conditions
vinf = 77.2;
rho = 1.007;
weightN = 13344.6648; % 3000 lb in N

wing_sweep_filename = ['aux_files/wing_sweep_',temp_name,'.vap'];
copyfile('X57_BLANK.vap', wing_sweep_filename);

vap3_inputmod_wing(wing_sweep_filename, wing_geom);

cd '../../'
seqALPHA = [2:10];
for i = 1:length(seqALPHA)
    VAP_IN = [];
    VAP_IN.vecVEHALPHA = seqALPHA(i);
    VAP_IN.valDELTIME = .25/vinf;
    VAP_IN.valSTARTFORCES = 30;
    VAP_IN.valMAXTIME = 30;
    %                     VAP_IN.valSTARTFORCES = 5
    %                     VAP_IN.valMAXTIME = 10
    WING_SWEEP(i) = fcnVAP_MAIN(wing_sweep_filename, VAP_IN);
end
cd 'Runs/J_COLE_OPTIMIZATION/'
delete(wing_sweep_filename)

% Calculate CL at VINF and S&L flight
S    = WING_SWEEP(1).valAREA; % ref. platform area
CL   = weightN./(0.5*rho*vinf.^2*S);

% interpolate alpha to maintain steady level flight at VINF
% using wing only data
ALPHA = interp1([WING_SWEEP.vecCLv_AVG],[WING_SWEEP.vecVEHALPHA],CL);
CDvap = interp1([WING_SWEEP.vecVEHALPHA],[WING_SWEEP.vecCD_AVG],ALPHA);
LD = 14;
CD = CL./(LD); % Calculate CD with Borer L/D Data
CX = 0.0294;
D  = 0.5*rho*vinf.^2.*CD*S; % Calulate drag force in Newton
thrust  = (D./cosd(ALPHA))/(2*N_prop); % Calculate Thrust force required from EACH PROP

%% Creating propeller in QMIL
[qmil_path, collective] = fcnQMILCREATE(temp_name, airfoil_data, rotor.blades, thrust, vinf, rotor.rpm, rotor.diam);
qmil_filename = regexprep(qmil_path, 'aux_files/', '');

% RUN QMIL
qmil_output_filename = ['output_', qmil_filename];

if ispc
    qmil_output_path = ['aux_files\', qmil_output_filename];
    exeName = ['aux_files\', qmil_filename, '.exe'];
    copyfile('qmil.exe', exeName);
else
    qmil_output_path = ['aux_files/', qmil_output_filename];
    exeName = ['aux_files/', qmil_filename, 'ex'];
    copyfile('qmilex', exeName);
end

prmpt = sprintf('%s %s %s', exeName, qmil_path, qmil_output_path);
[~,~] = system(prmpt);

delete(exeName);
delete(qmil_path);

%% Building Propeller & Wing VAP File
vap_filename = ['aux_files/vap_',temp_name,'.vap'];
copyfile('X57_BLANK.vap', vap_filename);

vap3_inputmod_wing(vap_filename, wing_geom)
for i = 1:N_prop
    rotor.hub = [prop_x(i) prop_y(i) prop_z(i)]./100;
    temp_dir = z((N_chord+N_dihe + 2 + (i-1)*Vars_prop) + 3); % 0 to 1. 0 < x <= 0.5, clockwise
    rotor.dir(temp_dir <= 0.5) = 0;
    rotor.dir(temp_dir > 0.5) = 1;
    vap3_inputmod_prop(vap_filename, rotor, qmil_output_path);
end
delete(qmil_output_path);

%% Trim
ROTDIAM  = rotor.diam; % should be 1.524
ROTORRPM = rotor.rpm; %should be 2250
rps      = ROTORRPM/60;

% Calculate CT required to maintain S&L flight
CT = thrust/(rho*rps^2*ROTDIAM^4);

ITER.maxIter = 6;
ITER.numCase = length(vinf);

ITER.Iteration = repmat((1:ITER.maxIter)',1,ITER.numCase);
ITER.CL        = nan(1, ITER.numCase);
ITER.CT        = nan(1, ITER.numCase);
ITER.CD        = nan(1, ITER.numCase);
ITER.AOA       = nan(1, ITER.numCase);
ITER.CLTV      = nan(1, ITER.numCase);

seqALPHA = ALPHA;

TRIMMED = false;
CDnac = 0.0025;
deltaCT = 0;

for n = 1:ITER.maxIter
    
    if n > 1
        deltaCT = deltaCT + (CT - ITER.CT(n - 1));
        % Alter thrust to account for updated drag prediction
        D = (CX + ITER.CD(n - 1) + sum(CDnac))*(0.5*rho*(vinf.^2)*S);
        CT = ((D / cosd(seqALPHA)) /(2*N_prop))/(rho*rps^2*ROTDIAM^4);
        thrust = (CT + deltaCT)*(rho*rps^2*ROTDIAM^4);
        
        %% Creating propeller in QMIL
        [qmil_path, collective] = fcnQMILCREATE(temp_name, airfoil_data, rotor.blades, thrust, vinf, rotor.rpm, rotor.diam);
        qmil_filename = regexprep(qmil_path, 'aux_files/', '');
        
        % RUN QMIL
        qmil_output_filename = ['output_', qmil_filename];
        
        if ispc
            qmil_output_path = ['aux_files\', qmil_output_filename];
            exeName = ['aux_files\', qmil_filename, '.exe'];
            copyfile('qmil.exe', exeName);
        else
            qmil_output_path = ['aux_files/', qmil_output_filename];
            exeName = ['aux_files/', qmil_filename, 'ex'];
            copyfile('qmilex', exeName);
        end
        
        prmpt = sprintf('%s %s %s', exeName, qmil_path, qmil_output_path);
        [~,~] = system(prmpt);
        
        delete(exeName);
        delete(qmil_path);
        
        %% Building Propeller & Wing VAP File
        vap_filename = ['aux_files/vap_',temp_name,'.vap'];
        copyfile('X57_BLANK.vap', vap_filename);
        
        vap3_inputmod_wing(vap_filename, wing_geom)
        for i = 1:N_prop
            rotor.hub = [prop_x(i) prop_y(i) prop_z(i)]./100;
            temp_dir = z((N_chord+N_dihe + 2 + (i-1)*Vars_prop) + 3); % 0 to 1. 0 < x <= 0.5, clockwise
            rotor.dir(temp_dir <= 0.5) = 0;
            rotor.dir(temp_dir > 0.5) = 1;
            vap3_inputmod_prop(vap_filename, rotor, qmil_output_path);
        end
        delete(qmil_output_path);
        
        
    end
    
    if n == 2
        dCL1 = CL - ITER.CL(1,:);
        % New sets of AOA input for 2nd iteration in order to hit the targeted CL
        seqALPHA = interp1([WING_SWEEP.vecCLv_AVG],[WING_SWEEP.vecVEHALPHA],CL + dCL1, 'linear', 'extrap');
    elseif n > 2
        % New sets of AOA input for the next iteration in order to hit the targeted CL
        seqALPHA = interp1(ITER.CL(1:n-1),ITER.AOA(1:n-1),CL,'linear','extrap');
    end
    
    ITER.AOA(n)  = seqALPHA;
    
    cd '../../'
    VAP_IN = [];
    VAP_IN.vecVEHALPHA = seqALPHA;
    VAP_IN.vecVEHVINF = vinf;
    VAP_IN.valMAXTIME = 160;
    VAP_IN.vecCOLLECTIVE = repmat(collective, N_prop, 1);
    VAP_IN.valSTARTFORCES = VAP_IN.valMAXTIME-20;
    %                         VAP_IN.valMAXTIME = 7
    %                         VAP_IN.valSTARTFORCES = 6
    VAP_IN.valDELTIME = (1/60)/(rotor.rpm/60);
    OUTP = fcnVAP_MAIN(vap_filename, VAP_IN);
    cd 'Runs/J_COLE_OPTIMIZATION/'
    
    % Write results
    ITER.CL(n,:) = OUTP.vecCL_AVG + (2.*(sind(ALPHA).*(sum(OUTP.vecCT_AVG).*((OUTP.vecROTORRPM(1)/60).^2).*(OUTP.vecROTDIAM(1).^4).*rho))./(rho.*S.*vinf.^2));
    ITER.CT(n,:) = nanmean(OUTP.vecCT_AVG);
    ITER.CD(n,:) = [OUTP.vecCD_AVG];
    CDnac = OUTP.NACELLE.vecNACDRAG/(0.5*rho*(vinf^2)*S);
    ITEROUTP(n).OUTP = OUTP;
    
    dCT = abs((ITER.CT(end) - CT)./CT);
    dCL = abs((ITER.CL(end) - CL)./CL);
    if dCT <= 0.01 && dCL <= 0.01 && n > 1
        break;
    end
end


dCT = abs((ITER.CT(end) - CT)./CT);
dCL = abs((ITER.CL(end) - CL)./CL);

if dCT <= 0.01 && dCL <= 0.01
    TRIMMED = true;
end


delete(vap_filename)

%% ANALYZE RESULTS

if TRIMMED == true
    out = sum(2.*OUTP.vecCP_AVG).*((rotor.rpm/60).^3).*(rotor.diam.^5).*OUTP.valDENSITY;
    
    if nargin ~= 0
        fp2 = fopen('opthistory.txt','at');
        fprintf(fp2,'%g ', [out, z]);
        fprintf(fp2,'\n');
        fclose(fp2);
    end
    
else
    out = 1e+20;
end

delete(matname)

end

