function [SampleTime,Amplitude]=AmplitudeSample(SampleTime,Amplitude,SampleNumber,CutNumber)
% 数据抽提
% 输入：
%   SampleTime,Amplitude  回波串数据
%   SampleNumber：选点个数
%   CutNumber：前端剔除点数  （避免使用零荡数据，没有零荡时设置为0）
% 输出：
%   SampleTime,Amplitude

% 转置是为了保证数据存储顺序与C++数据存储方式一致
SampleTime=SampleTime';
Amplitude=Amplitude';
l=length(SampleTime); %数据长度
if(SampleNumber<l)
    SampleIndex=logspace(log(CutNumber+1)*log10(exp(1)),log(l)*log10(exp(1)),SampleNumber)'; %对数布点（换底  log->ln）
    tp=(CutNumber+1:1:SampleNumber+CutNumber)';
% 修改, 周小龙，2015-05-19
  % 删除
%     l1=round(SampleIndex(SampleIndex>tp));
%     Index=[tp(SampleIndex<=tp);l1];
  % 删除结束
  % 增加
    th = find(SampleIndex<=tp,1,'last');
    Index = [tp(1:th);round(SampleIndex(th+1:end))];                       % 风险：参数设置不合理（CutNumber过大），导致round部分出现重复值
  % 增加结束
% 修改结束
    SampleTime=SampleTime(Index)';
    Amplitude=Amplitude(Index)';
else
    SampleTime=SampleTime';
    Amplitude=Amplitude';
end