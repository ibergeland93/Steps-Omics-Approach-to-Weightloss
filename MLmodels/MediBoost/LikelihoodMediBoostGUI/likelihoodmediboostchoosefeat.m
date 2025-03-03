function [fIdx,cutPoint,cutCategory] = likelihoodmediboostchoosefeat(x,y,catPredictors,funcValue,weights,colIdx)
% LIKELIHOODMEDIBOOSTCHOOSEFEAT - Selects a feature with maximum information
% gain and provides the decision values and column index for the chosen 
% feature
%
% Usage:
% 
% [fIdx,cutPoint,cutCategory] = LIKELIHOODMEDIBOOSTCHOOSEFEAT(x, y, catPredictors, funcValue, weights, colIdx)
%
%  inputs:
%   x               -   N x D matrix of N examples with D features
%   y               -   N x 1 vector of labels with values in {-1,1}
%   catPredictors   -   Logical vector with the same length as the feature
%                       vector, where a true entry means that the corresponding column of x is
%                       a categorical variable
%   funcValue       -   function of observation values
%   weights         -   distributions of observatios
%   colIdx          -   the indices of features (columns) under consideration
%
%  outputs:
%   fIdx            -   index of the feature with maximum information gain
%   cutPoint        -   decision value of feature with maximum information gain
%   cutCategory     -   decision value of category with maximum information gain
% 
% SEE ALSO
%   likelihoodmediboostdrawtree, likelihoodmediboostprunetree, likelihoodmediboosttrain, likelihoodmediboostvalue

%initializing the variables
cutPoint = []; 
cutCategory = {};

%Compute current Score
firstDer =  2.*y./(1 + exp(2.*y.*funcValue));

% Choosing the split by first creating a tree using the Matlab function
% fitrtree and checking if the split was on a categorical or 
% continuos variable
tree = fitrtree(x(:,colIdx),firstDer,'CategoricalPredictors',catPredictors(:,colIdx),'Weights',weights);

% Getting the feature where the split was made
fIdx = colIdx(strcmp(tree.PredictorNames,tree.CutVar{1}));

% Classifying the split as categorical or continous
if strcmp(tree.CutType{1},'continuous')
    cutPoint = tree.CutPoint(1);
else
   cutCategory = tree.CutCategories(1,:);
end