require 'spec_helper'
require 'rspec-puppet'


describe 'insert_child_subkey_if_missing' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  let(:regex) { '^puppet_module_' }

  let(:src_data_1) {
    {
      'puppet_module_vsftpd' => {
        'ensure'   => 'present'
      }
    }
  }
  let(:src_data_2) {
    {
      'puppet_module_vsftpd' => {
        'ensure'   => 'present',
        'branch'   => 'production'
      }
    }
  }
  let(:src_data_3) {
    {
      'key_1' => {
        'child_key_1' => 'child_value_1'

      },
      'key_2' => {
        'child_key_2' => 'child_value_2'
      },
      'key_3' => {
        'child_key_3' => 'child_value_3'
      }
    }
  }
  let(:insert_hash_1) {
    {
      'git_repo' => 'git@git.theirdomain',
      'branch'   => 'master'
    }
  }
  let(:insert_hash_2){
    {
      'simple' => 'hash'
    }
  }

  describe 'argument handling' do
    it 'fails with no arguments' do
      lambda { scope.function_insert_child_subkey_if_missing([]) }.should( raise_error(Puppet::ParseError))
    end
  end

  describe 'basic functionality' do
    it 'should not delete or modify existing keys out of regex scope' do
      result = scope.function_insert_child_subkey_if_missing([src_data_1,regex,insert_hash_1])
      true_test = result['puppet_module_vsftpd'].has_key?('ensure')
      true_test.should(eq(true))
      result['puppet_module_vsftpd']['ensure'].should(eq('present'))
    end

    it 'should add new keys where they do not already exist' do
      result = scope.function_insert_child_subkey_if_missing([src_data_1,regex,insert_hash_1])
      key_test = result['puppet_module_vsftpd'].keys
      key_test.should include('git_repo')
      result['puppet_module_vsftpd']['git_repo'].should(eq('git@git.theirdomain'))
    end
    
    it 'should not overwrite values for existing keys' do
      result = scope.function_insert_child_subkey_if_missing([src_data_2,regex,insert_hash_1])
      result = result['puppet_module_vsftpd']['branch']
      result.should(eq('production'))
    end

    describe 'given a regex that matches anything' do
      it 'should insert the RHS hash into every child hash' do
        result = scope.function_insert_child_subkey_if_missing([src_data_3,'.',insert_hash_2])
        result.each_key do |r_key|
          result[r_key]['simple'].should(eq('hash'))
        end
      end
    end
  end

end

