function plot_fan_gdp_alg0exante(pctl_all,periods,filename,supt)
time = linspace(1,periods,periods)';
patchx = [1:periods periods:-1:1]';
lb99 = [0.7137, 0.8667, 0.8902];
lb95 = [0.4275, 0.6706, 0.7608];
lb90 = [0.3882, 0.5647, 0.7216];
db = [38, 49, 109]/256;
lr1 = [0.8314, 0.6549, 0.6549];
lr5 = [0.8000, 0.5922, 0.5922];
lr10 = [0.6392, 0.3725, 0.3725];
dr = [174,0,0]/256;

cmedian = [dr; db];

lstyle = {'-','--'};

myalpha25 = 0.75;
myalpha10 = 0.65;
myalpha5 = 0.55;
myalpha1 = 0.4;

fields = fieldnames(pctl_all);


figure('Position',[0, 0, 1200, 800]);


y_ub = 0.5;
y_lb = -2;

for ii=1:length(fields)
    
    % Get percentiles 
    pctl_in= pctl_all.(fields{ii});

    min_y = min([min(min(pctl_in.f_shock.y)); min(min(pctl_in.m_shock.y)); min(min(pctl_in.y_shock.y))]);
    max_y = max([max(max(pctl_in.f_shock.y)); max(max(pctl_in.m_shock.y)); max(max(pctl_in.y_shock.y))]);
    
    if min_y < y_lb
        y_lb = floor(min_y);
    end
    
    if max_y > y_ub
        y_ub = ceil(max_y);
    end
end


for ii=1:length(fields)
    
    % Get percentiles 
    pctl_in= pctl_all.(fields{ii});
    
    
    
    subplot(2,3,1); hold on;
%     patch(patchx,[pctl_in.f_shock.y(1,:)'; flipud(pctl_in.f_shock.y(2,:)')],lr1,'EdgeColor','none','FaceAlpha',myalpha1,'DisplayName','1st pctl');
%     patch(patchx,[pctl_in.f_shock.y(2,:)'; flipud(pctl_in.f_shock.y(3,:)')],lr5,'EdgeColor','none','FaceAlpha',myalpha5,'DisplayName','5th pctl')
%     patch(patchx,[pctl_in.f_shock.y(3,:)'; flipud(pctl_in.f_shock.y(4,:)')],lr10,'EdgeColor','none','FaceAlpha',myalpha10,'DisplayName','10th pctl')
%     patch(patchx,[pctl_in.f_shock.y(4,:)'; flipud(pctl_in.f_shock.y(5,:)')],dr,'EdgeColor','none','FaceAlpha',myalpha25,'DisplayName','25th pctl')
%     patch(patchx,[pctl_in.f_shock.y(5,:)'; flipud(pctl_in.f_shock.y(6,:)')],db,'EdgeColor','none','FaceAlpha',myalpha25,'DisplayName','75th pctl')
%     patch(patchx,[pctl_in.f_shock.y(6,:)'; flipud(pctl_in.f_shock.y(7,:)')],lb90,'EdgeColor','none','FaceAlpha',myalpha10,'DisplayName','90th pctl')
%     patch(patchx,[pctl_in.f_shock.y(7,:)'; flipud(pctl_in.f_shock.y(8,:)')],lb95,'EdgeColor','none','FaceAlpha',myalpha5,'DisplayName','95th pctl')
%     patch(patchx,[pctl_in.f_shock.y(8,:)'; flipud(pctl_in.f_shock.y(9,:)')],lb99,'EdgeColor','none','FaceAlpha',myalpha1,'DisplayName','99th pctl')
    plot(time,pctl_in.f_shock.y(5,:)','LineWidth',2.5,'Color',cmedian(ii,:),'DisplayName',fields{ii},'LineStyle',lstyle{ii});
    xticks([3 6 9 12]); xlim([1 12]); ylim([y_lb y_ub]);
    set(gca,'FontSize',14);
    hold off;
    ylabel('- Financial Shock');
    title('GDP response')
    
    subplot(2,3,2); hold on;
%     patch(patchx,[pctl_in.m_shock.y(1,:)'; flipud(pctl_in.m_shock.y(2,:)')],lr1,'EdgeColor','none','FaceAlpha',myalpha1,'DisplayName','1st pctl');
%     patch(patchx,[pctl_in.m_shock.y(2,:)'; flipud(pctl_in.m_shock.y(3,:)')],lr5,'EdgeColor','none','FaceAlpha',myalpha5,'DisplayName','5th pctl')
%     patch(patchx,[pctl_in.m_shock.y(3,:)'; flipud(pctl_in.m_shock.y(4,:)')],lr10,'EdgeColor','none','FaceAlpha',myalpha10,'DisplayName','10th pctl')
%     patch(patchx,[pctl_in.m_shock.y(4,:)'; flipud(pctl_in.m_shock.y(5,:)')],dr,'EdgeColor','none','FaceAlpha',myalpha25,'DisplayName','25th pctl')
%     patch(patchx,[pctl_in.m_shock.y(5,:)'; flipud(pctl_in.m_shock.y(6,:)')],db,'EdgeColor','none','FaceAlpha',myalpha25,'DisplayName','75th pctl')
%     patch(patchx,[pctl_in.m_shock.y(6,:)'; flipud(pctl_in.m_shock.y(7,:)')],lb90,'EdgeColor','none','FaceAlpha',myalpha10,'DisplayName','90th pctl')
%     patch(patchx,[pctl_in.m_shock.y(7,:)'; flipud(pctl_in.m_shock.y(8,:)')],lb95,'EdgeColor','none','FaceAlpha',myalpha5,'DisplayName','95th pctl')
%     patch(patchx,[pctl_in.m_shock.y(8,:)'; flipud(pctl_in.m_shock.y(9,:)')],lb99,'EdgeColor','none','FaceAlpha',myalpha1,'DisplayName','99th pctl')
    plot(time,pctl_in.m_shock.y(5,:)','LineWidth',2.5,'Color',cmedian(ii,:),'DisplayName',fields{ii},'LineStyle',lstyle{ii});
    xticks([3 6 9 12]);xlim([1 12]);  ylim([y_lb y_ub]);
    set(gca,'FontSize',14);
    hold off;
    ylabel('- Macro Shock');
    title('GDP response')
    
    subplot(2,3,3); hold on;
%     patch(patchx,[pctl_in.y_shock.y(1,:)'; flipud(pctl_in.y_shock.y(2,:)')],lr1,'EdgeColor','none','FaceAlpha',myalpha1,'DisplayName','1st pctl');
%     patch(patchx,[pctl_in.y_shock.y(2,:)'; flipud(pctl_in.y_shock.y(3,:)')],lr5,'EdgeColor','none','FaceAlpha',myalpha5,'DisplayName','5th pctl')
%     patch(patchx,[pctl_in.y_shock.y(3,:)'; flipud(pctl_in.y_shock.y(4,:)')],lr10,'EdgeColor','none','FaceAlpha',myalpha10,'DisplayName','10th pctl')
%     patch(patchx,[pctl_in.y_shock.y(4,:)'; flipud(pctl_in.y_shock.y(5,:)')],dr,'EdgeColor','none','FaceAlpha',myalpha25,'DisplayName','25th pctl')
%     patch(patchx,[pctl_in.y_shock.y(5,:)'; flipud(pctl_in.y_shock.y(6,:)')],db,'EdgeColor','none','FaceAlpha',myalpha25,'DisplayName','75th pctl')
%     patch(patchx,[pctl_in.y_shock.y(6,:)'; flipud(pctl_in.y_shock.y(7,:)')],lb90,'EdgeColor','none','FaceAlpha',myalpha10,'DisplayName','90th pctl')
%     patch(patchx,[pctl_in.y_shock.y(7,:)'; flipud(pctl_in.y_shock.y(8,:)')],lb95,'EdgeColor','none','FaceAlpha',myalpha5,'DisplayName','95th pctl')
%     patch(patchx,[pctl_in.y_shock.y(8,:)'; flipud(pctl_in.y_shock.y(9,:)')],lb99,'EdgeColor','none','FaceAlpha',myalpha1,'DisplayName','99th pctl')
    plot(time,pctl_in.y_shock.y(5,:)','LineWidth',2.5,'Color',cmedian(ii,:),'DisplayName',fields{ii},'LineStyle',lstyle{ii});
    xticks([3 6 9 12]);xlim([1 12]);  ylim([y_lb y_ub]);
    set(gca,'FontSize',14);
    hold off;
    lgd = legend('Location','eastoutside'); legend boxoff
    ylabel('- GDP Shock');
    title('GDP response')
    
    subplot(2,3,4)
    plot(pctl_in.p_bad_path_shock.f,'LineWidth',2.5,'Color',cmedian(ii,:),'DisplayName',fields{ii},'LineStyle',lstyle{ii}); hold on;
%     plot(pctl_in.p_bad_path_shockbase.f,'LineWidth',2,'Color','k','DisplayName','Baseline'); hold on;
%     legend('Location','N','Orientation','Horizontal');
    title('p(s=bad)'); legend('hide')
    xticks([3 6 9 12]); xlim([1 12]); box off;
    set(gca,'FontSize',14);
    ylim([0,1.1]);
    
    subplot(2,3,5)
    plot(pctl_in.p_bad_path_shock.m,'LineWidth',2.5,'Color',cmedian(ii,:),'DisplayName',fields{ii},'LineStyle',lstyle{ii}); hold on;
%     plot(pctl_in.p_bad_path_shockbase.m,'LineWidth',2,'Color','k','DisplayName','Baseline'); hold on;
%     legend('Location','N','Orientation','Horizontal');
    title('p(s=bad)'); legend('hide')
    xticks([3 6 9 12]); xlim([1 12]); box off;
    set(gca,'FontSize',14);
    ylim([0,1.1]);
    
    subplot(2,3,6)
    plot(pctl_in.p_bad_path_shock.y,'LineWidth',2.5,'Color',cmedian(ii,:),'DisplayName',fields{ii},'LineStyle',lstyle{ii}); hold on;
%     plot(pctl_in.p_bad_path_shockbase.y,'LineWidth',2,'Color','k','DisplayName','Baseline'); hold on;
%     legend('Location','N','Orientation','Horizontal');
    title('p(s=bad)'); legend('hide')
    xticks([3 6 9 12]); xlim([1 12]); box off;
    ylim([0,1.1]);
    set(gca,'FontSize',14);
end

set(lgd,'Position',[0.5 0.06 0.0 0.0],'Orientation','Horizontal');
%%
sgtitle(supt);
orient(gcf,'landscape');
% saveas(gcf,filename);

end