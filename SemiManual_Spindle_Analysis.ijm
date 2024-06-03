
macro "SpindleLineScans" {
	// get parameteres
	savedir = getDirectory("Select directory to save files");
	pixelsize = getNumber("What is the pixel size (um)?", 0.053);
	channels = getNumber("How many colors/channels? (2,3 or 4)" , 3);
	size = getNumber ("Set the size for the 'Median' filter (set to 0 for no filtering)" , 0);
	scaleSize = getNumber("Define the length of the scale bar (um) ", 5);
	lineWidth = getNumber("Select the width of the line in the linescan (Just for metadata purposes need to adjust it manual)", 60);
	//selections = newArray("Average projection","Maximum Projection","Middle z-slice");
	//Dialog.create("projection method");
    //Dialog.addChoice("Choose a projection method", selections, "Average Projection");
	//Dialog.show();
    //projMethod = Dialog.getChoice(); 
   	projMethod = "Average Projection"; // For analysis meta data
    //keepBack= getBoolean("How would you like to treat the background?", "Keep", "Subtract");
  	//intensityMeasure = getBoolean("Would you like to measure Intensities?");
  	//saveCroped = getBoolean("Would you like to save the croped Image aswell?");
  	//lineScans = getBoolean("Would you like to create the LineScans?");
  	lineScans = true;
  	intensityMeasure = true;
  	
  	if(intensityMeasure){
  		channelMask = getNumber("Select the channel to create the mask" , 3);
  	}
  
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	print("\\Clear");
	IJ.log("You have run this macro at "+dayOfMonth+ "/"+month+1+"/"+year+" at "+hour+":"+minute+":"+second);
	IJ.log("You have used the following settings");
	IJ.log("Saving Directory: " +savedir);
	IJ.log("Images have "+channels+ " color/channels");
	IJ.log("Size of 'Median' filter: " +size);
	IJ.log("Projection Method: "+projMethod);
	
	bckRound = "Yes";
	intMeas = "Yes";

	IJ.log("Background substraction: "+bckRound);
	IJ.log("Selected to measure intenisties inside a ROI: "+intMeas);
	
	IJ.log("Width of line for the linescan was set to: "+lineWidth+" pixels");
	IJ.log("Macro created by Stylianos Didaskalou. For improvemnts and corrections please send an email @ steliosdidaskalou@hotmail.com");
	selectWindow("Log");
	saveAs("Text", savedir+"Log.txt");

	
	
	


	// main part of the code, run until user presses ESC
	do{
		Clearing();// close all,  clear results table and roi manager
		
		open();
		imgTitle = getTitle();
		
		// from stack to hyperstack
		slices = nSlices;
		zSlices = slices/channels;
		run("Stack to Hyperstack...", "order=xyczt(default) channels="+channels+" slices="+zSlices+" frames=1 display=Composite");
		
		// apply median if selected so
		if (size > 0) {
			run("Median...", "radius="+size);
		}

		// do the projection
		if (zSlices > 1) {
		run("Z Project...", "projection=[Average Intensity]");
		selectImage(1); // close the z-stacks image
		close();
		}
			
		// set the scale properties
		selectImage(1);
		run("Properties...", "channels="+channels+" slices=1 frames=1 unit=um pixel_width="+pixelsize+" pixel_height="+pixelsize+" voxel_depth="+pixelsize+"");

		// prepare channels for montage
		Stack.setChannel(1);
		run("Blue");
		resetMinAndMax();

		Stack.setChannel(2);
		run("Green");
		resetMinAndMax();

		if (channels >= 3) { 
			Stack.setChannel(3);
			run("Magenta");	
			resetMinAndMax();		
			}

		if (channels == 4) {
			Stack.setChannel(4);
			run("Magenta");
			resetMinAndMax();
			}
			
		// Start creating the ROIs
		// ROI out of the cell
		setTool("rectangle");
		run("Set Measurements...", "area mean redirect=None decimal=3");
		waitForUser("Select an area away from the cell");
		roiManager("add");
		roiManager("select", 0);
		roiManager("multi-measure measure_all append");
		roiManager("select", 0);
		roiManager("Delete");
		run("Select None");
		
		// Subtract background
		Stack.setChannel(1);
		Background = getResult("Mean", 0);
		run("Subtract...", "value="+Background+ " slice");

		Stack.setChannel(2);
		Background = getResult("Mean", 1);
		run("Subtract...", "value="+Background+ " slice");

		Stack.setChannel(3);
		Background = getResult("Mean", 2);
		run("Subtract...", "value="+Background+ " slice");

		run("Clear Results");
		
		// ROI on the cytoplasm
		waitForUser("Select an area on the cytoplasm");
		roiManager("add");
		roiManager("select", 0);
		roiManager("multi-measure measure_all append");
		roiManager("select", 0);
		roiManager("Delete");
		
		// ROI on the Spindle
		setTool("ellipse");
		run("Set Measurements...", "area mean min fit redirect=None decimal=3");
		waitForUser("Select spindle");
		roiManager("add");
		roiManager("select", 0);
		roiManager("multi-measure measure_all append");
		roiManager("select", 0);
		roiManager("Delete");
		
		saveAs("Results", savedir+imgTitle+"_IntensityMeasurments.csv");
		run("Clear Results");
		
		// Create the lineScan
		// draw the line and add it to the roi 
		setTool("line");
		waitForUser("draw a line from pole to pole");
		Roi.setPosition(1);
		roiManager("add");
		Roi.setPosition(2);
		roiManager("add");
		if(channels >=3){
		Roi.setPosition(3);
		roiManager("add");
		}
		if(channels==4){
			Roi.setPosition(4);
			roiManager("add");
		}
	
		// get the profile for each channel and append it to the results table
		selectImage(1);
		
		// to save results
		for (c = 1; c <= channels; c++) {
			Stack.setChannel(c);
			roiManager("select", (c-1));
			profile = getProfile();
				for (i=0; i<profile.length; i++){
					if (c==1) {setResult("X-Cord", i, i*pixelsize);}
						setResult("Value"+c, i, profile[i]);
						updateResults();
						}
						}
		saveAs("Results", savedir+imgTitle+"_PlotProfiles.csv");


	}while(true)
	

	
}



function Clearing() { 
// closes all images / results tables and clears all ROIs

run("Close All");
	run("Clear Results");
	flag = true; // flag to create new roi
	roin = roiManager("count");
	if (roin > 0){
		//keepROI= getBoolean("Selection found in  ROI manager. Continue or Delete it?", "Continue", "Delete"); // The option to delete it is in case a ROI exists in ROImanager for a previous, unrelated session.
		keepROI = 0;
		if(keepROI == 0){
			roiManager("show none");
			roiManager("deselect");
			roiManager("delete");
			flag = true; 
		}
		else{
			flag = false;
		}
	}
}