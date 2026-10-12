defmodule ConnectFourWebWeb.LobbyLive do
  use ConnectFourWebWeb, :live_view

  # ===========================================================================
  # Initialization
  # ===========================================================================
  @impl true
  def mount(_params, _session, socket) do
    # We initialize an empty form for the join input
    {:ok, assign(socket, form: to_form(%{"room_id" => ""}))}
  end

  # ===========================================================================
  # Event Handling
  # ===========================================================================

  @impl true
  def handle_event("create_room", _params, socket) do
    # Generate the random code
    room_id = for _ <- 1..4, into: "", do: <<Enum.random(?A..?Z)>>

    # 1. Create the room explicitly here!
    ConnectFourWeb.GameServer.create_room(room_id)

    # 2. Redirect the user's browser to the new game room
    {:noreply, push_navigate(socket, to: "/game/#{room_id}")}
  end

  @impl true
  def handle_event("join_room", %{"room_id" => room_id}, socket) do
    # Clean up the user input (remove spaces and uppercase it)
    clean_room_id =
      room_id
      |> String.trim()
      |> String.upcase()

    # Redirect them to the room they typed in
    {:noreply, push_navigate(socket, to: "/game/#{clean_room_id}")}
  end

  # ===========================================================================
  # HTML Rendering
  # ===========================================================================
  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 flex items-center justify-center p-4">
      <div class="flex flex-col gap-6 w-full max-w-sm">

        <div class="card bg-base-100 shadow-xl flex-1">
          <div class="card-body items-center text-center flex flex-col justify-between">
            <h2 class="card-title text-primary text-2xl mb-2">Create Match</h2>
            <p class="text-base-content/80">Start a fresh game and get a room code to share with a friend.</p>

            <div class="card-actions mt-6">
              <button phx-click="create_room" class="btn btn-primary w-full text-lg">
                Create New Room
              </button>
            </div>
          </div>
        </div>

        <div class="card bg-base-100 shadow-xl flex-1">
          <div class="card-body items-center text-center flex flex-col justify-between">

            <h2 class="card-title text-primary text-2xl mb-2">Join Room</h2>
            <p class="text-base-content/80">Already have a room code? Enter it below to join the match.</p>

            <form phx-submit="join_room" class="form-control flex flex-col w-full mt-6 gap-2">
              <input
                type="text"
                name="room_id"
                placeholder="Room Code"
                class="input input-bordered w-full uppercase"
                autocomplete="off"
              />
              <button type="submit" class="btn btn-primary w-full text-lg">
                Join Game
              </button>
            </form>
          </div>
        </div>

      </div>
    </div>
    """
  end
end
