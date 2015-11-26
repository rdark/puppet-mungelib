#
# array2hashnamedbysubkey.rb
#
# === Author
#
# Richard Clark <rclark@fohnet.co.uk>
#
module Puppet::Parser::Functions
  newfunction(:array2hashnamedbysubkey, :type => :rvalue, :doc => <<-EOS
This sexily named function is intended for the use case where you have an array
of hashes, which you want to point at a type or define, but in order to do this
you need to convert this to a hash of hashes, so that each resulting resource
has a namevar.

The naming of these parent keys can come from one of two sources.

1. When two arguments are given (an array of hashes, and a string), the string
is used as a prefix for each of the hash keys, which will be followed by an
string representation of an integer ($prefix1, $prefix2 etc).

2. When three arguments are given (an array of hashes, a string, and a second
string), the first string is used as a prefix same as before. The second string
is used to look up a matching key within each hash (which _must_ exist). The
value of that key is used as the postfix. It then that the values of that key
must be unique within the data structure so that all resulting hash keys are
unique.

*Examples:*

1. Example of default behavior with two arguments:

An array of hashes resembling:

$vhosts = [
  {
    'port' => '443',
    'data' => 'foo',
  },
  {
    'port' => '80',
    'data' => 'bar',
  },
  {
    'port' => '8080',
    'data' => 'baz',
  },
]

A prefix:

$prefix = 'vhost_'

Passed to this function like:

array2hashnamedbysubkey($vhosts,$prefix)

Would give:

{
  'vhost_1' =>  {
    'port' => '443',
    'data' => 'foo',
  },
  'vhost_2' =>  {
    'port' => '80',
    'data' => 'bar',
  },
  'vhost_3' =>  {
    'port' => '8080',
    'data' => 'baz',
  },
}

2. Example of default behavior with three arguments and subkey naming:

An array of hashes resembling:

$vhosts = [
  {
    'port' => '443',
    'data' => 'foo',
  },
  {
    'port' => '80',
    'data' => 'bar',
  },
  {
    'port' => '8080',
    'data' => 'baz',
  },
]

A prefix:

$prefix = 'vhost_'

A subkey to match:

$subkey = 'port'

Passed to this function like:

array2hashnamedbysubkey($vhosts,$prefix,$subkey)

Would give:

{
  'vhost_443' =>  {
    'port' => '443',
    'data' => 'foo',
  },
  'vhost_80' =>  {
    'port' => '80',
    'data' => 'bar',
  },
  'vhost_8080' =>  {
    'port' => '8080',
    'data' => 'baz',
  },
}

EOS
  ) do |arguments|
    if (arguments.size < 2) or (arguments.size > 3) then
      raise ArgumentError, "array2hashnamedbysubkey(): Wrong number of arguments" +
        "given #{arguments.size} for 2 or 3"
    end

    src_array = arguments[0]
    prefix    = arguments[1]
    child_key = arguments[2]

    unless src_array.is_a? Array
      raise ArgumentError, "First argument must be an array"
    end
    unless prefix.is_a? String
      raise ArgumentError, "Second argument must be a string"
    end
    if child_key and !child_key.is_a? String
      raise ArgumentError, "Third argument (if given) must be a string"
    end

    # grab name of child key if given for verification
    dest_hash = Hash.new
    postfix = 1

    # verify all sub-data structures are hashes
    src_array.each_with_index do |element,i|
      unless element.is_a? Hash
        raise Puppet::ParseError, "All array elements must be hashes"
      end
      # just simple prefix + integer
      if arguments.size == 2
        dest_hash["#{prefix}#{postfix.to_s}"] = src_array[i]
        postfix += 1
      else
        # set parent key name to value of child hash
        raise Puppet::ParseError, "Hash at index #{i} does not have key #{child_key}" unless src_array[i].has_key? child_key
        dest_hash["#{prefix}#{src_array[i][child_key]}"] = src_array[i]
      end
    end

    dest_hash
  end
end


# vim: set ts=2 sw=2 et :
