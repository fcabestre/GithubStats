defmodule GitStats.CLI do

  def main(args) do
    GitStats.get_user_stats(args)
  end

end
