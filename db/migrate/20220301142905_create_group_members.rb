class CreateGroupMembers < ActiveRecord::Migration[6.1]
  def change
    create_table :group_members, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :account_id, null: false
      t.uuid :group_id, null: false
      t.string :member_type, null: false
      t.uuid :member_id, null: false

      t.timestamps

      t.index %i[account_id]
      t.index %i[group_id]

      # NOTE(ezekg) Eventually, I'd like to support multiple groups per-member,
      #             but for now we're going to stick to 1 group to member.
      t.index %i[member_type member_id], unique: true
    end
  end
end
