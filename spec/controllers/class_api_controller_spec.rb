# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClassApiController, type: :controller do
  let (:customer) { Customer.create(name: "gawreg", stuff: "aerwgh") }
  let (:test) { Test.create(name: "gawreg", stuff: "aerwgh") }
  let (:block) { Block.create(name: "gawreg") }

  it "allows a user to request a customer index without pagination params" do
    get :index, params: {model: 'customer'}

    expect(response.code).to eq("200")
  end

  it 'allows the user to retrieve the count of a resource' do
    get :count, params: {model: 'customer'}

    expect(JSON.parse(response.body)['customers_count']).to eq Customer.count
  end

  it 'allows the user to retrieve the scoped count of a resource' do
    post :count, params: {model: 'customer', customer: {name: 'test'}}

    expect(JSON.parse(response.body)['customers_count']).to eq Customer.where(name: 'test').count
  end

  it "allows a user to request a test index without pagination params" do
    get :index, params: {model: 'test'}

    expect(response.code).to eq("200")
  end

  it "allows a user to query without a paramater" do
    post :index, params: {model: 'customer'}

    expect(response.code).to eq("200")
  end

  it "allows a user to query with pagination parameters" do
    post :index, params: {model: 'customer', page: 1, per_page: 10}

    expect(response.code).to eq("200")
  end

  it "allows a user to query with an order parameter" do
    post :index, params: {model: 'customer', order_by: :name}

    expect(response.code).to eq("200")
  end

  it "allows a user to query by a permitted paramater" do
    post :index, params: {model: 'customer', customers: {name: "customer"}}

    expect(response.code).to eq("200")
  end

  it "allows a user to show an existing record record" do
    get :show, params: {model: 'customer', id: customer.id}

    expect(response.code).to eq("200")
  end

  context "allows a user to create a record" do
    it "returns success if the user was created" do
      post :create, params: {model: 'customer', customer: {name: "gawreg", stuff: "aerwgh"}}

      expect(response.code).to eq("200")
    end

    it "it returns a 422 if the record did not meet validation" do
      post :create, params: {model: 'customer', customer: {stuff: "aerwgh"}}

      expect(response.code).to eq("422")
    end
  end

  context "allows a user to update a record" do
    it "returns success if the user was updated" do
      patch :update, params: {model: 'customer', id: customer.id, customer: {name: "new_name", stuff: "aerwgh"}}

      expect(response.code).to eq("200")
      expect(customer.reload.name).to eq("new_name")
    end

    it "it returns a 422 if the record did not meet validation" do
      post :update, params: {model: 'customer', id: customer.id, customer: {name: nil}}

      expect(response.code).to eq("422")
    end
  end

  it "allows a user to destroy a record" do
    delete :destroy, params: {model: 'customer', id: customer.id}

    expect(response.code).to eq("200")
  end

  it "allows a user to perform a fuzzy search" do
    post :search, params: {model: 'customer', search_field: :name, search_string: "a"}

    expect(response.code).to eq("200")
  end

  it "allows a user to perform a scoped fuzzy search" do
    post :search, params: {model: 'customer', customer: {stuff: 'bob'}, search_field: :name, search_string: "a"}

    expect(response.code).to eq("200")
  end

  it 'allows the user to specify params per model on a generalized controller' do
    post :update, params: {model: 'tests', id: test.id, test: {updated_at: DateTime.now}}

    expect(JSON.parse(response.body)['test']['updated_at']).not_to eq test.updated_at

    post :update, params: {model: 'blocks', id: block.id, block: {created_at: DateTime.now}}

    expect(JSON.parse(response.body)['block']['created_at']).to eq block.created_at.as_json
  end
end
