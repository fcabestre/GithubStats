defmodule GitStats.App do

  use Application

  def start(_type, _args) do
    GitStats.Supervisor.start_link(:ok)
  end

end
