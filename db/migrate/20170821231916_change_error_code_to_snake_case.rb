class ChangeErrorCodeToSnakeCase < ActiveRecord::Migration[5.1]
  def do_sql(*args)
    expression = ActiveRecord::Base.send :sanitize_sql, args
    ActiveRecord::Base.connection.exec_query(expression)
  end

  def rename_json_property(table, field, old_property_name, new_property_name)
    rows = ActiveRecord::Base.connection.exec_query(
      "SELECT uuid, #{field} FROM #{table} WHERE #{field} ? '#{old_property_name}'"
    )

    parser = rows.column_types[field]
    rows.each do |row|
      json_data = parser.deserialize(row['source_metadata'])
      json_data[new_property_name] = json_data[old_property_name]
      json_data.delete(old_property_name)
      do_sql(
        "UPDATE #{table} SET #{field} = ? WHERE uuid = ?",
        parser.serialize(json_data),
        row['uuid']
      )
    end
  end

  def up
    rename_json_property(
      'versions',
      'source_metadata',
      'errorCode',
      'error_code'
    )
  end

  def down
    rename_json_property(
      'versions',
      'source_metadata',
      'error_code',
      'errorCode'
    )
  end
end
