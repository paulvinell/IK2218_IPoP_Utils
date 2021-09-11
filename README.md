# IK2218_IPoP_Utils
Ruby utils for reducing manual labor when solving utils in KTH course IK2218.
The primary premise is easy conversion between three main types - strings, bit strings, and IPv4 addresses.

Run it from your terminal with

```
./helper.rb
```

You will enter standard Ruby irb, but sprinkled with helper functions.

For instance, does 177.121.128.2 belong to 177.121.128.0/18?

```
irb(main):002:0> "177.121.128.2".to_ipv4.mask(18).to_s
=> "177.121.128.0"
```

Or maybe you want the directed broadcast address of 177.121.128.0/18.

```
irb(main):005:0> ("177.121.128.0".to_ipv4 | ipv4_netmask(18).invert).to_s
=> "177.121.191.255"
```

Or in binary

```
irb(main):006:0> ("177.121.128.0".to_ipv4 | ipv4_netmask(18).invert).bit_str.to_s
=> "10110001 01111001 10111111 11111111"
```
