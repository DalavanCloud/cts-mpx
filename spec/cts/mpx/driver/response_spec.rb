require 'spec_helper'

module Cts
  module Mpx
    module Driver
      describe Response do
        include_context "with request and response objects"

        it { is_expected.to be_a_kind_of Creatable }
        it { is_expected.to respond_to(:data).with(0).arguments }
        it { is_expected.to respond_to(:healthy?).with(0).arguments }
        it { is_expected.to respond_to(:page).with(0).arguments }
        it { is_expected.to respond_to(:status).with(0).arguments }

        describe "#data" do
          it { expect(response.data).to be_a_kind_of Hash }

          it "is expected to call Oj.compat_load against original.body" do
            allow(Oj).to receive(:compat_load).and_call_original
            response.data
            expect(Oj).to have_received(:compat_load).with(excon_body)
          end

          context "when the response contains a service exception" do
            let(:excon_body) { service_exception_body }

            it { expect { response.data }.to raise_error ServiceError, /title.*description.*cid/ }
          end

          context "when healthy? is false" do
            before { excon_response.params[:status] = 500 }

            it "is expected to raise an exception" do
              expect { response.data }.to raise_error RuntimeError, 'response does not appear to be healthy'
            end
          end

          context "when original.body is not serializable" do
            before { excon_response.params[:body] = 'no.' }

            it "is expected to raise an exception" do
              expect { response.data }.to raise_error(RuntimeError, /could not parse data/)
            end
          end
        end

        describe "#healthy?" do
          it "is expected to return true" do
            expect(response.healthy?).to eq true
          end

          context "when original.status is not 2xx or 3xx" do
            before { excon_response.params[:status] = 500 }

            it "is expected to return false" do
              expect(response.healthy?).to eq false
            end
          end
        end

        describe "#service_exception?" do
          it { expect(response.service_exception?).to be false }

          context "when the isException field is true" do
            before { excon_response.params[:body] = service_exception_body }

            it { expect(response.service_exception?).to eq true }
          end
        end

        describe "#page" do
          it "is expected to call Page.create with the entries and xmlns values extracted from the body." do
            allow(Page).to receive(:create)
            response.page
            expect(Page).to have_received(:create).with entries: [], xmlns: nil
          end

          it "is expected to return an instance of Page" do
            expect(response.page).to be_a_kind_of Cts::Mpx::Driver::Page
          end

          context "when healthy? is false" do
            before { excon_response.params[:status] = 500 }

            it "is expected to raise an exception" do
              expect { response.page }.to raise_error RuntimeError, 'response does not appear to be healthy'
            end
          end
        end

        describe "#status" do
          it "is expected to return the status code of the response" do
            expect(response.status).to eq 200
          end

          it { expect(response.status).to be_a_kind_of Integer }
        end
      end
    end
  end
end
