defmodule ConnectFourWeb.GameServer do
  use GenServer, restart: :transient

  alias ConnectFourWeb.GameLogic

  # Initialization
  def start_link(room_code) do
    GenServer.start_link(__MODULE__, room_code, name: {:via, Registry, {ConnectFourWeb.GameRegistry, room_code}})
  end

  @impl true
  def init(room_code) do
    initial_state = %{
      room_code: room_code,
      game: GameLogic.new_game(),
      players: %{red: nil, yellow: nil}
    }
    {:ok, initial_state}
  end


  # API
  defp via_tuple(room_code) do
    {:via, Registry, {ConnectFourWeb.GameRegistry, room_code}}
  end

  @doc "Tells the DynamicSupervisor to spawn a new game server"
  def create_room(room_code) do
    DynamicSupervisor.start_child(
      ConnectFourWeb.GameSupervisor,
      {__MODULE__, room_code}
    )
  end

  @doc "Retrieves the current game state from the server."
  def get_state(room_code) do
    GenServer.call(via_tuple(room_code), :get_state)
  end

  @doc "Attempts to drop a token into the specified column."
  def make_move(room_code, player, column) do
    GenServer.call(via_tuple(room_code), {:make_move, player, column})
  end

  @doc "Attempts to join the game. Returns a color or an error."
  def join_game(room_code, live_view_pid) do
    GenServer.call(via_tuple(room_code), {:join, live_view_pid})
  end

  @impl true
  def handle_call({:join, pid}, _from, state) do
    cond do
      is_nil(state.players.red) ->
        # Seat is open! Monitor the browser process and assign Red.
        Process.monitor(pid)
        new_state = put_in(state.players.red, pid)
        {:reply, {:ok, :red}, new_state}

      is_nil(state.players.yellow) ->
        # Seat is open! Monitor the browser process and assign Yellow.
        Process.monitor(pid)
        new_state = put_in(state.players.yellow, pid)
        {:reply, {:ok, :yellow}, new_state}

      true ->
        # Both seats are taken!
        {:reply, {:error, :room_full}, state}
    end
  end

  # Callbacks
  @impl true
  def handle_call(:get_state, _from, state) do
    # Reply with the state, and keep the state unchanged
    {:reply, state.game, state}
  end

  @impl true
  def handle_call({:make_move, player, column}, _from, state) do
    # Pass the current state to your pure logic module
    case GameLogic.make_move(state.game, player, column) do
      {:error, reason} ->
        # If the move is invalid (e.g., column full), reply with the error
        # and keep the old state so the GenServer doesn't crash.
        {:reply, {:error, reason}, state}

      new_game ->
        # If the move succeeds, reply with {:ok, new_state} to the caller,
        # and save the new_state as the new GenServer state.
        {:reply, {:ok, new_game}, %{state | game: new_game}}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do

    Phoenix.PubSub.broadcast(
      ConnectFourWeb.PubSub,
      "room:#{state.room_code}",
      {:room_closed, "A player disconnected. The room has been closed."}
    )

    {:stop, :normal, state}
  end
end
