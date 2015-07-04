% -*- Mode: Prolog -*-

% Reference: Yann-Michaël De Hauwere
%            Declarative Programming
%            Vrije Univeriteit Brussel

% A slight modification has been made in the algorithm. Instead
% of using immediate values, the algorithm needs a predicate to
% get the value of elements.

% We will use the algorithm with a list of customer ids. A predicate
% will then be used to get the min pickup time. Ultimately we will get
% a list of customer ids that is sorted on their min pickup time.

partition(_SortPred, [], _N, [], []).
partition( SortPred, [Head|Tail], N, [Head|Littles], Bigs) :-
	call(SortPred, Head, ValHead),
	call(SortPred, N, ValN),
	ValHead < ValN,
	partition(SortPred, Tail, N, Littles, Bigs).
partition( SortPred, [Head|Tail], N, Littles, [Head|Bigs]):-
	call(SortPred, Head, ValHead),
	call(SortPred, N, ValN),
	ValHead >= ValN,
	partition(SortPred, Tail, N, Littles, Bigs).

quicksort(_SortPred, [], []).
quicksort( SortPred, [X|Xs], Sorted):-
	partition(SortPred, Xs, X, Littles, Bigs),
	quicksort(SortPred, Littles, SortedLittles),
	quicksort(SortPred, Bigs, SortedBigs),
	append(SortedLittles, [X|SortedBigs], Sorted).

