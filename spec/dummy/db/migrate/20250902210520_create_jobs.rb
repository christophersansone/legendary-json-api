class CreateJobs < ActiveRecord::Migration[7.2]
  def change
    create_table :jobs do |t|
      t.integer :user_id
      t.string :title

      t.timestamps
    end
  end
end
