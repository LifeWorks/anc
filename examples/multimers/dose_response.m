% Description: Plot the saturation curve of tetramer defined in the models
%    multimer_MWC.mod,
%    multipler_KNF_[tetra|square|linear].mod,
%    multimer_TTS.mod, multimer_TTS_gem.mod

total_H = p_L0 + p_L1 + p_L2 + p_L3 + p_L4;

occupancy = (p_L1 + 2*p_L2 + 3*p_L3 + 4*p_L4)./total_H/4;

ss_occupancy = get_samples(event_times, t, occupancy);

ss_L = get_samples(event_times, t, L);

figure(1);

semilogx(ss_L,ss_occupancy,'.-')

figure(2);

plot(ss_L, ss_occupancy,'.-')

figure(3);

yym1 = ss_occupancy./(1-ss_occupancy);

plot(log10(ss_L), log10(yym1),'.-');


