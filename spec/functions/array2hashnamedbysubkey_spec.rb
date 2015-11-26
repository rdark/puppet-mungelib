require 'spec_helper'
require 'rspec-puppet'

describe 'array2hashnamedbysubkey' do
  let(:good_array) {
    [
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
  }

  let(:bad_array_missing_key) {
    [
      {
        'port' => '443',
        'data' => 'foo',
      },
      {
        'data' => 'bar',
      },
      {
        'port' => '8080',
        'data' => 'baz',
      },
    ]
  }
  
  let(:expect_good_array_iter) {
    {
      'prefix_1' =>  {
        'port' => '443',
        'data' => 'foo',
      },
      'prefix_2' =>  {
        'port' => '80',
        'data' => 'bar',
      },
      'prefix_3' =>  {
        'port' => '8080',
        'data' => 'baz',
      },
    }
  }

  let(:expect_good_array_key) {
    {
      'prefix_443' =>  {
        'port' => '443',
        'data' => 'foo',
      },
      'prefix_80' =>  {
        'port' => '80',
        'data' => 'bar',
      },
      'prefix_8080' =>  {
        'port' => '8080',
        'data' => 'baz',
      },
    }
  }

  describe 'Make a nested hash with postfixed integer iterator' do
    it { should run.with_params(good_array, 'prefix_').and_return(expect_good_array_iter) }
  end

  describe 'Make a nested hash with postfixed integer iterator' do
    it { should run.with_params(good_array, 'prefix_', 'port').and_return(expect_good_array_key) }
  end

  describe "When incorrect arguments are given" do
    it { should run.with_params().and_raise_error(ArgumentError) }
    # need an array as first arg
    it { should run.with_params({},'23').and_raise_error(ArgumentError) }
    # need a string rather than integer as second arg
    it { should run.with_params([],23).and_raise_error(ArgumentError) }
    # type error for third arg (if given)
    it { should run.with_params([],23, []).and_raise_error(ArgumentError) }
    # need array elements to be hashes
    it { should run.with_params([{},'a string', 'another string'],"23").and_raise_error(Puppet::ParseError) }
  end

  describe "When a key is missing from input data" do
    it { should run.with_params(bad_array_missing_key, 'prefix_', 'port').and_raise_error(Puppet::ParseError)}
  end

end

# vim: set ts=2 sw=2 et :
