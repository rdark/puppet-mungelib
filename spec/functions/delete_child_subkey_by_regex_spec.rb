require 'spec_helper'
require 'rspec-puppet'

describe 'delete_child_subkey_by_regex' do

  let(:hiera_puppet_modules) {
    {
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
  }

  let(:expect_match_positive) {
    {
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
      }
    }
  }

  let(:expect_match_negative) {
    {
      'puppet_module_vsftpd' => {
        'ensure'   => 'present',
        'git_repo' => 'git@git.mydomain',
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
      }
    }
  }

  describe 'Match keys in the single regex' do
    it { should run.with_params(hiera_puppet_modules, '^puppet_module_', '^(git_repo|branch|spurious|data)$').and_return(expect_match_positive) }
  end

   describe 'Match keys _not_ in single regex' do
     it { should run.with_params(hiera_puppet_modules, '^puppet_module_', '^(ensure|git_repo)$', true).and_return(expect_match_negative) }
   end

  describe 'Match keys in the array of regex' do
    let(:matches) {
      [ '^git_repo$','^branch$', '^spurious$', '^data$']
    }
    it { should run.with_params(hiera_puppet_modules, '^puppet_module_', matches).and_return(expect_match_positive) }
  end

  describe 'Match keys _not_ in the array of regex' do
    let(:matches) {
      [ '^ensure$','^git_repo$']
    }
    it { should run.with_params(hiera_puppet_modules, '^puppet_module_', matches, 'inverse').and_return(expect_match_negative) }
  end

  describe "When incorrect arguments are given" do
    # empty args
    it { should run.with_params().and_raise_error(ArgumentError) }
    # need a hash as first arg
    it { should run.with_params([],'23','blah').and_raise_error(ArgumentError) }
  end


end

# vim: set ts=2 sw=2 et :
