defmodule ReportGitCli.TableFormatter do
  def print_table_for_columns(rows, headers) do
    with data_by_columns = split_into_columns(rows, headers),
         data_by_columns_with_header =
           Enum.map(headers, &printable/1)
           |> Enum.zip(data_by_columns)
           |> Enum.map(fn {header, list} -> [header] ++ list end),
         column_widths = widths_of(data_by_columns_with_header),
         format = format_for(column_widths) do
      puts_one_line_in_columns(headers, format)
      IO.puts(separator(column_widths))
      puts_in_columns(data_by_columns, format)
    end
  end

  def split_into_columns(rows, headers) do
    for header <- headers do
      for row <- rows, do: printable(row[header])
    end
  end

  def printable(str) when is_binary(str), do: str
  def printable(str), do: to_string(str)

  def widths_of(columns) do
    for column <- columns, do: column |> Enum.map(&String.length/1) |> Enum.max()
  end

  def format_for(column_widths) do
    format =
      column_widths
      |> Enum.with_index()
      |> Enum.map_join(" | ", fn {width, index} ->
        "~#{if index == 0, do: "-", else: ""}#{width}s"
      end)

    format <> "~n"
  end

  def separator(column_widths) do
    Enum.map_join(column_widths, "-+-", fn width -> List.duplicate("-", width) end)
  end

  def puts_in_columns(data_by_columns, format) do
    data_by_columns
    |> List.zip()
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.each(&puts_one_line_in_columns(&1, format))
  end

  def puts_one_line_in_columns(fields, format) do
    :io.format(format, fields)
  end
end
