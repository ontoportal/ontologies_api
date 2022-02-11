# Contributing to the BioPortal REST API

Thanks for taking the time to contribute! We appreciate you!

## Code of Conduct

This project and everyone participating in it is governed by the [BioPortal Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [admin@bioontology.org](mailto:admin@bioontology.org).

## How do I ask a question?

Please don't file issues to ask questions. You'll get the fastest response by sending a message to our support list: [support@bioontology.org](mailto:support@bioontology.org)

## What to know before getting started

The [BioPortal REST API](https://data.bioontology.org/documentation) is an open source project made up of seven repositories, which are hosted in the [NCBO Organization](https://github.com/ncbo) on GitHub. This section is meant to help you understand which of the seven repositories encapsulates the functionality you'd like to modify or report bugs against.

### API repositories

* [ontologies_api](https://github.com/ncbo/ontologies_api) - Hypermedia API for ontologies
* [ontologies_linked_data](https://github.com/ncbo/ontologies_linked_data) - Models and serializers for ontologies and related artifacts
* [ncbo_annotator](https://github.com/ncbo/ncbo_annotator) - Annotate text with relevant ontology concepts
* [ncbo_ontology_recommender](https://github.com/ncbo/ncbo_ontology_recommender) - Obtain recommendations for relevant ontologies based on excerpts from biomedical text or lists of keywords
* [ncbo_cron](https://github.com/ncbo/ncbo_cron) - Cron jobs that run on a regular basis in the infrastructure
* [goo](https://github.com/ncbo/goo) - Graph Oriented Objects (GOO) for Ruby. An RDF/SPARQL-based ORM.
* [sparql-client](https://github.com/ncbo/sparql-client) - SPARQL client for Ruby

## How can I contribute?

### Reporting bugs

Bugs are tracked using [GitHub issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/about-issues). Before submitting a bug report, determine which repository the problem should be reported against, and search the Issues tab to see if the problem has already been entered. When creating issues:

* Use clear, descriptive titles
* Describe the steps to reproduce the problem
* Include details about your environment

### Suggesting enhancements

Enhancement suggestions are welcome, including new features and minor enhancements to existing functionality. Enhancements are tracked using [GitHub issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/about-issues) with the "enhancement" label. Before creating an enhancement request, determine which repository the enhancement should be reported against, and search the Issues tab to see if it has already been entered.

### Contributing to the code

We follow the [fork and pull](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/getting-started/about-collaborative-development-models) collaborative development model.

Please use the following guideline for code contributions:

* Fork the repository
* New features and bug fixes should be developed in their own branch
* Add tests for any changes

Pull requests are accepted and encouraged.
    
## Working with the source code

### Workflows

There are several ways to work with the code and run the application. The three things you will likely do most often are:

1) Run the application with code reloading enabled 
2) Run the console 
3) Run tests

#### Run with code reloading

We use a library called [Shotgun]() to force our entire application to reload on each request. This allows you to make a change in a file, hit refresh in a browser, and see the changes reflected. To load the application with Shotgun, use the following command:

`bundle exec shotgun`

Once started, the application will be available on localhost:9393 (by default, this can be changed).

If you need to insert a breakpoint, modify the code by adding `binding.pry` on a line by itself. When you make a request, the application will stop at that point in the code and you can inspect objects and local variables easily. Type `ls` to see a list of local variables and methods that are available to run.

#### Run in console mode

You can load a pry session that's bootstrapped with the project environment:

`bundle exec rackup -E console`

This will put you into the application at a point where you can invoke code. For example, you could create and save new Goo models, make requests using methods from [Rack::Test](http://www.sinatrarb.com/testing.html), or access variables, settings, etc set for the project.

#### Run tests

Tests can be created under the top-level `test` folder in the corresponding section (model, controller, etc). Tests are written using the Ruby default [Test::Unit library](http://en.wikibooks.org/wiki/Ruby_Programming/Unit_testing). Many projects will have a base test class that initializes the environment as needed (e.g. [`test_case.rb`](https://github.com/ncbo/ontologies_api/blob/master/test/test_case.rb) from ontologies_api).

To run tests, just use Ruby to call the class:

`bundle exec ruby test/controllers/test_user_controller.rb` (from ontologies api)

You can insert breakpoints using `binding.pry` and interact with the code directly from the test.

Another option is invoking full test suites with [Rake](https://ruby.github.io/rake/). To see the list of available rake tasks, run `rake -T` from the project folder. Generally, running `rake test` will execute all tests.

### Components

#### Controllers

Sinatra routes can be defined in controller files, found in the /controllers folder. All controller files should inherit from the ApplicationController, which makes methods defined in the ApplicationController available to all controllers. Generally you will create one controller per resource. Controllers can also use helper methods, either from the ApplicationHelper or other helpers.

#### Helpers

Re-usable code can be included in helpers in files located in the /helpers folder. Helper methods should be created in their own module namespace, under the Sinatra::Helpers module (see MessageHelper for an example).

#### Libraries

The /lib folder can be used for organizing complex code or Rack middleware that doesn't fit well in the /helpers or /models space. For example, a small DSL for defining relationships between resources or a data access layer.

#### Config

Environment-specific settings can be placed in the appropriate /config/environments/{environment}.rb file. These will get included automatically on a per-environment basis.

#### Logs

Logs are created when running in production mode. In development, all logging goes to STDOUT.

### Testing

A simple testing framework, based on Ruby's TestUnit framework and Rake, is available. The tests rely on a few conventions:

* Models and controllers should require and inherit from the /test/test_case.rb file (and TestCase class).
* Helpers should require and inherit from the /test/test_case_helpers.rb file (and TestCaseHelpers class).
* Libraries should preferably have self-contained tests.

The [Rack::Test](http://www.sinatrarb.com/testing.html) environment is available from all test types for doing mock requests and reading responses.

#### Rake tasks

Several rake tasks are available for running tests:

- `bundle exec rake test` runs all tests
- `bundle exec rake test:controllers` runs controller tests
- `bundle exec rake test:models` runs model tests
- `bundle exec rake test:helpers` runs helper tests

Tests can alternatively be run by invoking Ruby directly:

```ruby
bundle exec ruby test/controllers/test_hello_world.rb
```

### Logging

A global logger is provided, which unfortunately does not yet integrate with Sinatra's logger. The logger is available using the constant `LOGGER` and uses Apache's common logging format.

There are multiple levels of logging available (`debug`, `info`, `warn`, `error`, and `fatal`), with only logging for `info` and above available in the production environment.

For more information on the logger, see Ruby's [Logger class](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/logger/rdoc/Logger.html).

### Bootstrapping

The application is bootstrapped from the app.rb file, which handles file load order, setting environment-wide configuration options, and makes controllers and helpers work properly in the Sinatra application without further work from the developer.

app.rb loads the /init.rb file to handle this process. Sinatra settings are included in the app.rb file.

### Dependencies

Dependent gems can be configured in the Gemfile using [Bundler](https://bundler.io/).

## Appendix

The following is information you may find useful while working in a Ruby/Sinatra/Rack environment.

### Goo API Specifics

[Goo](https://github.com/ncbo/goo) is a general library for Object to RDF Mapping written by [Manuel Salvadores](https://github.com/msalvadores). It doesn't have any NCBO-specific pieces in it, except to model data in the way it makes sense for us. It includes functionality for basic CRUD operations.

Using Goo, we have created a library called [ontologies_linked_data](https://github.com/ncbo/ontologies_linked_data). This library extends Goo to provide specific models for use with NCBO data. You can see how things work by looking at the tests included with ontologies_linked_data or Goo. We'll cover the basics here:

#### Creating a new object

We can look at some tests in Goo to see how to work with objects built with Goo.

For example, here is an object `Person` defined in a test: [`test_model_person.rb`](https://github.com/ncbo/goo/blob/master/test/test_model_person.rb#L28-L40)

In the method `test_person`, you can see how an instance of the model is created: [`Person.new`](https://github.com/ncbo/goo/blob/master/test/test_model_person.rb#L49)

#### Validating an object

There can be restrictions on the kind of data stored in an attribute for a Goo object. For example, `Person` contains an attribute called `contact_data`. This attribute can only be populated with an instance of the `ContactData` class or it will not be considered valid. This is defined as a [part of the object](https://github.com/ncbo/goo/blob/master/test/test_model_person.rb#L33) with this syntax:
`:contact_data , :instance_of => { :with => :contact_data }`

To test if an instance is valid, you can use the `valid?` method. For example:

```
> p = Person.new
> p.valid?
=> false
```

If calling `valid?` fails, the corresponding errors will be available by calling the `errors` method, for example:

```
> p = Person.new
> p.valid?
=> false
> p.errors
```

#### Saving an object

After validating an object, you can call the `save` method to store the object's triples in the triplestore backend. If the object isn't valid, calling `save` will result in an exception.

#### Retrieving an object

The simplest way to retrieve an object is using its ID with the class method `find`:

```
Person.find("paul")
```

You can also do a lookup with the full IRI:

```
Person.find(RDF::IRI.new("http://example.org/person/paul"))
```

Each object type has its own IRI prefix, so using the short form of the ID will simply result it in being appended to the IRI prefix.

You can also search for objects using attribute conditions:

```
Person.where(name: "paul")
Person.where(birth_date: DateTime.parse("2012-10-04T07:00:00.000Z"))
```

You can also retrieve all objects:

```
Person.all
```

In the future, there will be syntax to handle [offsets and limits](https://github.com/ncbo/goo/issues/26).

#### Updating an object

After retrieving an object, you can modify attributes and then save the object in order to update the data. This corresponds to an HTTP PATCH.

Another option is to delete the existing object and write a new one with the same ID as the old. This would be equivalent to an HTTP PUT.

#### Deleting an object

Goo objects also contain a `delete` method that will remove all of the object's triples from the store.

### Rack

[Rack](https://github.com/rack/rack) is a framework that sits between a web server (Apache, passenger, Thin, etc) and application code:

    [ web server ] → [ request ] → [ rack / middleware ] → [ application ]  ↓
                    [ web server ] ← [ response ] ← [ rack / middleware ] ←

Rack and its associated middleware basically wraps your application code and allows you to work with and modify the HTTP request and response information. This happens in the `rack / middleware` steps above.

[Read More](http://whatcodecraves.com/articles/2012/07/23/ruby-on-rack)
