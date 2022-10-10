##
# print_table prints a table of pivot table for roles and permissions, used in the docs.
#
# See: https://stackoverflow.com/a/42984778/3247081
def print_table(row_labels_title, row_labels, col_labels, values, gap_size = 3)
  col_width = [values.flatten.max.size, col_labels.max_by(&:size).size].max + gap_size
  row_labels_width = [row_labels_title.size, row_labels.max_by(&:size).size].max + gap_size
  horiz_line = '-'*(row_labels_width + col_labels.size * col_width + col_labels.size)
  puts horiz_line
  print row_labels_title.ljust(row_labels_width)
  col_labels.each do |s|
    print "|#{s.center(col_width)}"
  end
  puts
  row_labels.each do |row_label|
    print row_label.ljust(row_labels_width)
    vals = values.shift
    col_labels.each do |col_label|
      print "|#{vals.shift.to_s.center(col_width)}"
    end
    puts
  end
  puts horiz_line
end

roles = {
  admin: Permission::ADMIN_PERMISSIONS,
  product: Permission::PRODUCT_PERMISSIONS,
  license: Permission::LICENSE_PERMISSIONS,
  user: Permission::USER_PERMISSIONS,
}

matrix = roles.values
              .map { |perms| Permission::ALL_PERMISSIONS.map { perms.include?(_1) ? 1 : 0 } }
              .transpose

print_table(
  'Roles and Permissions',
  Permission::ALL_PERMISSIONS,
  roles.keys.map(&:to_s),
  matrix,
  1,
)
