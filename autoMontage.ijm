/* A macro for making montage from a multi channel z-stack images. Supports 2,3 or 4 channel z-stacks 					 	 
 * Slices should be in a stack format and not in a hyperstack format
 * z-stacks are projected in z dimensions with average or maximum projection according to user's selection 					 
 * To smooth noise, an option to apply median filter is also provided, to skip applying the filter set its size to 0 (default) 
 * Also there is the option to subtract the background before making the montage												 
 * The user provides the appropriate rectange region only in the 1st image, next images should be croped with the same...      
 * region in order all montages have the same size. In addition the ROI is also saved in the save directory for later use      
 * To use a saved ROI, drag and drop the .roi file in ImageJ and run the macro afterwards. When prompted select the...	    
 * "keep" option.																												 
 * Scale bar is also added, so be carefull to enter the correct pixel-size. For a different font edit the "font=15" in line 204	
 * To stop running press ESC button when a dialog box is opened
 *												  										  
 * Created by Stylianos Didaskalou, for questions, updates, improvemnts, corrections ...										 
 * please contact me @ steliosdidaskalou@hotmail.com	
 * 
 * This macro is free to use, redistribut and/or modify it and it comes
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *  
 *  
 *  							** ENJOY**
 *  							
 *  							
 * Version Control						
 * Version 1: created by SD @ 10/02/2022
 */															 


macro "Montage" {

	//define parameters
	savedir = getDirectory("Select directory to save files");
	pixelsize = getNumber("What is the pixel size (um)?", 0.053);
	channels = getNumber("How many colors/channels? (2,3 or 4)" , 3);
	size = getNumber ("Set the size for the 'Median' filter (set to 0 for no filtering)" , 0);
	scaleSize = getNumber("Define the length of the scale bar (um) ", 5);
	
	selections = newArray("Average projection","Maximum Projection");
	Dialog.create("projection method");
    Dialog.addChoice("Choose a projection method", selections, "Maximum Projection");
	Dialog.show();
    projMethod = Dialog.getChoice();
  	keepBack= getBoolean("How would you like to treat the background?", "Keep", "Subtract");

	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	print("\\Clear");
	IJ.log("You have run this macro at "+dayOfMonth+ "/"+month+1+"/"+year+" at "+hour+":"+minute+":"+second);
	IJ.log("You have used the following settings");
	IJ.log("Saving Directory: " +savedir);
	IJ.log("Images have "+channels+ " color/channels");
	IJ.log("Size of 'Median' filter: " +size);
	IJ.log("Projection Method: "+projMethod);
	
	if (keepBack){
		bckRound = "No";
	}else {
		bckRound = "Yes";
	}
	IJ.log("Background substraction: "+bckRound);
	IJ.log("Macro created by Stylianos Didaskalou. For improvemnts and corrections please send an email @ steliosdidaskalou@hotmail.com");
	selectWindow("Log");
	saveAs("Text", savedir+"Log.txt");
	
	// close all,  clear results table and roi manager
	run("Close All");
	run("Clear Results");
	flag = true; // flag to create new roi
	roin = roiManager("count");
	if (roin > 0){
		keepROI= getBoolean("Selection found in  ROI manager. Continue or Delete it?", "Continue", "Delete"); // The option to delete it is in case a ROI exists in ROImanager for a previous, unrelated session.
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
	
	
	do { // repeat until user selects to stop (pressing ESC in a dialog terminates the macro)
	
	// check if is the 1st image, if yes prompt to select a rectabgle area,crop, save roi and continue,
	// else select the roi and continue
		if (flag) {
			setTool("rectangle");
			seltype = -1; // dummy to enter the while loop
			 while (seltype == -1){
				waitForUser("Open and image and select an area to crop");
				seltype = selectionType() ;
				if (seltype!=-1){
					roiManager("add");
					roiManager("save", savedir+"MontageRoi.roi"); // edit the MontageRoi to whatever name you want
					run("Crop");
					flag = false;
					settype = 1;
				}	
			}//while (selType == -1)
		 }//if (flag) 
		else {
			do {
			waitForUser("Open the next image");
			}while(nImages<1)
			imgTitle = getTitle();
			roiManager("select", 0);
			waitForUser("Move the selection area to crop");
			run("Crop");
		}//if(flag) else  

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
			if (projMethod == "Maximum Projection") {
				run("Z Project...", "projection=[Max Intensity]");
			}
			else { 
				run("Z Project...", "projection=[Average Intensity]");
			}
		}
		selectImage(1); // close the z-stacks image
		close();
		
		// set the scale properties
		selectImage(1);
		run("Properties...", "channels="+channels+" slices=1 frames=1 unit=um pixel_width="+pixelsize+" pixel_height="+pixelsize+" voxel_depth="+pixelsize+"");

		// prepare channels for montage
		Stack.setChannel(1);
		run("Blue");
		//resetMinAndMax();
		setMinAndMax(100, 10000);
		run("Apply LUT", "stack");
		
		Stack.setChannel(2);
		run("Green");
		//resetMinAndMax();
		setMinAndMax(100, 2000);
		run("Apply LUT", "stack");

		if (channels >= 3) { 
			Stack.setChannel(3);
			run("Magenta");	
			//resetMinAndMax();	
			setMinAndMax(200, 20000);	
			run("Apply LUT", "stack");
		}

		if (channels == 4) {
			Stack.setChannel(4);
			run("Magenta");
			resetMinAndMax();
		}

		// subtract background 
		if (keepBack == 0){
			Stack.setChannel(2); 
			setTool("oval");
			waitForUser("Select Background");
			roiManager("add");
			roiManager("select", 1);
			roiManager("multi measure");
			Background = getResult("Mean1", 1);
			roiManager("deselect");
			run("Select None");
			run("Subtract...", "value="+Background+ " slice");
			
			Stack.setChannel(1);
			Background = getResult("Mean1", 0);
			run("Select None");
			roiManager("Show None");
			run("Subtract...", "value="+Background+ " slice");

			if (channels >=3){
				Stack.setChannel(3);
				Background = getResult("Mean1", 2);
				run("Select None");
				run("Subtract...", "value="+Background+ " slice");
			}// if (channels >=3)

			if (channels == 4){
				Stack.setChannel(4);
				Background = getResult("Mean1", 3);
				run("Select None");
				run("Subtract...", "value="+Background+ " slice");
			}// if (channels >=3)
			
		run("Clear Results"); // clear results table
		roiManager("select", 1);
		roiManager("delete"); // clear the background area from the roimanager
		run("Select None");
		}// if (keepBack == 0)

		// organise images to make montage
		selectImage(1);
		rename("stack");
		run("Duplicate...", "title=RGB duplicate");
		selectImage("stack");
		run("Split Channels");
		selectWindow("RGB");
		run("Stack to RGB");
		selectWindow("RGB");
		close();
		selectWindow("RGB (RGB)");
		// add a scale bar 
		run("Scale Bar...", "width="+scaleSize+" height=4 font=30 color=White background=None location=[Lower Right] bold overlay");
		run("Flatten");
		selectWindow("RGB (RGB)");
		run("Close");

		// images to stack
		run("Images to Stack", "name=Stack title=[] use");
		nMontage = channels+1;
		run("Make Montage...", "columns="+nMontage+" rows=1 scale=1 border=1");
		
		saveAs("Tiff", savedir+imgTitle+"_Montage.tiff");
		run("Close All");
		
		
					
	}while(true)//do { // repeat until user selects to stop
	
	
}// macro "Montage"

