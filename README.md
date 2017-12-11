# `git cococo`: git COmmit COmpletely COmmand output

[![License X11](https://img.shields.io/badge/license-X11-blue.svg)](https://raw.githubusercontent.com/nishidayuya/git-cococo/master/LICENSE.txt)
[![Build Status](https://img.shields.io/travis/nishidayuya/git-cococo/master.svg)](https://travis-ci.org/nishidayuya/git-cococo)
[![Build Status](https://img.shields.io/appveyor/ci/nishidayuya/git-cococo/master.svg)](https://ci.appveyor.com/project/nishidayuya/git-cococo)

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

Replace `writed` to `wrote` all of git tracked files and commit with re-runnable commit message.

```sh
$ git cococo sh -c 'git ls-files -z | xargs -0 sed -i -e s/writed/wrote/g'
```

Examples for Rubyists:

```sh
$ git cococo --init bundle init
$ git cococo bundle add rake
$ git cococo bundle update nokogiri

$ n=new_awesome_gem && git cococo --init=$n bundle gem $n

$ n=blog && git cococo --init=$n rails new $n
$ git cococo bin/rails generate scaffold post title body:text published_at:datetime
$ git cococo bin/rails db:migrate
```

Examples for Noders:

```sh
$ git cococo --init npm init --yes
$ git cococo npm install --save xmlhttprequest
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
