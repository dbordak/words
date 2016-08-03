defmodule Words.PageController do
  use Words.Web, :controller

  def index(conn, _params) do
    render conn, "index.html", id: Words.generate_player_id
  end
end
