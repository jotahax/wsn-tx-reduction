# wsn-tx-reduction
Métodos desarrollados para la reducción del número de transmisiones de una red de sensores inalámbricos de uso medioambiental.

CONJUNTO DE DATOS: Contiene los datos recogidos por la red en un periodo de 21 días con muestras cada minuto. Tal y como está programado el sistema ¡cada muestra equivale a una transmisión! Los datos se encuentran en el archivo dades_soroll_pm10.txt

ESTADÍSTICAS DE LOS DATOS: La distribución de los datos y las diferentes figuras que muestran toda la información que se puede extraer de ellos se encuentan en el archivo extraccio_soroll_pm10.m

MÉTODOS:

I. Reducción de transmisiones por comparación --> El algoritmo y los resultados se encuentran en el archivo metodo_i.m

II. Reducción de transmisiones y detecciones por reducción fija del periodo de muestreo --> El algoritmo y los resultados se encuentran en el archivo metodo_ii.m

II. Reducción de transmisiones y detecciones por regla heurística --> Hay 4 reglas heurística y cada una se encuentra en su respectivo archivo metodo_iii_x.m, donde x es el numero de cada regla

IV. Reducción de transmisiones y detecciones con Multi-Armed Bandit --> El algoritmo y los resultados se encuentran en el archivo metodo_iv.m



IMPORTANTE: Los resultados y gráficos para cada uno de los dos elementos (pm10 y ruido) y para cada uno de los escenarios (sin umbral, umbral mínimo y umbral máximo) se encuentran dentro del mismo archivo. En los comentarios del código se indica que se debe hacer para ejecutar uno y otro.
