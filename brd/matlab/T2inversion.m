clc;clear 
global A1
T2min=1;  %  unit ms,T2 min
T2max=10000; %  unit ms,T2 min
numT2=1000  ; %choose time points
T2=logspace(log10(T2min),log10(T2max),numT2); 
alp=1;
[Pick_time,Pick_date]=AmplitudeSample(A1(:,1),A1(:,2),length(A1(:,1)),0);  
T2Array=exp(-Pick_time*T2.^(-1));    
fT2= brd1(T2Array,Pick_date,alp);   
T2=T2';                                     