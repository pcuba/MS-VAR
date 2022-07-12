%------------------------------------------------------------------
% Predictive Density - Direct simulation
% Generates the Predictive Density for a given parameter vector
% Parameter vector is a structure in which each field corresponds
% to a parameter draw
%
%
%------------------------------------------------------------------
function [out,pden_mat] = fPredDensityDirectDGP(param_in,FF,MF,GDP,p_reg_bad,trend_fit,opt,modelspec)

tperiods = opt.tperiods;

% Pre-allocate simulation matrices
y_mat_fut_ex_temp  = NaN(opt.nParamDraws,opt.nDraws,tperiods); 
y_mat_fut_ex_temp_good = NaN(opt.nParamDraws,opt.nDraws,tperiods); 
y_mat_fut_ex_temp_bad = NaN(opt.nParamDraws,opt.nDraws,tperiods); 


% Pre-allocate state matrices
stemp_t   = NaN(opt.nParamDraws,opt.nDraws,tperiods);

% Regime indicator
pbad = p_reg_bad;

% Loop over parameter draws
for dd=1:opt.nParamDraws
    
    % Counter for rows storing parameter*repetition
    %             waitbar(dd/opt.nParamDraws,wb,'Calculating paths for the direct version')
    
    % Check regime indicator and collect VAR matrices
    param = scriptParams_FULL(param_in,dd,modelspec);
        
    % Loop over repetitions
    parfor uu=1:opt.nDraws
        %st_sim = 1; % initialization of the simulated states
        st_sim = NaN(tperiods,1);
        
        % Loop over periods
        for tt=1:tperiods
            
            % Simulate s(t) conditional on realized path of m and f
            % from t-12 to t-1.
            if tt<opt.hh+1
                % In the first hh we can construct s(t) from the filtered probabilities
                
                % Use filtered probability to determine current state
                udraw = rand(1); % draw a coin that determines the regime
                if udraw < (1-pbad(tt))
                    st_temp = 1;
                else
                    st_temp = 2;
                end
            else
                
                % s(t-opt.hh)
                st_lag = st_sim(tt-opt.hh);
                
                % Realized path of f and m from t-opt.hh,....,t-1
                f_temp = FF(tt-opt.hh:tt-1);
                m_temp = MF(tt-opt.hh:tt-1);
                
                % Compute transition probabilities for s(t-11),...,s(t)
                [p12,p21] = fTranstionProb(param,f_temp,m_temp,opt);
                
                p11 = ones(opt.hh,1) - p12; % probability of remaining in normal
                p22 = ones(opt.hh,1) - p21; % probability of remaining in bad
                
                % This returns s(t-11)...s(t))
                st_sim_temp = simulate_st(st_lag,p11,p22,opt.hh);
                
                % This is s(t)
                st_temp = st_sim_temp(opt.hh);
                
            end
            
            st_sim(tt) = st_temp;
            
            % Macro and financial factor in period t
            f_t = FF(tt);
            m_t = MF(tt);
            gdp_t = GDP(tt);
            
            % Simulate GDP
            [y_temp,y_temp1,y_temp2] = simulate_DirectFull(st_temp,f_t,m_t,gdp_t,param);
            
            % Average future GDP t+1:t+h
            y_mat_fut_ex_temp(dd,uu,tt) = y_temp+trend_fit(tt);
            y_mat_fut_ex_temp_good(dd,uu,tt) = y_temp1 + trend_fit(tt);
            y_mat_fut_ex_temp_bad(dd,uu,tt) = y_temp2+ trend_fit(tt);
            
            % Collect t state
            stemp_t(dd,uu,tt)      = st_temp;
            
        end
    end
end

% Reshape matrices
y_mat_fut_ex = reshape(y_mat_fut_ex_temp,[opt.nDraws*opt.nParamDraws,tperiods]);
y_mat_fut_ex_good  = reshape(y_mat_fut_ex_temp_good,[opt.nDraws*opt.nParamDraws,tperiods]);
y_mat_fut_ex_bad  = reshape(y_mat_fut_ex_temp_bad,[opt.nDraws*opt.nParamDraws,tperiods]);

stmat_t = reshape(stemp_t,[opt.nDraws*opt.nParamDraws,tperiods]);

% Change st=2 (bad) to st = 0 for plotting
% Mean(st) represents probability of good regime
stmat_t(stmat_t==2) = 0;

out.st_t_mean= mean(stmat_t)'; % This is in t
out.dYsim_25 = prctile(y_mat_fut_ex,25)';
out.dYsim_75 = prctile(y_mat_fut_ex,75)';
out.dYsim_10 = prctile(y_mat_fut_ex,10)';
out.dYsim_90 = prctile(y_mat_fut_ex,90)';
out.mean     = mean(y_mat_fut_ex)';


% This is the predictive density matrix (opt.nDraws*opt.nParamDraws)xselected_periods
if ~isempty(opt.date_index)
    pden_mat.realized = y_mat_fut_ex(:,opt.date_index);
    pden_mat.good     = y_mat_fut_ex_good(:,opt.date_index);
    pden_mat.bad      = y_mat_fut_ex_bad(:,opt.date_index);
else
    pden_mat = [];
end
