class CreateConversations < ActiveRecord::Migration[5.0]
  def change
    create_table :conversations do |t|
      t.belongs_to :user, index: true
      t.string :current_question
      t.timestamps
    end
  end
end
