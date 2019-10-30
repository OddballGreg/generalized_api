# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlocksController, type: :controller do
  # let (:test) {FactoryBot.create(:test)}
  let (:block) { Block.create(name: 'gawreg') }

  it 'allows a user to request an index without pagination params with a block applied to the index' do
    get :index

    expect(JSON.parse(response.body)['blocks'].first['name']).to eq 'BLOCK'
    expect(response.code).to eq('200')
  end

  it 'allows a user to query without a paramater' do
    post :index

    expect(response.code).to eq('200')
  end

  it 'allows a user to query with pagination parameters' do
    post :index, params: { page: 1, per_page: 10 }

    expect(response.code).to eq('200')
  end

  it 'allows a user to query with an order parameter' do
    post :index, params: { order_by: 'name desc' }

    expect(response.code).to eq('200')
  end

  it 'allows a user to query by a permitted paramater' do
    post :index, params: { blocks: { name: 'block' } }

    expect(response.code).to eq('200')
  end

  it 'allows a user to show an existing record' do
    get :show, params: { id: block.id }

    expect(response.code).to eq('200')
  end

  context 'allows a user to create a record' do
    it 'returns success if the user was created' do
      post :create, params: { block: { name: 'gawreg' } }

      expect(response.code).to eq('200')
    end
  end

  context 'allows a user to update a record' do
    it 'returns success if the user was updated' do
      patch :update, params: { id: block.id, block: { name: 'new_name' } }

      expect(response.code).to eq('200')
      expect(block.reload.name).to eq('new_name')
    end
  end

  it 'allows a user to destroy a record' do
    delete :destroy, params: { id: block.id }

    expect(response.code).to eq('200')
  end

  it 'allows a user to perform a fuzzy search' do
    post :index, params: { search: { name: 'a' } }

    expect(response.code).to eq('200')
  end
end
