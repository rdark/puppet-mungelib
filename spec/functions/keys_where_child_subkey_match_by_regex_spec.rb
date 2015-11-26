require 'spec_helper'
require 'rspec-puppet'

describe 'keys_where_child_subkey_match_by_regex' do

  let(:hiera_puppet_modules) {
    {
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
  }

  let(:expect_match_positive) {
    ['puppet_module_vsftpd', 'puppet_module_apache']
  }

  let(:expect_match_positive_array) {
    ['puppet_module_vsftpd', 'puppet_module_sudo', 'puppet_module_apache']
  }

  describe 'Return parent keys where subkeys match by single regex' do
    it { should run.with_params(hiera_puppet_modules, '^puppet_module_', '^git_repo$').and_return(expect_match_positive) }
  end

  describe 'Return values from subkeys by array of regex' do
    let(:matches) {
      ['^git_repo$','^ensure$']
    }
    it { should run.with_params(hiera_puppet_modules, '^puppet_module_', matches).and_return(expect_match_positive_array) }
  end

  describe "When incorrect arguments are given" do
    # empty args
    it { should run.with_params().and_raise_error(ArgumentError) }
    # need a hash as first arg
    it { should run.with_params([],'23','blah').and_raise_error(ArgumentError) }
  end


end

# vim: set ts=2 sw=2 et :
