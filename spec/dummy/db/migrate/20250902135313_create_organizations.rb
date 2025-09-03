class CreateOrganizations < ActiveRecord::Migration[7.2]
  def change
    create_table :organizations do |t|
      t.string :name

      t.timestamps
    end

    add_column :users, :organization_id, :integer
  end
end
