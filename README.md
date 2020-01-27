# `git cococo`: git COmmit COmpletely COmmand output

[![License X11](https://img.shields.io/badge/license-X11-blue.svg)](https://raw.githubusercontent.com/nishidayuya/git-cococo/master/LICENSE.txt)
[![Latest tag](https://img.shields.io/github/v/tag/nishidayuya/git-cococo)](https://github.com/nishidayuya/git-cococo/tags)
[![Build Status](https://github.com/nishidayuya/git-cococo/workflows/ubuntu/badge.svg)](https://github.com/nishidayuya/git-cococo/actions?query=workflow%3Aubuntu)
[![Build Status](https://github.com/nishidayuya/git-cococo/workflows/windows/badge.svg)](https://github.com/nishidayuya/git-cococo/actions?query=workflow%3Awindows)
[![Build Status](https://github.com/nishidayuya/git-cococo/workflows/macos/badge.svg)](https://github.com/nishidayuya/git-cococo/actions?query=workflow%3Amacos)

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

Run `sed` command and commit its changes with commit message "run: git cococo sed -i -e s/foo/bar/g a.txt".

```sh
$ git cococo sed -i -e s/foo/bar/g a.txt
```

Oops! I forgot un-commmitted changes. `git cococo` tells me it and don't run command.

```sh
$ git cococo sed -i -e s/foo/bar/g a.txt
Detects following uncommitted changes:

     M b.txt
    ?? c.txt

Run "git stash" and retry "git cococo":

    $ git stash --include-untracked &&
      git cococo sed -i -e s/foo/bar/g a.txt &&
      git stash pop

Or, use "--autostash" option:

    $ git cococo --autostash sed -i -e s/foo/bar/g a.txt
```

Replace `writed` to `wrote` all of git tracked files and commit with re-runnable commit message.

```sh
$ git cococo sh -c 'git ls-files -z | xargs -0 sed -i -e s/writed/wrote/g'
```

## Examples

### for Rubyists

```sh
$ git cococo --init bundle init
$ git cococo rbenv local 2.7.0
$ git cococo bundle add rake
$ git cococo bundle update nokogiri

$ n=new_awesome_gem && git cococo --init=$n bundle gem $n

$ n=blog && git cococo --init=$n rails new $n
$ cd $n
$ git cococo bin/rails generate scaffold post title body:text published_at:datetime
$ git cococo bin/rails db:migrate
```

### for JavaScripters

```sh
$ git cococo --init npm init --yes
$ git cococo sh -c 'echo /node_modules | tee -a .gitignore'
$ git cococo npm install --save express
$ git cococo npm install --save-dev mocha
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nishidayuya/git-cococo .

## Development

* [Ruby](https://www.ruby-lang.org/): To run `rake` command and tests.
* [CMake](https://cmake.org/download/): To build rugged.gem for tests.
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
