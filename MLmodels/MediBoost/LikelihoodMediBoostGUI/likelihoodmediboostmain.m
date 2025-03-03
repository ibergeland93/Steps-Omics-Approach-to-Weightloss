function likelihoodmediboostmain(depthLimit,A,learningRate,porTrain,dataset)

% Matlab script that demonstrates how to build a tree under the MediBoost 
% paradigm. For more information please see:
%
% VALDES Gilmer, LUNA José, EATON Eric, UNGAR Lyle, SIMONE Charles 
% and SOLDBERG Timothy. MediBoost: a Patient Stratification Tool for 
% Interpretable Decision Making in the Era of Precision Medicine. Under 
% Review. 2016.
%
% Usage:
%   Open the script likelihoodmediboostmain and provide the dataset file DATA.MAT, the 
%   depth of the tree DEPTH_LIMIT, the value of the accelerator factor A, the 
%   learning rate for the update of the function values of the nodes LEARNINGRATE and
%   the categorical predictor vector CATPREDICTORS. Then, in the Command Window type:
% 		mediboostmain
% 	to run the demonstration script.
%
% SEE ALSO
%   likelihoodmediboostchoosefeat, likelihoodmediboostdrawtree, likelihoodmediboostprunetree, likelihoodmediboosttrain,
%   likelihoodmediboostvalue

%% Setting parameters and loading training data
% Loading Breast Cancer Wisconsin data set from uci (http://archive.ics.uci.edu/ml/)
load(dataset);

% The catPredictors vector should be true in the entries corresponding to a
% categorical feature
catPredictors = logical(false(1,size(x,2)));

n = size(x,1);
sel = randperm(size(x,1));
xTrain = x(sel(1:round(n*porTrain)),:);
yTrain = y(sel(1:round(n*porTrain)));

%% Training the tree using the Mediboost paradigm
tree = likelihoodmediboosttrain(xTrain,yTrain,catPredictors,depthLimit,learningRate,A);

% Script for pruning the tree based on the elimination of child nodes 
% whose classification outputs are the same, as well as impossible paths
prevDec = {};
tree = likelihoodmediboostprunetree(tree,prevDec);

% Script for drawing the obtained Mediboost tree in a matlab figure
likelihoodmediboostdrawtree(tree,dataset)

%% Testing the tree

% Defining the testing data. We are selecting half the available data
xTest = x(sel(round(n/2)+1:end),:);
yTest = y(sel(round(n/2)+1:end));

%Calculating the Predicted Y for the testing set
yPredTrain = likelihoodmediboostvalue(tree, xTrain);
yPredTest = likelihoodmediboostvalue(tree, xTest);

% Calculating the classification error
errorTrain = sum(yPredTrain ~= yTrain)./numel(yTrain);
errorTest = sum(yPredTest ~= yTest)./numel(yTest);
clc
display(['Classification error for training: ' num2str(errorTrain*100) ' %']);
display(['Classification error for testing: ' num2str(errorTest*100) ' %']);