# ReportGitCli

## What is this?
- This summarizes `$ git log --numstat`.

## Requirement
- [Elixir](https://elixir-lang.org/)
- [Git](https://git-scm.com/)

## Build

`$ mix escript.build`

## Usage
- `report_git_cli --dir <dir> [ --branch <branch> --author <author> --since <since> --until <until> ]`

## Sample

```
$ ./report_git_cli --dir "/your/path"
email               | num_of_added_lines | num_of_deleted_lines
--------------------+--------------------+---------------------
elixir@lovelove.com |               2517 |                  677
fuga@sample.co.uk   |               2068 |                  717
testtest@sample.com |                391 |                   89
hoge@sample.co.jp   |                153 |                   57
```

```
$ ./report_git_cli --dir "/your/path" --branch develop
```


```
./report_git_cli --dir "/your/path" --branch develop --since 2019/06/06 --until 2019/06/14
```

```
./report_git_cli --dir "/your/path" --branch develop --author "TORIFUKU Kaiou" --since 2019/06/06 --until 2019/06/14
```

## git command
- refer to `lib/report_git_cli/git.ex`

```
$ git fetch origin
$ git log origin/master --oneline --no-merges --pretty=%h
$ git log origin/master --numstat --no-merges --author "TORIFUKU Kaiou" --since 2019/06/06 --until 2019/06/14
```
