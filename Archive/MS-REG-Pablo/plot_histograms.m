set(0,'defaulttextinterpreter','latex')
set(0,'defaultLegendInterpreter','latex');
set(0,'defaultAxesTickLabelInterpreter','latex');


fig=figure('Name','Histograms'); clf;
subplot(3,2,1)
hold on
l1=histogram(s_3_3_sync_1(correct,:),50,'EdgeColor',colors(60,:),'FaceColor',colors(60,:),'DisplayName','S.d. regime 1');
l2=histogram(s_3_3_sync_2(correct,:),50,'EdgeColor',colors(25,:),'FaceColor',colors(25,:),'DisplayName','S.d. regime 2');
if dir_or_it ==2
    l3=xline(dgp.s_3_3_sync_1,'Color','k','LineWidth', 1.5,'DisplayName','DGPs');
    xline(dgp.s_3_3_sync_2,'Color','k','LineWidth', 1.5);
    legend([l1 l2 l3],'Orientation','Vertical','Location','Best','interpreter','Latex');legend boxoff;
elseif dir_or_it ==1
    legend([l1 l2],'Orientation','Vertical','Location','Best','interpreter','Latex');legend boxoff;
end
set(gca,'children',flipud(get(gca,'children')))
hold off
axis tight
subplot(3,2,2)
hold on
l1=histogram(a0_3_1_sync_1(correct,:)*(-1),50,'EdgeColor',colors(60,:),'FaceColor',colors(60,:),'DisplayName','$f_t$ regime 1');
l2=histogram(a0_3_1_sync_2(correct,:)*(-1),50,'EdgeColor',colors(25,:),'FaceColor',colors(25,:),'DisplayName','$f_t$ regime 2');
if dir_or_it ==2
    l3=xline(dgp.a0_3_1_sync_1,'Color','k','LineWidth', 1.5,'DisplayName','DGPs');
    xline(dgp.a0_3_1_sync_2,'Color','k','LineWidth', 1.5);
    legend([l1 l2 l3],'Orientation','Vertical','Location','Best','interpreter','Latex');legend boxoff;
elseif dir_or_it ==1
    legend([l1 l2],'Orientation','Vertical','Location','Best','interpreter','Latex');legend boxoff;
end
set(gca,'children',flipud(get(gca,'children')))
hold off
axis tight
subplot(3,2,3)
hold on
l1=histogram(c_3_1_sync_1(correct,:),50,'EdgeColor',colors(60,:),'FaceColor',colors(60,:),'DisplayName','Constant regime 1');
l2=histogram(c_3_1_sync_2(correct,:),50,'EdgeColor',colors(25,:),'FaceColor',colors(25,:),'DisplayName','Constant regime 2');
if dir_or_it ==2
    l3=xline(dgp.c_3_1_sync_1,'Color','k','LineWidth', 1.5,'DisplayName','DGPs');
    xline(dgp.c_3_1_sync_2,'Color','k','LineWidth', 1.5);
    legend([l1 l2 l3],'Orientation','Vertical','Location','Best','interpreter','Latex');legend boxoff;
elseif dir_or_it ==1
    legend([l1 l2],'Orientation','Vertical','Location','Best','interpreter','Latex');legend boxoff;
end
set(gca,'children',flipud(get(gca,'children')))
hold off
axis tight
subplot(3,2,4)
hold on
l1=histogram(a0_3_2_sync_1(correct,:)*(-1),50,'EdgeColor',colors(60,:),'FaceColor',colors(60,:),'DisplayName','$m_t$ regime 1');
l2=histogram(a0_3_2_sync_2(correct,:)*(-1),50,'EdgeColor',colors(25,:),'FaceColor',colors(25,:),'DisplayName','$m_t$ regime 2');
if dir_or_it ==2
    l3=xline(dgp.a0_3_2_sync_1,'Color','k','LineWidth', 1.5,'DisplayName','DGPs');
    xline(dgp.a0_3_2_sync_2,'Color','k','LineWidth', 1.5);
    legend([l1 l2 l3],'Orientation','Vertical','Location','Best','interpreter','Latex');legend boxoff;
elseif dir_or_it ==1
    legend([l1 l2],'Orientation','Vertical','Location','Best','interpreter','Latex');legend boxoff;
end
set(gca,'children',flipud(get(gca,'children')))
hold off
axis tight
tightfig;
if saveit==1
    print('-dpdf',fig,[sim_folder '/' model 'Histograms'],'-bestfit');
    saveas(fig,sprintf('%s.png',[sim_folder '/' model 'Histograms']));
end


%             title('Regime Coeficients (Estimated and DGP)','FontSize',16','Interpreter','Latex');









