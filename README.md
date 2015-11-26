####Table of Contents

1. [Overview](#overview)
2. [Usage - Configuration options and additional functionality](#usage)
3. [Function List](#function-list)
    * [array2hashnamedbysubkey](#array2hashnamedbysubkey)
    * [delete_child_subkey_by_regex](#delete_child_subkey_by_regex)
    * [downcase_child_subkey_by_regex](#downcase_child_subkey_by_regex)
    * [get_child_subkey_value_by_regex](#get_child_subkey_value_by_regex)
    * [keys_where_child_subkey_match_by_regex](#keys_where_child_subkey_match_by_regex)
    * [insert_child_subkey_if_missing](#insert_child_subkey_if_missing)
    * [insert_child_subkey](#insert_child_subkey)
4. [Development - Guide for contributing to the module](#development)
    * [Running Tests](#running-tests)

##Overview

[![Build Status](https://travis-ci.org/rdark/puppet-mungelib.svg?branch=develop)](https://travis-ci.org/rdark/puppet-mungelib)

A stdlib of sorts, a collection of functions for munging, mangling and
manipulating data in wierd and wonderful ways.

## Function List

### Array2hashnamedbysubkey

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

#### Array2hashnamedbysubkey Examples

1. Example of default behavior with two arguments:

Given an array of hashes resembling:

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

2. Example of default behavior with three arguments and subkey naming

Given an array of hashes resembling:

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

And a subkey to match:

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

### Delete_child_subkey_by_regex

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
define/defined type using create_resources or equivilant.

Anything that is not a nested hash, or does not match the regular expression is
passed to the output without processing further.

See also: `delete_child_subkey()`, `delete()`

#### Delete_child_subkey_by_regex Examples

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

A second argument regular expession matching: `^puppet_module_`

And a third argument regular expression matching:  `'^(git_repo|branch|spurious|data)$'`

Passed to this function as: 

    delete_child_subkey(
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

A second argument regular expession matching: `^puppet_module_`

And a third argument regular expression matching:  `^(git_repo|branch|spurious|data)$`

And a fourth argument given as something evaluating to true, all passed to this function as: 

    delete_child_subkey(
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

### Downcase_child_subkey_by_regex

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

See also: `delete_child_subkey_by_regex()`, `downcase()`

#### Downcase_child_subkey_by_regex Examples

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

A second argument regular expession matching: `^vhost_[0-9]+$`

And a third argument regular expression matching:  `^SSLEnable$`

Passed to this function as: 

    downcase_child_subkey_by_regex(
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
matching (i.e any subkey _not_ matching the regex should be downcased):

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

A second argument regular expession matching: `^vhost_[0-9]+$`

And a third argument regular expression matching:  `^SSLEnable$`

And a fourth argument given as something evaluating to true:

Passed to this function as: 

    downcase_child_subkey(
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

### Get_child_subkey_value_by_regex

This function follows a similar logic to delete_child_subkey_by_regex, but
instead of deleting values, it will return an array of the the values of a
given subkey, matching the parent key by regex.

In summary, the first argument should be a nested hash data structure, the
second argument should be a regular expression matching parent keys to operate
on, and the third argument should be a regular expressions matching child
subkey values to return.

This is primarily intended for sharing hiera data structures between multiple
classes that require similar, but not identical data in order to pass back to a
define/defined type using create_resouces or equivilant.

Anything that is not a nested hash, or does not match the regular expression is
passed to the output without processing further.

See also: `delete_child_subkey_by_regex()`

#### Get_child_subkey_value_by_regex Examples

1. Regular matching.

A given variable $hiera_puppet_modules which contains a hash:

    hiera_puppet_modules = {
      'puppet_module_vsftpd' => {
        'ensure'   => 'present',
        'git_repo' => 'git@git.mydomain/vsftpd',
        'branch'   => 'production',
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

A second argument regular expession matching: `^puppet_module_`

And a third argument regular expression matching:  `^git_repo$`

Passed to this function as: 

    get_child_subkey_value_by_regex(
        $hiera_puppet_modules,
        '^puppet_module_',
        '^git_repo$'
    )

Would give:

    ['git@git.mydomain/apache', 'git@git.mydomain/vsftpd']

### Keys_where_child_subkey_match_by_regex

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

See also: `get_child_subkey_value_by_regex()`

#### Keys_where_child_subkey_match_by_regex Examples

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

A second argument regular expession matching: `^puppet_module_`

And a third argument regular expression matching:  `^git_repo$`

Passed to this function as: 

    get_child_subkey_value_by_regex(
        $hiera_puppet_modules,
        '^puppet_module_',
        '^git_repo$'
    )

Would give:

    ['puppet_module_vsftpd', 'puppet_module_apache']


### Insert_child_subkey_if_missing

Given a hash containing nested hashes, a single or array of regular
expressions, and a single-depth hash, this function will insert the keys+values
of the second hash (provided as third argument) into each first-depth nested
hash that matches any of the given regular expressions, but _only_ if that key
does not exist. This allows you to set defaults within a module, but provide
more explicit values via hiera.

This is primarily intended for sharing hiera data structures between multiple
classes that require similar, but not identical data in order to pass back to a
define/defined type using create_resouces or equivilant.

Anything that is not a nested hash, or does not match the regular expression is
passed to the output without processing further.

See also: `insert_child_subkey()`

#### Insert_child_subkey_if_missing Examples

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

A regular expession matching: `^puppet_module_`

And a third hash matching matching: 

    $insert_hash = {
      'git_repo' => 'git@git.theirdomain',
      'branch'   => 'master',
    }

Passed to this function as:

    insert_child_subkey_if_missing(
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

#### Insert_child_subkey

Given a hash containing nested hashes, a single or array of regular
expressions, and a single-depth hash, this function will insert the keys+values
of that third hash into each first-depth nested hash that matches any of the
given regular expressions.

Note that this is done in a RHS-wins fashion, so any existing data will be
overwritten where matching keys are found.

This is primarily intended for sharing hiera data structures between multiple
classes that require similar, but not identical data in order to pass back to a
define/defined type using create_resouces or equivilant.

Anything that is not a nested hash, or does not match the regular expression is
passed to the output without processing further.

See also: `insert_child_subkey_if_missing()`

##### Insert_child_subkey Examples

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

A regular expession matching: `^puppet_module_`

And a third hash matching matching: 

    $insert_hash = {
      'git_repo' => 'git@git.theirdomain',
      'branch'   => 'master',
    }
    
Passed to this function as: 

    insert_child_subkey(
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


##Development

1. Fork the repository
2. Create a feature/topic branch (usually against develop)
3. Write tests
4. Write code
5. Write docs (explain what/why and how)
6. Practice good commit hygiene
7. Send a Pull Request

### Running Tests

    $ bundle exec rake spec

##Contributors

* [Richard Clark](https://github.com/rdark)
