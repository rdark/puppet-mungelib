#
# insert_child_subkey_if_missing.rb
#
# === Author
#
# Richard Clark <rclark@fohnet.co.uk>
#
module Puppet::Parser::Functions
  newfunction(:insert_child_subkey_if_missing, :type => :rvalue, :doc => <<-EOS
Given a hash containing nested hashes, a single or array of regular
expressions, and a single-depth hash, this function will insert the keys+values
of that third hash into each first-depth nested hash that matches any of the
given regular expressions, but _only_ if that key does not exist.

This is primarily intended for sharing hiera data structures between multiple
classes that require similar, but not identical data in order to pass back to a
define/defined type using create_resouces or equivilant.

Anything that is not a nested hash, or does not match the regular expression is
passed to the output without processing further.

See also: insert_child_subkey()

*Examples:*

A given variable $hiera_puppet_modules which contains a hash:

hiera_puppet_modules = {
  'puppet_module_vsftpd' => {
    'ensure'   => 'present',
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
  }
}

A regular expession matching: '^puppet_module_'

And a third hash matching matching: 

$insert_hash = {
  'git_repo' => 'git@git.theirdomain',
  'branch'   => 'master',
}

Passed to this function as: insert_child_subkey(
  $hiera_puppet_modules,
  '^puppet_module_',
  $insert_hash
)

Would give:

hiera_puppet_modules = {
  'puppet_module_vsftpd' => {
    'ensure'   => 'present',
    'git_repo' => 'git@git.theirdomain',
    'branch'   => 'master',
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
    'git_repo' => 'git@git.theirdomain',
    'branch'   => 'master',
  }
}

EOS
  ) do |arguments|

    if (arguments.size != 3) then
      raise(Puppet::ParseError, "insert_child_subkey_if_missing(): Wrong number of arguments "+
        "given #{arguments.size} for 3.")
    end

    src_hash    = arguments[0]
    regex       = arguments[1]
    insert_hash = arguments[2]

    unless src_hash.is_a?(Hash)
      raise Puppet::ParseError, "First argument must be a hash"
    end
    unless regex.is_a?(String) or regex.is_a?(Array)
      raise Puppet::ParseError, "Second argument must be a single or array of string-format regex"
    end
    unless insert_hash.is_a?(Hash)
      raise Puppet::ParseError, "Third argument must be a hash"
    end

    # transform regex into array if not already
    regex = [ regex ] if regex.is_a?(String)
    # destination hash to store wanted data structure
    dest_hash = Hash.new

    # get second level keys
    src_hash.keys.each do |parent|
      # if anything is not a nested hash just insert it and move on
      unless src_hash[parent].is_a?(Hash)
        dest_hash[parent] = src_hash[parent]
        next
      end
      # create empty hash nested at parent in destination hash
      dest_hash[parent] = Hash.new
      existing_children = false
      regex_matched = false
      regex.each do |r|
        if parent =~ /#{r}/
          regex_matched = true
          # add any existing children, unless we have already
          unless existing_children
            src_hash[parent].keys.each do |child|
              # insert the key into the hash regardless of whether or not
              # insert_hash has the key
              dest_hash[parent][child] = src_hash[parent][child]
            end
            existing_children = true
          end
          # otherwise we have a match, so walk through each of our
          # insert_hash keys and insert them at this depth
          insert_hash.keys.each do |insert|
            unless src_hash[parent].key?(insert)
              dest_hash[parent][insert] = insert_hash[insert]
            end
          end
          # break out as we've matched at least one regex
          break
        end
      end
      # if no regex matches then we need to add the parent hash in entirety
      dest_hash[parent] = src_hash[parent] unless regex_matched
    end
    dest_hash
  end
end

# vim: set ts=2 sw=2 et :
