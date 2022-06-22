/* 	A macro for making intensity plot profiles along a user-defined line.
 *  The macro supports z-stacks of 2,3 or 4 channels.
 *  The input image should be in a stack format and not in a hyper-stack format
 *  z-stacks in projected along z-dimension with Maximum or Average (default) projection according to user's selection
 *  Also there is the option to keep or to subtract the background signal for each channel and/or apply a median filter for smooting 
 *  out noise. The size of the filter is set by the user. For skipping this step use filter size of 0. 
 *  Default values are "Average projection", Filter size = 2 for a smooth plot profile.
 *  A .csv file with the plot profile results is saved, as well as a montage with the results for visualization.
 *  X-Value: X-axis values, Value1: intenisty profile of channel 1, Value2: Intensity values of channel 2, etc...
 *  The selected ROI is also saved in the 1st image, for further user, user can change this area afterwards but macro doesnt not save it.
 *  If user selects a length greater of 0 for the scale bar, a scale bar is also added in the RGB image on the montage. 
 *  This feature is added because the pixelsize value is limmited to 3 scientific digits after comma and rounds the value if more diggits are added.
 *  Thus, if some precission is needed, the user should select pixelsize = 1 and modify the X-value measurements afterwards in the .csv file.
 *  For pixelsize = 1 the scale bar would be wrong, thus choosing not to add a scale bar should be an option.
 *  To stop the macro press "ESC".
 *  
 *  written by Styliandos Didaskalou @ 13/02/2022. For any questions, suggestions or troubleshooting please contact me @ steliosdidaskalou@hotmail.com
 *  
 *  This macro is free to use, redistribut and/or modify it and it comes
 *  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *  
 *  
 *  							** ENJOY**
 *  							
 *  							
 * Version Control
 * Version 1: created by SD @ 13/02/2022
 * Version 1.1: modified by SD. fixed a bug where linescan ROIs didnt get deleted, leading to incorrect plot profiles in the next images. Version tested only in 3channel images but should work for 2 and 4 channels aswell @ 03/08/2022
 * Version 1.2: modified by SD. added the option to use only the middle z-stack for the linescan. The output .csv file have all three channes (tested only with 3) but the final montage shown only channel 3 (need to fix this) @ 21/06/2022
 */

macro "SpindleLineScans" {
	// get parameteres
	savedir = getDirectory("Select directory to save files");
	pixelsize = getNumber("What is the pixel size (um)?", 0.112);
	channels = getNumber("How many colors/channels? (2,3 or 4)" , 3);
	size = getNumber ("Set the size for the 'Median' filter (set to 0 for no filtering)" , 2);
	scaleSize = getNumber("Define the length of the scale bar (um) ", 20);
	selections = newArray("Average projection","Maximum Projection","Middle z-slice");
	Dialog.create("projection method");
    Dialog.addChoice("Choose a projection method", selections, "Average Projection");
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


	// main part of the code, run until user presses ESC
	do{
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
			else if (projMethod == "Average Projection") { 
				run("Z Project...", "projection=[Average Intensity]");
			}
			else {
				if(zSlices%2 == 0){
					middleZ = zSlices / 2;
				}
				else {
					middleZ = (zSlices + 1) /2 ;
				}
				IJ.log("Middle z-slice selected : "+middleZ);
				run("Duplicate...", "duplicate slices="+middleZ);
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
		resetMinAndMax();

		Stack.setChannel(2);
		run("Green");
		resetMinAndMax();

		if (channels >= 3) { 
			Stack.setChannel(3);
			run("Red");	
			resetMinAndMax();		
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



		// draw the line and add it to the roi 
		setTool("line");
		if(channels>=3){ // if channels is set to 3 or 4 draw the line the the 3rd channel (usually tub in our case) 
			Stack.setChannel(3);
		}else { // otherwise go to channel 2, channel 1 is usually dapi, if user wants something else can change the channels, draw line and go back to the previous channel to continue the macro
			Stack.setChannel(2);
		}
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
		run("Clear Results");
		// to save results
		for (c = 1; c <= channels; c++) {
			Stack.setChannel(c);
			roiManager("select", (c));
			profile = getProfile();
				for (i=0; i<profile.length; i++){
					if (c==1) {setResult("X-Cord", i, i*pixelsize);}
		 			setResult("Value"+c, i, profile[i]);
					updateResults();
				}
		}
		saveAs("Results", savedir+imgTitle+"_PlotProfiles.csv");

		// get the line profile graph
		selectImage(1);
		roiIndx = newArray(channels);
		for(i=0; i<roiIndx.length; i++){
			roiIndx[i] = i+1;
		}
		roiManager("Select",roiIndx);
		roiManager("Multi Plot");

		//prepare images for the montage
		// 1st row of the montage
		selectImage(1);
		rename("stack");
		selectImage("stack");
		run("Duplicate...", "title=RGB duplicate");
		selectImage("stack");
		run("Split Channels");
		selectWindow("RGB");
		run("Stack to RGB");
		selectWindow("RGB");
		close();
		selectWindow("RGB (RGB)");
		if(scaleSize>0){
		// add a scale bar to the RGB image
		run("Scale Bar...", "width="+scaleSize+" height=4 font=15 color=White background=None location=[Lower Right] bold overlay");
		run("Flatten");
		selectWindow("RGB (RGB)");
		run("Close");
		}

		//2nd row of the montage
		selectImage("C1-stack");
		roiManager("select", 1);
		run("Flatten");
		

		selectImage("C2-stack");
		roiManager("select", 2);
		run("Flatten");
		

		if(channels>=3){
			selectImage("C3-stack");
			roiManager("select", 3);
			run("Flatten");
			
		}
		if(channels==4){
			selectImage("C4-stack");
			roiManager("select", 4);
			run("Flatten");
			
		}


		selectImage("Profiles");
		run("Duplicate...", "title=Profile duplicate");
		selectImage("Profiles");
		run("Close");
		run("Images to Stack", "method=[Scale (smallest)] name=Stack title=[] use");
		run("Make Montage...", "columns="+channels+1+" rows=2 scale=1 border=1");
		saveAs("Tiff", savedir+imgTitle+"_Montage.tiff");
		run("Close All");
		
		// clear roi manager except the 1st roi that stores the area for croping
		n = roiManager("count");
		roiIndxs = newArray(n-1);
		for (i = 0; i < n-1 ; i++) {
			roiIndxs[i] = i + 1;
		}
		roiManager("select", roiIndxs);
		roiManager("delete");

	}while(true)
	







	
}
