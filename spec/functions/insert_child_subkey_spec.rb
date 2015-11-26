require 'spec_helper'
require 'rspec-puppet'


describe 'insert_child_subkey' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  let(:regex) { '^puppet_module_' }
  let(:insert_hash_1) {
    {
      'git_repo' => 'git@git.theirdomain',
      'branch'   => 'master',
    }
  }
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

  describe 'argument handling' do
    it 'fails with no arguments' do
      lambda { scope.function_insert_child_subkey([]) }.should( raise_error(Puppet::ParseError))
    end
  end

  describe 'basic functionality' do
    it 'should not delete or modify existing keys out of regex scope' do
      result = scope.function_insert_child_subkey([src_data_1,regex,insert_hash_1])
      true_test = result['puppet_module_vsftpd'].has_key?('ensure')
      true_test.should(eq(true))
      result['puppet_module_vsftpd']['ensure'].should(eq('present'))
    end

    it 'should add new keys where they do not already exist' do
      result = scope.function_insert_child_subkey([src_data_1,regex,insert_hash_1])
      key_test = result['puppet_module_vsftpd'].keys
      key_test.should include('git_repo')
      result['puppet_module_vsftpd']['git_repo'].should(eq('git@git.theirdomain'))
    end
    
    it 'should overwrite values for existing keys' do
      result = scope.function_insert_child_subkey([src_data_2,regex,insert_hash_1])
      result = result['puppet_module_vsftpd']['branch']
      result.should(eq('master'))
    end

  end

end

