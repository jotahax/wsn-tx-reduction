clear all
close all

% Declaración de los elementos del texto para el split
comillas=char(34);
barra=char(47);
coma=char(44);
pcoma=char(59);
dpuntos=char(58);
novalinea=newline;
guio=char(45);
fle=char(62);
p1=char(40);
p2=char(41);

%%% Format fitxer PM10 i soroll
% Se abre el fichero y se obtienen los datos de cada elemento, son 8
fileID=fopen('dades_soroll_pm10.txt','r');
formatSpec=['%d' barra '%d' barra '%d'  '%d' dpuntos '%d' dpuntos '%d' pcoma '%d' pcoma '%d'];
C=textscan(fileID,formatSpec);
fclose(fileID);

% Se guarda cada elemento en su correspondiente variable
any=C{1}; 
mes=C{2};
dia=C{3};
hora=C{4}+14;
a=find(hora>=24);
hora(a)=double(hora(a)-24);
minut=C{5}+27;
a=find(minut>=60);
minut(a)=double(minut(a)-60);

%%% Transformació dels valors analògics a dBs
soroll=C{8}; %Ruido en analógico
y1=30;
x1=0;
y2=78.8;
x2=3326;
pendent=(y2-y1)/(x2-x1);

%%% Variables para transmitir
pm10=double(C{7}); %Contaminación atmosférica
soroll_dbs=double(pendent.*(soroll-x1)+y1); %Contaminación acústica

%%  IMAGENES DE LOS DATOS %%
m = 29911;
dias = unique(dia); %sacamos los dias
horas = unique(hora); %sacamos las horas
media_dias = zeros(length(dias), 1);
media_horas = zeros(length(horas),1);

%medias totales
media_total_pm10 = sum(pm10)/m;
media_total_ruido = sum(soroll_dbs)/m;
%valor mas repetido siempre
vmr_pm10 = mode(pm10);
vmr_ruido = mode(soroll_dbs);

%CALCULAMOS VALOR MEDIO DIARIO
for i=1:length(dias)
   % x = pm10(dia==dias(i));
    x = soroll_dbs(dia==dias(i));

    %calculamos el valor medio de cada dia
    total = sum(x);
    n = length(x);
    media_dias(i) = total/n;
end

%CALCULAMOS CANTIDAD DE VARIACIONES POR HORA
vsm1 = zeros(length(horas),1); % cantidad de valores que superan el vmr
vsm2 = zeros(length(horas),1); %cantidad de valores que superan el vmr
for i=1:length(horas)
    x1 = pm10(hora==horas(i));
    x2 = soroll_dbs(hora==horas(i));

    %calculamos la cantidad de valores que superan el valor mas repetido
    vsm1(i) = length(x1(pm10(hora==horas(i))>vmr_pm10));
    vsm2(i) = length(x2(soroll_dbs(hora==horas(i))>vmr_ruido));
    
    %calculamos el valor medio de cada hora
%     total = sum(x1);
%     n = length(x1);
%     media_horas(i) = total/n;
end

%CALCULAMOS LOS DIFERENTES TIPOS DE VALORES QUE HAY Y LA CANTIDAD DE VECES
%QUE APARECEN EN LOS 21 DIAS
valores_pm10 = unique(pm10); %sacamos los diferentes valores que hay
cv_pm10 = zeros(length(valores_pm10),1); %cantidad valores diferentes
valores_ruido = unique(soroll_dbs); %sacamos los diferentes valores que hay
cv_ruido = zeros(length(valores_ruido),1); %cantidad valores diferentes
for i=1:length(valores_pm10) %pm10
    cv_pm10(i) = length(pm10(pm10==valores_pm10(i)));
end
for i=1:length(valores_ruido) %ruido
    cv_ruido(i) = length(soroll_dbs(soroll_dbs==valores_ruido(i)));
end

%bar(media_dias);
%bar(media_horas);
%bar(media_total);

% figure
% bar(valores_pm10, cv_pm10/21); %cantidad de veces que se utiliza un valor pm10 de media al día
% boxplot(valores_pm10);
% figure
% plot(valores_ruido, cv_ruido/21); %cantidad de veces que se utiliza un valor ruido de media al día

% figure
% bar(horas, vsm1/24); %variacion media de pm10 por hora
% xlabel('Hora');
% ylabel('Alteraciones');
% set(gca,'xtick', 0:2:23);
% set(gca,'ytick', 0:4:40);
% ylim([0 40]);
% figure
% bar(horas, vsm2/24); %variacion media de ruido por hora3
% xlabel('Hora');
% ylabel('Alteraciones');
% set(gca,'xtick', 0:2:23);
% set(gca,'ytick', 0:4:40);

%CALCULAMOS LOS GRAFICOS REDUCIDOS
%length(soroll_dbs(1:2:29911)) %cantidad de muestras transmitidas con la reduccion
% figure
% plot(soroll_dbs(1:1:29911));
% figure
% plot(soroll_dbs(1:2:29911));
% figure
% plot(soroll_dbs(1:3:29911));
% figure
% plot(soroll_dbs(1:5:29911));
% figure
% plot(soroll_dbs(1:2:29911));
% ax = gca;
% ax.YAxis.Limits = [30 220];
% figure
% plot(soroll_dbs(1:3:29911));
% ax = gca;
% ax.YAxis.Limits = [30 220];
% figure
% plot(soroll_dbs(1:5:29911));
% ax = gca;
% ax.YAxis.Limits = [30 220];
% figure
% plot(soroll_dbs(1:10:29911));
% ax = gca;
% ax.YAxis.Limits = [30 220];

% %MEODO II: CALCULAMOS CANTIDAD DE VARIACIONES POR HORA EN VECTORES REDUCIDOS
% vsm1 = zeros(length(horas),1); % cantidad de valores que superan el vmr
% vsm2 = zeros(length(horas),1); %cantidad de valores que superan el vmr
% pm10 = pm10(1:10:29911);
% hora = hora(1:10:29911);
% soroll_dbs = soroll_dbs(1:10:29911);
% for i=1:length(horas)
%     x1 = pm10(hora==horas(i));
%     x2 = soroll_dbs(hora==horas(i));
%     %calculamos la cantidad de valores que superan el valor mas repetido
%     vsm1(i) = length(x1(pm10(hora==horas(i))>vmr_pm10));
%     vsm2(i) = length(x2(soroll_dbs(hora==horas(i))>vmr_ruido));
% end
% figure
% bar(vsm1/24); %variacion media de pm10 por hora
% figure
% bar(vsm2/24); %variacion media de ruido por hora

%VALOR MAS REPETIDO CADA DIA (FIGURA 1)
% dias_totales = unique(dia);
% cantidad_diaria_pm10 = zeros(length(dias_totales),1);
% cantidad_diaria_ruido = zeros(length(dias_totales),1);
% for i=1:length(dias_totales)
%     dr = soroll_dbs(dia==dias_totales(i));
%     cantidad_diaria_ruido(i,1) = length(dr(dr==30));
%     dp = pm10(dia==dias_totales(i));
%     cantidad_diaria_pm10(i,1) = length(dp(dp==43));
% end
% figure
% boxplot(cantidad_diaria_ruido);
% ylabel('Muestras diarias');
% xticklabels({'43 μm/m3'});
% figure
% boxplot(cantidad_diaria_pm10);
% xticklabels({'30 dB'});
% ylabel('Muestras diarias');
% ylim([650 1150]);
% figure
% boxplot(pm10)
% ylim([40 60]);
% set(gca,'ytick', 40:2:60);
% xticklabels({'Datos PM10'});
% ylabel('Valor en μm/m3');
% figure
% boxplot(soroll_dbs);
% ylim([28 60]);
% set(gca,'ytick', 28:2:60);
% xticklabels({'Datos RUIDO'});
% ylabel('Valor en dB');

%FIGURA 2
figure
scatter(double(hora), double(pm10));
xlabel('Hora');
ylabel('Alteraciones VS Valores PM10 en μm/m3');
hold on
bar(horas, vsm1/24);
set(gca,'ytick', 0:3:70);
legend('valores pm10', 'cantidad media de alteraciones');
hold off
figure
scatter(double(hora), double(soroll_dbs));
xlabel('Hora');
ylabel('Alteraciones VS Valores RUIDO en dB');
hold on
bar(horas, vsm2/24);
set(gca,'ytick', 0:10:240);
legend('valores ruido', 'cantidad media de alteraciones');
hold off
