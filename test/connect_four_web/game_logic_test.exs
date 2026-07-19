defmodule ConnectFour.GameLogicTest do
  use ExUnit.Case, async: true

  alias ConnectFour.GameLogic

  describe "new_game/0" do
    test "initializes a board with 7 empty columns" do
      game = GameLogic.new_game()

      assert game.status == :in_progress
      assert length(game.board) == 7

      # Ensure every column is completely empty
      assert Enum.all?(game.board, fn col -> col == [] end)

      # Ensure a valid player was chosen
      assert game.current_player in [:red, :yellow]
    end
  end

  describe "make_move/3" do
    test "successfully drops a token and switches the player" do
      game = GameLogic.new_game()
      original_player = game.current_player

      # Make a move in column 0, passing the original_player
      new_game = GameLogic.make_move(game, original_player, 0)

      # Assert the piece was placed
      column_zero = Enum.at(new_game.board, 0)
      assert column_zero == [original_player]

      # Assert the player swapped
      assert new_game.current_player != original_player
    end

    test "returns an error if the column is full" do
      game = GameLogic.new_game()

      # Manually inject a full column to bypass needing to call make_move 6 times
      full_column = [:red, :yellow, :red, :yellow, :red, :yellow]
      board_with_full_column = List.replace_at(game.board, 0, full_column)
      game = %{game | board: board_with_full_column}

      # Try to drop a piece into the full column
      assert {:error, :column_full} = GameLogic.make_move(game, game.current_player, 0)
    end

    test "returns an error if a player attempts to move out of turn" do
      game = GameLogic.new_game()
      game = %{game | current_player: :red}

      # Yellow attempts to move on Red's turn
      assert {:error, :wrong_turn} = GameLogic.make_move(game, :yellow, 0)
    end

    test "returns an error if a player attempts to move after the game is over" do
      game = GameLogic.new_game()
      game = %{game | status: {:won, :red, []}, current_player: :yellow}

      # Yellow attempts to move after Red has won
      assert {:error, :game_over} = GameLogic.make_move(game, :yellow, 0)
    end
  end

  describe "win conditions" do
    test "detects a horizontal win on the bottom row" do
      game = GameLogic.new_game()
      game = %{game | current_player: :red}

      # Setup a board where Red has pieces in columns 0, 1, and 2
      near_win_board = [
        [:red], [:red], [:red], [], [], [], []
      ]
      game = %{game | board: near_win_board}

      # Drop the winning piece in column 3
      won_game = GameLogic.make_move(game, :red, 3)

      # Use pattern matching to assert it returns a win for red
      # match? returns true if the right side matches the pattern on the left
      assert match?({:won, :red, _positions}, won_game.status)
    end

    test "detects a diagonal win going up and to the right (/)" do
      game = GameLogic.new_game()
      game = %{game | current_player: :red}

      # We need to build a "staircase" so the red pieces line up diagonally
      up_right_board = [
        [:red],
        [:yellow, :red],
        [:yellow, :yellow, :red],
        [:yellow, :red, :yellow], # We will drop the winning :red on top of this column
        [], [], []
      ]
      game = %{game | board: up_right_board}

      won_game = GameLogic.make_move(game, :red, 3)
      assert match?({:won, :red, _positions}, won_game.status)
    end

    test "detects a diagonal win going down and to the right (\\)" do
      game = GameLogic.new_game()
      game = %{game | current_player: :red}

      # We build a reverse staircase.
      # The highest piece is on the left, and we drop the lowest piece on the right.
      down_right_board = [
        [:yellow, :yellow, :yellow, :red],
        [:yellow, :yellow, :red],
        [:yellow, :red],
        [], # We drop the final :red here, which will land at the very bottom
        [], [], []
      ]
      game = %{game | board: down_right_board}

      won_game = GameLogic.make_move(game, :red, 3)
      assert match?({:won, :red, _positions}, won_game.status)
    end
  end

  describe "false positive win conditions" do
    test "does not detect a win when a streak is blocked by an opponent" do
      game = GameLogic.new_game()

      # It is Yellow's turn
      game = %{game | current_player: :yellow}

      # Red has 3 in a row horizontally.
      false_win_board = [
        [:red], [:red], [:red], [], [], [], []
      ]
      game = %{game | board: false_win_board}

      # Yellow drops a piece in column 3 to block Red's horizontal line
      blocked_game = GameLogic.make_move(game, :yellow, 3)

      # Assert the status remains in progress
      assert blocked_game.status == :in_progress

      # Verify the board looks like we expect: Red, Red, Red, Yellow
      assert Enum.at(blocked_game.board, 3) == [:yellow]
    end

    test "does not detect a win for non-consecutive pieces" do
      game = GameLogic.new_game()
      game = %{game | current_player: :red}

      # Red drops a piece, but there is a Yellow piece interrupting the vertical line
      interrupted_column_board = [
        [:red, :red, :yellow], [], [], [], [], [], []
      ]
      game = %{game | board: interrupted_column_board}

      moved_game = GameLogic.make_move(game, :red, 0)

      # Streak is: Red, Red, Yellow, Red. This is not 4 in a row.
      assert moved_game.status == :in_progress
    end
  end

  describe "draw conditions" do
    test "transitions to :draw when the board is completely filled with no winner" do
      game = GameLogic.new_game()
      # It is Yellow's turn to drop the final piece
      game = %{game | current_player: :yellow}

      # We define two column patterns that safely interlock without causing any 4-in-a-rows
      col_a = [:red, :red, :yellow, :yellow, :red, :yellow]
      col_b = [:yellow, :yellow, :red, :red, :yellow, :red]

      # col_a_missing has only 5 pieces. We need to drop a :yellow on top to finish it.
      col_a_missing = [:red, :red, :yellow, :yellow, :red]

      # Assemble the near-full board
      draw_board = [
        col_a, col_b, col_a, col_b, col_a, col_b, col_a_missing
      ]
      game = %{game | board: draw_board}

      # Yellow drops the final piece in the last column (index 6)
      finished_game = GameLogic.make_move(game, :yellow, 6)

      assert finished_game.status == :draw
    end
  end
end
