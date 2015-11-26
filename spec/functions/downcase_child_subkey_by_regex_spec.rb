require 'spec_helper'
require 'rspec-puppet'

describe 'downcase_child_subkey_by_regex' do

  let(:tomcat_connectors) {
    {
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
  }

  let(:expect_match_positive) {
    {
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
  }

  let(:expect_match_negative) {
    {
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
  }

  describe 'Match keys in the single regex' do
    it { should run.with_params(tomcat_connectors, '^vhost_[0-9]$', '^SSLEnable$').and_return(expect_match_positive) }
  end

   describe 'Match keys _not_ in single regex' do
     it { should run.with_params(tomcat_connectors, '^vhost_[0-9]$', '^$SSLEnable$', true).and_return(expect_match_negative) }
   end

  describe 'Match keys in the array of regex' do
    let(:matches) {
      [ '^SSLEnable$', '^port$']
    }
    it { should run.with_params(tomcat_connectors, '^vhost_[0-9]$', matches).and_return(expect_match_positive) }
  end

  describe 'Match keys _not_ in the array of regex' do
    let(:matches) {
      [ '^SSLEnable$', '^port$']
    }
    it { should run.with_params(tomcat_connectors, '^vhost_[0-9]$', matches, 'inverse').and_return(expect_match_negative) }
  end

  describe "When incorrect arguments are given" do
    # empty args
    it { should run.with_params().and_raise_error(ArgumentError) }
    # need a hash as first arg
    it { should run.with_params([],'23','blah').and_raise_error(ArgumentError) }
  end


end

# vim: set ts=2 sw=2 et :
