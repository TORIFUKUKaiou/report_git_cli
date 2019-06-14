defmodule ReportGitCliTest do
  use ExUnit.Case
  doctest ReportGitCli

  test ":help returned by option parsing with -h and --help options" do
    assert ReportGitCli.CLI.parse_args(["-h", "anything"]) == :help
    assert ReportGitCli.CLI.parse_args(["--help", "anything"]) == :help
  end

  test "all args" do
    assert ReportGitCli.CLI.parse_args([
             "--dir",
             "dir",
             "--branch",
             "master",
             "--author",
             "me",
             "--since",
             "4 days ago",
             "--until",
             "2015/01/22"
           ]) ==
             [
               dir: "dir",
               branch: "master",
               author: "me",
               since: "4 days ago",
               until: "2015/01/22"
             ]
  end

  test "only dir" do
    assert ReportGitCli.CLI.parse_args(["--dir", "dir"]) == [dir: "dir"]
  end

  test "only branch" do
    assert ReportGitCli.CLI.parse_args(["--branch", "master"]) == :help
  end

  test "conver_to_list_of_maps" do
    map = %{
      "test" => [
        %ReportGitCli.Commit{num_of_added_lines: 10, num_of_deleted_lines: 20},
        %ReportGitCli.Commit{num_of_added_lines: 5, num_of_deleted_lines: 1},
        %ReportGitCli.Commit{num_of_added_lines: 1, num_of_deleted_lines: 2}
      ],
      "hoge" => [
        %ReportGitCli.Commit{num_of_added_lines: 1, num_of_deleted_lines: 2},
        %ReportGitCli.Commit{num_of_added_lines: 3, num_of_deleted_lines: 4}
      ],
      "fuga" => [
        %ReportGitCli.Commit{num_of_added_lines: 1, num_of_deleted_lines: 2},
        %ReportGitCli.Commit{num_of_added_lines: 3, num_of_deleted_lines: 4},
        %ReportGitCli.Commit{num_of_added_lines: 5, num_of_deleted_lines: 6}
      ]
    }

    expected = [
      %{email: "test", num_of_added_lines: 16, num_of_deleted_lines: 23},
      %{email: "hoge", num_of_added_lines: 4, num_of_deleted_lines: 6},
      %{email: "fuga", num_of_added_lines: 9, num_of_deleted_lines: 12}
    ]

    assert ReportGitCli.CLI.conver_to_list_of_maps(map) == expected
  end

  test "sort descending orders correct way" do
    a = %{email: "a", num_of_added_lines: 200, num_of_deleted_lines: 0}
    b = %{email: "b", num_of_added_lines: 150, num_of_deleted_lines: 300}
    c = %{email: "c", num_of_added_lines: 0, num_of_deleted_lines: 400}

    assert ReportGitCli.CLI.sort_into_descending_order([c, b, a]) ==
             [a, b, c]
  end

  test "sha_1_checksum" do
    commit_line = "commit 1c4d98a0b26ae315cbef906a0ed459cb09bcb74f (HEAD -> feature/view)"

    assert ReportGitCli.Git.sha_1_checksum(commit_line) ==
             "1c4d98a0b26ae315cbef906a0ed459cb09bcb74f"
  end

  test "author" do
    assert ReportGitCli.Git.author("Author: TORIFUKUKaiou <torifuku.kaiou@gmail.com>") ==
             %{"name" => "TORIFUKUKaiou", "email" => "torifuku.kaiou@gmail.com"}
  end

  test "date" do
    assert ReportGitCli.Git.date("Date:   Mon Jun 10 18:32:43 2019 +0900") ==
             "Mon Jun 10 18:32:43 2019 +0900"
  end

  test "numstat" do
    assert ReportGitCli.Git.numstat("25      0       app/controllers/top_controller.rb") ==
             %{"added" => "25", "deleted" => "0"}

    assert ReportGitCli.Git.numstat(
             "-       -       app/src/main/res/mipmap-hdpi/ic_launcher.png"
           ) ==
             %{"added" => "-", "deleted" => "-"}
  end

  test "numstats" do
    log = """
    commit c193e5c14d9f1cdb81296b501a3769eff48e8568
    Author: TORIFUKUKaiou <torifuku.kaiou@gmail.com>
    Date:   Wed Jun 12 17:16:58 2019 +0900

    add timex

    2       1       mix.exs
    14      0       mix.lock
    28      0       mix.exs
    -       -       app/src/main/res/mipmap-hdpi/ic_launcher.png
    -       -       app/src/main/res/mipmap-hdpi/ic_launcher_round.png
    -       -       app/src/main/res/mipmap-mdpi/ic_launcher.png
    -       -       app/src/main/res/mipmap-mdpi/ic_launcher_round.png
    8       2       test/report_git_cli_test.exs
    1       0       test/test_helper.exs
    """

    assert ReportGitCli.Git.numstats(log) == %{"added" => 53, "deleted" => 3}
  end

  test "logs_parse" do
    log1 = """
    commit 3488307d20fb990c3027895c39fc41d1c9f0ab5b
    Author: Hoge Hoge <hoge@hoge.com>
    Date:   Thu May 30 09:56:28 2019 +0900

    update default point amount (except owner)

    3       3       lib/tasks/dummy.rake
    """

    log2 = """
    commit 73d405e3ef9106d20981ff23bedb986a28e17c07
    Author: Fuga Fuga <fuga@fuga.com>
    Date:   Tue Apr 16 16:15:29 2019 +0900

    add transaction dependent

    2       2       app/models/user.rb
    -       -       app/src/main/res/mipmap-hdpi/ic_launcher.png
    2       2       spec/models/user_spec.rb
    """

    log3 = """
    commit 43eea67f7ba6ca691d8bc9c50e3d7731a5e60916
    Author: Test Test <test@test.com>
    Date:   Wed May 29 13:19:50 2019 +0900

    add a member(guest).

    10      8       lib/tasks/dummy.rake
    """

    log4 = """
    commit d05aaa26a9d9248e7108d98934e9bb243afb4591
    Author: Hoge Hoge <hoge@hoge.com>
    Date:   Wed May 29 14:12:38 2019 +0900

        set up default user type( Owner Admin User)

    1       0       app/models/user.rb
    6       0       spec/models/user/admin/owner_spec.rb
    -       -       app/src/main/res/mipmap-hdpi/ic_launcher.png
    7       1       spec/models/user/admin_spec.rb
    7       1       spec/models/user/member_spec.rb
    18      0       spec/models/user_spec.rb
    -       -       app/src/main/res/mipmap-hdpi/ic_launcher.png
    """

    log5 = """
    commit a1b0f3b03410a90b91d681452050273f75b47f56
    Author: Test Test <test@test.com>
    Date:   Fri May 24 16:07:23 2019 +0900

    History also update with sync.

    1       1       app/models/payment.rb
    """

    log6 = """
    commit 0bb36b1bf6b3a0475c353b7af1193471e2fb70d9
    Author: Hoge Hoge <hoge@hoge.com>
    Date:   Fri May 24 19:43:53 2019 +0900

    insert special guest & speaker guest data

    49      0       lib/tasks/dummy.rake
    """

    map = [log1, log2, log3, log4, log5, log6] |> ReportGitCli.Git.logs_parse()
    keys = map |> Map.keys() |> Enum.sort()
    assert keys == ["fuga@fuga.com", "hoge@hoge.com", "test@test.com"]
    assert length(Map.get(map, "fuga@fuga.com")) == 1
    assert length(Map.get(map, "hoge@hoge.com")) == 3
    assert length(Map.get(map, "test@test.com")) == 2
  end

  test "greets the world" do
    assert ReportGitCli.hello() == :world
  end
end
