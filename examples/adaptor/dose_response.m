% Description: Run this script to plot the dose-reponse
% of the model adaptor_generic.mod after it has been simulated.

ss_times = event_times(1:size(event_times,2));

ss_X = get_samples(ss_times,t,X);
ss_RESPONSE = get_samples(ss_times,t,RESPONSE);
figure(1);
semilogx(ss_X, ss_RESPONSE, '.-k')
hold on;
ylabel('[AY] + [XAY]');
xlabel('[X]')
xlim([1e-3 1e3])
ylim([0 1])

