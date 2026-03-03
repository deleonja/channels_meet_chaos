#!/usr/bin/env wolframscript
(* ::Package:: *)

(* ::Section:: *)
(*Anotaciones*)


(* ::Text:: *)
(*Modifiqu\[EAcute]*)
(*- L*)
(*- kernels*)
(*- points*)
(**)
(*Crear carpeta L_8*)
(**)


(* ::Section:: *)
(*Par\[AAcute]metros (s\[OAcute]lo modificar esta secci\[OAcute]n)*)


(* ::Text:: *)
(*Parametros del sistema*)


L = 8;(* espines *)


(* ::Text:: *)
(*Tiempos*)


{t0, tf, tn}={0., 50., 0.5};(* t inicial, t final, n\[UAcute]mero de puntos *)


(* ::Text:: *)
(*Numero de kernels a utilizar en la paralelizacion*)


(*kernels = 30;*)
kernels = {1, 20, 40, 30, 10};


(* ::Section:: *)
(*Ac\[AAcute] comienza el c\[AAcute]lculo*)


(* ::Text:: *)
(*Fijar directorio, cargar paquete QMB y encender todos los kernels a utilizar*)


SetDirectory["/home/jadeleon/Documents/chaos_meets_channels/ja_files/data/haar_avg_choi_purity/heisenberg/L_"<>ToString[L]];
Get["../../../../../Mathematica_packages/QMB.wl"];


(* ::Text:: *)
(*Inicializar variables*)


tiempos = Table[t, {t, t0, tf, tn}];

points = Flatten[Table[{i, j} , {j, 30}, {i, Subdivide[0.05, 5, 29]}], 1][[279;;]];
lenpoints = Length[points];

(* Pauli strings *)
pauliIndices = Tuples[Range[0,3],L-1];

(* Constantes que aparecen dentro de la suma del promedio de Haar *)
constants = (1/2)^2*(1/12)^(L-1)*Power[3., (L-1) - Count[#, x_/; x!=0]] & /@ pauliIndices;

(* Lista de tiempos por cada iteraci\[OAcute]n del Do *)
times={};

dimH=2^L;
halfDimH=dimH/2;
halfDimHPlusOne=dimH/2+1;


L=3;
(1/2)^2*(1/12)^(L-1)*Power[3., (L-1) - Count[#, x_/; x!=0]]&[{0,0}]


numkernels = Total[kernels];
kernels = Prepend[StringJoin[#1, ToString[#2]]&@@@Transpose[{{"ssh://nodo1/?","ssh://nodo2/?","ssh://nodo3/?","ssh://nodo4/?"}, kernels[[2;;]]}], kernels[[1]]];
LaunchKernels[kernels];
Print["N\[UAcute]mero de kernels listos: ", Length[ParallelKernels[]], "/", numkernels];

Do[
startTime = AbsoluteTime[];

{h, j} = points[[i]];(* j indexa la realizaci\[OAcute]n de h *)
hlist = RandomReal[{-h, h}, L];

(* Crear Hamiltoniano y diagonalizar *)
H = HeisenbergXXXwNoise[hlist, L];
{eigenvalues, eigenvectors} = Chop[Eigensystem[H]];

(* Calcular la matriz de cambio de base de la de eigenenerg\[IAcute]as a la computacional *)
P = Transpose[eigenvectors];

(* Operador de evoluci\[OAcute]n *)
ClearAll[U]; U[t_] := P . DiagonalMatrix[Exp[-I*eigenvalues*t]] . ConjugateTranspose[P];

(* Calcular valor esperado de Haar de la pureza de Choi para cada t *)
DistributeDefinitions[U, Pauli, L];
choipurity = {}; SetSharedVariable[choipurity];
ParallelDo[
	t1 = AbsoluteTime[];
	
	(* Asignar el operador de evoluci\[OAcute]n a una variable (para no repetir en cada t\[EAcute]rmino de la suma del valor esperado de Haar) *)
	u = U[t]; uDg = ConjugateTranspose[u];
	{{u11, u12}, {u21, u22}} = {{u[[1;;halfDimH, 1;;halfDimH]], u[[1;;halfDimH, halfDimHPlusOne;;dimH]]}, {u[[halfDimHPlusOne;;dimH, 1;;halfDimH]], u[[halfDimHPlusOne;;dimH, halfDimHPlusOne;;dimH]]}};
	{{uDg11, uDg12}, {uDg21, uDg22}} = {{uDg[[1;;halfDimH, 1;;halfDimH]], uDg[[1;;halfDimH, halfDimHPlusOne;;dimH]]}, {uDg[[halfDimHPlusOne;;dimH, 1;;halfDimH]], uDg[[halfDimHPlusOne;;dimH, halfDimHPlusOne;;dimH]]}};
	(*--------------------------------------------------------*)
	
	(*DistributeDefinitions[u11, u12, u21, u22, uDg11, uDg12, uDg21, uDg22];*)
	haarAvgChoiPurity = 
	Total[
		Table[
		With[{c = constants[[i]]},
			(* Calcular \Tr_S( U(t).\sigma .U^\dagger(t) ) *)
			A = u11 . # . uDg11 + u12 . # . uDg21 + u21 . # . uDg12 + u22 . # . uDg22 &[Pauli[IntegerDigits[i-1, 4, L - 1]]];
			(* Calcular la pureza de A y multiplicarlo por su respectiva constante *)
			Chop[c * Total[Abs[A]^2, 2]]
		]
		, {i, 4^(L-1)}]
	];
	(*ClearDistributedDefinitions[u11, u12, u21, u22, uDg11, uDg12, uDg21, uDg22];*)
	
	t2 = AbsoluteTime[];
	Print["h = "<>ToString[NumberForm[h, {Infinity, 2}]]<>". t = "<>ToString[NumberForm[t, {Infinity, 1}]]<>": "<>ToString[NumberForm[t2-t1, {Infinity, 2}]]<>" s"];
	AppendTo[choipurity, {t, haarAvgChoiPurity}];
,{t, tiempos}];

(* Exportar datos *)
filename = "h_"<>ToString[NumberForm[h, {Infinity, 2}]]<>"_"<>StringPadLeft[ToString[j], 2, "0"]<>".csv";
Export[filename, Prepend[SortBy[choipurity, First], {"t", "valor esperado de Haar de la pureza de Choi"}], "CSV"];
(*---------------*)

endTime = AbsoluteTime[];
time = endTime-startTime;
remainingIterations = (lenpoints - i);
AppendTo[times, time];
Print[DateString[], ". ", "(h="<>ToString[NumberForm[h, {Infinity, 2}]]<>", j="<>ToString[NumberForm[j, {Infinity, 2}]]<>") done. ", ToString[i], "/", lenpoints,": ", ToString[NumberForm[time,{Infinity,0}]], " s. Terminar\[AAcute]: ", DateString[DatePlus[Now,Quantity[remainingIterations*Mean[times]/3600,"Hours"]]]];

,{i, lenpoints}]; 

CloseKernels[];
