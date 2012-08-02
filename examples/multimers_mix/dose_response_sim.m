% Description: Study the effect of competitive agonists on the
% dose-response curve of a reference agonist through the hill number and
% EC50 of that response.
%
% A panel of agonists is defined each with a distinct differential affinity
% to each conformation of the protein. Then, the dose-response curve of each
% agonist is computed in isolation. One of these is designated as the
% reference agonist, and its dose-response curve in the presence of different
% concentrations of each competitor (including itself) is measured.
%
% In 3-D matrix of results(i,j,k) i indexes points of a dose-response,
% j indexes ligands (so each column corresponds to a ligand), and
% k>=2 indexes the concentration of the competitive ligand.
% If k=1, then the matrix contains dose-response curves of individual
% ligands.
%
% A script dose_response_analyze.m is used to analyze & plot results.
%

clear all; close all;

KNF_flag = 0;

if (KNF_flag ~= 0)
    K_TR = 0.01;
    Gamma = 10;
else
    K_TR = 1e-3;
    Gamma = 999;  % dummy value
end

delta_log_L1 = 0.005;
log_L1 = (-3:delta_log_L1:4);
L1 = 10.^log_L1;
m = size(L1,2);  % m = no. of points on curve

delta_log_alpha = 2;
log_alpha = (2:-delta_log_alpha:-2);
alpha = 10.^log_alpha;
n = size(alpha,2);  % n = no. of ligands

K_T = 1 ./ sqrt(alpha);
K_R = 1 .* sqrt(alpha);

L1_indx = find(log_alpha==2);   % find the index of ligand with alpha==100

K = 30;  % no. of points on either side of ec50

%%%%%%%%%%%%%%%%%%%%%%%%
% simulation loop
%%%%%%%%%%%%%%%%%%%%%%%%
for k=1:(2*K+2)  % loop thru concentrations
    
    for j=1:n  % loop thru ligands
        
        disp(sprintf('ITERATION (j,k) = (%d, %d)', j, k));
        
        IC_vec(:,1) = ones(m,1) * 1;
        IC_vec(:,2) = ones(m,1) * 0;
        IC_vec(:,3) = ones(m,1) * 0;
        
        K_TR_vec = ones(m,1) * K_TR;
        Gamma_vec = ones(m,1) * Gamma;
        
        L1_clamp_vec = L1';
        
        if k==1   % dose-response of each ligand alone
            L2_clamp_vec = ones(m,1) * 0;
            K1_T_vec = ones(m,1) * K_T(j);
            K1_R_vec = ones(m,1) * K_R(j);
            K2_T_vec = ones(m,1) * 99; % bogus value
            K2_R_vec = ones(m,1) * 99;
        else      % dose-response of selected ligand w/ each competitor
            L2_clamp_vec = ones(m,1) * mixin_vec(k-1,j);
            K1_T_vec = ones(m,1) * K_T(L1_indx);
            K1_R_vec = ones(m,1) * K_R(L1_indx);
            K2_T_vec = ones(m,1) * K_T(j);
            K2_R_vec = ones(m,1) * K_R(j);
        end
        
        if KNF_flag ~= 0
            res = multimer_KNF_tetra_mixFunc([ ...
                IC_vec, ...
                L1_clamp_vec, ...
                L2_clamp_vec, ...
                K_TR_vec,  ...
                Gamma_vec, ...
                K1_T_vec, ...
                K1_R_vec, ...
                K2_T_vec, ...
                K2_R_vec, ...
                ]);
        else
            res = multimer_MWC_mixFunc([ ...
                IC_vec, ...
                L1_clamp_vec, ...
                L2_clamp_vec, ...
                K_TR_vec,  ...
                K1_T_vec, ...
                K1_R_vec, ...
                K2_T_vec, ...
                K2_R_vec, ...
                ]);
        end

        p_L1x0 = res(:,1);
        p_L1x1 = res(:,2);
        p_L1x2 = res(:,3);
        p_L1x3 = res(:,4);
        p_L1x4 = res(:,5);
        
        occupancy = (p_L1x1 + 2*p_L1x2 + 3*p_L1x3 + 4*p_L1x4)/4;
        
        response(:,j,k) = occupancy;
        
        if k==1
            % calculate mixin concentrations such that we sample with
            % appropriate density near ec50 of competitor
            ec40 = interp1(occupancy, L1_clamp_vec, 0.4, 'cubic');
            ec50 = interp1(occupancy, L1_clamp_vec, 0.5, 'cubic');
            ec60 = interp1(occupancy, L1_clamp_vec, 0.6, 'cubic');
            
            step_ratio = sqrt(ec60/ec40);
            
            mixin_vec(:,j) = ec50 .* (step_ratio .^ (-K:1:K));
        end
    end
    
end

if exist('tag') == 0
    if KNF_flag ~= 0
        tag = strrep(sprintf('KNF_G%gK%g', Gamma, K_TR), '.', 'p');
    else
        tag = strrep(sprintf('MWC_K%g', K_TR), '.', 'p');
    end
end

save dr.temp.mat;
system(sprintf('cp dr.temp.mat dr.%s.mat', tag));


