class Migration::MartenDBSessionStore::V202204052043241 < Marten::Migration
  def plan
    create_table :marten_db_session_store_entry do
      column :key, :string, max_size: 40, primary_key: true
      column :data, :text
      column :expires, :date_time, index: true
    end
  end
end
