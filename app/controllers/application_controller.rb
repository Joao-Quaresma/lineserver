class ApplicationController < ActionController::Base
  before_action :check_rate_limit

  allow_browser versions: :modern

  private

  def check_rate_limit
    ip = request.remote_ip
    key = "rate_limit:#{ip}"

    count = RedisCache.get(key).to_i

    if count >= 100
      respond_to do |format|
        format.json { render json: { error: "Rate limit exceeded. Try again later." }, status: 429 }
        format.html { render plain: "Rate limit exceeded. Try again later.", status: 429 }
      end
    else
      RedisCache.set(key, count + 1, 60)
    end
  end
end
