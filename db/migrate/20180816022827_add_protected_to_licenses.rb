class AddProtectedToLicenses < ActiveRecord::Migration[5.0]
  def change
    add_column :licenses, :protected, :boolean

    # Update all licenses to inherit their policy's protected attribute
    License.connection.update('
      UPDATE licenses AS l
        SET protected = p.protected
      FROM policies AS p
        WHERE l.policy_id = p.id
    ')
  end
end
