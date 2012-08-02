function [ samples ] = get_samples(sampling_times, t, f_t )
% Function: get_samples
% Summary: Given a vector of times at which steady-state was reached,
% and state variable (f_t) sampled at the times given by (t), returns
% the values in f_t corresponding to the times at which a steady-state
% was reached.

for i=1:length(sampling_times)
    sampling_time = sampling_times(i);
    sampling_time_index = find(t==sampling_time);
    samples(i) = f_t(sampling_time_index);
end

end

