-module(bully_algo).

%% API
-export([run/2, run_process/3]).

run(N, Nodes) ->
  {Node, ID} = lists:nth(N, Nodes),
  io:format("Run process ~w with id: ~w~n", [Node, ID]),
  register(Node, spawn(bully_algo, run_process, [Node, ID, Nodes])).

run_process(Name, ID, Nodes) ->
  elections(Name, ID, Nodes).

usual_node(Name, ID, Nodes, Leader_PID) ->
  receive
    Message -> process_message(Message, Name, ID, Nodes, Leader_PID)
  after 8000 ->
    io:format("The king is dead, long live the king! New elections.~n", []),
    elections(Name, ID, Nodes)
  end.

coordinator(Name, ID, Nodes) ->
  receive
    {election, _, _} -> elections(Name, ID, Nodes)
  after 1000 ->
    [{Node, Node} ! {handshake, self(), ID} || {Node, _} <- Nodes, Node =/= node()],
    coordinator(Name, ID, Nodes)
  end.

process_message({election, Node_Name, Node_ID}, Name, ID, Nodes, _) ->
  if
    Node_ID < ID ->
      Node_Name ! {answer, self(), ID},
      elections(Name, ID, Nodes);
    true ->
      receive
        Message -> process_message(Message, Name, ID, Nodes, 1)
      after 5000 ->
        io:format("Stop waiting. New elections...~n", []),
        elections(Name, ID, Nodes)
      end
  end;
process_message({victory, Node_Name, Node_ID}, Name, ID, Nodes, _) ->
  if
    Node_ID < ID ->
      io:format("You are so weak to be coordiantor, ~w!~n", [node(Node_Name)]),
      elections(Name, ID, Nodes);
    true ->
      io:format("Let's work with new coordinator - ~w.~n",[node(Node_Name)]),
      usual_node(Name, ID, Nodes, Node_Name)
  end;
process_message({handshake, Node_Name, _}, Name, ID, Nodes, Current_Coordinator) ->
  if
    Node_Name =/= Current_Coordinator ->
      elections(Name, ID, Nodes);
    true ->
      io:format("Handshake from coordinator ~w~n", [node(Current_Coordinator)]),
      usual_node(Name, ID, Nodes, Current_Coordinator)
  end.

elections(Name, ID, Nodes) ->
  io:format("Let's start elections!~n"),
  [{Node, Node} ! {election, self(), ID} || {Node, Node_Id} <- Nodes, Node_Id > ID],
  receive
    {answer, _, _} ->
      receive
        Message -> process_message(Message, Name, ID, Nodes, 1)
      after 10000 ->
        io:format("seems all are dead~n", []),
        elections(Name, ID, Nodes)
      end;
    Message -> process_message(Message, Name, ID, Nodes, 1)
  after 3000 ->
    io:format("I'm coordiator now! MUA-HA-HA!~n"),
    [{Node, Node} ! {victory, self(), ID} || {Node, Node_Id} <- Nodes, Node_Id < ID],
    coordinator(Name, ID, Nodes)
  end.
