defmodule ConnectFourWeb.GameLogic do

  @type color :: :red | :yellow
  @type board :: list(list(color))

  @columns 7
  @rows 6

  # State holds the board, the current player, and status
  # "won" status tuple holds the color of the winning player as well as a list of positions which mark the found winning four tokens
  @type t :: %__MODULE__{
          board: board,
          current_player: color,
          status: :in_progress | {:won, color, [{integer(), integer()}]} | :draw
        }

  defstruct board: for(_ <- 1..@columns, do: []),
            current_player: :red,
            status: :in_progress

  def new_game do
    %__MODULE__{current_player: Enum.random([:red, :yellow])}
  end

  @spec drop_token(board(), color(), integer()) :: {:ok, board()} | {:error, atom()}
  def drop_token(board, color, column_index) do
    case Enum.at(board, column_index) do
      # Make sure the column exists (not out of range)
      nil ->
        {:error, :invalid_column}
      # Make sure the column is not full
      column when length(column) < @rows ->
        # Add a token to the column
        {:ok, List.update_at(board, column_index, &(&1 ++ [color]))}
      _ ->
        {:error, :column_full}
    end
  end

  @spec token_at(board(), integer(), integer()) :: color() | nil
  def token_at(board, col_index, row_index) do
    case Enum.at(board, col_index) do
      nil -> nil
      column -> Enum.at(column, row_index)
    end
  end

  # Checks whether there is a 4 in a row of a given color based on a list of positions
  @spec find_win_in_list(board(), color(), [{integer(), integer()}]) :: [{integer(), integer()}] | nil
  defp find_win_in_list(board, color, position_list) do

    result = Enum.reduce_while(position_list, [], fn {col, row} = current_pos, streak ->
      if token_at(board, col, row) == color do
        # Prepend the new position to the current streak
        new_streak = [current_pos | streak]

        if length(new_streak) == 4 do
          {:halt, {:win, new_streak}}
        else
          {:cont, new_streak}
        end
      else
        # Color doesn't match, so reset the streak to an empty list
        {:cont, []}
      end
    end)

    case result do
      {:win, positions} -> positions
      _ -> nil
    end
  end

  @doc "Check win condition based on last dropped token"
  @spec check_win(board(), color(), integer()) :: [{integer(), integer()}] | nil
  def check_win(board, color, column) do
    row = length(Enum.at(board, column)) - 1

    # Check for the current row, column, and diagonals
    pos_lists = [
      # Horizontal
      for(x <- 0..(@columns-1), do: {x, row}),
      # Vertical
      for(y <- 0..(@rows-1), do: {column, y}),
      # Diagonal /
      for(i <- -3..3,
          x = column + i,
          y = row + i,
          x >= 0 and x < @columns and y >= 0 and y < @rows,
          do: {x, y}),
      # Diagonal \
      for(i <- -3..3,
          x = column + i,
          y = row - i,
          x >= 0 and x < @columns and y >= 0 and y < @rows,
          do: {x, y})
    ]

    Enum.find_value(pos_lists, &find_win_in_list(board, color, &1))
  end

  @doc "Checks if the game is a draw - that is, if every column is filled"
  @spec check_draw(board()) :: boolean()
  def check_draw(board) do
    Enum.all?(board, &(length(&1) == @rows))
  end

  @doc "Attempt to make a move, check win condition and pass to the next player. The player making the move must the current player in the game state."
  @spec make_move(t(), color(), integer()) :: t() | {:error, atom()}
  def make_move(%__MODULE__{board: board, current_player: current_player, status: :in_progress} = state, current_player, column) do
    case drop_token(board, current_player, column) do
      {:ok, new_board} ->
        win_check = check_win(new_board, current_player, column)

        new_status = cond do
          win_check -> {:won, current_player, win_check}
          check_draw(new_board) -> :draw
          true -> :in_progress
        end

        next_player = case current_player do
          :red -> :yellow
          :yellow -> :red
        end

        %{state | board: new_board, current_player: next_player, status: new_status}
      {:error, err} -> {:error, err}
    end
  end

  # If player attempts to make a move while it is not their turn, return error
  def make_move(%__MODULE__{status: :in_progress}, _attempting_player, _column) do
    {:error, :wrong_turn}
  end

  # If the status is not in_progress, return error
  def make_move(_state, _attempting_player, _column) do
      {:error, :game_over}
  end
end
