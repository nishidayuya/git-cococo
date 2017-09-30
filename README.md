# `git cococo`: git COmmit COmpletely COmmand output

## Requirements

* Git

## Installation

`git cococo` is written by shell script. So we can install following:

```sh
$ wget https://raw.githubusercontent.com/nishidayuya/git-cococo/master/exe/git-cococo
$ chmod a+x git-cococo
$ mv git-cococo move-to-PATH-env-directory/
```

## Usage

Run `sed` command and commit its changes with commit message "run: git cococo sed -e s/foo/bar/g a.txt".

```sh
$ git cococo sed -e s/foo/bar/g a.txt
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nishidayuya/git-cococo .

## Development

Clone this project.

`git cococo` is tested by Ruby script. We must install Ruby.

Install related RubyGems and run tests:

```sh
$ bundle
$ bundle exec rake
```

Write some changes with tests.

Run tests:

```sh
$ bundle exec rake
```

Submit pull-request.

Thank you!
