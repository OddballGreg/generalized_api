# frozen_string_literal: true

class CreateTests < ActiveRecord::Migration[5.1]
  def change
    create_table :tests do |t|
      t.string :name
      t.string :stuff

      t.timestamps
    end

    create_table :customers do |t|
      t.string :name
      t.string :stuff

      t.timestamps
    end
  end
end
