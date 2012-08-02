function rval = multimer_MWC_mixFunc(arg_matrix)

IC_vec = arg_matrix(:,1:3);

L1_clamp_vec = arg_matrix(:,4);
L2_clamp_vec = arg_matrix(:,5);

K_TR_vec = arg_matrix(:,6);
K1_T_vec = arg_matrix(:,7);
K1_R_vec = arg_matrix(:,8);
K2_T_vec = arg_matrix(:,9);
K2_R_vec = arg_matrix(:,10);

N = size(arg_matrix,1);

for i=1:N
    
    
    % initial values (free nodes only)
    HR = IC_vec(i,1);
    L1 = IC_vec(i,2);
    HR_L1i00 = 0;
    L2 = IC_vec(i,3);
    HR_L2i00 = 0;
    HT = 0;
    HT_L1i00 = 0;
    HT_L2i00 = 0;
    HR_L1_L1i00 = 0;
    HR_L1_L2i00 = 0;
    HT_L1_L1i00 = 0;
    HT_L1_L2i00 = 0;
    HR_L2_L2i00 = 0;
    HT_L2_L2i00 = 0;
    HR_L1_L1_L1i00 = 0;
    HR_L1_L1_L2i00 = 0;
    HR_L1_L2_L2i00 = 0;
    HT_L1_L1_L1i00 = 0;
    HT_L1_L1_L2i00 = 0;
    HT_L1_L2_L2i00 = 0;
    HR_L2_L2_L2i00 = 0;
    HT_L2_L2_L2i00 = 0;
    HR_L1_L1_L1_L1i00 = 0;
    HR_L1_L1_L1_L2i00 = 0;
    HR_L1_L1_L2_L2i00 = 0;
    HR_L1_L2_L2_L2i00 = 0;
    HT_L1_L1_L1_L1i00 = 0;
    HT_L1_L1_L1_L2i00 = 0;
    HT_L1_L1_L2_L2i00 = 0;
    HT_L1_L2_L2_L2i00 = 0;
    HR_L2_L2_L2_L2i00 = 0;
    HT_L2_L2_L2_L2i00 = 0;
    ivalues = [HR L1 HR_L1i00 L2 HR_L2i00 HT HT_L1i00 HT_L2i00 ...
        HR_L1_L1i00 HR_L1_L2i00 HT_L1_L1i00 HT_L1_L2i00 HR_L2_L2i00 HT_L2_L2i00 HR_L1_L1_L1i00 HR_L1_L1_L2i00 ...
        HR_L1_L2_L2i00 HT_L1_L1_L1i00 HT_L1_L1_L2i00 HT_L1_L2_L2i00 HR_L2_L2_L2i00 HT_L2_L2_L2i00 HR_L1_L1_L1_L1i00 HR_L1_L1_L1_L2i00 ...
        HR_L1_L1_L2_L2i00 HR_L1_L2_L2_L2i00 HT_L1_L1_L1_L1i00 HT_L1_L1_L1_L2i00 HT_L1_L1_L2_L2i00 HT_L1_L2_L2_L2i00 HR_L2_L2_L2_L2i00 HT_L2_L2_L2_L2i00 ...
        ];
    
    % rate constants
    K_TR= K_TR_vec(i,1);
    k_TR= 1;
    Phi_TR= 0.5;
    K1_T= K1_T_vec(i,1);
    kf1_T= 1;
    K1_R= K1_R_vec(i,1);
    kf1_R= 10;
    K2_T= K2_T_vec(i,1);
    kf2_T= 1;
    K2_R= K2_R_vec(i,1);
    kf2_R= 10;
    L1_clamp= L1_clamp_vec(i,1);
    L2_clamp= L2_clamp_vec(i,1);
    k_sink_Stm00_L1= 1000;
    k_sink_Stm01_L2= 1000;
    rates= [K_TR k_TR Phi_TR K1_T kf1_T K1_R kf1_R K2_T kf2_T K2_R kf2_R L1_clamp ...
        L2_clamp k_sink_Stm00_L1 k_sink_Stm01_L2];
    
    % time interval
    t0= 0;
    tf= 100000;
    
    % call solver routine
    global event_times;
    global event_flags;
    
    cd multimer_MWC_mix
    [t, y, intervals]= multimer_MWC_mix_ode_event(@ode15s, @multimer_MWC_mix_odes, [0:1:tf], ivalues, odeset('InitialStep', 1e-15, 'AbsTol', 1e-48, 'RelTol', 1e-5), [0], [100], [1e-3], [1e-6], rates);
    cd ..
    
    % map free node state vector names
    HR = y(:,1); L1 = y(:,2); HR_L1i00 = y(:,3); L2 = y(:,4); HR_L2i00 = y(:,5); HT = y(:,6); HT_L1i00 = y(:,7); HT_L2i00 = y(:,8); HR_L1_L1i00 = y(:,9); HR_L1_L2i00 = y(:,10);
    HT_L1_L1i00 = y(:,11); HT_L1_L2i00 = y(:,12); HR_L2_L2i00 = y(:,13); HT_L2_L2i00 = y(:,14); HR_L1_L1_L1i00 = y(:,15); HR_L1_L1_L2i00 = y(:,16); HR_L1_L2_L2i00 = y(:,17); HT_L1_L1_L1i00 = y(:,18); HT_L1_L1_L2i00 = y(:,19); HT_L1_L2_L2i00 = y(:,20);
    HR_L2_L2_L2i00 = y(:,21); HT_L2_L2_L2i00 = y(:,22); HR_L1_L1_L1_L1i00 = y(:,23); HR_L1_L1_L1_L2i00 = y(:,24); HR_L1_L1_L2_L2i00 = y(:,25); HR_L1_L2_L2_L2i00 = y(:,26); HT_L1_L1_L1_L1i00 = y(:,27); HT_L1_L1_L1_L2i00 = y(:,28); HT_L1_L1_L2_L2i00 = y(:,29); HT_L1_L2_L2_L2i00 = y(:,30);
    HR_L2_L2_L2_L2i00 = y(:,31); HT_L2_L2_L2_L2i00 = y(:,32);
    
    
    
    % plot free nodes
    %figure(100);plot(t, L1);title('L1')
    %figure(101);plot(t, L2);title('L2')
    
    % plot expressions
    p_H_R = HR + HR_L1i00 + HR_L2i00 + HR_L1_L1i00 + HR_L1_L2i00 + HR_L2_L2i00 + HR_L1_L1_L1i00 + HR_L1_L1_L2i00 + HR_L1_L2_L2i00 + HR_L2_L2_L2i00 + HR_L1_L1_L1_L1i00 + HR_L1_L1_L1_L2i00 + HR_L1_L1_L2_L2i00 + HR_L1_L2_L2_L2i00 + HR_L2_L2_L2_L2i00;
    %figure(102); plot(t, p_H_R);title('p\_H\_R=HR + HR\_L1i00 + HR\_L2i00 + HR\_L1\_L1i00 +.....(truncated)');
    p_H_T = HT + HT_L1i00 + HT_L2i00 + HT_L1_L1i00 + HT_L1_L2i00 + HT_L2_L2i00 + HT_L1_L1_L1i00 + HT_L1_L1_L2i00 + HT_L1_L2_L2i00 + HT_L2_L2_L2i00 + HT_L1_L1_L1_L1i00 + HT_L1_L1_L1_L2i00 + HT_L1_L1_L2_L2i00 + HT_L1_L2_L2_L2i00 + HT_L2_L2_L2_L2i00;
    %figure(103); plot(t, p_H_T);title('p\_H\_T=HT + HT\_L1i00 + HT\_L2i00 + HT\_L1\_L1i00 +.....(truncated)');
    p_L1x0 = HR + HT + HR_L2i00 + HT_L2i00 + HR_L2_L2i00 + HT_L2_L2i00 + HR_L2_L2_L2i00 + HT_L2_L2_L2i00 + HR_L2_L2_L2_L2i00 + HT_L2_L2_L2_L2i00;
    %figure(104); plot(t, p_L1x0);title('p\_L1x0=HR + HT + HR\_L2i00 + HT\_L2i00 + HR\_L2\_L2.....(truncated)');
    p_L1x1 = HR_L1i00 + HT_L1i00 + HR_L1_L2i00 + HT_L1_L2i00 + HR_L1_L2_L2i00 + HT_L1_L2_L2i00 + HR_L1_L2_L2_L2i00 + HT_L1_L2_L2_L2i00;
    %figure(105); plot(t, p_L1x1);title('p\_L1x1=HR\_L1i00 + HT\_L1i00 + HR\_L1\_L2i00 + HT\_L.....(truncated)');
    p_L1x2 = HR_L1_L1i00 + HT_L1_L1i00 + HR_L1_L1_L2i00 + HT_L1_L1_L2i00 + HR_L1_L1_L2_L2i00 + HT_L1_L1_L2_L2i00;
    %figure(106); plot(t, p_L1x2);title('p\_L1x2=HR\_L1\_L1i00 + HT\_L1\_L1i00 + HR\_L1\_L1\_L2i.....(truncated)');
    p_L1x3 = HR_L1_L1_L1i00 + HT_L1_L1_L1i00 + HR_L1_L1_L1_L2i00 + HT_L1_L1_L1_L2i00;
    %figure(107); plot(t, p_L1x3);title('p\_L1x3=HR\_L1\_L1\_L1i00 + HT\_L1\_L1\_L1i00 + HR\_L1\_.....(truncated)');
    p_L1x4 = HR_L1_L1_L1_L1i00 + HT_L1_L1_L1_L1i00;
    %figure(108); plot(t, p_L1x4);title('p\_L1x4=HR\_L1\_L1\_L1\_L1i00 + HT\_L1\_L1\_L1\_L1i00');
    
    % issue done message for calling/wrapper scripts
    disp('Facile driver script done');
    
    rval(i,1) = p_L1x0(end);
    rval(i,2) = p_L1x1(end);
    rval(i,3) = p_L1x2(end);
    rval(i,4) = p_L1x3(end);
    rval(i,5) = p_L1x4(end);
    
end

