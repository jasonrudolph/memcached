require 'test_helper'

class ClientTest < BaseTest

  # Flush

  def test_flush
    cache.set "foo", "bar"
    assert_equal "bar", cache.get("foo")
    cache.flush
    assert_nil cache.get("foo")
  end

  # Exist

  def test_missing_exist
    refute cache.exist(key)
  end

  def test_exist
    cache.set key, @value
    assert cache.exist(key)
  end

  def test_missing_exist_binary
    refute binary_protocol_cache.exist(key)
  end

  def test_exist_binary
    binary_protocol_cache.set key, @value
    assert binary_protocol_cache.exist(key)
  end

  # Replace

  def test_replace
    cache.set key, nil
    cache.replace key, @value
    assert_equal @value, cache.get(key)
  end

  def test_missing_replace
    refute cache.replace(key, @value)
    assert_nil cache.get(key)
  end

  # Error states

  def test_key_with_spaces
    key = "i have a space"
    assert_raises(Memcached::BadKeyProvided) do
      cache.set key, @value
    end
    assert_raises(Memcached::BadKeyProvided) do
      cache.get(key)
    end
  end

#  def test_key_with_null
#    key = "with\000null"
#    #assert_raises(Memcached::ABadKeyWasProvidedOrCharactersOutOfRange) do
#      cache.set key, @value
#    #end
#    #assert_raises(Memcached::ABadKeyWasProvidedOrCharactersOutOfRange) do
#      cache.get(key)
#    #end
#      #assert_raises(Memcached::ABadKeyWasProvidedOrCharactersOutOfRange) do
#      cache.get_multi([key])
#  end

  def test_key_with_invalid_control_characters
    key = "ch\303\242teau"
    assert_raises(Memcached::BadKeyProvided) do
      cache.set key, @value
    end
    assert_raises(Memcached::BadKeyProvided) do
      cache.get(key)
    end
    assert_raises(Memcached::BadKeyProvided) do
      cache.get_multi([key])
    end
  end

  def test_key_too_long
    key = "x"*251
    assert_raises(Memcached::BadKeyProvided) do
      cache.set key, @value
    end
    assert_raises(Memcached::BadKeyProvided) do
      cache.get(key)
    end
    assert_raises(Memcached::BadKeyProvided) do
      cache.get_multi([key])
    end
  end

#  def test_verify_key_disabled
#    cache = Memcached.new @servers, :verify_key => false
#    key = "i have a space"
#    assert_raises(Memcached::ProtocolError) do
#      cache.set key, @value
#    end
#    assert_raises(Memcached::NotFound) do
#      cache.get key, @value
#    end
#  end
#
  def test_server_error_message
    err = assert_raises(Memcached::E2big) do
      cache.set key, "I'm big" * 1000000
    end
    assert_equal "ITEM TOO BIG", err.message
  end

#  def test_errno_message
#    Rlibmemcached::MemcachedServerSt.any_instance.stubs("cached_errno").returns(1)
#    @cache.send(:check_return_code, Rlibmemcached::MEMCACHED_ERRNO, key)
#  rescue Memcached::SystemError => e
#    assert_match /^Errno 1: "Operation not permitted". Key/, e.message
  #  end

  def test_clone_with_connection_loaded
    @cache = cache
    cache = @cache.clone
    assert_equal cache.servers, @cache.servers
    refute_equal cache, @cache

    # Definitely check that the connections are unlinked
    refute_equal @cache.connection.object_id, cache.connection.object_id

    # normal set, should work
    @cache.set key, @value
  end

  def test_clone_with_connected_client
    @cache = cache
    @cache.set key, @value

    cache = @cache.clone
    assert_equal cache.servers, @cache.servers
    refute_equal cache, @cache

    # Definitely check that the connections are unlinked
    refute_equal @cache.connection.object_id, cache.connection.object_id

    # normal set, should work
    @cache.set key, @value
  end

  def test_thread_contention
    @cache = cache

    threads = []
    4.times do |index|
      threads << Thread.new do
        cache = @cache.clone
        cache.set("test_thread_contention_#{index}", "value#{index}")
        assert_equal "value#{index}", cache.get("test_thread_contention_#{index}")
      end
    end
    threads.each { |thread| thread.join }
  end
end