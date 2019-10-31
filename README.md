# Generalized Api

[![Gem Version](https://badge.fury.io/rb/generalized_api.svg)](http://badge.fury.io/rb/generalized_api)

<!-- Tocer[start]: Auto-generated, don't remove. -->

## Table of Contents

  - [Features](#features)
  - [Screencasts](#screencasts)
  - [Requirements](#requirements)
  - [Setup](#setup)
  - [Usage](#usage)
  - [Tests](#tests)
  - [Versioning](#versioning)
  - [Code of Conduct](#code-of-conduct)
  - [Contributions](#contributions)
  - [License](#license)
  - [History](#history)
  - [Credits](#credits)

<!-- Tocer[finish]: Auto-generated, don't remove. -->


## Features
- Single, DRY controller to expose the database to requests by way of a JSON API using the standard rails MVC pathways.
- Syntax developed to allow highly configurable and logical queries against the database such as like queries on string fields, paginated requests and ordering.
- Developed to interact wtih the (GeneralizedResource)[https://github.com/OddballGreg/generalized_resource] gem to provide a ActiveRecord-like chainable relation syntax for interacting with a JSON api.  

## To Do
- Configurable Model Exposure List
  - The GeneralizedApi will currently expose all models within the application to requests provided the requestor knows the exact name of the model in camel case form. This is enough to delete, show and index records, even if there is no permitted_params listing for the model.
- Configurable Parameter Rules
  - Currently the user is required to configure the the permitted params for the api rather verbosely or by requesting the column names from the Active Record models. 
- Hard Parameter Checking and exception on invalid request
  - The api will simply disregard unexpected parameters by nature of permitted params removing unexpected parameters. This may be undesireable as it can make diagnosing incorrect requests difficult, whereas an exception when invalid parameters are passed would simplify this process.
- Negative (not) requests.
- Advanced Query Requests. Allow the requester to offload relational queries to SQL on the API server rather than reconstruct the joins manually after requesting both tables of information.
- Permitted Paramter Helper
- Route Helper
- Option to disable `error: true/false` return in lieu of standard 422/200 reponses.
- Option to disable the keying of a response within the data response.
  - ie `data: []` instead of `data: {customers: []}`

## FAQ
### Why?
I wanted something that could quickly, consistently and DRYly return JSON data from a Rails api server to facilitate a microservice based architecture. I grew tired of needing to update controllers and other nonsense every single time we added a new model, especially when the only thing that changed between each model was what parameters I would permit. Having 18 controllers doing the same thing 18 times was the antithesis of D.R.Y. in my opinion.

### Does it work and should I use it in production?
GeneralizedApi was developed as it was used in production for multiple commercial api applications, and has proven to be a stable, consistent and fast way to implement a JSON api within the context of a rails environment.

This said, in the context of sensitive data, one should be certain that the information is exposed and able to be interacted with in the desired manner. GeneralizedApi was made to quickly bootstrap the process of presenting restful interactions with data via a JSON api under the assumption that the user has considered the safety implications of doing so. However, GeneralizedApi is a standard Rails controller, and can be secured using familiar methods such as Devise Token Authentication and rollify/cancancan.

### Is there something better out there?
As far as I know, maybe. I was not aware of the functionality of GraphQL when I built this, which somewhat fufills the same niche without following standard restful practices or rails conventions. Like anything in software, it might subjectively be the better choice depending on your use case, so only you can answer this question for yourself.

## Requirements

0. [Ruby 2.5.0](https://www.ruby-lang.org)
0. [Ruby on Rails](http://rubyonrails.org)
0. Other requirements will be fufilled via the Gemfile.

## Setup

To install, run:

    gem install generalized_api

Add the following to your Gemfile:

    gem "generalized_api"

## Usage

The generalized api was constructed in tandem with [GeneralizedResource](https://github.com/OddballGreg/generalized_resource) as a way to provide a standard, conventional and consistent json api interface which the GeneralizedResource gem could interact with via a chainable api riffing on ActiveRecord's ActiveRecord::Relation syntax, while also being interactable from any application that could configure the necessary parameters via the relevant REST request for the desired action.

### Config

In order to use the the GeneralizedApi, you will need to stipulate a controller that will adopt the GeneralizedApi functionality, as well as nominate the model fields you wish to be interactable via the GeneralizedApi.

GeneralizedApi expectes a symbol keyed hash of all the resources it should expose, and symbols expressing the fields that should be interactable on those models. (Essentially, the permitted_params for each model.) How you configure this controller and provide this paramter hash is up to you, but the below is a reasonably effective way to accomplish this without maintaining a long file full of table and field names.

NB: 'If you're not being completely specific about the fields you're exposing, do at least refrain from permitting the "id" field like the example below filters out, else the id's of models will be modifiable, which can cause very large issues for Rails and Active Record, let alone foreign key issues that might arise if your database was not configured strictly.

```
# in app/controllers/api/v1/api_controller.rb

class Api::V1::ApiController < ApplicationController
  include GeneralizedApi::Api

  def initialize
    super
    @resource_params = api_params(%w[customers
                                     orders
                                     order_items
                                     order_item_details])
  end

  private

  def api_params(model_names)
    full_params = {}
    model_names.each do |model|
      full_params[model.to_sym] = model.to_s.titleize.singularize.delete(' ').constantize.columns.map(&:name).map(&:to_sym) - [:id]
    end
    full_params
  end
end
```

Once this controller is configured, you will need to provide the required routing to make it available to requests:

```
# in config/routes.rb

namespace :api do
  namespace :v1 do
    post ':model/query/count', to: 'api#count'
    get ':model/count', to: 'api#count'
    post ':model/search', to: 'api#index'
    post ':model/query', to: 'api#index'
    post ':model', to: 'api#create'
    put ':model/:id', to: 'api#update'
    patch ':model/:id', to: 'api#update'
    delete ':model/:id', to: 'api#destroy'
    get ':model/:id', to: 'api#show'
    get ':model', to: 'api#index'
  end
end
```

You'll note that the above examples are namespaced to `/api/v1` per standard rails API development practice, but also that where you might commonly expect a model name like `customers` followed by the parameterized `:id`, we have a `:model` paramter. This is what GeneralizedApi uses to resolve requests without having a distinct controller per resource.

With those two pieces of configuration complete, your GeneralizedApi is ready.

### Interacting With It

The GeneralizedApi gem was constructed in tandem with [GeneralizedResource](https://github.com/OddballGreg/generalized_resource) as a way to provide a standard, conventional and consistent API interface which the GeneralizedResource gem could interact with via a chainable API riffing on ActiveRecord's Relation syntax, while also being interactable from any application that could configure the necessary parameters via the relevant REST request for the desired action.

As such, if you merely want to interact with your GeneralizedApi from another Ruby application, the [GeneralizedResource](https://github.com/OddballGreg/generalized_resource) gem handles all the details of this interaction by default. Else, you will need to contruct a protocol for delivering a JSON payload of the required keys to engage with GeneralizedApi.

**Do Note** that due to the nature of it's development, GeneralizedApi's standard data returns diverge slightly from what one might commonly expect from a Resftul API's JSON return.

The below is the expected response for a succesful show/update/create action where the return is a singular instance of the model called 'Customer':

```
{ 
  error: false,
  customer: {
    full_name: "Barney Stinson",
    first_name: "Barney",
    surname: "Stinson"
  }

}, status: :ok
```

Expected response for a succesful index/query/search action where the return is a plural array of 'Customer's:

```
{ 
  error: false,
  customers: [
    {
      full_name: "Barney Stinson",
      first_name: "Barney",
      surname: "Stinson"
    },
    {
      full_name: "Frank Barnes",
      first_name: "Frank",
      surname: "Barnes"
    }
  ]

} , status: :ok
```

GeneralizedApi by standard uses standard 200 Content Ok for succesful requests, or 422 Unprocessable Entity for requests which is unable to handle but understands. Misunderstood requests (due to pathing or whatever issue) will result in a 500 Server Error as expected.

Non-standard REST default behaviour of GeneralizedApi, in addition to keying the type of the models in its response, is to return `error: false` or `error: true` as part of the body in the event that it was unable to process the request, usually create/update/delete. In these instances, the ActiveRecord.errors.full_messages response is returned as below:

```
{
  error: true,
  messages: [
    "Full Name may not be blank!",
    "Surname may not be blank!"
  ]

}, status: :unprocessable_entity
```

### Basic Requests

Assuming you have a GeneralizedApi correctly configured with a Customer model, the below would be possible to fetch a customer with the id of `1`:

```ruby
HTTParty.get('http://localhost:3000/api/v1/customers/1').body

# { 
#  error: false,
#  customer: {
#    id: 1,
#    full_name: "Barney Stinson",
#    first_name: "Barney",
#    surname: "Stinson"
#  }
#
# }, status: :ok
```

### Indexing

Still following standard Rails API convention, a get to the model name will return an standard index of the table. However, by default this return will be paginated to the first 1000 results to prevent overloading of the API servers's memory.

```ruby 
HTTParty.get('http://localhost:3000/api/v1/customers').body

# { 
#   error: false,
#   customers: [
#     {
#       id: 1,
#       full_name: "Barney Stinson",
#       first_name: "Barney",
#       surname: "Stinson"
#     },
#     {
#       id: 2,
#       full_name: "Frank Barnes",
#       first_name: "Frank",
#       surname: "Barnes"
#     }
#   ]
# } , status: :ok
```

### Pagination

Rails developers may be familiar with the behaviour of the will_paginate gem for the safe pagination of queries. This pagination behaviour can be made use of through GeneralizedApi.

```ruby 
HTTParty.post('http://localhost:3000/api/v1/customers/query', body: {page: 1, per_page: 2}).body

# { 
#   error: false,
#   customers: [
#     {
#       id: 1,
#       full_name: "Barney Stinson",
#       first_name: "Barney",
#       surname: "Stinson"
#     },
#     {
#       id: 2,
#       full_name: "Frank Barnes",
#       first_name: "Frank",
#       surname: "Barnes"
#     }
#   ]
# } , status: :ok
```

### Querying
Of course, ActiveRecords most useful feature is it's querying of attributes, which is equally possible through GeneralizedResource.

```ruby 
HTTParty.post('http://localhost:3000/api/v1/customers/query', body: {customers: {first_name: 'Barney'}, page: 1, per_page: 2}).body

# { 
#   error: false,
#   customers: [
#     {
#       id: 1,
#       full_name: "Barney Stinson",
#       first_name: "Barney",
#       surname: "Stinson"
#     }
#   ]
# } , status: :ok
```

For additional power, GeneralizedApi also exposes syntax for performing case-insensitive like searches against a string column provided the database supports it.  

```ruby
HTTParty.post('http://localhost:3000/api/v1/customers/query/search', body: {search: { 'full_name' =>'Bar'} , page: 1, per_page: 2} ).body

# { 
#   error: false,
#   customers: [
#     {
#       id: 1,
#       full_name: "Barney Stinson",
#       first_name: "Barney",
#       surname: "Stinson"
#     },
#     {
#       id: 2,
#       full_name: "Frank Barnes",
#       first_name: "Frank",
#       surname: "Barnes"
#     }
#   ]

# } , status: :ok
```

### Ordering

GeneralizedApi allows you to specify an attribute to request the results in a specific order via the SQL.

```ruby
HTTParty.post('http://localhost:3000/api/v1/customers/query/search', body: {search_field: 'full_name', search_string: '%Bar%', page: 1, per_page: 2, order_by: { 'surname' =>  'desc'} }).body

# { 
#   error: false,
#   customers: [
#     {
#       id: 2,
#       full_name: "Frank Barnes",
#       first_name: "Frank",
#       surname: "Barnes"
#     },
#     {
#       id: 1,
#       full_name: "Barney Stinson",
#       first_name: "Barney",
#       surname: "Stinson"
#     }
#   ]

# } , status: :ok
```

### Creating

Creating using GeneralizedApi is fairly straightforward, merely post the parameters of the new model to the base route of the model.

```ruby
HTTParty.post('http://localhost:3000/api/v1/customers', body: {customer: {first_name: 'Alane', surname: 'Wake'}}).body

# { 
#   error: false,
#   customers: {
#       id: 1,
#       full_name: "Alane Wake",
#       first_name: "Alane",
#       surname: "Wake"
#     }
# } , status: :ok
```

### Updating
Updating using GeneralizedApi requires sending the parameters to be updated to the models id'd route in a put or patch request.

```ruby
HTTParty.put('http://localhost:3000/api/v1/customers/1', body: {customer: {first_name: 'Alan', surname: 'Wake'}}).body
#or
HTTParty.patch('http://localhost:3000/api/v1/customers/1', body: {customer: {first_name: 'Alan', surname: 'Wake'}}).body

# { 
#   error: false,
#   customers: {
#       id: 1,
#       full_name: "Alan Wake",
#       first_name: "Alan",
#       surname: "Wake"
#     }
# } , status: :ok
```

### Deleting

Deleteing using GeneralizedApi requires sending a Delete action to the models id'd route.

```ruby
HTTParty.delete('http://localhost:3000/api/v1/customers/1').body

# { 
#   error: false,
#   messages: [
#     "Customer 1 has been succesfully deleted!"
#   ]
# } , status: :ok
```

### Showing

Requesting the show action for a model is a simple get request to it's id'd route.

```ruby
HTTParty.get('http://localhost:3000/api/v1/customers/1').body

# { 
#   error: false,
#   customer: {
#       id: 1,
#       full_name: "Alan Wake",
#       first_name: "Alan",
#       surname: "Wake"
#     }
# } , status: :ok
```

### Count

Requesting the count of a model is as simple as adding count to the get request for that route.

```ruby
HTTParty.get('http://localhost:3000/api/v1/customers/count').body

# { 
#   error: false,
#   count: 10
# } , status: :ok
```

Or a post to request the count of a number of models under a where clause:

```ruby
HTTParty.post('http://localhost:3000/api/v1/customers/query/count', body: {customer: {first_name: 'Barney'}} ).body

# { 
#   error: false,
#   count: 1
# } , status: :ok
```

## Tests

To test, run:

    bundle exec rake

## Versioning

Read [Semantic Versioning](http://semver.org) for details. Briefly, it means:

- Major (X.y.z) - Incremented for any backwards incompatible public API changes.
- Minor (x.Y.z) - Incremented for new, backwards compatible, public API enhancements/fixes.
- Patch (x.y.Z) - Incremented for small, backwards compatible, bug fixes.

## Code of Conduct

Please note that this project is released with a [CODE OF CONDUCT](CODE_OF_CONDUCT.md). By
participating in this project you agree to abide by its terms.

## Contributions

Read [CONTRIBUTING](CONTRIBUTING.md) for details.

## License

Copyright 2018 []().
Read [LICENSE](LICENSE.md) for details.

## History

Read [CHANGES](CHANGES.md) for details.
Built with [Gemsmith](https://github.com/bkuhlmann/gemsmith).

## Credits

Developed by [Gregory Havenga](https://github.com/OddballGreg) at
[]().
