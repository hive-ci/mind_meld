require 'spec_helper'
require 'mind_meld/device'

describe MindMeld::Device do
  let(:device1) {
    { name: 'First device' }
  }
  let(:device2) {
    { name: 'Second device' }
  }
  let(:api) { MindMeld::Device.new(
      url: 'http://test.server/',
      device: {
        name: 'Controlling device'
      }
    )
  }

  before(:each) do
    stub_request(:put, 'http://test.server/api/devices/poll.json').
      with(:body => "device%5Bname%5D=First+device").
      to_return(
        :status => 200,
        :body => '[]'
      )

  end

  describe '#register' do
    it 'registers a valid device' do
      expect(api.register( device1 )).to be_a Hash
    end

    it 'returns the id of a device' do
      expect(api.register( device1 )['id']).to eq 1
      expect(api.register( device2 )['id']).to eq 2
    end
  end

  let(:api) {
              MindMeld::Device.new(
                            url: 'http://test.server/',
                            device: {
                              name: 'Test host',
                            }
                          )
            }
  let(:api_fail) {
              MindMeld::Device.new(
                            url: 'http://test.server/',
                            device: {
                              name: 'Test host fail',
                            }
                          )
            }
  before(:each) do
    stub_request(:post, 'http://test.server/api/devices/register.json').
      with(body: 'device%5Bname%5D=Test+host').
      to_return(
        status: 200,
        body: '{ "id": 76, "name": "Name returned from server" }'
      )
    stub_request(:post, 'http://test.server/api/devices/register.json').
      with(body: 'device%5Bname%5D=Test+host+fail').
      to_return(
        status: 500
      )
  end

  describe '#id' do
    it 'returns the id of the device' do
      expect(api.id).to eq 76
    end

    it 'returns nil if device cannot register' do
      expect(api_fail.id).to be_nil
    end
  end

  describe '#name' do
    it 'returns the name of the device' do
      expect(api.name).to eq 'Name returned from server'
    end
  end

  describe '#poll' do
    let(:api) {
                MindMeld::Device.new(
                              url: 'http://test.server/',
                              device: {
                                name: 'Test host',
                              }
                            )
              }

    before(:each) do
      stub_request(:post, 'http://test.server/api/devices/register.json').
        with(body: 'device%5Bname%5D=Test+host').
        to_return(
          status: 200,
          body: '{ "id": 76 }'
        )
    end

    it 'polls the controlling device' do
      stub_request(:put, 'http://test.server/api/devices/poll.json').
        with(body: 'poll%5Bid%5D=76').
        to_return(
          status: 200,
          body: '{}'
        )
      expect(api.poll).to eq({})
    end

    it 'polls another device' do
      stub_request(:put, 'http://test.server/api/devices/poll.json').
        with(body: 'poll%5Bdevices%5D%5B%5D=123&poll%5Bid%5D=76').
        to_return(
          status: 200,
          body: '{}'
        )
      expect(api.poll(123)).to eq({})
    end

    it 'polls multiple devices' do
      stub_request(:put, "http://test.server/api/devices/poll.json").
        with(:body => "poll%5Bdevices%5D%5B%5D=123&poll%5Bdevices%5D%5B%5D=364&poll%5Bdevices%5D%5B%5D=7&poll%5Bid%5D=76").
        to_return(
          status: 200,
          body: '{}'
        )
      expect(api.poll(123, 364, 7)).to eq({})
    end
  end

  describe '#create_action' do
    it 'submits a new action for a device' do
      stub_request(:put, 'http://test.server/api/devices/action.json').
        with(body: 'device_action%5Baction_type%5D=redirect&device_action%5Bbody%5D=http%3A%2F%2Fexample.com&device_action%5Bdevice_id%5D=76').
        to_return(
          status: 200,
          body: '{ }'
        )
      expect(api.create_action(action_type: 'redirect', body: 'http://example.com')).to eq({})
    end
  end

  describe '#hive_queues' do
    let(:api) {
                MindMeld::Device.new(
                              url: 'http://test.server/',
                              device: {
                                name: 'First device',
                              }
                            )
              }
    let(:api2) {
                MindMeld::Device.new(
                              url: 'http://test.server/',
                              device: {
                                name: 'Second device',
                              }
                            )
              }

    it 'returns a list of hive queues' do
      expect(api.hive_queues).to match_array(['first_queue', 'second_queue'])
    end

    it 'returns an empty list of hive queues for nil value' do
      expect(api2.hive_queues).to eq []
    end
  end
end