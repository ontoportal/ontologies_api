# MC Sinatra
#### {model} {controller} {sinatra}
MC Sinatra is a skeleton Sinatra application and bootstrap/runtime environment that allows for the use of models, controllers, and helpers for creating simple, easy-to-understand web APIs.

## Usage
Fork the project, create a branch, and then customize as necessary. There are several classes that are included that give you an idea of how to use extend the existing framework.

### Installation
MC Sinatra requires a ruby 1.9.3 environment and the bundler gem. Once bundler is installed, fork, branch and clone the code. Then, from the main directory:

    bundle install
    rackup

### Runtime environment options
There are several ways to load the application:

- `bundle exec shotgun` will load the application using the Shotgun server, which will reload all code on every request. This should be relatively fast.
- `bundle exec rackup` will load the application using the config.ru file in the rack environment.
- `ruby app.rb` will load the Sinatra framework directly in a ruby vm. This can be useful for debugging bootstrapping issues. However, code reloading does not happen in this environment.

A full range of options are available at the command line, common ones being:

- `-p` use a custom port
- `-E` change the environment (default: `development`)
- `-o` bind to a custom host

### REPL / Console Access
MC Sinatra provides a basic REPL environment using Pry, an alternative to ruby's irb. To enter the console:
`rackup -e console`

`quit` will exit the console. No code reloading is available once you are in the console (future versions may support this).

The console will automatically load a Rack::Test environment, meaning that you can test requests in the console:

`get '/path', params={}, rack_env={}`

`get`, `put`, `post`, `delete`, and `head` are all available. See [Rack::Test](http://www.sinatrarb.com/testing.html) for more information.

Pry also allows for command-line code browsing. For example:

    cd Person
    ls

For help on available commands, type `help` in the console or read up on [Pry](http://pryrepl.org/).

### Debugging
You can place the statement `binding.pry` anywhere in the code to drop into a pry-based debug session.

## Components

### Models
Models reside in the /models folder. There is a corresponding models folder under /test. Sub-folders can be used for organization where necessary.

### Controllers
Sinatra routes can be defined in controller files, found in the /controllers folder. All controller files should inherit from the ApplicationController, which makes methods defined in the ApplicationController available to all controllers. Generally you will create one controller per resource. Controllers can also use helper methods, either from the ApplicationHelper or other helpers.

### Helpers
Re-usable code can be included in helpers in files located in the /helpers folder. Helper methods should be created in their own module namespace, under the Sinatra::Helpers module (see MessageHelper for an example).

### Libraries
The /lib folder can be used for organizing complex code or Rack middleware that doesn't fit well in the /helpers or /models space. For example, a small DSL for defining relationships between resources or a data access layer.

### Config
Environment-specific settings can be placed in the appropriate /config/environments/{environment}.rb file. These will get included automatically on a per-environment basis.

### Vendor
You can bake in gems using the bundler command `bundle install --deployment`. This will freeze the gem versions for use in deployment.

### Logs
Logs are created when running in production mode. In development, all logging goes to STDOUT.

## Testing
A simple testing framework, based on Ruby's TestUnit framework and rake, is available. The tests rely on a few conventions:

- Models and controllers should require and inherit from the /test/test_case.rb file (and TestCase class).
- Helpers should require and inherit from the /test/test_case_helpers.rb file (and TestCaseHelpers class).
- Libraries should have preferably have self-contained tests.

The [Rack::Test](http://www.sinatrarb.com/testing.html) environment is available from all test types for doing mock requests and reading responses.

### Rake tasks
Several rake tasks are available for running tests:

- `rake test` runs all tests
- `rake test:controllers` runs controller tests
- `rake test:models` runs model tests
- `rake test:helpers` runs helper tests

Tests can alternatively be run by invoking ruby directly:
`ruby tests/controllers/test_hello_world.rb`\

## Logging
A global logger is provided, which unfortunately does not yet integrate with Sinatra's logger. The logger is available using the constant `LOGGER` and uses Apache's common logging format.

There are multiple levels of logging available (`debug`, `info`, `warn`, `error`, and `fatal`), with only logging for `info` and above available in the production environment.

For more information on the logger, see Ruby's [Logger class](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/logger/rdoc/Logger.html).

## Bootstrapping
The application is bootstrapped from the app.rb file, which handles file load order, setting environment-wide configuration options, and makes controllers and helpers work properly in the Sinatra application without further work from the developer.

app.rb loads the /init.rb file to handle this process. Sinatra settings are included in the app.rb file.

## Dependencies
Dependent gems can be configured in the Gemfile using [Bundler](http://gembundler.com/).