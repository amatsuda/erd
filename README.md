# Erd

A Rails engine for drawing your app's ER diagram and operating migrations


## Requirements

* Rails 7.0, 6.1, 6.0, 5.2, 5.1, 5.0, 4.2, 4.1, 4.0, 3.2, or 3.1

* Graphviz


## Installation

Bundle 'erd' gem to your existing Rails app's Gemfile:
```ruby
gem 'erd', group: :development

```


## Usage

Browse at your http://localhost:3000/erd


## Features

### Show Mode

* Erd draws an ER diagram based on your app's database and models.

* You can drag and arrange the positions of each model.

    * Then you can save the positions to a local file `db/erd_positions.json`, so you can share the diagram between the team members.

### Edit Mode

* You can operate DB schema manipulations such as `add column`, `rename column`, `alter column`, `create model (as well as table)`, and `drop table`.

* Then, Erd generates migration files on the server.

* And you can run each migration on your browser super quickly.


## TODO

* Fix buggy JS

* drop column (need to think of the UI)

* stop depending on Graphviz

* tests

* cleaner code (the code is horrible. Please don't read the code, though of course your patches welcome)


## Contributing to Erd

* Send me your pull requests!


## Team

* [Akira Matsuda][https://github.com/amatsuda]
* [Teppei Machida][http://github.com/machida] (design)


## Copyright

Copyright (c) 2012 Akira Matsuda. See MIT-LICENSE for further details.
