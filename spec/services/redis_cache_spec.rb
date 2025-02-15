require "rails_helper"

RSpec.describe RedisCache, type: :service do
  let(:key) { "test_key" }
  let(:value) { "test_value" }
  let(:hash_key) { "test_hash" }
  let(:field) { "field1" }
  let(:field_value) { "field_value" }

  before do
    RedisCache.delete(key)
    RedisCache.hdel(hash_key)
  end

  after(:all) do
    RedisCache.delete("files:list")
    RedisCache.delete("file:test_file")
  end

  describe ".set and .get" do
    it "stores and retrieves a value" do
      RedisCache.set(key, value, 300)

      expect(RedisCache.get(key)).to eq(value)
    end

    it "returns nil for missing keys" do
      expect(RedisCache.get("non_existent_key")).to be_nil
    end
  end

  describe ".delete" do
    it "removes a key" do
      RedisCache.set(key, value, 300)
      RedisCache.delete(key)

      expect(RedisCache.get(key)).to be_nil
    end
  end

  describe ".hset and .hget" do
    it "stores and retrieves a hash field" do
      RedisCache.hset(hash_key, field, field_value)

      expect(RedisCache.hget(hash_key, field)).to eq(field_value)
    end

    it "returns nil for missing hash fields" do
      expect(RedisCache.hget(hash_key, "missing_field")).to be_nil
    end
  end

  describe ".hdel" do
    it "deletes a hash key" do
      RedisCache.hset(hash_key, field, field_value)
      RedisCache.hdel(hash_key)

      expect(RedisCache.hget(hash_key, field)).to be_nil
    end
  end
end
