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
    <div class="max-w-md mx-auto mt-20 text-center">
      <h1 class="text-6xl font-extrabold mb-10 text-blue-700 tracking-tight">
        Connect Four
      </h1>

      <!-- Create Room Section -->
      <div class="bg-white p-8 rounded-xl shadow-lg border border-gray-100 mb-8">
        <h2 class="text-2xl font-bold text-gray-800 mb-4">Start a New Match</h2>
        <p class="text-gray-500 mb-6">Generate a random room code and invite a friend.</p>

        <button
          phx-click="create_room"
          class="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded-lg transition shadow-md hover:shadow-lg"
        >
          Create Room
        </button>
      </div>

      <!-- Join Room Section -->
      <div class="bg-white p-8 rounded-xl shadow-lg border border-gray-100">
        <h2 class="text-2xl font-bold text-gray-800 mb-4">Join Existing Match</h2>
        <p class="text-gray-500 mb-6">Have a code from a friend? Enter it below.</p>

        <.form for={@form} phx-submit="join_room" class="flex gap-2">
          <input
            type="text"
            name="room_id"
            placeholder="e.g. ABCD"
            class="flex-1 rounded-lg border-gray-300 px-4 py-3 uppercase focus:ring-2 focus:ring-blue-500 focus:border-blue-500 font-bold tracking-widest text-center"
            required
            autocomplete="off"
            maxlength="10"
          />
          <button
            type="submit"
            class="bg-green-600 hover:bg-green-700 text-white font-bold py-3 px-6 rounded-lg transition shadow-md hover:shadow-lg"
          >
            Join
          </button>
        </.form>
      </div>
    </div>
    """
  end
end
