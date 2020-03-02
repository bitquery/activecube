RSpec.describe Activecube do


  before(:all) {
    ActiveRecord::MigrationContext.new(MIGRATIONS_PATH, ActiveRecord::Base.connection.schema_migration).up
  }

  let(:cube) { Test::TransfersCube }

  context "context" do
    it "executes in context" do
      cube.connected_to(database: :default) do |c|
        q = c.measure(:count).query
        expect(q.rows.count).to eq(1)
      end
    end
  end


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

    it "modified by function" do

      sql = cube.measure(cube.metrics[:amount].calculate(:maximum)).to_sql

      expect(sql).to eq("SELECT MAX(transfers_currency.value) / dictGetUInt64('currency', 'divider', toUInt64(currency_id)) AS `amount` FROM transfers_currency")
    end


    context "selectors" do

      it "uses selector for metric" do

        sql = cube.measure(
                my_count: cube.metrics[:count].
                    when(cube.selectors[:currency].eq(1))
              ).to_sql

        expect(sql).to eq("SELECT count() AS `my_count` FROM transfers_currency WHERE transfers_currency.currency_id = 1")
      end

      it "fiters all cube by selector" do

        sql = cube.measure(
            my_count: cube.metrics[:count]
        ). when(cube.selectors[:currency].eq(1)).to_sql

        expect(sql).to eq("SELECT count() AS `my_count` FROM transfers_currency WHERE transfers_currency.currency_id = 1")
      end


      it "fiters all cube by date" do

        sql = cube.measure(
            my_count: cube.metrics[:count]
        ).when(cube.selectors[:date].eq(Date.parse('2019-01-01'))).to_sql

        expect(sql).to eq("SELECT count() AS `my_count` FROM transfers_currency WHERE transfers_currency.tx_date = '2019-01-01'")
      end

      it "fiters all cube by gteq / lteq date" do

        sql = cube.measure(
            my_count: cube.metrics[:count]
        ).when(cube.selectors[:date].gt(Date.parse('2019-01-01'))).
            when(cube.selectors[:date].lteq(Date.parse('2019-02-01'))).to_sql

        expect(sql).to eq("SELECT count() AS `my_count` FROM transfers_currency WHERE transfers_currency.tx_date > '2019-01-01' AND transfers_currency.tx_date <= '2019-02-01'")
      end

      it "fiters all cube by since / till date" do

        sql = cube.measure(
            my_count: cube.metrics[:count]
        ).when(cube.selectors[:date].since(Date.parse('2019-01-01'))).
            when(cube.selectors[:date].till(Date.parse('2019-02-01'))).to_sql

        expect(sql).to eq("SELECT count() AS `my_count` FROM transfers_currency WHERE transfers_currency.tx_date >= '2019-01-01' AND transfers_currency.tx_date <= '2019-02-01'")
      end

      it "fiters all cube by between date" do

        sql = cube.measure(
            my_count: cube.metrics[:count]
        ).when(cube.selectors[:date].between(Date.parse('2019-01-01'), Date.parse('2019-02-01') )).to_sql

        expect(sql).to eq("SELECT count() AS `my_count` FROM transfers_currency WHERE transfers_currency.tx_date BETWEEN '2019-01-01' AND '2019-02-01'")
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

      it "uses multiple metrics ( sumIf test ) with separate selectors" do

        sql = cube.measure(
            count1: cube.metrics[:amount].
                when(cube.selectors[:currency].eq(1)),
            count2: cube.metrics[:amount].
                when(cube.selectors[:currency].eq(2))
        ).to_sql

        expect(sql).to eq("SELECT sumIf(transfers_currency.value,transfers_currency.currency_id = 1) / dictGetUInt64('currency', 'divider', toUInt64(currency_id)) AS `count1`, sumIf(transfers_currency.value,transfers_currency.currency_id = 2) / dictGetUInt64('currency', 'divider', toUInt64(currency_id)) AS `count2` FROM transfers_currency WHERE (transfers_currency.currency_id = 1 OR transfers_currency.currency_id = 2)")
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

      expect(sql).to eq("SELECT transfers_currency.currency_id AS `currency`, transfers_currency.currency_id, count() AS `count` FROM transfers_currency GROUP BY transfers_currency.currency_id ORDER BY `currency`")
    end

    it "slices with many metrics" do
      sql = cube.slice(currency: cube.dimensions[:currency][:symbol]).
          measure(outflow: cube.metrics[:amount].when(
              cube.selectors[:transfer_from].eq('1111')
          )).measure(inflow: cube.metrics[:amount].when(
          cube.selectors[:transfer_to].not_in('1111','2222')
      )).to_sql

      expect(sql).to eq("SELECT * FROM (SELECT dictGetString('currency', 'symbol', toUInt64(currency_id)) AS `currency`, transfers_from.currency_id, SUM(transfers_from.value) / dictGetUInt64('currency', 'divider', toUInt64(currency_id)) AS `outflow` FROM transfers_from WHERE transfers_from.transfer_from_bin = unhex('1111') GROUP BY transfers_from.currency_id ORDER BY `currency`) FULL OUTER JOIN (SELECT dictGetString('currency', 'symbol', toUInt64(currency_id)) AS `currency`, transfers_to.currency_id, SUM(transfers_to.value) / dictGetUInt64('currency', 'divider', toUInt64(currency_id)) AS `inflow` FROM transfers_to WHERE transfers_to.transfer_to_bin NOT IN (unhex('1111'), unhex('2222')) GROUP BY transfers_to.currency_id ORDER BY `currency`)  USING currency_id")
    end

    it "use function modifers ( format )" do

      sql = cube.
          measure(:count).
          slice(date: cube.dimensions[:date][:date].format('%Y-%m')).
          to_sql

      expect(sql).to eq("SELECT formatDateTime(tx_date,'%Y-%m') AS `date`, count() AS `count` FROM transfers_currency GROUP BY `date` ORDER BY `date`")
    end

    it "can slice with no measures" do

      sql = cube.
          slice(date: cube.dimensions[:date][:date].format('%Y-%m')).
          to_sql

      expect(sql).to eq("SELECT formatDateTime(tx_date,'%Y-%m') AS `date` FROM transfers_currency GROUP BY `date` ORDER BY `date`")
    end


    it "uses selector for slice" do
      sql = cube.
          measure(:count).
          slice(date: cube.dimensions[:date][:date].format('%Y-%m').
                      when( cube.selectors[:transfer_to].not_in('1111','2222') )).
          to_sql

      expect(sql).to eq("SELECT formatDateTime(tx_date,'%Y-%m') AS `date`, count() AS `count` FROM transfers_to WHERE transfers_to.transfer_to_bin NOT IN (unhex('1111'), unhex('2222')) GROUP BY `date` ORDER BY `date`")
    end

    it "use function modifers ( format ) as send" do

      sql = cube.
          measure(:count).
          slice(date: cube.dimensions[:date][:date].format('%Y-%m')).
          to_sql

      expect(sql).to eq("SELECT formatDateTime(tx_date,'%Y-%m') AS `date`, count() AS `count` FROM transfers_currency GROUP BY `date` ORDER BY `date`")
    end

    context 'fields' do
      it "use field class inline" do

        sql = cube.
            measure(:count).
            slice(date: cube.dimensions[:date][:date_inline].format('%Y-%m')).
            to_sql

        expect(sql).to eq("SELECT formatDateTime(tx_date,'%Y-%m') AS `date`, count() AS `count` FROM transfers_currency GROUP BY `date` ORDER BY `date`")
      end

      it "use field hierarchy" do

        sql = cube.
            measure(:count).
            slice(year: cube.dimensions[:date][:day][:year][:number]).
            to_sql

        expect(sql).to eq("SELECT toYear(tx_date) AS `year`, count() AS `count` FROM transfers_currency GROUP BY `year` ORDER BY `year`")
      end

      it "use field hierarchy and method" do

        sql = cube.
            measure(:count).
            slice(date: cube.dimensions[:date][:day][:date][:formatted].format('%Y-%m')).
            to_sql

        expect(sql).to eq("SELECT formatDateTime(tx_date,'%Y-%m') AS `date`, count() AS `count` FROM transfers_currency GROUP BY `date` ORDER BY `date`")
      end

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

      expect(sql).to eq("SELECT * FROM (SELECT formatDateTime(tx_date,'%Y-%m') AS `date`, SUM(transfers_to.value) / dictGetUInt64('currency', 'divider', toUInt64(currency_id)) AS `sum_in`, count() AS `count_in` FROM transfers_to WHERE transfers_to.transfer_to_bin = unhex('adr') AND transfers_to.currency_id = 1 GROUP BY `date` ORDER BY `date`) FULL OUTER JOIN (SELECT formatDateTime(tx_date,'%Y-%m') AS `date`, SUM(transfers_from.value) / dictGetUInt64('currency', 'divider', toUInt64(currency_id)) AS `sum_out`, count() AS `count_out` FROM transfers_from WHERE transfers_from.transfer_from_bin = unhex('adr') AND transfers_from.currency_id = 1 GROUP BY `date` ORDER BY `date`)  USING date")

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
          desc(:count_in).desc(:count_out).limit(5).offset(0)
          .to_sql

      expect(sql).to eq("SELECT * FROM (SELECT dictGetString('currency', 'symbol', toUInt64(currency_id)) AS `date`, transfers_to.currency_id, dictGetString('currency', 'address', toUInt64(currency_id)) AS `address`, transfers_to.currency_id, SUM(transfers_to.value) / dictGetUInt64('currency', 'divider', toUInt64(currency_id)) AS `sum_in`, count() AS `count_in` FROM transfers_to WHERE transfers_to.transfer_to_bin = unhex('adr') GROUP BY transfers_to.currency_id ORDER BY `date`, `address`) FULL OUTER JOIN (SELECT dictGetString('currency', 'symbol', toUInt64(currency_id)) AS `date`, transfers_from.currency_id, dictGetString('currency', 'address', toUInt64(currency_id)) AS `address`, transfers_from.currency_id, SUM(transfers_from.value) / dictGetUInt64('currency', 'divider', toUInt64(currency_id)) AS `sum_out`, count() AS `count_out` FROM transfers_from WHERE transfers_from.transfer_from_bin = unhex('adr') GROUP BY transfers_from.currency_id ORDER BY `date`, `address`)  USING currency_id ORDER BY `count_in` DESC, `count_out` DESC LIMIT 5 OFFSET 0")
    end

  end

  context "options" do

    it 'orders and limits' do

      sql = cube.
          measure(:count).
          slice(:currency).
          asc(:count).
          limit(5).
          offset(5).
          to_sql

      expect(sql).to eq("SELECT transfers_currency.currency_id AS `currency`, transfers_currency.currency_id, count() AS `count` FROM transfers_currency GROUP BY transfers_currency.currency_id ORDER BY `count` ASC LIMIT 5 OFFSET 5")

    end

    it 'use offset / limit aliases' do

      sql = cube.
          measure(:count).
          slice(:currency).
          asc(:count).
          limit(5).
          offset(5).
          to_sql

      expect(sql).to eq("SELECT transfers_currency.currency_id AS `currency`, transfers_currency.currency_id, count() AS `count` FROM transfers_currency GROUP BY transfers_currency.currency_id ORDER BY `count` ASC LIMIT 5 OFFSET 5")

    end

    it 'forces ordering if specified' do

      sql = cube.
          measure(:count).
          slice(year: cube.dimensions[:date][:year]).
          asc('year').
          limit(5).
          offset(5).
          to_sql

      expect(sql).to eq("SELECT toYear(tx_date) AS `year`, count() AS `count` FROM transfers_currency GROUP BY `year` ORDER BY `year` ASC LIMIT 5 OFFSET 5")

    end


    it 'ordering case with internal measure reduction' do

      sql = cube.
          measure(count: cube.metrics[:count].when(cube.selectors[:transfer_from].eq('ADR'))).
          slice(year: cube.dimensions[:date][:year]).
          asc('count').
          to_sql

      expect(sql).to eq("SELECT toYear(tx_date) AS `year`, count() AS `count` FROM transfers_from WHERE transfers_from.transfer_from_bin = unhex('adr') GROUP BY `year` ORDER BY `count` ASC")

    end

  end

end
