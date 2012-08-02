function mma = XAY_ssFunc(arg_matrix)

IC_vec = arg_matrix(:,1:3);
L_vec = arg_matrix(:,4);
KR_vec = arg_matrix(:,5:6);
alpha_vec = arg_matrix(:,7:8);

N = size(arg_matrix,1);

for i=1:N
    
    % initial values (free nodes only)
    AR = IC_vec(i,2);
    X = IC_vec(i,1);
    AR_Xi00 = 0;
    Y = IC_vec(i,3);
    AR_Yi00 = 0;
    AS = 0;
    AS_Xi00 = 0;
    AS_Yi00 = 0;
    AR_X_Yi00 = 0;
    AS_X_Yi00 = 0;
    ivalues = [AR X AR_Xi00 Y AR_Yi00 AS AS_Xi00 AS_Yi00 ...
        AR_X_Yi00 AS_X_Yi00];
    
    % rate constants
    K_RS= L_vec(i,1);
    kf_RS= 0.1;
    Phi_AX= 0.5;
    Phi_AY= 0.5;
    alpha_X= alpha_vec(i,1);
    alpha_Y= alpha_vec(i,2);
    K_RX= KR_vec(i,1);
    kf_RX= 1;
    kf_SX= 1;
    K_RY= KR_vec(i,2);
    kf_RY= 1;
    kf_SY= 1;
    rates= [K_RS kf_RS Phi_AX Phi_AY alpha_X alpha_Y K_RX kf_RX kf_SX K_RY kf_RY kf_SY ...
        ];
    
    % time interval
    t0= 0;
    tf= 500000;
    
    % call solver routine
    global event_times;
    global event_flags;
    
    cd XAY_ss;
    [t,y]= XAY_ss([0:1:tf], ivalues, rates);
    cd ..;
    
    % map free node state vector names
    AR = y(:,1); X = y(:,2); AR_Xi00 = y(:,3); Y = y(:,4); AR_Yi00 = y(:,5); AS = y(:,6); AS_Xi00 = y(:,7); AS_Yi00 = y(:,8); AR_X_Yi00 = y(:,9); AS_X_Yi00 = y(:,10);
    
    
    
    
    % plot free nodes
    %figure(100);plot(t, X);title('X')
    %figure(101);plot(t, Y);title('Y')
    
    % plot expressions
    TRIMER = AR_X_Yi00 + AS_X_Yi00;
    %figure(102); plot(t, TRIMER);title('TRIMER=AR\_X\_Yi00 + AS\_X\_Yi00');
    AX_DIMER = AR_Xi00 + AS_Xi00;
    %figure(103); plot(t, AX_DIMER);title('AX\_DIMER=AR\_Xi00 + AS\_Xi00');
    AY_DIMER = AR_Yi00 + AS_Yi00;
    %figure(104); plot(t, AY_DIMER);title('AY\_DIMER=AR\_Yi00 + AS\_Yi00');
    A_FREE = AR + AS;
    %figure(105); plot(t, A_FREE);title('A\_FREE=AR + AS');
    A_TOTAL = AR + AS + AR_Xi00 + AS_Xi00 + AR_Yi00 + AS_Yi00 + AR_X_Yi00 + AS_X_Yi00;
    %figure(106); plot(t, A_TOTAL);title('A\_TOTAL=AR + AS + AR\_Xi00 + AS\_Xi00 + AR\_Yi00 + .....(truncated)');
    X_TOTAL = X + AR_Xi00 + AS_Xi00 + AR_X_Yi00 + AS_X_Yi00;
    %figure(107); plot(t, X_TOTAL);title('X\_TOTAL=X + AR\_Xi00 + AS\_Xi00 + AR\_X\_Yi00 + AS\_X.....(truncated)');
    Y_TOTAL = Y + AR_Yi00 + AS_Yi00 + AR_X_Yi00 + AS_X_Yi00;
    %figure(108); plot(t, Y_TOTAL);title('Y\_TOTAL=Y + AR\_Yi00 + AS\_Yi00 + AR\_X\_Yi00 + AS\_X.....(truncated)');
    
    % issue done message for calling/wrapper scripts
    disp('Facile driver script done');
    
    
    mma(i,1) = TRIMER(end);
end
end
