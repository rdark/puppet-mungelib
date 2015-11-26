#
# keys_where_child_subkey_match_by_regex.rb
#
# === Author
#
# Richard Clark <rclark@fohnet.co.uk>
#
module Puppet::Parser::Functions
  newfunction(:keys_where_child_subkey_match_by_regex, :type => :rvalue, :doc => <<-EOS
This function follows a similar logic to get_child_subkey_value_by_regex, but
instead of returning an array of values of a given subkey, it returns an array
of parent keys where the keys within that hash match the second regex.

In summary, the first argument should be a nested hash data structure, the
second argument should be a regular expression matching parent keys to operate
on, and the third argument should be a regular expressions matching child
subkey values to match.

This is primarily intended for sharing hiera data structures between multiple
classes that require similar, but not identical data in order to pass back to a
define/defined type using create_resouces or equivilant.

Anything that is not a nested hash, or does not match the regular expression is
passed to the output without processing further.

See also: get_child_subkey_value_by_regex()

*Examples:*

1. Regular matching.

A given variable $hiera_puppet_modules which contains a hash:

hiera_puppet_modules = {
  'puppet_module_vsftpd' => {
    'ensure'   => 'present',
    'git_repo' => 'git@git.mydomain/vsftpd',
    'branch'   => 'production',
    'unwanted' => 'data',
  },
  'puppet_module_sudo' => {
    'ensure'   => 'present',
    'branch'   => 'development',
    'unwanted' => 'data',
  },
  'puppet_module_this' => 'that',
  'array_of_data' => [ 'some', 'things' ],
  'my_code_repo' => {
    'ensure'   => 'present',
    'git_repo' => 'git@git.mydomain/my_code_repo',
    'branch'   => 'production',
    'spurious' => 'data',
    'unwanted' => 'data',
  },
  'puppet_module_apache' => {
    'ensure'   => 'present',
    'git_repo' => 'git@git.mydomain/apache',
    'branch'   => 'production',
    'spurious' => 'data',
  }
}

A second argument regular expession matching: '^puppet_module_'

And a third argument regular expression matching:  '^git_repo$'

Passed to this function as: get_child_subkey_value_by_regex(
  $hiera_puppet_modules,
  '^puppet_module_',
  '^git_repo$'
)

Would give:

['puppet_module_vsftpd', 'puppet_module_apache']

EOS
  ) do |arguments|

    if arguments.size != 3 then
      raise(ArgumentError, "keys_where_child_subkey_match_by_regex(): Wrong number of arguments "+
        "given #{arguments.size} for 3")
    end

    src_hash     = arguments[0]
    parent_regex = arguments[1]
    child_regex  = arguments[2]

    unless src_hash.is_a?(Hash)
      raise ArgumentError, "First argument must be a hash"
    end
    unless parent_regex.is_a?(String) or parent_regex.is_a?(Array)
      raise ArgumentError, "Second argument must be a single or array of string-format regular expressions"
    end
    unless child_regex.is_a?(String) or child_regex.is_a?(Array)
      raise ArgumentError, "Third argument must be a single or array of string-format regular expressions"
    end

    # transform parent_regex + child_regex into arrays if they are not already
    parent_regex = [ parent_regex ] if parent_regex.is_a?(String)
    child_regex = [ child_regex ] if child_regex.is_a?(String)
    # destination array to store wanted data structure
    dest_array = Array.new
    
    # get second level keys
    src_hash.keys.each do |parent|
      # if it's not a hash, just ignore it and move on
      unless src_hash[parent].is_a?(Hash)
        next
      end
      # catch parent matches
      catch :parent_matched do
        src_hash[parent].keys.each do |child|
          parent_regex.each do |r|
            if parent.match(r)
              child_regex.each do |c|
                if c.match(child)
                  # matched both parent and child - insert the value
                  dest_array << parent
                  # break out of nested blocks so we don't get duplicates
                  throw :parent_matched
                end
              end
            end
          end
        end
      end
    end
    dest_array
  end
end

# vim: set ts=2 sw=2 et :
