defmodule ReportGitCliTest do
  use ExUnit.Case
  doctest ReportGitCli

  test "greets the world" do
    assert ReportGitCli.hello() == :world
  end
end
