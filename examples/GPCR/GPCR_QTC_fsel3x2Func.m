function rval = GPCR_QTC_fsel3x2Func(arg_matrix)

KactL_vec = arg_matrix(:,1);
KactG_vec = arg_matrix(:,2);
Gamma_vec = arg_matrix(:,3);

IC_R_vec = arg_matrix(:,4);
L_clamp_vec = arg_matrix(:,5:7);
IC_G_vec = arg_matrix(:,8:9);

Ka_vec = arg_matrix(:,10:12);
alpha_t_vec = arg_matrix(:,13:15);
alpha_a_vec = arg_matrix(:,16:18);
alpha_at_vec = arg_matrix(:,19:21);

Kg_vec = arg_matrix(:,22:23);
beta_t_vec = arg_matrix(:,24:25);
beta_a_vec = arg_matrix(:,26:27);
beta_at_vec = arg_matrix(:,28:29);

N = size(arg_matrix,1);

for i=1:N
    
    
    % initial values (free nodes only)
    G1 = IC_G_vec(i,1);
    Ras = 0;
    G1_Rasi00 = 0;
    Rat = 0;
    G1_Rati00 = 0;
    Ris = IC_R_vec(i,1);
    G1_Risi00 = 0;
    Rit = 0;
    G1_Riti00 = 0;
    G2 = IC_G_vec(i,2);
    G2_Rasi00 = 0;
    G2_Rati00 = 0;
    G2_Risi00 = 0;
    G2_Riti00 = 0;
    L1 = 0;
    L1_Rasi00 = 0;
    L1_Rati00 = 0;
    L1_Risi00 = 0;
    L1_Riti00 = 0;
    L2 = 0;
    L2_Rasi00 = 0;
    L2_Rati00 = 0;
    L2_Risi00 = 0;
    L2_Riti00 = 0;
    L3 = 0;
    L3_Rasi00 = 0;
    L3_Rati00 = 0;
    L3_Risi00 = 0;
    L3_Riti00 = 0;
    G1_L1_Rasi00 = 0;
    G1_L1_Rati00 = 0;
    G1_L1_Risi00 = 0;
    G1_L1_Riti00 = 0;
    G1_L2_Rasi00 = 0;
    G1_L2_Rati00 = 0;
    G1_L2_Risi00 = 0;
    G1_L2_Riti00 = 0;
    G1_L3_Rasi00 = 0;
    G1_L3_Rati00 = 0;
    G1_L3_Risi00 = 0;
    G1_L3_Riti00 = 0;
    G2_L1_Rasi00 = 0;
    G2_L1_Rati00 = 0;
    G2_L1_Risi00 = 0;
    G2_L1_Riti00 = 0;
    G2_L2_Rasi00 = 0;
    G2_L2_Rati00 = 0;
    G2_L2_Risi00 = 0;
    G2_L2_Riti00 = 0;
    G2_L3_Rasi00 = 0;
    G2_L3_Rati00 = 0;
    G2_L3_Risi00 = 0;
    G2_L3_Riti00 = 0;
    ivalues = [G1 Ras G1_Rasi00 Rat G1_Rati00 Ris G1_Risi00 Rit ...
        G1_Riti00 G2 G2_Rasi00 G2_Rati00 G2_Risi00 G2_Riti00 L1 L1_Rasi00 ...
        L1_Rati00 L1_Risi00 L1_Riti00 L2 L2_Rasi00 L2_Rati00 L2_Risi00 L2_Riti00 ...
        L3 L3_Rasi00 L3_Rati00 L3_Risi00 L3_Riti00 G1_L1_Rasi00 G1_L1_Rati00 G1_L1_Risi00 ...
        G1_L1_Riti00 G1_L2_Rasi00 G1_L2_Rati00 G1_L2_Risi00 G1_L2_Riti00 G1_L3_Rasi00 G1_L3_Rati00 G1_L3_Risi00 ...
        G1_L3_Riti00 G2_L1_Rasi00 G2_L1_Rati00 G2_L1_Risi00 G2_L1_Riti00 G2_L2_Rasi00 G2_L2_Rati00 G2_L2_Risi00 ...
        G2_L2_Riti00 G2_L3_Rasi00 G2_L3_Rati00 G2_L3_Risi00 G2_L3_Riti00];
    
    % rate constants
    KactL= KactL_vec(i,1);
    k_st= 10;
    KactG= KactG_vec(i,1);
    k_ia= 1;
    Gamma= Gamma_vec(i,1);
    Phi= 0.5;
    Ka1= Ka_vec(i,1);
    kf1_is= 1;
    alpha1_t= alpha_t_vec(i,1);
    kf1_it= 1;
    alpha1_a= alpha_a_vec(i,1);
    kf1_as= 1;
    alpha1_at= alpha_at_vec(i,1);
    kf1_at= 100;
    Ka2= Ka_vec(i,2);
    kf2_is= 1;
    alpha2_t= alpha_t_vec(i,2);
    kf2_it= 1;
    alpha2_a= alpha_a_vec(i,2);
    kf2_as= 1;
    alpha2_at= alpha_at_vec(i,2);
    kf2_at= 1;
    Ka3= Ka_vec(i,3);
    kf3_is= 1;
    alpha3_t= alpha_t_vec(i,3);
    kf3_it= 1;
    alpha3_a= alpha_a_vec(i,3);
    kf3_as= 1;
    alpha3_at= alpha_at_vec(i,3);
    kf3_at= 1;
    Kg1= Kg_vec(i,1);
    kfg1_is= 1;
    beta1_t= beta_t_vec(i,1);
    kfg1_it= 1;
    beta1_a= beta_a_vec(i,1);
    kfg1_as= 1;
    beta1_at= beta_at_vec(i,1);
    kfg1_at= 1;
    Kg2= Kg_vec(i,2);
    kfg2_is= 1;
    beta2_t= beta_t_vec(i,2);
    kfg2_it= 1;
    beta2_a= beta_a_vec(i,2);
    kfg2_as= 1;
    beta2_at= beta_at_vec(i,2);
    kfg2_at= 1;
    L1_clamp= L_clamp_vec(i,1);
    L2_clamp= L_clamp_vec(i,2);
    L3_clamp= L_clamp_vec(i,3);
    k_sink_Stm00_L1= 1000;
    k_sink_Stm01_L2= 1000;
    k_sink_Stm02_L3= 1000;
    rates= [KactL k_st KactG k_ia Gamma Phi Ka1 kf1_is alpha1_t kf1_it alpha1_a kf1_as ...
        alpha1_at kf1_at Ka2 kf2_is alpha2_t kf2_it alpha2_a kf2_as alpha2_at kf2_at Ka3 kf3_is ...
        alpha3_t kf3_it alpha3_a kf3_as alpha3_at kf3_at Kg1 kfg1_is beta1_t kfg1_it beta1_a kfg1_as ...
        beta1_at kfg1_at Kg2 kfg2_is beta2_t kfg2_it beta2_a kfg2_as beta2_at kfg2_at L1_clamp L2_clamp ...
        L3_clamp k_sink_Stm00_L1 k_sink_Stm01_L2 k_sink_Stm02_L3];
    
    % time interval
    t0= 0;
    tf= 100000;
    
    % call solver routine
    global event_times;
    global event_flags;
    
    cd GPCR_QTC_fsel3x2
    [t, y, intervals]= GPCR_QTC_fsel3x2_ode_event(@ode15s, @GPCR_QTC_fsel3x2_odes, [0:1:tf], ivalues, odeset('InitialStep', 1e-15, 'AbsTol', 1e-48, 'RelTol', 1e-5), [0], [100], [1e-3], [1e-6], rates);
    cd ..
    
    % map free node state vector names
    G1 = y(:,1); Ras = y(:,2); G1_Rasi00 = y(:,3); Rat = y(:,4); G1_Rati00 = y(:,5); Ris = y(:,6); G1_Risi00 = y(:,7); Rit = y(:,8); G1_Riti00 = y(:,9); G2 = y(:,10);
    G2_Rasi00 = y(:,11); G2_Rati00 = y(:,12); G2_Risi00 = y(:,13); G2_Riti00 = y(:,14); L1 = y(:,15); L1_Rasi00 = y(:,16); L1_Rati00 = y(:,17); L1_Risi00 = y(:,18); L1_Riti00 = y(:,19); L2 = y(:,20);
    L2_Rasi00 = y(:,21); L2_Rati00 = y(:,22); L2_Risi00 = y(:,23); L2_Riti00 = y(:,24); L3 = y(:,25); L3_Rasi00 = y(:,26); L3_Rati00 = y(:,27); L3_Risi00 = y(:,28); L3_Riti00 = y(:,29); G1_L1_Rasi00 = y(:,30);
    G1_L1_Rati00 = y(:,31); G1_L1_Risi00 = y(:,32); G1_L1_Riti00 = y(:,33); G1_L2_Rasi00 = y(:,34); G1_L2_Rati00 = y(:,35); G1_L2_Risi00 = y(:,36); G1_L2_Riti00 = y(:,37); G1_L3_Rasi00 = y(:,38); G1_L3_Rati00 = y(:,39); G1_L3_Risi00 = y(:,40);
    G1_L3_Riti00 = y(:,41); G2_L1_Rasi00 = y(:,42); G2_L1_Rati00 = y(:,43); G2_L1_Risi00 = y(:,44); G2_L1_Riti00 = y(:,45); G2_L2_Rasi00 = y(:,46); G2_L2_Rati00 = y(:,47); G2_L2_Risi00 = y(:,48); G2_L2_Riti00 = y(:,49); G2_L3_Rasi00 = y(:,50);
    G2_L3_Rati00 = y(:,51); G2_L3_Risi00 = y(:,52); G2_L3_Riti00 = y(:,53);
    
    
    % plot free nodes
    %figure(100);plot(t, L1);title('L1')
    %figure(101);plot(t, L2);title('L2')
    %figure(102);plot(t, L3);title('L3')
    
    % plot expressions
    p_Ris = Ris + G1_Risi00 + G2_Risi00 + L1_Risi00 + L2_Risi00 + L3_Risi00 + G1_L1_Risi00 + G2_L1_Risi00 + G1_L2_Risi00 + G2_L2_Risi00 + G1_L3_Risi00 + G2_L3_Risi00;
    %figure(103); plot(t, p_Ris);title('p\_Ris=Ris + G1\_Risi00 + G2\_Risi00 + L1\_Risi00 .....(truncated)');
    p_Rit = Rit + L1_Riti00 + L2_Riti00 + L3_Riti00 + G1_Riti00 + G2_Riti00 + G1_L1_Riti00 + G2_L1_Riti00 + G1_L2_Riti00 + G2_L2_Riti00 + G1_L3_Riti00 + G2_L3_Riti00;
    %figure(104); plot(t, p_Rit);title('p\_Rit=Rit + L1\_Riti00 + L2\_Riti00 + L3\_Riti00 .....(truncated)');
    p_Ras = Ras + L1_Rasi00 + L2_Rasi00 + L3_Rasi00 + G1_Rasi00 + G2_Rasi00 + G1_L1_Rasi00 + G2_L1_Rasi00 + G1_L2_Rasi00 + G2_L2_Rasi00 + G1_L3_Rasi00 + G2_L3_Rasi00;
    %figure(105); plot(t, p_Ras);title('p\_Ras=Ras + L1\_Rasi00 + L2\_Rasi00 + L3\_Rasi00 .....(truncated)');
    p_Rat = Rat + L1_Rati00 + L2_Rati00 + L3_Rati00 + G1_Rati00 + G2_Rati00 + G1_L1_Rati00 + G2_L1_Rati00 + G1_L2_Rati00 + G2_L2_Rati00 + G1_L3_Rati00 + G2_L3_Rati00;
    %figure(106); plot(t, p_Rat);title('p\_Rat=Rat + L1\_Rati00 + L2\_Rati00 + L3\_Rati00 .....(truncated)');
    p_Rix = Ris + Rit + G1_Risi00 + G2_Risi00 + L1_Risi00 + L2_Risi00 + L3_Risi00 + L1_Riti00 + L2_Riti00 + L3_Riti00 + G1_Riti00 + G2_Riti00 + G1_L1_Risi00 + G2_L1_Risi00 + G1_L1_Riti00 + G2_L1_Riti00 + G1_L2_Risi00 + G2_L2_Risi00 + G1_L2_Riti00 + G2_L2_Riti00 + G1_L3_Risi00 + G2_L3_Risi00 + G1_L3_Riti00 + G2_L3_Riti00;
    %figure(107); plot(t, p_Rix);title('p\_Rix=Ris + Rit + G1\_Risi00 + G2\_Risi00 + L1\_R.....(truncated)');
    p_Rax = Ras + Rat + L1_Rasi00 + L1_Rati00 + L2_Rasi00 + L2_Rati00 + L3_Rasi00 + L3_Rati00 + G1_Rasi00 + G1_Rati00 + G2_Rasi00 + G2_Rati00 + G1_L1_Rasi00 + G1_L1_Rati00 + G2_L1_Rasi00 + G2_L1_Rati00 + G1_L2_Rasi00 + G1_L2_Rati00 + G2_L2_Rasi00 + G2_L2_Rati00 + G1_L3_Rasi00 + G1_L3_Rati00 + G2_L3_Rasi00 + G2_L3_Rati00;
    %figure(108); plot(t, p_Rax);title('p\_Rax=Ras + Rat + L1\_Rasi00 + L1\_Rati00 + L2\_R.....(truncated)');
    p_TOTAL_R = Ris + Ras + Rit + Rat + G1_Risi00 + G2_Risi00 + L1_Risi00 + L2_Risi00 + L3_Risi00 + L1_Rasi00 + L1_Riti00 + L1_Rati00 + L2_Rasi00 + L2_Riti00 + L2_Rati00 + L3_Rasi00 + L3_Riti00 + L3_Rati00 + G1_Rasi00 + G1_Riti00 + G1_Rati00 + G2_Rasi00 + G2_Riti00 + G2_Rati00 + G1_L1_Risi00 + G2_L1_Risi00 + G1_L1_Rasi00 + G1_L1_Riti00 + G1_L1_Rati00 + G2_L1_Rasi00 + G2_L1_Riti00 + G2_L1_Rati00 + G1_L2_Risi00 + G2_L2_Risi00 + G1_L2_Rasi00 + G1_L2_Riti00 + G1_L2_Rati00 + G2_L2_Rasi00 + G2_L2_Riti00 + G2_L2_Rati00 + G1_L3_Risi00 + G2_L3_Risi00 + G1_L3_Rasi00 + G1_L3_Riti00 + G1_L3_Rati00 + G2_L3_Rasi00 + G2_L3_Riti00 + G2_L3_Rati00;
    %figure(109); plot(t, p_TOTAL_R);title('p\_TOTAL\_R=Ris + Ras + Rit + Rat + G1\_Risi00 + G2\_R.....(truncated)');
    p_FREE_R = Ris + Ras + Rit + Rat;
    %figure(110); plot(t, p_FREE_R);title('p\_FREE\_R=Ris + Ras + Rit + Rat');
    p_Lx_R = L1_Risi00 + L2_Risi00 + L3_Risi00 + L1_Rasi00 + L1_Riti00 + L1_Rati00 + L2_Rasi00 + L2_Riti00 + L2_Rati00 + L3_Rasi00 + L3_Riti00 + L3_Rati00;
    %figure(111); plot(t, p_Lx_R);title('p\_Lx\_R=L1\_Risi00 + L2\_Risi00 + L3\_Risi00 + L1\_R.....(truncated)');
    p_R_G1 = G1_Risi00 + G1_Rasi00 + G1_Riti00 + G1_Rati00;
    %figure(112); plot(t, p_R_G1);title('p\_R\_G1=G1\_Risi00 + G1\_Rasi00 + G1\_Riti00 + G1\_R.....(truncated)');
    p_Lx_R_G1 = G1_L1_Risi00 + G1_L1_Rasi00 + G1_L1_Riti00 + G1_L1_Rati00 + G1_L2_Risi00 + G1_L2_Rasi00 + G1_L2_Riti00 + G1_L2_Rati00 + G1_L3_Risi00 + G1_L3_Rasi00 + G1_L3_Riti00 + G1_L3_Rati00;
    %figure(113); plot(t, p_Lx_R_G1);title('p\_Lx\_R\_G1=G1\_L1\_Risi00 + G1\_L1\_Rasi00 + G1\_L1\_Riti.....(truncated)');
    p_Rax_G1 = G1_Rasi00 + G1_Rati00 + G1_L1_Rasi00 + G1_L1_Rati00 + G1_L2_Rasi00 + G1_L2_Rati00 + G1_L3_Rasi00 + G1_L3_Rati00;
    %figure(114); plot(t, p_Rax_G1);title('p\_Rax\_G1=G1\_Rasi00 + G1\_Rati00 + G1\_L1\_Rasi00 + G.....(truncated)');
    p_Rix_G1 = G1_Risi00 + G1_Riti00 + G1_L1_Risi00 + G1_L1_Riti00 + G1_L2_Risi00 + G1_L2_Riti00 + G1_L3_Risi00 + G1_L3_Riti00;
    %figure(115); plot(t, p_Rix_G1);title('p\_Rix\_G1=G1\_Risi00 + G1\_Riti00 + G1\_L1\_Risi00 + G.....(truncated)');
    p_Rax_G2 = G2_Rasi00 + G2_Rati00 + G2_L1_Rasi00 + G2_L1_Rati00 + G2_L2_Rasi00 + G2_L2_Rati00 + G2_L3_Rasi00 + G2_L3_Rati00;
    %figure(116); plot(t, p_Rax_G2);title('p\_Rax\_G2=G2\_Rasi00 + G2\_Rati00 + G2\_L1\_Rasi00 + G.....(truncated)');
    p_Rix_G2 = G2_Risi00 + G2_Riti00 + G2_L1_Risi00 + G2_L1_Riti00 + G2_L2_Risi00 + G2_L2_Riti00 + G2_L3_Risi00 + G2_L3_Riti00;
    %figure(117); plot(t, p_Rix_G2);title('p\_Rix\_G2=G2\_Risi00 + G2\_Riti00 + G2\_L1\_Risi00 + G.....(truncated)');
    
    % issue done message for calling/wrapper scripts
    disp('Facile driver script done');
    
    rval(i,1) = p_Rax_G1(end);
    rval(i,2) = p_Rax_G2(end);
    rval(i,3) = p_Rix_G1(end);
    rval(i,4) = p_Rix_G2(end);

end
