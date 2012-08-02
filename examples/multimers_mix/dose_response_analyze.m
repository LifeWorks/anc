% Description: Analyze the simulation results of dose_response_sim.m

close all;

colours = 'gbcmry';
markers = '.xsod*';

%%%%%%%%%%%%%%%%%%%%%%%%%
% analysis & plotting
%%%%%%%%%%%%%%%%%%%%%%%%%
clear ec50;

for k=1:(2*K+2)  % loop thru concentrations
    
    for j=1:n  % loop thru ligands
        
        disp(sprintf('ITERATION (j,k) = (%d, %d)', j, k));
        
        % compute ec50 of all responses
        if max(response(:,j,k)) > 0.5
            ec50(k,j) = interp1(response(:,j,k), L1_clamp_vec, 0.5, 'cubic');
        else
            ec50(k,j) = NaN;
        end
        
        %line_format = [colours(i),markers(i),'-'];
        if k==1
            line_format = 'k.-';
        else
            format_index = mod(j-1,n) + 1;
            line_format = [colours(format_index),markers(format_index),'-'];
        end
        
        figure(1);
        semilogx(L1_clamp_vec, response(:,j,k),line_format); hold on;
        grid on;
        
        figure(2);
        plot(L1_clamp_vec, response(:,j,k),line_format); hold on;
        xlim([0 2]); grid on;
        
        figure(3);
        y_over_1minusy = response(:,j,k)./(1-response(:,j,k));
        plot(log10(L1_clamp_vec), log10(y_over_1minusy),line_format);
        hold on;
        grid on;
        
        % method 1: compute max slope of log[y/(1-y)] to estimate hill coeff
        delta_y = log10(y_over_1minusy(2:end)) - log10(y_over_1minusy(1:end-1));
        delta_x = log10(L1_clamp_vec(2:end)) - log10(L1_clamp_vec(1:end-1));
        [max_dydx, indx] = max(delta_y./delta_x);
        hill_m1(k,j) = max_dydx;
        hill_m1_L1(k,j) = (L1_clamp_vec(indx+1) + L1_clamp_vec(indx)) / 2;
        
        % method 2: compute as h = 2 * [d ln(y) / d ln(x)]@EC50
        if ~isnan(ec50(k,j))
            d_logx = delta_log_L1;
            d_logy = interp1(log(L1_clamp_vec), log(response(:,j,k)), log(ec50(k,j)) + d_logx/2, 'cubic') - ...
                interp1(log(L1_clamp_vec), log(response(:,j,k)), log(ec50(k,j)) - d_logx/2, 'cubic');
            hill_m2(k,j) = d_logy / d_logx * 2;
        else
            hill_m2(k,j) = NaN;
        end
        
        % note: the main difference between the methods is that method no. 1
        % does not evaluate the slope at the EC50 but at its maximum, which could be lower
        % than the EC50. otherwise it should give the same answer.... ??
        
    end
end

mixin_vec
ec50
hill_m1
hill_m1_L1
hill_m2

figure(4);
for j=1:n
    fig_hill_x = mixin_vec(:,j) / ec50(1,j);
    fig_hill_y = fig_hill_x * 0;  % make y same size
    fig_hill_y(1:end) = hill_m2(2:end,j);
    line_format = [colours(j),'.','-'];
    semilogx(fig_hill_x, fig_hill_y, line_format);
    % save for export
    fig_hill(:,2*j-1) = fig_hill_x;
    fig_hill(:,2*j) = fig_hill_y;
    hold on;
    grid on;
end
ylim([1 4]);

figure(5);
for j=1:n
    fig_ec50_x = mixin_vec(:,j) / ec50(1,j);
    fig_ec50_y = fig_ec50_x * 0;  % make y same size
    fig_ec50_y(1:end) = ec50(2:end,j) / ec50(1,L1_indx);
    line_format = [colours(j),'.','-'];
    loglog(fig_ec50_x, fig_ec50_y, line_format);
    % save for export
    fig_ec50(:,2*j-1) = fig_ec50_x;
    fig_ec50(:,2*j) = fig_ec50_y;
    hold on;
    grid on;
end

