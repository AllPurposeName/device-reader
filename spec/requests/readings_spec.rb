require 'rails_helper'
RSpec.describe 'Readings' do
  describe 'POST' do
    subject { post(url, params:) }
    let(:url) { device_reading_index_path }
    let(:params) { base_params }
    let(:reading_1) do
      {
        timestamp: "2021-09-29T16:08:15+01:00",
        count: 2,
      }
    end
    let(:reading_2) do
      {
        timestamp: "2021-09-29T16:09:15+01:00",
        count: 15,
      }
    end
    let(:base_params) do
      {
        id: "36d5658a-6908-479e-887e-a949ec199272",
        readings: [reading_1, reading_2],
      }
    end
    context 'invalid requests' do
      shared_examples "returns an invalid parameter error" do |missing_parameter|
        it do
          subject
          expect(response.status).to eq(422)
          expect(JSON.parse(response.body)["message"]).to include("Missing or invalid parameters: #{missing_parameter}")
        end
      end
      context 'missing the required top level key' do
        ['id', 'readings'].each do |missing_required_key|
          context "#{missing_required_key}" do
            let(:params) { base_params.except(missing_required_key.to_sym) }
            it_behaves_like "returns an invalid parameter error", missing_required_key
          end
        end
      end
      context 'missing the required readings key' do
        ['count', 'timestamp'].each do |missing_required_key|
          context "#{missing_required_key}" do
            let(:reading_2) { reading_1.except(missing_required_key.to_sym) }
            it_behaves_like "returns an invalid parameter error", missing_required_key
          end
        end
      end
    end
    context 'duplicate request' do
      subject do
        post(url, params:)
        post(url, params:)
      end

      it 'is idempotent' do
        expect_any_instance_of(DeviceReadingMemoryStorage).to receive(:increment_count).exactly(1).times
        subject
      end
    end

    context 'happy path' do
      it 'writes to storage' do
        subject
        expect(response.status).to eq(201)
      end
    end
  end
end
