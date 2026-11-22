---
title: "Lab: Producto punto, normas y distancias"
unit: "I"
lesson: 2
type: lab
tags: [producto punto, normas, distancia, vecino mas cercano, numpy, pinguinos]
difficulty: introductory
duration: "60 mins"
---

# Lab: Producto punto, normas y distancias

**Meta:** calcular productos punto, normas y distancias con NumPy, encontrar el pingüino más
parecido a otro y comprobar que la respuesta depende de las unidades. Acompaña a la página de
conceptos [Producto punto, normas y distancias](l02_concept_producto_punto_normas.qmd).

> **Cómo usar este laboratorio:** en el sitio del curso esta página es de solo lectura: muestra el código junto con lo que produjo. Para ejecutarlo, ábrelo en Google Colab y usa *Archivo, Guardar una copia en Drive* antes de trabajar. Ejecuta las celdas en orden, de arriba abajo.
>
> [![Open in Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/devomh/mate4031-2027/blob/main/u01_vectores/l02_lab_producto_punto_normas.ipynb)

## Preparación

Este laboratorio no instala nada: Colab ya trae NumPy, pandas y Matplotlib. La celda de preparación importa
las bibliotecas, fija la semilla y carga los datos: los pingüinos de Palmer (licencia CC0), la
misma copia de la L01. Ejecútala cada vez que abras el laboratorio.

```python
# Preparacion: bibliotecas, semilla y datos. Seguro de ejecutar de nuevo.
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

rng = np.random.default_rng(4031)

# Los pinguinos de Palmer (Gorman, Williams y Fraser, 2014; CC0), copia del curso.
RUTA = Path("data/penguins.csv")
URL = "https://raw.githubusercontent.com/devomh/mate4031-2027/main/u01_vectores/data/penguins.csv"
pinguinos = pd.read_csv(RUTA if RUTA.exists() else URL)

# Las cuatro medidas; se descartan los 2 pinguinos que no tienen medidas.
VARIABLES = ["bill_length_mm", "bill_depth_mm", "flipper_length_mm", "body_mass_g"]
completos = pinguinos.dropna(subset=VARIABLES).reset_index(drop=True)
X = completos[VARIABLES].to_numpy()
especie = completos["species"].to_numpy()

print("matriz X:", X.shape)
```

<!-- #region -->
<details><summary>Resultado esperado</summary>

~~~text
matriz X: (342, 4)
~~~
</details>

Como en la L01, `X` es la matriz de datos (*data matrix*): 342 pingüinos por 4 variables, el
largo y la profundidad del pico (mm), el largo de la aleta (mm) y la masa (g).
<!-- #endregion -->

## Paso 1: el producto punto

### Primero, con un ciclo

El producto punto (*dot product*) multiplica las componentes que se corresponden y suma. Con un
ciclo, para los vectores de la página de conceptos:

```python
u = np.array([3, 4])
v = np.array([2, -1])

total = 0
for k in range(len(u)):
    total = total + u[k] * v[k]
print("con un ciclo:", total)
```

<!-- #region -->
<details><summary>Resultado esperado</summary>

~~~text
con un ciclo: 2
~~~
</details>
<!-- #endregion -->

### Mejor: `np.dot` y el operador `@`

NumPy lo hace en una sola operación, vectorizada: `np.dot(u, v)` o, más corto, `u @ v`. El
orden no importa, porque el producto punto es simétrico:

```python
print("np.dot(u, v):", np.dot(u, v))
print("u @ v:       ", u @ v)
print("v @ u:       ", v @ u)
print("u @ u:", u @ u)
print("norma de u al cuadrado:", np.linalg.norm(u) ** 2)
```

<!-- #region -->
<details><summary>Resultado esperado</summary>

~~~text
np.dot(u, v): 2
u @ v:        2
v @ u:        2
u @ u: 25
norma de u al cuadrado: 25.0
~~~
</details>

`u @ u` es $\|\mathbf{u}\|^2$: la norma de $(3, 4)$ es $5$, y $5^2 = 25$. El resultado de un
producto punto es un número, no un arreglo.
<!-- #endregion -->

## Paso 2: tres normas y tres distancias

`np.linalg.norm(v, ord=...)` calcula la norma (*norm*) que se le pida: `ord=1` es $\ell_1$,
`ord=2` (o nada) es $\ell_2$ y `ord=np.inf` es $\ell_\infty$.

```python
for orden in [1, 2, np.inf]:
    print("orden", orden, "->", np.linalg.norm(u, ord=orden))
```

<!-- #region -->
<details><summary>Resultado esperado</summary>

~~~text
orden 1 -> 7.0
orden 2 -> 5.0
orden inf -> 4.0
~~~
</details>

Son los números de la página de conceptos: $3 + 4 = 7$, $\sqrt{3^2 + 4^2} = 5$ y
$\max(3, 4) = 4$.
<!-- #endregion -->

La distancia (*distance*) entre dos vectores es la norma de su diferencia. Completa la línea
marcada para calcular las tres distancias entre $\mathbf{a} = (1, 2)$ y $\mathbf{b} = (4, 6)$,
quita los `#` y ejecuta. Después normaliza $\mathbf{u}$: divídelo entre su norma y comprueba que
el resultado tiene norma 1.

```python
a = np.array([1, 2])
b = np.array([4, 6])
# for orden in [1, 2, np.inf]:
#     print("distancia, orden", orden, "->", ____)    # <- completa: la norma de b - a
# unitario = ____                                  # <- completa: u dividido entre su norma
# print("u / ||u|| =", unitario)
# print("su norma:", np.linalg.norm(unitario))
```

<!-- #region -->
<details><summary>Resultado esperado</summary>

~~~text
distancia, orden 1 -> 7.0
distancia, orden 2 -> 5.0
distancia, orden inf -> 4.0
u / ||u|| = [0.6 0.8]
su norma: 1.0
~~~
</details>

$\mathbf{b} - \mathbf{a} = (3, 4)$, el mismo vector que $\mathbf{u}$, así que las distancias son
las normas de antes. El vector unitario (*unit vector*) $(0.6, 0.8)$ apunta en la dirección de
$\mathbf{u}$ y mide 1.
<!-- #endregion -->

## Paso 3: el pingüino más parecido

`X - X[0]` resta el primer pingüino de **cada fila** de `X`: NumPy repite el vector `X[0]` a lo
largo de las filas, una regla llamada difusión (*broadcasting*). Con `axis=1`,
`np.linalg.norm` calcula la norma de cada fila, es decir, la distancia de cada pingüino al
primero.

```python
x0 = X[0]
print("pinguino 0:", x0, especie[0])
diferencias = X - x0
print("forma de X - x0:", diferencias.shape)

d = np.linalg.norm(diferencias, axis=1)
print("cinco distancias:", np.round(d[:5], 2))
print("solo la masa:    ", np.abs(diferencias[:5, 3]))
```

<!-- #region -->
<details><summary>Resultado esperado</summary>

~~~text
pinguino 0: [  39.1   18.7  181.  3750. ] Adelie
forma de X - x0: (342, 4)
cinco distancias: [  0.    50.27 500.2  300.25 100.42]
solo la masa:     [  0.  50. 500. 300. 100.]
~~~
</details>

Ese es el **control**: las distancias con las cuatro variables casi coinciden con la diferencia
de masa sola. Las otras tres variables apenas cuentan.
<!-- #endregion -->

El vecino más cercano (*nearest neighbor*) es el pingüino a menor distancia. `np.argsort(d)`
ordena los índices de menor a mayor distancia; el primero es el mismo pingüino, a distancia 0,
así que el vecino es el segundo. La última línea mide qué parte de la suma de los cuadrados de
todas las diferencias viene de la masa.

```python
indices = np.argsort(d)
vecino = indices[1]
print("vecino mas cercano:", vecino, X[vecino], especie[vecino])
print("distancia:", round(d[vecino], 2))

cuadrados = diferencias ** 2
print("parte de la masa:", round(cuadrados[:, 3].sum() / cuadrados.sum(), 4))
```

<!-- #region -->
<details><summary>Resultado esperado</summary>

~~~text
vecino mas cercano: 148 [  37.8   18.1  193.  3750. ] Adelie
distancia: 12.09
parte de la masa: 0.9992
~~~
</details>

El vecino tiene exactamente la misma masa, 3750 g, aunque su aleta mide 12 mm más. En las 341
distancias de este pingüino a los demás, el 99.92% de la suma de los cuadrados viene de la masa.
La masa se anotó de 25 en 25 g, así que cualquier pingüino con otra masa queda a 25 o más de
distancia: el vecino es uno con exactamente la misma masa. La distancia la decide casi solo la
masa.
<!-- #endregion -->

## Paso 4: la misma pregunta en kilogramos

Pasar la masa a kilogramos es un múltiplo escalar de una columna (L01): los pingüinos son los
mismos, solo cambia la unidad de una variable.

```python
X_kg = X.copy()
X_kg[:, 3] = X[:, 3] * 0.001

d_kg = np.linalg.norm(X_kg - X_kg[0], axis=1)
vecino_kg = np.argsort(d_kg)[1]
print("vecino en kg:", vecino_kg, X[vecino_kg], especie[vecino_kg])
print("distancia:", round(d_kg[vecino_kg], 2))
```

<!-- #region -->
<details><summary>Resultado esperado</summary>

~~~text
vecino en kg: 5 [  38.9   17.8  181.  3625. ] Adelie
distancia: 0.93
~~~
</details>

El vecino cambió: ahora es un pingüino con la misma aleta (181 mm) y un pico casi igual, aunque
pesa 125 g menos.
<!-- #endregion -->

La figura muestra los 342 pingüinos en dos de sus cuatro variables, el largo de la aleta y la
masa, y marca el pingüino 0 y sus dos vecinos.

```python
fig, ax = plt.subplots(figsize=(7, 5))
for nombre, color in [("Adelie", "tab:blue"), ("Chinstrap", "tab:orange"),
                      ("Gentoo", "tab:green")]:
    filas = X[especie == nombre]
    ax.scatter(filas[:, 2], filas[:, 3], s=12, alpha=0.35, color=color, label=nombre)
ax.scatter(X[0, 2], X[0, 3], s=120, color="black", label="pinguino 0")
ax.scatter(X[vecino, 2], X[vecino, 3], s=120, marker="s", facecolors="none",
           edgecolors="black", linewidths=2, label="vecino en gramos")
ax.scatter(X[vecino_kg, 2], X[vecino_kg, 3], s=120, marker="^", facecolors="none",
           edgecolors="black", linewidths=2, label="vecino en kilogramos")
ax.set_xlabel("largo de la aleta (mm)")
ax.set_ylabel("masa (g)")
ax.legend(fontsize=9)
plt.show()
```

**Cómo leer la figura.** El vecino en gramos, el cuadrado, está a la misma altura que el
pingüino 0: tiene la misma masa, aunque su aleta mide 12 mm más. El vecino en kilogramos, el
triángulo, está justo debajo: tiene la misma aleta y pesa 125 g menos. Cada unidad escoge como
vecino al pingüino que se parece en la variable que domina la distancia. La figura misma también
escogió escalas para sus ejes: en ella el triángulo parece más cerca que el cuadrado, porque el
eje de la masa encoge 125 g a una distancia corta. Ninguna de las tres miradas es "la correcta".

¿Pasa solo con este pingüino? La función `vecinos` busca el vecino más cercano de **todos** los
pingüinos: para cada pingüino `i` repite el cálculo del Paso 3 con `M - M[i]`, pone infinito
(`np.inf`) en su propia distancia para que nadie sea su propio vecino y guarda el índice de la
menor distancia (`argmin`). Completa las dos líneas marcadas, quita los `#` y ejecuta.

```python
def vecinos(M):
    resultado = []
    for i in range(len(M)):
        d = np.linalg.norm(M - M[i], axis=1)   # el Paso 3, para el pinguino i
        d[i] = np.inf                          # nadie es su propio vecino
        resultado.append(d.argmin())
    return np.array(resultado)


# v_g = vecinos(X)
# v_kg = ____                       # <- completa: los vecinos con la masa en kg
# print("vecinos que cambian:", (v_g != v_kg).sum(), "de", len(X))
# print("misma especie, gramos:", round((especie[v_g] == especie).mean(), 3))
# print("misma especie, kilogramos:", round(____, 3))   # <- completa
```

<!-- #region -->
<details><summary>Resultado esperado</summary>

~~~text
vecinos que cambian: 323 de 342
misma especie, gramos: 0.871
misma especie, kilogramos: 0.965
~~~
</details>

El vecino cambia para 323 de los 342 pingüinos. Con la masa en kilogramos, el 96.5% de los
pingüinos tiene un vecino de su misma especie; en gramos, el 87.1%. La unidad de una sola
variable cambió la respuesta a "¿quién se parece a quién?".
<!-- #endregion -->

## Tu turno

### Ejercicio 1: una media es un producto punto

Con el vector de unos $\mathbf{1}$ de $\mathbb{R}^{342}$, el producto punto
$\mathbf{1} \cdot \mathbf{x}$ suma las componentes de $\mathbf{x}$. Calcula la masa media de los
342 pingüinos como $\frac{1}{n}\,\mathbf{1} \cdot \mathbf{x}$, donde $\mathbf{x}$ es la columna de
la masa, y compárala con `X[:, 3].mean()`. Redondea a un decimal.

```python
# TODO: tu codigo aqui (np.ones(n) crea el vector de unos)
```

<!-- #region -->
<details><summary>Resultado esperado</summary>

~~~text
4201.8 4201.8
~~~

La media de una columna es un producto punto: la columna por el vector $\frac{1}{n}\mathbf{1}$,
cuyas componentes son los coeficientes $1/n$ de la combinación lineal de la L01.
</details>
<!-- #endregion -->

### Ejercicio 2: ¿quién decide en kilogramos?

En gramos, la masa decidía la distancia. Calcula, para el primer pingüino y con la masa en
kilogramos, qué parte de la suma de los cuadrados de las diferencias viene de **cada** variable
(redondea a 3 decimales). Después explica en dos oraciones por qué cambió el vecino y si los
kilogramos resolvieron el problema.

```python
# TODO: tu codigo aqui (los cuadrados de X_kg - X_kg[0], sumados por columna)
```

<!-- #region -->
<details><summary>Resultado esperado</summary>

~~~text
[0.081 0.01  0.908 0.001]
~~~

En kilogramos, las diferencias de masa son décimas, y la variable con las diferencias más
grandes pasa a ser el largo de la aleta (en mm), que aporta el 90.8%: por eso el vecino nuevo
tiene la misma aleta. Los kilogramos no resolvieron el problema, solo lo movieron: ahora decide
la aleta. Una distancia que no dependa de las unidades necesita estandarizar cada variable, el
tema de la L04.
</details>
<!-- #endregion -->

### Ejercicio 3: el pingüino más típico

¿Cuál es el pingüino más cercano al vector media (*mean vector*)? Usa los datos en kilogramos
(`X_kg`), escoge una norma y justifica la elección en una oración. Muestra el índice, la especie
y las medidas originales del pingüino, `X[i]`. Después repítelo con las otras dos normas: ¿cambia la respuesta?

```python
# TODO: tu codigo aqui (la media es X_kg.mean(axis=0))
```

<!-- #region -->
<details><summary>Resultado esperado</summary>

~~~text
338 Chinstrap [  43.5   18.1  202.  3400. ]
~~~

Con las tres normas sale el mismo pingüino, el 338, un Chinstrap. Una justificación posible:
$\ell_2$ es la distancia en línea recta, la que usa la geometría del curso; $\ell_\infty$ diría
"el pingüino cuya peor diferencia con la media es menor". Que las tres coincidan hace la
respuesta más confiable. Como en la L01, el vector media es un punto calculado, no un animal
medido: el pingüino 338 es el que más se le acerca, pero no tiene sus medidas.
</details>
<!-- #endregion -->

## Resumen

- `u @ v` (o `np.dot(u, v)`) es el producto punto, un número; `u @ u` es $\|\mathbf{u}\|^2$.
- `np.linalg.norm(v, ord=1)`, `np.linalg.norm(v)` y `np.linalg.norm(v, ord=np.inf)` son las
  normas $\ell_1$, $\ell_2$ y $\ell_\infty$; la distancia es la norma de la diferencia.
- `X - x0` resta `x0` de cada fila (difusión), y `np.linalg.norm(..., axis=1)` da una distancia
  por fila.
- Con datos en unidades distintas, la variable con los números más grandes decide la distancia:
  el vecino más cercano cambió para 323 de 342 pingüinos al pasar de gramos a kilogramos.
- Próxima lección (L03): el ángulo entre vectores y la similitud coseno (*cosine
  similarity*), y la demostración de la
  desigualdad triangular para $\ell_2$.
