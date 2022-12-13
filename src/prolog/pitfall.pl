% Labyrinth size: 59x34
% Agent's initial energy: 100
% Enemies' initial energy: 100
% Ammo damage: 10
% Ammo count: unlimited
% Energy filled by power-ups: 10, 20, 50
% Game ends if agent dies by damage or falls into a pit


:- module(pitfall, [
    sense/1,
    learn/3,
    facing/1,
    set_agent_position/1,
    set_agent_facing/1,
    sense_learn_act/2,
    print_cave/0,
    disable_logging/0,
    enable_logging/0,
    force_update_position/1,
    certain/2,
    run_until_done/0,
    get_agent_health/1,
    get_game_score/1,
    world_position/2,
    agent_position/1,
    get_inventory/2,
    collected/2,
    set_last_observation/1,
    last_observation/1,
    set_game_score/1,
    update_agent_health/2
]).

:- use_module(a_star).
:- use_module(logging).

:- dynamic([
    world_position/2,
    world_count/2,
    possible_position/3,
    agent_position/1,
    facing/1,
    killed_enemy/0,
    kill_mode_count/1,
    heard_steps/0,
    goal/1,
    certain/2,
    collected/2,
    game_score/1,
    health/3,
    agent_health/1,
    inventory/3,
    last_observation/1,
    last_position/1,
    last_action/1,
    blocked_position/1
]).

:- enable_logging.

% assert_new/1
% assert_new(+Term)
% Assertz Term if not already known. Avoids duplicate entries in the KB.
assert_new(Term) :-
    \+ Term,
    assertz(Term),
    !.
assert_new(_).

agent_position((1,1)).

collected(gold_ring, 0).
collected(gold_coin, 0).
collected(power_up_10, 0).
collected(power_up_20, 0).
collected(power_up_50, 0).

%
% World information
% -----------------

set_agent_position((X,Y)) :-
    retractall(agent_position(_)),
    assertz(agent_position((X,Y))),
    retractall(world_position(agent, _)),
    assertz(world_position(agent, (X,Y))),
    !.

set_agent_facing(Dir) :-
    retractall(facing(_)),
    assertz(facing(Dir)),
    !.

set_last_observation((Steps, Breeze, Flash, Glow, Impact, Scream)) :-
    retractall(last_observation(_)),
    assertz(last_observation((Steps, Breeze, Flash, Glow, Impact, Scream))),
    !.

set_last_position((X, Y)) :-
    retractall(last_position(_)),
    assertz(last_position((X, Y))),
    !.

set_last_action(Action) :-
    retractall(last_action(_)),
    assertz(last_action(Action)),
    !.

facing(east). % TODO: no longer fixed

dir(north).
dir(east).
dir(south).
dir(west).

clockwise(north, east).
clockwise(east, south).
clockwise(south, west).
clockwise(west, north).

anticlockwise(north, west).
anticlockwise(west, south).
anticlockwise(south, east).
anticlockwise(east, north).

% adjacent/2
% adjacent(+Pos, ?NextPos, ?Direction)
adjacent((X, Y1), (X, Y2), south) :-
    Y2 is Y1 + 1.
adjacent((X, Y1), (X, Y2), north) :-
    Y2 is Y1 - 1.
adjacent((X1, Y), (X2, Y), west) :-
    X2 is X1 - 1.
adjacent((X1, Y), (X2, Y), east) :-
    X2 is X1 + 1.

minX(0). maxX(59).
minY(0). maxY(34).

% valid_position/1
% valid_position(+Pos)
valid_position((X, Y)) :-
    minX(MinX), maxX(MaxX), between(MinX, MaxX, X),
    minY(MinY), maxY(MaxY), between(MinY, MaxY, Y).


% TODO: Review cave elements for new map
% -----
% 1. 2 two small enemies (damage 20)
% 2. 2 large enemies (damage 50)
% 3. 8 pits
% 4. 3 gold
% 5. 4 teletransporting enemies
% 6. 3 power ups
% 7. Walls around the whole cave

% world_position/2
% world_position contains absolute world knowledge and should not be queried for decision making

world_position(agent, (1, 1)).

% Print cave for debugging

print_cave :-
    minY(MinY), maxY(MaxY),
    between(MinY, MaxY, Y),
    print_cave_line(Y).
% print_cave :-
%     get_agent_health(H),
%     get_game_score(S),
    % get_inventory(A, P),
    % NP is 3 - P,
    % collected(gold_ring, G1),
    % collected(gold_coin, G2),
    % (G is integer(G1)+integer(G2)),
    % log('Health: ~t~w~nScore: ~t~w~nAmmo: ~t~w~nGold: ~t~w~nPower ups: ~t~w~n',
    %     [H, S, A, G, NP]
    % ).
print_cave_line(Y) :-
    minX(MinX), maxX(MaxX),
    between(MinX, MaxX, X),
    print_cave_cell(X, Y),
    log(' '),
    fail.
print_cave_line(_) :- log('~n').
print_cave_cell(X, Y) :-
    world_position(agent, (X, Y)),
    facing(north),
    log('\033[48;5;35m^\033[0m'),
    !.
print_cave_cell(X, Y) :-
    world_position(agent, (X, Y)),
    facing(east),
    log('\033[48;5;35m>\033[0m'),
    !.
print_cave_cell(X, Y) :-
    world_position(agent, (X, Y)),
    facing(west),
    log('\033[48;5;35m<\033[0m'),
    !.
print_cave_cell(X, Y) :-
    world_position(agent, (X, Y)),
    facing(south),
    log('\033[48;5;35mv\033[0m'),
    !.
print_cave_cell(X, Y) :-
    blocked_position((X, Y)),
    log('\033[48;5;231m\033[38;5;0mB\033[0m'),
    !.
print_cave_cell(X, Y) :-
    certain(visited, (X,Y)),
    log('\033[48;5;231m\033[38;5;0m.\033[0m'),
    !.
print_cave_cell(X, Y) :-
    certain(safe, (X,Y)),
    log('\033[48;5;231m\033[38;5;0mS\033[0m'),
    !.
print_cave_cell(X, Y) :-
    certain(pit, (X,Y)),
    log('\033[48;5;238mP\033[0m'),
    !.
print_cave_cell(X, Y) :-
    certain(teleporter, (X,Y)),
    log('\033[48;5;26mT\033[0m'),
    !.
print_cave_cell(X, Y) :-
    certain(gold, (X,Y)),
    log('\033[48;5;220mO\033[0m'),
    !.
print_cave_cell(X, Y) :-
    possible_position(pit, (X,Y), _),
    possible_position(teleporter, (X,Y), _),
    log('+'),
    !.
print_cave_cell(X, Y) :-
    possible_position(pit, (X,Y), _),
    possible_position(teleporter, (X,Y), _),
    log('+'),
    !.
print_cave_cell(X, Y) :-
    possible_position(pit, (X,Y), _),
    log('\033[48;5;238mp\033[0m'),
    !.
print_cave_cell(X, Y) :-
    agent_position(AP),
    adjacent((X,Y), AP, _),
    heard_steps,
    log('\033[48;5;208md\033[0m'),
    !.
print_cave_cell(X, Y) :-
    possible_position(teleporter, (X,Y), _),
    log('\033[48;5;26mt\033[0m'),
    !.
print_cave_cell(_, _) :-
    log('\033[48;5;0m\033[38;5;0m?\033[0m'),
    !.


%
% Health Tracking
% ------
% Agent's initial energy: 100
% Enemies' initial energy: 100

% initial_health/2
% Initializes health for agent and enemies --> all 100 HP
initial_health(agent, 100).
initial_health(enemy, 100).

% get_health/3
% Given a character (excluding agent) and their position on the map, get said character's health
% If character's health hasn't been tracked yet, initialize new health
get_health(Pos, Character, Health) :-
    health(Pos, Character, Health),
    !.
get_health(Pos, Character, Health) :-
    world_position(Character, Pos),
    initial_health(Character, Health),
    assertz(health(Pos, Character, Health)),
    !.

% update_health/3
% Given a character (excluding agent) and their position on the map, update said character's health
% If NewHealth <= 0, call character_killed rule
update_health(Pos, Character, NewHealth) :-
    (NewHealth > 0),
    retractall(health(Pos, Character, _)),
    assertz(health(Pos, Character, NewHealth)),
    !.
update_health(Pos, Character, _) :-
    retractall(health(Pos, Character, _)),
    assertz(health(Pos, Character, 0)),
    character_killed(Character, Pos),
    !.

% character_killed/1
% Called when character's (except agent) HP reaches 0
character_killed(EnemyType, EnemyPos) :-
    log('Character killed!~n'),
    retractall(world_position(EnemyType, EnemyPos)),
    (   EnemyType = teleporter
    ->  CountType = teleporter
    ;   CountType = enemy
    ),
    world_count(CountType, C),
    NC is C - 1,
    retractall(world_count(CountType, _)),
    assertz(world_count(CountType, NC)),
    assertz(killed_enemy),
    killing_enemy_score,
    !.

% get_agent_health/1
% Get agent's health
% If agent's health hasn't been tracked yet, initialize new health
get_agent_health(Health) :-
    agent_health(Health),
    !.
get_agent_health(Health) :-
    initial_health(agent, Health),
    assertz(agent_health(Health)),
    !.

% update_agent_health/2
% Update agent's health
% When NewHealth <= 0, agent is killed, game over!
update_agent_health(NewHealth,_) :-
    (NewHealth > 0),
    retractall(agent_health(_)),
    assertz(agent_health(NewHealth)),
    !.
update_agent_health(_,Cost) :-
    retractall(agent_health(_)),
    assertz(agent_health(0)),
    agent_killed(Cost),
    !.

% agent_killed/1
% Called when agent's HP reaches zero, game over!
agent_killed(Cost) :-
    killed_score(Cost),
    log('You died! Game over!~n'),
    fail.


% 
% Score System: Costs and Rewards
% ------
% Assumes game score cannot be negative
% 1. Pick up: -5+{item cost}: 
%   - Golden Coins: +1000
%   - Golden Rings: +500
% 2. Falling in a pit: -1000
% 3. Getting killed by an enemy: -10
% 4. Killing an enemy: +1000
% 5. Shooting: -10
% 6. Other Actions (moving, turning, etc): -1

% initial_game_score/1
% Inicialize game score
initial_game_score(0).

% get_game_score/1
% Get the game's score
get_game_score(Score) :-
    game_score(Score),
    !.
get_game_score(Score) :-
    initial_game_score(Score),
    assertz(game_score(Score)),
    !.

set_game_score(NewScore) :-
    retractall(game_score(_)),
    assertz(game_score(NewScore)),
    !.

% update_game_score/1
% Update the game's score
update_game_score(NewScore) :-
    (NewScore >= 0),
    retractall(game_score(_)),
    assertz(game_score(NewScore)),
    !.
update_game_score(_).


% killed/1
% Killed by enemy -> Cost = -10 points
% Killed by pit   -> Cost = -1000 points
killed_score(Cost) :-
    get_game_score(OldScore),
    (NewScore is integer(OldScore)-integer(Cost)),
    update_game_score(NewScore),
    !.

% killing_enemy/0
% Killing an enemy -> +1000 points
killing_enemy_score :-
    get_game_score(OldScore),
    (NewScore is integer(OldScore)+1000),
    update_game_score(NewScore),
    !.



%
% Inventory
% ----
% Tracks ammo and power up usage
% Power ups count: (?)
% Ammo count: unlimited

% initial_inventory/3
initial_inventory(agent, 0, 0).

% get_inventory/2
% Get agent's inventory
get_inventory(Ammo, PowerUps) :-
    inventory(agent, Ammo, PowerUps),
    !.
get_inventory(Ammo, PowerUps) :-
    initial_inventory(agent, Ammo, PowerUps),
    assertz(inventory(agent, Ammo, PowerUps)),
    !.


%
% Observation and decision making
% ----

% sense_learn_act/2
% sense_learn_act(-Goal, -Action)
% Learns from the environment and acts accordingly, returning the current Goal and the Action it performed
sense_learn_act(Goal, Action) :-
    log('-----~n'),
    sense(Sensors),
    log('Learning:~n'),
    learn(Sensors, Goal, Action),
    print_cave,
    log('Goal: ~w~nAction: ~w~n', [Goal, Action]).

% sense/1
% sense(-Sensors)
sense((Steps, Breeze, Flash, Glow, Impact, Scream)) :-
    last_observation((Steps, Breeze, Flash, Glow, Impact, Scream)),
    write_sensors((Steps, Breeze, Flash, Glow, Impact, Scream)).

% learn/3
% learn(+Sensors, -Goal, -Action)
learn(Sensors, Goal, Action) :-
    update_knowledge(Sensors),
    update_goal(Goal),
    next_action(Goal, Action),
    set_last_action(Action).


% Sensors
% -----
% 1. Steps (adjacent cells to damage-inflicting enemies)
% 2. Breeze (adjacent cells to pits)
% 3. Flash (adjacent cells to teleporting enemies)
% 4. TODO: Glow (cells where gold is present)
%     - redLight  -> treasure
%     - blueLight -> power up
%     - weakLight -> unknown
% 5. Impact (when walking into a wall)
% 6. Scream (when an enemy dies)

write_sensors(Sensors) :-
    agent_position(AP),
    world_position(agent, ActualAP),
    facing(Dir),
    log('Agent~n~t~2|at: ~w~n~t~2|sensing: ~w~nWorld~n~t~2|agent at: ~w~n~t~2|facing: ~w~n', [AP, Sensors, ActualAP, Dir]),
    !.


% For testing only
force_update_position(NP) :-
    retractall(world_position(agent, _)),
    retractall(agent_position(_)),
    assertz(world_position(agent, NP)),
    assertz(agent_position(NP)).

%
% Update knowledge
% ------
% Updating knowledge should not use absolute world position, but agent perception,
% as it should reflect where the agent thinks it is

% update_knowledge/1
% update_knowledge(+Sensors)
update_knowledge(Sensors) :-
    Sensors = (Steps, Breeze, Flash, Glow, Impact, Scream),
    clear_transient_flags,
    % Update impact first in case the wall was hit in the previous step
    update_impact(Impact),
    update_scream(Scream),
    update_steps(Steps),
    update_breeze(Breeze),
    update_flash(Flash),
    update_glow(Glow),
    set_visited_cell,
    infer_dangerous_positions,
    infer_safe_positions.

clear_transient_flags :-
    retractall(heard_steps),
    retractall(killed_enemy).

set_visited_cell :-
    agent_position(AP),
    assert_new(certain(visited, AP)),
    set_last_position(AP),
    log('~t~2|visited: ~w~n', [AP]).

% update_steps/1
% update_steps(+Steps)
update_steps(steps) :-
    assertz(heard_steps).
update_steps(no_steps).

% update_breeze/1
% update_breeze(+Breeze)
update_breeze(Breeze) :-
    agent_position(AP),
    assert_new(certain(Breeze, AP)),
    update_pits(Breeze).

% update_pits/1
% update_pits(+Breeze)
update_pits(no_breeze) :-
    agent_position(AP),
    learn(no_pit, AP),
    adjacent(AP, P, _),
    valid_position(P),
    \+ blocked_position(P),
    learn(no_pit, P),
    fail.
update_pits(no_breeze).

update_pits(breeze) :-
    % If already found all pits
    world_count(pit, PC),
    aggregate_all(count, certain(pit, _), PC),
    !.
update_pits(breeze) :-
    agent_position(AP),
    adjacent(AP, P, _),
    valid_position(P),
    \+ blocked_position(P),
    \+ certain(no_pit, P),
    assert_new(possible_position(pit, P, AP)),
    fail.
update_pits(breeze).

% update_flash/1
% update_flash(+Flash)
update_flash(Flash) :-
    agent_position(AP),
    % Retract in case there was flash generated by a now killed teleporter
    retractall(certain(flash, AP)),
    assert_new(certain(Flash, AP)),
    update_teleporter(Flash).

% update_teleporter/1
% update_teleporter(+Flash)
update_teleporter(no_flash) :-
    agent_position(AP),
    assert_new(certain(no_teleporter, AP)),
    adjacent(AP, P, _),
    valid_position(P),
    \+ blocked_position(P),
    learn(no_teleporter, P),
    fail.
update_teleporter(no_flash) :- !.

update_teleporter(flash) :-
    % If already found all pits
    world_count(teleporter, TC),
    aggregate_all(count, certain(teleporter, _), TC),
    !.
update_teleporter(flash) :-
    agent_position(AP),
    adjacent(AP, P, _),
    valid_position(P),
    \+ blocked_position(P),
    \+ certain(no_teleporter, P),
    assert_new(possible_position(teleporter, P, AP)),
    fail.
update_teleporter(flash).

% update_glow/1
% update_glow(+Glow)
update_glow(Glow) :-
    agent_position(AP),
    % Retract in case we collected gold from this position
    retractall(certain(glow, AP)),
    assert_new(certain(Glow, AP)),
    update_gold(Glow).

% update_gold/1
% update_gold(+Glow)
update_gold(glow) :-
    agent_position(AP),
    assert_new(certain(gold, AP)),
    log('~t~2|gold position: ~w~n', [AP]).
update_gold(no_glow) :-
    agent_position(AP),
    % Retract in case we collected gold from this position
    retractall(certain(gold, AP)),
    assert_new(certain(no_gold, AP)).

% update_impact/1
% update_impact(+Impact)
update_impact(no_impact).
update_impact(impact) :-
    % If impact, a wall was hit on last move, so mark the position as blocked
    agent_position(AP),
    last_action(move_forward),
    facing(Dir),
    adjacent(AP, BlockedPos, Dir),
    learn(blocked, BlockedPos),
    log('~t~2|blocked position: ~w~n', [BlockedPos]),
    !.
update_impact(impact) :-
    % If impact, a wall was hit on last move, so mark the position as blocked
    agent_position(AP),
    last_action(move_backward),
    facing(Dir),
    clockwise(Dir, Dir90),
    clockwise(Dir90, Back),
    adjacent(AP, BlockedPos, Back),
    learn(blocked, BlockedPos),
    log('~t~2|blocked position: ~w~n', [BlockedPos]).

% update_scream/1
% update_scream(+Scream)
update_scream(no_scream).
update_scream(scream) :-
    assertz(killed_enemy).


% learn/2
% learn(+Item, +Location)
learn(no_teleporter, P) :-
    retractall(possible_position(teleporter, P, _)),
    retractall(certain(teleporter, P)),
    assert_new(certain(no_teleporter, P)).
learn(teleporter, P) :-
    retractall(possible_position(_, P, _)),
    assert_new(certain(teleporter, P)).
learn(no_pit, P) :-
    retractall(possible_position(pit, P, _)),
    assert_new(certain(no_pit, P)).
learn(pit, P) :-
    retractall(possible_position(_, P, _)),
    assert_new(certain(pit, P)).
learn(safe, P) :-
    % Do nothing if already known to be safe
    certain(safe, P),
    !.
learn(safe, P) :-
    member(Danger, [enemy, pit, teleporter]),
    retractall(possible_position(Danger, P, _)),
    fail.
learn(safe, P) :-
    assert_new(certain(safe, P)),
    log('~t~2|safe: ~w~n', [P]).
learn(blocked, P) :-
    retractall(certain(safe, P)),
    assert_new(blocked_position(P)).


% infer_dangerous_positions/0
% Use current knowledge to consolidate possible positions of dangers into certainties.
% Used for enemies, teleporters and pits.
% Eg. If there were steps at one cell with 4 neighbors and the agent is certain that 3
% of those have no enemies, than the enemy has to be on the fourth one.
infer_dangerous_positions :-
    % For each danger trio (Hint, NotThere, There)
    % e.g. (steps, no_enemy, enemy) or (breeze, no_pit, pit)
    Dangers = [(breeze, no_pit, pit), (flash, no_teleporter, teleporter)],
    member((Hint, NotThere, There), Dangers),
    % For each known Hint (e.g. steps) location
    certain(Hint, Pos),
    % Get valid neighboring cells
    findall(MaybeDangerPos, (
        adjacent(Pos, MaybeDangerPos, _),
        valid_position(MaybeDangerPos),
        \+ blocked_position(MaybeDangerPos)
    ), MaybeDangerPositions),
    % Get the number of cells
    length(MaybeDangerPositions, CellCount),
    % Filter the ones that are known not to have dangers (e.g. enemies) in them
    findall(NotADangerousPos, (
        member(NotADangerousPos, MaybeDangerPositions),
        certain(NotThere, NotADangerousPos)
    ), NotDangerousPositions),
    % If we know the danger (e.g. enemy) not to be in N-1 of them, then it has only one possible location
    CertainSize is CellCount - 1,
    length(NotDangerousPositions, CertainSize),
    % Get the position
    findall(Cell, (
        member(Cell, MaybeDangerPositions),
        \+ memberchk(Cell, NotDangerousPositions)
    ), [DangerPos|_]),
    % Learn that there is a danger (e.g. enemy) there
    learn(There, DangerPos),
    % Backtrack
    fail.
infer_dangerous_positions.

% infer_safe_positions/0
infer_safe_positions :-
    certain(no_pit, Pos),
    certain(no_teleporter, Pos),
    learn(safe, Pos),
    fail.
infer_safe_positions.


%
% Kill mode
% ---------

kill_mode_limit(20).
kill_mode_count(0).

reset_kill_mode_count :-
    retractall(kill_mode_count(_)),
    assertz(kill_mode_count(0)).


%
% Update goal
% -----------

% update_goal/1
% update_goal(-NewGoal)
update_goal(NewGoal) :-
    goal(Goal),
    update_goal(Goal, NewGoal),
    !.
update_goal(NewGoal) :-
    update_goal(none, NewGoal).

% update_goal/2
% update_goal(+CurrGoal, -NewGoal)
update_goal(reach(Pos), NewGoal) :-
    % If the goal is to reach an invalid position, remove goal and get a new one
    (\+ valid_position(Pos) ; blocked_position(Pos)),
    retractall(goal(_)),
    update_goal(none, NewGoal).
update_goal(kill, NewGoal) :-
    % If the goal is to kill an enemy, and the enemy has been killed, remove goal and get a new one
    killed_enemy,
    reset_kill_mode_count,
    retractall(goal(_)),
    update_goal(none, NewGoal).
update_goal(kill, NewGoal) :-
    % If the goal is to kill an enemy, and the time limit has been reached, remove goal and get a new one
    kill_mode_limit(L),
    kill_mode_count(C),
    C >= L,
    reset_kill_mode_count,
    retractall(goal(_)),
    update_goal(none, NewGoal).
update_goal(none, NewGoal) :-
    % If no goal, set a new one
    ask_goal_KB(NewGoal),
    set_goal(NewGoal),
    !.
update_goal(reach(Pos), NewGoal) :-
    % If goal is reach, and position is reached, get new goal
    agent_position(Pos),
    retractall(goal(_)),
    update_goal(none, NewGoal),
    !.
update_goal(reach(Pos), reach(Pos)) :-
    % If goal is reach, and haven't reached yet, don't change goal
    !.
update_goal(kill, kill) :-
    % If the goal is to kill an enemy and the time limit hasn't been reached, keep it
    kill_mode_count(C),
    CN is C + 1,
    retractall(kill_mode_count(_)),
    assertz(kill_mode_count(CN)),
    !.

% set_goal/1
% set_goal(+Goal)
set_goal(Goal) :-
    retractall(goal(_)),
    assertz(goal(Goal)).

ask_goal_KB(kill) :-
    heard_steps.

ask_goal_KB(reach(Pos)) :-
    next_position_to_explore(Pos),
    !.

% next_position_to_explore/1
% next_position_to_explore(-Pos)
% Gets the next position to try to reach when exploring the cave
next_position_to_explore(Pos) :-
    agent_position(AP),
    next_position_to_explore([AP], [], Pos).

% next_position_to_explore/3
% next_position_to_explore(+Queue, +Explored, -Pos)
% Expands neighbours in a BFS fashion until a safe unexplored position is found
next_position_to_explore([], _, _) :- !, fail.
next_position_to_explore([Pos | _], _, Pos) :-
    % If the next in the queue has not been visited, pick it to explore
    \+ certain(visited, Pos),
    !.
next_position_to_explore([Next | QueueTail], Explored, Pos) :-
    setof(
        Neighbour,
        Dir^(
            adjacent(Next, Neighbour, Dir),
            valid_position(Neighbour),
            \+ blocked_position(Neighbour),
            certain(safe, Neighbour),
            \+ member(Neighbour, Explored),
            \+ member(Neighbour, QueueTail)
        ),
        QueueAdd
    ),
    append(QueueTail, QueueAdd, Queue),
    !,
    next_position_to_explore(Queue, [Next | Explored], Pos).
next_position_to_explore([Failed | QueueTail], Explored, Pos) :-
    !,
    next_position_to_explore(QueueTail, [Failed | Explored], Pos).

unknown(Pos) :-
    valid_position(Pos),
    \+ blocked_position(Pos),
    \+certain(visited, Pos),
    \+certain(no_teleporter, Pos),
    \+certain(no_pit, Pos),
    \+certain(teleporter, Pos),
    \+certain(pit, Pos),
    \+possible_position(teleporter, Pos, _),
    \+possible_position(pit, Pos, _),
    !.

%
% Actions
% -------
% 1.1. Move forward (move_forward)
% TODO: 1.2. Move backward (move_backward)
% 2.1. Turn right 90 deg clockwise (turn_clockwise)
% 2.2. Turn left 90 deg anticlockwise (turn_anticlockwise)
% 3. Pick up object (gold)
% 4. Shoot on the current facing direction
%    (to any enemy in the adjacent celin the direction the agent is facing)
%    TODO: (ammo is unlimited and has range until coliding with blocked position)
% TODO: 5. Observe information on the world around
% 5. TODO: Remove? Climb out of the cave (only at the start)

% next_action/2
% next_action(+Goal, -Action)
% Gets the next Action to perform in order to reach Goal
next_action(_, pick_up) :-
    agent_position(AP),
    certain(gold, AP),
    !.
next_action(reach(Pos), move_forward) :-
    % If goal is to reach a position
    % and the agent is next to the position and facing the right direction
    agent_position(AP),
    facing(Dir),
    adjacent(AP, Pos, Dir),
    % move forward
    !.
next_action(reach(Pos), turn_clockwise) :-
    % If goal is to reach a position
    % and the agent is next to the position, but facing the wrong direction
    agent_position(AP),
    facing(FD),
    clockwise(FD, Dir),
    adjacent(AP, Pos, Dir),
    % turn clockwise
    !.
next_action(reach(Pos), turn_anticlockwise) :-
    % If goal is to reach a position
    % and the agent is next to the position, but facing the wrong direction
    agent_position(AP),
    adjacent(AP, Pos, _),
    % turn anticlockwise
    !.
next_action(reach(Pos), Action) :-
    % If goal is to reach a position and the agent is not next to the position
    % try to reach an adjacent position
    agent_position(AP),
    a_star(AP, Pos, a_star_heuristic, a_star_extend, [Next | _]),
    next_action(reach(Next), Action),
    !.

next_action(kill, turn_clockwise) :-
    % If goal is to kill, turn and shoot
    % TODO: improve strategy
    last_action(shoot).
next_action(kill, shoot).


% a_star_heuristic/3
% a_star_heuristic(+Origin, +Goal, -EstCost)
% Estimates the cost from Origin to Goal
a_star_heuristic((X0, Y0), (X1, Y1), H) :-
    H is abs(Y1 - Y0) + abs(X1 - X0).

a_star_extend(Goal, Origin, Next) :-
    adjacent(Origin, Next, _),
    valid_position(Next),
    \+ blocked_position(Next),
    (Next = Goal ; certain(safe, Next)).


% frontier_count/4
% frontier_count(+Origin, +Dir, +Rounds, -Count)
% Counts how many new cells can be explored from Origin in up to Rounds moves
frontier_count(Origin, Dir, Rounds, Count) :-
    frontier_extend(Origin, Dir, Rounds, ExtendedFrontier),
    length(ExtendedFrontier, Count),
    !.

% frontier_extend/4
% frontier_extend(+Pos, +Dir, +Steps, -Reacheable)
% Gets a list of unknown cells that can be visited in up to Steps moves from an agent
% located at Pos and facing Dir
frontier_extend(_, _, 0, []) :- !.
frontier_extend(Pos, Dir, Steps, Reacheable) :-
    frontier_extend_(Pos, Dir, Steps, R1),
    delete(R1, Pos, Reacheable),
    !.

% frontier_extend_(+Pos, +Dir, +Steps, -Reacheable)
frontier_extend_(Pos, _, 0, R) :-
    (   valid_position(Pos),
        \+ blocked_position(Pos)
    ->  R = [Pos]
    ;   R = []
    ), !.
frontier_extend_(Pos, Dir, Steps, Reacheable) :-
    adjacent(Pos, NextPos, Dir),
    clockwise(Dir, NextDir),
    NextSteps is Steps - 1,
    frontier_extend_(NextPos, Dir, NextSteps, R1),
    frontier_extend_(Pos, NextDir, NextSteps, R2),
    setof(
        P,
        (member(P, R1) ; member(P, R2)),
        Reacheable
    ),
    !.
frontier_extend_(_, _, _, []).

% For testing only
% Runs the algorithm until finding a gold position
run_until_done :-
    sense_learn_act(_, A),
    A \= shoot,
    A \= step_out,
    run_until_done,
    !.
run_until_done.
