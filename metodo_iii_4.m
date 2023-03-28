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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%            PRUEBAS            %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ESCENARIO III: Reduccion heuristica
m = length(pm10); %total de muestras
e = zeros(2, 3); %cantidad de error
ma1 = pm10(1); %muestra anterior de pm10
ma2 = soroll_dbs(1); %muestra anterior de ruido
vr1 = pm10; %vector pm10 reducido
vr2 = soroll_dbs; %vector ruido reducido
n = [1, 2, 3, 5, 10];
indice = 1;
cn = zeros(24, length(n)); %cantidad de veces que escoge cada periodo
tx_horas_pm10 = zeros(24,1);
tx_horas_pm10_metodo_i = [155;164;162;154;150;145;168;182;173;135;143;167;129;150;192;160;154;125;161;146;151;155;179;131];

i = 2; %posicion actual para coger una muestra
q = 1; %periodo: valor que añadimos a la posicion actual para aumentar o disminuir el periodo
tx_pm10 = 1; %transmisiones totales de pm10
tx_ruido = 1; %transmisiones totales de ruido

%proceso heuristico para el pm10
while(i<m)

    vr1(i-q:i-1) = ma1; %completamos espacios entre muestras transmitidas con el ultimo valor transmitido
    tx_pm10 = tx_pm10 + 1; %contamos transmision
    tx_horas_pm10(hora(i)+1) = tx_horas_pm10(hora(i)+1) + 1; %contamos transmisiones por horas

    %caso 1: si dos muestras transmitidas son diferentes disminuimos el periodo
    if abs(ma1 - pm10(i)) > 0 %caso extra: posibilidad de mantener
    
        if abs(ma1 - pm10(i)) > 2 %disminuimos
        
            if indice>1 %evitamos que q sea negativa
                indice = indice-1;
                cn(hora(i)+1,indice) = cn(hora(i)+1,indice) + 1;
                q = n(indice); %disminuimos periodo
            end
    
            if (i+q)<=m %evitamos que la posicion supere la longitud del vector
                ma1 = pm10(i); %guardamos la muestra
                i = i + q; %obtenemos nueva posicion actual
            else
                i = m; %cerramos bucle
            end

        else %mantenemos

            if (i+q)<=m %evitamos que la posicion supere la longitud del vector
                ma1 = pm10(i); %guardamos la muestra
                i = i + q; %obtenemos nueva posicion actual
            else
                i = m; %cerramos bucle
            end

        end

    %caso 2: si son iguales lo aumentamos
    else
        
        if indice<length(n) %evitamos que q supere los 10 minutos de periodo
            indice = indice + 1;
            cn(hora(i)+1,indice) = cn(hora(i)+1,indice) + 1;
            q = n(indice); %aumentamos periodo
        end
        if (i+q)<=m %evitamos que la posicion supere la longitud del vector
            ma1 = pm10(i); %guardamos la muestra
            i = i + q; %obtenemos nueva posicion actual
        else
            i = m; %cerramos bucle
        end

    end
end %end proceso heuristico pm10

i = 2; %reiciamos posicion actual
q = 1; %reiniciamos periodo

%proceso heuristico para el ruido
while(i<m)

    vr2(i-q:i-1) = ma2; %completamos espacios entre muestras transmitidas con el ultimo valor transmitido
    tx_ruido = tx_ruido + 1; %contamos transmision

    %caso 1: si dos muestras transmitidas son diferentes disminuimos el periodo
    if abs(ma2 - soroll_dbs(i)) > 0 %caso extra: posibilidad de mantener
    
        if abs(ma2 - soroll_dbs(i)) > 2 %disminuimos

            if indice>1 %evitamos que q sea negativa
                indice = indice-1;
                q = n(indice); %disminuimos periodo
            end
    
            if (i+q)<=m %evitamos que la posicion supere la longitud del vector
                ma2 = soroll_dbs(i); %guardamos la muestra
                i = i + q; %obtenemos nueva posicion actual
            else
                i = m; %cerramos bucle
            end

        else %mantenemos
            
            if (i+q)<=m %evitamos que la posicion supere la longitud del vector
                ma2 = soroll_dbs(i); %guardamos la muestra
                i = i + q; %obtenemos nueva posicion actual
            else
                i = m; %cerramos bucle
            end

        end

    %caso 2: si son iguales lo aumentamos
    else

        if indice<length(n) %evitamos que q supere los 10 minutos de periodo
            indice = indice + 1;
            q = n(indice); %aumentamos periodo
        end
        if (i+q)<=m %evitamos que la posicion supere la longitud del vector
            ma2 = soroll_dbs(i); %guardamos la muestra
            i = i + q; %obtenemos nueva posicion actual
        else
            i = m; %cerramos bucle
        end

    end
end %end proceso heuristico ruido

%comprobamos el error con cada umbral
for i = 1:m
       if abs(vr1(i)-pm10(i)) > 0 %pm10 sin umbral
           e(1,1) = e(1,1) + 1;
       end
       if abs(vr1(i)-pm10(i)) > 1 %pm10 con umbral minimo
           e(1,2) = e(1,2) + 1;
       end
       if umbral_pm(vr1(i),pm10(i)) >= 1 %pm10 con umbral adaptado
           e(1,3) = e(1,3) + 1;
       end
       if abs(vr2(i)-soroll_dbs(i)) > 0 %ruido sin umbral
           e(2,1) = e(2,1) + 1;
       end
       if abs(vr2(i)-soroll_dbs(i)) > 3 %ruido con umbral minimo
           e(2,2) = e(2,2) + 1;
       end
       if abs(vr2(i)-soroll_dbs(i)) > 10 %ruido con umbral maximo
           e(2,3) = e(2,3) + 1;
       end
end %end comprobacion error

%resultados numericos
disp("Transmisiones totales:");
tx_pm10
tx_ruido
disp("Porcentaje reducción de transmisiones:");
tx_pm10 = 100-tx_pm10/m*100 %calculamos porcentajes de transmisiones
tx_ruido = 100-tx_ruido/m*100
disp("Error en porcentajes:");
e = e/29911*100 %calculamos porcentajes de error
figure
bar(e(1,:))
xlabel('Valor del umbral');
ylabel('Error (%)');
xticklabels({'0','1','adaptado'});
ylim([0 55]);
set(gca,'ytick', 0:5:55);
figure
bar(e(2,:))
xlabel('Valor del umbral');
ylabel('Error (%)');
xticklabels({'0','3','10'});
ylim([0 55]);
set(gca,'ytick', 0:5:55);

%comparacion actual vs optimo
figure
bar(unique(hora),((1260-tx_horas_pm10_metodo_i)/1260*100));
hold on
bar(unique(hora), (1260-tx_horas_pm10)/1260*100);
ylim([0 100]);
set(gca,'ytick', 0:10:100);
xlabel('Hora');
ylabel('Reducción de transmisiones (%)');
legend('resultado optimo', 'resultado actual', 'Location','southeast');

%distribucion de las acciones del resultado optimo de pm10 a lo largo del dia
figure
plot(unique(hora), cumsum(cn), 'LineWidth',2);
xlabel('Hora');
ylabel('Cantidad de acciones');
legend('n=1', 'n=2', 'n=3', 'n=5', 'n=10', 'Location', 'northwest');

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
