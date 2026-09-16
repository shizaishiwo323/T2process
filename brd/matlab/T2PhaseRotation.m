function [Amplitude,Noise]=T2PhaseRotation(DataReal,DataImaginary)
% DataReal=abs(DataReal);
% DataImaginary=abs(DataImaginary);
sre=sum(DataReal(1:20));
sim=sum(DataImaginary(1:20));
alpha=atan(sim/sre);
if(sre<0)
    alpha=pi+alpha;
end
Amplitude=DataReal*cos(alpha)+DataImaginary*sin(alpha);
% if(Amplitude(1)<0)
%    Amplitude = -Amplitude;
% end                               %·ÀÖ¹·ûºÅ³ö´í 2015.01.08 by Shannon

Noise = DataReal*sin(alpha)-DataImaginary*cos(alpha);                       %http://www.google.com/patents/US5291137  Eq.(23)
%figure;plot(SampleTime,Amplitude,'-r',SampleTime,Noise,'-g');