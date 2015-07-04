% -*- Mode: Prolog -*-

% Copyright Wouter Van Rossem

% ************************** Imports **************************
% *************************************************************
:- consult(city2).
:- consult(quicksort).
:- consult(dijkstra).

% ******************** Helper Predicates **********************
% *************************************************************

% Get the minimum pickup time of a customer.
% +Customer -Time
min_pick_up(Customer, Time) :-
	customer(Customer, Time, _LatestTime, _From, _To).

% Sort the customers on their minimum pickup time. Uses the
% quicksort algorithm to do the sorting.
% -SortedCustomers
sort_customers(SortedCustomers) :-
	findall(C, customer(C, _, _, _, _), AllCustomers),
	quicksort(min_pick_up, AllCustomers, SortedCustomers).

% Gets all the available Taxis from the database.
% -Taxis
get_taxis(Taxis) :-
	findall(T, taxi(T), Taxis).

% Initializes the TaxiPositions assoc.
% -TaxiPositions
init_taxi_positions(TaxiPositions) :-
	empty_assoc(TaxiPositions).

% Gets the current position and time of a taxi.
% +Taxi +Taxis -Position -Time
get_taxi_position(Taxi, Taxis, Position, Time) :-
	get_assoc(Taxi, Taxis, [Position,Time]).

% Updates the position and time of a taxi
% +Taxi +TaxiPositions +Position +Time -NewTaxiPositions
update_taxi_position(Taxi, TaxiPositions, Position, Time, NewTaxiPositions) :-
	get_assoc(Taxi, TaxiPositions, OldPosition, NewTaxiPositions, [Position, Time]),
	print('Moving Taxi '), print(Taxi),
	print(' From: '), print(OldPosition),
	print(' To: '), print([Position, Time]).

% Add a new taxi and its corresponding position and time to the TaxiPositions
% +Taxi +TaxiPositions +Position +Time -NewTaxiPositions
add_taxi_position(Taxi, TaxiPositions, Position, Time, NewTaxiPositions) :-
	put_assoc(Taxi, TaxiPositions, [Position, Time], NewTaxiPositions).
	%print('NEW Taxi '), print(Taxi),
	%print(' To: '),print([Position, Time]).	  

% Get the start position of a customer.
% +Customer -Position
get_customer_position(Customer, Position) :-
	customer(Customer, _, _, Position, _).

% Gets the destination position of a customer.
% +Customer -Destination
get_customer_destination(Customer, Destination) :-
	customer(Customer, _, _, _, Destination).

% Calculate the duration of Start to Destination
% +StartPos +Destination -Duration
calc_duration(StartPos, Destination, Duration) :-
	% Add caching to dijkstra
	dijkstra_path(StartPos, Destination, _Path, Duration).

% *************************************************************



% ******************** Scheduler Predicates *******************
% *************************************************************

% Run the scheduler
% -FinalTaxiPositions
scheduler(FinalTaxiPositions) :-
	print('*** Starting Taxi Scheduler *** \n'),
	sort_customers(Customers),
	get_taxis(Taxis),
	init_taxi_positions(TaxiPositions),
	schedule_taxis(Taxis, [], Customers, TaxiPositions, FinalTaxiPositions).

% Sequentially serve all the customers
% +Taxis +UsedTaxis +Customers +TaxiPostions -FinalTaxiPositions
schedule_taxis(_Taxis, _UsedTaxis, [], TaxiPositions, TaxiPositions).
schedule_taxis(Taxis, UsedTaxis, [Customer|Customers], TaxiPositions, FinalTaxiPositions) :-
	print('* Scheduling Customer '), print(Customer), print('\n'),
	send_taxi(Taxis, UsedTaxis, Customer, TaxiPositions, NewTaxiPositions, NewUsedTaxis),
	schedule_taxis(Taxis, NewUsedTaxis, Customers, NewTaxiPositions, FinalTaxiPositions).

% Check if a Taxi has already been used
% + Taxi +UsedTaxis
is_used_taxi(Taxi, UsedTaxis) :-
	member(Taxi, UsedTaxis).

% Add a Taxi to the UsedTaxis list
% +Taxi +UsedTaxis -NewUsedTaxis
add_used_taxi(Taxi, UsedTaxis, NewUsedTaxis) :-
	append([Taxi], UsedTaxis, NewUsedTaxis).

% Send out a NEW Taxi to the customer and drive him/her to his/her destination
% +Taxis +UsedTaxis +Customer +TaxiPositions -NewTaxiPositions -NewUsedTaxis
send_taxi([Taxi|_Taxis], UsedTaxis, Customer, TaxiPositions, NewTaxiPositions, NewUsedTaxis) :-
	not(is_used_taxi(Taxi, UsedTaxis)),
	!,
	customer(Customer, Earliest, _Latest, CustStart, _CustEnd),
	dijkstra_path(0, CustStart, Path, Duration),
	% Set the taxi position to pickup node and time to earliest pickup
	print('\tSending NEW taxi '), print(Taxi),
	print(' to Pos '), print(CustStart),
	print(' , ArrivalTime = '), print(Earliest),
	print(' , Duration = '), print(Duration),
	print(' , Path = '), print(Path), print('\n'),
	add_taxi_position(Taxi, TaxiPositions, CustStart, Earliest, TempTaxiPositions),
	add_used_taxi(Taxi, UsedTaxis, NewUsedTaxis),
	% Drive the customer to its destination
	drive_customer(Taxi, Customer, TempTaxiPositions, NewTaxiPositions).

% We find a taxi that is already out that can take the customer and drive him/her to his/her
% destination
% +Taxis +UsedTaxis +Customer +TaxiPositions -NewTaxiPostions -UsedTaxis
send_taxi([Taxi|_Taxis], UsedTaxis, Customer, TaxiPositions, NewTaxiPositions, UsedTaxis) :-
	get_taxi_position(Taxi, TaxiPositions, TaxiPos, TaxiTime),
	customer(Customer, Earliest, Latest, CustStart, _CustEnd),
	dijkstra_path(TaxiPos, CustStart, _Path, Duration),
	TripEndTime is TaxiTime + Duration,
	% Can the taxi reach the customer on time?
	TripEndTime =< Latest,
	% Arrival time for pickup must not be < earliest pickup time
	taxi_arrival_time(TaxiTime, Duration, Earliest, ArrivalTime),
	print('\tUpdating taxi '), print(Taxi),
	print(' from Pos '), print(TaxiPos),
	print(' to Pos '), print(CustStart),
	print(' , ArrivalTime: '), print(Earliest),
	print(' , Duration: '), print(Duration),
	print(' , Path = '), print(Path), print('\n'),
	update_taxi_postion(Taxi, TaxiPositions, CustStart, ArrivalTime, TempTaxiPositions),
	drive_customer(Taxi, Customer, TempTaxiPositions, NewTaxiPositions).

% Check if the next taxi in the list can pick up the customer
% +Taxis +UsedTaxis +Customer +TaxiPositions -NewTaxiPostions -UsedTaxis
send_taxi([_Taxi|Taxis], UsedTaxis, Customer, TaxiPositions, NewTaxiPositions, UsedTaxis) :-
	send_taxi(Taxis, UsedTaxis, Customer, TaxiPositions, NewTaxiPositions, UsedTaxis).

% Drive a customer to his/her destination
% +Taxi +Customer +TaxiPositions -NewTaxiPositions
drive_customer(Taxi, Customer, TaxiPositions, NewTaxiPositions) :-
	get_taxi_position(Taxi, TaxiPositions, TaxiPos, TaxiTime),
	customer(Customer, _Earliest, _Latest, _CustStart, CustEnd),
	dijkstra_path(TaxiPos, CustEnd, Path, Duration),
	ArrivalTime is TaxiTime + Duration,
	print('\tDriving Customer '), print(Customer),
	print(' in Taxi '), print(Taxi),
	print(' from Pos '), print(TaxiPos),
	print(' to Pos '), print(CustEnd),
	print(' - Duration = '), print(Duration),
	print(' , Path = '), print(Path),
	print(' , Arrival = '), print(ArrivalTime), print('\n'),
	update_taxi_position(Taxi, TaxiPositions, CustEnd, ArrivalTime, NewTaxiPositions).

% Calculate the optimal arrival time for a Taxi.
% If the Taxi could arrive before the earliest arrival time, the taxi
% will arrive on that time instead.
% +TaxiTime +Duration +Earliest -ArrivalTime
taxi_arrival_time(TaxiTime, Duration, Earliest, ArrivalTime) :-
	TaxiTime + Duration =< Earliest,
	!,
	ArrivalTime is Earliest.
taxi_arrival_time(TaxiTime, Duration, _Earliest, ArrivalTime) :-
	ArrivalTime is TaxiTime + Duration.

% *************************************************************

