#
# downcase_child_subkey_by_regex.rb
#
# === Author
#
# Richard Clark <rclark@fohnet.co.uk>
#
module Puppet::Parser::Functions
  newfunction(:downcase_child_subkey_by_regex, :type => :rvalue, :doc => <<-EOS
This function is similar to delete_child_subkey_by_regex, but instead of
deleting matches or non-matches, it will downcase the keys within scope.

The first argument is a nested hash structure, the second argument is a regex
(or array of regexes) matching parent keys to operate on, and the third
argument is a regex (or array of regexes) matching child subkeys to downcase. 

There is an optional fourth argument that will negate the regular expression
matching for child subkeys (i.e the third argument) - if true, then any child
subkeys _not_ matching the regular expressions will be downcased in the returned
data structure

This is primarily intended for sharing hiera data structures between multiple
classes that require similar, but not identical data in order to pass back to a
define/defined type using create_resources or equivilant.

Anything that is not a nested hash, or does not match the regular expression is
passed to the output without processing further.

See also: delete_child_subkey_by_regex(), downcase()

*Examples:*

1. Regular matching.

A given variable $tomcat_connectors which contains a hash:

tomcat_connectors = {
  'vhost_1' => {
    'ensure'            => 'present',
    'port'              => '443',
    'SSLEnable'         => true,
    'maxHttpHeaderSize' => 8192,
  },
  'vhost_2' => {
    'ensure'            => 'present',
    'port'              => '80',
    'SSLEnable'         => false,
    'maxHttpHeaderSize' => 8192,
  },
  'array_of_data' => [ 'some', 'things' ],
}

A second argument regular expession matching: '^vhost_[0-9]+$'

And a third argument regular expression matching:  '^SSLEnable$'

Passed to this function as: downcase_child_subkey(
  $tomcat_connectors,
  '^vhost_[0-9]+$',
  '^SSLEnable$'
)

Would give:

tomcat_connectors = {
  'vhost_1' => {
    'ensure'            => 'present',
    'port'              => '443',
    'sslenable'         => true,
    'maxHttpHeaderSize' => 8192,
  },
  'vhost_2' => {
    'ensure'            => 'present',
    'port'              => '80',
    'sslenable'         => false,
    'maxHttpHeaderSize' => 8192,
  },
  'array_of_data' => [ 'some', 'things' ],
}

2. Inverse Matching.

Using the above example, but with a fourth argument that denotes inverse
matching (i.e any subkey _not_ matching the regex should be deleted):

tomcat_connectors = {
  'vhost_1' => {
    'ensure'            => 'present',
    'port'              => '443',
    'SSLEnable'         => true,
    'maxHttpHeaderSize' => 8192,
  },
  'vhost_2' => {
    'ensure'            => 'present',
    'port'              => '80',
    'SSLEnable'         => false,
    'maxHttpHeaderSize' => 8192,
  },
  'array_of_data' => [ 'some', 'things' ],
}

A second argument regular expession matching: '^vhost_[0-9]+$'

And a third argument regular expression matching:  '^SSLEnable$'

And a fourth argument given as something evaluating to true:

Passed to this function as: downcase_child_subkey(
  $tomcat_connectors,
  '^vhost_[0-9]+$',
  '^SSLEnable$',
  true
)

Would give:

tomcat_connectors = {
  'vhost_1' => {
    'ensure'            => 'present',
    'port'              => '443',
    'SSLEnable'         => true,
    'maxhttpheadersize' => 8192,
  },
  'vhost_2' => {
    'ensure'            => 'present',
    'port'              => '80',
    'SSLEnable'         => false,
    'maxhttpheadersize' => 8192,
  },
  'array_of_data' => [ 'some', 'things' ],
}

EOS
  ) do |arguments|

    if (arguments.size < 3) or (arguments.size > 4) then
      raise(ArgumentError, "downcase_child_subkey_by_regex(): Wrong number of arguments "+
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
            # if inverse, then downcase non-matches
            if inverse
              unless child_regex_matched
                # no match, insert + downcase
                dest_hash[parent]["#{child.downcase}"] = src_hash[parent][child]
              else
                # match - insert as-is
                dest_hash[parent][child] = src_hash[parent][child]
              end
            else
              # if 'regular' then downcase the keys we did match
              if child_regex_matched
                # match - downcase
                dest_hash[parent]["#{child.downcase}"] = src_hash[parent][child]
              else
                # no-match - downcase
                dest_hash[parent][child] = src_hash[parent][child]
              end
            end
            break
          end
        end
      end
    end
    dest_hash
  end
end

# vim: set ts=2 sw=2 et :
