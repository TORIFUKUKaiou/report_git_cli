defmodule ReportGitCli.Git do
  @reg_author ~r/^Author: (?<name>.+?) <(?<email>|.+?)>$/
  @reg_date ~r/^Date:\s+(?<date>.+)$/
  @reg_numstat ~r/(?<added>\d+|-)\s+(?<deleted>\d+|-).+/

  def fetch(opts) do
    dir = opts[:dir]

    git_fetch_origin(dir)

    0..(num_of_git_logs(dir, Keyword.get(opts, :branch, "master")) - 1)
    |> Flow.from_enumerable()
    |> Flow.map(fn i -> log(i, opts) end)
    |> Flow.partition()
    |> logs_parse
  end

  defp run_git_command(option_list, dir) do
    {result, 0} = System.cmd("git", option_list, cd: dir)
    result
  end

  defp git_fetch_origin(dir), do: run_git_command(["fetch", "origin"], dir)

  defp git_log_oneline(dir, branch),
    do:
      run_git_command(["log", "origin/#{branch}", "--oneline", "--no-merges", "--pretty=%h"], dir)

  defp num_of_git_logs(dir, branch), do: git_log_oneline(dir, branch) |> String.split() |> length

  def log(i, opts) do
    dir = opts[:dir]
    branch = Keyword.get(opts, :branch, "master")

    run_git_command(
      ["log", "origin/#{branch}", "--numstat", "--no-merges", "--skip=#{i}", "-n 1"] ++
        options(opts),
      dir
    )
  end

  def options(opts) do
    author = Keyword.get(opts, :author)
    since = Keyword.get(opts, :since)
    until = Keyword.get(opts, :until)

    _options(author: author) ++
      _options(since: since) ++
      _options(until: until)
  end

  def logs_parse(logs) do
    logs
    |> Flow.reduce(fn -> %{} end, fn lines, acc ->
      sha_1_checksum = lines |> String.split("\n") |> Enum.at(0) |> sha_1_checksum()
      %{"email" => email} = lines |> String.split("\n") |> Enum.at(1) |> author()
      date = lines |> String.split("\n") |> Enum.at(2) |> date()

      %{"added" => num_of_added_lines, "deleted" => num_of_deleted_lines} = numstats(lines)

      commit = %ReportGitCli.Commit{
        sha_1_checksum: sha_1_checksum,
        date: date,
        num_of_added_lines: num_of_added_lines,
        num_of_deleted_lines: num_of_deleted_lines
      }

      Map.update(acc, email, [commit], &(&1 ++ [commit]))
    end)
    |> Enum.reduce(%{}, fn {email, commits}, acc ->
      Map.update(acc, email, commits, &(&1 ++ commits))
    end)
  end

  # commit 1c4d98a0b26ae315cbef906a0ed459cb09bcb74f (HEAD -> feature/view)
  def sha_1_checksum(line), do: String.split(line, " ") |> Enum.at(1)

  # Author: TORIFUKUKaiou <torifuku.kaiou@gmail.com>
  def author(line), do: Regex.named_captures(@reg_author, line)

  # Date:   Mon Jun 10 18:32:43 2019 +0900
  def date(line) do
    %{"date" => date} = Regex.named_captures(@reg_date, line)
    date
  end

  # 25      0       app/controllers/top_controller.rb
  # 1       0       app/views/layouts/application.html.slim
  # 23      0       app/views/top/index.html.slim
  # 1       0       config/routes.rb
  def numstats(lines) do
    lines
    |> String.split("\n")
    |> Enum.reject(fn line -> String.length(line) == 0 end)
    |> Enum.reverse()
    |> Enum.take_while(fn line -> Regex.match?(@reg_numstat, line) end)
    |> Enum.reduce(%{"added" => 0, "deleted" => 0}, &_numstat/2)
  end

  # 25      0       app/controllers/top_controller.rb
  def numstat(line), do: Regex.named_captures(@reg_numstat, line)

  defp _numstat(line, acc) do
    %{"added" => a, "deleted" => d} = numstat(line)

    acc
    |> Map.put("added", acc["added"] + _extract_of(Integer.parse(a)))
    |> Map.put("deleted", acc["deleted"] + _extract_of(Integer.parse(d)))
  end

  defp _extract_of({n, ""}), do: n
  defp _extract_of(_), do: 0

  defp _options(author: nil) do
    []
  end

  defp _options(author: author) do
    ["--author=#{author}"]
  end

  defp _options(since: nil) do
    []
  end

  defp _options(since: since) do
    ["--since=#{since}"]
  end

  defp _options(until: nil) do
    []
  end

  defp _options(until: until) do
    ["--until=#{until}"]
  end

  defp _options(_) do
    []
  end
end
