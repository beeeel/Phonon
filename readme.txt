Summary of analysis scripts for Phonon scanning data

batch_processing_v_1_6(filebase, run_no)
	- Function version of standard processing script used by Fernando and others
	- Processes dataset whos .con file is named filebase + run_no + .con
	- Returns whole data set as struct

show_hist(ax, directory, filenameRoot, start, lb, ub, opt, exclude)
	- Loads and processes data found in directory
	- Searches for files with names starting filenameRoot
	- excludes run_nos that match the string exclude (very hacky, don't trust it)
	- Fits gaussian mix model to data (more on that below)
	- Plots on axis given by ax
show_hist(ax, freqs, title, start, lb, ub, opt)
	- Fits gaussian mix model to frequency data in freqs
	- plots on axis given by ax
	- Both versions determine the number of gaussians to fit by the length of start
	- start, lb and ub must be matrices
	- opt is options struct created by statset
	- both methods return [freqs, fits, confs] - frequency data vector, fit value vector and 95% confidence interval vector

nocodazole_hists
	- Example of how to use show_hist
	- Plots frequency histograms for different datasets specified at the top
