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

  describe 'GET' do
    subject { get url }
    let(:url) { device_reading_path(id) }
    context 'when a device reading has been registered' do
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
      let(:device_reading_params) do
        {
          id: "36d5658a-6908-479e-887e-a949ec199272",
          readings: [reading_1, reading_2],
        }
      end
      before do
        DeviceReadingMemoryStorage.ingest!(params: device_reading_params)
      end

      context 'given a device id' do
        let(:id) { "36d5658a-6908-479e-887e-a949ec199272" }

        it 'returns the latest_timestamp' do
          subject
          expect(JSON.parse(response.body)["latest_timestamp"]).to eq("2021-09-29T16:09:15+01:00")
        end

        it 'returns the cumulative_count' do
          subject
          expect(JSON.parse(response.body)["cumulative_count"]).to eq(17)
        end

        context 'with no readings' do
          let(:id) { "non-existent" }
          it 'has an empty latest_timestamp' do
            subject
            expect(JSON.parse(response.body)["latest_timestamp"]).to eq("")
          end
          it 'has an empty cumulative_count' do
            subject
            expect(JSON.parse(response.body)["cumulative_count"]).to eq(0)
          end
        end

        context 'with duplicate writes' do
          before do
            DeviceReadingMemoryStorage.ingest!(params: device_reading_params_dup)
          end
          let(:device_reading_params_dup) do
            {
              id: "36d5658a-6908-479e-887e-a949ec199272",
              readings: [reading_2, reading_3],
            }
          end
          let(:reading_3) do
            {
              timestamp: "2020-12-20T13:28:45+01:00",
              count: 5,
            }
          end

          it 'returns the latest_timestamp' do
            subject
            expect(JSON.parse(response.body)["latest_timestamp"]).to eq("2021-09-29T16:09:15+01:00")
          end

          it 'returns the cumulative_count' do
            subject
            expect(JSON.parse(response.body)["cumulative_count"]).to eq(22)
          end
        end
        context 'with multiple separate readings' do
          let(:device_reading_params_2) do
            {
              id: "36d5658a-6908-479e-887e-a949ec199272",
              readings: [reading_3, reading_4, reading_5],
            }
          end
          let(:device_reading_params_3) do
            {
              id: "36d5658a-6908-479e-887e-a949ec199272",
              readings: [reading_6],
            }
          end

          let(:reading_3) do
            {
              timestamp: "2021-12-20T13:28:45+01:00",
              count: 5,
            }
          end
          let(:reading_4) do
            {
              timestamp: "2022-01-22T23:40:55+01:00",
              count: 1,
            }
          end
          let(:reading_5) do
            {
              timestamp: "2022-01-25T04:04:04+01:00",
              count: 18,
            }
          end
          let(:reading_6) do
            {
              timestamp: "2021-09-27T12:22:11+01:00",
              count: 100,
            }
          end
          before do
            DeviceReadingMemoryStorage.ingest!(params: device_reading_params_2)
            DeviceReadingMemoryStorage.ingest!(params: device_reading_params_3)
          end

          it 'returns the latest_timestamp' do
            subject
            expect(JSON.parse(response.body)["latest_timestamp"]).to eq("2022-01-25T04:04:04+01:00")
          end

          it 'returns the cumulative_count' do
            subject
            expect(JSON.parse(response.body)["cumulative_count"]).to eq(141)
          end
        end
      end
    end
  end
end
