function node = likelihoodmediboosttrain(x,y,catPredictors,depthLimit,learningRate,A)
% LIKELIHOODMEDIBOOSTTRAIN - Trains a binary decision tree classifier under the
% MediBoost paradigm. For more information see:
%
% VALDES Gilmer, LUNA José, EATON Eric, UNGAR Lyle, SIMONE Charles 
% and SOLDBERG Timothy. MediBoost: a Patient Stratification Tool for 
% Interpretable Decision Making in the Era of Precision Medicine. Under 
% Review. 2016.
%
%   node = LIKELIHOODMEDIBOOSTTRAIN(x, y, depthLimit, learningRate, A)
%
%  inputs:
%   x               -   N x D matrix of N examples with D features
%   y               -   N x 1 vector of labels with values in {-1,1}
%   catPredictors   -   Logical vector with the same length as the feature
%                       vector, where a true entry means that the corresponding column of x is
%                       a categorical variable
%   depthLimit      -   maximum depth of the tree
%   learningRate    -   learning rate for the Newton Raphson step that
%                       updates the function values of the node
%   A               -   acceleration factor
%
% Returns a linked hierarchy of structs with the following fields:
%
%   node.terminal               -   Logical variable that indicates whether or not this 
%                                   node is a terminal (leaf) node
%   node.fIdx, node.cutPoint    -   variables used to carry out the feature 
%   node.cutCategory                based tests associated with this node.
%                                   If the features are continuous then the
%                                   test is (is x(fIdx) > cutPoint?) if
%                                   the features are categorical the test is
%                                   (is x(fIdx) in cutCategory{2}?) 
%   node.weights                -   Double variable that stores the weight of each 
%                                   observation for each node
%   node.obsValues              -   Double variable that stores the current
%                                   observations in the node
%   node.value                  -   Double variable that stores the summation of all 
%                                   weights of the parent nodes and the current node
%   node.left                   -   Struct of the child node on left branch (f <= value)
%   node.right                  -   Struct of the child node on right branch (f > value)
% 
% SEE ALSO
%   likelihoodmediboostchoosefeat, likelihoodmediboostdrawtree, likelihoodmediboostprunetree, likelihoodmediboostvalue

    % Initial distribution values
    weights = ones(numel(y),1);

    % Initial probabilities
    probability = weights./ numel(y);

    % Initial node values
    nodeValue = log(1 + probability'*y) - log(1 - probability'*y) ;

    % Initial observations
    obsValues = ones(numel(y),1).*(log(1 + probability'*y) - log(1 - probability'*y));

    % Recursive function to build tree
    node = likelihoodmediboostsplitnode(x,y,weights,catPredictors,obsValues,nodeValue,1:size(x,2),0,depthLimit,learningRate,A);
end

function node = likelihoodmediboostsplitnode(x,y,weights,catPredictors,obsValues,nodeValue,colIdx,depth,depthLimit,learningRate,A)
% LIKELIHOODMEDIBOOSTSPLITNODE - Recursive function that returns a node structure under
% the MediBoost paradigm. For more information see:
%
% VALDES Gilmer, LUNA José, EATON Eric, UNGAR Lyle, SIMONE Charles 
% and SOLDBERG Timothy. MediBoost: a Patient Stratification Tool for 
% Interpretable Decision Making in the Era of Precision Medicine. Under 
% Review. 2016.
%    
% node = LIKELIHOODMEDIBOOSTSPLITNODE(x, y, xRange, weights, catPredictors, obsValues, nodeValue, colIdx, depth, depthLimit, learningRate, A)
%  
%  inputs: 
%   x               -   N x D matrix of N examples with D features
%   y               -   N x 1 vector of labels with values in {-1,1}
%   xRange          -   cell array containing the range of values for each feature
%   weights         -   Double variable that stores the weight of each 
%                       observation for each node
%   catPredictors   -   Logical vector with the same length as the feature
%                       vector, where a true entry means that the corresponding column of x is
%                       a categorical variable
%   obsValues       -   Double vector containing the current observations        
%   nodeValue       -   the default value of the node if y is empty
%   colIdx          -   the indices of features (columns) under consideration
%   depth           -   current depth of the tree
%   depthLimit      -   maximum depth of the tree
%   learningRate    -   learning rate for the Newton Raphson step that
%                       updates the function values of the node
%   A               -   acceleration factor
%
% Returns a linked hierarchy of structs with the following fields:
%
%   node.terminal               -   Logical variable that indicates whether or not this 
%                                   node is a terminal (leaf) node
%   node.fIdx, node.cutPoint    -   variables used to carry out the feature 
%   node.cutCategory                based tests associated with this node.
%                                   If the features are continuous then the
%                                   test is (is x(fIdx) > cutPoint?) if
%                                   the features are categorical the test is
%                                   (is x(fIdx) in cutCategory{2}?) 
%   node.weights                -   Double variable that stores the weight of each 
%                                   observation for each node
%   node.obsValues              -   Double variable that stores the current
%                                   observations in the node
%   node.value                  -   Double variable that stores the summation of all 
%                                   weights of the parent nodes and the current node
%   node.left                   -   Struct of the child node on left branch (f <= value)
%   node.right                  -   Struct of the child node on right branch (f > value)
%   node.maxig                  -   Double variable containing the information gain
%                                   associated with this node

    %Initializing the node with default values
    node.terminal = true;
    node.fIdx = [];
    node.cutPoint = [];
    node.cutCategory = {};
    node.weights = weights;
    node.obsValues = obsValues;
    node.value = nodeValue;
    node.left = [];
    node.right = [];
    
    % Evaluating if the depth limit has been reached
    if depth < depthLimit

        % Indicating that the structure is not a leaf
        node.terminal = false;

        % Choosing a feature to split on using regression of the first derivative of the loss function.
        [node.fIdx, node.cutPoint, node.cutCategory] = likelihoodmediboostchoosefeat(x,y,catPredictors,node.obsValues,node.weights,colIdx);    

        if ~isempty(node.cutPoint) || ~isempty(node.cutCategory)
            %declaring the node no terminal
            node.terminal = false;
            
            %Split the data based on this feature.
            if ~isempty(node.cutPoint)
                leftIdx = x(:,node.fIdx) < node.cutPoint;
                rightIdx = x(:,node.fIdx) >= node.cutPoint;
            else
                leftIdx = ismember(x(:,node.fIdx),node.cutCategory{1,1});
                rightIdx = ismember(x(:,node.fIdx),node.cutCategory{1,2});
            end

            % Calculating the observations, weights and node coefficients
            % Calculating left weights and outputs
            leftY = y(leftIdx);
            leftWeight = weights(leftIdx);
            % Calculating right weights and outputs
            rightY = y(rightIdx);
            rightWeight = weights(rightIdx);

            % Calculating the current value of the function for right and left
            % node
            funcValueLeft = node.obsValues(leftIdx);
            funcValueRight = node.obsValues(rightIdx);

            % Computing the coefficients of the left child node
            firstDerLeft = -2.*leftY./(1+exp(2.*leftY.*funcValueLeft));
            weightedFirstDerLeft =  leftWeight'* firstDerLeft;            
            secDerLeft = abs(firstDerLeft).*( 2 - abs(firstDerLeft));
            weightedSecDerLeft = leftWeight'* secDerLeft;           

            % Using exp(log(a)-log(b)) = a/b to avoid singularity errors in
            % the gradient step when the weights become close to zero 
            nodeValueLeft = node.value - real(exp(log(learningRate*(weightedFirstDerLeft))-log(weightedSecDerLeft)));
            observValuesLeft = funcValueLeft - real(exp(log(learningRate*(weightedFirstDerLeft))-log(weightedSecDerLeft)));

            % Computing the coefficients for the right child node
            firstDerRight = -2.*rightY./(1+exp(2.*rightY.*funcValueRight));
            weightedFirstDerRight =  rightWeight'* firstDerRight;            
            secDerRight = abs(firstDerRight).*(2 - abs(firstDerRight));
            weightedSecDerRight = rightWeight'*secDerRight;           

            % Using exp(log(a)-log(b)) = a/b to avoid singularity errors in
            % the gradient step when the weights become close to zero 
            nodeValueRight = node.value - real(exp(log(learningRate*(weightedFirstDerRight))-log(weightedSecDerRight)));
            observValuesRight = funcValueRight - real(exp(log(learningRate*(weightedFirstDerRight))-log(weightedSecDerRight)));

            % Updating the observation values at this depth
            newObservValue = node.obsValues;        
            newObservValue(leftIdx)=observValuesLeft;
            newObservValue(rightIdx)=observValuesRight;

            % Indicator function that assigns 1 to the samples in the left 
            % branch and -1 to the remaining ones
            leftRule = y;
            leftRule(leftIdx) = 1; 
            leftRule(rightIdx) = -1;

            % Indicator function that assigns 1 to the samples in the right
            % branch and -1 to the remaining ones
            rightRule = y;
            rightRule(leftIdx) = -1;
            rightRule(rightIdx) = 1;

            % Updating the weights
            leftWeights = node.weights.*( exp((leftRule-1).*A./2)./(exp((leftRule-1).*A./2) + exp((rightRule-1).*A./2) ));                          
            rightWeights = node.weights.*(exp((rightRule-1).* A./2)./(exp((leftRule-1).*A./2) + exp((rightRule-1).*A./2)));


            %normalizing the new weights to the total summation of weights
            leftWeights = leftWeights./sum(leftWeights);
            rightWeights = rightWeights./sum(rightWeights);

            %Creating the right and left terminal nodes
            if ~isinf(nodeValueRight) && ~isinf(nodeValueLeft) && ~isnan(nodeValueRight) && ~isnan(nodeValueLeft)
                node.right = likelihoodmediboostsplitnode(x,y,rightWeights,catPredictors,newObservValue,nodeValueRight,1:size(x,2),depth+1,depthLimit,learningRate,A);
                node.left = likelihoodmediboostsplitnode(x,y,leftWeights,catPredictors,newObservValue,nodeValueLeft,1:size(x,2),depth+1,depthLimit,learningRate,A);
            else
                node.terminal = true;
            end
        end
    else
        return;
    end
end