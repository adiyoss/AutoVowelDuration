# This script measures formants F1 and F2 every 10ms
# Written by Yossi Adi
# Contact adiyoss@cs.biu.ac.il
# ask a user the directories
###########################

##########  FORM  ##########
form supply_arguments
	sentence input_directory  /Users/adiyoss/Desktop/audio
	sentence output_directory /Users/adiyoss/Desktop/audio/results
	sentence type_file .wav
endform
###########################

#########READ FILES#########
writeInfo: ""
##### FINDING THE FILES WE LOOKING FOR #####
Create Strings as file list... list 'input_directory$'/*'type_file$'
###########################

####### GET THE NUMBER OF FILES ######
numberOfFiles = Get number of strings
appendInfoLine: numberOfFiles
###########################

#### LOOP OVER THE FILES ####
for ifile to numberOfFiles
	##### READ THE FILE AND PARSE IT #####
	select Strings list
	fileName$ = Get string... ifile
	Read from file... 'input_directory$'/'fileName$'
	appendInfoLine: fileName$
	s$ = replace$ (fileName$, type_file$, "", 0)
	select Sound 's$'
	###########################

	##### EXTRACT THE FORMATS #####
	To Formant (burg)... 0.01 5 5500 0.025 50
	###########################

	##### GET THE END TIME OF THE FILE #####
	fTime = Get finishing time
	###########################

	##### CALCULATE THE TIME FOR THE OUTPUT FILE #####
	numTimes = fTime / 0.01
	appendInfoLine: numTimes
	###########################

	##### CREATING THE TABLE #####
	Create Table... 's$' numTimes 2
	Set column label (index)... 1 formant_1
	Set column label (index)... 2 formant_2
	###########################

	##### LOOP OVER THE FILE IN 0.01 MILISEC #####
	for itime to numTimes		
		select Formant 's$'
		curtime = 0.01 * itime
		curtime$ = fixed$ (curtime, 5)
		
		##### EXTRACT F1 AND F2 #####
		f1 = Get value at time... 1 'curtime' Hertz Linear
		f1$ = fixed$ (f1, 2)
		if f1$ = "--undefined--"
			f1$ = "0"
		endif

		f2 = Get value at time... 2 'curtime' Hertz Linear
		f2$ = fixed$ (f2, 2)
		if f2$ = "--undefined--"
			f2$ = "0"
		endif
		###########################

		##### WRITE THE DATA TO THE TABLE #####
		select Table 's$'
		Set numeric value... itime formant_1 'f1$'
		Set numeric value... itime formant_2 'f2$' 
		###########################

	endfor

	##### WRITE THE TABLE TO .XLS FILE #####
	select Strings list
	fileName$ = Get string... ifile
	s$ = replace$ (fileName$, ".wav", "", 0)
	select Table 's$'
	Write to table file... 'output_directory$'/'s$'.csv
	###########################

endfor
###########################
