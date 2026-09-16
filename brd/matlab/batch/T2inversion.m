clc;clear
global T02
T2min=1;  %  unit ms,T2 min
T2max=1000; %  unit ms,T2 min
numT2=1000  ; %choose time points
T2=logspace(log10(T2min),log10(T2max),numT2); 
alp=1; 
[Pick_time,Pick_date]=AmplitudeSample(T02(:,1),T02(:,2),4500,0);  
T2Array=exp(-Pick_time*T2.^(-1));    
fT2(:,1)= brd1(T2Array,Pick_date,alp);   
[Pick_time,Pick_date]=AmplitudeSample(T02(:,1),T02(:,3),158,0); 
T2Array=exp(-Pick_time*T2.^(-1));
fT2(:,2)= brd1(T2Array,Pick_date,alp);  
[Pick_time,Pick_date]=AmplitudeSample(T02(:,1),T02(:,4),158,0); 
T2Array=exp(-Pick_time*T2.^(-1));
fT2(:,3)= brd1(T2Array,Pick_date,alp);  
[Pick_time,Pick_date]=AmplitudeSample(T02(:,1),T02(:,5),70,0); 
T2Array=exp(-Pick_time*T2.^(-1));
fT2= brd1(T2Array,Pick_date,alp)+fT2;  
[Pick_time,Pick_date]=AmplitudeSample(T02(:,1),T02(:,6),70,0); 
T2Array=exp(-Pick_time*T2.^(-1));
fT2= brd1(T2Array,Pick_date,alp)+fT2;  
T2=T2';                                     