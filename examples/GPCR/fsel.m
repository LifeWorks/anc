clear all; close all;

log_L_vec = [-4:0.25:4]';
L_vec = 10.^log_L_vec;
n = size(L_vec,1);
N = 6*n;

KactL_vec = ones(N,1) * 1;
KactG_vec = ones(N,1) * 0.05;
Gamma_vec = ones(N,1) * 1;

IC_R_vec = ones(N,1) * 1;
L_clamp_vec(:,1) = [L_vec; L_vec; zeros(n,1); zeros(n,1); zeros(n,1); zeros(n,1)];
L_clamp_vec(:,2) = [zeros(n,1); zeros(n,1); L_vec; L_vec; zeros(n,1); zeros(n,1)];
L_clamp_vec(:,3) = [zeros(n,1); zeros(n,1); zeros(n,1); zeros(n,1); L_vec; L_vec];
IC_G_vec(:,1) = [ones(n,1) * 1; zeros(n,1); ones(n,1) * 1; zeros(n,1); ones(n,1) * 1; zeros(n,1)];
IC_G_vec(:,2) = [zeros(n,1); ones(n,1) * 1; zeros(n,1); ones(n,1) * 1; zeros(n,1); ones(n,1) * 1];

% L1 (strong agonist on s)
%Ka_vec(:,1) = ones(N,1) * 10;
%alpha_t_vec(:,1) = ones(N,1) * 0.1;
%alpha_a_vec(:,1) = ones(N,1) * 10;
%alpha_at_vec(:,1) = ones(N,1) * 1;

% L1 
Ka_vec(:,1) = ones(N,1) * 100;
alpha_t_vec(:,1) = ones(N,1) * 0.1;
alpha_a_vec(:,1) = ones(N,1) * 0.4;
alpha_at_vec(:,1) = ones(N,1) * 0.01;

% L2 (strong agonist on t)
%Ka_vec(:,2) = ones(N,1) * 1;
%alpha_t_vec(:,2) = ones(N,1) * 20;
%alpha_a_vec(:,2) = ones(N,1) * 20;
%alpha_at_vec(:,2) = ones(N,1) * 400;

% L2 
Ka_vec(:,2) = ones(N,1) * 20;
alpha_t_vec(:,2) = ones(N,1) * 20;
alpha_a_vec(:,2) = ones(N,1) * 0.05;
alpha_at_vec(:,2) = ones(N,1) * 5;

% L3 (agonist on t, inverse agonst on s)
Ka_vec(:,3) = ones(N,1) * 0.1;
alpha_t_vec(:,3) = ones(N,1) * 10;
alpha_a_vec(:,3) = ones(N,1) * 10;
alpha_at_vec(:,3) = ones(N,1) * 1e-2;

% G1 (binds strongly to s)
Kg_vec(:,1) = ones(N,1) * 10;
beta_t_vec(:,1) = ones(N,1) * 0.1;
beta_a_vec(:,1) = ones(N,1) * 10;
beta_at_vec(:,1) = ones(N,1) * 1;

% G2 (binds strongly to t)
Kg_vec(:,2) = ones(N,1) * 1;
beta_t_vec(:,2) = ones(N,1) * 10;
beta_a_vec(:,2) = ones(N,1) * 10;
beta_at_vec(:,2) = ones(N,1) * 100;

xxx = [...
    KactL_vec, ...
    KactG_vec, ...
    Gamma_vec, ...
    IC_R_vec, ...
    L_clamp_vec, ...
    IC_G_vec, ...
    Ka_vec, ...
    alpha_t_vec, ...
    alpha_a_vec, ...
    alpha_at_vec, ...
    Kg_vec, ...
    beta_t_vec, ...
    beta_a_vec, ...
    beta_at_vec, ...
    ];


rval = GPCR_QTC_fsel3x2Func([...
    KactL_vec, ...
    KactG_vec, ...
    Gamma_vec, ...
    IC_R_vec, ...
    L_clamp_vec, ...
    IC_G_vec, ...
    Ka_vec, ...
    alpha_t_vec, ...
    alpha_a_vec, ...
    alpha_at_vec, ...
    Kg_vec, ...
    beta_t_vec, ...
    beta_a_vec, ...
    beta_at_vec, ...
    ]);

p_Rax_G1 = rval(:,1);
p_Rax_G2 = rval(:,2);
p_Rix_G1 = rval(:,3);
p_Rix_G2 = rval(:,4);

rho_L1_on_G1 = p_Rax_G1(1:n);
rho_L1_on_G2 = p_Rax_G2(n+1:2*n);
rho_L2_on_G1 = p_Rax_G1(2*n+1:3*n);
rho_L2_on_G2 = p_Rax_G2(3*n+1:4*n);
rho_L3_on_G1 = p_Rax_G1(4*n+1:5*n);
rho_L3_on_G2 = p_Rax_G2(5*n+1:6*n);

figure(1); 
semilogx(L_vec, rho_L1_on_G1, '.-k'); hold on;
semilogx(L_vec, rho_L1_on_G2, 'x-k')
semilogx(L_vec, rho_L2_on_G1, '.-b')
semilogx(L_vec, rho_L2_on_G2, 'x-b')
semilogx(L_vec, rho_L3_on_G1, '.-g')
semilogx(L_vec, rho_L3_on_G2, 'x-g')
legend('rho\_L1\_on\_G1', 'rho\_L1\_on\_G2', 'rho\_L2\_on\_G1', 'rho\_L2\_on\_G2', 'rho\_L3\_on\_G1', 'rho\_L3\_on\_G2');
xlabel('L1, L2, or L3')
xlim([1e-4 1e3])
ylim([0 1])

