defmodule ConnectFourWebWeb.PageController do
  use ConnectFourWebWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
