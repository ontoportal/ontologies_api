# Intro to NCBO infrastructure 

## Prerequisites
- Command line interface (iterm, xterm, etc)
- [Ruby 1.9.3](http://www.ruby-lang.org/en/downloads/) (most recent patch level -- see rbenv below for information on managing multiple versions)
- [Git](http://git-scm.com/)
- [Bundler](http://gembundler.com/)
    - Install with `gem install bundler` if you don't have it
- [4store](http://4store.org/)
    - NCBO code relies on 4store as the main datastore. There are several installation options, but the easiest is getting the [binaries](http://4store.org/trac/wiki/Download).
    - For starting, stopping, and restarting 4store easily, you can try setting up [4s-service](https://gist.github.com/4211360)
- [rbenv](https://github.com/sstephenson/rbenv) and [ruby-build](https://github.com/sstephenson/ruby-build)
    - If you anticipate needing to switch Ruby versions for other projects, you may want to install something like [rbenv](https://github.com/sstephenson/rbenv) to manage multiple Ruby installations

## Installing
Here are the steps to run at the command line to get the code, get the dependencies, run the tests, and then run the application:

    git clone github.com:ncbo/ontologies_api.git
    cd ontologies_api
    bundle install
    bundle exec rake test
    bundle exec shotgun

All dependencies for the project(s) are managed using Bundler, which ensures that all developers are using the same version of the software. Most of the dependencies are Ruby-only, but occasionally something will rely on a compiled C-language binary, which can make working on Windows challenging.

## Updating
Code from github can be pulled easily:

    # git fetch allows you to see changes from github
    git fetch
    # You'll want to switch to the master branch
    # (unless you need code from a specific branch)
    git checkout master
    # After running git status, you can see how many 
    # commits exist on the remote github repo that 
    # you haven't pulled
    git status
    # Running git pull will get those changes and 
    # attempt a merge with your code
    git pull
    # You may get conflicts if you have touched code that
    # the server also has changes for. These can be 
    # resolved easily by opening the file where a 
    # conflict occurs, make the file look like it should, 
    # then save. Then run:
    git add file/that/conflicts.rb
    git commit
    # Just to be safe, let's update our bundle
    # bundle update will get changes from git repos
    bundle install
    bundle update
    
## Adding code
Working with git can be confusing and frustrating if you are coming from other source code management systems. It's best to not try to map concepts from svn or cvs onto git and really try to approach it as something new.

There are a few things to keep in mind:

- Generally, new features and bug fixes should be developed in their own branch and then merged into the main development branch (sometimes called `development`, other times directly in the `master` branch)
    - This is the easiest way to create a new branch:
    `git checkout -b this_is_my_branch_name`    
- ABC: always be committing
    - git works best when you have lots of smaller commits to work with. 
    - Committing code does not send it back to the github repository, so there's no reason to avoid commits until you have a big chunk of work done.
- Once you have finished working in a feature or bug fix branch, you can merge it with the main development branch:
    - `git checkout this_is_my_branch_name`
    - `git merge master`
    - `git checkout master`
    - `git merge this_is_my_branch_name`
    - These steps will make sure you have recent changes from `master` in `this_is_my_branch_name`, then move changes from `this_is_my_branch_name` into `master`.
- After you have put code into `master`, you can push the changes to the github repository:
    - `git push origin master`
    - This makes your changes available so that everyone else can `git pull` them.
- It's also a good idea to merge changes from the main development branch often as you are working, especially if your work is going to take longer than a day. You can do this from your branch AFTER you have pulled the most recent changes:
    - `git merge master`

    
## Workflow
There are a few ways to work with the code and run the application. The three things you will likely do the most often is 1) run the application with code reloading enabled 2) run the console and 3) run tests

### Code reloading
We can use a library called [Shotgun]() to force our entire application to reload on each request. This allows you to make a change in a file, hit refresh in a browser, and see the changes reflected. To load the application using Shotgun, simply run:

`bundle exec shotgun`

Once it has started, the application will be available on localhost:9393 (by default, this can be changed). Running via this method will work pretty much like every other server-based environment you have used in the past.

#### Debugging
If you want to insert a breakpoint, simply go to the code and add `binding.pry` on a line by itself. When you make a request, the application will stop at that point in the code and you can inspect objects and local variables easily. Type `ls` to see a list of local variables and methods that are available to run.

### Testing
Tests are a very handy way to do development. They don't require that you make individual requests using a browser, meaning that it's easier to check multiple endpoints at once.

Tests can be created under the top-level `test` folder in the corresponding section (model, controller, etc). Tests are written using the Ruby default [Test::Unit library](http://en.wikibooks.org/wiki/Ruby_Programming/Unit_testing). Many projects will have a base test class that initializes the environment as needed (e.g. [`test_case.rb`](https://github.com/ncbo/ontologies_api/blob/master/test/test_case.rb) from ontologies_api).

To run tests, just use ruby to call the class:

`ruby test/controllers/test_user_controller.rb` (from ontologies api)

You can put breakpoints using `binding.pry` and interact with the code directly from the test.

#### Rake
You can also invoke full test suites or run all tests with rake (Ruby Make). To see the available rake tasks, run `rake -T` from the project folder. Generally, running `rake test` will execute all tests.

### Console
You can also load a pry session that has been bootstrapped with the project environment:

`bundle exec rackup -E console`

This will put you into the application at a point where you can invoke code. For example, you could create and save new Goo models, make requests using methods from [Rack::Test](http://www.sinatrarb.com/testing.html), or access variables, settings, etc set for the project.

We'll be looking at options to support code reloading from the console. For now, hit `ctrl-c` and then reload the console to see your changes reflected.

## ontologies_api
The [ontologies_api](https://github.com/ncbo/ontologies_api) project holds code for the main ontologies REST API. The code is contained primarily in controllers and helpers while relying on the ontologies_linked_data library for models (Ontology, User, Group, Category, etc). Models that are specific to the ontologies_api context can be created in the project under the `models` folder.

This is just the start of the framework for our REST applications. If things aren't working smoothly or you see an opportunity to improve how we do things, please send an email or (preferred) [file an issue on github](https://github.com/ncbo/ontologies_api/issues).

The ontologies_api relies on Sinatra for handling route definitions. Routes are created with an HTTP verb and a path, which can contain parameters (both optional and required).

Stubs for many of the controllers we will need (and their corresponding tests) have already been created, but to see a concrete example, you can look at users:

[`User`](https://github.com/ncbo/ontologies_linked_data/blob/master/lib/ontologies_linked_data/models/user.rb) model (from the ontologies_linked_data library)

[`UsersController`](https://github.com/ncbo/ontologies_api/blob/master/controllers/users_controller.rb)

[`TestUsersController`](https://github.com/ncbo/ontologies_api/blob/master/test/controllers/test_users_controller.rb)

### HTTP Verbs
You'll note in the users controller that there is no POST method. Recently, the W3C has added PATCH as a verb, which really clarifies how the different verbs are used in a RESTful context:

- GET: retrieve resource
- POST: create resource when the server assigns an id
- PUT: create or replace resource when client can assign the id
- PATCH: partial update of existing resource
- DELETE: remove a resource

Since the client knows the id (username), you will always do a PUT to create users and typically do a PATCH to update them.

## Appendix
The following is information you may find useful while working in a Ruby/Sinatra/Rack environment.

### Goo API Specifics
[Goo](https://github.com/ncbo/goo) is a general library for Object to RDF Mapping written by Manuel. It doesn't have any NCBO-specific pieces in it, except to model data in the way it makes sense for us. It includes functionality for basic CRUD operations.

Using Goo, we have created a library called [ontologies_linked_data](https://github.com/ncbo/ontologies_linked_data). This library extends Goo to provide specific models for use with NCBO data.

Eventually we hope to have some good documentation in code for the API, but while things are still in flux and time is short, you can see how things work by looking at the tests included with ontologies_linked_data or Goo. We'll cover the basics here:

#### Creating a new object
We can look at some tests in Goo to see how to work with objects built with Goo.

For example, here is an object `Person` defined in a test: [`test_model_person.rb`](https://github.com/ncbo/goo/blob/master/test/test_model_person.rb#L28-L40)

In the method `test_person`, you can see how an instance of the model is created: [`Person.new`](https://github.com/ncbo/goo/blob/master/test/test_model_person.rb#L49)

#### Validating an object

There can be restrictions on the kind of data stored in an attribute for a Goo object. For example, `Person` contains an attribute called `contact_data`. This attribute can only be populated with an instance of the `ContactData` class or it will not be considered valid. This is defined as a p[art of the object](https://github.com/ncbo/goo/blob/master/test/test_model_person.rb#L33) with this syntax:
`:contact_data , :instance_of => { :with => :contact_data }`

To test if an instance is valid, you can use the `valid?` method. For example:

    > p = Person.new
    > p.valid?
    => false

If calling `valid?` fails, the correspond errors will be available by calling the `errors` method, for example:

    > p = Person.new
    > p.valid?
    => false
    > p.errors

#### Saving an object
After validating an object, you can call the `save` method to store the object's triples in the triplestore backend. If the object isn't valid then calling `save` will result in an exception.

#### Retrieving an object
The simplest way to retrieve an object is using its id with the class method `find`:

`Person.find("paul")`

You can also do a lookup with the full id IRI:

`Person.find(RDF::IRI.new("http://example.org/person/paul"))`

Each object type has its own IRI prefix, so using the short form of the id will simply result it in being appended to the IRI prefix.

You can also search for objects using attribute conditions:

    Person.where(:name => "paul")
    Person.where(:birth_date => DateTime.parse("2012-10-04T07:00:00.000Z"))

You can also retrieve all objects:

`Person.all`

In the future, there will be syntax to handle [offsets and limits](https://github.com/ncbo/goo/issues/26).

#### Updating an object
After retrieving an object, you can modify attributes and then save the object in order to update the data. This corresponds to an HTTP PATCH.

Another option is to delete the existing object and write a new one with the same id as the old. This would be equivalent to an HTTP PUT.

#### Deleting an object
Goo objects also contain a `delete` method that will remove all of the object's triples from the store.

### Rack
[Rack](https://github.com/rack/rack) is a framework that sits between a web server (apache, passenger, thin, etc) and application code:

    [ web server ] → [ request ] → [ rack / middleware ] → [ application ]  ↓
                    [ web server ] ← [ response ] ← [ rack / middleware ] ←

Rack and its associated middleware basically wraps your application code and allows you to work with and modify the http request and response information. This happens in the `rack / middleware` steps above.

[Read More](http://whatcodecraves.com/articles/2012/07/23/ruby-on-rack)

### A note on bundler
While bundler is a really nice way to manage dependencies, it also introduces some pain points when it comes to running code. Bundler will install the gems for a particular project in a way that they are isolated from the system gems. This is good when you are trying to make sure that everyone is working with the same version of the dependencies and it doesn't muck up your system gem installation.

However, it also means that when you go to run code then your normal gem setup doesn't know about the gems that bundler has installed. There's a relatively easy way to get around this using an execution method provided by bundler.

For example:
`bundle exec rake test`

This will execute the rake task called test using the bundle environment that has been created for your project. You will need to do this for pretty much any command you want to run associated with the project:

- `bundle exec shotgun`
- `bundle exec ruby test/controllers/test_application_controller.rb`
- `bundle exec rackup -E console`

There are a few methods for possibly getting around this, which essentially bootstrap the bundler environment for the project under the hood when you run something. We can explore these solutions more. You can also alias the `bundle exec` command in your `.bashrc` or `.zshrc` file:

    alias b='bundle exec '
    alias br='bundle exec ruby '

