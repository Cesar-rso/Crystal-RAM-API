class CreateTravels < Jennifer::Migration::Base
    def up
      create_table :travels do |t|
        t.string :stops, {:null => false}

      end
    end
  
    def down
      drop_table :travels if table_exists? :travels
    end
  end
  
  