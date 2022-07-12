% Understanding Growth-at-Risk: A Markov-Switching Approach
% Model with f_t and m_t endogenous
%
% This script produces posterior mode estimates and predictive
% densities at the posterior mode for any dataset.
%
% There are two estimation optionns
%  1. Direct: estimates the measurement equation at horizon hh.
%  2. Iterated: estimates the contemporanous measurement equation and
%     then iterates the predictive density through horizon hh.
%=====================================================================

%  AUG 16, 2012 CHANGE: GDP is not t to t+11 instead of t+1 to t+12

%% housekeeping
% clear; clc; tic;
% close all;

% Important paths
if ~isdeployed
    addpath('/if/gms_research_gar/GAR/MS-VAR/RISE_toolbox'); % RISE Toolbox
    addpath(genpath('functions'));      % Main functions
    addpath(genpath('scripts'));        % Main scripts
    addpath(genpath('textools'));       % Tools to produce tables
    addpath(genpath('auxtools'));       % Tools for plotting and other
    addpath(genpath('cbrewer'));        % Color mixing tools
else
    i = str2num(i); % Comes from the SLURM loop
end

% Load RISE
rise_startup()

% Date formats
inputformat   = 'yyyy-MMM';
dataformat    = 'yyyy-mmm';

%========================================
% USER INPUT
%========================================
opt.dir_or_it      = 1;     % 1 = direct, 2 = iterated
opt.hh             = 12;    % forecast horizon
opt.optimizer      = 1;     % 1 = fminunc, 0 or not specified = fmincon
opt.transprob      = 0;     
% 1 = endogenous, otherwise exogenous (activates 'drawst' option for 
% simulation of densities, opt.const cannot be 0, target_date cannot be
% beyond end of estimation sample, for now)
opt.simul          = 0;     % 1 = RISE forecast, 0 = our simulation function
opt.simtype        = 1;     % 1 = forecast, 0 = drawst
opt.const          = 1;     % 1 = have a constant in transition probability
opt.normal         = 0;     % 1 = use normal distribution, 0 = gamma distribution
opt.paramsUse      = 'mode';
opt.force_estimate = 1;     % 1 = force to reestimate model
opt.printsol       = 1;     % 1 = print model solution


% Simulation options
opt.nDraws       = 5000;    % Number of simulations for each time period
opt.nParamDraws  = 1000;    % Draws from posterior. has to be less than options.N;

% MCMC options
options = struct();
options.alpha = 0.234;
options.thin = 10;
options.burnin = 10^3;
options.N = 2*10^4;
% options.thin = 1;
% options.burnin = 0;
% options.N = 200;
options.nchain = 1;

% VAR configuration
% important: if nlags>1 the routine that pulls the parameters
% (scriptParams_FULL_companion.m) does not work for MCMC
opt.nlags=1;
nlags=opt.nlags;
exog={};
constant=true;
panel=[];

% Select which models to run
% mymodels = [1 13];
% mymodels = [2 11];
% mymodels = [4 12];
mymodels = [11];


efirst = 'dec 01 1999';
esample = 'oct 01 2020';
maxwin = months(efirst,esample);
efirstok = datestr(efirst,dataformat);

for i=1:maxwin
    for imodel=mymodels
        tic;
        modelspec = imodel;

        % Model spectag
        if opt.transprob==1
            tag ='';
        else
            tag ='_EXO';
        end
        spectag = fSpecLabel(modelspec);
                    
        % Data vintage, sample and country selection
        datafilename = '11302020';
        sheetuse     = 'US_DFM';
        start_date   = '1973-Jan';
        end_date     = datestr(datenum(datetime(efirstok,'InputFormat',inputformat)+calmonths(i)),dataformat);

        out_print = ['Performing iteration ending on ' end_date ' of model ' num2str(modelspec) ];
        disp(out_print);

        % Define target periods for density cuts
        target_dates = datenum(datetime(end_date,'InputFormat',inputformat));

        %========================================
        % MODEL SPECIFIC VARIABLES
        %========================================

        foldertag = 'OOS';

        if opt.dir_or_it ==1
            fcstype= 'direct';
            varlist={'FF','MF','GDPGH'}';
            % Folders
            paramsfolder = ['results/Params/' opt.paramsUse '/Full/Direct/VAR' num2str(nlags)  '/' foldertag '/' ];
            IS_paramsfolder = ['results/Params/' opt.paramsUse '/Full/Direct/VAR' num2str(nlags)  '/' ];

        elseif opt.dir_or_it ==2
            fcstype= 'iterated';
            varlist={'FF','MF','GDPG'}';
            % Folders
            paramsfolder = ['results/Params/' opt.paramsUse '/Full/Iterated/VAR' num2str(nlags) '/' foldertag '/' ];
            IS_paramsfolder = ['results/Params/' opt.paramsUse '/Full/Iterated/VAR' num2str(nlags) '/'];

        end

        %========================================
        % CONFIGURE DATES AND PLOT OPTIONS
        %========================================

        % Vector of dates for the full sample and for the available estimation sample
        dates_full = datenum((datetime(start_date,'InputFormat',inputformat)):calmonths(1):(datetime(end_date,'InputFormat',inputformat)))';

        % Vector of dates for the available estimation sample
        sd_var = find(datenum((datetime(start_date,'InputFormat',inputformat)+calmonths(nlags)))==dates_full);
        ed_var  = find(datenum((datetime(end_date,'InputFormat',inputformat)-calmonths(opt.hh)))==dates_full);
        dates_var  = dates_full(sd_var:ed_var);

        % Number of time-periods in simulation of GDP
        opt.tperiods = length(dates_full);
        
        % Extract the index for the desired density plots
        opt.date_index = find(ismember(dates_full, target_dates));

        % Figure options
        FontSize  = 16;
        numticks  = 48;
        figSize   = [12 6];
        linestyle = {'-','--',':'};
        colors    = cbrewer('div', 'RdYlBu', 64);
        colors2   = cbrewer('qual', 'Set1', 8);
        left_color= [0 0 0];
        right_color= colors(2,:);

        % Create folders to store results
        if exist(paramsfolder,'dir')==0;  mkdir(paramsfolder); end

        %%
        %==========================================================================
        % LOAD DATA
        %==========================================================================

        [db, db_full,startdb,enddb,tex] = fLoadData(datafilename,sheetuse,start_date,end_date,opt.hh);

        % Collect MF, FF and trend (estimation sample)
        FF    = db.FF.data(nlags+1:end);
        MF    = db.MF.data(nlags+1:end);
        TR    = db.TRENDH.data(nlags+1:end);
        GDPG  = db.GDPG.data(nlags+1:end);
        GDPGH = db.GDPGH.data(nlags+1:end);

        % Collect MF, FF and trend (full sample)
        FF_full = db_full.FF.data;
        MF_full = db_full.MF.data;
        TR_full = db_full.TRENDH.data;
        GDPG_full  = db_full.GDPG.data;
        GDPGH_full = db_full.GDPGH.data;
        GDPGH_full_wt = GDPGH_full + TR_full;

        % Complete the trend with the last observation
        for jj=1:length(TR_full)
            if TR_full(jj)==0; TR_full(jj) = TR_full(jj-1); end
        end

        % Model name and title
        % Note: iterated model posterior mode depends on opt.hh through the estimation sample
        modelname = [datafilename '_' sheetuse '_' startdb enddb ...
            '_' 'C' num2str(opt.const) 'N' num2str(opt.normal) 'H' num2str(opt.hh) spectag];

        IS_modelname = [datafilename '_' sheetuse '_' '1973M1' '2019M10' ...
            '_' 'C' num2str(opt.const) 'N' num2str(opt.normal) 'H' num2str(opt.hh) spectag];

        %% RISE ESTIMATION

        %%%%%%%%
        % MODE %
        %%%%%%%%
        if strcmp(opt.paramsUse,'mode')

            % Load results or estimate posterior mode
            if exist([paramsfolder modelname '.mat'],'file')==0 || opt.force_estimate==1

                % Estimate posterior mode
                run scriptEstimateMode_FULL.m;

                % Store solution structure
                save([paramsfolder modelname '.mat'],'sPMode')
            else
                % Load stored results
                load([paramsfolder modelname '.mat']);

                % Map objects:
                sv = sPMode.sv;
            end

        else
            %%%%%%%%
            % MCMC %
            %%%%%%%%

            % Load or estimate mcmc
            if exist([paramsfolder modelname '.mat'],'file')==0 || opt.force_estimate==1
                % Estimat posterior distribution
                run scriptEstimateMCMC.m

                % Store solution structure
                save([paramsfolder modelname '.mat'],'sPmcmc')

            else

                % Load stored results
                load([paramsfolder modelname '.mat']);

                % Map objects:
                sv = sPmcmc.sv;
                pmcmc = sPmcmc.params;
                results = sPmcmc.results;
                [ff,lb,ub,x0,vcov,self]=pull_objective(sv);


                % Collect Posterior Estimates and Confidence Bands
                pmode=posterior_mode(sv);

                pnames=fieldnames(pmode);

                a2tilde_to_a=sv.estim_.linres.a2tilde_to_a;

                params=[results.pop.x];

                params_M = prctile(params,50,2);
                params_UB = prctile(params,95,2);
                params_LB = prctile(params,5,2);

                print_structural_form(sv)

                F = fieldnames(pmode);
                C = num2cell(struct2cell(pmode),3);
                C = cellfun(@(c)[c{:}],C,'uni',0);
                params_pmode = vertcat(C{:});

                params_M_Struct=a2tilde_to_a(params_M);
                params_UB_Struct=a2tilde_to_a(params_UB);
                params_LB_Struct=a2tilde_to_a(params_LB);

                paramsAll = a2tilde_to_a(params);
                for ii=1:numel(F)
                    eval(['pmcmc.' F{ii} '= paramsAll(ii,:) ;'])
                end

            end
        end

        %% Posterior Mode Analysis

        % Posterior mode values
        pmode=posterior_mode(sv);

        % Map posterior mode coefficient estimates
        fnames = fieldnames(pmode);
        for jj=1:length(fnames)
            eval([fnames{jj} ' = pmode.' fnames{jj} ';']);
        end


        %% Collect parameters

        if strcmp(opt.paramsUse,'mode')
            params_in   = pmode;
            opt.nParamDraws = 1; %length(pmode.a12);
        elseif strcmp(opt.paramsUse,'mcmc')
            params_in   = pmcmc;
            opt.nDraws  = 10;
        end

        outparams = scriptParams_FULL_companion(sv,params_in,1); % works for any lag and model

        %% Construct Densities
        if opt.simtype==1
            simtype = 'forecastst';
        else
            simtype = 'drawst';
        end

        if opt.dir_or_it==1
            % Direct forecast
            [quantiles,pdensity] = fPredDensityDirectFull(sv,params_in,FF_full,MF_full,GDPGH_full,TR_full,opt,simtype);
        elseif opt.dir_or_it==2
            % Iterated forecast
            [quantiles, pdensity] = fPredDensityIteratedFull(sv,params_in,FF_full,MF_full,GDPG_full,TR_full,opt,simtype);
        end


        % Quantiles
        quantiles.dYsim_25  = quantiles.dYsim_25(opt.date_index);
        quantiles.dYsim_75  = quantiles.dYsim_75(opt.date_index);
        quantiles.dYsim_10  = quantiles.dYsim_10(opt.date_index);
        quantiles.dYsim_90  = quantiles.dYsim_90(opt.date_index);
        quantiles.mean      = quantiles.mean(opt.date_index);
        quantiles.st_t_mean = quantiles.st_t_mean(opt.date_index);

        % Predictive density at specified episodes
        [pdfi,xi]  = ksdensity(pdensity.realized);
        [pdfi_good,xi_good]  = ksdensity(pdensity.good);
        [pdfi_bad,xi_bad]  = ksdensity(pdensity.bad);
        [cxi,cdfi] = ksdensity(pdensity.realized,'Function','icdf');

        % Predictive score at specified episodes
        [~,xi_ps]  = min(abs(xi-GDPGH_full_wt(opt.date_index,:)));
        if isempty(xi_ps) || xi_ps==1 || xi_ps==100
            ps = 0;
        else
            ps = pdfi(1,xi_ps);
        end

        % PITs at specified episodes
        [~,xi_pits]  = min(abs(cxi-GDPGH_full_wt(opt.date_index,:)));
        if isempty(xi_pits) || xi_pits==1 || xi_pits==100
            pits = 0;
        else
            pits = cdfi(1,xi_pits);
        end


        %% Stored Output
        results.outparams  = outparams; % parameters
        results.quantiles  = quantiles; % quantiles and transition probability
        results.pdfi       = pdfi;      % PDF ergodic
        results.pdfi_good  = pdfi_good; % PDF good regime
        results.pdfi_bad   = pdfi_bad;  % PDF bad regime
        results.ps         = ps;        % predictive score
        results.pits       = pits;      % PIT

        save([paramsfolder modelname '.mat'],'results');
        toc;

    end
end
%%
rise_exit
