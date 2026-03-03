#!/usr/bin/env wolframscript
(* ::Package:: *)

rutaPaquete = "/home/miguel.gonzalez/Documents/chaos_meet_channels/ja_files/wls/QMB.wl";
rutaGuardar = "/home/miguel.gonzalez/Documents/chaos_meet_channels/ja_files/wls/";


Quiet[Get[rutaPaquete]];


n=L=11; J=U=1.;
H=BoseHubbardHamiltonian[n,L,J,U,SymmetricSubspace->"EvenParity"];


\[Mu]=Tr[H]/Length[H];
\[Sigma]=Sqrt[Total[H["ExplicitValues"]^2]/Length[H]-\[Mu]^2];


d=Length[H];
deltaE=0.01\[Sigma];
k=Ceiling[d*PDF[NormalDistribution[\[Mu],\[Sigma]],\[Mu]]*deltaE];


Print["Voy a empezar la diagonalizaci\[OAcute]n de "<>ToString[k]<>" eigenvalores."];


startTime = AbsoluteTime[];


evals=Sort@Eigenvalues[H,k,Method->{"Arnoldi","Shift"->\[Mu],"Criteria"->"Magnitude"}];


endTime = AbsoluteTime[];
time = endTime-startTime;


Print["Termin\[EAcute], me tard\[EAcute] "<>ToString[NumberForm[time, {Infinity, 0}]]]


Export[rutaGuardar<>"prueba.csv",evals];
