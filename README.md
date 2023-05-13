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

```console
$ wget https://raw.githubusercontent.com/nishidayuya/git-cococo/master/exe/git-cococo
$ chmod a+x git-cococo
$ mv git-cococo move-to-PATH-env-directory/
```

## Usage

Run `sed` command and commit changes with re-runnable commit message "run: git cococo sed -i -e s/foo/bar/g a.txt".

```console
$ git cococo sed -i -e s/foo/bar/g a.txt
```

---

Oops! I forgot un-commmitted changes. `git cococo` tells me it and don't run command.

```console
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

Replace `writed` to `wrote` all of git tracked files and commit.

```console
$ git cococo sh -c 'git ls-files -z | xargs -0 sed -i -e s/writed/wrote/g'
```

## Examples

### for Rubyists

```console
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

```console
$ git cococo --init npm init --yes
$ git cococo sh -c 'echo /node_modules | tee -a .gitignore'
$ git cococo npm install --save express
$ git cococo npm install --save-dev mocha
```

### for Pythonistas

```console
$ git cococo --init pyenv local 3.8.1
$ git cococo touch requirements.txt
$ git cococo sh -c 'echo /venv | tee -a .gitignore'
$ python -m venv venv
$ git cococo sh -ex -c '
    . venv/bin/activate
    pip install -r requirements.txt
    pip install --upgrade pip
    pip install tensorflow
    pip freeze | tee requirements.txt
  '
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nishidayuya/git-cococo .

## Development

* [Ruby](https://www.ruby-lang.org/): To run `rake` command and tests.
* [CMake](https://cmake.org/download/): To build rugged.gem for tests.
* [Shellcheck](https://github.com/koalaman/shellcheck#installing): To run lint.

Clone this project.

Install related RubyGems and run tests and lint:

```console
$ bundle
$ bundle exec rake
```

Write some changes with tests.

Run tests and lint:

```console
$ bundle exec rake
```

Submit pull-request.

Thank you!

### Tools for development

#### To use specified version of Git:

```console
$ v=2.11.0
$ ./tools/install_git $v
$ ./tools/switch_git $v
git version 2.11.0
```

#### To use latest released version of Git:

```console
$ v=$(./tools/latest_git_version)
$ ./tools/install_git $v
$ ./tools/switch_git $v
```
