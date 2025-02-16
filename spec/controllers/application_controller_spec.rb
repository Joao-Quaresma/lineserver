require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller do
    before_action :check_rate_limit

    def index
      render json: { message: "Success" }
    end
  end

  let(:test_ip) { "123.45.67.89" }

  before do
    RedisCache.delete("rate_limit:#{test_ip}")
    request.remote_ip = test_ip
  end

  it "allows requests under the limit" do
    99.times do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  it "blocks requests exceeding the limit" do
    100.times { get :index }

    get :index
    expect(response).to have_http_status(429)
    expect(response.body).to include("Rate limit exceeded")
  end
end
