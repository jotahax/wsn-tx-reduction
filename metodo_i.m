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

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%            PRUEBAS            %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ESCENARIO I: Comparacion
% Comparamos una muestra con la ultima tx, si es diferente la transmitimos
% si es igual la mantenemos.
m = length(pm10); %total de muestras: ambos vectores son iguales
e_pm10 = [0 1 2]; %umbrales de error pm10: 2 es un valor cualquiera para guardar la posicion y mostrar el umbral adaptado en el grafico
e_ruido = [0 3 10]; %umbrales de error ruido
n_pm10 = zeros(1, length(e_pm10)); %transmisiones de pm10 totales
n_ruido = zeros(1, length(e_ruido)); %transmisiones de ruido totales
tx_pm10 = 0; %ultimo valor transmitido de pm10
tx_ruido = 0; %ultimo valor transmitido de ruido
tx_horas_pm10 = zeros(24,1);
tx_horas_ruido = zeros(24,1);

%el proceso de comparacion/transmision se hace para cada umbral
for i=1:length(e_ruido) 

    for j=1:m %se recorren todas las muestras

        %pm10
        if e_pm10(i) == 2 %en la ultima posicion usamos umbral adaptado
            if umbral_pm(pm10(j),tx_pm10) >= 1
                n_pm10(length(e_pm10)) = n_pm10(length(e_pm10)) + 1; %contamos transmision
                tx_pm10 = pm10(j); %guardamos el valor transmitido
                tx_horas_pm10(hora(j)+1) = tx_horas_pm10(hora(j)+1) + 1; %comentamos la linea para calcular los otros umbrales
            end
        else
            if abs(pm10(j)-tx_pm10) > e_pm10(i) %usamos umbrales nulo y minimo
                n_pm10(i) = n_pm10(i) + 1; %contamos transmision
                tx_pm10 = pm10(j); %guardamos el valor transmitido
                if i==1 %modificamos el valor para obtener el grafico con cada umbral i==1/2
                    %tx_horas_pm10(hora(j)+1) = tx_horas_pm10(hora(j)+1) + 1; %comentamos la linea para calcular el umbral maximo
                end
            end
        end

        %ruido
        if abs(soroll_dbs(j)-tx_ruido) > e_ruido(i) %todos los umbrales
            n_ruido(i) = n_ruido(i) + 1;  %contamos transmision
            tx_ruido = soroll_dbs(j); %guardamos el valor transmitido
            if i==1 %modificamos el valor para obtener el grafico con cada umbral i==1/2/3
                tx_horas_ruido(hora(j)+1) = tx_horas_ruido(hora(j)+1) + 1;
            end
        end

    end

    %se reinicia la ultima muestra para el siguiente umbral
    tx_pm10 = 0;
    tx_ruido = 0;

end

%resultados numericos
disp("Porcentaje reduccion de PM10:");
n_pm10
p1 = (m-n_pm10)/m*100
disp("Porcentaje reduccion de Ruido:");
n_ruido
p2 = (m-n_ruido)/m*100

%grafico pm10 con umbral
figure
bar([0 1 2], p1)
ylim([0 100]);
set(gca,'ytick', 0:10:100);
xlabel('Valor del umbral');
ylabel('Reducción de transmisiones (%)');
xticklabels({'0','1','adaptado'});

%grafico ruido con umbral
figure
bar([0 1 2], p2)
ylim([0 100]);
set(gca,'ytick', 0:10:100);
xlabel('Valor del umbral');
ylabel('Reducción de transmisiones (%)');
xticklabels({'0','3','10'});

%reducciones por hora pm10 sin umbral
figure
bar(unique(hora), (1260-tx_horas_pm10)/1260*100);
ylim([0 100]);
set(gca,'ytick', 0:10:100);
xlabel('Hora');
ylabel('Reducción de transmisiones (%)');

%reducciones por hora ruido sin umbral
figure
bar(unique(hora), (1260-tx_horas_ruido)/1260*100);
ylim([0 100]);
set(gca,'ytick', 0:10:100);
xlabel('Hora');
ylabel('Reducción de transmisiones (%)');

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%            FUNCIONES            %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%umbral adaptado a los niveles de pm10
%diferenciamos tres casos
function tx = umbral_pm(tx_actual, tx_anterior)
    if tx_actual >= 49 %a partir de 49 todos los valores importan
        tx = abs(tx_anterior - tx_actual); %si es diferente siempre transmitimos
    else
        if tx_actual == 48 %si estamos en 48 importan a partir de 50
            if abs(tx_anterior - tx_actual) > 1 %se permite un margen de 2
                tx = 1;
            else
                tx = 0;
            end
        else
            if abs(tx_anterior - tx_actual) > 2 %se permite un margen de 3
                tx = 1;
            else
                tx = 0;
            end
        end
    end
end
