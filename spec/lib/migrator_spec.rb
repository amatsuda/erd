require 'spec_helper'

describe Erd::Migrator do
  subject { Erd::Migrator }
  after do
    Dir.glob(Rails.root.join('db/migrate/*.rb')).each do |f|
      FileUtils.rm f unless File.basename(f).in? %w(20120428022519_create_authors.rb 20120428022535_create_books.rb)
    end
  end
  describe '.status' do
    context 'when all migrations are up' do
      its(:status) { should == [{:status => 'up', :version => '20120428022519', :name => 'create_authors'}, {:status => 'up', :version => '20120428022535', :name => 'create_books'}] }
    end

    context 'when one is undone' do
      before do
        FileUtils.touch Rails.root.join('db/migrate/20999999999999_create_foobars.rb')
      end
      its(:status) { should == [{:status => 'up', :version => '20120428022519', :name => 'create_authors'}, {:status => 'up', :version => '20120428022535', :name => 'create_books'}, {:status => 'down', :version => '20999999999999', :name => 'create_foobars'}] }
    end
  end

  describe '.run_migrations' do
    before do
      FileUtils.touch Rails.root.join('db/migrate/20999999999999_create_foobars.rb')
      mock(ActiveRecord::Migrator).run(:up, 'db/migrate', 20999999999999)
      mock(ActiveRecord::SchemaDumper).dump(ActiveRecord::Base.connection, anything)
    end
    specify do
      subject.run_migrations(:up => ['20999999999999'])
    end
  end

  describe '.execute_generate_migration' do
    before do
      stub.proxy(Time).now {|t| stub(t).utc { Time.new 2012, 5, 12, 13, 26 } }
      Erd::Migrator.execute_generate_migration 'create_foobars'
    end
    specify do
      File.should be_exists Rails.root.join('db/migrate', '20120512132600_create_foobars.rb')
    end
  end
end
