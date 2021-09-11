#!/usr/bin/env ruby

class String
  def to_bit_str
    BitString.new(self)
  end

  def to_ipv4
    IPv4.new(self)
  end
end

class BitString
  attr_reader :str

  def initialize(str)
    @str = str.gsub(" ", "").gsub(/\A0+/, "")
  end

  def pad(pad_count: 8)
    leftover_count = @str.length % pad_count
    add_count = if leftover_count > 0
                  pad_count - leftover_count
                else
                  0
                end
    "0" * add_count + @str
  end

  def &(object)
    padded_and(object)
  end

  def |(object)
    padded_or(object)
  end

  def invert
    BitString.new(@str.split("").map { |x| x == "1" ? "0" : "1" }.join)
  end

  def to_s
    self.pad(pad_count: 8).scan(/.{8}/).join(" ")
  end

  def to_ipv4
    IPv4.new(self)
  end

  def padded_and(object, pad_count: 8)
    bit_str = if object.is_a?(BitString)
                object
              elsif object.is_a?(IPv4)
                object.bit_str
              end

    str1 = self.pad(pad_count: pad_count)
    str2 = bit_str.pad(pad_count: pad_count)

    if str1.length != str2.length
      raise "Incompatible lengths: #{str1.length} and #{str2.length}. Try adding more padding."
    end

    str = str1.split("").zip(str2.split("")).map do |a, b|
      a == "1" && b == "1" ? "1" : "0"
    end.join

    BitString.new(str)
  end

  def padded_or(object, pad_count: 8)
    bit_str = if object.is_a?(BitString)
                object
              elsif object.is_a?(IPv4)
                object.bit_str
              end

    str1 = self.pad(pad_count: pad_count)
    str2 = bit_str.pad(pad_count: pad_count)

    if str1.length != str2.length
      raise "Incompatible lengths: #{str1.length} and #{str2.length}. Try adding more padding."
    end

    str = str1.split("").zip(str2.split("")).map do |a, b|
      a == "1" || b == "1" ? "1" : "0"
    end.join

    BitString.new(str)
  end
end

class IPv4
  attr_reader :bit_str

  def initialize(object)
    if object.is_a?(BitString)
      @bit_str = object
    elsif object.is_a?(String)
      str = object.gsub(" ", "")
      if str.match?(/\A[01]+\z/) # Bit string
        @bit_str = BitString.new(str)
      elsif str.match?(/\A(\d{1,3}\.){3}\d{1,3}\z/) # IP address
        bit_str = str.split(".").map do |x|
          unpadded = x.to_i(10).to_s(2)
          "0" * (8 - unpadded.length) + unpadded
        end.join
        @bit_str = BitString.new(bit_str)
      else
        raise "Can't turn object into IPv4: string does not match bit string or IP address: #{str}"
      end
    else
      raise "Can't turn object into IPv4: #{object}"
    end
  end

  def invert
    IPv4.new(@bit_str.invert)
  end

  def &(object)
    bit_str = if object.is_a?(BitString)
                object
              elsif object.is_a?(IPv4)
                object.bit_str
              end

    IPv4.new(@bit_str.padded_and(bit_str, pad_count: 32))
  end

  def |(object)
    bit_str = if object.is_a?(BitString)
                object
              elsif object.is_a?(IPv4)
                object.bit_str
              end

    IPv4.new(@bit_str.padded_or(bit_str, pad_count: 32))
  end

  def mask(netmask)
    netmask = ipv4_netmask(netmask) if netmask.is_a?(Integer)
    bit_str = self.bit_str & netmask.bit_str
    IPv4.new(bit_str)
  end

  def split_half(netmask_length)
    bit_str1 = @bit_str.pad.dup
    bit_str2 = @bit_str.pad.dup
    bit_str1[netmask_length + 1] = "0"
    bit_str2[netmask_length + 1] = "1"
    [BitString.new(bit_str1), BitString.new(bit_str2)]
  end

  def directed_broadcast_addr(netmask_length)
    self | ipv4_netmask(netmask_length).invert
  end

  def to_s
    @bit_str.pad(pad_count: 32).gsub(" ", "").scan(/.{8}/).map { |x| x.to_i(2).to_s }.join(".")
  end
end

# In: integer: number of bits in the network part
# Out: string: netmask (format: bits)
def ipv4_netmask(netmask_length)
  ("1" * netmask_length + "0" * (32 - netmask_length)).to_ipv4
end

require 'irb'
binding.irb
