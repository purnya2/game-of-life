# NOTES

Il tempo passa all'aumentare del tick di una variabile *t*

ogni cella ha il suo behaviour, 
in base alle celle vicine, una cella in tempo t0, decide dove si trova in t1

regole di sviluppo/morte possano essere definite tramite file di configurazione.

regole base :

- Any live cell with fewer than two live neighbours dies, as if by underpopulation.
- Any live cell with two or three live neighbours lives on to the next generation.
- Any live cell with more than three live neighbours dies, as if by overpopulation.
- Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction

definire un confine di morte certa per gli elementi
