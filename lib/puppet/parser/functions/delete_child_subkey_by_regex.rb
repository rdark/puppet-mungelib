#
# delete_child_subkey_by_regex.rb
#
# === Author
#
# Richard Clark <rclark@fohnet.co.uk>
#
module Puppet::Parser::Functions
  newfunction(:delete_child_subkey_by_regex, :type => :rvalue, :doc => <<-EOS
This function is exactly the same as delete_child_subkey, but instead of
passing the third argument as an array of keys or single string key to delete,
the third argument is instead a single regex (or array of regexes) matching
child subkeys to delete. 

There is an optional fourth argument that will negate the regular expression
matching for child subkeys (i.e the third argument) - if true, then any child
subkeys _not_ matching the regular expressions will be deleted in the returned
data structure

In summary, the first argument should be a nested hash data structure, the
second argument should be a regular expression matching parent keys to operate
on, and the third argument should be a regular expressions matching child
subkeys to delete.

This is primarily intended for sharing hiera data structures between multiple
classes that require similar, but not identical data in order to pass back to a
define/defined type using create_resouces or equivilant.

Anything that is not a nested hash, or does not match the regular expression is
passed to the output without processing further.

See also: delete_child_subkey(), delete()

*Examples:*

1. Regular matching.

Given a variable $hiera_puppet_modules which contains a hash:

hiera_puppet_modules = {
  'puppet_module_vsftpd' => {
    'ensure'   => 'present',
    'git_repo' => 'git@git.mydomain',
    'branch'   => 'production',
    'unwanted' => 'data',
  },
  'puppet_module_this' => 'that',
  'array_of_data' => [ 'some', 'things' ],
  'my_code_repo' => {
    'ensure'   => 'present',
    'git_repo' => 'git@git.mydomain',
    'branch'   => 'production',
    'spurious' => 'data',
    'unwanted' => 'data',
  },
  'puppet_module_apache' => {
    'ensure'   => 'present',
    'git_repo' => 'git@git.mydomain',
    'branch'   => 'production',
    'spurious' => 'data',
  }
}

A second argument regular expession matching: '^puppet_module_'

And a third argument regular expression matching:  '^(git_repo|branch|spurious|data)$'

Passed to this function as: delete_child_subkey(
  $hiera_puppet_modules,
  '^puppet_module_',
  '^(git_repo|branch|spurious|data)$'
)

Would give:

hiera_puppet_modules = {
  'puppet_module_vsftpd' => {
    'ensure'   => 'present',
    'unwanted' => 'data',
  },
  'puppet_module_this' => 'that',
  'array_of_data' => [ 'some', 'things' ],
  'my_code_repo' => {
    'ensure'   => 'present',
    'git_repo' => 'git@git.mydomain',
    'branch'   => 'production',
    'spurious' => 'data',
    'unwanted' => 'data',
  },
  'puppet_module_apache' => {
    'ensure'   => 'present',
    'unwanted' => 'data',
  }
}

2. Inverse Matching.

Using the above example, but with a fourth argument that denotes inverse
matching (i.e any subkey _not_ matching the regex should be deleted):

hiera_puppet_modules = {
  'puppet_module_vsftpd' => {
    'ensure'   => 'present',
    'git_repo' => 'git@git.mydomain',
    'branch'   => 'production',
    'unwanted' => 'data',
  },
  'puppet_module_this' => 'that',
  'array_of_data' => [ 'some', 'things' ],
  'my_code_repo' => {
    'ensure'   => 'present',
    'git_repo' => 'git@git.mydomain',
    'branch'   => 'production',
    'spurious' => 'data',
    'unwanted' => 'data',
  },
  'puppet_module_apache' => {
    'ensure'   => 'present',
    'git_repo' => 'git@git.mydomain',
    'branch'   => 'production',
    'spurious' => 'data',
  }
}

A second argument regular expession matching: '^puppet_module_'

And a third argument regular expression matching:  '^(git_repo|branch|spurious|data)$'

And a fourth argument given as something evaluating to true:

Passed to this function as: delete_child_subkey(
  $hiera_puppet_modules,
  '^puppet_module_',
  '^(git_repo|branch|spurious|data)$',
  true
)

Would give:

hiera_puppet_modules = {
  'puppet_module_vsftpd' => {
    'git_repo' => 'git@git.mydomain',
    'branch'   => 'production',
  },
  'puppet_module_this' => 'that',
  'array_of_data' => [ 'some', 'things' ],
  'my_code_repo' => {
    'ensure'   => 'present',
    'git_repo' => 'git@git.mydomain',
    'branch'   => 'production',
    'spurious' => 'data',
    'unwanted' => 'data',
  },
  'puppet_module_apache' => {
    'git_repo' => 'git@git.mydomain',
    'branch'   => 'production',
    'spurious' => 'data',
  }
}

EOS
  ) do |arguments|

    if (arguments.size < 3) or (arguments.size > 4) then
      raise(ArgumentError, "delete_child_subkey_by_regex(): Wrong number of arguments "+
        "given #{arguments.size} for 3 or 4.")
    end

    src_hash     = arguments[0]
    parent_regex = arguments[1]
    child_regex  = arguments[2]
    inverse      = arguments[3] ? true : false

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
    # destination hash to store wanted data structure
    dest_hash = Hash.new
    
    # get second level keys
    src_hash.keys.each do |parent|
      # if it's not a hash, just insert it and move on
      unless src_hash[parent].is_a?(Hash)
        dest_hash[parent] = src_hash[parent]
        next
      end
      # create empty hash nested at parent in destination hash
      dest_hash[parent] = Hash.new
      src_hash[parent].keys.each do |child|
        parent_regex.each do |r|
          if parent !~ /#{r}/
            # if we don't match the parent_regex, insert the values and move on
            dest_hash[parent][child] = src_hash[parent][child]
            break
          else
            child_regex_matched = false
            child_regex.each do |c|
              if c.match(child)
                child_regex_matched = true
                break
              end
            end
            # if inverse, then insert the keys we matched
            # if 'regular' then insert the keys we didn't match
            if inverse 
              dest_hash[parent][child] = src_hash[parent][child] if child_regex_matched
              break
            else
              dest_hash[parent][child] = src_hash[parent][child] unless child_regex_matched
              break
            end
          end
        end
      end
    end
    dest_hash
  end
end

# vim: set ts=2 sw=2 et :
