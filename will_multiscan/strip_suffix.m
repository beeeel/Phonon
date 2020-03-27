%[out, status] = strip_suffix(in, suffix);
%
%Strips a string of everything from the last instance of "suffix" onwards.
%
%"status" is a descriptive string, which will be one of:
%
%'0: Suffix stripped'
%'1: Suffix found and stripped. Other instance of suffix in string still exists'
%'2: Suffix not found, returning string unchanged'
%
%For example:
%  in = 'test.mat', suffix = '.mat'	: out = 'test',   status = '0:...'
%  in = 'test.2.m', suffix = '.'	: out = 'test.2', status = '1:...'
%  in = 'test_2',   suffix = '.wf'	: out = 'test_2', status = '2:...'

function [out, status] = strip_suffix(in, suffix);

f = findstr(in, suffix);

if isempty(f)
	out = in;
	status = '2: Suffix not found, returning string unchanged';
else
	out = in(1:max(f)-1);
	if length(f) > 1
		status = '1: Suffix found and stripped. Other instance of suffix in string still exists';
	else
		status = '0: Suffix stripped';
	end
end

