% -*- Mode: Prolog -*-

% NODES
node(0, 0, 0). %A
node(1, 0, 1). %B
node(2, 0, 2). %C
node(3, 0, 3). %D
node(4, 0, 4). %E
node(5, 0, 5). %F
node(6, 0, 6). %G
node(7, 0, 7). %H

% A->B
edge(0, 1, 20).
% A->D
edge(0, 3, 80).
% A->G
edge(0, 6, 90).
% B->F
edge(1, 5, 10).
% C->H
edge(2, 7, 20).
% C->F
edge(2, 5, 50).
% D->G
edge(3, 6, 20).
% E->G
edge(4, 6, 30).
% E->B
edge(4, 1, 50).
% F->D
edge(5, 3, 40).
% F->C
edge(5, 2, 10).
% G->A
edge(6, 0, 20).
% H no out edges