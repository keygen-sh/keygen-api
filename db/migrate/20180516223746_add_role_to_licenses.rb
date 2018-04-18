class AddRoleToLicenses < ActiveRecord::Migration[5.0]
  def change
    License.find_each do |license|
      license.update role: Role.new(name: :license)
    end
  end
end
