%% Markov-Switching Real-Time Growth-at-Risk
% Model with f_t and m_t endogenous

%% housekeeping
clear; close all; clc; tic;

% Important paths
addpath('/if/prod-tfs/production/GAR/MS-VAR/RISE_toolbox');
addpath(genpath('scripts'));
addpath(genpath('cbrewer'));

% Options
dir_or_it    = 2; % 1 = direct, 2 = iterated
const        = 1; % 1 = have a constant in transition probability
normal       = 0; % 1 = use normal distribution, 0 = gamma distribution
saveit       = 1; % 1 = save figures
example_draw = 10; % single draw for comparison
num_rep      = 1000; % Number of repetitions for the coverage bands
compare      = 2; % 1 = compare the iterated and direct results (no parameter uncertainty)
% 2 = compare the iterated and direct results (parameter uncertainty)


% Data vintage, sample and country selection
start_date   = '2100-Jan';
end_date     = '2198-Dec';
end_date_db  = '2199-Dec';

% VAR configuration
nlags=1;
exog={};
constant=true;
panel=[];

if dir_or_it ==1
    model = 'results_direct';
elseif dir_or_it ==2
    model = 'results_iterated';
end

sim_folder = 'Results/Simulation/';
if exist(sim_folder,'dir')==0
    mkdir(sim_folder)
end


% Create date formats for plotting
inputformat = 'yyyy-MMM';
dataformat  = 'yyyy-mmm';
start_plot    = '2100-Feb';
end_plot      = end_date_db;
end_plot_full = end_date;

% Vector of dates for the full sample
dates_full = datenum((datetime(start_date,'InputFormat',inputformat))+calmonths(nlags):calmonths(1):(datetime(end_date,'InputFormat',inputformat)))';

% Index of dates
sd      = find(datenum(start_plot,dataformat)==dates_full);
ed      = find(datenum(end_plot,dataformat)==dates_full);
ed_full = find(datenum(end_plot_full,dataformat)==dates_full);

% Vector of dates for plotting
dates   = dates_full(sd:ed);

% Figure options
FontSize = 16;
numticks = 48;
figSize = [12 6];
linestyle = {'-','--',':'};
colors = cbrewer('div', 'RdYlBu', 64);
colors2 = cbrewer('qual', 'Set1', 8);
left_color = [0 0 0];
right_color = colors(2,:);

%% Load RISE
rise_startup()

%% Load results or estimate
if exist([sim_folder '' model '.mat'],'file')==2
    compare_temp = compare;
    load([sim_folder '' model '.mat'])
    compare = compare_temp;
else
    run estimation_loop.m; % This only estimates and stores the posterior mode
    save([sim_folder '' model '.mat'])
end

if compare ==2
    if exist([sim_folder '' model '_samp.mat'],'file')==2
        load([sim_folder '' model '_samp.mat'])
    else
        samp=posterior_sampling_example(example_draw,dir_or_it,nlags,start_date,const,normal);
        save([sim_folder '' model '_samp.mat'],'samp')
    end
end

%% Check if reg =1 is high growth, low vol
check_good = zeros(n_draws,1);
check_flip = zeros(n_draws,1);
check_wrong = zeros(n_draws,1);

for yy=1:n_draws
    if c_3_1_sync_1(yy)>c_3_1_sync_2(yy)
        if s_3_3_sync_1(yy)<s_3_3_sync_2(yy)
            check_good(yy)=1; % if mean is larger, and s.d. is smaller
        else
            check_wrong(yy)=1; % if mean is larger, and s.d. is larger
        end
    else
        if s_3_3_sync_1(yy)<s_3_3_sync_2(yy)
            check_wrong(yy)=1; % if mean is smaller, and s.d. is smaller
        else
            check_flip(yy)=1; % if mean is smaller, and s.d. is larger
        end
    end
end
%% Quantiles

y_mat = y_fit';
size_y = size(y_mat,2);

% Check for convergence errors
correct = s_3_3_sync_2<dgp.s_3_3_sync_2*10;


% Compute percentiles
dY_25 = prctile(y_mat(correct,:),25)'; dY_75 = prctile(y_mat(correct,:),75)';
dY_10 = prctile(y_mat(correct,:),10)'; dY_90 = prctile(y_mat(correct,:),90)';
if dir_or_it ==2
    
    % 12-months ahead from the fitted
    y_mat_fut = NaN(size(y_mat,1),size(y_mat,2)-12);
    for hh=1:size(y_mat,1)
        for ww=1:size(y_mat,2)-12
            y_mat_fut(hh,ww) = mean(y_mat(hh,ww+1:ww+12));
        end
    end
    dY_25_fut = prctile(y_mat_fut(correct,:),25)'; dY_75_fut = prctile(y_mat_fut(correct,:),75)';
    dY_10_fut = prctile(y_mat_fut(correct,:),10)'; dY_90_fut = prctile(y_mat_fut(correct,:),90)';
end

run plot_histograms_and_figs.m


%% Compare both estimations
if compare ==1
    if exist([sim_folder 'results_iterated.mat'],'file')==2
        load([sim_folder 'results_iterated.mat'])
        compare =1;
        %% EXAMPLE DRAW (DGP)
        y_mat_fut_ex_dgp = NaN(size(y_mat,1),size(y_mat,2)); % This stores all realizations for the ITERATED
        for jj=1:size(y_mat,2)
            dd=example_draw;
            for uu=1:num_rep
                y_temp = [Res_iterated.y_mat(dd,jj);NaN(12,1)];
                f_temp = [Res_iterated.FF(dd,jj);NaN(12,1)];
                m_temp = [Res_iterated.MF(dd,jj);NaN(12,1)];
                s_temp = [Res_iterated.st_mat(dd,jj);NaN(12,1)];
                
                for ee=2:13 % Construct states, mf and ff for every period from t+1 to t+12, check state at each point in time and construct GDP accordingly, then avergage GDP (t+1 to t+12)
                    
                    eta1 = randn(2,1); % financial and macro shocks
                    
                    m_temp(ee) = dgp.c_2_1 +                         dgp.a1_2_1*f_temp(ee-1) + dgp.a1_2_2*m_temp(ee-1) + dgp.s_2_2*eta1(2,1);
                    f_temp(ee) = dgp.c_1_1 + dgp.a0_1_2*m_temp(ee) + dgp.a1_1_1*f_temp(ee-1) + dgp.a1_1_2*m_temp(ee-1) + dgp.s_1_1*eta1(1,1);
                    
                    
                    
                    p12 = 1/(1+exp(dgp.a12-dgp.b12*(f_temp(ee))+dgp.c12*(m_temp(ee))));
                    p21 = 1/(1+exp(dgp.a21+dgp.b21*(f_temp(ee))-dgp.c21*(m_temp(ee))));
                    
                    p11 = 1 - p12; % probability of remaining in normal
                    p22 = 1 - p21; % probability of remaining in bad
                    
                    
                    udraw = rand(1);
                    
                    if s_temp(ee-1) == 1 % started in good regime
                        if udraw > p11
                            s_temp(ee) = 2; % switch from good to bad
                        else
                            s_temp(ee) = 1; % don't switch and remain in good
                        end
                    else % start in bad regime
                        if udraw > p22
                            s_temp(ee) = 1; % switch from bad to good
                        else
                            s_temp(ee) = 2; % don't switch and remain in bad
                        end
                        
                    end
                    
                    
                    eta2 = randn(1,1); % GDP shock
                    
                    if s_temp(ee)==2
                        y_temp(ee) = dgp.c_3_1_sync_2+dgp.a0_3_1_sync_2*f_temp(ee) +dgp.a0_3_2_sync_2*m_temp(ee) +dgp.s_3_3_sync_2*eta2;
                    else
                        y_temp(ee) = dgp.c_3_1_sync_1+dgp.a0_3_1_sync_1*f_temp(ee) +dgp.a0_3_2_sync_1*m_temp(ee) +dgp.s_3_3_sync_1*eta2;
                    end
                    
                    
                    if ee==13
                        y_mat_fut_ex_dgp(uu,jj) = mean(y_temp(2:end,1));
                    end
                end
            end
        end
        dY_25_fut_ex_dgp = prctile(y_mat_fut_ex_dgp,25)'; dY_75_fut_ex_dgp = prctile(y_mat_fut_ex_dgp,75)';
        dY_10_fut_ex_dgp = prctile(y_mat_fut_ex_dgp,10)'; dY_90_fut_ex_dgp = prctile(y_mat_fut_ex_dgp,90)';
        
        %% Simulated
        st_mat = st_fit'; % Now use the fitted values
        y_mat = y_fit';
        % 12-months ahead iterated
        y_mat_fut2 = NaN(size(y_mat,1),size(y_mat,2));
        % Set a 0.9 threshold to switch from good to bad regime
        % Check for convergence errors
        correct = s_3_3_sync_2<dgp.s_3_3_sync_2*10;
        
        for jj=1:size(y_mat,2)
            for dd=1:n_draws
                y_temp = [y_mat(dd,jj);NaN(12,1)];
                f_temp = [Res_iterated.FF(dd,jj);NaN(12,1)];
                m_temp = [Res_iterated.MF(dd,jj);NaN(12,1)];
                s_temp = [st_mat(dd,jj);NaN(12,1)];
                
                for ee=2:13
                    
                    eta1 = randn(2,1); % financial and macro shocks
                    
                    m_temp(ee) = c_2_1(dd) +                              a1_2_1(dd)*f_temp(ee-1) + a1_2_2(dd)*m_temp(ee-1) + s_2_2(dd)*eta1(2,1);
                    f_temp(ee) = c_1_1(dd) + a0_1_2(dd)*m_temp(ee)*(-1) + a1_1_1(dd)*f_temp(ee-1) + a1_1_2(dd)*m_temp(ee-1) + s_1_1(dd)*eta1(1,1);
                    
                    
                    
                    p12 = 1/(1+exp(a12(dd)-b12(dd)*(f_temp(ee))+c12(dd)*(m_temp(ee))));
                    p21 = 1/(1+exp(a21(dd)+b21(dd)*(f_temp(ee))-c21(dd)*(m_temp(ee))));
                    
                    p11 = 1 - p12; % probability of remaining in normal
                    p22 = 1 - p21; % probability of remaining in bad
                    
                    
                    udraw = rand(1);
                    
                    if s_temp(ee-1) == 1 % started in good regime
                        if udraw > p11
                            s_temp(ee) = 2; % switch from good to bad
                        else
                            s_temp(ee) = 1; % don't switch and remain in good
                        end
                    else % start in bad regime
                        if udraw > p22
                            s_temp(ee) = 1; % switch from bad to good
                        else
                            s_temp(ee) = 2; % don't switch and remain in bad
                        end
                        
                    end
                    
                    
                    eta2 = randn(1,1); % GDP shock
                    
                    if s_temp(ee)==2
                        y_temp(ee) = c_3_1_sync_2(dd)+a0_3_1_sync_2(dd)*f_temp(ee)*(-1) +a0_3_2_sync_2(dd)*m_temp(ee)*(-1) +s_3_3_sync_2(dd)*eta2;
                    else
                        y_temp(ee) = c_3_1_sync_1(dd)+a0_3_1_sync_1(dd)*f_temp(ee)*(-1) +a0_3_2_sync_1(dd)*m_temp(ee)*(-1) +s_3_3_sync_1(dd)*eta2;
                    end
                    
                    
                    if ee==13
                        y_mat_fut2(dd,jj) = mean(y_temp(2:end,1));
                    end
                end
            end
        end
        
        dY_25_fut2 = prctile(y_mat_fut2(correct,:),25)'; dY_75_fut2 = prctile(y_mat_fut2(correct,:),75)';
        dY_10_fut2 = prctile(y_mat_fut2(correct,:),10)'; dY_90_fut2 = prctile(y_mat_fut2(correct,:),90)';
        
        %% EXAMPLE DRAW
        y_mat_fut_ex = NaN(size(y_mat,1),size(y_mat,2)); % This stores all realizations for the ITERATED
        for jj=1:size(y_mat,2)
            dd=example_draw;
            for uu=1:num_rep
                y_temp = [y_mat(dd,jj);NaN(12,1)];
                f_temp = [Res_iterated.FF(dd,jj);NaN(12,1)];
                m_temp = [Res_iterated.MF(dd,jj);NaN(12,1)];
                s_temp = [st_mat(dd,jj);NaN(12,1)];
                
                for ee=2:13 % Construct states, mf and ff for every period from t+1 to t+12, check state at each point in time and construct GDP accordingly, then avergage GDP (t+1 to t+12)
                    
                    eta1 = randn(2,1); % financial and macro shocks
                    
                    m_temp(ee) = c_2_1(dd) +                              a1_2_1(dd)*f_temp(ee-1) + a1_2_2(dd)*m_temp(ee-1) + s_2_2(dd)*eta1(2,1);
                    f_temp(ee) = c_1_1(dd) + a0_1_2(dd)*m_temp(ee)*(-1) + a1_1_1(dd)*f_temp(ee-1) + a1_1_2(dd)*m_temp(ee-1) + s_1_1(dd)*eta1(1,1);
                    
                    
                    
                    p12 = 1/(1+exp(a12(dd)-b12(dd)*(f_temp(ee))+c12(dd)*(m_temp(ee))));
                    p21 = 1/(1+exp(a21(dd)+b21(dd)*(f_temp(ee))-c21(dd)*(m_temp(ee))));
                    
                    p11 = 1 - p12; % probability of remaining in normal
                    p22 = 1 - p21; % probability of remaining in bad
                    
                    
                    udraw = rand(1);
                    
                    if s_temp(ee-1) == 1 % started in good regime
                        if udraw > p11
                            s_temp(ee) = 2; % switch from good to bad
                        else
                            s_temp(ee) = 1; % don't switch and remain in good
                        end
                    else % start in bad regime
                        if udraw > p22
                            s_temp(ee) = 1; % switch from bad to good
                        else
                            s_temp(ee) = 2; % don't switch and remain in bad
                        end
                        
                    end
                    
                    
                    eta2 = randn(1,1); % GDP shock
                    
                    if s_temp(ee)==2
                        y_temp(ee) = c_3_1_sync_2(dd)+a0_3_1_sync_2(dd)*f_temp(ee)*(-1) +a0_3_2_sync_2(dd)*m_temp(ee)*(-1) +s_3_3_sync_2(dd)*eta2;
                    else
                        y_temp(ee) = c_3_1_sync_1(dd)+a0_3_1_sync_1(dd)*f_temp(ee)*(-1) +a0_3_2_sync_1(dd)*m_temp(ee)*(-1) +s_3_3_sync_1(dd)*eta2;
                    end
                    
                    
                    if ee==13
                        y_mat_fut_ex(uu,jj) = mean(y_temp(2:end,1));
                    end
                end
            end
        end
        dY_25_fut_ex = prctile(y_mat_fut_ex,25)'; dY_75_fut_ex = prctile(y_mat_fut_ex,75)';
        dY_10_fut_ex = prctile(y_mat_fut_ex,10)'; dY_90_fut_ex = prctile(y_mat_fut_ex,90)';
        
        
        
        
        if exist([sim_folder 'results_direct.mat'],'file')==2
            load([sim_folder 'results_direct.mat'])
            y_mat = y_fit';
            size_y = size(y_mat,2);
            
            % Check for convergence errors
            correct = s_3_3_sync_2<dgp.s_3_3_sync_2*10;
            
            % Compute percentiles
            dY_25 = prctile(y_mat(correct,:),25)'; dY_75 = prctile(y_mat(correct,:),75)';
            dY_10 = prctile(y_mat(correct,:),10)'; dY_90 = prctile(y_mat(correct,:),90)';
            
            fig=figure; clf;
            hold on
            l1=plot(1:size_y, dY_10_fut2,'Color',colors(5,:),'LineWidth', 1.5,'DisplayName','Iterated 10th');
            % l2=plot(1:size_y, dY_25_fut2,'Color',colors(15,:),'LineWidth', 2,'DisplayName','Iterated 25th');
            % l3=plot(1:size_y, dY_75_fut2,'Color',colors(45,:),'LineWidth', 2,'DisplayName','Iterated 75th');
            l4=plot(1:size_y, dY_90_fut2,'Color',colors(55,:),'LineWidth', 1.5,'DisplayName','Iterated 90th');
            l11=plot(1:size_y, dY_10,'-.','Color',colors(5,:),'LineWidth', 1.5,'DisplayName','Direct 10th');
            % l22=plot(1:size_y, dY_25,'-.','Color',colors(15,:),'LineWidth', 2,'DisplayName','Direct 25th');
            % l33=plot(1:size_y, dY_75,'-.','Color',colors(45,:),'LineWidth', 2,'DisplayName','Direct 75th');
            l44=plot(1:size_y, dY_90,'-.','Color',colors(55,:),'LineWidth', 1.5,'DisplayName','Direct 90th');
            legend([l1 l4 l11 l44],'Orientation','Vertical','Location','Best','interpreter','Latex');legend boxoff;
            set(gca,'children',flipud(get(gca,'children')))
            hold off
            ylabel('Percent','interpreter','Latex','fontsize',10)
            title('Comparison GDP distribution 1-year ahead','FontSize',16','Interpreter','Latex');
            axis tight
            if saveit==1
                print('-dpdf',fig,[sim_folder 'CompareGDP_dist_direct_iterated'],'-bestfit');
                saveas(fig,sprintf('%s.png',[sim_folder 'CompareGDP_dist_direct_iterated']));
            end
            
            %% EXAMPLE DRAW
            y_mat_fut_ex2 = NaN(size(y_mat,1),size(y_mat,2));  % This stores all realizations for the DIRECT
            for jj=13:size(y_mat,2)
                dd=example_draw;
                for uu=1:num_rep
                    y_temp = [y_mat(dd,jj);NaN(12,1)];
                    f_temp = Res_iterated.FF(dd,jj-12:jj);
                    m_temp = Res_iterated.MF(dd,jj-12:jj);
                    s_temp = [st_mat(dd,jj-12);NaN(12,1)];
                    
                    for ee=2:13 % Construct states, mf and ff for every period from t-12 to t, then check the state at t and construct the direct GDP (t+1 to t+12)
                        
                        %                         eta1 = randn(2,1); % financial and macro shocks
                        %
                        %                         m_temp(ee) = c_2_1(dd) +                              a1_2_1(dd)*f_temp(ee-1) + a1_2_2(dd)*m_temp(ee-1) + s_2_2(dd)*eta1(2,1);
                        %                         f_temp(ee) = c_1_1(dd) + a0_1_2(dd)*m_temp(ee)*(-1) + a1_1_1(dd)*f_temp(ee-1) + a1_1_2(dd)*m_temp(ee-1) + s_1_1(dd)*eta1(1,1);
                        %
                        
                        
                        p12 = 1/(1+exp(a12(dd)-b12(dd)*(f_temp(ee))+c12(dd)*(m_temp(ee))));
                        p21 = 1/(1+exp(a21(dd)+b21(dd)*(f_temp(ee))-c21(dd)*(m_temp(ee))));
                        
                        p11 = 1 - p12; % probability of remaining in normal
                        p22 = 1 - p21; % probability of remaining in bad
                        
                        
                        udraw = rand(1);
                        
                        if s_temp(ee-1) == 1 % started in good regime
                            if udraw > p11
                                s_temp(ee) = 2; % switch from good to bad
                            else
                                s_temp(ee) = 1; % don't switch and remain in good
                            end
                        else % start in bad regime
                            if udraw > p22
                                s_temp(ee) = 1; % switch from bad to good
                            else
                                s_temp(ee) = 2; % don't switch and remain in bad
                            end
                            
                        end
                        
                        if ee==13
                            eta2 = randn(1,1); % GDP shock
                            
                            if s_temp(ee)==2
                                y_mat_fut_ex2(uu,jj) = c_3_1_sync_2(dd)+a0_3_1_sync_2(dd)*f_temp(ee)*(-1) +a0_3_2_sync_2(dd)*m_temp(ee)*(-1) +s_3_3_sync_2(dd)*eta2;
                            else
                                y_mat_fut_ex2(uu,jj) = c_3_1_sync_1(dd)+a0_3_1_sync_1(dd)*f_temp(ee)*(-1) +a0_3_2_sync_1(dd)*m_temp(ee)*(-1) +s_3_3_sync_1(dd)*eta2;
                            end
                            
                        end
                    end
                end
            end
            dY_25_fut_ex2 = prctile(y_mat_fut_ex2,25)'; dY_75_fut_ex2 = prctile(y_mat_fut_ex2,75)';
            dY_10_fut_ex2 = prctile(y_mat_fut_ex2,10)'; dY_90_fut_ex2 = prctile(y_mat_fut_ex2,90)';
            
            size_ex = 1000;
            fig=figure; clf;
            hold on
            l1=plot(13:size_ex, dY_10_fut_ex(13:size_ex),'--k','Color',colors(5,:),'LineWidth', 1.5,'DisplayName','Iterated draw 10th');
            l4=plot(13:size_ex, dY_90_fut_ex(13:size_ex),'--k','Color',colors(55,:),'LineWidth', 1.5,'DisplayName','Iterated draw 90th');
            l11=plot(13:size_ex, dY_10_fut_ex2(13:size_ex),'-k','Color',colors(5,:),'LineWidth', 1.5,'DisplayName','Direct draw 10th');
            l44=plot(13:size_ex, dY_90_fut_ex2(13:size_ex),'-k','Color',colors(55,:),'LineWidth', 1.5,'DisplayName','Direct draw 90th');
            l111=plot(13:size_ex, dY_10_fut_ex_dgp(13:size_ex),'-.k','Color',colors(5,:),'LineWidth', 1.5,'DisplayName','DGP draw 10th');
            l444=plot(13:size_ex, dY_90_fut_ex_dgp(13:size_ex),'-.k','Color',colors(55,:),'LineWidth', 1.5,'DisplayName','DGP draw 90th');
            %             l2=plot(13:size_ex, Res_direct.y_mat(example_draw,14:size_ex+1),'-k','LineWidth', 1.5,'DisplayName','Data');
            %             legend([l1 l4 l11 l44 l111 l444 l2],'Orientation','Vertical','Location','Best','interpreter','Latex');legend boxoff;
            legend([l1 l4 l11 l44 l111 l444],'Orientation','Vertical','Location','Best','interpreter','Latex');legend boxoff;
            set(gca,'children',flipud(get(gca,'children')))
            hold off
            ylabel('Percent','interpreter','Latex','fontsize',10)
            title('Comparison GDP distribution 1-year ahead (single draw)','FontSize',16','Interpreter','Latex');
            axis tight
            
            if saveit==1
                print('-dpdf',fig,[sim_folder 'CompareGDP_draw_direct_iterated'],'-bestfit');
                saveas(fig,sprintf('%s.png',[sim_folder 'CompareGDP_draw_direct_iterated']));
            end
        end
    end
end

%% PARAMETER UNCERTAINTY

if compare ==2
    if exist([sim_folder 'results_iterated.mat'],'file')==2
        load([sim_folder 'results_iterated.mat'])
        if exist([sim_folder 'results_iterated_samp.mat'],'file')==2;load([sim_folder 'results_iterated_samp.mat']);end
        %% EXAMPLE DRAW (DGP)
        y_mat_fut_ex_dgp = NaN(size(y_mat,1),size(y_mat,2)); % This stores all realizations for the ITERATED
        st_dgp = NaN(size(y_mat,1),size(y_mat,2)); % This stores all realizations for the ITERATED
        h = waitbar(0,'Calculating paths for the d.g.p.');
        
        for jj=1:size(y_mat,2)
            waitbar(jj/size(y_mat,2),h,'Calculating paths for the d.g.p.')
            
            dd=example_draw;
            for uu=1:num_rep
                y_temp = [Res_iterated.y_mat(dd,jj);NaN(12,1)];
                f_temp = [Res_iterated.FF(dd,jj);NaN(12,1)];
                m_temp = [Res_iterated.MF(dd,jj);NaN(12,1)];
                s_temp = [Res_iterated.st_mat(dd,jj);NaN(12,1)];
                
                for ee=2:13 % Construct states, mf and ff for every period from t+1 to t+12, check state at each point in time and construct GDP accordingly, then avergage GDP (t+1 to t+12)
                    
                    eta1 = randn(2,1); % financial and macro shocks
                    
                    m_temp(ee) = dgp.c_2_1 +                         dgp.a1_2_1*f_temp(ee-1) + dgp.a1_2_2*m_temp(ee-1) + dgp.s_2_2*eta1(2,1);
                    f_temp(ee) = dgp.c_1_1 + dgp.a0_1_2*m_temp(ee) + dgp.a1_1_1*f_temp(ee-1) + dgp.a1_1_2*m_temp(ee-1) + dgp.s_1_1*eta1(1,1);
                    
                    
                    
                    p12 = 1/(1+exp(dgp.a12-dgp.b12*(f_temp(ee))+dgp.c12*(m_temp(ee))));
                    p21 = 1/(1+exp(dgp.a21+dgp.b21*(f_temp(ee))-dgp.c21*(m_temp(ee))));
                    
                    p11 = 1 - p12; % probability of remaining in normal
                    p22 = 1 - p21; % probability of remaining in bad
                    
                    
                    udraw = rand(1);
                    
                    if s_temp(ee-1) == 1 % started in good regime
                        if udraw > p11
                            s_temp(ee) = 2; % switch from good to bad
                        else
                            s_temp(ee) = 1; % don't switch and remain in good
                        end
                    else % start in bad regime
                        if udraw > p22
                            s_temp(ee) = 1; % switch from bad to good
                        else
                            s_temp(ee) = 2; % don't switch and remain in bad
                        end
                        
                    end
                    
                    
                    eta2 = randn(1,1); % GDP shock
                    
                    if s_temp(ee)==2
                        y_temp(ee) = dgp.c_3_1_sync_2+dgp.a0_3_1_sync_2*f_temp(ee) +dgp.a0_3_2_sync_2*m_temp(ee) +dgp.s_3_3_sync_2*eta2;
                    else
                        y_temp(ee) = dgp.c_3_1_sync_1+dgp.a0_3_1_sync_1*f_temp(ee) +dgp.a0_3_2_sync_1*m_temp(ee) +dgp.s_3_3_sync_1*eta2;
                    end
                    
                    
                    if ee==13
                        y_mat_fut_ex_dgp(uu,jj) = mean(y_temp(2:end,1));
                        st_dgp(uu,jj) = s_temp(ee);
                    end
                end
            end
        end
        close(h);
        
        for jj=1:size(y_mat,2)
            for uu=1:num_rep
                if st_dgp(uu,jj) ==1 % good regime
                    st_dgp(uu,jj) = 1;
                elseif st_dgp(uu,jj) ==2 % bad regime
                    st_dgp(uu,jj) = 0;
                end
            end
        end
        st_dgp_t = Res_iterated.st_mat;
        for jj=1:size(st_dgp_t,2)
            for uu=1:size(st_dgp_t,1)
                if st_dgp_t(uu,jj) ==1 % good regime
                    st_dgp_t(uu,jj) = 1;
                elseif st_dgp_t(uu,jj) ==2 % bad regime
                    st_dgp_t(uu,jj) = 0;
                end
            end
        end        
        st_dgp_50 =        mean(st_dgp)'; % This is in t+12
        dY_25_fut_ex_dgp = prctile(y_mat_fut_ex_dgp,25)'; dY_75_fut_ex_dgp = prctile(y_mat_fut_ex_dgp,75)';
        dY_10_fut_ex_dgp = prctile(y_mat_fut_ex_dgp,10)'; dY_90_fut_ex_dgp = prctile(y_mat_fut_ex_dgp,90)';
        
        
        %% EXAMPLE DRAW
        
        st_mat = st_fit'; % Now use the fitted values
        y_mat = y_fit'; % Now use the fitted values
        
        nDraws      = 10;           % Number of simulations per parameter draw
        nParamDraws = samp.options.N;    % Number of parameter draws
        y_mat_fut_ex_temp = NaN(nDraws,nParamDraws,size(y_mat,2)); % This stores all realizations for the ITERATED
        st_it_temp = NaN(nDraws,nParamDraws,size(y_mat,2));
        st_it_temp_t = NaN(nDraws,nParamDraws,size(y_mat,2));
        h = waitbar(0,'Calculating paths for the iterated version');
        y_temp_par1 = y_mat(example_draw,:);
        ff_temp_par1 = Res_iterated.FF(example_draw,:);
        mf_temp_par1 = Res_iterated.MF(example_draw,:);
        st_temp_par1 = st_mat(example_draw,:);
        for jj=1:size(y_mat,2)
            waitbar(jj/size(y_mat,2),h,'Calculating paths for the iterated version')
                y_temp_par = y_temp_par1(jj);
                ff_temp_par = ff_temp_par1(jj);
                mf_temp_par = mf_temp_par1(jj);
                st_temp_par = st_temp_par1(jj);
            parfor dd=1:nParamDraws
                for uu=1:nDraws
                    y_temp = [y_temp_par;NaN(12,1)];
                    f_temp = [ff_temp_par;NaN(12,1)];
                    m_temp = [mf_temp_par;NaN(12,1)];
                    s_temp = [st_temp_par;NaN(12,1)];
                    
                    for ee=2:13 % Construct states, mf and ff for every period from t+1 to t+12, check state at each point in time and construct GDP accordingly, then avergage GDP (t+1 to t+12)
                        
                        eta1 = randn(2,1); % financial and macro shocks
                        
                        m_temp(ee) = samp.c_2_1(dd) +                                   samp.a1_2_1(dd)*f_temp(ee-1) + samp.a1_2_2(dd)*m_temp(ee-1) + samp.s_2_2(dd)*eta1(2,1);
                        f_temp(ee) = samp.c_1_1(dd) + samp.a0_1_2(dd)*m_temp(ee)*(-1) + samp.a1_1_1(dd)*f_temp(ee-1) + samp.a1_1_2(dd)*m_temp(ee-1) + samp.s_1_1(dd)*eta1(1,1);
                        
                        
                        
                        p12 = 1/(1+exp(samp.a12(dd)-samp.b12(dd)*(f_temp(ee))+samp.c12(dd)*(m_temp(ee))));
                        p21 = 1/(1+exp(samp.a21(dd)+samp.b21(dd)*(f_temp(ee))-samp.c21(dd)*(m_temp(ee))));
                        
                        p11 = 1 - p12; % probability of remaining in normal
                        p22 = 1 - p21; % probability of remaining in bad
                        
                        
                        udraw = rand(1);
                        
                        if s_temp(ee-1) == 1 % started in good regime
                            if udraw > p11
                                s_temp(ee) = 2; % switch from good to bad
                            else
                                s_temp(ee) = 1; % don't switch and remain in good
                            end
                        else % start in bad regime
                            if udraw > p22
                                s_temp(ee) = 1; % switch from bad to good
                            else
                                s_temp(ee) = 2; % don't switch and remain in bad
                            end
                            
                        end
                        
                        
                        eta2 = randn(1,1); % GDP shock
                        
                        if s_temp(ee)==2
                            y_temp(ee) = samp.c_3_1_sync_2(dd)+samp.a0_3_1_sync_2(dd)*f_temp(ee)*(-1) +samp.a0_3_2_sync_2(dd)*m_temp(ee)*(-1) +samp.s_3_3_sync_2(dd)*eta2;
                        else
                            y_temp(ee) = samp.c_3_1_sync_1(dd)+samp.a0_3_1_sync_1(dd)*f_temp(ee)*(-1) +samp.a0_3_2_sync_1(dd)*m_temp(ee)*(-1) +samp.s_3_3_sync_1(dd)*eta2;
                        end
                        
                        
                        if ee==13
                            y_mat_fut_ex_temp(uu,dd,jj) = mean(y_temp(2:end,1));
                            st_it_temp(uu,dd,jj) = s_temp(ee);
                            st_it_temp_t(uu,dd,jj) = s_temp(1);
                        end
                    end
                end
            end
        end
        close(h);
        y_mat_fut_ex = NaN(nDraws*nParamDraws,size(y_mat,2)); % This stores all realizations for the ITERATED
        st_it = NaN(nDraws*nParamDraws,size(y_mat,2));
        st_it_t = NaN(nDraws*nParamDraws,size(y_mat,2));
        
        st_it_temp_OR = st_it_temp; st_it_temp_t_OR = st_it_temp_t; % Just storing the originals
        
        for jj=1:size(y_mat,2)
            for dd=1:nParamDraws
                for uu=1:nDraws
                    if st_it_temp(uu,dd,jj) ==1 % good regime
                        st_it_temp(uu,dd,jj) = 1;
                    elseif st_it_temp(uu,dd,jj) ==2 % bad regime
                        st_it_temp(uu,dd,jj) = 0;
                    end
                     if st_it_temp_t(uu,dd,jj) ==1 % good regime
                        st_it_temp_t(uu,dd,jj) = 1;
                    elseif st_it_temp_t(uu,dd,jj) ==2 % bad regime
                        st_it_temp_t(uu,dd,jj) = 0;
                     end
                end
            end
        end
        
        for rr=1:nDraws
            y_mat_fut_ex(rr*nParamDraws - nParamDraws+1:rr*nParamDraws,:) = squeeze(y_mat_fut_ex_temp(rr,:,:));
            st_it(rr*nParamDraws - nParamDraws+1:rr*nParamDraws,:) = squeeze(st_it_temp(rr,:,:));
            st_it_t(rr*nParamDraws - nParamDraws+1:rr*nParamDraws,:) = squeeze(st_it_temp_t(rr,:,:));
        end
        st_it_50 =     mean(st_it)';
        st_it_t_50 =     mean(st_it_t)';
        dY_25_fut_ex = prctile(y_mat_fut_ex,25)'; dY_75_fut_ex = prctile(y_mat_fut_ex,75)';
        dY_10_fut_ex = prctile(y_mat_fut_ex,10)'; dY_90_fut_ex = prctile(y_mat_fut_ex,90)';
        
        
        
        
        if exist([sim_folder 'results_direct.mat'],'file')==2
            load([sim_folder 'results_direct.mat'])
            if exist([sim_folder 'results_direct_samp.mat'],'file')==2;load([sim_folder 'results_direct_samp.mat']);end
            
            y_mat = y_fit';
            size_y = size(y_mat,2);
            
            
            %% EXAMPLE DRAW
            nDraws      = 10;           % Number of simulations per parameter draw
            nParamDraws = samp.options.N;    % Number of parameter draws
            y_mat_fut_ex2_temp = NaN(nDraws,nParamDraws,size(y_mat,2)); % This stores all realizations for the direct
            st_dir_temp = NaN(nDraws,nParamDraws,size(y_mat,2));
            h = waitbar(0,'Calculating paths for the direct version');
        ff_temp_par1 = Res_iterated.FF(example_draw,:);
        mf_temp_par1 = Res_iterated.MF(example_draw,:);
        st_temp_par1 = st_mat(example_draw,:);           
            for jj=13:size(y_mat,2)
                waitbar(jj/size(y_mat,2),h,'Calculating paths for the direct version')
                f_temp = ff_temp_par1(jj-12:jj);
                m_temp = mf_temp_par1(jj-12:jj);
                st_temp_par = st_temp_par1(jj);
                parfor dd=1:nParamDraws
                    for uu=1:nDraws
                        s_temp = [st_temp_par;NaN(12,1)];
                        
                        for ee=2:13 % Construct states, mf and ff for every period from t-12 to t, then check the state at t and construct the direct GDP (t+1 to t+12)
                            
                            p12 = 1/(1+exp(samp.a12(dd)-samp.b12(dd)*(f_temp(ee))+samp.c12(dd)*(m_temp(ee))));
                            p21 = 1/(1+exp(samp.a21(dd)+samp.b21(dd)*(f_temp(ee))-samp.c21(dd)*(m_temp(ee))));
                            
                            p11 = 1 - p12; % probability of remaining in normal
                            p22 = 1 - p21; % probability of remaining in bad
                            
                            
                            udraw = rand(1);
                            
                            if s_temp(ee-1) == 1 % started in good regime
                                if udraw > p11
                                    s_temp(ee) = 2; % switch from good to bad
                                else
                                    s_temp(ee) = 1; % don't switch and remain in good
                                end
                            else % start in bad regime
                                if udraw > p22
                                    s_temp(ee) = 1; % switch from bad to good
                                else
                                    s_temp(ee) = 2; % don't switch and remain in bad
                                end
                                
                            end
                            
                            if ee==13
                                eta2 = randn(1,1); % GDP shock
                                st_dir_temp(uu,dd,jj) = s_temp(ee);
                                
                                
                                if s_temp(ee)==2
                                    y_mat_fut_ex2_temp(uu,dd,jj) = samp.c_3_1_sync_2(dd)+samp.a0_3_1_sync_2(dd)*f_temp(ee)*(-1) +samp.a0_3_2_sync_2(dd)*m_temp(ee)*(-1) +samp.s_3_3_sync_2(dd)*eta2;
                                else
                                    y_mat_fut_ex2_temp(uu,dd,jj) = samp.c_3_1_sync_1(dd)+samp.a0_3_1_sync_1(dd)*f_temp(ee)*(-1) +samp.a0_3_2_sync_1(dd)*m_temp(ee)*(-1) +samp.s_3_3_sync_1(dd)*eta2;
                                end
                                
                            end
                        end
                    end
                end
            end
            close(h);
            
            st_dir_temp_OR = st_dir_temp; % Just storing the original 
            
            for jj=1:size(y_mat,2)
                for dd=1:nParamDraws
                    for uu=1:nDraws
                        if st_dir_temp(uu,dd,jj) ==1 % good regime
                            st_dir_temp(uu,dd,jj) = 1;
                        elseif st_dir_temp(uu,dd,jj) ==2 % bad regime
                            st_dir_temp(uu,dd,jj) = 0;
                        end
                    end
                end
            end
            
            y_mat_fut_ex2 = NaN(nDraws*nParamDraws,size(y_mat,2)); % This stores all realizations for the DIRECT
            st_dir = NaN(nDraws*nParamDraws,size(y_mat,2));
            
            for rr=1:nDraws
                y_mat_fut_ex2(rr*nParamDraws - nParamDraws+1:rr*nParamDraws,:) = squeeze(y_mat_fut_ex2_temp(rr,:,:));
                st_dir(rr*nParamDraws - nParamDraws+1:rr*nParamDraws,:) = squeeze(st_dir_temp(rr,:,:));
            end
            
            st_dir_50 =     mean(st_dir)';
            dY_25_fut_ex2 = prctile(y_mat_fut_ex2,25)'; dY_75_fut_ex2 = prctile(y_mat_fut_ex2,75)';
            dY_10_fut_ex2 = prctile(y_mat_fut_ex2,10)'; dY_90_fut_ex2 = prctile(y_mat_fut_ex2,90)';
            
            size_ex = 300+13;
            fig=figure('Units','normalized','Position', [0,0,1.2,0.9]); clf;
            hold on
            l1=plot(13:size_ex, dY_10_fut_ex(13:size_ex),'--k','Color',colors(5,:),'LineWidth', 1.5,'DisplayName','Iterated draw 10th');
            l4=plot(13:size_ex, dY_90_fut_ex(13:size_ex),'--k','Color',colors(55,:),'LineWidth', 1.5,'DisplayName','Iterated draw 90th');
            l11=plot(13:size_ex, dY_10_fut_ex2(13:size_ex),'-k','Color',colors(5,:),'LineWidth', 1.5,'DisplayName','Direct draw 10th');
            l44=plot(13:size_ex, dY_90_fut_ex2(13:size_ex),'-k','Color',colors(55,:),'LineWidth', 1.5,'DisplayName','Direct draw 90th');
            l111=plot(13:size_ex, dY_10_fut_ex_dgp(13:size_ex),'-.k','Color',colors(5,:),'LineWidth', 1.5,'DisplayName','DGP draw 10th');
            l444=plot(13:size_ex, dY_90_fut_ex_dgp(13:size_ex),'-.k','Color',colors(55,:),'LineWidth', 1.5,'DisplayName','DGP draw 90th');
            %             l2=plot(13:size_ex, Res_direct.y_mat(example_draw,14:size_ex+1),'-k','LineWidth', 1.5,'DisplayName','Data');
            %             legend([l1 l4 l11 l44 l111 l444 l2],'Orientation','Vertical','Location','Best','interpreter','Latex');legend boxoff;
            legend([l11 l44 l1 l4 l111 l444],'Orientation','Vertical','Location','Best','interpreter','Latex');legend boxoff;
            set(gca,'children',flipud(get(gca,'children')))
            hold off
            ylabel('Percent','interpreter','Latex','fontsize',10)
            title('Comparison GDP distribution 1-year ahead (single draw)','FontSize',16','Interpreter','Latex');
            axis tight
            tightfig;
            
            if saveit==1
                print('-dpdf',fig,[sim_folder 'CompareGDP_draw_direct_iterated_par_unc'],'-bestfit');
                saveas(fig,sprintf('%s.png',[sim_folder 'CompareGDP_draw_direct_iterated_par_unc']));
            end
            
            
            fig=figure('Units','normalized','Position', [0,0,1.2,0.9]); clf;
            hold on
            l1=plot(13:size_ex, st_it_t_50(13:size_ex),'--k','Color',colors(5,:),'LineWidth', 1.5,'DisplayName','Iterated draw state (mean)');
            l11=plot(13:size_ex, st_dir_50(13:size_ex),'-k','Color',colors(5,:),'LineWidth', 1.5,'DisplayName','Direct draw state (mean)');
%             l111=plot(13:size_ex, st_dgp_50(13:size_ex),'-.k','Color',colors(5,:),'LineWidth', 1.5,'DisplayName','DGP draw state (mean)');
            l111=plot(13:size_ex, st_dgp_t(example_draw,13:size_ex),'-k','LineWidth', 1.5,'DisplayName','DGP draw state (mean)');
%                         l2=plot(13:size_ex, Res_direct.y_mat(example_draw,14:size_ex+1),'-k','LineWidth', 1.5,'DisplayName','Data');
            %             legend([l1 l4 l11 l44 l111 l444 l2],'Orientation','Vertical','Location','Best','interpreter','Latex');legend boxoff;
            legend([l11 l1 l111],'Orientation','Vertical','Location','Best','interpreter','Latex');legend boxoff;
            set(gca,'children',flipud(get(gca,'children')))
            hold off
            ylabel('Percent','interpreter','Latex','fontsize',10)
            title('Comparison states (single draw)','FontSize',16','Interpreter','Latex');
            axis tight
            tightfig;
            
            if saveit==1
                print('-dpdf',fig,[sim_folder 'Compare_st_draw_direct_iterated_par_unc'],'-bestfit');
                saveas(fig,sprintf('%s.png',[sim_folder 'Compare_st_draw_direct_iterated_par_unc']));
            end
        end
    end
end




toc;
