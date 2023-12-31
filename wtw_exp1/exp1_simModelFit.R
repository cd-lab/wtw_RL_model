simModelFit = function(encodeModel, decodeModel, isFirstFit, batchIdx = NULL, parallel = FALSE){
  # generate output directories
  dir.create("../../genData/wtw_exp1")
  dir.create("../../genData/wtw_exp1/simModelFit")
  dir.create("stanWarnings")
  dir.create(sprintf("../../genData/wtw_exp1/simModelFit/%s", encodeModel))
  dir.create(sprintf("../../genData/wtw_exp1/simModelFit/%s/%s", encodeModel, decodeModel))
  
  # load experiment parameters
  load("expParas.RData")
  
  # load sub-functions and packages
  library("dplyr"); library("tidyr")
  source("subFxs/loadFxs.R")
  source("subFxs/helpFxs.R")
  source('subFxs/modelFitGroup.R')
  source("exp1_expSchematics.R")
  
  # load simulation data 
  load(sprintf("../../genData/wtw_exp1/simulation/%s.RData", encodeModel))
  
  # prepare inputs
  outputDir = sprintf("../../genData/wtw_exp1/simModelFit/%s/%s", encodeModel, decodeModel)
  if(isFirstFit){
    config = list(
      nChain = 4,
      nIter = 8000,
      adapt_delta = 0.99,
      max_treedepth = 11,
      warningFile = sprintf("stanWarnings/sim_%s_%s.txt", encodeModel, decodeModel)
    )
    # divide data into small batches if batchIdx exists 
    if(!is.null(batchIdx)){
      if(batchIdx == 1){
        trialData = trialData[1 : 30]
      }else if(batchIdx == 2){
        trialData = trialData[31 : length(trialData)]
      }
    }
  }
  
  # if it is the first time to fit the model, fit all participants
  # otherwise, check model fitting results and refit those that fail any of the following criteria
  ## no divergent transitions 
  ## Rhat < 1.01 
  ## Effective Sample Size (ESS) > nChain * 100
  if(!isFirstFit){
    ids = names(trialData)
    paraNames = getParaNames(decodeModel)
    simPara = loadExpPara(paraNames, outputDir)
    passCheck = checkFit(paraNames, simPara)
    trialData = trialData[passCheck]
    
    # increase the num of Iterations 
    config = list(
      nChain = 4,
      nIter = 20000,
      adapt_delta = 0.99,
      max_treedepth = 11,
      warningFile = sprintf("stanWarnings/sim_refit_%s_%s.txt", encodeModel, decodeModel)
    )
  }
  
  # fit the model for all participants
  modelFitGroup(decodeModel, trialData, config, outputDir, parallel = parallel, isTrct = F)
}

if (sys.nframe() == 0){
  args = commandArgs(trailingOnly = T)
  simModelFit(args[1], args[2], as.logical(args[3]), as.numeric(args[4]))
}
