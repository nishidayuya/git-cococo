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

Replace `writed` to `wrote` all of git tracked files and commit with re-runnable commit message.

```sh
$ git cococo sh -c 'git ls-files -z | xargs -0 sed -i -e s/writed/wrote/g'
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nishidayuya/git-cococo .

## Development

* [Ruby](https://www.ruby-lang.org/): To run `rake` command and tests.
* [Shellcheck](https://github.com/koalaman/shellcheck#installing): To run lint.

Clone this project.

Install related RubyGems and run tests and lint:

```sh
$ bundle
$ bundle exec rake
```

Write some changes with tests.

Run tests and lint:

```sh
$ bundle exec rake
```

Submit pull-request.

Thank you!
