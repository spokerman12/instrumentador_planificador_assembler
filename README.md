# Instrumentador y planificador en MIPS

En este proyecto, se pide implementar dos procesos complementarios para la
arquitectura de procesador MIPS.
El primero es un instrumentador, el cual debe analizar las instrucciones de un
programa de entrada y realizar los siguientes cambios:
- Si hay un add, debe insertar un break 0x20 debajo del mismo
Al insertar el break 0x20, todas las instrucciones debajo del add deben ser
trasladadas 4 bytes. Si hay un beq cuyo inmediato apunte a una dirección que
está por encima del add, es necesario corregir el inmediato para que apunte a la
instrucción correcta.
- Si hay un syscall 10, debe reemplazarlo por un break 0x10.
El segundo es un planificador de tiempo exclusivo (y compartido en el caso de la
actividad adicional). El planificador requiere de un manejador de excepciones, en
este caso una versión modificada del manejador para SPIM S20 MIPS.
El planificador requiere que el manejador de excepciones reconozca las siguientes
interrupciones:
- Cuando el usuario presiona la tecla 's'. En este caso, el planificador pasará al
siguiente programa.
- Cuando el usuario presiona la tecla 'p'. En este caso, el planificador pasará al
programa anterior.
- Cuando el usuario presiona la tecla 'esc'. En este caso, el planificador cesará la
ejecución e imprimirá el estado de finalización de cada programa, junto al número
de add que contiene cada uno.
- Cuando se ejecuta un break 0x10. Esta instrucción finaliza el programa
actual.