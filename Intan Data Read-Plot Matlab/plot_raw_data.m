function plot_raw_data(data)
% Access this from "read_raw_data"

figure
fprintf('Plotting data from %s \n', data.info.path);
t = tiledlayout(3,1,'TileSpacing','Compact', ...
    'Padding', 'Compact');
xlabel(t,'Time (sec)')
% title(t,'EAG with two-odors')
title(t,['EAG EXP -- ' data.info.notes.note1 ]);

ax1 = nexttile(t,[1 1]); hold on;
if isfield(data, 'EnSig'); plot(data.time, data.EnSig, ':'); end
if isfield(data, 'LSig'); plot(data.time, data.LSig, ':'); end
if isfield(data, 'RSig'); plot(data.time, data.RSig, ':'); end
ylim([-0.2 1.2])
ylabel('Stimulus')
% legend({'Enable','OdorA_L','OdorB_R'});

ax2 = nexttile(t,[2 1]);
plot(data.time, data.amp1_uV/1000); % Check?
ylabel('Ampl (mV)')
y = ylim;
ylim([y(1)*1.2 y(2)*1.2])

linkaxes([ax1 ax2],'x')
% saveas(gcf,['../_local/f_' data.info.notes.note1 '.fig']);
% saveas(gcf,['../_local/f_' data.info.notes.note1 '.png']);
shg