% -*- Mode: Prolog -*-

% Copyright Wouter Van Rossem

% Information on assocs can be found here:
% http://www.complang.tuwien.ac.at/SWI-Prolog/Manual/assoc.html



% ******************** Helper Predicates **********************
% *************************************************************

% Check if a node is solved, i.e. that it is in the solved list
% +SolvedNodes +Node
is_solved(SolvedNodes, Node) :-
	member(Node, SolvedNodes).

% Get the current cost of a certain node.
% +Node +Costs -Cost
get_cost(Node, Costs, Cost) :-
	get_assoc(Node, Costs, Cost).

% Immediatly modifies a cost
% +Node +Costs +Val -NewCosts
modify_cost(Node, Costs, Val, NewCosts) :-
	get_assoc(Node, Costs, _OldCost, NewCosts, Val).

% Gets the next node on the agenda
% +Agenda -Node
get_next_node([Node|_Rest], Node).

% Add a node to the solved nodes
% +Node +SolvedNodes -NewSolvedNodes
add_solved(Node, SolvedNodes, NewSolvedNodes) :-
	append([Node], SolvedNodes, NewSolvedNodes).

% Is this list empty
% +List
is_empty([]).

% *************************************************************




% ******************** Neighbor predices **********************
% *************************************************************

% Get all the unsolved neighbor nodes of a certain node	
% +Node +SolvedNodes ?Neighbors 
neighbors(Node, SolvedNodes, Neighbors) :-
	findall(N, edge(Node, N, _Distance), TempNeighbors),
	% Filters out the nodes that are solved
	exclude(is_solved(SolvedNodes), TempNeighbors, Neighbors).

% Updates the costs of the neighbors
% This will also update the previous nodes and the agenda
% +From +Neighbors +Costs -NewCosts +Prevs -Prevs +Agenda -NewAgenda
update_neighbors_costs(_From, [], Costs, Costs, Prevs, Prevs, Agenda, Agenda).
update_neighbors_costs(From, [Neighbor|Rest], Costs, NewCosts,
		       Prevs, NewPrevs, Agenda, NewAgenda) :-
	update_cost(From, Neighbor, Costs, TempCosts, Prevs,
		    TempPrevs, Agenda, TempAgenda),
	update_neighbors_costs(From, Rest, TempCosts, NewCosts,
			       TempPrevs, NewPrevs, TempAgenda, NewAgenda).

% Update the cost of a single node
% This will only update it if the newly found path to the node is cheaper
% +FromNode +ToNode +Costs -NewCosts +Prevs -NewPrevs +Agenda ⁻NewAgenda
update_cost(FromNode, ToNode, Costs, NewCosts, Prevs, NewPrevs, Agenda, NewAgenda) :-
	get_assoc(ToNode, Costs, ToCost),
	ToCost =:= -1,
	get_assoc(FromNode, Costs, FromCost),
	edge(FromNode, ToNode, Weight),
	NewCost is FromCost + Weight,
	get_assoc(ToNode, Costs, _OldCost, NewCosts, NewCost),
	get_assoc(ToNode, Prevs, _OldPrev, NewPrevs, FromNode),
	% Update the weights of the node in the agenda
	% So that it will higher in the queue.
	% First we remove it from the agenda and then add
	% it again in order to get it in the right position
	remove_from_agenda(ToNode, Agenda, TmpAgenda),
	add_to_agenda([ToNode], TmpAgenda, NewCosts, NewAgenda).
% Update the cost of a single node
% This will only update it if the newly found path to the node is cheaper
% +FromNode +ToNode +Costs -NewCosts +Prevs -NewPrevs +Agenda ⁻NewAgenda
update_cost(FromNode, ToNode, Costs, NewCosts, Prevs, NewPrevs, Agenda, NewAgenda) :-
	get_assoc(FromNode, Costs, FromCost),
	get_assoc(ToNode, Costs, ToCost),
	edge(FromNode, ToNode, Weight),
	NewCost is FromCost + Weight,
	ToCost >= NewCost,
	get_assoc(ToNode, Costs, _OldCost, NewCosts, NewCost),
	get_assoc(ToNode, Prevs, _OldPrev, NewPrevs, FromNode),
	% Update the weights of the node in the agenda
	% So that it will higher in the queue.
	% First we remove it from the agenda and then add
	% it again in order to get it in the right position
	remove_from_agenda(ToNode, Agenda, TmpAgenda),
	add_to_agenda([ToNode], TmpAgenda, NewCosts, NewAgenda).

% *************************************************************


% ********************* Agenda Predicates *********************
% *************************************************************

% Initialize the agenda
% +Start +Costs ?Agenda
init_agenda(Start, Costs, Agenda) :-
	findall(N, edge(Start, N, _Weight), TempAgenda),
	add_to_agenda(TempAgenda, [], Costs, Agenda).

% Update the agenda with new nodes
% +Nodes +Agenda +Costs -NewAgenda
update_agenda([], Agenda, _Costs, Agenda).
update_agenda([Node|Rest], Agenda, Costs, NewAgenda) :-
	member(Node, Agenda),
	!,
	update_agenda(Rest, Agenda, Costs, NewAgenda).
update_agenda([Node|Rest], Agenda, Costs, NewAgenda) :-
	add_to_agenda([Node], Agenda, Costs, NewAgenda),
	update_agenda(Rest, Agenda, Costs, NewAgenda).
	
	
% Add nodes to the agenda
% +Neighbors +Agenda +Costs -NewAgenda
add_to_agenda([], Agenda, _Costs, Agenda).
add_to_agenda([Neighbor|Neighbors], OldAgenda, Costs, NewAgenda) :-
	add_one(Neighbor, OldAgenda, Costs, TmpAgenda),
	add_to_agenda(Neighbors, TmpAgenda, Costs, NewAgenda).

% Add a node to the agenda
% +Neighbor +Agenda +Costs -NewAgenda
add_one(Neighbor, OldAgenda, Costs, NewAgenda) :-
	get_cost(Neighbor, Costs, Cost),
	add_one(Cost, Neighbor, OldAgenda, Costs, NewAgenda).	
add_one(_Cost, Neighbor, [], _Costs, [Neighbor]).
add_one(Cost, Neighbor, [Node|Rest], Costs, [Neighbor, Node|Rest]) :-
	get_cost(Node, Costs, C),
	Cost<C.
add_one(Cost, Neighbor, [Node|Rest], Costs, [Node|NewRest]) :-
	get_cost(Node, Costs, C),
	Cost>=C,
	add_one(Cost, Neighbor, Rest, Costs, NewRest).
	
% Remove a node from the agenda
% +Node +Agenda -NewAgenda
remove_from_agenda(Node, Agenda, Agenda) :-
	not(member(Node, Agenda)),
	!.
remove_from_agenda(Node, [Node|Rest], Rest).
remove_from_agenda(Node, [N|Rest], [N|Rest2]) :-
	remove_from_agenda(Node, Rest, Rest2).
	
% *************************************************************

% ******************* Dijkstra algorithm **********************
% *************************************************************

% Computes the shortest path to all the nodes from a Start node
% +Start -Costs -Prevs
dijkstra(Start, Costs, Prevs) :-
	initialize(IniCosts, IniPrevs),
	modify_cost(Start, IniCosts, 0, TmpCosts),
	%SolvedNodes is [Start],
	%init_agenda(Start, TmpCosts, Agenda),
	dijkstra_loop([Start], [], TmpCosts, IniPrevs, Costs, Prevs).

% Main loop of the dijkstra algorithm for computing the shortest paths
% +Agenda +SolvedNodes +Costs +Prevs -FinalCosts -FinalPrevs
dijkstra_loop([], _SolvedNodes, Costs, Prevs, Costs, Prevs). 
dijkstra_loop([Node|AgendaRest], SolvedNodes, Costs,
	      Prevs, FinalCosts, FinalPrevs) :-
	add_solved(Node, SolvedNodes, NewSolvedNodes),
	neighbors(Node, NewSolvedNodes, Neighbors),
	update_neighbors_costs(Node, Neighbors, Costs, NewCosts,
			       Prevs, NewPrevs, AgendaRest, NewAgenda),
	%update_agenda(Neighbors, AgendaRest, Costs, Agenda),
	% Next node is the one with lowest cost
	dijkstra_loop(NewAgenda, NewSolvedNodes, NewCosts,
		      NewPrevs, FinalCosts, FinalPrevs).





% Computes the shortest path from the Start node to the End node.
% Also returns the total cost of the path.
% +Start +End -Path -Cost
dijkstra_path(Start, End, Path, Cost) :-
	initialize(IniCosts, IniPrevs),
	modify_cost(Start, IniCosts, 0, TmpCosts),
	%print('*****************************************\n'),
	%print('Starting new Dijkstra loop with Start = '), print(Start),
	%print(' and End = '), print(End), print('\n'),
	dijkstra_loop_path(End, [Start], [], TmpCosts, IniPrevs, Costs, Prevs),
	recreate_path(Start, End, Prevs, Path),
	get_cost(End, Costs, Cost).

% The main loop for the dijkstra algorithm that computes the shortest path from a Start
% node to an End node.
% +Goal +Agenda +Costs +Prevs -FinalCosts -FinalPrevs
dijkstra_loop_path(_Goal, [], _SolvedNodes, Costs, Prevs, Costs, Prevs).
dijkstra_loop_path(Goal, [Goal|AgendaRest], SolvedNodes, Costs,
		   Prevs, Costs, Prevs).  %:-
	%print('\tReached goal  - Agenda = '), print([Goal|AgendaRest]),
	%print(' , SolvedNode = '), print(SolvedNodes), print('\n'),
	%print('*****************************************\n').
dijkstra_loop_path(Goal, [Node|AgendaRest], SolvedNodes,
		   Costs, Prevs, FinalCosts, FinalPrevs) :-
	%print('\tDijkstra loop - Solving = '), print(Node),
	%print(' , Agenda = '), print(AgendaRest),
	%print(' , SolvedNode = '), print(SolvedNodes), print('\n'),
	not(is_solved(SolvedNodes, Node)),
	add_solved(Node, SolvedNodes, NewSolvedNodes),
	neighbors(Node, NewSolvedNodes, Neighbors),
	update_neighbors_costs(Node, Neighbors, Costs, NewCosts,
			       Prevs, NewPrevs, AgendaRest, NewAgenda),
	%update_agenda(Neighbors, AgendaRest, Costs, Agenda),
	% Next node is the one with lowest cost
	dijkstra_loop_path(Goal, NewAgenda, NewSolvedNodes, NewCosts,
			   NewPrevs, FinalCosts, FinalPrevs).
dijkstra_loop_path(Goal, [Node|AgendaRest], SolvedNodes, Costs,
		   Prevs, FinalCosts, FinalPrevs) :-	
	is_solved(SolvedNodes, Node),
	%print('\tSkipping Node '), print(Node), print('\n'),
	dijkstra_loop_path(Goal, AgendaRest, SolvedNodes, Costs,
			   Prevs, FinalCosts, FinalPrevs).


% Recreate the path from the Start to End node.
% +Start +End +Prevs -Path
recreate_path(Start, End, Prevs, Path) :-
	create_rev_path(Start, End, Prevs, [End], Path).

% Recursion function that computes the path starting from the end
% node and following the previous nodes until the start node.
% +Start +End +Prevs +TmpPath -Path
create_rev_path(Start, End, Prevs, TmpPath, Path) :-
	get_assoc(End, Prevs, Prev),
	Prev =:= Start,
	append([Prev], TmpPath, Path).
create_rev_path(Start, End, Prevs, TmpPath, Path) :-
	get_assoc(End, Prevs, Prev),
	append([Prev], TmpPath, NewPath),
	create_rev_path(Start, Prev, Prevs, NewPath, Path).




% **************** Initialization Predicates ******************
% *************************************************************

% Initializes the costs and previous nodes of all the nodes
% Costs of nodes are initialized to -1
% Previous nodes of nodes are initialized to 
% -Costs -Prevs
initialize(Costs, Prevs) :-
	findall(Node, node(Node, _X, _Y), AllNodes),
	empty_assoc(UninitCosts),
	empty_assoc(UninitPrevs),
	add_nodes_costs(AllNodes, UninitCosts, Costs),
	add_nodes_prevs(AllNodes, UninitPrevs, Prevs).
	
% Initializations of cost to reach nodes
% +Nodes +Costs -NewCosts
add_nodes_costs([], Costs, Costs).
add_nodes_costs([Node|Rest], Costs, NewCosts) :-
	add_one_cost(Node, Costs, TempCosts),
	add_nodes_costs(Rest, TempCosts, NewCosts).	
add_one_cost(Node, Costs, NewCosts) :-
	put_assoc(Node, Costs, -1, NewCosts).
	
% Initializations of previous in optimal path
% +Nodes +Prevs -NewPrevs
add_nodes_prevs([], Prevs, Prevs).
add_nodes_prevs([Node|Rest], Prevs, NewPrevs) :-
	add_one_prev(Node, Prevs, TempPrevs),
	add_nodes_prevs(Rest, TempPrevs, NewPrevs).	
add_one_prev(Node, Prevs, NewPrevs) :-
	put_assoc(Node, Prevs, -1, NewPrevs).

% *************************************************************