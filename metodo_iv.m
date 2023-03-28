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

% ESCENARIO IV: Multi-armed Bandit
%Obtenemos el periodo de muestreo mas optimo para cada hora del dia
m = length(pm10); %total de muestras
T = [2 3 5 10]; %periodos posibles
rewards = zeros(24, length(T)); %tabla de recompensas para cada hora y periodo
epsilon = 0.2; %epsilon con valor estandar
vr1 = pm10; %copia del vector de datos pm10
vr2 = soroll_dbs; %copia del vector de datos ruido
j = 1; %variable iniciada en 1 para el bucle e-greedy (posicion actual del vector)
ja = j; %variable para almacenar la posicion anterior en el bucle e-greedy y calcular la recompensa
rewards(1:24) = 0; %iniciamos el algoritmo con periodo 2
c_acciones = zeros(24, length(T)); %cantidad de veces que escoge una accion por hora
c_greedy = zeros(2,1); %cantidad de veces que decide explotar/explorar
c_rewards = zeros(24, length(T)); %cantidad de veces que sale cada recompensa
r_total = 0;

for i=1:100 %iteraciones de aprendizaje

    %recorremos vector explorando/explotando 
    while j<m

        if rand < 0.05
            %explorar
            c_greedy(1) = c_greedy(1) + 1;
            [~,t] = max(rewards(hora(j)+1,:)); %obtenemos el periodo con mayor recompensa
            T2 = T(T~=T(t)); %los sacamos para explorar otra opcion
            t = T2(randi(length(T2))); %nuevo periodo
            c_acciones(hora(j)+1, find(T==t)) = c_acciones(hora(j)+1, find(T==t)) + 1;
        else
            %explotar
            c_greedy(2) = c_greedy(2) + 1;
            [~,t] = max(rewards(hora(j)+1,:)); %cogemos el periodo con mayor recompensa acumulada
            t = T(t); %nuevo periodo
            c_acciones(hora(j)+1, find(T==t)) = c_acciones(hora(j)+1, find(T==t)) + 1;
        end

        %cogemos muestra
        ja = j; %guardamos posicion anterior
        j = j + t; %nueva posicion
        if j <= m
            %calculamos recompensa: se comprueban las muestras intermedias entre dos
            %transmisiones, si no superan el umbral se suma 1 a la recompensa,
            %si lo supera no se suma nada
            r_total = 0;
            for k=ja+1:j-1
                %%%%%%%%UMBRALES PM10%%%%%%%%               
                %if abs(vr1(k)-pm10(j)) == 0 %sin umbral
                %if abs(vr1(k)-pm10(j)) <= 1 %umbral minimo
                %if umbral_pm(vr1(k),pm10(k)) == 0 %umbral adaptado
                %%%%%%%%UMBRALES RUIDO%%%%%%%%
                if abs(vr2(k)-soroll_dbs(j)) == 0 %sin umbral
                %if abs(vr2(k)-soroll_dbs(j)) <= 3 %umbral minimo
                %if abs(vr2(k)-soroll_dbs(j)) <= 10 %umbral maximo
                    r_total = r_total + 1;
                end
            end

            %rewards(hora(j)+1, find(T==t)) = rewards(hora(j)+1, find(T==t)) + reward_unitario(r_total, t); %sumamos recompensa en la posicion correspondiente al periodo de la muestra transmitida actual
            rewards(hora(j)+1, find(T==t)) = rewards(hora(j)+1, find(T==t)) + reward_porcentaje(r_total, t);

        else
            j = m; %cerramos bucle
        end

    end %end bucle vector

    %reiniciamos para la proxima iteracion
    j=1;
    ja=j;
    
    %cogemos el periodo con mayor recompensa despues de cada iteracion
    [~, t] = max(rewards(1:24,:)');
    T(t);
    for i=1:length(t)
        c_rewards(i, t(i)) = c_rewards(i, t(i)) + 1;
    end

    rewards = zeros(24, length(T)); %reiniciamos la recompensa, comentar para no reiniciar suele dar mejores resultados en pm10

end %end total iteraciones

[~, t] = max(c_rewards(1:24,:)'); %sacamos las recompensa maxima en cada hora
T_total = T(t) %obtenemos el valor de periodo de muestreo optimo correspondiente a cada recompensa

%Evolucion de acciones a lo largo del dia de media
figure
plot(unique(hora), cumsum(c_acciones/21/100), 'LineWidth',2);
%ylim([0 100]);
xlabel('Hora');
ylabel('Cantidad de acciones');
legend('n=2', 'n=3', 'n=5', 'n=10', 'Location','northwest');

%Porcentaje de cada periodo en cada hora
figure
bar(unique(hora), c_rewards,'stacked');
xlabel('Hora');
ylabel('Cantidad de veces en %');
legend('n=2', 'n=3', 'n=5', 'n=10', 'Location','northwest');

%% Utilizamos el periodo mas optimo y calculamos el numero
% de transmisiones y el error: este periodo de ejemplo ha sido
% obtenido ejecutando el metodo anterior 10.000 veces.
ma1 = pm10(1); %primera muestra pm10
ma2 = soroll_dbs(1); %primera muestra ruido
vr1 = pm10; %copia del vector de datos pm10
vr2 = soroll_dbs; %copia del vector de datos ruido
e = 0; %error total
tx = 0; %transmisiones totales
tx_horas_pm10_metodo_i = [155;164;162;154;150;145;168;182;173;135;143;167;129;150;192;160;154;125;161;146;151;155;179;131];
tx_horas_pm10 = zeros(24,1);
tx_horas_ruido = zeros(24,1);
tx_horas_ruido_metodo_i = [256;281;271;309;349;451;711;938;1016;929;926;958;874;922;880;827;836;878;817;685;601;431;338;260];

%muestreo = [5     5     2     5     5     5     5     5     5     5     5    10    10    10     5    10    10     5     5     5     5     5     5     5]; %mejor resultado pm10
%muestreo = [10    10    10    10    10    10    10     2     2     2     2     2     2     2     2     2     2     2     2     2     2    10    10    10]; %mejor resultado ruido
muestreo = [2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2];

%se obtiene el vector con el muestreo optimo y se comprueba el error
for i=1:m

    if mod(i,muestreo(hora(i)+1)) == 1 %cogemos una muestra
       ma1 = pm10(i);
       %ma2 = soroll_dbs(i);
       tx=tx+1;
       %tx_horas_pm10(hora(i)+1) = tx_horas_pm10(hora(i)+1) + 1; %contamos transmisiones por horas
       tx_horas_ruido(hora(i)+1) = tx_horas_ruido(hora(i)+1) + 1;
    else %utilizamos la anterior
       vr1(i) = ma1; %pm10
       %vr2(i) = ma2; %ruido
    end

%    %COMPROBACION ERROR PM10: comentar bloque para calcular ruido
   if abs(vr1(i)-pm10(i)) > 0 %sin umbral
   %if abs(vr1(i)-pm10(i)) > 1 %umbral minimo
   %if umbral_pm(pm10(i),vr1(i)) >= 1 %umbral maximo
       e = e + 1;
   end

   % %COMPROBACION ERROR RUIDO: comentar bloque para calcular pm10
   % if abs(vr2(i)-soroll_dbs(i)) > 0 %sin umbral
   % % %if abs(vr2(i)-soroll_dbs(i)) > 3 %umbral minimo
   % % %if abs(vr2(i)-soroll_dbs(i)) > 10 %umbral maximo
   %    e = e + 1;
   % end

end %end comparacion de error

disp("Porcentaje reducción de transmisiones:");
p = 100- tx/m*100
disp("Error:");
e = e/m*100

%% Periodo aprendido vs periodo optimo
%distribucion de las acciones del resultado optimo de pm10 a lo largo del dia
% figure
% bar(unique(hora),((1260-tx_horas_pm10_metodo_i)/1260*100));
% hold on
% bar(unique(hora), (1260-tx_horas_pm10)/1260*100);
% ylim([0 100]);
% set(gca,'ytick', 0:10:100);
% xlabel('Hora');
% ylabel('Reducción de transmisiones (%)');
% legend('resultado optimo', 'resultado actual', 'Location','southeast');

%reducciones por hora ruido sin umbral
figure
b = bar(unique(hora), ((1260-tx_horas_ruido)/1260*100));
b.FaceColor = "#D95319"; %naranja
hold on
b = bar(unique(hora),((1260-tx_horas_ruido_metodo_i)/1260*100));
b.FaceColor = "#0072BD"; %azul
ylim([0 100]);
set(gca,'ytick', 0:10:100);
xlabel('Hora');
ylabel('Reducción de transmisiones (%)');
legend('resultado actual', 'resultado optimo', 'Location','southeast');

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%            FUNCIONES            %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

% FUNCIONES DE RECOMPENSA %
function r_final = reward_unitario(r_total,t)

    if t>3 && r_total >= (t-2)
        r_total = r_total*1.5;
    end
    if r_total < (t-2)
        r_total = r_total*0.5;
    end

    r_final = r_total;
end

function r_final = reward_porcentaje(r_total, t)
    r_final = r_total/(t-1);
end
