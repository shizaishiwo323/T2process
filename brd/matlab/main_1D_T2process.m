%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    一维T2谱数据处理
%   输入数据为底层软件的fid（二进制格式，需知道文件格式）或上层软件fid（文本格式）
%   输出T2谱
%   需要的子函数4个：①fid读取子函数（ReadFid2对应底层软件fid文件；fidread对应上层软件fid文件）；②相位旋转子函数T2PhaseRotation；
%                    ③数据压缩子函数AmplitudeSample；④一维BRD反演子函数brd1
%   注意，本程序可批处理数据，批处理前提是SW、TE、NECH、P1、P2等采集参数都一致，如果上述参数任何一个不一致，只能选择一个一个处理
%   2023年5月 维也纳  吴飞 18516712218 f_wu@niumag.com
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all;
clear;
clc
%% Step1：采集参数赋值
SW=333.333 ;% 单位 kHz
TE=0.12;% 单位 ms
NECH=2000;% 单位 个
Ft_echo=31;%无量纲，回波串第一个回波峰点对应的数组中的序号，待处理数据该数值不清楚时，可先赋值10以内的数值，待回波峰点绘图后精确

%% Step2：反演参数赋值
T2min=0.01;  %  单位 ms,T2弛豫时间的最小值
T2max=10000; %  单位 ms,T2弛豫时间的最大值
numT2=1000   ; %  单位 个，T2弛豫时间布点的个数
T2=logspace(log10(T2min),log10(T2max),numT2); %单位 ms，T2布点
alp=0.1      ; %  无量纲，BRD反演平滑因子

%% Step3：提取fid数据
[FileName, PathName] = uigetfile({'*.Fid'},'文本数据读取','MultiSelect','on');  %选择要打开的数据，获取fid文件的文件名，顺序就是文件夹里的文件顺序
if ~iscell(FileName)
  FileName = {FileName};  
end
num=size(FileName,2); %批量文件的数量
for i=1:num
File = [PathName,FileName{1,i}];   % 按顺序打开fid文件
%[Real(:,i),Imag(:,i)]=ReadFid2(File); % 如果是底层控制软件输出的fid数据，需要用ReadFid2子程序打开，调用格式为 [DataReal,DataImaginary]=ReadFid2(FileName)，输入文件名，输出为交流电信号（核磁信号）的实部、虚部
%Modu(:,i)=abs(complex(Real(:,i),Imag(:,i))); %核磁信号模值信号
[~,~,Real(:,i),Imag(:,i)]=fidread(File); % 如果是底层控制软件输出的fid数据，需要用ReadFid2子程序打开，调用格式为 [DataReal,DataImaginary]=ReadFid2(FileName)，输入文件名，输出为交流电信号（核磁信号）的实部、虚部
Modu(:,i)=abs(complex(Real(:,i),Imag(:,i))); %核磁信号模值信号
end
DW=1/SW; % 单位 ms，dwell time，fid核磁信号相邻采样点时间间隔
time(:,1)=0:DW:DW*(size(Real,1)-1);

%% Step4：取回波峰点数据
figure   % 绘制其中一个fid信号，确定第1个回波的准确位置序号，Ft_echo
flag=1;  % 辅助判断取峰点准确性的fid信号的序号
plot(Modu(:,flag),'Color',[0 0 1]);  % 可在下一行语句加断点，准确确定Ft_echo并重新赋值后取消断点
Peak_position=floor( Ft_echo:TE*SW:Ft_echo+TE*SW*(NECH-1) );  % 每个回波在fid信号中位置的序号，注意位置必须是整数

Peak_Real(:,:)=Real(Peak_position,:); % 获取回波峰点的实部信号
Peak_Imag(:,:)=Imag(Peak_position,:); % 获取回波峰点的虚部信号
Peak_Modu(:,:)=Modu(Peak_position,:); % 获取回波峰点的模值信号

figure % 取峰点后，选择一条回波串绘制回波与fid模值信号，判断峰点取值准确性
plot(Modu(:,flag),'Color',[0 0 1]);hold on;plot(Peak_position,Peak_Modu(:,flag),'MarkerFaceColor',[1 0 0],'MarkerEdgeColor',[1 0 0],'MarkerSize',4,'Marker','square','LineStyle','--','Color',[1 0 0]);
legend('模值','峰点');
% 取峰点步骤判断无误后，进入下一处理步骤

%% Step5：相位旋转（目的是信噪分离），详细原理及步骤见邓克俊老师教材《核磁共振测井理论及应用》第4.3章节
for i=1:num
[Amp(:,i),Noise(:,i)]=T2PhaseRotation(Peak_Real(:,i),Peak_Imag(:,i)); %相位旋转子函数，调用规则为 T2PhaseRotation(回波峰点实部信号,回波峰点虚部信号)，返回值为信号通道、噪声通道
SNR(i)=Amp(1,i)/std(Noise(size(Noise,1)*0.6:end,i));   % SNR计算
end
Peak_time(:,1)=TE:TE:TE*NECH;  % 单位 ms，   峰点回波时间,列向量


%% Step6：T2反演，BRD解谱算法
Pick_num=200;  %回波串参与反演的点数
for  i=1:num
[Pick_time,Pick_date(:,i)]=AmplitudeSample(Peak_time,Amp(:,i),Pick_num,0);  % 数据压缩，选择部分数据点参与反演，调用格式AmplitudeSample(回波时间,回波幅度,参与反演点数,前端剔除点数（避免使用零荡数据，没有零荡时设置为0）);
T2Array=exp(-Pick_time*T2.^(-1));    % 构造一维T2谱反演系数矩阵，矩阵维度：Pick_num*numT2
fT2(:,i)= brd1(T2Array,Pick_date(:,i),alp);   % brd1为1维BRD反演算法，也即只有一个弛豫属性
                                         % 调用格式为brd1（反演系数矩阵，回波串幅度，平缓因子）； Pick_date=T2Array*fT2(:,i)，注意各矩阵维度匹配，Pick_date维度：Pick_num*1；T2Array维度：Pick_num*numT2
Pick_date_fit(:,i)=T2Array*fT2(:,i);   % 回波串拟合值
fiterro(i)=(((Pick_date(:,i)-Pick_date_fit(:,i))'*(Pick_date(:,i)-Pick_date_fit(:,i)))/(Pick_date(:,i)'*Pick_date(:,i)));   % 拟合误差计算
end


figure   % 绘制T2谱反演结果，验证拟合效果
subplot(1,2,1)
plot(T2,fT2);set(gca,'XScale','log');xlabel('T2/ms');ylabel('信号幅度')
subplot(1,2,2)
plot(Pick_time,Pick_date);%原始回波串
hold on;plot(Pick_time,Pick_date_fit,'MarkerFaceColor',[1 0 0],'MarkerEdgeColor',[1 0 0], 'MarkerSize',3,'Marker','pentagram','LineStyle','none');%原始回波串
set(gca,'XScale','log');xlabel('时间/ms');ylabel('信号幅度');
legend('原始','拟合');

figure   % 所有T2谱，这里的T2谱纵坐标还只是信号幅度，没有进行孔隙度换算
plot(T2,fT2);set(gca,'XScale','log');xlabel('T2/ms');ylabel('信号幅度')
legend('','','','','','');






