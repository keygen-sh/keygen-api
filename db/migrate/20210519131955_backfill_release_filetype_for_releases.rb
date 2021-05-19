class BackfillReleaseFiletypeForReleases < ActiveRecord::Migration[6.1]
  def change
    Release.find_each do |release|
      fileext  = File.extname(release.key).strip.downcase.delete('.')
      filetype = ReleaseFiletype.find_or_create_by!(key: fileext, account: release.account)

      release.update! filetype: filetype
    end
  end
end
