require "redis"

class RedisCache
  REDIS = Redis.new(url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" })

  def self.set(key, value, expiration = 300)
    REDIS.set(key, value, ex: expiration)
  end

  def self.get(key)
    REDIS.get(key)
  end

  def self.delete(key)
    REDIS.del(key)
  end

  def self.hset(hash, field, value)
    REDIS.hset(hash, field, value)
  end

  def self.hget(hash, field)
    REDIS.hget(hash, field)
  end

  def self.hdel(hash)
    REDIS.del(hash)
  end
end
