% Description:
% 
% The purpose of this file is to generate a plot of the efficiency of the
% assembly of a trimer XAY as the concentration of A and the cooperativity
% (theta) of binding of X and Y to A are varied.

close all;
clear all;

% set inital concentrations of X and Y
X0 = 1;
Y0 = 1;

% set effective affinity of A to X and Y
K_AX = 1;
K_AY = 1;

str = '';

log10_A0 = [-4:0.05:4]';
A0 = 10.^log10_A0;
n=size(log10_A0,1);

IC_vec(:,1) = ones(n,1) * X0;      % X0
IC_vec(:,2) = A0;                  % A0
IC_vec(:,3) = ones(n,1) * Y0;      % Y0

% copy some data for easy export or copy/paste into spreadsheet
excel(:,1) = 10.^log10_A0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% simulation loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

log10_theta = [0:0.25:4];
theta = 10.^log10_theta;

for i = 1:size(log10_theta,2)

    % we calculate the differential affinity required to achieve
    % a cooperativity of theta, assuming that alpha_X=alpha_Y=alpha and
    % that K_RS=1/alpha, which is also the K_RS which
    % maximizes cooperativity given alpha.
    b = 2-4*theta(i);
    alpha = (-b+(b^2-4)^0.5)/2;
    alpha_X = alpha;
    alpha_Y = alpha;
    K_RS = 1/alpha;
    
    theta_verify = (1+K_RS)*(1+alpha_X*alpha_Y*K_RS)/((1+alpha_X*K_RS)*(1+alpha_Y*K_RS));
    if (theta(i) ~= theta_verify)
        disp('ERROR in theta calculation!!!');
    end
    
    % given effective affinities, K_RS and alpha,
    % calculate affinity to R conformation
    K_RX = K_AX * (K_RS + 1)/(alpha_X * K_RS + 1);
	K_RY = K_AY * (K_RS + 1)/(alpha_Y * K_RS + 1);

    L_vec(:,1) = K_RS * ones(n,1);
    KR_vec(:,1) = K_RX * ones(n,1);
    KR_vec(:,2) = K_RY * ones(n,1);
    alpha_vec(:,1) = alpha_X * ones(n,1);
    alpha_vec(:,2) = alpha_Y * ones(n,1);

    results = XAY_ssFunc([IC_vec, L_vec, KR_vec, alpha_vec]);
    XAY(:,i) = results(:,1);
    excel(:,end+1) = XAY(:,i);
    
end


save XAY_prozone.mat


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% analysis/plotting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all;

% plots of XAY, efficacy, efficiency...
for i = 1:size(log10_theta,2)
    efficiency_A = XAY(:,i) ./ A0;
    efficiency_agg = 3*XAY(:,i) ./ (A0 + X0 + Y0);
    efficacy = XAY(:,i) ./ min(A0, min(X0, Y0));
        
    figure(1);
    semilogx(A0, XAY, '.-b')
    hold on; semilogx(A0, efficiency_A, '.-r')
    hold on; semilogx(A0, efficiency_agg, '.-k')
    hold on; semilogx(A0, efficacy, '.-g')
    legend('XAY', 'efficiency of A', 'aggregate efficiency','efficacy');
    xlabel('total A')
    xlim([1e-4 1e4])
    ylim([0 1])
    
    if (isempty(str))
        str = sprintf('%.2f',str,theta(i));
    else
        str = sprintf('%s,%.2f',str,theta(i));
    end
end
    
str = sprintf('theta=(%s), Kd=1, X0=%.2f Y0=%.2f',str,X0, Y0);
title(str);
grid;

% compute and plot max response and widths
for i = 1:size(log10_theta,2)
    XAY_max(i) = max(XAY(:,i));
    XAY_max_index(i) = find(XAY(:,i) == XAY_max(i));
    XAY_50p(i) = XAY_max(i)/2;
    XAY_left = XAY(1:XAY_max_index(i),i);
    XAY_right = XAY(XAY_max_index(i):end,i);
    A0_left = A0(1:XAY_max_index(i));
    A0_right = A0(XAY_max_index(i):end);
    
    A0_50p_left(i) = interp1(XAY_left, A0_left, XAY_50p(i), 'cubic');
    A0_50p_right(i) = interp1(XAY_right, A0_right, XAY_50p(i), 'cubic');
end
XAY_width = log10(A0_50p_right) - log10(A0_50p_left);

figure(2)
semilogx(theta, XAY_width, 'k.-');
hold on;
semilogx(theta, XAY_max / XAY_max(1), 'b.-');


