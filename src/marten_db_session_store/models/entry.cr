module MartenDBSessionStore
  class Entry < Marten::Model
    field :key, :string, max_size: 40, primary_key: true
    field :data, :text
    field :expires, :date_time, index: true
  end
end
