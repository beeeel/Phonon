% scope metadata file version 0.3 March 2016
function scp=test_apt_apt_count_1_pistage0_pistage0_count0_scope0()
scp.version=0.3;
scp.hint=1e-08;
scp.hoff=1.32e-05;
scp.vgain=[1.2489e-06,6.2442e-06];
scp.voff=[0.0015998,0.0014986];
scp.points_per_trace=5000;
scp.n_traces=8820;
scp.n_channels=2;
scp.format=2;
scp.dataname='test_apt_apt_count_1_pistage0_pistage0_count0_scope0.dat';
% next line: n_averages meaning depends on scope and the multitrace capability, -1 means not implemented
scp.n_averages=1000;
% next line: multitraces=1 means off, -1 means undefined or not implemented, >1 is the number of traces
scp.multitraces=1000;
scp.channels={'F1','F3'};
