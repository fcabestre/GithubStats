defmodule GitStats do
  @moduledoc """
  Simple exercise to discover the use of supervision trees, Elixir tasks,
  escripts and maybe distribution.
  """

  alias Monad.Result

  def get_user_stats(user) do
    "https://api.github.com/users/#{user}/repos"
    |> get_url
    |> Result.bind(&decode_body/1)
    |> Result.bind(&iterate_repos/1)
    |> display_stats(user)
  end

  defp iterate_repos(repos) do
    repos
    |> Enum.map(&supervised_task_async(:get_repo_stats, &1))
    |> Enum.map(&Task.await(&1, :infinity))
  end

  def get_repo_stats(repo) do
    repo_name = repo["name"]
    languages_url = repo["languages_url"]
    contributors_url = repo["contributors_url"]

    languages_task = supervised_task_async(:get_stats_from_url, languages_url)
    contributors_task = supervised_task_async(:get_stats_from_url, contributors_url)
    contributors = Task.await(contributors_task, :infinity)
    languages = Task.await(languages_task, :infinity)

    Result.bind(languages, fn l ->
      Result.bind(contributors, fn c ->
        %{
          name: repo_name,
          languages: Map.keys(l),
          contributors: Enum.map(c, &(&1["login"]))}
      end)
    end)
  end

  #==================================================================
  # Display functions
  #

  defp display_stats(stats, user) do
    IO.puts """
    User: #{user}
    """
    Enum.each(stats, & display_repo_stats(&1))
    %{languages: languages, contributors: contributors} =
      Enum.reduce(
        stats,
        %{languages: [], contributors: []},
        fn(s,acc) -> %{languages: acc.languages ++ s.languages, contributors: acc.contributors ++ s.contributors} end)
    IO.puts """
       Total language: #{count_single_items(languages)}
       Total contributors: #{count_single_items(contributors)}
    """
  end

  defp display_repo_stats(repo) do
    IO.puts """
        Repo: #{repo.name}
            Languages count: #{Enum.count(repo.languages)}
            Contributors count: #{Enum.count(repo.contributors)}
    """
  end

  #==================================================================
  # HTTPoison and Poison helpers
  #

  def get_stats_from_url(url) do
    url
    |> get_url
    |> Result.bind(&decode_body/1)
  end
  #    |> Result.bind(&Enum.count/
  defp get_url(url) do
    url
    |> HTTPoison.get(%{Authorization: "token ddfb459db415fcf91f97ca2828074f28d202074d"})
    |> Result.from_tuple
  end

  defp decode_body(%{body: body}) do
    body
    |> Poison.decode
    |> Result.from_tuple
  end

  defp decode_body(_) do
    Result.error("Wrong HTTP response format")
  end

  #==================================================================
  # Miscellaneous functions
  #

  defp supervised_task_async(f, a) do
    Task.Supervisor.async(GitsStats.TasksSupervisor, GitStats, f, [a])
  end

  defp count_single_items(list) do
    list
    |> Enum.sort
    |> Enum.dedup
    |> Enum.count
  end

end
