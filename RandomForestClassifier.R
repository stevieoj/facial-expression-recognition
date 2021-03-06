# Copyright (C) 2015 Rustem Bekmukhametov
# This program is free software: you can redistribute it and/or modify it under the terms of the 
# GNU General Public License as published by the Free Software Foundation, either version 3 of the 
# License, or (at your option) any later version.

library(randomForest)

## Custom implementation of a simple Random Forest, based on rpart package's decision tree
## @formula parameter is used to specify labels & features 

initForest2 <- function(trainingSet, formula = NULL, treesNum = 10) {
    # Training phase
    folds  <- cvFolds(nrow(trainingSet), K = treesNum)
    forest <- list()
    
    for(i in 1:treesNum) {
        train <- trainingSet[folds$subsets[folds$which != i], ]
        tree <- fitDTClassifier(train, formula) # rpart(emotion ~ ., method="class", data=train, control=rpart.control(minsplit=1, cp=0.006147)) 
        if (i == 1) {
            forest <- list(tree)
        } else {
            forest <- c(forest, list(tree))
        }
    }
    
    forest.predictOne <- function(entry) {
        votes <- c(0, 0, 0, 0, 0, 0, 0)
        
        for (treeId in 1:length(forest)) {
            assumptions <- predict(forest[[treeId]], entry)
            votes <- votes + assumptions
        }
        
        # Identifying the elected winner
        max      <- -1
        winnerId <-  1
        voteId   <-  1  
        
        for (vote in votes) {
            if (vote > max) {
                max <- vote
                winnerId <- voteId
            }
            voteId <- voteId + 1
        }
        winnerId
    }
    
    forest.predict <- function(testSet) {
        predictions <- c()
        for (testId in 1:nrow(testSet)) {
            class <- forest.predictOne(testSet[testId, ])
            predictions <- c(predictions, class)
        }
        predictions
    }
    
    forest.hitsNum <- function(testSet, trueLabels) {
        predictions <- test(testSet)
        hits <- predictions == trueLabels
        hitsNum <- sum(hits)
        hitsNum
    }
    
    forest.crossValidation <- function(dataSet = trainingSet, K = 10) {
        crossValidation(dataSet, classifierType = "random_forest2", K)
    }
    
    ## Returns a list representation of the object with methods and properties accessed through indexed keys
    list(classifier = forest, predict = forest.predict, hitsNum = forest.hitsNum, crossValidation = forest.crossValidation)
}  

## Random Forest implementation based on the randomForest package.
## @formula parameter is used to specify labels & features

initForest <- function(trainingSet, formula = NULL, treesNum = 200) {
    # Training phase
    if (is.null(formula)) {
        formula <- emotion ~ . #X1+X11+X18+X43+X52+X87+X89+X91+X92+X101+X102+X117+X118+X120+X123+X125
    }
    priors <- c(0.13761468, 0.05504587, 0.18042813, 0.07645260, 0.21100917, 0.08562691, 0.25382263)
    forest <- randomForest(formula, 
                           ntree = treesNum
                           corr.bias = TRUE, 
                           data = dataSet, 
                           importance = TRUE,
                           # strata = factor(dataSet[,137]),                           
                           # classwt = priors, 
                           # mtry = 45,
                           # proximity = TRUE,
                           # maxnodes = 15, 
                           # nodesize = 10
                           ) 
    
    forest.predict <- function(entry) {
        predict(forest, entry)
    }
    
    forest.hitsNum <- function(inputs, trueLabels) {
        hitsNum <- 0
        labels <- c(8)
        pred <-  predict(forest, inputs[, 1:136])
        for (resultInd in 1: length(pred)) {
            result <- pred[resultInd]
            labels <- c(labels, result)
            
            if (round(result) == trueLabels[resultInd]) {
                hitsNum <- hitsNum + 1
            } 
        }
        hitsNum
    }
    
    forest.crossValidation <- function(dataSet, K = 10) {
        crossValidation(dataSet, classifierType = "random_forest", K)
    }
    
    ## Returns a list representation of the object with methods and properties accessed through indexed keys
    list(classifier = forest, predict = forest.predict, hitsNum = forest.hitsNum, crossValidation = forest.crossValidation)
}
