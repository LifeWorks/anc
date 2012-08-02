% run this script to plot the dose_reponse sim of GPCR_QTC.mod

ss_times = event_times(1:size(event_times,2));

ss_L = get_samples(ss_times,t,L);
ss_p_Rax_G = get_samples(ss_times,t,p_Rax_G);
ss_p_Rix_G = get_samples(ss_times,t,p_Rix_G);
figure(1);
semilogx(ss_L, ss_p_Rax_G, '.-k')
hold on;
semilogx(ss_L, ss_p_Rix_G, '.-b')
legend('p\_Rax\_G', 'p\_Rix\_G');
xlabel('L')
xlim([1e-4 1e2])
ylim([0 1])

