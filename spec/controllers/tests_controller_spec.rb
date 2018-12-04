# frozen_string_literal: true

require "rails_helper"

RSpec.describe TestsController, type: :controller do
  # let (:test) {FactoryBot.create(:test)}
  let (:test) { Test.create(name: "gawreg", stuff: "aerwgh") }

  it "allows a user to request an index without pagination params" do
    get :index

    expect(response.code).to eq("200")
  end

  it "allows a user to query without a paramater" do
    post :index

    expect(response.code).to eq("200")
  end

  it "allows a user to query with pagination parameters" do
    post :index, params: {page: 1, per_page: 10}

    expect(response.code).to eq("200")
  end

  it "allows a user to query with an order parameter" do
    post :index, params: {order_by: :name}

    expect(response.code).to eq("200")
  end

  it "allows a user to query by a permitted paramater" do
    post :index, params: {tests: {name: "test"}}

    expect(response.code).to eq("200")
  end

  it "allows a user to show an existing record record" do
    get :show, params: {id: test.id}

    expect(response.code).to eq("200")
  end

  context "allows a user to create a record" do
    it "returns success if the user was created" do
      post :create, params: {test: {name: "gawreg", stuff: "aerwgh"}}

      expect(response.code).to eq("200")
    end

    it "it returns a 422 if the record did not meet validation" do
      post :create, params: {test: {stuff: "aerwgh"}}

      expect(response.code).to eq("422")
    end
  end

  context "allows a user to update a record" do
    it "returns success if the user was updated" do
      patch :update, params: {id: test.id, test: {name: "new_name", stuff: "aerwgh"}}

      expect(response.code).to eq("200")
      expect(test.reload.name).to eq("new_name")
    end

    it "it returns a 422 if the record did not meet validation" do
      post :update, params: {id: test.id, test: {name: nil}}

      expect(response.code).to eq("422")
    end
  end

  it "allows a user to destroy a record" do
    delete :destroy, params: {id: test.id}

    expect(response.code).to eq("200")
  end

  it "allows a user to perform a fuzzy search" do
    post :search, params: {search_field: :name, search_string: "a"}

    expect(response.code).to eq("200")
  end
end
