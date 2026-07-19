A simple real-time multiplayer Connect Four game made in Elixir using Phoenix LiveView framework.
The project was made primarily as a basic study of the Elixir language and Phoenix framework, so it's not fully polished, but should be functional.

Some parts of the project (including a majority of the CSS and HEEx code) were generated with the help of Google's Gemini.

# Features
The game allows for multiple concurrent game rooms by using Elixir's DynamicSupervisor and Registry. To initiate a game, one player must press the "Create Room" button on the main screen, and another must then input the generated room code and press "Join Room". The first two users to join the room will be assigned colors (red or yellow), any further users who attempt to join will be assigned as spectators.
When one of the players (non-spectators) exits the game (by for example closing the browser window), the room will close.

# Prerequisites
To run this project, you will need:
- Elixir (1.14 or later)
- Erlang/OTP (25 or later)

## Running the Game Locally
Clone the repository and navigate into the project directory.

Install the Elixir dependencies:
`mix deps.get`

Start the Phoenix server:
`mix phx.server`

Open your browser and navigate to http://localhost:4000.

To enable access to other devices in the local network, you must open config/dev.exs and change the http: IP binding from {127, 0, 0, 1} to {0, 0, 0, 0}.
Afterwards the website can be accessed by using the computer's IP address.

# Tech Stack
- Language: Elixir
- Web Framework: Phoenix & Phoenix LiveView
- State Management: GenServer & DynamicSupervisor
- Real-time Communication: Phoenix PubSub
- Styling: Tailwind CSS