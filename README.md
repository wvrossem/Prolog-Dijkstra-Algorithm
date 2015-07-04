# Prolog-Dijkstra-Algorithm
Prolog taxi scheduler application using Dijkstra's algorithm.

This application will try to optimally schedule taxis in order to pick up customers.

This is done by using Dijkstra's algorithm for finding the shortest path, and for which an implementation is provided.

The code can be run by consulting `scheduler.pl` and calling `scheduler(FinalTaxiPositions)`.

In order to only test Dijkstra's algorithm the `graph.pl` can be used:

````
% 0 is that start node = A
?- dijkstra(0, Costs, Prevs).
% 0 is start node = A, 2 is destination = D
?- dijkstra_path(0, 2, Path, Cost).
```
