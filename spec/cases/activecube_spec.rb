RSpec.describe Activecube do


  before(:all) {
    ActiveRecord::MigrationContext.new(MIGRATIONS_PATH, ActiveRecord::Base.connection.schema_migration).up
  }

  let(:cube) { Test::TransfersCube }

  context "metrics" do

    it "counts record in cube" do

      sql = cube.measure(:count).to_sql

      expect(sql).to eq("SELECT count() AS `count` FROM transfers_currency")
    end

    it "uses alias" do

      sql = cube.measure(
              'my.count' => cube.metrics[:count]
            ).to_sql

      expect(sql).to eq("SELECT count() AS `my.count` FROM transfers_currency")
    end

    it "accepts alias as symbol" do

      sql = cube.measure(
              my_count: cube.metrics[:count]
            ).to_sql

      expect(sql).to eq("SELECT count() AS `my_count` FROM transfers_currency")
    end

    context "selectors" do

      it "uses selector for metric" do

        sql = cube.measure(
                my_count: cube.metrics[:count].
                    when(cube.selectors[:currency].eq(1))
              ).to_sql

        expect(sql).to eq("SELECT count() AS `my_count` FROM transfers_currency WHERE transfers_currency.currency_id = 1")
      end

      it "uses multiple selector for metric" do

        sql = cube.measure(
            my_count: cube.metrics[:count].
                when(cube.selectors[:currency].eq(1)).
                when(cube.selectors[:transfer_from].eq('FROM'))
        ).to_sql

        expect(sql).to eq("SELECT count() AS `my_count` FROM transfers_from WHERE transfers_from.currency_id = 1 AND transfers_from.transfer_from_bin = unhex('from')")
      end

      it "uses multiple metrics with separate selectors" do

        sql = cube.measure(
            count1: cube.metrics[:count].
                when(cube.selectors[:currency].eq(1)),
            count2: cube.metrics[:count].
                when(cube.selectors[:currency].eq(2))
        ).to_sql

        expect(sql).to eq("SELECT countIf(transfers_currency.currency_id = 1) AS `count1`, countIf(transfers_currency.currency_id = 2) AS `count2` FROM transfers_currency WHERE (transfers_currency.currency_id = 1 OR transfers_currency.currency_id = 2)")
      end

      it "uses multiple metrics with separate selectors" do

        sql = cube.measure(
            count1: cube.metrics[:count].
                when(cube.selectors[:currency].eq(1)),
            count2: cube.metrics[:count].
                when(cube.selectors[:currency].eq(2))
        ).to_sql

        expect(sql).to eq("SELECT countIf(transfers_currency.currency_id = 1) AS `count1`, countIf(transfers_currency.currency_id = 2) AS `count2` FROM transfers_currency WHERE (transfers_currency.currency_id = 1 OR transfers_currency.currency_id = 2)")
      end

      it "chains selectors" do

        sql = cube.measure(
                count1: cube.metrics[:count].
                    when(cube.selectors[:currency].eq(1))
              ).measure(
                count2: cube.metrics[:count].
                    when(cube.selectors[:currency].eq(2))
              ).to_sql

        expect(sql).to eq("SELECT countIf(transfers_currency.currency_id = 1) AS `count1`, countIf(transfers_currency.currency_id = 2) AS `count2` FROM transfers_currency WHERE (transfers_currency.currency_id = 1 OR transfers_currency.currency_id = 2)")
      end


    end

  end

  context "dimensions" do

    it "slices" do

      sql = cube.
            measure(:count).
            slice(:currency).
          to_sql

      expect(sql).to eq("SELECT transfers_currency.currency_id AS `currency`, transfers_currency.currency_id, count() AS `count` FROM transfers_currency GROUP BY transfers_currency.currency_id")
    end

    it "slices with many metrics" do
      sql = cube.slice(currency: cube.dimensions[:currency][:symbol]).
          measure(outflow: cube.metrics[:amount].when(
              cube.selectors[:transfer_from].eq('1111')
          )).measure(inflow: cube.metrics[:amount].when(
          cube.selectors[:transfer_to].not_in('1111','2222')
      )).to_sql

      expect(sql).to eq("SELECT * FROM (SELECT dictGetString('currency', 'symbol', toUInt64(currency_id)) AS `currency`, transfers_from.currency_id, SUM(transfers_from.value) / dictGetUInt64('currency', 'divider', toUInt64(currency_id)) AS `outflow` FROM transfers_from WHERE transfers_from.transfer_from_bin = unhex('1111') GROUP BY transfers_from.currency_id) FULL OUTER JOIN (SELECT dictGetString('currency', 'symbol', toUInt64(currency_id)) AS `currency`, transfers_to.currency_id, SUM(transfers_to.value) / dictGetUInt64('currency', 'divider', toUInt64(currency_id)) AS `inflow` FROM transfers_to WHERE transfers_to.transfer_to_bin NOT IN (unhex('1111'), unhex('2222')) GROUP BY transfers_to.currency_id)  USING currency_id")
    end

    it "use function modifers ( format )" do

      sql = cube.
          measure(:count).
          slice(date: cube.dimensions[:date][:date].format('%Y-%m')).
          to_sql

      expect(sql).to eq("SELECT formatDateTime(tx_date,'%Y-%m') AS `date`, count() AS `count` FROM transfers_currency GROUP BY `date` ORDER BY `date`")
    end

  end

  context "examples" do

    it 'slices by months transfers' do

      sql = cube.
          slice(date: cube.dimensions[:date][:date].format('%Y-%m')).

          measure(sum_in: cube.metrics[:amount].when(
              cube.selectors[:transfer_to].eq('ADR'),
              cube.selectors[:currency].eq(1)
          )).

          measure(sum_out: cube.metrics[:amount].when(
              cube.selectors[:transfer_from].eq('ADR'),
              cube.selectors[:currency].eq(1)
          )).

          measure(count_in: cube.metrics[:count].when(
              cube.selectors[:transfer_to].eq('ADR'),
              cube.selectors[:currency].eq(1)
          )).

          measure(count_out: cube.metrics[:count].when(
              cube.selectors[:transfer_from].eq('ADR'),
              cube.selectors[:currency].eq(1)
          )).to_sql

      expect(sql).to eq("SELECT * FROM (SELECT formatDateTime(tx_date,'%Y-%m') AS `date`, SUM(transfers_to.value) / dictGetUInt64('currency', 'divider', toUInt64(1)) AS `sum_in`, count() AS `count_in` FROM transfers_to WHERE transfers_to.transfer_to_bin = unhex('adr') AND transfers_to.currency_id = 1 GROUP BY `date` ORDER BY `date`) FULL OUTER JOIN (SELECT formatDateTime(tx_date,'%Y-%m') AS `date`, SUM(transfers_from.value) / dictGetUInt64('currency', 'divider', toUInt64(1)) AS `sum_out`, count() AS `count_out` FROM transfers_from WHERE transfers_from.transfer_from_bin = unhex('adr') AND transfers_from.currency_id = 1 GROUP BY `date` ORDER BY `date`)  USING date")

    end

    it "slices by currencies" do


      sql = cube.
          slice(
              date: cube.dimensions[:currency][:symbol]
          ).
          slice(
              address: cube.dimensions[:currency][:address]
          ).
          measure(sum_in: cube.metrics[:amount].when(
              cube.selectors[:transfer_to].eq('ADR')
          )).

          measure(sum_out: cube.metrics[:amount].when(
              cube.selectors[:transfer_from].eq('ADR')
          )).

          measure(count_in: cube.metrics[:count].when(
              cube.selectors[:transfer_to].eq('ADR')
          )).

          measure(count_out: cube.metrics[:count].when(
              cube.selectors[:transfer_from].eq('ADR')
          )).
          desc(:count_in).desc(:count_out).take(5).skip(0)
          .to_sql

      expect(sql).to eq("SELECT * FROM (SELECT dictGetString('currency', 'symbol', toUInt64(currency_id)) AS `date`, transfers_to.currency_id, dictGetString('currency', 'address', toUInt64(currency_id)) AS `address`, transfers_to.currency_id, SUM(transfers_to.value) / dictGetUInt64('currency', 'divider', toUInt64(currency_id)) AS `sum_in`, count() AS `count_in` FROM transfers_to WHERE transfers_to.transfer_to_bin = unhex('adr') GROUP BY transfers_to.currency_id) FULL OUTER JOIN (SELECT dictGetString('currency', 'symbol', toUInt64(currency_id)) AS `date`, transfers_from.currency_id, dictGetString('currency', 'address', toUInt64(currency_id)) AS `address`, transfers_from.currency_id, SUM(transfers_from.value) / dictGetUInt64('currency', 'divider', toUInt64(currency_id)) AS `sum_out`, count() AS `count_out` FROM transfers_from WHERE transfers_from.transfer_from_bin = unhex('adr') GROUP BY transfers_from.currency_id)  USING currency_id ORDER BY count_in DESC, count_out DESC LIMIT 5 OFFSET 0")
    end

  end

  context "options" do

    it 'orders and limits' do

      sql = cube.
          measure(:count).
          slice(:currency).
          asc(:count).
          take(5).
          skip(5).
          to_sql

      expect(sql).to eq("SELECT transfers_currency.currency_id AS `currency`, transfers_currency.currency_id, count() AS `count` FROM transfers_currency GROUP BY transfers_currency.currency_id ORDER BY count ASC LIMIT 5 OFFSET 5")

    end

  end

end
