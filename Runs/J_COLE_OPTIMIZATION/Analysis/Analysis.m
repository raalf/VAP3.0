clc
clear

cd G:\GIT\VAP3\Runs\J_COLE_OPTIMIZATION\Analysis

addpath('../../../')
addpath('../../../airfoils')
addpath('./../../../Runs/J_COLE_OPTIMIZATION/aux_files')
addpath('./../../../Runs/J_COLE_OPTIMIZATION/')

z(1,:) = [71.3941 68.7533 68.6304 65.9588 64.5861 63.2590 61.8437 61.4030 61.1291 60.0904 59.0279 0 0 0 0 0 0 0 0 0 0 0 158.186 2226.86 450.979 -12.5485 0.770671]; % 74748.4
z(2,:) = [85.9495 83.1285 80.1618 77.3493 75.7004 63.8025 60.9942 59.5311 58.3303 57.1046 52.2952 10.054 17.625	17.9299	20.7694	31.5342	33.8535	38.4692	44.6215	49.6259	64.9211	67.2667	159.808	2097.24	144.366	-13.7057 0.605461]; %75836.2
rotors = [1, 1, 1];

legend_entry = {'Baseline Design', 'Cruise-Optimized Design'};

linestyles = {'--';'-.';'-';':'};
markers = {'o';'x';'s';'^';'*';'d';'v';'>';'<';'p';'h'};
colors = {'k';'b';'r';'m';'c';'g'};

% cd ./../
% parfor i = 1:size(z,1) + 1
%     if i == size(z,1) + 1
%         [out(1,i), Design(i).ITER, Design(i).ITEROUTP] = fcnBASELINE_OBJ();
%     else
%         [out(1,i), Design(i).ITER, Design(i).ITEROUTP] = fcnOBJECTIVE(z(i,:), 11, rotors(i), 3);
%     end
% end
% cd Analysis/
% save('matlab.mat');

load('matlab.mat');

%% Drag Bar Graph
x = categorical({'Total Drag', 'Induced Drag', 'Profile Drag'});
vinf = 77.2;
baseline = [Design(end).ITEROUTP(end).OUTP.vecCD_AVG; ...
    Design(end).ITEROUTP(end).OUTP.vecCDI_AVG; ...
    Design(end).ITEROUTP(end).OUTP.vecCDP_AVG];
% baseline = baseline.*(0.5.*Design(end).ITEROUTP(end).OUTP.valDENSITY.*vinf.^2.*(Design(end).ITEROUTP(end).OUTP.valAREA));

for i = 1:size(z,1)
   designs(:,i) = [Design(i).ITEROUTP(end).OUTP.vecCD_AVG; Design(i).ITEROUTP(end).OUTP.vecCDI_AVG; Design(i).ITEROUTP(end).OUTP.vecCDP_AVG];
%    designs(:,i) = designs(:,i).*(0.5.*Design(i).ITEROUTP(end).OUTP.valDENSITY.*vinf.^2.*(Design(i).ITEROUTP(end).OUTP.valAREA));
end

hFig200 = figure(200);
clf(200);

b = bar( x, 100.*(designs - repmat(baseline,[1,size(z,1)]))./repmat(baseline,[1,size(z,1)]) );
b(1).LineStyle = '--';
b(1).LineWidth = 1;
% b(2).LineStyle = '-.';
% b(2).LineWidth = 1;
% b(3).LineStyle = ':';
% b(3).LineWidth = 1;
grid minor
box on
axis tight

ylabel('Percent Change from Baseline', 'FontSize', 15)
% legend('Design 1')

%% Power Bar Graph
x = categorical({'Total Power', 'Induced Power', 'Profile Power'});

baseline = [Design(end).ITEROUTP(end).OUTP.vecCP_AVG; ...
    Design(end).ITEROUTP(end).OUTP.vecCPI_AVG; ...
    Design(end).ITEROUTP(end).OUTP.vecCPP_AVG];
baseline = baseline.*(Design(end).ITEROUTP(end).OUTP.valDENSITY.*(abs(Design(end).ITEROUTP(end).OUTP.vecROTORRPM(1)./60).^3).*(Design(end).ITEROUTP(end).OUTP.vecROTDIAM(1).^5));

designs = [];
for i = 1:size(z,1)
   designs(:,i) = [mean(Design(i).ITEROUTP(end).OUTP.vecCP_AVG,2); mean(Design(i).ITEROUTP(end).OUTP.vecCPI_AVG,2); mean(Design(i).ITEROUTP(end).OUTP.vecCPP_AVG,2)];
   designs(:,i) = designs(:,i).*rotors(i).*(Design(i).ITEROUTP(end).OUTP.valDENSITY.*(abs(Design(i).ITEROUTP(end).OUTP.vecROTORRPM(1)./60).^3).*(Design(i).ITEROUTP(end).OUTP.vecROTDIAM(1).^5));
end

hFig201 = figure(201);
clf(201);

b = bar( x, 100.*(designs - repmat(baseline,[1,size(z,1)]))./repmat(baseline,[1,size(z,1)]) );
b(1).LineStyle = '--';
b(1).LineWidth = 1;
% b(2).LineStyle = '-.';
% b(2).LineWidth = 1;
% b(3).LineStyle = ':';
% b(3).LineWidth = 1;
grid minor
box on
axis tight

ylabel('Percent Change from Baseline', 'FontSize', 15)
% legend('Design 1', 'Design 2', 'Design 3')

%% Prop Thrust Distribution
hFig202 = figure(202);
clf(202);
loc = 2.*(Design(end).ITEROUTP(end).OUTP.ROTOR.vecSPANLOC)./Design(end).ITEROUTP(end).OUTP.vecROTDIAM(1);
p = plot(loc, mean(reshape(Design(end).ITEROUTP(end).OUTP.ROTOR.vecTHRUSTDIST_AVG, 1, 19, 3),3));
p.LineStyle = linestyles{1,:};
p.Marker = markers{1,:};
p.Color = colors{1,:};

grid minor
box on
axis tight
xlabel('Nondimensionalized Radial Location', 'FontSize', 15);
ylabel('Time-Averaged Thrust (N)', 'FontSize', 15);

hold on
for i = 1:size(z,1)
loc = 2.*(Design(i).ITEROUTP(end).OUTP.ROTOR(1).vecSPANLOC)./Design(i).ITEROUTP(end).OUTP.vecROTDIAM(1);
thrust = mean(mean(reshape(cat(1, [Design(i).ITEROUTP(end).OUTP.ROTOR(:).vecTHRUSTDIST_AVG]), 1, 19, rotors(i)*3),3),1);
p = plot(loc, thrust);
p.LineStyle = linestyles{i+1,:};
p.Marker = markers{i+1,:};
p.Color = colors{i+1,:};
end
lgnd = legend(legend_entry,'Location','SouthEast');
hold off

% Figure handle, figure name, figure path, [WIDTH HEIGHT] in inches
fcnFIG2LATEX(hFig202, 'prop_thrust_dist.pdf', 'figures', [6 3.5]);

%% Prop Power Distribution
hFig203 = figure(203);
clf(203);
loc = 2.*(Design(end).ITEROUTP(end).OUTP.ROTOR.vecSPANLOC)./Design(end).ITEROUTP(end).OUTP.vecROTDIAM(1);
p = plot(loc, mean(reshape(Design(end).ITEROUTP(end).OUTP.ROTOR.vecTORQUEDIST_AVG, 1, 19, 3),3));
p.LineStyle = linestyles{1,:};
p.Marker = markers{1,:};
p.Color = colors{1,:};
grid minor
box on
axis tight
xlabel('Nondimensionalized Radial Location', 'FontSize', 15);
ylabel('Time-Averaged Torque (Nm)', 'FontSize', 15);

hold on
for i = 1:size(z,1)
loc = 2.*(Design(i).ITEROUTP(end).OUTP.ROTOR(1).vecSPANLOC)./Design(i).ITEROUTP(end).OUTP.vecROTDIAM(1);
torque = mean(mean(reshape(cat(1, [Design(i).ITEROUTP(end).OUTP.ROTOR(:).vecTORQUEDIST_AVG]), 1, 19, rotors(i)*3),3),1);
p = plot(loc, torque);
p.LineStyle = linestyles{i+1,:};
p.Marker = markers{i+1,:};
p.Color = colors{i+1,:};
end
lgnd = legend(legend_entry,'Location','SouthEast');
hold off

% Figure handle, figure name, figure path, [WIDTH HEIGHT] in inches
fcnFIG2LATEX(hFig203, 'prop_power_dist.pdf', 'figures', [6 3.5]);

%% Lift Distribution
hFig204 = figure(204);
clf(204);
loc = 2.*(Design(1).ITEROUTP(end).OUTP.WING(1).vecSPANLOC)./10;
p = plot(loc, Design(end).ITEROUTP(end).OUTP.WING(1).vecLDIST_AVG);
p.LineStyle = linestyles{1,:};
p.Marker = markers{1,:};
p.Color = colors{1,:};
grid minor
box on
axis tight
xlabel('Nondimensionalized Spanwise Location', 'FontSize', 15);
ylabel('Lift (N)', 'FontSize', 15);

hold on
for i = 1:size(z,1)
loc = 2.*(Design(i).ITEROUTP(end).OUTP.WING(1).vecSPANLOC)./10;
lift = Design(i).ITEROUTP(end).OUTP.WING(1).vecLDIST_AVG;
p = plot(loc, lift);
p.LineStyle = linestyles{i+1,:};
p.Marker = markers{i+1,:};
p.Color = colors{i+1,:};
end
lgnd = legend(legend_entry,'Location','SouthWest');
hold off

% Figure handle, figure name, figure path, [WIDTH HEIGHT] in inches
fcnFIG2LATEX(hFig204, 'lift_dist.pdf', 'figures', [6 3.5]);

%% Drag Distribution
hFig205 = figure(205);
clf(205);
loc = 2.*(Design(1).ITEROUTP(end).OUTP.WING(1).vecSPANLOC)./10;
drag = Design(end).ITEROUTP(end).OUTP.WING(1).vecDIDIST_AVG(11:end) + Design(end).ITEROUTP(end).OUTP.WING(1).vecDPDIST_AVG;
p = plot(loc, drag);
p.LineStyle = linestyles{1,:};
p.Marker = markers{1,:};
p.Color = colors{1,:};
grid minor
box on
axis tight
xlabel('Nondimensionalized Spanwise Location', 'FontSize', 15);
ylabel('Drag (N)', 'FontSize', 15);

hold on
for i = 1:size(z,1)
    loc = 2.*(Design(i).ITEROUTP(end).OUTP.WING(1).vecSPANLOC)./10;
    drag = Design(i).ITEROUTP(end).OUTP.WING(1).vecDIDIST_AVG(2:2:end) + Design(i).ITEROUTP(end).OUTP.WING(1).vecDPDIST_AVG;
    p = plot(loc, drag);
    p.LineStyle = linestyles{i+1,:};
    p.Marker = markers{i+1,:};
    p.Color = colors{i+1,:};
end
lgnd = legend(legend_entry,'Location','SouthWest');
hold off

% Figure handle, figure name, figure path, [WIDTH HEIGHT] in inches
fcnFIG2LATEX(hFig205, 'drag_dist.pdf', 'figures', [6 3.5]);

%% Fitness vs Generation
A = dlmread('fitness.txt','',2,0);

hFig206 = figure(206);
clf(206);
scatter(A(:,1), A(:,3), 'ok');

xlabel('Generation','FontSize',15);
ylabel('Best Fitness (W)','FontSize',15);
box on 
grid minor
axis tight

% Figure handle, figure name, figure path, [WIDTH HEIGHT] in inches
fcnFIG2LATEX(hFig206, 'fitness_vs_generation.pdf', 'figures', [6 3.5]);










