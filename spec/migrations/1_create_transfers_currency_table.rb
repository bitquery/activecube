# frozen_string_literal: true

class CreateTransfersCurrencyTable < ActiveRecord::Migration[5.0]
  def up
    create_table :transfers_currency do |t|

      t.date :tx_date
      t.datetime :tx_time

      t.string :transfer_from_bin
      t.string :transfer_to_bin
      t.string :tx_hash_bin

      t.integer :currency_id

      t.float :value

    end

    Test::TransfersCurrency.reset_column_information

  end

end

