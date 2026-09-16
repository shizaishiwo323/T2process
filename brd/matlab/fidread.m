function [Modu,time,datareal,dataimag] = fidread(FileName)
C = load(FileName);
time = C(:,4);
Modu = C(:,3);
datareal=C(:,1);
dataimag=C(:,2);