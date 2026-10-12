defmodule ConnectFourWebWeb.GameLive do
  use ConnectFourWebWeb, :live_view

  alias ConnectFourWeb.GameServer

  # ===========================================================================
  # Initialization (Mount)
  # ===========================================================================


  @impl true
  def mount(%{"room_id" => room_id}, _session, socket) do
    if Registry.lookup(ConnectFourWeb.GameRegistry, room_id) == [] do
      # Room is missing! Just flag it, no messy redirects.
      socket = assign(socket, room_found: false, room_id: room_id)
      {:ok, socket}
    else
      # Room exists! Proceed normally.
      game_state = ConnectFourWeb.GameServer.get_state(room_id)

      if connected?(socket) do
        Phoenix.PubSub.subscribe(ConnectFourWeb.PubSub, "room:#{room_id}")

        case ConnectFourWeb.GameServer.join_game(room_id, self()) do
          {:ok, player_color} ->
            socket = assign(socket,
              room_found: true,
              room_id: room_id,
              game: game_state,
              color: player_color,
              error_message: nil,
              connected: true
            )
            {:ok, socket}

          {:error, :room_full} ->
            socket = assign(socket,
              room_found: true,
              room_id: room_id,
              game: game_state,
              color: :spectator,
              error_message: "Room is full! You are watching as a spectator.",
              connected: true
            )
            {:ok, socket}
        end
      else
        socket = assign(socket,
          room_found: true,
          room_id: room_id,
          game: game_state,
          color: nil,
          error_message: nil,
          connected: false
        )
        {:ok, socket}
      end
    end
  end

  # ===========================================================================
  # Event Handling (Browser Clicks)
  # ===========================================================================
  @impl true
  def handle_event("drop_piece", %{"col" => col_str}, socket) do
    col_index = String.to_integer(col_str)
    room_id = socket.assigns.room_id
    player_color = socket.assigns.color

    case GameServer.make_move(room_id, player_color, col_index) do
      {:ok, new_state} ->
        # Move successful! Clear any previous errors and update the board.
        Phoenix.PubSub.broadcast(
          ConnectFourWeb.PubSub,
          "room:#{room_id}",
          {:board_updated, new_state}
        )

        # Return socket with current state, new state will be updated in :board_updated event
        {:noreply, assign(socket, error_message: nil)}


      {:error, reason} ->
        # Move failed (wrong turn, game over, etc.). Show an error.
        {:noreply, assign(socket, :error_message, "Invalid move: #{reason}")}
    end
  end

  # ===========================================================================
  # Inter-Process Communication (PubSub)
  # ===========================================================================
  @impl true
  def handle_info({:board_updated, new_state}, socket) do

    just_ended = new_state.status != :in_progress and socket.assigns.game.status == :in_progress

    # Make the game state such that moves cannot be made, send the actual winning/draw status state after a delay
    if just_ended do
      temp_game = %{new_state | status: :in_progress, current_player: :none}

      Process.send_after(self(), {:reveal_winner, new_state}, 3000)

      {:noreply, assign(socket, game: temp_game, error_message: nil)}
    else
      {:noreply, assign(socket, game: new_state, error_message: nil)}
    end
  end

  def handle_info({:reveal_winner, new_state}, socket) do
    {:noreply, assign(socket, game: new_state, error_message: nil)}
  end

  @impl true
  def handle_info({:room_closed, message}, socket) do

    {:noreply, assign(socket, error_message: message, color: :spectator)}
  end

  # ===========================================================================
  # HTML Rendering (HEEx)
  # ===========================================================================
  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto mt-10 text-center ">
      <%= if @room_found do %>
        <!-- ================= THE GAME BOARD ================= -->
        <h1 class="text-4xl font-bold mb-4">Room: <%= @room_id %></h1>

        <%= if @connected do %>
          <p class="text-xl mb-2">
            You are playing as: <span class="font-bold uppercase"><%= @color %></span>
          </p>

          <p class="text-lg font-semibold mb-6">
            <%= case @game.status do %>
              <% :in_progress -> %> Current Turn: <%= @game.current_player %>
              <% {:won, winner, _} -> %> 🏆 <%= winner %> Wins! 🏆
              <% :draw -> %> It's a draw!
            <% end %>
          </p>

          <div class="h-16 mb-4 w-full max-w-md mx-auto">
          <%= if @error_message do %>
            <div class="bg-red-200 text-red-800 p-3 rounded-lg shadow">
              <%= @error_message %>
            </div>
          <% end %>
          </div>

          <!-- FLUID BOARD WRAPPER -->
          <div class="w-full max-w-3xl mx-auto px-2">
            <div id="game-board" class="grid grid-cols-7 gap-1 sm:gap-2 bg-blue-600 p-2 sm:p-4 rounded-xl shadow-2xl">
              <%= for {column, col_index} <- Enum.with_index(@game.board) do %>

              <!-- 1. Add an ID to the column -->
              <div
                id={"column-#{col_index}"}
                class={[
                  "flex flex-col-reverse justify-start gap-1 sm:gap-2 w-full bg-blue-700 rounded py-1 sm:py-2 transition",
                  @color in [:red, :yellow] && "cursor-pointer hover:bg-blue-500"
                ]}
                phx-click={if @color in [:red, :yellow], do: "drop_piece", else: nil}
                phx-value-col={col_index}
              >

                <!-- 2. Pattern match {piece_color, row_index} directly in the loop -->
                <%= for {piece_color, row_index} <- Enum.with_index(column) do %>
                  <div
                    id={"piece-#{col_index}-#{row_index}"}
                    style={"--row: #{row_index};"}
                    class={[
                      "w-full aspect-square mx-auto rounded-full shrink-0 shadow-md",
                      if(piece_color == :red, do: "bg-red-500", else: "bg-yellow-400"),
                      if(row_index == length(column) - 1, do: "animate_drop_in", else: ""),
                      case @game.status do
                        {:won, _, winning_coords} -> if({col_index, row_index} in winning_coords, do: "winning-piece", else: "")
                        _ -> ""
                      end
                      ]}
                  ></div>
                <% end %>

                <!-- 3. Add an ID to the empty slots and calculate their row index -->
                <%= for row_index <- length(column)..5//1 do %>
                  <%= if row_index < 6 do %>
                    <div id={"empty-#{col_index}-#{row_index}"} class="w-full aspect-square mx-auto rounded-full bg-blue-800/80 shadow-inner shrink-0"></div>
                  <% end %>
                <% end %>

              </div>
            <% end %>
            </div>
          </div>

        <% else %>
          <div class="mt-20 text-2xl font-semibold text-gray-500 animate-pulse">
            Joining room...
          </div>
        <% end %>

      <% else %>
        <!-- ================= ROOM NOT FOUND ERROR ================= -->


          <div class="card w-full max-w-md bg-base-100 shadow-xl mx-auto mt-20">
            <div class="card-body items-center text-center">

              <h2 class="card-title text-error text-3xl mb-2">Room Not Found</h2>

              <p class="text-base-content/80 mb-6">
                The room <span class="font-bold text-base-content"><%= @room_id %></span> does not exist, or the game has already ended.
              </p>

              <div class="card-actions w-full mt-2">
                <.link navigate="/" class="btn btn-primary w-full text-lg">
                  Back to Lobby
                </.link>
              </div>

            </div>
          </div>


      <% end %>
    </div>
    """
  end
end
