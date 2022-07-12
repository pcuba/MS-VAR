    %load data
    load('Res_sim');
    Res.Res_iterated = Res_iterated; Res.Res_direct = Res_direct;
    
    n_draws = size(Res.Res_direct.y_mat,1);
%     n_draws = 2;
    
    y_fit = NaN(size(Res.Res_direct.y_mat,2)-nlags,n_draws);
    st_fit = NaN(size(Res.Res_direct.y_mat,2)-nlags,n_draws);
    
    c_1_1 = NaN(n_draws,1);
    c_2_1 = NaN(n_draws,1);
    a0_1_1 = NaN(n_draws,1);
    a0_2_1 = NaN(n_draws,1);
    a0_1_2 = NaN(n_draws,1);
    a0_2_2 = NaN(n_draws,1);
    a0_1_3 = NaN(n_draws,1);
    a0_2_3 = NaN(n_draws,1);
    a1_1_1 = NaN(n_draws,1);
    a1_2_1 = NaN(n_draws,1);
    a1_3_1 = NaN(n_draws,1);
    a1_1_2 = NaN(n_draws,1);
    a1_2_2 = NaN(n_draws,1);
    a1_3_2 = NaN(n_draws,1);
    a1_1_3 = NaN(n_draws,1);
    a1_2_3 = NaN(n_draws,1);
    a1_3_3 = NaN(n_draws,1);
    s_1_1 = NaN(n_draws,1);
    s_2_2 = NaN(n_draws,1);
    a12 = NaN(n_draws,1);
    a21 = NaN(n_draws,1);
    b12 = NaN(n_draws,1);
    c12 = NaN(n_draws,1);
    b21 = NaN(n_draws,1);
    c21 = NaN(n_draws,1);
    c_3_1_sync_1 = NaN(n_draws,1);
    c_3_1_sync_2 = NaN(n_draws,1);
    a0_3_1_sync_1 = NaN(n_draws,1);
    a0_3_1_sync_2 = NaN(n_draws,1);
    a0_3_2_sync_1 = NaN(n_draws,1);
    a0_3_2_sync_2 = NaN(n_draws,1);
    a0_3_3_sync_1 = NaN(n_draws,1);
    a0_3_3_sync_2 = NaN(n_draws,1);
    s_3_3_sync_1 = NaN(n_draws,1);
    s_3_3_sync_2 = NaN(n_draws,1);
    
    parfor draw =1:n_draws
%     for draw =100:100
        [db, db_full, tex] = data_sim(Res,draw,start_date);
        nlags=1;
        % Collect MF, FF and trend (estimation sample)
        FF = db.FF.data(nlags+1:end);
        MF = db.MF.data(nlags+1:end);
        
        % Collect MF, FF and trend (full sample)
        FF_full = db_full.FF.data(nlags+1:end);
        MF_full = db_full.MF.data(nlags+1:end);
        
        if dir_or_it ==1
            varlist={'FF','MF','GDPGH'}';
        elseif dir_or_it ==2
            varlist={'FF','MF','GDPG'}';
        end
        
        %% set up Markov chains
        
        switches = {'c(3)','a0(3)','s(3)'};
        
        if const==1
            if normal==1
                prob_fct = {{
                    
                % Format is [name_tp_1_2]
                'sync_tp_1_2=1/(1+exp(a12-b12*(FF)-c12*(MF)))'
                'sync_tp_2_1=1/(1+exp(a21-b21*(FF)-c21*(MF)))'
                }};
            elseif normal==0
                prob_fct = {{
                    'sync_tp_1_2=1/(1+exp(a12-b12*(FF)+c12*(MF)))'
                    'sync_tp_2_1=1/(1+exp(a21+b21*(FF)-c21*(MF)))'
                    }};
            end
            prob_params = {{'a12','a21','b12','c12','b21','c21'}};
        elseif const==0
            if normal==1
                prob_fct = {{
                    'sync_tp_1_2=1/(1+exp(-b12*(FF)-c12*(MF)))'
                    'sync_tp_2_1=1/(1+exp(-b21*(FF)-c21*(MF)))'
                    }};
            elseif normal==0
                prob_fct = {{
                    'sync_tp_1_2=1/(1+exp(-b12*(FF)+c12*(MF)))'
                    'sync_tp_2_1=1/(1+exp(+b21*(FF)-c21*(MF)))'
                    }};
            end
            prob_params = {{'b12','c12','b21','c21'}};
        end
        
        markov_chains=struct('name','sync',...
            'number_of_states',2,...
            'controlled_parameters',{switches},...   % these correspond to the parameters that are switching
            'endogenous_probabilities',prob_fct,...
            'probability_parameters',prob_params);
        
        
        %% Create the VAR
        nlags=1;
        
        exog={};
        
        constant=true;
        
        panel=[];
        
        sv0=svar(varlist,exog,nlags,constant,panel,markov_chains);
        
        %% set up restrictions
        
        % syntax is alag(eqtn,vname)
        %-------------------------------
        if dir_or_it ==1
            lin_restr={
                % first equation or "financial factor" equation
                %----------------------------------
                'a0(1,GDPGH)=0'
                'a1(1,GDPGH)=0'
                %'a1(1,MF)=0'
                % second equation or "macroeconomic factor" equation
                %-----------------------------------
                'a0(2,GDPGH)=0'
                'a0(2,FF)=0'
                'a1(2,GDPGH)=0'
                % third equation or "GDP Growth" equation
                %----------------------------------
                'a1(3,GDPGH)=0'
                'a1(3,FF)=0'
                'a1(3,MF)=0'
                };
        elseif dir_or_it ==2
            lin_restr={
                % first equation or "financial factor" equation
                %----------------------------------
                'a0(1,GDPG)=0'
                'a1(1,GDPG)=0'
                %'a1(1,MF)=0'
                % second equation or "macroeconomic factor" equation
                %-----------------------------------
                'a0(2,GDPG)=0'
                'a0(2,FF)=0'
                'a1(2,GDPG)=0'
                % third equation or "GDP Growth" equation
                %----------------------------------
                'a1(3,GDPG)=0'
                'a1(3,FF)=0'
                'a1(3,MF)=0'
                };
        end
        
        restrictions=lin_restr;
        
        %% set priors
        
        % priors for the VAR coefficients
        var_prior=svar.prior_template();
        %--------------------------------
        % Sims and Zha (1998) Normal-Wishart Prior Hyperparameters
        % L1 : Overall tightness
        % L2 : Cross-variable specific variance parameter
        % L3 : Speed at which lags greater than 1 converge to zero
        % L4 : tightness on deterministic/exogenous terms
        % L5 : covariance dummies(omega)
        % L6 : co-persistence (lambda)
        % L7 : Own-persistence (mu)
        var_prior.type='sz';
        var_prior.L1=1;
        var_prior.L5=1;
        var_prior.L6=0; % cointegration
        var_prior.L7=0; % unit root
        % var_prior.coefprior=0.9; % impose 0.9 eigenvalue for both
        
        % priors for the sync transition probabilities
        %------------------------------------------------
        switch_prior=struct();
        if const==1
            if normal==1
                switch_prior.a12={0,0,2,'normal'};
                switch_prior.b12={0,0,2,'normal'};
                switch_prior.c12={0,0,2,'normal'};
                switch_prior.a21={0,0,2,'normal'};
                switch_prior.b21={0,0,2,'normal'};
                switch_prior.c21={0,0,2,'normal'};
            elseif normal==0
                switch_prior.a12={0.5,0.5,0.5,'normal'};
                switch_prior.a21={0.5,0.5,0.5,'normal'};
                switch_prior.b12={0.5,0.5,0.25,'gamma'};
                switch_prior.c12={0.5,0.5,0.25,'gamma'};
                switch_prior.b21={0.5,0.5,0.25,'gamma'};
                switch_prior.c21={0.5,0.5,0.25,'gamma'};
            end
        elseif const==0
            if normal==1
                switch_prior.b12={-0.25,-0.25,0.1,'normal'};
                switch_prior.c12={0.25,0.25,0.1,'normal'};
                switch_prior.b21={0.25,0.25,0.1,'normal'};
                switch_prior.c21={-0.25,-0.25,0.1,'normal'};
            elseif normal==0
                switch_prior.b12={0.5,0.5,0.25,'gamma'};
                switch_prior.c12={0.5,0.5,0.25,'gamma'};
                switch_prior.b21={0.5,0.5,0.25,'gamma'};
                switch_prior.c21={0.5,0.5,0.25,'gamma'};
            end
        end
        
        prior=struct();
        
        prior.var=var_prior;
        
        prior.nonvar=switch_prior;
        
        %% Find posterior mode
        sv=estimate(sv0,db,{'2100M1','2198M12'},prior,restrictions,'fmincon');
        pmode=posterior_mode(sv);
        [Resids,Fits]=residuals(sv);
        if dir_or_it ==1
            fit1 = Fits.GDPGH.data(:,1);
            fit2 = Fits.GDPGH.data(:,2);
        elseif dir_or_it ==2
            fit1 = Fits.GDPG.data(:,1);
            fit2 = Fits.GDPG.data(:,2);
        end
        
        
        % Smoothed and Filtered probabilities
        [~,~,~,f]=filter(sv);
        p_reg1 = f.smoothed_regime_probabilities.regime1.data;
        p_reg2 = f.smoothed_regime_probabilities.regime2.data;
        
        p_reg1_filtered = f.filtered_regime_probabilities.regime1.data;
        p_reg2_filtered = f.filtered_regime_probabilities.regime2.data;
        
        y_fit(:,draw) = fit1.*p_reg1 + fit2.*p_reg2;
        
        st_temp1 = ones(size(p_reg2));
        st_temp1(p_reg2>0.9) = 2;
        st_fit(:,draw) = st_temp1;
%         if draw ==100 ss1 = st_temp1;
%         elseif draw ==4 ss2 = st_temp1;
%         end
        
        %% Store estimates
        
        c_1_1(draw) = pmode.c_1_1;
        c_2_1(draw) = pmode.c_2_1;
        a0_1_1(draw) = pmode.a0_1_1;
        a0_2_1(draw) = pmode.a0_2_1;
        a0_1_2(draw) = pmode.a0_1_2;
        a0_2_2(draw) = pmode.a0_2_2;
        a0_1_3(draw) = pmode.a0_1_3;
        a0_2_3(draw) = pmode.a0_2_3;
        a1_1_1(draw) = pmode.a1_1_1;
        a1_2_1(draw) = pmode.a1_2_1;
        a1_3_1(draw) = pmode.a1_3_1;
        a1_1_2(draw) = pmode.a1_1_2;
        a1_2_2(draw) = pmode.a1_2_2;
        a1_3_2(draw) = pmode.a1_3_2;
        a1_1_3(draw) = pmode.a1_1_3;
        a1_2_3(draw) = pmode.a1_2_3;
        a1_3_3(draw) = pmode.a1_3_3;
        s_1_1(draw) = pmode.s_1_1;
        s_2_2(draw) = pmode.s_2_2;
        a12(draw) = pmode.a12;
        a21(draw) = pmode.a21;
        b12(draw) = pmode.b12;
        c12(draw) = pmode.c12;
        b21(draw) = pmode.b21;
        c21(draw) = pmode.c21;
        c_3_1_sync_1(draw) = pmode.c_3_1_sync_1;
        c_3_1_sync_2(draw) = pmode.c_3_1_sync_2;
        a0_3_1_sync_1(draw) = pmode.a0_3_1_sync_1;
        a0_3_1_sync_2(draw) = pmode.a0_3_1_sync_2;
        a0_3_2_sync_1(draw) = pmode.a0_3_2_sync_1;
        a0_3_2_sync_2(draw) = pmode.a0_3_2_sync_2;
        a0_3_3_sync_1(draw) = pmode.a0_3_3_sync_1;
        a0_3_3_sync_2(draw) = pmode.a0_3_3_sync_2;
        s_3_3_sync_1(draw) = pmode.s_3_3_sync_1;
        s_3_3_sync_2(draw) = pmode.s_3_3_sync_2;
        
        
        % print_structural_form(sv)
        % print_solution(sv)
        
    end