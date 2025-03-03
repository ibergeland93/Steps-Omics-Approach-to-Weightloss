MediBoost Decision Trees

==============



Matlab scripts that demonstrate how to build a tree under the MediBoost 

paradigm. For more information please see:

 

VALDES Gilmer, LUNA José, EATON Eric, UNGAR Lyle, SIMONE Charles 
and SOLDBERG Timothy. MediBoost: a Patient Stratification Tool for 
Interpretable Decision Making in the Era of Precision Medicine. Under 
Review. 2016.

 

Usage:

    Open the script likelihoodmediboostmain and provide the dataset file DATA.MAT, the 
    depth of the tree DEPTH_LIMIT, the value of the accelerator factor A, the 
    learning rate for the update of the function values of the nodes LEARNINGRATE and

    the categorical predictor vector CATPREDICTORS. Then, in the Command Window type:

		likelihoodmediboostmain

	to run the demonstration script.