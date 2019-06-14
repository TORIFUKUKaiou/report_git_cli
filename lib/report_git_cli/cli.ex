defmodule ReportGitCli.CLI do
  def main(argv) do
    argv
    |> parse_args
    |> process
    |> conver_to_list_of_maps
    |> sort_into_descending_order
    |> ReportGitCli.TableFormatter.print_table_for_columns([
      :email,
      :num_of_added_lines,
      :num_of_deleted_lines
    ])
  end

  def parse_args(argv) do
    parse =
      OptionParser.parse(argv,
        strict: [
          help: :boolean,
          dir: :string,
          branch: :string,
          author: :string,
          since: :string,
          until: :string
        ]
      )

    case parse do
      {[help: true], _, _} -> :help
      {opts, _, _} -> parse_opts(opts)
      _ -> :help
    end
  end

  def process(:help) do
    IO.puts("""
    usage: report_git_cli --dir <dir> [ --branch <branch> --author <author> --since <since> --until <until> ]
    """)

    System.halt(0)
  end

  def process(opts) do
    ReportGitCli.Git.fetch(opts)
  end

  def conver_to_list_of_maps(map) do
    map
    |> Enum.reduce([], fn {email, commits}, acc ->
      [
        %{
          email: email,
          num_of_added_lines: sum_of_added_lines(commits),
          num_of_deleted_lines: sum_of_deleted_lines(commits)
        }
      ] ++ acc
    end)
  end

  def sort_into_descending_order(list_of_numstat) do
    Enum.sort(
      list_of_numstat,
      fn i1, i2 -> i1[:num_of_added_lines] >= i2[:num_of_added_lines] end
    )
  end

  defp parse_opts(opts) do
    if Keyword.has_key?(opts, :dir), do: opts, else: :help
  end

  defp sum_of_added_lines(commits), do: commits |> Enum.map(& &1.num_of_added_lines) |> Enum.sum()

  defp sum_of_deleted_lines(commits),
    do: commits |> Enum.map(& &1.num_of_deleted_lines) |> Enum.sum()
end
