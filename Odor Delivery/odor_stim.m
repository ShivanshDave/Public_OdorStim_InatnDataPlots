function odor_stim(dur_ms)
%% Odor stim
st.nTreat = 'stim_right'; % 'stim_right' 'stim_left'
st.nTrials = 10;
st.trialBreak_sec = 15;

%% Run
run_dur_min = round(((st.trialBreak_sec)*(st.nTrials))/60,2); % 10p
fprintf('Strating... (Estimated Time: %.1f mins)\n',run_dur_min)

arduino_operate('start');
for i=1:st.nTrials
    fprintf('--Running Trial (%d/%d))\n',i,st.nTrials)
    arduino_operate(st.nTreat, st.trialBreak_sec, dur_ms);
end
arduino_operate('end');
fprintf('---END---\n')
end