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

% ESCENARIO II: Reduccion fija
m = length(pm10); %total de muestras: iguales en ambos casos
n = [2 3 5 10]; %valores de muestreo establecidos
ma1 = pm10(1); %muestra anterior de pm10
ma2 = soroll_dbs(1); %muestra anterior de ruido
e = zeros(2, length(n)); %cantidad de error total
vr1 = pm10; %vector pm10 reducido
vr2 = soroll_dbs; %vector ruido reducido
e_horas = zeros(24,length(n));
tx_horas_pm10 = 1260*0.8*ones(24,1);
tx_horas_pm10_metodo_i = [155;164;162;154;150;145;168;182;173;135;143;167;129;150;192;160;154;125;161;146;151;155;179;131];

%se calcula el error para cada periodo de muestreo
for i=1:length(n) 

   for j=1:m %recorremos todas las muestras

       if mod(j,n(i)) == 1 %cogemos una muestra cada n
           ma1 = pm10(j); %almacenamos muestra anterior de pm10
           ma2 = soroll_dbs(j); %almacenamos muestra anterior de ruido
       else %si no cogemos muestra utilizamos la anterior en todas las posiciones
           vr1(j) = ma1; 
           vr2(j) = ma2;
       end

       %comprobamos el error: por tema de memoria como son vectores muy
       %grandes calculamos cada grafico en una ejecución
       %if abs(vr1(j)-pm10(j)) > 0 %sin umbral pm10
       %if abs(vr1(j)-pm10(j)) > 1 %umbral minimo pm10
       if umbral_pm(pm10(j),vr1(j)) >= 1 %umbral maximo (adaptado) pm10
           e(1,i) = e(1,i) + 1;
       end
       if abs(vr2(j)-soroll_dbs(j)) > 0 %sin umbral ruido
       %if abs(vr2(j)-soroll_dbs(j)) > 3 %umbral minimo ruido
       %if abs(vr2(j)-soroll_dbs(j)) > 10 %umbral maximo ruido
           e(2,i) = e(2,i) + 1;
           e_horas(hora(j)+1, i) = e_horas(hora(j)+1, i) + 1;
       end

   end

   %reiniciamos los vectores reducidos para el siguiente periodo de
   %muestreo: dejamos el ultimo valor tal cual para calcular la media
   if i~=length(n)
        vr1 = pm10;
        vr2 = soroll_dbs;
   end

end

%resultados numericos
disp("Porcentaje transmitido de Total:");
ptx = 100-100./n
disp("Error:");
e = e/29911*100
figure
bar([0 1 2 3],e)
%title('MÉTODO II: Reducción fija');
legend('pm10','ruido', 'Location','northwest');
xlabel('Reducción de transmisiones (%)');
ylabel('Error (%)');
xticklabels(round(100-100./n,1));
ylim([0 60]);
set(gca,'ytick', 0:5:60);
figure
bar(unique(hora), e_horas(:,1)/1260*100); %cada hora con 60 muestras sale 21 veces en el conjunto, 21*60=1260 para la media
ylim([0 100]);
xlabel('Hora');
ylabel('Error (%)');
figure
bar(unique(hora), e_horas(:,2)/1260*100);
ylim([0 100]);
xlabel('Hora');
ylabel('Error (%)');
figure
bar(unique(hora), e_horas(:,3)/1260*100);
ylim([0 100]);
xlabel('Hora');
ylabel('Error (%)');
figure
bar(unique(hora), e_horas(:,4)/1260*100);
ylim([0 100]);
xlabel('Hora');
ylabel('Error (%)');

%reducciones por hora pm10 sin umbral
figure
bar(unique(hora),((1260-tx_horas_pm10_metodo_i)/1260*100));
hold on
bar(unique(hora), (tx_horas_pm10)/1260*100);
ylim([0 100]);
set(gca,'ytick', 0:10:100);
xlabel('Hora');
ylabel('Reducción de transmisiones (%)');
legend('resultado optimo', 'resultado actual', 'Location','southeast');

%% CASO ESPECIAL RUIDO: Horas nocturnas y diurnas
vr = soroll_dbs;
ma = 0;
n_dia = [1 4]; %cambiar 2 por 1 para muestreo original
n_noche = [5 10];
tx = zeros(length(n_dia), length(n_noche));
e = zeros(length(n_dia), length(n_noche));
ee_horas = zeros(24,1);
tx_horas_ruido = zeros(24,1);
tx_horas_ruido_metodo_i = [256;281;271;309;349;451;711;938;1016;929;926;958;874;922;880;827;836;878;817;685;601;431;338;260];

for j=1:length(n_dia) 
    for k=1:length(n_noche)

        for i=1:m %recorremos todas las muestras
        
           if hora(i)+1 >= 7 && hora(i)+1 <=21 %horas del dia
               if mod(i,n_dia(j)) == 0 %cogemos una muestra cada n - poner en 0 para muestreo original
                   ma = soroll_dbs(i); %almacenamos muestra anterior de ruido
                   tx(j, k) = tx(j,k) + 1;
                   if n_noche(k)==10 && n_dia(j)==1 %cambiar n_dia a 1 para muestreo original
                        tx_horas_ruido(hora(i)+1) = tx_horas_ruido(hora(i)+1) + 1;
                    end
               else %si no cogemos muestra utilizamos la anterior en todas las posiciones
                   vr(i) = ma;
               end
           elseif hora(i)+1 < 7 || hora(i)+1 > 21 %horas de la noche
               if mod(i,n_noche(k)) == 1 %cogemos una muestra cada n
                   ma = soroll_dbs(i); %almacenamos muestra anterior de ruido
                   tx(j,k) = tx(j,k) + 1;
                   if n_noche(k)==10 && n_dia(j)==1 %cambiar n_dia a 1 para muestreo original
                        tx_horas_ruido(hora(i)+1) = tx_horas_ruido(hora(i)+1) + 1;
                    end
               else %si no cogemos muestra utilizamos la anterior en todas las posiciones
                   vr(i) = ma;
               end
           end

           if abs(vr(i)-soroll_dbs(i)) > 0 %sin umbral ruido
           %if abs(vr(i)-soroll_dbs(i)) > 3 %umbral minimo ruido
           %if abs(vr(i)-soroll_dbs(i)) > 10 %umbral maximo ruido
               e(j,k) = e(j,k) + 1;
               if n_dia(j)==2 && n_noche(k)==10
                    ee_horas(hora(i)+1) = ee_horas(hora(i)+1) + 1;
               end
           end
        
        end
vr = soroll_dbs;
    end

end

tx = reshape(tx',1,[])
p_tx = reshape((100-tx/m*100)',1,[])
e = reshape((e/m*100)',1,[])

% error = [29.1732 29.8385 37.0466 37.7319];
% r_tx = [61.4000   65.2000   71.7000   75.5000];
figure
bar([0 1 2 3], e);
ylim([0 60]);
set(gca,'ytick', 0:5:60);
xlabel('Reducción de transmisiones (%)');
ylabel('Error (%)');
xticklabels(round(100-tx/m*100,1));
% figure
% bar(unique(hora), ee_horas/1440*100);
% ylim([0 100]);
% xlabel('Hora');
% ylabel('Error (%)');

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
