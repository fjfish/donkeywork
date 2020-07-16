# Donkeywork

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/donkeywork`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'donkeywork'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install donkeywork

Add this to your Rakefile:

    spec = Gem::Specification.find_by_name 'donkeywork'
    load "#{spec.gem_dir}/lib/tasks/donkeywork.rake"

Then try

    rake donkey:info

## Usage

You create your model, and then have to create all the other rubbish that goes with it. This is tedious donkey work. The original project this came from was an Ember one, the Rails side of which uses authorizers, serializers and controllers etc. etc. to talk JSON to the Ember app. When building a new module with half a dozen new tables I decided it would be quicker to use templates to do all of the boring bits.

We also use rspec, and in general have specs for the authorizers and serializers (but not controllers for historical reasons I don't want to go into here), so the templates build those for you.

In another side project I use plain old HTML (because it's internal and doesn't need to be over done). So I also added templates to do HTML controllers and views with a default form as well.

This gives you a series of rake tasks that you give the camel cased model name to:

        rake donkey:authorizer_with_specs       # create authorizer with specs
        rake donkey:check                       # check environment
        rake donkey:controller                  # create controller
        rake donkey:ember_model                 # create Ember model
        rake donkey:fabricator                  # create fabricator
        rake donkey:html_controller             # create HTML controller
        rake donkey:html_views                  # create HTML views
        rake donkey:info                        # info
        rake donkey:init                        # initialise
        rake donkey:serializer_with_specs       # create serializer with specs

Note that the Ember is a little non-generic and you might want to change it. We also use Fabricate, not FactoryBot, so I generate fabricators.

As it stands it's rough around the edges but will give you something that works after you've created the model and just want to get to the interesting bits, whether you're going down the customised Ember route or HTML.

I have plans to allow you to make your own copies of the templates and put them in your Rails project and so on, but not the energy to do it today.

It supports namespaced tables, except with the fabricators, which will require a little work after generation. For example:

    Fabricator(:rota_practitioner_diary, from: "Rota::PractitionerDiary")
    
I can't remember how FactoryBot handles this, so some editing may be required. Also might need to edit the specs, but at least you didn't have to write them yourself. :)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fjfish/donkeywork. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Donkeywork project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).
