require 'test_helper'

class MigratorTest < ActiveSupport::TestCase
  teardown do
    Dir.glob(Rails.root.join('db/migrate/*.rb')).each do |f|
      FileUtils.rm f unless File.basename(f).in? %w(20120428022519_create_authors.rb 20120428022535_create_books.rb)
    end
  end

  sub_test_case '.status' do
    test 'when all migrations are up' do
      assert_equal [{:status => 'up', :version => '20120428022519', :name => 'create_authors', :filename => '20120428022519_create_authors.rb'}, {:status => 'up', :version => '20120428022535', :name => 'create_books', :filename => '20120428022535_create_books.rb'}], Erd::Migrator.status
    end

    test 'when one is undone' do
      FileUtils.touch Rails.root.join('db/migrate/20999999999999_create_foobars.rb')

      assert_equal [{:status => 'up', :version => '20120428022519', :name => 'create_authors', :filename => '20120428022519_create_authors.rb'}, {:status => 'up', :version => '20120428022535', :name => 'create_books', :filename => '20120428022535_create_books.rb'}, {:status => 'down', :version => '20999999999999', :name => 'create_foobars', :filename => '20999999999999_create_foobars.rb'}], Erd::Migrator.status
    end
  end

  sub_test_case '.run_migrations' do
    setup do
      FileUtils.touch Rails.root.join('db/migrate/20999999999999_create_foobars.rb')
      mock(ActiveRecord::Migrator).run(:up, 'db/migrate', 20999999999999)
      mock(ActiveRecord::SchemaDumper).dump(ActiveRecord::Base.connection, anything)
    end
    test 'runs migration by version number' do
      Erd::Migrator.run_migrations(:up => ['20999999999999'])
    end
    test 'runs migration by migration filename' do
      Erd::Migrator.run_migrations(:up => [Rails.root.join('db/migrate/20999999999999_create_foobars.rb')])
    end
  end
end

class GenaratorRunnerTest < ActiveSupport::TestCase
  setup do
    stub.proxy(Time).now {|t| stub(t).utc { Time.new 2012, 5, 12, 13, 26 } }
  end
  teardown do
    Dir.glob(Rails.root.join('db/migrate/*.rb')).each do |f|
      FileUtils.rm f unless File.basename(f).in? %w(20120428022519_create_authors.rb 20120428022535_create_books.rb)
    end
  end

  test '.execute_generate_migration' do
    assert_includes 'db/migrate/20120512132600_create_foobars.rb', Erd::GenaratorRunner.execute_generate_migration('create_foobars')
  end
end
