# NEON // Titán del tiempo

Abre `project.godot` con Godot 4.2 o posterior y pulsa **F5**. No necesitas addons ni descargar recursos externos.

## Pelea isométrica contra el boss

Selecciona **DESAFIAR AL TITÁN** en el menú. El gigante verde protege su cabeza hasta que se congela el tiempo.

1. **Aviso (2,5 s):** acércate al cuadrado dorado frente al gigante.
2. **Lluvia roja (3 s):** esquiva los proyectiles. Los cuadrados rojos indican dónde van a caer.
3. **Tiempo congelado (8 s):** las balas se detienen y la cabeza se vuelve dorada. Ve al cuadrado dorado, pulsa **E** para colocar una escalera y **E otra vez** para subir. Apunta con el ratón a la cabeza y ataca. Solo puedes dañarla desde arriba durante esta fase.
4. **Reanudación (2,2 s):** las balas vuelven a caer. Pulsa **E** para bajar antes de que termine la pausa. Al iniciar el siguiente ciclo la escalera se retira y vuelves al suelo. Recuperas 8 puntos de vida por ciclo.

La escalera se coloca únicamente en la zona dorada, dentro de un radio de 3 metros. La subida dura 1,8 segundos. Puedes bajar con E. La vida del boss aparece arriba a la derecha. El combate termina con victoria o derrota y puedes reiniciarlo.

## Controles

- **WASD o flechas:** moverte según la pantalla isométrica.
- **Ratón:** apuntar. **Clic izquierdo mantenido:** atacar.
- **1:** espada. **2:** arco.
- **E:** colocar escalera, subir o bajar (boss).
- **Espacio:** dash con invulnerabilidad breve y 2 segundos de recarga.
- **Shift:** correr. **Esc:** pausa. **M:** activar o silenciar música y efectos.

## Arena original

El botón **ARENA DE OLEADAS** conserva el modo de supervivencia anterior: drones, enemigos resistentes desde la tercera oleada y mejoras de daño, velocidad o curación. Cada baja recupera algo de vida.

## Recursos y validación

La geometría del boss, la escalera y la arena se generan en Godot. La música electrónica y los efectos WAV fueron sintetizados expresamente para este proyecto, sin muestras externas. `audio/battle.wav.import` configura la reproducción en bucle. El modelo stickman original se conserva, aunque esta versión no lo usa.

Probado con Godot 4.6.3 sin interfaz gráfica: carga, ciclos de caída/congelación/reanudación, colocación y subida, daño de espada y arco a la cabeza, inmunidad fuera de la ventana, victoria, derrota, reinicio, pausa, música en bucle y modo de oleadas. El sonido por altavoces y la presentación visual deben comprobarse al jugar en tu computadora.
