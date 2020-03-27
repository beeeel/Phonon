% scope metadata file version 0.3 March 2016
function scp=test_fibre_air_2_count0_scope0()
scp.version=0.3;
scp.hint=1e-08;
scp.hoff=-4.42e-05;
scp.vgain=[2.4977e-06];
scp.voff=[-0];
scp.points_per_trace=10000;
scp.n_traces=50;
scp.n_channels=1;
scp.format=2;
scp.dataname='test_fibre_air_2_count0_scope0.dat';
% next line: n_averages meaning depends on scope and the multitrace capability, -1 means not implemented
scp.n_averages=10000;
% next line: multitraces=1 means off, -1 means undefined or not implemented, >1 is the number of traces
scp.multitraces=1000;
scp.channels={'F1'};
